# Multi-stage build: First stage for building assets
FROM node:20-alpine AS node-builder

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci --cache /tmp/empty-cache

# Copy source files and build assets
COPY . .
RUN npm run build

# Main stage: FrankenPHP static builder with required extensions
FROM --platform=linux/amd64 dunglas/frankenphp:static-builder

# Copy the Laravel application
COPY . /go/src/app/dist/app

# Copy built assets from node-builder stage
COPY --from=node-builder /app/public/build /go/src/app/dist/app/public/build

# Set working directory
WORKDIR /go/src/app/dist/app

# Install PHP dependencies (production only)
# The FrankenPHP static builder will build the binary with necessary PHP extensions
# but Composer doesn't know about them during build time, so we ignore platform requirements
RUN composer install --no-dev --optimize-autoloader --no-scripts \
    --ignore-platform-req=ext-fileinfo \
    --ignore-platform-req=ext-iconv

# Generate optimized autoloader
RUN composer dump-autoload --optimize --classmap-authoritative

# Cache Laravel configuration, routes, and views for better performance
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# Set proper permissions for Laravel directories
RUN chmod -R 755 storage bootstrap/cache

# The FrankenPHP static builder will automatically create the binary
# with the Laravel application embedded