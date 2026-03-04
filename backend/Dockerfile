FROM golang:1.25-alpine

WORKDIR /app
COPY lib /app/lib
COPY packages/books/getBookByIsbn /app/packages/books/getBookByIsbn

WORKDIR /app/packages/books/getBookByIsbn
RUN go mod download

# Generate main.go for local/Docker runs
RUN printf 'package main\n\
\n\
import (\n\
	"context"\n\
	"os"\n\
	"biblio-api/types"\n\
)\n\
\n\
func main() {\n\
	Main(context.Background(), types.Event{Isbn: os.Args[1]})\n\
}\n' > main.go

RUN go build -o getBookByIsbn .

ENTRYPOINT ["./getBookByIsbn"]
