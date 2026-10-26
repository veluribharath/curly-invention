import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/person.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/entities/video.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';

/// Built-in data used when no TMDB key is set: in tests, CI and quick runs.
class MockCatalog {
  const MockCatalog._();

  static const netflix = StreamingService(providerId: 8, name: 'Netflix', displayPriority: 1);
  static const prime = StreamingService(providerId: 9, name: 'Amazon Prime Video', displayPriority: 2);
  static const disney = StreamingService(providerId: 337, name: 'Disney Plus', displayPriority: 3);
  static const max = StreamingService(providerId: 1899, name: 'Max', displayPriority: 4);
  static const hulu = StreamingService(providerId: 15, name: 'Hulu', displayPriority: 5);
  static const appleTv = StreamingService(providerId: 350, name: 'Apple TV+', displayPriority: 6);
  static const tubi = StreamingService(providerId: 73, name: 'Tubi TV', displayPriority: 7);
  static const appleStore = StreamingService(providerId: 2, name: 'Apple TV', displayPriority: 8);

  static const services = [netflix, prime, disney, max, hulu, appleTv, tubi, appleStore];

  static const _nolan = Person(id: '525', name: 'Christopher Nolan');

  static const titles = <MediaTitle>[
    MediaTitle(
      id: TitleId.movie(603692),
      name: 'John Wick: Chapter 4',
      year: 2023,
      genres: ['Action', 'Thriller', 'Crime'],
      posterPath: '/2A9n3ZdhC6qB6SmFmpK1kP7sOZb.jpg',
      overview: 'John Wick uncovers a path to defeating the High Table.',
      runtimeMinutes: 170,
      voteAverage: 7.7,
      voteCount: 7000,
      popularity: 90,
      cast: [
        Person(id: '6384', name: 'Keanu Reeves'),
        Person(id: '1341', name: 'Donnie Yen'),
      ],
      directors: [Person(id: '40684', name: 'Chad Stahelski')],
    ),
    MediaTitle(
      id: TitleId.movie(76600),
      name: 'Avatar: The Way of Water',
      year: 2022,
      genres: ['Science Fiction', 'Adventure', 'Action'],
      posterPath: '/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
      overview: 'Jake Sully lives with his newfound family on the planet of Pandora.',
      runtimeMinutes: 192,
      voteAverage: 7.6,
      voteCount: 11000,
      popularity: 80,
      cast: [
        Person(id: '65731', name: 'Sam Worthington'),
        Person(id: '8691', name: 'Zoe Saldaña'),
      ],
      directors: [Person(id: '2710', name: 'James Cameron')],
    ),
    MediaTitle(
      id: TitleId.movie(361743),
      name: 'Top Gun: Maverick',
      year: 2022,
      genres: ['Action', 'Drama'],
      posterPath: '/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
      overview: 'After more than thirty years of service, Maverick is still pushing the envelope.',
      runtimeMinutes: 131,
      voteAverage: 8.2,
      voteCount: 9000,
      popularity: 75,
      cast: [
        Person(id: '500', name: 'Tom Cruise'),
        Person(id: '996701', name: 'Miles Teller'),
      ],
      directors: [Person(id: '86270', name: 'Joseph Kosinski')],
    ),
    MediaTitle(
      id: TitleId.movie(27205),
      name: 'Inception',
      year: 2010,
      genres: ['Science Fiction', 'Action', 'Adventure'],
      posterPath: '/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg',
      overview: 'A thief who steals corporate secrets through dream-sharing technology.',
      runtimeMinutes: 148,
      voteAverage: 8.4,
      voteCount: 36000,
      popularity: 70,
      cast: [
        Person(id: '6193', name: 'Leonardo DiCaprio'),
        Person(id: '24045', name: 'Joseph Gordon-Levitt'),
      ],
      directors: [_nolan],
      videos: [Video(key: 'YoHD9XEInc0', kind: VideoKind.trailer, name: 'Official Trailer')],
    ),
    MediaTitle(
      id: TitleId.movie(157336),
      name: 'Interstellar',
      year: 2014,
      genres: ['Adventure', 'Drama', 'Science Fiction'],
      posterPath: '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      overview: 'A team of explorers travel through a wormhole in space.',
      runtimeMinutes: 169,
      voteAverage: 8.4,
      voteCount: 35000,
      popularity: 85,
      cast: [
        Person(id: '10297', name: 'Matthew McConaughey'),
        Person(id: '1813', name: 'Anne Hathaway'),
      ],
      directors: [_nolan],
      videos: [Video(key: 'zSWdZVtXT7E', kind: VideoKind.trailer, name: 'Official Trailer')],
    ),
    MediaTitle(
      id: TitleId.movie(693134),
      name: 'Dune: Part Two',
      year: 2024,
      genres: ['Science Fiction', 'Adventure'],
      overview: 'Paul Atreides unites with Chani and the Fremen while seeking revenge.',
      runtimeMinutes: 167,
      voteAverage: 8.2,
      voteCount: 6000,
      popularity: 95,
      cast: [
        Person(id: '1190668', name: 'Timothée Chalamet'),
        Person(id: '505710', name: 'Zendaya'),
      ],
      directors: [Person(id: '137427', name: 'Denis Villeneuve')],
      videos: [Video(key: 'Way9Dexny3w', kind: VideoKind.trailer, name: 'Official Trailer 3')],
    ),
    MediaTitle(
      id: TitleId.movie(680),
      name: 'Pulp Fiction',
      year: 1994,
      genres: ['Crime', 'Thriller'],
      posterPath: '/dM2w364MScsjFf8pfMbaWUcWrR.jpg',
      overview: 'The lives of two mob hitmen, a boxer and a pair of diner bandits intertwine.',
      runtimeMinutes: 154,
      voteAverage: 8.5,
      voteCount: 27000,
      popularity: 60,
      cast: [
        Person(id: '8891', name: 'John Travolta'),
        Person(id: '2231', name: 'Samuel L. Jackson'),
      ],
      directors: [Person(id: '138', name: 'Quentin Tarantino')],
    ),
    MediaTitle(
      id: TitleId.movie(238),
      name: 'The Godfather',
      year: 1972,
      genres: ['Drama', 'Crime'],
      posterPath: '/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
      overview: 'The aging patriarch of an organized crime dynasty transfers control to his son.',
      runtimeMinutes: 175,
      voteAverage: 8.7,
      voteCount: 20000,
      popularity: 55,
      cast: [
        Person(id: '3084', name: 'Marlon Brando'),
        Person(id: '1158', name: 'Al Pacino'),
      ],
      directors: [Person(id: '1776', name: 'Francis Ford Coppola')],
    ),
    MediaTitle(
      id: TitleId.movie(155),
      name: 'The Dark Knight',
      year: 2008,
      genres: ['Drama', 'Action', 'Crime', 'Thriller'],
      posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
      overview: 'Batman raises the stakes in his war on crime.',
      runtimeMinutes: 152,
      voteAverage: 8.5,
      voteCount: 32000,
      popularity: 65,
      cast: [
        Person(id: '3894', name: 'Christian Bale'),
        Person(id: '1810', name: 'Heath Ledger'),
      ],
      directors: [_nolan],
    ),
    MediaTitle(
      id: TitleId.movie(603),
      name: 'The Matrix',
      year: 1999,
      genres: ['Action', 'Science Fiction'],
      posterPath: '/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
      overview: 'A hacker learns the true nature of his reality.',
      runtimeMinutes: 136,
      voteAverage: 8.2,
      voteCount: 25000,
      popularity: 58,
      cast: [
        Person(id: '6384', name: 'Keanu Reeves'),
        Person(id: '2975', name: 'Laurence Fishburne'),
      ],
      directors: [
        Person(id: '9340', name: 'Lana Wachowski'),
        Person(id: '9339', name: 'Lilly Wachowski'),
      ],
    ),
    MediaTitle(
      id: TitleId.movie(515042),
      name: 'Free Solo',
      year: 2018,
      genres: ['Documentary', 'Adventure'],
      overview: 'Alex Honnold attempts to climb El Capitan without a rope.',
      runtimeMinutes: 100,
      voteAverage: 7.9,
      voteCount: 1300,
      popularity: 20,
      directors: [Person(id: '1388040', name: 'Elizabeth Chai Vasarhelyi')],
    ),
    MediaTitle(
      id: TitleId.movie(682110),
      name: 'My Octopus Teacher',
      year: 2020,
      genres: ['Documentary'],
      overview: 'A filmmaker forges an unusual friendship with an octopus in a South African kelp forest.',
      runtimeMinutes: 85,
      voteAverage: 7.9,
      voteCount: 1200,
      popularity: 15,
    ),
    MediaTitle(
      id: TitleId.tv(1396),
      name: 'Breaking Bad',
      year: 2008,
      genres: ['Drama', 'Crime'],
      overview: 'A chemistry teacher diagnosed with cancer turns to making meth.',
      runtimeMinutes: 47,
      seasonCount: 5,
      voteAverage: 8.9,
      voteCount: 14000,
      popularity: 88,
      cast: [
        Person(id: '17419', name: 'Bryan Cranston'),
        Person(id: '84497', name: 'Aaron Paul'),
      ],
      directors: [Person(id: '66633', name: 'Vince Gilligan')],
    ),
    MediaTitle(
      id: TitleId.tv(66732),
      name: 'Stranger Things',
      year: 2016,
      genres: ['Drama', 'Science Fiction', 'Fantasy', 'Mystery'],
      overview: 'A young boy vanishes, and a small town uncovers a mystery involving secret experiments.',
      runtimeMinutes: 60,
      seasonCount: 5,
      voteAverage: 8.6,
      voteCount: 18000,
      popularity: 92,
      cast: [
        Person(id: '1356210', name: 'Millie Bobby Brown'),
        Person(id: '35029', name: 'David Harbour'),
      ],
      directors: [
        Person(id: '1179419', name: 'Matt Duffer'),
        Person(id: '1179422', name: 'Ross Duffer'),
      ],
    ),
    MediaTitle(
      id: TitleId.tv(95396),
      name: 'Severance',
      year: 2022,
      genres: ['Drama', 'Mystery', 'Science Fiction', 'Fantasy'],
      overview: "Office workers' memories are surgically divided between work and personal lives.",
      runtimeMinutes: 50,
      seasonCount: 2,
      voteAverage: 8.4,
      voteCount: 2000,
      popularity: 70,
      cast: [
        Person(id: '19274', name: 'Adam Scott'),
        Person(id: '7907', name: 'Patricia Arquette'),
      ],
      directors: [Person(id: '1857839', name: 'Dan Erickson')],
    ),
    MediaTitle(
      id: TitleId.tv(136315),
      name: 'The Bear',
      year: 2022,
      genres: ['Comedy', 'Drama'],
      overview: 'A young chef from the fine dining world comes home to run his family sandwich shop.',
      runtimeMinutes: 30,
      seasonCount: 4,
      voteAverage: 8.2,
      voteCount: 1500,
      popularity: 50,
      cast: [
        Person(id: '1428070', name: 'Jeremy Allen White'),
        Person(id: '1891386', name: 'Ayo Edebiri'),
      ],
      directors: [Person(id: '1355958', name: 'Christopher Storer')],
    ),
    MediaTitle(
      id: TitleId.tv(2316),
      name: 'The Office',
      year: 2005,
      genres: ['Comedy'],
      overview: 'The everyday lives of office employees at Dunder Mifflin.',
      runtimeMinutes: 22,
      seasonCount: 9,
      voteAverage: 8.6,
      voteCount: 4000,
      popularity: 60,
      cast: [
        Person(id: '4495', name: 'Steve Carell'),
        Person(id: '57755', name: 'Rainn Wilson'),
      ],
      directors: [Person(id: '17016', name: 'Greg Daniels')],
    ),
    MediaTitle(
      id: TitleId.tv(68595),
      name: 'Planet Earth II',
      year: 2016,
      genres: ['Documentary'],
      overview: "David Attenborough presents a new look at the planet's most remarkable habitats.",
      runtimeMinutes: 50,
      seasonCount: 1,
      voteAverage: 9.0,
      voteCount: 1200,
      popularity: 30,
      cast: [Person(id: '2134', name: 'David Attenborough')],
    ),
  ];

