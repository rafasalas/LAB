class Gui {

  Slidersimple factorSlider;
  Slidersimple beatSlider;
  Slidersimple gravesSlider, mediosSlider, agudosSlider;
  PVector Posiciongui;
  PImage despliega, pliega;
  PFont f_label;
  int Alto, Ancho;

  // Columnas
  int lcX, lcW, rcX, rcW;

  Gui(PVector posiciongui, int alto, int ancho) {
    Posiciongui = posiciongui;
    Alto = alto;
    Ancho = ancho;

    lcX = 10;
    lcW = 480;
    rcX = 510;
    rcW = Ancho - rcX - 10;   // 1180 - 510 - 10 = 660

    f_label = createFont("SansSerif", 14, true);

    despliega = loadImage("desplegar.png");
    pliega    = loadImage("replegar.png");

    // Sliders de ganancia global y umbral de beat
    factorSlider = new Slidersimple(new PVector(rcX + 10, 126), rcW - 20);
    factorSlider.posicion_marker = int((Factor - 10) / 190.0 * (rcW - 20));

    beatSlider = new Slidersimple(new PVector(rcX + 10, 171), rcW - 20);
    beatSlider.posicion_marker = int((BEAT_THRESHOLD - 1.0) * (rcW - 20));

    // Sliders de ganancia por banda
    int segW = (rcW - 10) / 3;
    int sLen = segW - 28;
    gravesSlider = new Slidersimple(new PVector(rcX + 5,          85), sLen);
    mediosSlider = new Slidersimple(new PVector(rcX + 5 + segW,   85), sLen);
    agudosSlider = new Slidersimple(new PVector(rcX + 5 + 2*segW, 85), sLen);
    gravesSlider.posicion_marker = sLen;
    mediosSlider.posicion_marker = sLen;
    agudosSlider.posicion_marker = sLen;
  }

  void display() {
    colorMode(RGB);
    rectMode(CORNER);
    pushMatrix();
    translate(Posiciongui.x, Posiciongui.y);

    noStroke();
    fill(255, 255, 255, 10);
    rect(0, 0, Ancho, height);

    if (beatFlash > 0) {
      fill(255, 255, 255, beatFlash * 90);
      rect(0, 0, Ancho, 28);
    }

    stroke(255, 255, 255, 65);
    strokeWeight(1);
    line(0, 0, 0, height);
    line(Ancho, 0, Ancho, height);
    line(505, 12, 505, height - 12);
    noStroke();

    fill(255, 255, 255, esta_arriba ? 45 : 90);
    rect(Ancho - 28, 5, 20, 20, 3);
    tint(255, 190);
    if (esta_arriba) { image(pliega,    Ancho - 27, 6, 16, 16); }
    else             { image(despliega, Ancho - 27, 6, 16, 16); }
    noTint();

    // ── COLUMNA IZQUIERDA: monitor de audio ───────────────────────
    drawMonitorPanel();

    // ── COLUMNA DERECHA ────────────────────────────────────────────

    sectionLabel("ANÁLISIS DE AUDIO", rcX, 22, rcX, Ancho - 10);
    drawBandMeters();

    sectionLabel("GANANCIA", rcX, 110, rcX, Ancho - 10);
    colorMode(RGB);
    noStroke();
    fill(255, 255, 255, 200);
    textFont(f_label);
    textSize(12);
    textAlign(RIGHT, BASELINE);
    text(int(Factor), Ancho - 10, 110);
    factorSlider.display3();

    sectionLabel("UMBRAL DE BEAT", rcX, 155, rcX, Ancho - 10);
    colorMode(RGB);
    noStroke();
    fill(255, 255, 255, 200);
    textFont(f_label);
    textSize(12);
    textAlign(RIGHT, BASELINE);
    text(nf(BEAT_THRESHOLD, 1, 2), Ancho - 10, 155);
    beatSlider.display3();

    sectionLabel("ESPECTRO DE FRECUENCIAS", rcX, 200, rcX, Ancho - 10);
    drawSpectrum();

    drawNetworkPanel();

    popMatrix();
  }

  void sectionLabel(String txt, int x, int y, int lineX1, int lineX2) {
    colorMode(RGB);
    stroke(255, 255, 255, 95);
    strokeWeight(1);
    line(lineX1, y - 10, lineX2, y - 10);
    noStroke();
    fill(255, 255, 255, 190);
    textFont(f_label);
    textSize(10);
    textAlign(LEFT, BASELINE);
    text(txt, x, y);
  }

  // ── Columna izquierda: fuente de audio + VU + barras de banda ─────
  void drawMonitorPanel() {
    colorMode(RGB);
    rectMode(CORNER);
    textFont(f_label);
    noStroke();

    sectionLabel("FUENTE DE AUDIO", lcX, 22, lcX, lcX + lcW);

    // Selector de dispositivo
    fill(255, 255, 255, 28);
    rect(lcX, 30, lcW, 30, 3);

    fill(255, 255, 255, 200);
    textSize(13);
    textAlign(CENTER, CENTER);
    text("<", lcX + 14, 45);
    text(">", lcX + lcW - 14, 45);

    String devName = (capturaCount == 0) ? "— sin dispositivos —" : capturaNombres[capturaDispIdx];
    if (devName.length() > 48) devName = devName.substring(0, 48) + "…";
    fill(255, 255, 255, 185);
    textSize(10);
    textAlign(CENTER, CENTER);
    text(devName, lcX + lcW / 2, 45);

    // VU meter post-AGC
    sectionLabel("NIVEL", lcX, 80, lcX, lcX + lcW);
    float lvlNorm = constrain(audioCaptura.getLevel() * agcGain * 5, 0, 1);
    fill(255, 255, 255, 18);
    rect(lcX, 85, lcW, 10, 2);
    if (lvlNorm > 0) {
      fill(255, 255, 255, 175);
      rect(lcX, 85, max(2, int(lvlNorm * lcW)), 10, 2);
    }
    fill(255, 255, 255, 70);
    textSize(9);
    textAlign(RIGHT, BASELINE);
    text("AGC ×" + nf(agcGain, 1, 1), lcX + lcW, 108);

    // Barras de banda verticales
    sectionLabel("BANDAS", lcX, 130, lcX, lcX + lcW);

    int barAreaTop = 140;
    int barAreaBot = 920;
    int barAreaH   = barAreaBot - barAreaTop;

    float[] bVals  = { bandBass, bandMid, bandHigh, bandAir };
    float[] bMaxs  = { 2.5,      2.5,     2.0,      1.0 };
    String[] bLbls = { "GRAVES", "MEDIOS", "AGUDOS", "BRILLOS" };
    float[] bHues  = { 220,      130,      30,       0 };

    int gap  = 8;
    int barW = (lcW - gap * 5) / 4;

    for (int i = 0; i < 4; i++) {
      int bx     = lcX + gap + i * (barW + gap);
      float norm = constrain(bVals[i] / bMaxs[i], 0, 1);
      int barH   = int(norm * barAreaH);

      fill(255, 255, 255, 15);
      rect(bx, barAreaTop, barW, barAreaH, 3);

      if (barH > 0) {
        colorMode(HSB, 360, 100, 100, 100);
        fill(bHues[i], 70, 90, int(norm * 80 + 20));
        colorMode(RGB);
        rect(bx, barAreaTop + barAreaH - barH, barW, barH, 3);
      }

      fill(255, 255, 255, 140);
      textFont(f_label);
      textSize(9);
      textAlign(CENTER, TOP);
      text(bLbls[i], bx + barW / 2, barAreaBot + 5);
    }
  }

  // ── Barras horizontales de banda + beat + sliders de ganancia ─────
  void drawBandMeters() {
    int my = 40, mh = 20;
    int segW = (rcW - 10) / 3;
    float[] vals  = { bandBass, bandMid, bandHigh };
    String[] lbls = { "GRAVES  0-344 Hz", "MEDIOS  344 Hz-2 kHz", "AGUDOS  2-8 kHz" };

    colorMode(RGB);
    textFont(f_label);
    noStroke();

    for (int i = 0; i < 3; i++) {
      fill(255, 255, 255, 150);
      textSize(10);
      textAlign(LEFT, BASELINE);
      text(lbls[i], rcX + 5 + i*segW, my - 6);

      float norm = constrain(vals[i] / 2.5, 0, 1);
      fill(255, 255, 255, 20);
      rect(rcX + 5 + i*segW, my, segW - 8, mh, 2);
      fill(255, 255, 255, 195);
      rect(rcX + 5 + i*segW, my, max(2, int(norm*(segW-8))), mh, 2);
    }

    int bx = Ancho - 60, by = my - 3;
    fill(beat ? color(255, 255, 255, 255) : color(255, 255, 255, 28));
    rect(bx, by, 26, 26, 3);
    fill(255, 255, 255, 130);
    textSize(10);
    textAlign(CENTER, TOP);
    text("BEAT", bx + 13, by + 29);

    if (currentBpm > 0) {
      fill(255, 255, 255, 170);
      textSize(12);
      textAlign(RIGHT, BASELINE);
      text(int(currentBpm) + " BPM", Ancho - 5, my + mh);
    }

    float[] gains = { gravesGain, mediosGain, agudosGain };
    for (int i = 0; i < 3; i++) {
      fill(255, 255, 255, 120);
      textSize(9);
      textAlign(RIGHT, BASELINE);
      text(nf(gains[i], 1, 2), rcX + 5 + (i+1)*segW - 10, 81);
    }
    gravesSlider.display3();
    mediosSlider.display3();
    agudosSlider.display3();
  }

  // ── Espectro FFT (HSB azul→rojo, 450 px de alto) ──────────────────
  void drawSpectrum() {
    int sx = rcX + 5;
    int sy = 212;
    int sw = Ancho - rcX - 20;
    int sh = 450;
    int nBands = 80;
    float barW = float(sw) / nBands;

    colorMode(RGB);
    noStroke();
    fill(0, 0, 0, 65);
    rect(sx, sy, sw, sh, 3);

    for (int i = 1; i <= nBands && i < fft_value.length; i++) {
      float val  = fft_value[i];
      float dB   = (val > 0) ? 20 * log(val) / 2.302585 : -80;
      float norm = constrain(map(dB, -55, 3, 0, 1), 0, 1);
      float barH = norm * sh;
      colorMode(HSB, 360, 100, 100, 100);
      float hue = map(i, 1, nBands, 220, 0);
      fill(hue, 80, 95, int(norm * 85 + 15));
      colorMode(RGB);
      rect(sx + (i-1)*barW, sy + sh - barH, max(1, barW - 0.5), barH);
    }

    colorMode(RGB);
    noStroke();
    fill(beat ? color(255, 255, 255, 230) : color(255, 255, 255, 28));
    ellipse(sx + sw - 10, sy + 10, 12, 12);

    if (currentBpm > 0) {
      fill(255, 255, 255, 110);
      textFont(f_label);
      textSize(11);
      textAlign(RIGHT, TOP);
      text(int(currentBpm) + " BPM", sx + sw - 22, sy + 4);
    }

    fill(255, 255, 255, 65);
    textFont(f_label);
    textSize(9);
    textAlign(LEFT, BOTTOM);
    text("20 Hz", sx + 3, sy + sh - 3);
    textAlign(CENTER, BOTTOM);
    text("1 kHz", sx + int(sw * 0.21), sy + sh - 3);
    textAlign(RIGHT, BOTTOM);
    text("5 kHz", sx + sw - 3, sy + sh - 3);
  }

  // ── Detección de flechas del selector de dispositivo ──────────────
  // Coordenadas GUI-locales (columna izquierda, y=30-60)

  boolean detectDevicePrev() {
    float mx = mouseX - Posiciongui.x;
    float my = mouseY - Posiciongui.y;
    return (mx >= lcX && mx <= lcX + 28 && my >= 30 && my <= 60);
  }

  boolean detectDeviceNext() {
    float mx = mouseX - Posiciongui.x;
    float my = mouseY - Posiciongui.y;
    return (mx >= lcX + lcW - 28 && mx <= lcX + lcW && my >= 30 && my <= 60);
  }

  void detectdeslizer() {
    PVector v = new PVector(mouseX, mouseY);
    v.sub(gui.Posiciongui);
    if (v.x > Ancho - 28 && v.x < Ancho - 4) {
      if (v.y > 5 && v.y < 25) { esta_arriba = !esta_arriba; }
    }
  }

  // ── Panel RED LOCAL ────────────────────────────────────────────────

  void drawNetworkPanel() {
    sectionLabel("RED LOCAL", rcX, 688, rcX, Ancho - 10);
    colorMode(RGB);
    noStroke();
    textFont(f_label);

    fill(broadcastMode ? color(255, 255, 255, 220) : color(255, 255, 255, 45));
    rect(rcX + 5, 696, 120, 28, 3);
    fill(broadcastMode ? color(0, 0, 0, 240) : color(255, 255, 255, 200));
    textSize(11);
    textAlign(CENTER, CENTER);
    text("BROADCAST", rcX + 65, 710);

    fill(!broadcastMode ? color(255, 255, 255, 220) : color(255, 255, 255, 45));
    rect(rcX + 130, 696, 120, 28, 3);
    fill(!broadcastMode ? color(0, 0, 0, 240) : color(255, 255, 255, 200));
    textAlign(CENTER, CENTER);
    text("UNICAST", rcX + 190, 710);

    fill(255, 255, 255, 110);
    textSize(10);
    textAlign(RIGHT, CENTER);
    text(knownPeers.size() + (knownPeers.size() == 1 ? " conectado" : " conectados"), Ancho - 10, 710);

    int listY   = 733;
    int rowH    = 28;
    int maxRows = min(knownPeers.size(), 6);

    if (knownPeers.size() == 0) {
      fill(255, 255, 255, 40);
      textSize(10);
      textAlign(LEFT, CENTER);
      text("Esperando conexiones…", rcX + 10, listY + 14);
    }

    for (int i = 0; i < maxRows; i++) {
      OscPeer p = knownPeers.get(i);
      long agoSec = (millis() - p.lastSeen) / 1000;
      float fresh = constrain(1.0 - agoSec / 15.0, 0.25, 1.0);

      fill(255, 255, 255, int(14 * fresh));
      rect(rcX + 5, listY + i*rowH, Ancho - rcX - 20, rowH - 3, 2);

      fill(255, 255, 255, int(215 * fresh));
      textSize(11);
      textAlign(LEFT, CENTER);
      text(p.name, rcX + 12, listY + i*rowH + rowH/2);

      fill(255, 255, 255, int(110 * fresh));
      textSize(9);
      textAlign(LEFT, CENTER);
      text(p.ip, rcX + 185, listY + i*rowH + rowH/2);

      fill(255, 255, 255, int(65 * fresh));
      textSize(9);
      textAlign(RIGHT, CENTER);
      text(agoSec + "s", Ancho - 12, listY + i*rowH + rowH/2);

      fill(fresh > 0.7 ? color(160, 255, 160, 200) : color(255, 255, 255, int(100 * fresh)));
      ellipse(rcX + 172, listY + i*rowH + rowH/2, 7, 7);
    }
  }

  boolean detectBroadcastToggle() {
    float mx = mouseX - Posiciongui.x;
    float my = mouseY - Posiciongui.y;
    return (mx >= rcX + 5 && mx <= rcX + 125 && my >= 696 && my <= 724);
  }

  boolean detectUnicastToggle() {
    float mx = mouseX - Posiciongui.x;
    float my = mouseY - Posiciongui.y;
    return (mx >= rcX + 130 && mx <= rcX + 250 && my >= 696 && my <= 724);
  }
}
