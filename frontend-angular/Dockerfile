# Stage 1: Build the Angular app
FROM node:22 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# Use the production configuration (AOT + optimizations)
RUN npm run build -- --configuration production

# Stage 2: Serve the Angular app with NGINX
FROM nginx:alpine
# Remove the default NGINX website
RUN rm -rf /usr/share/nginx/html/*
# Copy Angular artifacts from the builder stage
COPY --from=builder /app/dist/qgis-map-viewer/browser/ /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
