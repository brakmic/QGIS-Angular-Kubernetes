import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

export interface AppConfig {
  production: boolean;
  qgisServerUrl: string;
  availableLayers: Array<{ id: string; name: string }>;
  initialView: {
    center: [number, number];
    zoom: number;
  };
}

@Injectable({
  providedIn: 'root'
})
export class AppConfigService {
  private config!: AppConfig;

  constructor(private http: HttpClient) {}

  async loadConfig(): Promise<void> {
    try {
      const config = await firstValueFrom(this.http.get<AppConfig>('assets/config.json'));
      this.config = config;
    } catch (error) {
      console.error('Could not load config, defaulting to environment settings', error);
      const env = await import('@environments/environment');
      this.config = {
        production: env.environment.production,
        qgisServerUrl: env.environment.qgisServerUrl,
        availableLayers: (env.environment as any).availableLayers || [],
        initialView: (env.environment as any).initialView || { center: [10, 50], zoom: 4 }
      };
    }
  }

  get settings(): AppConfig {
    return this.config;
  }
}
