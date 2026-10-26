import 'dart:math' as math;

import 'package:reel/domain/entities/feed_signal.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/person.dart';

/// How much each thing you do says about your taste. Positive is "more like
/// this". Library signals are strong; Discover signals are light nudges.
class TasteWeights {
  const TasteWeights._();

  static const favorite = 2.0;
  static const loved = 1.5;
  static const liked = 1.0;
  static const watchedUnrated = 0.5;
  static const disliked = -1.5;
  static const watchlist = 0.5;
  static const notInterested = -1.0;
  static const skippedFast = -0.15;
  static const watchedClip = 0.25;
  static const unmuted = 0.25;
  static const openedDetails = 0.25;
  static const openedService = 0.5;

  static double forSignal(FeedSignalType type) => switch (type) {
    FeedSignalType.notInterested => notInterested,
    FeedSignalType.skippedFast => skippedFast,
    FeedSignalType.watchedClip => watchedClip,
    FeedSignalType.unmuted => unmuted,
    FeedSignalType.openedDetails => openedDetails,
    FeedSignalType.openedService => openedService,
  };

  /// What a library entry says, from favorite, latest rating and watchlist.
  static double forEntry(LibraryEntry entry) {
    if (entry.favorite) return favorite;
    if (entry.watched) {
      return switch (entry.latestRating) {
        Rating.loved => loved,
        Rating.liked => liked,
        Rating.disliked => disliked,
        null => watchedUnrated,
      };
    }
    return entry.onWatchlist ? watchlist : 0;
  }
}

/// Positive and negative weight behind one genre, person or media type.
class Affinity {
  final double positive;
  final double negative;

  const Affinity({this.positive = 0, this.negative = 0});

  /// -1 to 1, pulled toward 0 when there's little evidence.
  double get score => (positive - negative) / (positive + negative + 2);

  double get evidence => positive + negative;

  Affinity add(double weight) => weight >= 0
      ? Affinity(positive: positive + weight, negative: negative)
      : Affinity(positive: positive, negative: negative - weight);
}

class GenreTaste {
  final String genre;
  final Affinity affinity;

  /// Watched titles in this genre.
  final int watched;

  const GenreTaste(this.genre, this.affinity, this.watched);
}

enum PersonRole { actor, director }

class PersonTaste {
  final Person person;
  final PersonRole role;
  final Affinity affinity;

  /// Watched titles with this person.
  final int watched;

  const PersonTaste(this.person, this.role, this.affinity, this.watched);
}

/// Watches per week, for the activity chart.
class WeeklyActivity {
  /// Monday 00:00 (local time) of the week.
  final DateTime weekStart;
  final int watches;

  const WeeklyActivity(this.weekStart, this.watches);
}

class TasteProfile {
  /// Strongest affinity first.
  final List<GenreTaste> genres;
  final List<PersonTaste> directors;
  final List<PersonTaste> actors;
  final Map<MediaType, Affinity> types;

  /// The middle half of runtimes you liked, in minutes; null without data.
  final (int, int)? likedRuntime;

  /// Titles you rated, favorited or saved; the strongest signals.
  final int libraryEvidence;

  // Stats for the You tab.
  final int watchedThisMonth;
  final int watchedThisYear;
  final int minutesWatched;
  final int titlesWatched;
  final List<WeeklyActivity> weeks;

  const TasteProfile({
    this.genres = const [],
    this.directors = const [],
    this.actors = const [],
    this.types = const {},
    this.likedRuntime,
    this.libraryEvidence = 0,
    this.watchedThisMonth = 0,
    this.watchedThisYear = 0,
    this.minutesWatched = 0,
    this.titlesWatched = 0,
    this.weeks = const [],
  });

  static const empty = TasteProfile();

  /// Enough to personalize: a few titles rated or saved.
  bool get hasTaste => libraryEvidence >= 3;

  Affinity genre(String name) => _genreMap[name] ?? const Affinity();

  Map<String, Affinity> get _genreMap => {for (final g in genres) g.genre: g.affinity};
}

