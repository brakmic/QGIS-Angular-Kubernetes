# QgisMapViewer

QgisMapViewer is an interactive web map viewer built with Angular and OpenLayers. It is designed to work with a QGIS server to dynamically query and display geospatial data via WMS services. The app enables users to switch between different map layers and provides a smooth, responsive interface for exploring mapping data.

## Features

- **Interactive Mapping**: Built with OpenLayers, the viewer can display high-quality maps.
- **Dynamic WMS Integration**: Query and render QGIS server layers on demand.
- **Layer Selection**: Users can select various layers to view, with smooth transitions and dynamic queries.
- **Responsive & Modern UI**: Developed using Angular CLI for a fast user experience.

## Development

### Running the Local Development Server

To start a local development server, run:

```bash
ng serve
```

Open your browser and navigate to [http://localhost:4200/](http://localhost:4200/). The application will automatically reload when you modify any source files.

### Code Scaffolding

Angular CLI provides powerful code scaffolding tools. To generate a new component, run:

```bash
ng generate component component-name
```

For a complete list of available schematics (such as components, directives, or pipes), run:

```bash
ng generate --help
```

## Building the Project

To build the project for production, run:

```bash
ng build --configuration production
```

This command compiles your project and stores the build artifacts in `dist/qgis-map-viewer/browser`. The production build optimizes your application for performance and speed.

## Docker Deployment

QgisMapViewer is containerized using a multi-stage Docker build that compiles the Angular app and serves the production artifacts via NGINX.

### Building the Docker Image

Make sure you have Docker installed. From the project root, run:

```bash
docker build -t your-docker-repo/qgis-viewer:latest .
```

> **Note:** Replace `your-docker-repo/qgis-viewer` with your actual Docker repository and image name.

### Running the Docker Container

After building the image, run the container with:

```bash
docker run -d -p 80:80 your-docker-repo/qgis-viewer:latest
```

The application will be available at [http://localhost](http://localhost).

## Running Tests

### Unit Tests

To run unit tests with Karma, execute:

```bash
ng test
```

### End-to-End Tests

For end-to-end (e2e) testing, run:

```bash
ng e2e
```

*(Angular CLI does not include an e2e testing framework by default, so choose one that suits your requirements.)*

## Additional Resources

For more details on using Angular CLI, visit the [Angular CLI Overview and Command Reference](https://angular.dev/tools/cli) page.

---

QgisMapViewer is built specifically for integrating with QGIS server services, delivering dynamic map layers and interactive geospatial queries.
