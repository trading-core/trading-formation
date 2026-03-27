# trading-formation/Dockerfile.account-service
FROM golang:1.23-alpine AS builder
WORKDIR /workspace
RUN apk add --no-cache git
COPY trading-backend/go.mod trading-backend/go.sum ./
RUN go mod download
COPY trading-backend .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/account-service ./cmd/account-service

FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/account-service ./account-service
EXPOSE 9000
ENTRYPOINT ["/app/account-service"]
