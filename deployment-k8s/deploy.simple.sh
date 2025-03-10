#!/usr/bin/env bash

# Command variables
DOCKER="sudo docker"
KUBECTL="sudo kubectl"
NAMESPACE="qgis-system"
IMAGE_NAME="brakmic/qgis-server"
IMAGE_TAG="latest"
BASE_PATH="/host_workspace/scratchpad/qgis-test"
KUBE_PATH="${BASE_PATH}/k8s"
CONFIG_PATH="${BASE_PATH}/config"
VIEWER_PATH="${BASE_PATH}/simple-viewer"
PROJECT_DIR="${BASE_PATH}/projects"
DATA_DIR="${BASE_PATH}/data"
PROJECT_FILE="${PROJECT_DIR}/world_map.qgs"
PROJECT_CONFIGMAP="qgis-project-file"
INGRESS_CONTROLLER_VERSION="v1.12.0"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Emoji indicators
EMOJI_INFO="ℹ️"
EMOJI_SUCCESS="✅"
EMOJI_WARNING="⚠️"
EMOJI_ERROR="❌"
EMOJI_CLOCK="🕒"
EMOJI_ROCKET="🚀"
EMOJI_GEAR="⚙️"
EMOJI_DEPLOY="📦"
EMOJI_TEST="🧪"
EMOJI_MAP="🗺️"
EMOJI_SERVER="🖥️"
EMOJI_CHECK="✓"
EMOJI_FILES="📁"

# Print status messages
print_status() {
  local emoji=$1
  local color=$2
  local message=$3
  echo -e "${color}${emoji} ${message}${NC}"
}

# Print section headers
print_section() {
  local emoji=$1
  local message=$2
  echo -e "\n${BOLD}${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${BLUE}${emoji} ${message}${NC}"
  echo -e "${BOLD}${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Run kubectl with minimal output
kubectl_quiet() {
  $KUBECTL "$@" > /dev/null 2>&1
}

# Print progress indicator
show_spinner() {
  local pid=$1
  local delay=0.25
  local spinstr='|/-\'
  local message=$2
  
  echo -ne "${CYAN}${message}${NC} "
  
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]" "$spinstr"
    sleep $delay
    printf "\b\b\b\b"
    spinstr=$temp${spinstr%"$temp"}
  done
  echo -e "${GREEN}${EMOJI_SUCCESS} Done!${NC}"
}

# Check if ingress controller is installed
check_ingress_controller() {
  print_status "$EMOJI_INFO" "$BLUE" "Checking for ingress-nginx controller..."
  
  if kubectl_quiet get namespace ingress-nginx && \
     kubectl_quiet get pods -n ingress-nginx -l app.kubernetes.io/component=controller; then
    print_status "$EMOJI_SUCCESS" "$GREEN" "Ingress-nginx controller found."
    return 0
  else
    print_status "$EMOJI_WARNING" "$YELLOW" "Ingress-nginx controller not found. Will install it."
    return 1
  fi
}

# Install ingress controller
install_ingress_controller() {
  print_section "$EMOJI_DEPLOY" "Installing ingress-nginx controller"
  
  print_status "$EMOJI_GEAR" "$CYAN" "Applying ingress-nginx manifests..."
  $KUBECTL apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${INGRESS_CONTROLLER_VERSION}/deploy/static/provider/cloud/deploy.yaml > /dev/null
  
  print_status "$EMOJI_CLOCK" "$CYAN" "Waiting for ingress controller pods to be ready..."
  
  # Run wait command in background and show spinner
  $KUBECTL wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s > /dev/null 2>&1 &
  
  show_spinner $! "Preparing ingress controller"
  
  # Check if the wait was successful
  if ! kubectl_quiet get pod -n ingress-nginx -l app.kubernetes.io/component=controller; then
    print_status "$EMOJI_INFO" "$BLUE" "You may need to use port-forwarding if ingress doesn't work."
  fi
  
  # Add qgis.local to /etc/hosts if it's not already there
  if ! grep -q "qgis.local" /etc/hosts; then
    echo "127.0.0.1 qgis.local" | sudo tee -a /etc/hosts > /dev/null
  fi
  
  print_status "$EMOJI_SUCCESS" "$GREEN" "Ingress controller installation completed."
}

