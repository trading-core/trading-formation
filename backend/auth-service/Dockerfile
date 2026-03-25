# trading-formation/Dockerfile.auth-service
FROM golang:1.23-alpine AS builder
WORKDIR /workspace
RUN apk add --no-cache git
COPY trading-backend/go.mod trading-backend/go.sum ./
RUN go mod download
COPY trading-backend .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/auth-service ./cmd/auth-service

FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/auth-service ./auth-service
EXPOSE 9100
ENTRYPOINT ["/app/auth-service"]
