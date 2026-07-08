# Tsunbooku

A cross-platform mobile app to keep track of your books.

**App**

[![App CI](https://github.com/samdouble/tsunbooku/actions/workflows/app-checks.yml/badge.svg)](https://github.com/samdouble/tsunbooku/actions/workflows/app-checks.yml)
[![Coverage Status](https://coveralls.io/repos/samdouble/tsunbooku/badge.svg?branch=master&service=github)](https://coveralls.io/github/samdouble/tsunbooku?branch=master)

[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=ffffff)](https://flutter.dev/)
[![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![iOS](https://img.shields.io/badge/iOS-000000?&logo=apple&logoColor=white)](https://developer.apple.com/ios/)

**Backend**

[![CI](https://github.com/samdouble/tsunbooku/actions/workflows/backend-checks.yml/badge.svg)](https://github.com/samdouble/tsunbooku/actions/workflows/backend-checks.yml)
[![Coverage Status](https://coveralls.io/repos/samdouble/tsunbooku/badge.svg?branch=master&service=github)](https://coveralls.io/github/samdouble/tsunbooku?branch=master)

[![Go](https://img.shields.io/badge/Go-%2300ADD8.svg?&logo=go&logoColor=white)](https://go.dev/)
[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-%234285F4.svg?logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![AWS Lambda](https://custom-icon-badges.demolab.com/badge/AWS%20Lambda-%23FF9900.svg?logo=aws-lambda&logoColor=white)](https://aws.amazon.com/lambda/)
[![MongoDB](https://img.shields.io/badge/MongoDB-%234ea94b.svg?logo=mongodb&logoColor=white)](https://www.mongodb.com/)

## Development

```mermaid

architecture-beta
    service: backend
    service: app
    service: database
```

### App

#### Set up environment variables

Create an `.env` file at the root of the project:

```
TSUNBOOKU_API_URL=
NEW_RELIC_ANDROID_APP_TOKEN=
NEW_RELIC_IOS_APP_TOKEN=
```

#### Install Flutter SDK and its dependencies

Follow the [official documentation](https://docs.flutter.dev/get-started/quick).

On macOS, that means installing:
- Flutter SDK
- XCode
- CocoaPods

For managing multiple Flutter SDK versions, you can use FVM.

```bash
brew tap leoafarias/fvm
brew install fvm
```

Run `fvm flutter doctor` to verify that everything is installed correctly.
Make sure you have the correct version of Flutter installed by running these commands from the root of the project:

```bash
fvm install 3.41.2
fvm use 3.41.2
fvm flutter --version
```

#### Run the app

If you are using a hardware device, make sure Developer Mode is enabled on your device and that you have USB debugging enabled.

In VSCode/Cursor, search for `Flutter: Select Device` and select your device. Then, in the `Run & Debug` pane, select `tsunbooku` and click the green play button.

Shortly after, you should see the app running on your device.

### Backend

#### Set up environment variables

Create a `.env` file with the following variables:

```
AUTH_JWT_SECRET=
GOOGLE_BOOKS_API_TOKEN=
ISBNDB_API_KEY=
MONGO_DBNAME=
MONGO_URL=
```

#### Scheduled catalog ingest

A Lambda (`BooksIngestCatalog`) runs every hour via EventBridge and pulls books from ISBNdb into MongoDB:

1. **Updated ISBN feed** — fetches recently updated ISBNs (Premium plans), then bulk-fetches book metadata via `POST /books`.
2. **Author crawl** — picks authors from the `authors` collection that have not been ingested recently and fetches their books.

Tune quota usage with these environment variables (defaults shown):

```
INGEST_FEED_ENABLED=true
INGEST_MAX_FEED_PAGES=3
INGEST_FEED_PAGE_SIZE=100
INGEST_MAX_AUTHORS_PER_RUN=3
INGEST_MAX_PAGES_PER_AUTHOR=2
INGEST_AUTHOR_PAGE_SIZE=100
INGEST_AUTHOR_STALE_DAYS=30
INGEST_BULK_ISBN_BATCH_SIZE=100
```

If the updated ISBN feed is unavailable on your plan, the job skips it and continues with author crawl only.

#### API routes

Authentication:
- `POST /auth/sendOtp` (send OTP)
- `POST /auth/verifyOtp` (verify OTP)

Feedback:

- `POST /feedback/submitFeedback` (submit feature idea or bug report)

Feedback routes require `Authorization: Bearer <token>`.
The token is returned by `POST /auth/verifyOtp`.

Libraries:

- `POST /libraries`
- `GET /libraries`
- `PATCH /libraries/{id}`
- `DELETE /libraries/{id}`
- `GET /libraries/{id}/books`
- `PUT /libraries/{id}/books`

Library routes require `Authorization: Bearer <token>`.  
The token is returned by `POST /auth/verifyOtp`.

#### Instantiate the MongoDB replica set

```sh
docker compose up -d
```

Build the Docker image:

```sh
docker build -t tsunbooku-api .
```

Run the Docker container with the book's ISBN as a command line argument:

```sh
docker run --env-file .env --network tsunbooku-api_default -e "MONGO_URL=mongodb://tsunbooku-api-mongo0:27017,tsunbooku-api-mongo1:27017,tsunbooku-api-mongo2:27017/?replicaSet=rs0" tsunbooku-api <isbn>
```
