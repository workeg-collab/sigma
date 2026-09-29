# ==========================================
# Stage 1: Build Flutter Web Application
# ==========================================
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Enable web support
RUN flutter config --enable-web

# Copy dependency specifications first to leverage Docker layer caching
COPY pubspec.yaml ./

# Fetch dependencies
RUN flutter pub get

# Copy the rest of the application source code
COPY . .

# Ensure SQLite web worker and wasm are generated
RUN dart run sqflite_common_ffi_web:setup

# Build the web bundle in release mode
RUN flutter build web --release

# Copy worker and wasm files to build output
RUN cp -f web/sqflite_sw.js build/web/ 2>/dev/null || true
RUN cp -f web/sqlite3.wasm build/web/ 2>/dev/null || true

# ==========================================
# Stage 2: Production Nginx Server
# ==========================================
FROM nginx:alpine

# Clean default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled Flutter web app from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose standard port for Coolify
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
