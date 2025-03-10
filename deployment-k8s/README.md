# QGIS Server Kubernetes Deployment

## Overview

This directory contains Kubernetes deployment configurations and scripts for deploying QGIS Server along with a web-based map viewer. The setup provides two different deployment options that achieve functionally equivalent results but with different implementation approaches:

1. **Full Deployment** (`deploy.sh`) - Uses pre-built Docker images for both QGIS Server and the Angular-based map viewer
2. **Simple Deployment** (`deploy.simple.sh`) - Uses the QGIS Server Docker image but deploys a simpler HTML/JS/CSS web viewer directly from ConfigMaps

Both deployment options expose the same functionality: a web interface that allows users to view and switch between different map layers served by QGIS Server.

## Deployment Options

### Option 1: Full Deployment (deploy.sh)

The full deployment uses containerized applications for both QGIS Server and the Angular-based viewer.

**Features:**
- Deploys QGIS Server from `brakmic/qgis-server:latest` image
- Deploys Angular-based viewer from `brakmic/qgis-viewer:latest` image
- More sophisticated UI capabilities through Angular
- Better code organization and maintainability for complex features
- Optional ability to build and push the viewer image (`BUILD_VIEWER_IMAGE` flag)

**Usage:**
```bash
./deploy.sh
```

### Option 2: Simple Deployment (deploy.simple.sh)

The simple deployment uses ConfigMaps to deploy a lightweight HTML/JS/CSS viewer application.

**Features:**
- Same QGIS Server deployment as Option 1
- Creates ConfigMaps from static HTML, JS, and CSS files in the `../frontend-simple/` directory
- Simpler implementation with vanilla JavaScript
- No need to build Docker images for the viewer component
- Easier to make quick changes to the viewer

**Usage:**
```bash
./deploy.simple.sh
```

## Key Components

### QGIS Server

Both deployment options use the same QGIS Server setup:

- Based on `brakmic/qgis-server:latest` Docker image
- Uses the world_map.qgs project file from ConfigMap
- Exposes map layers through WMS
- Configured through environment variables and NGINX
- Handles various data formats for Natural Earth geographic data

### Map Viewer

The primary difference between the deployment options is in the map viewer implementation:

#### Angular-based Viewer (Full Deployment)
- Pre-built Docker image with Angular application
- Used in the deployment.yaml
- More complex application structure
- Reactive updates through Angular signals
- Managed as a complete web application

#### Simple Viewer (Simple Deployment)
- Basic HTML/JS/CSS files stored in ConfigMaps
- Used in the deployment.simple.yaml
- Creates ConfigMaps on-the-fly from files in `../frontend-simple/` directory
- Vanilla JavaScript implementation
- Simpler but less scalable for complex functionality

## Deployment Files

### Common Files
- deployment.yaml - QGIS Server deployment
- service.yaml - QGIS Server service
- ingress.yaml - Ingress configurations for both components
- `config/*.yaml` - ConfigMaps for NGINX configuration, entrypoint scripts, etc.

### Full Deployment
- deployment.yaml - Angular viewer deployment
- service.yaml - Viewer service

### Simple Deployment
- deployment.simple.yaml - Simple viewer deployment with ConfigMap volumes
- Multiple ConfigMaps created dynamically from the HTML/JS/CSS files

## How the Deployments Work

### Full Deployment (deploy.sh)

1. Creates namespace `qgis-system`
2. Checks and installs ingress controller if needed
3. Creates ConfigMaps for NGINX config, entrypoint script, etc.
4. Creates ConfigMap from the QGIS project file
5. Deploys QGIS Server using deployment.yaml
6. Optionally builds and pushes the viewer Docker image
7. Deploys viewer using deployment.yaml
8. Applies services and ingress configurations
9. Waits for pods to be ready

### Simple Deployment (deploy.simple.sh)

1. Creates namespace `qgis-system`
2. Checks and installs ingress controller if needed
3. Creates ConfigMaps for NGINX config, entrypoint script, etc.
4. Creates ConfigMaps from the QGIS project file
5. Creates ConfigMaps from HTML, JS, and CSS files in the `../frontend-simple/` directory
6. Deploys QGIS Server using deployment.yaml
7. Deploys viewer using deployment.simple.yaml which mounts the HTML/JS/CSS ConfigMaps
8. Applies services and ingress configurations
9. Waits for pods to be ready

## Key Differences

| Feature | Full Deployment | Simple Deployment |
|---------|----------------|-------------------|
| Viewer Implementation | Angular | Vanilla JavaScript |
| Packaging | Docker Images | ConfigMaps |
| Source Code Location | Angular app in `/qgis-map-viewer/` | Static files in `/frontend-simple/` |
| Deployment Mechanism | Container image | ConfigMaps mounted in container |
| Development Experience | Angular dev workflow | Simple file edits |
| Complexity | Higher | Lower |
| Maintainability | Better for complex apps | Simpler for basic features |
| Updates | Requires rebuilding image | Just update ConfigMaps |

## Functional Equivalence

Despite the implementation differences, both deployment options provide the same core functionality:
- Display a web interface with a dropdown to select map layers
- Show OpenStreetMap as the base layer
- Allow overlaying different geographic layers from QGIS Server
- Access the application via the same URL (`http://qgis.local/`)
- Access QGIS Server at the same endpoint (`http://qgis.local/qgis/qgis_mapserv.fcgi`)

## Accessing the Application

After deployment, the application can be accessed at:
- Map Viewer: `http://qgis.local/`
- QGIS Server: `http://qgis.local/qgis/qgis_mapserv.fcgi?SERVICE=WMS&REQUEST=GetCapabilities`
