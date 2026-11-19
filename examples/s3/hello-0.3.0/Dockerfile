FROM golang:1.27 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /server .

FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=build /server /server
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/server"]
