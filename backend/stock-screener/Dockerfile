# trading-formation/Dockerfile.stock-screener
FROM golang:1.25-alpine AS builder
WORKDIR /workspace
RUN apk add --no-cache git
COPY trading-backend/go.mod trading-backend/go.sum ./
RUN go mod download
COPY trading-backend .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/stock-screener ./cmd/stock-screener

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/stock-screener ./stock-screener
EXPOSE 8080
ENTRYPOINT ["/app/stock-screener"]