# Create a ConfigMap from a file with helpful logging
create_configmap_from_file() {
  local name=$1
  local file_path=$2
  local file_param=$3

  print_status "$EMOJI_FILES" "$CYAN" "Creating ConfigMap ${BOLD}${name}${NC} from file: $(basename $file_path)"
  
  # Check if the file exists
  if [ ! -f "$file_path" ]; then
    print_status "$EMOJI_ERROR" "$RED" "File not found: $file_path"
    return 1
  fi
  
  # Delete the ConfigMap if it already exists
  if kubectl_quiet get configmap ${name} -n ${NAMESPACE}; then
    kubectl_quiet delete configmap ${name} -n ${NAMESPACE}
  fi
  
  # Create the ConfigMap
  if [ -z "$file_param" ]; then
    $KUBECTL create configmap ${name} --from-file=${file_path} -n ${NAMESPACE} > /dev/null
  else
    $KUBECTL create configmap ${name} --from-file=${file_param}=${file_path} -n ${NAMESPACE} > /dev/null
  fi
  
  if [ $? -eq 0 ]; then
    print_status "$EMOJI_SUCCESS" "$GREEN" "ConfigMap ${name} created successfully."
    return 0
  else
    print_status "$EMOJI_ERROR" "$RED" "Failed to create ConfigMap ${name}."
    return 1
  fi
}

# Create a ConfigMap from a directory with helpful logging
create_configmap_from_dir() {
  local name=$1
  local dir_path=$2

  print_status "$EMOJI_FILES" "$CYAN" "Creating ConfigMap ${BOLD}${name}${NC} from directory: $(basename $dir_path)"
  
  # Check if the directory exists
  if [ ! -d "$dir_path" ]; then
    print_status "$EMOJI_WARNING" "$YELLOW" "Directory not found: $dir_path"
    return 1
  fi
  
  # Delete the ConfigMap if it already exists
  if kubectl_quiet get configmap ${name} -n ${NAMESPACE}; then
    kubectl_quiet delete configmap ${name} -n ${NAMESPACE}
  fi
  
  # Create the ConfigMap
  $KUBECTL create configmap ${name} --from-file=${dir_path} -n ${NAMESPACE} > /dev/null
  
  if [ $? -eq 0 ]; then
    print_status "$EMOJI_SUCCESS" "$GREEN" "ConfigMap ${name} created successfully."
    return 0
  else
    print_status "$EMOJI_ERROR" "$RED" "Failed to create ConfigMap ${name}."
    return 1
  fi
}

# Begin deployment
print_section "$EMOJI_ROCKET" "QGIS Server Kubernetes Deployment"
print_status "$EMOJI_SERVER" "$CYAN" "Starting deployment of ${BOLD}${IMAGE_NAME}:${IMAGE_TAG}${NC} to namespace ${BOLD}${NAMESPACE}${NC}"

# Verify required directories exist
if [ ! -d "$PROJECT_DIR" ]; then
    print_status "$EMOJI_WARNING" "$YELLOW" "Projects directory doesn't exist: Creating it now..."
    mkdir -p "$PROJECT_DIR"
else
    print_status "$EMOJI_CHECK" "$GREEN" "Projects directory found."
fi

if [ ! -d "$DATA_DIR" ]; then
    print_status "$EMOJI_WARNING" "$YELLOW" "Data directory doesn't exist: Creating it now..."
    mkdir -p "$DATA_DIR"
else
    print_status "$EMOJI_CHECK" "$GREEN" "Data directory found."
fi

# Verify project file exists and has correct permissions
if [ ! -f "$PROJECT_FILE" ]; then
    print_status "$EMOJI_ERROR" "$RED" "QGIS project file not found: $(basename "$PROJECT_FILE")"
    print_status "$EMOJI_INFO" "$BLUE" "Please place a valid .qgs file at: $PROJECT_DIR"
    exit 1
else
    print_status "$EMOJI_SUCCESS" "$GREEN" "QGIS project file found: $(basename "$PROJECT_FILE")"
    chmod 644 "$PROJECT_FILE" > /dev/null 2>&1
fi

# Check if namespace exists before trying to delete it
print_section "$EMOJI_GEAR" "Preparing Kubernetes Environment"

