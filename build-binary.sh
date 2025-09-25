#!/bin/bash
set -e

echo "🚀 Building FrankenPHP standalone binary..."

# Build the Docker image with the Laravel app
echo "📦 Building Docker image..."
docker build -f static-build.Dockerfile -t franken-laravel-static .

# Create a temporary container to extract the binary
echo "📤 Extracting binary from container..."
CONTAINER_ID=$(docker create franken-laravel-static)

# Extract the binary (FrankenPHP static builder creates it at /go/src/app/dist/*)
# First, let's see what's in the dist directory
echo "🔍 Looking for binary in container..."
docker run --rm franken-laravel-static find /go/src/app -type f -executable 2>/dev/null | head -10 || true

# Extract the embedded binary (it should be the frankenphp file in the app directory)
docker cp "$CONTAINER_ID:/go/src/app/dist/app/frankenphp" ./franken-laravel 2>/dev/null || {
    echo "❌ Binary not found at expected location"
    echo "🔍 Looking for the binary..."
    docker run --rm franken-laravel-static find /go -name "*franken*" -type f -executable 2>/dev/null | head -5
    exit 1
}

# Clean up the temporary container
docker rm "$CONTAINER_ID"

# Make the binary executable
chmod +x franken-laravel

# Get binary size for reporting
BINARY_SIZE=$(du -h franken-laravel | cut -f1)

echo "✅ Binary created successfully!"
echo "📊 Binary size: $BINARY_SIZE"
echo "🏃 To run the binary:"
echo "   ./franken-laravel php-server --listen :8000 --root public"
echo ""
echo "💡 With custom storage path:"
echo "   export LARAVEL_STORAGE_PATH=/custom/path"
echo "   ./franken-laravel php-server --listen :8000 --root public"