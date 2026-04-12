# trading-formation/backend/reporting-service/Dockerfile
FROM golang:1.25-alpine AS builder
WORKDIR /workspace
RUN apk add --no-cache git
COPY trading-backend/go.mod trading-backend/go.sum ./
RUN go mod download
COPY trading-backend .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/reporting-service ./cmd/reporting-service

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/reporting-service ./reporting-service
EXPOSE 8082
ENTRYPOINT ["/app/reporting-service"]
