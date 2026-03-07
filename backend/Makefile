# CGO_ENABLED=0 produces static binary for Lambda provided.al2023
GOBUILD = CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bootstrap .
BUILD_DIR = .build

# Pre-build all Lambda binaries into .build/<id>/ so SAM gets per-function CodeUri.
# Run: make build-all && sam build
build-all:
	@mkdir -p $(BUILD_DIR)/AuthSendOtp $(BUILD_DIR)/AuthVerifyOtp $(BUILD_DIR)/BooksGetBookByIsbn $(BUILD_DIR)/BooksSearchBooks \
		$(BUILD_DIR)/LibrariesCreateLibrary $(BUILD_DIR)/LibrariesGetLibraries $(BUILD_DIR)/LibrariesUpdateLibrary $(BUILD_DIR)/LibrariesDeleteLibrary
	cd packages/auth/sendOtp && $(GOBUILD) && mv bootstrap ../../../$(BUILD_DIR)/AuthSendOtp/
	cd packages/auth/verifyOtp && $(GOBUILD) && mv bootstrap ../../../$(BUILD_DIR)/AuthVerifyOtp/
	cd packages/books/getBookByIsbn && $(GOBUILD) && mv bootstrap ../../../$(BUILD_DIR)/BooksGetBookByIsbn/
	cd packages/books/searchBooks && $(GOBUILD) && mv bootstrap ../../../$(BUILD_DIR)/BooksSearchBooks/
	cd packages/libraries/createLibrary && $(GOBUILD) && mv bootstrap ../../../$(BUILD_DIR)/LibrariesCreateLibrary/
	cd packages/libraries/getLibraries && $(GOBUILD) && mv bootstrap ../../../$(BUILD_DIR)/LibrariesGetLibraries/
	cd packages/libraries/updateLibrary && $(GOBUILD) && mv bootstrap ../../../$(BUILD_DIR)/LibrariesUpdateLibrary/
	cd packages/libraries/deleteLibrary && $(GOBUILD) && mv bootstrap ../../../$(BUILD_DIR)/LibrariesDeleteLibrary/
	@for id in AuthSendOtp AuthVerifyOtp BooksGetBookByIsbn BooksSearchBooks LibrariesCreateLibrary LibrariesGetLibraries LibrariesUpdateLibrary LibrariesDeleteLibrary; do \
		printf 'build-%s:\n\tcp bootstrap $$(ARTIFACTS_DIR)/\n' "$$id" > $(BUILD_DIR)/$$id/Makefile; \
	done

# SAM build targets (used when CodeUri is .)
build-AuthSendOtp:
	cd packages/auth/sendOtp && $(GOBUILD) && cp bootstrap $(ARTIFACTS_DIR)/
build-AuthVerifyOtp:
	cd packages/auth/verifyOtp && $(GOBUILD) && cp bootstrap $(ARTIFACTS_DIR)/
build-BooksGetBookByIsbn:
	cd packages/books/getBookByIsbn && $(GOBUILD) && cp bootstrap $(ARTIFACTS_DIR)/
build-BooksSearchBooks:
	cd packages/books/searchBooks && $(GOBUILD) && cp bootstrap $(ARTIFACTS_DIR)/
build-LibrariesCreateLibrary:
	cd packages/libraries/createLibrary && $(GOBUILD) && cp bootstrap $(ARTIFACTS_DIR)/
build-LibrariesGetLibraries:
	cd packages/libraries/getLibraries && $(GOBUILD) && cp bootstrap $(ARTIFACTS_DIR)/
build-LibrariesUpdateLibrary:
	cd packages/libraries/updateLibrary && $(GOBUILD) && cp bootstrap $(ARTIFACTS_DIR)/
build-LibrariesDeleteLibrary:
	cd packages/libraries/deleteLibrary && $(GOBUILD) && cp bootstrap $(ARTIFACTS_DIR)/
