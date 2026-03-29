# trading-formation/backend/bot-service/Dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /workspace
RUN apk add --no-cache git
COPY trading-backend/go.mod trading-backend/go.sum ./
RUN go mod download
COPY trading-backend .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/bot-service ./cmd/bot-service

FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/bot-service ./bot-service
EXPOSE 8080
ENTRYPOINT ["/app/bot-service"]
