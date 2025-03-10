import { signal } from '@angular/core';

/**
 * A simple signal storing the current selected layer name.
 */
export const selectedLayer = signal<string>('OSM');