if kubectl_quiet get namespace ${NAMESPACE}; then
    print_status "$EMOJI_INFO" "$BLUE" "Namespace ${BOLD}${NAMESPACE}${NC} exists, deleting..."
    $KUBECTL delete namespace ${NAMESPACE} --wait=false > /dev/null
    
    # Wait for namespace deletion with progress indication
    timeout=60
    start_time=$(date +%s)
    print_status "$EMOJI_CLOCK" "$CYAN" "Waiting for namespace deletion to complete..."
    
    while kubectl_quiet get namespace ${NAMESPACE}; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        
        if [ $elapsed_time -gt $timeout ]; then
            print_status "$EMOJI_WARNING" "$YELLOW" "Namespace deletion timeout after ${timeout} seconds."
            print_status "$EMOJI_INFO" "$BLUE" "Proceeding with deployment anyway."
            break
        fi
        
        sleep 3
        echo -ne "${CYAN}${EMOJI_CLOCK} Waiting: ${elapsed_time}s elapsed\r${NC}"
    done
    echo -ne "\n"
    sleep 3
else
    print_status "$EMOJI_INFO" "$BLUE" "Namespace ${BOLD}${NAMESPACE}${NC} does not exist."
fi

print_status "$EMOJI_GEAR" "$CYAN" "Creating namespace ${BOLD}${NAMESPACE}${NC}..."
$KUBECTL create namespace ${NAMESPACE} > /dev/null

# Check and install ingress controller if needed
if ! check_ingress_controller; then
    install_ingress_controller
fi

print_section "$EMOJI_DEPLOY" "Creating ConfigMaps from External Files"

# Create favicon ConfigMap
print_status "$EMOJI_FILES" "$CYAN" "Creating favicon ConfigMap..."
kubectl_quiet apply -f ${KUBE_PATH}/config/favicon-configmap.yaml -n ${NAMESPACE}

if [ $? -eq 0 ]; then
    print_status "$EMOJI_SUCCESS" "$GREEN" "Favicon ConfigMap created successfully."
else
    print_status "$EMOJI_ERROR" "$RED" "Failed to create favicon ConfigMap."
    exit 1
fi

# Create QGIS nginx config ConfigMap
print_status "$EMOJI_FILES" "$CYAN" "Creating QGIS nginx config..."
kubectl_quiet apply -f ${KUBE_PATH}/config/qgis-nginx-configmap.yaml -n ${NAMESPACE}

if [ $? -eq 0 ]; then
    print_status "$EMOJI_SUCCESS" "$GREEN" "QGIS nginx config created successfully."
else
    print_status "$EMOJI_ERROR" "$RED" "Failed to create QGIS nginx config."
    exit 1
fi

# Create ConfigMap for HTML file
print_status "$EMOJI_FILES" "$CYAN" "Creating viewer HTML ConfigMap..."
kubectl_quiet delete configmap qgis-viewer-html -n ${NAMESPACE} 2>/dev/null || true

if [ -f "${VIEWER_PATH}/index.html" ]; then
    $KUBECTL create configmap qgis-viewer-html --from-file=index.html=${VIEWER_PATH}/index.html -n ${NAMESPACE} > /dev/null
    
    if [ $? -eq 0 ]; then
        print_status "$EMOJI_SUCCESS" "$GREEN" "Viewer HTML ConfigMap created successfully."
    else
        print_status "$EMOJI_ERROR" "$RED" "Failed to create viewer HTML ConfigMap."
        exit 1
    fi
else
    print_status "$EMOJI_ERROR" "$RED" "HTML file not found: ${VIEWER_PATH}/index.html"
    exit 1
fi

# Create ConfigMap for JS files
print_status "$EMOJI_FILES" "$CYAN" "Creating viewer JS ConfigMap..."
kubectl_quiet delete configmap qgis-viewer-js -n ${NAMESPACE} 2>/dev/null || true

if [ -f "${VIEWER_PATH}/js/main.js" ]; then
    $KUBECTL create configmap qgis-viewer-js --from-file=main.js=${VIEWER_PATH}/js/main.js -n ${NAMESPACE} > /dev/null
    
    if [ $? -eq 0 ]; then
        print_status "$EMOJI_SUCCESS" "$GREEN" "Viewer JS ConfigMap created successfully."
    else
        print_status "$EMOJI_ERROR" "$RED" "Failed to create viewer JS ConfigMap."
        exit 1
    fi
else
    print_status "$EMOJI_ERROR" "$RED" "JS file not found: ${VIEWER_PATH}/js/main.js"
    exit 1
fi

