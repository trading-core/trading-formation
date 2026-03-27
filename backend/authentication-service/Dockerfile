# trading-formation/Dockerfile.authentication-service
FROM golang:1.23-alpine AS builder
WORKDIR /workspace
RUN apk add --no-cache git
COPY trading-backend/go.mod trading-backend/go.sum ./
RUN go mod download
COPY trading-backend .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/authentication-service ./cmd/authentication-service

FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/authentication-service ./authentication-service
EXPOSE 9100
ENTRYPOINT ["/app/authentication-service"]
