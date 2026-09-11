FROM golang:1.27 AS build

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -o /out/biltongssh .

FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /var/lib/biltongssh
COPY --from=build /out/biltongssh /biltongssh

EXPOSE 23234
ENTRYPOINT ["/biltongssh"]
