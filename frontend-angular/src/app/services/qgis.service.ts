import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AppConfigService } from '@app/config/app-config.service';

@Injectable({ providedIn: 'root' })
export class QgisService {
  private http = inject(HttpClient);
  private configService: AppConfigService = inject(AppConfigService);

  testConnection() {
    const url = `${this.configService.settings.qgisServerUrl}?SERVICE=WMS&REQUEST=GetCapabilities`;
    return this.http.get(url, { responseType: 'text' });
  }

  getCapabilities() {
    const url = `${this.configService.settings.qgisServerUrl}?SERVICE=WMS&REQUEST=GetCapabilities`;
    return this.http.get(url, { responseType: 'text' });
  }

  testGetMap(layer: string) {
    const url = `${this.configService.settings.qgisServerUrl}?SERVICE=WMS&REQUEST=GetMap&VERSION=1.3.0&LAYERS=${layer}&STYLES=&CRS=EPSG:3857&BBOX=-20026376.39,-20048966.10,20026376.39,20048966.10&WIDTH=256&HEIGHT=256&FORMAT=image/png`;
    return this.http.get(url, { responseType: 'blob' });
  }
}
