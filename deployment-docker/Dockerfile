FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install QGIS server and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg \
    ca-certificates \
    wget \
    curl \
    && add-apt-repository ppa:ubuntugis/ubuntugis-unstable \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    qgis-server \
    fcgiwrap \
    spawn-fcgi \
    nginx \
    xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directories for QGIS Server
RUN mkdir -p /etc/qgisserver /var/log/qgis /var/lib/qgisserver/data

# Create authentication DB directory with correct permissions
RUN mkdir -p /var/lib/qgis/.local/share/QGIS/QGIS3/profiles/default/qgis-auth.db/ && \
    chmod -R 777 /var/lib/qgis/

# Configure nginx - ensure default config is removed
RUN rm -f /etc/nginx/sites-enabled/default && \
    rm -f /etc/nginx/conf.d/default.conf

# Copy and verify nginx config
COPY nginx-qgis.conf /etc/nginx/conf.d/qgis-server.conf
RUN nginx -t -c /etc/nginx/nginx.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create volume mount points
VOLUME /etc/qgisserver
VOLUME /var/lib/qgisserver/data

# Expose port 80
EXPOSE 80

# Set default environment variables
ENV QGIS_PROJECT_FILE=/etc/qgisserver/world_map.qgs
ENV QGIS_SERVER_LOG_LEVEL=0
ENV QGIS_AUTH_DB_DIR_PATH=/var/lib/qgis/.local/share/QGIS/QGIS3/profiles/default/qgis-auth.db/

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost/qgis/qgis_mapserv.fcgi?SERVICE=WMS&REQUEST=GetCapabilities || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
