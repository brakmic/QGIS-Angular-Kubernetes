import { Routes } from '@angular/router';
import { MapComponent } from '@components/map/map.component';
import { DebugPanelComponent } from '@components/debug-panel/debug-panel.component';

export const appRoutes: Routes = [
  { path: '', component: MapComponent },
  { path: 'debug', component: DebugPanelComponent },
];