  /// Where each title streams, the same in every country.
  static final Map<TitleId, List<Offer>> offers = {
    const TitleId.movie(603692): const [
      Offer(service: prime, type: OfferType.subscription),
      Offer(service: appleStore, type: OfferType.rent),
    ],
    const TitleId.movie(76600): const [
      Offer(service: disney, type: OfferType.subscription),
      Offer(service: max, type: OfferType.subscription),
    ],
    const TitleId.movie(361743): const [
      Offer(service: prime, type: OfferType.subscription),
      Offer(service: appleStore, type: OfferType.buy),
    ],
    const TitleId.movie(27205): const [
      Offer(service: netflix, type: OfferType.subscription),
      Offer(service: appleStore, type: OfferType.rent),
    ],
    const TitleId.movie(157336): const [
      Offer(service: prime, type: OfferType.subscription),
      Offer(service: appleStore, type: OfferType.rent),
    ],
    const TitleId.movie(693134): const [
      Offer(service: max, type: OfferType.subscription),
      Offer(service: appleStore, type: OfferType.buy),
    ],
    const TitleId.movie(680): const [
      Offer(service: tubi, type: OfferType.ads),
      Offer(service: appleStore, type: OfferType.rent),
    ],
    const TitleId.movie(238): const [Offer(service: appleStore, type: OfferType.rent)],
    const TitleId.movie(155): const [Offer(service: max, type: OfferType.subscription)],
    const TitleId.movie(603): const [
      Offer(service: max, type: OfferType.subscription),
      Offer(service: tubi, type: OfferType.ads),
    ],
    const TitleId.movie(515042): const [
      Offer(service: disney, type: OfferType.subscription),
      Offer(service: hulu, type: OfferType.subscription),
    ],
    const TitleId.movie(682110): const [Offer(service: netflix, type: OfferType.subscription)],
    const TitleId.tv(1396): const [Offer(service: netflix, type: OfferType.subscription)],
    const TitleId.tv(66732): const [Offer(service: netflix, type: OfferType.subscription)],
    const TitleId.tv(95396): const [Offer(service: appleTv, type: OfferType.subscription)],
    const TitleId.tv(136315): const [
      Offer(service: hulu, type: OfferType.subscription),
      Offer(service: disney, type: OfferType.subscription),
    ],
    const TitleId.tv(2316): const [Offer(service: prime, type: OfferType.subscription)],
    const TitleId.tv(68595): const [Offer(service: prime, type: OfferType.buy)],
  };

