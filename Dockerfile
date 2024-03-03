# Set the base image to astralinux with a specific version
FROM registry.astralinux.ru/library/alse:1.7.3 AS builder

# Set the working directory in the Docker image
WORKDIR /usr/src/go

# Add specific go and roadrunner files to Docker image
COPY go1.21.3.linux-amd64.tar.gz  /go1.21.3.linux-amd64.tar.gz
COPY roadrunner_with_vendor_catalog.tar.gz /roadrunner_with_vendor_catalog.tar.gz

# Unpack the necessary files into their appropriate locations
RUN set -eux && \
    tar -xzvf /roadrunner_with_vendor_catalog.tar.gz -C /usr/src && \
    tar -xzvf /go1.21.3.linux-amd64.tar.gz -C /usr/local

# Update the PATH to include the go binaries
ENV PATH=$PATH:/usr/local/go/bin

# Set App version argument and expose it as an environment variable
ARG APP_VERSION="v2023.3"
ENV LDFLAGS="-s -X github.com/roadrunner-server/roadrunner/v2023/internal/meta.version=$APP_VERSION"

# Set the working directory to the roadrunner directory
WORKDIR /usr/src/roadrunner

# Turning on shell debugging in the following RUN commands for enhanced logging
RUN set -x

# Compile the roadrunner application
RUN CGO_ENABLED=0 go build -pgo=roadrunner.pprof -trimpath -ldflags "$LDFLAGS" -o ./rr ./cmd/rr

# Verify the version of roadrunner
RUN ./rr -v

FROM registry.astralinux.ru/library/alse:1.7.3

# copy required files from builder image
COPY --from=builder /usr/src/roadrunner/rr /usr/bin/rr
COPY --from=builder /usr/src/roadrunner/.rr.yaml /usr/bin/.rr.yaml

ENTRYPOINT ["/usr/bin/rr"]

#"-c", "/usr/local/bin/.rr.yaml"   -path to  config file
#CMD ["/usr/bin/rr", "serve", "-c", "/usr/bin/.rr.yaml"]
