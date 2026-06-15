# Build Flutter web and serve with nginx
FROM cirrusci/flutter:stable as builder

WORKDIR /app

# Copy pubspec and get dependencies first for caching
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the app
COPY . ./

# Build web release
RUN flutter build web --release

# Production image
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html

# Remove default nginx config and use a minimal one
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/veritask.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