  static MediaTitle? byId(TitleId id) {
    for (final title in titles) {
      if (title.id == id) return title;
    }
    return null;
  }
}

class MockCatalogRepository implements CatalogRepository {
  /// Pretends to be a network so loading states show; zero in tests.
  final Duration latency;

  const MockCatalogRepository({this.latency = Duration.zero});

  Future<void> _wait() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

  @override
  Future<TitlePage> search(String query, {int page = 1}) async {
    await _wait();
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty || page > 1) return TitlePage.empty;
    return TitlePage(
      titles: [
        for (final title in MockCatalog.titles)
          if (title.name.toLowerCase().contains(needle) ||
              title.cast.any((p) => p.name.toLowerCase().contains(needle)) ||
              title.directors.any((p) => p.name.toLowerCase().contains(needle)))
            title,
      ],
    );
  }

  @override
  Future<MediaTitle> details(TitleId id) async {
    await _wait();
    final title = MockCatalog.byId(id);
    if (title == null) throw StateError('No mock title $id');
    return title;
  }

  @override
  Future<TitlePage> discover(DiscoverQuery query) async {
    await _wait();
    if (query.page > 1) return TitlePage(titles: const [], page: query.page);
    final results = MockCatalog.titles.where((t) {
      if (t.type != query.type) return false;
      if (query.genres.isNotEmpty && !t.genres.any(query.genres.contains)) return false;
      if (t.genres.any(query.withoutGenres.contains)) return false;
      if ((t.voteCount ?? 0) < query.minVotes) return false;
      if (query.people.isNotEmpty && ![...t.cast, ...t.directors].any((p) => query.people.contains(p.id))) {
        return false;
      }
      if (query.releasedAfter != null && (t.year ?? 0) < query.releasedAfter!.year) return false;
      // As on TMDB: without providers, the monetization types still apply.
      if (query.region != null) {
        final offers = MockCatalog.offers[t.id] ?? const [];
        final match = offers.any(
          (o) =>
              (query.providerIds.isEmpty || query.providerIds.contains(o.service.providerId)) &&
              query.monetization.contains(o.type),
        );
        if (!match) return false;
      }
      return true;
    }).toList();
    results.sort(switch (query.sort) {
      DiscoverSort.popular => (a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0),
      DiscoverSort.topRated => (a, b) => (b.voteAverage ?? 0).compareTo(a.voteAverage ?? 0),
      DiscoverSort.newest => (a, b) => (b.year ?? 0).compareTo(a.year ?? 0),
    });
    return TitlePage(titles: results);
  }

  @override
  Future<TitlePage> trending({int page = 1}) async {
    await _wait();
    if (page > 1) return TitlePage.empty;
    final titles = [...MockCatalog.titles]..sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
    return TitlePage(titles: titles.take(10).toList());
  }

  @override
  Future<List<MediaTitle>> similar(TitleId id) async {
    await _wait();
    final source = MockCatalog.byId(id);
    if (source == null) return const [];
    return [
      for (final title in MockCatalog.titles)
        if (title.id != id && title.genres.any(source.genres.contains)) title,
    ].take(8).toList();
  }

  @override
  Future<List<MediaTitle>> byPerson(String personId) async {
    await _wait();
    return [
      for (final title in MockCatalog.titles)
        if ([...title.cast, ...title.directors].any((p) => p.id == personId)) title,
    ];
  }

  @override
  Future<List<StreamingService>> services(String country) async {
    await _wait();
    return MockCatalog.services;
  }

  @override
  Future<Map<String, String>> regions() async {
    await _wait();
    return const {'CA': 'Canada', 'GB': 'United Kingdom', 'IN': 'India', 'US': 'United States of America'};
  }
}