# Create ConfigMap for CSS files
print_status "$EMOJI_FILES" "$CYAN" "Creating viewer CSS ConfigMap..."
kubectl_quiet delete configmap qgis-viewer-css -n ${NAMESPACE} 2>/dev/null || true

if [ -f "${VIEWER_PATH}/css/main.css" ]; then
    $KUBECTL create configmap qgis-viewer-css --from-file=main.css=${VIEWER_PATH}/css/main.css -n ${NAMESPACE} > /dev/null
    
    if [ $? -eq 0 ]; then
        print_status "$EMOJI_SUCCESS" "$GREEN" "Viewer CSS ConfigMap created successfully."
    else
        print_status "$EMOJI_ERROR" "$RED" "Failed to create viewer CSS ConfigMap."
        exit 1
    fi
else
    print_status "$EMOJI_ERROR" "$RED" "CSS file not found: ${VIEWER_PATH}/css/main.css"
    exit 1
fi

# Create entrypoint script ConfigMap
print_status "$EMOJI_FILES" "$CYAN" "Creating entrypoint script ConfigMap..."
kubectl_quiet apply -f ${KUBE_PATH}/config/qgis-entrypoint-configmap.yaml -n ${NAMESPACE}

if [ $? -eq 0 ]; then
    print_status "$EMOJI_SUCCESS" "$GREEN" "Entrypoint script ConfigMap created successfully."
else
    print_status "$EMOJI_ERROR" "$RED" "Failed to create entrypoint script ConfigMap."
    exit 1
fi

# Deploy viewer NGINX config
print_status "$EMOJI_FILES" "$CYAN" "Applying viewer NGINX configuration..."
kubectl_quiet apply -f ${KUBE_PATH}/viewer/nginx-configmap.yaml -n ${NAMESPACE}

if [ $? -eq 0 ]; then
    print_status "$EMOJI_SUCCESS" "$GREEN" "Viewer NGINX config created successfully."
else
    print_status "$EMOJI_ERROR" "$RED" "Failed to create viewer NGINX config."
    exit 1
fi

# Create ConfigMap from the QGIS project file
create_configmap_from_file "${PROJECT_CONFIGMAP}" "${PROJECT_FILE}" "world_map.qgs"

print_section "$EMOJI_DEPLOY" "Deploying QGIS Server Components"

# Apply the QGIS server deployment with retries
print_status "$EMOJI_DEPLOY" "$CYAN" "Deploying QGIS server..."
MAX_ATTEMPTS=3
attempt=1

while [ $attempt -le $MAX_ATTEMPTS ]; do
    kubectl_quiet apply -f ${KUBE_PATH}/qgis-server/deployment.yaml -n ${NAMESPACE}
    
    if [ $? -eq 0 ]; then
        print_status "$EMOJI_SUCCESS" "$GREEN" "QGIS server deployment created successfully."
        break
    else
        print_status "$EMOJI_WARNING" "$YELLOW" "Deployment failed (attempt $attempt/$MAX_ATTEMPTS), retrying..."
        attempt=$((attempt + 1))
        sleep 3
    fi
done

if [ $attempt -gt $MAX_ATTEMPTS ]; then
    print_status "$EMOJI_ERROR" "$RED" "Failed to deploy QGIS server after $MAX_ATTEMPTS attempts."
    exit 1
fi

# Deploy viewer
print_status "$EMOJI_DEPLOY" "$CYAN" "Deploying map viewer..."
kubectl_quiet apply -f ${KUBE_PATH}/viewer/deployment.simple.yaml -n ${NAMESPACE}

if [ $? -eq 0 ]; then
    print_status "$EMOJI_SUCCESS" "$GREEN" "Map viewer deployment created successfully."
else
    print_status "$EMOJI_ERROR" "$RED" "Failed to deploy map viewer."
    exit 1
fi

# Deploy viewer service
print_status "$EMOJI_GEAR" "$CYAN" "Creating viewer service..."
kubectl_quiet apply -f ${KUBE_PATH}/viewer/service.yaml -n ${NAMESPACE}

if [ $? -eq 0 ]; then
    print_status "$EMOJI_SUCCESS" "$GREEN" "Viewer service created successfully."
else
    print_status "$EMOJI_ERROR" "$RED" "Failed to create viewer service."
    exit 1
fi

