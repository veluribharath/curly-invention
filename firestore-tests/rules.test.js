import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';

import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-reel',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(() => env.clearFirestore());

const entry = (overrides = {}) => ({
  type: 'movie',
  tmdbId: 27205,
  title: 'Inception',
  onWatchlist: true,
  favorite: false,
  watches: [],
  genres: ['Science Fiction'],
  ...overrides,
});

test('a user reads and writes their own library', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice/library/movie_27205'), entry()));
  await assertSucceeds(getDoc(doc(db, 'users/alice/library/movie_27205')));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/library/movie_27205')));
});

test("nobody reads or writes someone else's library", async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(getDoc(doc(db, 'users/alice/library/movie_27205')));
  await assertFails(setDoc(doc(db, 'users/alice/library/movie_27205'), entry()));
});

test('signed-out users get nothing', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/alice')));
  await assertFails(getDoc(doc(db, 'availabilityCache/US_movie_1')));
});

test('the document id must match the title', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'users/alice/library/tv_27205'), entry()));
  await assertFails(setDoc(doc(db, 'users/alice/library/movie_27205'), entry({ type: 'book' })));
});

test('settings only take known fields', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice'), { country: 'US', serviceIds: [8, 9], includeFreeWithAds: false }));
  await assertFails(setDoc(doc(db, 'users/alice'), { country: 'US', isAdmin: true }));
});

test('signals can be added but not changed', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const ref = doc(db, 'users/alice/signals/s1');
  await assertSucceeds(setDoc(ref, { type: 'tv', tmdbId: 1396, signal: 'notInterested', at: new Date() }));
  await assertFails(setDoc(ref, { type: 'tv', tmdbId: 1396, signal: 'unmuted', at: new Date() }));
});

test('caches are read-only to clients', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(getDoc(doc(db, 'clipOverrides/movie_1')));
  await assertFails(setDoc(doc(db, 'availabilityCache/US_movie_1'), { offers: [] }));
  await assertFails(setDoc(doc(db, 'clipOverrides/movie_1'), { start: 30 }));
});
