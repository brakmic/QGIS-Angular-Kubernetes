import { Directive, ElementRef, HostListener, Input } from '@angular/core';

@Directive({
  standalone: true,
  selector: '[appDebugMode]'
})
export class DebugModeDirective {
  @Input() appDebugMode = false;

  constructor(private el: ElementRef) {}

  @HostListener('click')
  onClick() {
    if (this.appDebugMode) {
      console.log('[DebugModeDirective] Element clicked:', this.el.nativeElement);
    }
  }
}
