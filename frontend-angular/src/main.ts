import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter, withDebugTracing } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { APP_INITIALIZER } from '@angular/core';

import { AppConfigService } from '@app/config/app-config.service';
import { AppComponent } from '@app/app.component';
import { appRoutes } from '@app/app.routes';
import { LoggingInterceptor } from '@interceptors/logging.interceptor';

export function initApp(appConfig: AppConfigService) {
  return () => appConfig.loadConfig();
}

bootstrapApplication(AppComponent, { 
  providers: [
    provideHttpClient(),
    { 
      provide: HTTP_INTERCEPTORS,
      useClass: LoggingInterceptor,
      multi: true 
    },
    provideRouter(appRoutes, withDebugTracing()),
    {
      provide: APP_INITIALIZER,
      useFactory: initApp,
      deps: [AppConfigService],
      multi: true
    }
  ]
}).catch(err => console.error(err));
