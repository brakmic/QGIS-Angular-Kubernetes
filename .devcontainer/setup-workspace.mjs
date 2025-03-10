import fs from "fs";
import path from "path";

// Workspace file path
const workspaceFilePath = "/workspace/dev.code-workspace";

// Ensure the directory for the workspace file exists
const dirPath = path.dirname(workspaceFilePath);
if (!fs.existsSync(dirPath)) {
  fs.mkdirSync(dirPath, { recursive: true });
}

// Define the workspace configuration
const workspaceConfig = {
  folders: [
    {
      name: "DevContainer Workspace",
      path: "/workspace"
    },
    {
      name: "Host Workspace",
      path: "/host_workspace"
    },
    {
      name: "Frontend (Angular)",
      path: "/host_workspace/frontend-angular"
    },
    {
      name: "Frontend (Simple)",
      path: "/host_workspace/frontend-simple"
    },
    {
      name: "QGIS Projects",
      path: "/host_workspace/projects"
    },
    {
      name: "QGIS Data",
      path: "/host_workspace/data"
    },
    {
      name: "Configuration",
      path: "/host_workspace/config"
    },
    {
      name: "Deployment (K8s)",
      path: "/host_workspace/deployment-k8s"
    },
    {
      name: "Deployment (Docker)",
      path: "/host_workspace/deployment-docker"
    },
    {
      name: "Scratchpad",
      path: "/host_workspace/scratchpad"
    }
  ],
  settings: {}
};

// Write the workspace file
fs.writeFileSync(workspaceFilePath, JSON.stringify(workspaceConfig, null, 2));
console.log(`Workspace file created: ${workspaceFilePath}`);