# Deploy QGIS server service
print_status "$EMOJI_GEAR" "$CYAN" "Creating QGIS server service..."
kubectl_quiet apply -f ${KUBE_PATH}/qgis-server/service.yaml -n ${NAMESPACE}

# Deploy ingress
print_status "$EMOJI_GEAR" "$CYAN" "Creating Ingress resources..."
kubectl_quiet apply -f ${KUBE_PATH}/network/ingress.yaml -n ${NAMESPACE}

# Apply storage class
print_status "$EMOJI_GEAR" "$CYAN" "Applying storage class..."
kubectl_quiet apply -f ${KUBE_PATH}/common/storage-class.yaml

# Wait for QGIS server to be ready
print_section "$EMOJI_CLOCK" "Waiting for QGIS Server Pod to be Ready"
print_status "$EMOJI_INFO" "$BLUE" "This may take a minute or two for the container to start..."

# Run wait command in background with spinner
$KUBECTL wait --for=condition=ready pod -l app=qgis-server -n ${NAMESPACE} --timeout=180s > /dev/null 2>&1 &
wait_pid=$!
show_spinner $wait_pid "Starting QGIS server"

# Check if the wait was successful
if ! kubectl_quiet get pod -l app=qgis-server -n ${NAMESPACE}; then
    print_status "$EMOJI_ERROR" "$RED" "QGIS server pod not found or not ready."
    exit 1
else
    print_status "$EMOJI_SUCCESS" "$GREEN" "QGIS server is ready."
fi

# Wait for viewer pod to be ready
print_status "$EMOJI_CLOCK" "$CYAN" "Waiting for viewer pod to be ready..."
$KUBECTL wait --for=condition=ready pod -l app=qgis-viewer -n ${NAMESPACE} --timeout=60s > /dev/null 2>&1 &
wait_pid=$!
show_spinner $wait_pid "Starting QGIS viewer"

# Print final status with clean formatting
print_section "$EMOJI_MAP" "QGIS Server Status"

# Format pod status
echo -e "${CYAN}Pods:${NC}"
$KUBECTL get pods -n ${NAMESPACE} -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount" | head -20

# Format services
echo -e "\n${CYAN}Services:${NC}"
$KUBECTL get services -n ${NAMESPACE} -o custom-columns="NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,PORT(S):.spec.ports[*].port" | head -20

# Format ingress
echo -e "\n${CYAN}Ingress:${NC}"
$KUBECTL get ingress -n ${NAMESPACE} -o custom-columns="NAME:.metadata.name,HOSTS:.spec.rules[*].host,PATHS:.spec.rules[*].http.paths[*].path" | head -20

# Print summary
print_section "$EMOJI_ROCKET" "Deployment Complete!"

# Use simpler formatting for final sections to prevent terminal issues
printf "${BOLD}${GREEN}QGIS Server has been deployed successfully!${NC}\n\n"
printf "${BOLD}Access Options:${NC}\n"
printf "${GREEN}${EMOJI_CHECK}${NC} ${CYAN}Via ingress:${NC} http://qgis.local/qgis/qgis_mapserv.fcgi?SERVICE=WMS&REQUEST=GetCapabilities\n"
printf "${GREEN}${EMOJI_CHECK}${NC} ${CYAN}Via port-forward:${NC} kubectl port-forward svc/qgis-server -n ${NAMESPACE} 8080:80\n"
printf "${GREEN}${EMOJI_CHECK}${NC} ${CYAN}Map viewer:${NC} http://qgis.local/\n\n"

printf "${BOLD}Troubleshooting Commands:${NC}\n"
printf "${BLUE}→${NC} View QGIS logs:\n"
printf "   ${YELLOW}kubectl logs -n ${NAMESPACE} \$(kubectl get pod -l app=qgis-server -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}')${NC}\n"
printf "${BLUE}→${NC} View Viewer logs:\n"
printf "   ${YELLOW}kubectl logs -n ${NAMESPACE} \$(kubectl get pod -l app=qgis-viewer -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}')${NC}\n"
printf "${BLUE}→${NC} Exec into viewer pod:\n"
printf "   ${YELLOW}kubectl exec -it \$(kubectl get pod -l app=qgis-viewer -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}') -n ${NAMESPACE} -- sh${NC}\n"
printf "${BLUE}→${NC} Run tests:\n"
printf "   ${YELLOW}./test-qgis.sh${NC}\n"

printf "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
