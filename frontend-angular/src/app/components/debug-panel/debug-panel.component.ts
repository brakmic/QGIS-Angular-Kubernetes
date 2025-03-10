import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { QgisService } from '@services/qgis.service';
import { DebugModeDirective } from '@directives/debug-mode.directive';

@Component({
  standalone: true,
  selector: 'app-debug-panel',
  templateUrl: './debug-panel.component.html',
  styleUrls: ['./debug-panel.component.css'],
  imports: [CommonModule, DebugModeDirective]
})
export class DebugPanelComponent {
  connectionStatus = signal<string>('');
  layerInfo = signal<string>('');
  requestInfo = signal<string>('');
  debugOn = signal<boolean>(false);

  constructor(private qgis: QgisService) {}

  toggleDebug() {
    this.debugOn.update((val) => !val);
    this.connectionStatus.set(`Console debug mode: \${this.debugOn() ? 'ON' : 'OFF'}`);
  }

  testConnection() {
    this.connectionStatus.set('Testing connection...');
    this.qgis.testConnection().subscribe({
      next: (data: any) => {
        this.connectionStatus.set('Connection successful');
        // parse and extract layers
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(data, 'text/xml');
        const layers = xmlDoc.getElementsByTagName('Layer');
        const layerNames: string[] = [];
        for (let i = 0; i < layers.length; i++) {
          const nameElem = layers[i].getElementsByTagName('Name');
          if (nameElem.length) {
            layerNames.push(nameElem[0].textContent || '');
          }
        }
        this.layerInfo.set(`Available layers: \${layerNames.join(', ')}`);
      },
      error: (err: any) => {
        this.connectionStatus.set(`Connection failed: \${err.message}`);
      }
    });
  }

  getCapabilities() {
    this.requestInfo.set('Requesting capabilities...');
    this.qgis.getCapabilities().subscribe({
      next: (data: any) => {
        this.requestInfo.update((prev) => `GetCapabilities response.\\n\${prev}`);
        this.requestInfo.update((prev) => `\${prev}\\nPreview: \${data.substring(0, 100)}...`);
      },
      error: (err: any) => {
        this.requestInfo.set(`Error: \${err.message}`);
      }
    });
  }

  testGetMap(layer: string) {
    if (layer === 'OSM') {
      this.requestInfo.set('Cannot test GetMap on OSM layer');
      return;
    }
    this.requestInfo.set(`Testing GetMap for layer: \${layer}`);
    this.qgis.testGetMap(layer).subscribe({
      next: (blob: any) => {
        this.requestInfo.update((prev) => `\${prev}\\nReceived image: \${Math.round(blob.size/1024)} KB`);
      },
      error: (err: any) => {
        this.requestInfo.set(`Error: \${err.message}`);
      }
    });
  }

  clearLog() {
    this.connectionStatus.set('');
    this.layerInfo.set('');
    this.requestInfo.set('');
  }

  analyzeCapabilities() {
    this.layerInfo.set('Analyzing WMS capabilities...');
    this.qgis.getCapabilities().subscribe({
      next: (data: any) => {
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(data, 'text/xml');
        const rootLayers = xmlDoc.getElementsByTagName('Layer');
        let info = 'Available WMS Layers:\\n';

        for (let i = 0; i < rootLayers.length; i++) {
          const layer = rootLayers[i];
          const nameElems = layer.getElementsByTagName('Name');
          const titleElems = layer.getElementsByTagName('Title');
          if (nameElems.length > 0) {
            const name = nameElems[0].textContent || 'No name';
            const title = titleElems.length ? titleElems[0].textContent : 'No title';
            info += `- Name: "\${name}", Title: "\${title}"\\n`;
          }
          const childLayers = layer.getElementsByTagName('Layer');
          for (let j = 0; j < childLayers.length; j++) {
            const cn = childLayers[j].getElementsByTagName('Name');
            const ct = childLayers[j].getElementsByTagName('Title');
            if (cn.length > 0) {
              const name = cn[0].textContent || 'No name';
              const title = ct.length ? ct[0].textContent : 'No title';
              info += `  • Name: "\${name}", Title: "\${title}"\\n`;
            }
          }
        }
        this.layerInfo.set(info);
      },
      error: (err: any) => {
        this.layerInfo.set(`Error analyzing capabilities: \${err.message}`);
      }
    });
  }
}