/// Builds the taste profile from your library and recent Discover signals.
///
/// [lookup] finds the details of a title a signal points at (library or
/// feed cards); signals for unknown titles are skipped.
TasteProfile analyzeTaste({
  required Iterable<LibraryEntry> library,
  Iterable<FeedSignal> signals = const [],
  MediaTitle? Function(TitleId id)? lookup,
  required DateTime now,
  int weekCount = 12,
}) {
  final genres = <String, Affinity>{};
  final genreWatched = <String, int>{};
  final people = <(PersonRole, String), Affinity>{};
  final peopleWatched = <(PersonRole, String), int>{};
  final names = <String, Person>{};
  final types = <MediaType, Affinity>{};
  final likedRuntimes = <int>[];
  var evidence = 0;

  void apply(MediaTitle title, double weight, {bool watched = false}) {
    if (weight == 0) return;
    for (final genre in title.genres.toSet()) {
      genres[genre] = (genres[genre] ?? const Affinity()).add(weight);
      if (watched) genreWatched[genre] = (genreWatched[genre] ?? 0) + 1;
    }
    for (final (role, credited) in [(PersonRole.director, title.directors), (PersonRole.actor, title.cast.take(5))]) {
      for (final person in credited) {
        final key = (role, person.id);
        names[person.id] = person;
        people[key] = (people[key] ?? const Affinity()).add(weight);
        if (watched) peopleWatched[key] = (peopleWatched[key] ?? 0) + 1;
      }
    }
    types[title.type] = (types[title.type] ?? const Affinity()).add(weight);
  }

  // Stats.
  final monthStart = DateTime(now.year, now.month);
  final yearStart = DateTime(now.year);
  final currentWeek = _weekStart(now);
  final firstWeek = _addWeeks(currentWeek, -(weekCount - 1));
  final weekly = List.filled(weekCount, 0);
  var thisMonth = 0;
  var thisYear = 0;
  var minutes = 0;
  var titlesWatched = 0;

  for (final entry in library) {
    final weight = TasteWeights.forEntry(entry);
    if (weight != 0) evidence++;
    apply(entry.snapshot, weight, watched: entry.watched);
    if (weight > 0 &&
        entry.watched &&
        entry.snapshot.runtimeMinutes != null &&
        entry.snapshot.type == MediaType.movie) {
      likedRuntimes.add(entry.snapshot.runtimeMinutes!);
    }
    if (entry.watched) titlesWatched++;
    for (final watch in entry.watches) {
      final at = watch.watchedAt;
      if (!at.isBefore(monthStart) && !at.isAfter(now)) thisMonth++;
      if (!at.isBefore(yearStart) && !at.isAfter(now)) thisYear++;
      // A series counts one episode-length per logged watch; we don't
      // track episodes yet.
      minutes += entry.snapshot.runtimeMinutes ?? 0;
      final index = _weeksBetween(firstWeek, _weekStart(at.toLocal()));
      if (index >= 0 && index < weekCount) weekly[index]++;
    }
  }

  final libraryIds = {for (final e in library) e.id};
  for (final signal in signals) {
    // The library already speaks for titles in it.
    if (libraryIds.contains(signal.id)) continue;
    final title = lookup?.call(signal.id);
    if (title != null) apply(title, TasteWeights.forSignal(signal.type));
  }

  int byAffinity(Affinity a, Affinity b, String an, String bn) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byEvidence = b.evidence.compareTo(a.evidence);
    return byEvidence != 0 ? byEvidence : an.compareTo(bn);
  }

  List<PersonTaste> peopleFor(PersonRole role) {
    final list = [
      for (final entry in people.entries)
        if (entry.key.$1 == role) PersonTaste(names[entry.key.$2]!, role, entry.value, peopleWatched[entry.key] ?? 0),
    ]..sort((a, b) => byAffinity(a.affinity, b.affinity, a.person.name, b.person.name));
    return list;
  }

  likedRuntimes.sort();
  return TasteProfile(
    genres: [for (final entry in genres.entries) GenreTaste(entry.key, entry.value, genreWatched[entry.key] ?? 0)]
      ..sort((a, b) => byAffinity(a.affinity, b.affinity, a.genre, b.genre)),
    directors: peopleFor(PersonRole.director),
    actors: peopleFor(PersonRole.actor),
    types: types,
    likedRuntime: likedRuntimes.length < 4
        ? null
        : (likedRuntimes[likedRuntimes.length ~/ 4], likedRuntimes[(likedRuntimes.length * 3) ~/ 4]),
    libraryEvidence: evidence,
    watchedThisMonth: thisMonth,
    watchedThisYear: thisYear,
    minutesWatched: minutes,
    titlesWatched: titlesWatched,
    weeks: [for (var i = 0; i < weekCount; i++) WeeklyActivity(_addWeeks(firstWeek, i), weekly[i])],
  );
}

