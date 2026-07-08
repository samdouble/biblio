# Changelog

## [0.8.0](https://github.com/samdouble/tsunbooku/compare/backend-v0.7.0...backend-v0.8.0) (2026-07-08)


### Features

* **app:** adjust app to the new REST-style backend routes ([8c69fd3](https://github.com/samdouble/tsunbooku/commit/8c69fd3e1b2ce0f17133a7190cff4ece69596752))
* **backend:** add submitFeedback route ([8ecb5e0](https://github.com/samdouble/tsunbooku/commit/8ecb5e0bdbb9d14ad6fdcb3b97f93abe1189118a))
* **backend:** go to REST-style routes for libraries ([0f6aefc](https://github.com/samdouble/tsunbooku/commit/0f6aefc16f901459d6fc568375d95a6d4937f996))
* **backend:** improve authentication for API routes ([059cf5c](https://github.com/samdouble/tsunbooku/commit/059cf5c10566cf15ce591f86e8c75b6498b0dfe6))
* **backend:** ingest books when idle ([84b9afb](https://github.com/samdouble/tsunbooku/commit/84b9afbdc8c059ef5e54abdbba6d8a14cb014a63))
* **backend:** save author information when fetching books ([216beee](https://github.com/samdouble/tsunbooku/commit/216beee077ebe7cdd67e4e6ab88e872d4e9aeaaf))
* rename app from Biblio to Tsundoku ([ded44ba](https://github.com/samdouble/tsunbooku/commit/ded44ba20ed4117f3653681e187313255772ca6b))
* rename app from Tsundoku to Tsunbooku ([4df685c](https://github.com/samdouble/tsunbooku/commit/4df685ca29236d20ead13fc0a284cb570a6415d9))


### Bug Fixes

* **backend:** make search case-insensitive and insensitive to diacritics ([0b12e41](https://github.com/samdouble/tsunbooku/commit/0b12e417f3ba863d1794c12afaef0344bdc08ce0))

## [0.7.0](https://github.com/samdouble/tsunbooku/compare/backend-v0.6.1...backend-v0.7.0) (2026-03-09)


### Features

* **backend:** allow assigning colors for libraries ([7fc071e](https://github.com/samdouble/tsunbooku/commit/7fc071e980e0c1d37ce0d44fde2c00c02cc6384b))

## [0.6.1](https://github.com/samdouble/tsunbooku/compare/backend-v0.6.0...backend-v0.6.1) (2026-03-08)


### Bug Fixes

* **backend:** fetch books information when books for author are requested ([115f2ef](https://github.com/samdouble/tsunbooku/commit/115f2ef81594cdc24e8d5747157d4980ca75cdd6))

## [0.6.0](https://github.com/samdouble/tsunbooku/compare/backend-v0.5.0...backend-v0.6.0) (2026-03-08)


### Features

* **backend:** add functions to sync books-libraries relationships ([8e3ffa6](https://github.com/samdouble/tsunbooku/commit/8e3ffa6628cd04b4beb95e0d997ce413d9ef5d8f))
* **backend:** add getBooksByAuthor function ([3e1e1ce](https://github.com/samdouble/tsunbooku/commit/3e1e1ceaf907b7be53d866639f66a5fcc917f614))

## [0.5.0](https://github.com/samdouble/tsunbooku/compare/backend-v0.4.0...backend-v0.5.0) (2026-03-04)


### Features

* **backend:** add searchBooks function ([30f0399](https://github.com/samdouble/tsunbooku/commit/30f0399f60f1c3b2021b62179c735133244cb6cc))


### Bug Fixes

* **backend:** fix build for libraries functions ([46e6607](https://github.com/samdouble/tsunbooku/commit/46e66070c7880bf554c5a3032d870da074da03b6))

## [0.4.0](https://github.com/samdouble/tsunbooku/compare/backend-v0.3.0...backend-v0.4.0) (2026-03-04)


### Features

* **backend:** add librairies endpoints ([ce0efb6](https://github.com/samdouble/tsunbooku/commit/ce0efb6851d9fde3953732dd610565761f1f17c0))

## [0.3.0](https://github.com/samdouble/tsunbooku/compare/backend-v0.2.0...backend-v0.3.0) (2026-03-03)


### Features

* **backend:** add send and verify OTP functions ([71edad7](https://github.com/samdouble/tsunbooku/commit/71edad7ffd3607ed09cbbdf276ac9c40fe02b9dd))
* **backend:** added signup endpoint ([8581716](https://github.com/samdouble/tsunbooku/commit/85817165140ffe2f1aa35fd3fad15c7e6efbb83c))

## [0.2.0](https://github.com/samdouble/tsunbooku/compare/backend-v0.1.0...backend-v0.2.0) (2026-02-28)


### Features

* **app:** add Libraries ([4f1922e](https://github.com/samdouble/tsunbooku/commit/4f1922e496559d66f92ba739c2d070aca47dc0ad))
* **backend:** add apiProvider field to books ([1dd1e8c](https://github.com/samdouble/tsunbooku/commit/1dd1e8c416d02aaee5a7e7f539a996139e0e3590))
* **backend:** add ISBN search using ISBNDB API ([f76aeb8](https://github.com/samdouble/tsunbooku/commit/f76aeb8f084c66c8e90daa284bcba0d141a3960c))
* **backend:** use ISBNDB by default ([520bc31](https://github.com/samdouble/tsunbooku/commit/520bc3114ae130f6e6e36ca3fda1f98f3171c3a4))
