import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { AppConfigService, AppConfig } from '@app/config/app-config.service';
import { selectedLayer } from '@signals/layer.signal';

@Component({
  standalone: true,
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css'],
  imports: [CommonModule, ReactiveFormsModule]
})
export class HeaderComponent implements OnInit {
  config!: AppConfig;
  layerControl = new FormControl();

  constructor(private appConfigService: AppConfigService) {}

  ngOnInit(): void {
    this.config = this.appConfigService.settings;
    const defaultLayer = this.config.availableLayers[0].id;
    this.layerControl.setValue(defaultLayer);
    selectedLayer.set(defaultLayer);

    this.layerControl.valueChanges.subscribe((value: string) => {
      selectedLayer.set(value);
    });
  }
}