/// Genres to search for candidates: liked more than not, with some
/// evidence, best first.
List<String> topGenres(TasteProfile taste, {int count = 2}) => [
  for (final g in taste.genres)
    if (g.affinity.score > 0.15 && g.affinity.evidence >= 2) g.genre,
].take(count).toList();

/// Directors and actors to search for, directors first on a tie.
List<PersonTaste> topPeople(TasteProfile taste, {int count = 3}) {
  final liked =
      [
        for (final p in [...taste.directors, ...taste.actors])
          if (p.affinity.score > 0.2 && p.affinity.evidence >= 2) p,
      ]..sort((a, b) {
        final byScore = b.affinity.score.compareTo(a.affinity.score);
        return byScore != 0 ? byScore : b.role.index.compareTo(a.role.index);
      });
  return liked.take(count).toList();
}

/// Titles to base "Because you liked X" on: favorites and loved titles,
/// most recently touched first.
List<MediaTitle> likedAnchors(Iterable<LibraryEntry> library, {int count = 3}) {
  final liked = [
    for (final e in library)
      if (e.favorite || e.latestRating == Rating.loved) e,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return liked.take(count).map((e) => e.snapshot).toList();
}

/// How well [title] fits [taste]: genre, people and media type, roughly -1.5
/// to 1.5. Also names what matched, for the card's reason.
({double score, String? person, List<String> genres}) tasteFit(MediaTitle title, TasteProfile taste) {
  final genreScores = [for (final g in title.genres) (g, taste.genre(g).score)];
  final genreScore = genreScores.isEmpty
      ? 0.0
      : genreScores.map((g) => g.$2).reduce((a, b) => a + b) / genreScores.length;
  final directors = {for (final p in taste.directors) p.person.id: p.affinity.score};
  final actors = {for (final p in taste.actors) p.person.id: p.affinity.score};
  var peopleScore = 0.0;
  String? bestPerson;
  var bestPersonScore = 0.3;
  for (final person in title.directors) {
    final s = directors[person.id] ?? 0;
    peopleScore += s;
    if (s > bestPersonScore) (bestPerson, bestPersonScore) = (person.name, s);
  }
  for (final person in title.cast) {
    // An actor counts half: a director shapes the whole film.
    final s = (actors[person.id] ?? 0) * 0.5;
    peopleScore += s;
    if (s > bestPersonScore) (bestPerson, bestPersonScore) = (person.name, s);
  }
  final typeScore = (taste.types[title.type]?.score ?? 0) * 0.3;
  final matched = [
    for (final (genre, score) in genreScores..sort((a, b) => b.$2.compareTo(a.$2)))
      if (score > 0.15) genre,
  ];
  return (score: genreScore + peopleScore.clamp(-1.0, 1.0) + typeScore, person: bestPerson, genres: matched);
}

DateTime _weekStart(DateTime time) {
  final day = DateTime(time.year, time.month, time.day);
  return DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));
}

// Calendar arithmetic keeps weeks aligned across daylight saving changes.
DateTime _addWeeks(DateTime weekStart, int weeks) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + weeks * 7);

int _weeksBetween(DateTime from, DateTime to) {
  final days = DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  return (days / 7).floor();
}

/// Hours for display, e.g. 12.5 -> "12.5", 3.0 -> "3".
String formatHours(int minutes) {
  final hours = minutes / 60;
  return hours >= 10 || hours == hours.roundToDouble() ? '${hours.round()}' : hours.toStringAsFixed(1);
}

/// Used for the weekly chart's scale.
int maxWeekly(List<WeeklyActivity> weeks) => weeks.fold(0, (m, w) => math.max(m, w.watches));
