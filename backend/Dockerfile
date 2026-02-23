FROM golang:1.20-alpine

WORKDIR /app

COPY packages/books/getBookByIsbn/go.mod packages/books/getBookByIsbn/go.sum ./
RUN go mod download && go mod verify

COPY packages/books/getBookByIsbn/ .

# Generate the main.go file for development
# In production, not needed as DigitalOcean will look for the Main function directly
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
