# We need to build aptly from source for arm64
FROM golang:latest as build
WORKDIR /src

RUN git clone https://github.com/aptly-dev/aptly /src/aptly
RUN cd /src/aptly && make modules && go generate && CGO_ENABLED=0 GOSTATIC=1 go build -o /aptly main.go

# we want a relatively minimal container
FROM alpine:3.19

RUN apk add --no-cache tini gnupg bzip2 gpgv xz
ENTRYPOINT ["/sbin/tini", "--"]

COPY --from=build /aptly /bin/aptly
COPY aptly.conf /etc/aptly.conf

RUN mkdir /opt/aptly
ENV GNUPGHOME="/opt/aptly/gpg"

EXPOSE 8080

WORKDIR /opt/aptly

CMD ["/bin/aptly", "api", "serve", "-listen=:8080", "-no-lock"]