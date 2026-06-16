# Simple production image serving pre-built web files with nginx
FROM nginx:alpine

# Copy the pre-built web files from the runner build directory
COPY build/web /usr/share/nginx/html

# Remove default nginx config and use our custom one
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/veritask.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
