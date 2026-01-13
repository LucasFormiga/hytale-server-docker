FROM eclipse-temurin:25-jdk-alpine

# Install dependencies
# gcompat: required for running standard glibc binaries (hytale-downloader) on Alpine
# libc6-compat: alternative/additional glibc compatibility
# su-exec: required for dropping privileges in entrypoint
RUN apk add --no-cache curl unzip bash su-exec gcompat libc6-compat libstdc++

# Create user 'hytale' with UID 1000
RUN addgroup -g 1000 hytale && \
    adduser -u 1000 -G hytale -h /hytale -D hytale

# Create data directory
RUN mkdir -p /hytale/data

# Ensure hytale user owns home and data
RUN chown -R hytale:hytale /hytale

# Set workdir
WORKDIR /hytale

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose port (UDP)
EXPOSE 5520/udp

# Volume for persistent data
VOLUME ["/hytale/data"]

# Entrypoint script handles startup logic
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

