class Gui {

  Listascroll lista;
  Bar_simple barra;
  Buttonplay boton;
  Buttonsimple loadmp3, loadm3u, clear, save;
  Slidersimple factorSlider;
  Slidersimple beatSlider;
  Slidersimple gravesSlider, mediosSlider, agudosSlider;
  PVector Posiciongui;
  PVector posicionbarra;
  PVector listaposicion;
  PImage despliega, pliega;
  PFont f_label;
  int Alto, Ancho;
  float donde;

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

    boton = new Buttonplay(lcX + lcW/2, 50, 34, 34);

    posicionbarra = new PVector(lcX, 100);
    barra = new Bar_simple(posicionbarra, lcW, 8);

    listaposicion = new PVector(lcX, 140);
    lista = new Listascroll(listaposicion);
    lista.ancho_items = lcW - 15;
    lista.ancho_barra = 15;
    lista.alto = 800;
    lista.itemsvisibles = 29;

    // Botones de acción en columna derecha — desplazados +42px para dar espacio a sección FUENTE
    int bw = 75, bh = 35;
    int bg = (rcW - 4*bw) / 5;
    loadmp3 = new Buttonsimple(rcX + bg,          162, bh, bw, "loadmp3.svg");
    loadm3u = new Buttonsimple(rcX + bg*2 + bw,   162, bh, bw, "loadm3u.svg");
    clear   = new Buttonsimple(rcX + bg*3 + bw*2, 162, bh, bw, "clear.svg");
    save    = new Buttonsimple(rcX + bg*4 + bw*3, 162, bh, bw, "save.svg");

    despliega = loadImage("desplegar.png");
    pliega    = loadImage("replegar.png");

    // Sliders de ganancia global y umbral — desplazados +35px
    factorSlider = new Slidersimple(new PVector(rcX + 10, 237), rcW - 20);
    factorSlider.posicion_marker = int((Factor - 10) / 190.0 * (rcW - 20));

    beatSlider = new Slidersimple(new PVector(rcX + 10, 287), rcW - 20);
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

    donde = 0;
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

    // ── COLUMNA IZQUIERDA ──────────────────────────────────────────

    sectionLabel("REPRODUCCIÓN", lcX, 22, lcX, lcX + lcW);
    boton.display();
    drawProgressArea();

    sectionLabel("LISTA DE REPRODUCCIÓN", lcX, 130, lcX, lcX + lcW);
    lista.display();

    // ── COLUMNA DERECHA ────────────────────────────────────────────

    sectionLabel("ANÁLISIS DE AUDIO", rcX, 22, rcX, Ancho - 10);
    drawBandMeters();

    sectionLabel("CONTROLES", rcX, 108, rcX, Ancho - 10);
    drawSourceSection();
    drawActionButtons();

    sectionLabel("GANANCIA", rcX, 220, rcX, Ancho - 10);
    colorMode(RGB);
    noStroke();
    fill(255, 255, 255, 200);
    textFont(f_label);
    textSize(12);
    textAlign(RIGHT, BASELINE);
    text(int(Factor), Ancho - 10, 220);
    factorSlider.display3();

    sectionLabel("UMBRAL DE BEAT", rcX, 270, rcX, Ancho - 10);
    colorMode(RGB);
    noStroke();
    fill(255, 255, 255, 200);
    textFont(f_label);
    textSize(12);
    textAlign(RIGHT, BASELINE);
    text(nf(BEAT_THRESHOLD, 1, 2), Ancho - 10, 270);
    beatSlider.display3();

    sectionLabel("ESPECTRO DE FRECUENCIAS", rcX, 320, rcX, Ancho - 10);
    drawSpectrum();

    drawNetworkPanel();

    popMatrix();

    if (estamosmoviendo && cancionatrapada > -1 && cancionatrapada < lista.Item.size()) {
      colorMode(RGB);
      fill(230, 230, 230, 210);
      textFont(f_label);
      textSize(13);
      textAlign(LEFT, BOTTOM);
      String cadena = lista.Item.get(cancionatrapada);
      if (cadena.length() > 60) cadena = cadena.substring(0, 60) + "…";
      text(cadena, mouseX, mouseY);
    }
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

  // ── Progreso: tiempo + barra (MP3) o VU meter (SISTEMA) ────────────
  void drawProgressArea() {
    colorMode(RGB);
    textFont(f_label);
    noStroke();

    if (!modoSistema) {
      textSize(11);
      fill(255, 255, 255, 150);
      textAlign(LEFT, BASELINE);
      int posSec = song.position() / 1000;
      int totSec = song.length()   / 1000;
      text(nf(posSec/60,1)+":"+nf(posSec%60,2)+"  /  "+nf(totSec/60,1)+":"+nf(totSec%60,2), lcX, 92);
      barra.display(donde);
    } else {
      fill(255, 255, 255, 55);
      textSize(10);
      textAlign(LEFT, BASELINE);
      text("ENTRADA EN VIVO", lcX, 92);
      // VU meter: nivel post-AGC
      float lvlNorm = constrain(audioCaptura.getLevel() * agcGain * 5, 0, 1);
      fill(255, 255, 255, 18);
      rect(lcX, 97, lcW, 8, 2);
      if (lvlNorm > 0) {
        fill(255, 255, 255, 175);
        rect(lcX, 97, max(2, int(lvlNorm * lcW)), 8, 2);
      }
    }
  }

  // ── Barras de banda, indicador beat, sliders de ganancia ───────────
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

  // ── Sección FUENTE: toggle MP3/SISTEMA + selector de dispositivo ───
  void drawSourceSection() {
    colorMode(RGB);
    noStroke();
    textFont(f_label);

    // Botón toggle MP3 / SISTEMA
    fill(modoSistema ? color(255, 255, 255, 220) : color(255, 255, 255, 45));
    rect(rcX + 5, 120, 110, 30, 3);
    fill(modoSistema ? color(0, 0, 0, 240) : color(255, 255, 255, 200));
    textSize(11);
    textAlign(CENTER, CENTER);
    text(modoSistema ? "SISTEMA" : "MP3", rcX + 60, 135);

    // Caja selector de dispositivo
    float devAlpha = modoSistema ? 1.0 : 0.35;
    int devBoxX = rcX + 123;
    int devBoxW = rcW - 128;

    fill(255, 255, 255, 28 * devAlpha);
    rect(devBoxX, 120, devBoxW, 30, 3);

    // Flecha <
    fill(255, 255, 255, 200 * devAlpha);
    textSize(13);
    textAlign(CENTER, CENTER);
    text("<", devBoxX + 13, 135);

    // Nombre del dispositivo
    String devName;
    if (capturaCount == 0) {
      devName = "— sin dispositivos —";
    } else {
      devName = capturaNombres[capturaDispIdx];
      if (devName.length() > 34) devName = devName.substring(0, 34) + "…";
    }
    fill(255, 255, 255, 185 * devAlpha);
    textSize(10);
    textAlign(CENTER, CENTER);
    text(devName, devBoxX + devBoxW / 2, 135);

    // Flecha >
    fill(255, 255, 255, 200 * devAlpha);
    textSize(13);
    textAlign(CENTER, CENTER);
    text(">", devBoxX + devBoxW - 13, 135);

    // Indicador AGC cuando está activo
    if (modoSistema) {
      fill(255, 255, 255, 75);
      textSize(9);
      textAlign(RIGHT, BASELINE);
      text("AGC ×" + nf(agcGain, 1, 1), Ancho - 10, 155);
    }
  }

  // ── Botones de acción (CARGAR MP3, PLAYLIST, LIMPIAR, GUARDAR) ─────
  void drawActionButtons() {
    loadmp3.display();
    loadm3u.display();
    clear.display();
    save.display();

    // Overlay de atenuado dibujado DESPUÉS de los SVGs para dimearlos
    if (modoSistema) {
      colorMode(RGB);
      noStroke();
      fill(12, 12, 12, 165);
      rectMode(CORNER);
      int bw = 75, bh = 35;
      int bg = (rcW - 4*bw) / 5;
      rect(rcX + bg,          162, bw, bh, 2);   // CARGAR MP3
      rect(rcX + bg*2 + bw,   162, bw, bh, 2);   // PLAYLIST
      rect(rcX + bg*4 + bw*3, 162, bw, bh, 2);   // GUARDAR
    }

    colorMode(RGB);
    noStroke();
    textFont(f_label);
    textSize(10);
    textAlign(CENTER, TOP);
    String[] lbls = { "CARGAR MP3", "PLAYLIST", "LIMPIAR", "GUARDAR" };
    int bw = 75;
    int bg = (rcW - 4*bw) / 5;
    int[] bx = {
      rcX + bg,
      rcX + bg*2 + bw,
      rcX + bg*3 + bw*2,
      rcX + bg*4 + bw*3
    };
    for (int i = 0; i < 4; i++) {
      fill(255, 255, 255, (modoSistema && i != 2) ? 50 : 140);
      text(lbls[i], bx[i] + bw/2, 202);
    }
  }

  // ── Espectro FFT (HSB azul→rojo) ───────────────────────────────────
  void drawSpectrum() {
    int sx = rcX + 5;
    int sy = 332;
    int sw = Ancho - rcX - 20;
    int sh = 350;
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

  // ── Detección de toggle y selección de dispositivo ─────────────────
  // Coordenadas GUI-locales (misma convención que Buttonplay/Buttonsimple)

  boolean detectSourceToggle() {
    float mx = mouseX - Posiciongui.x;
    float my = mouseY - Posiciongui.y;
    return (mx >= rcX + 5 && mx <= rcX + 115 && my >= 120 && my <= 150);
  }

  boolean detectDevicePrev() {
    float mx = mouseX - Posiciongui.x;
    float my = mouseY - Posiciongui.y;
    return (mx >= rcX + 123 && mx <= rcX + 148 && my >= 120 && my <= 150);
  }

  boolean detectDeviceNext() {
    float mx = mouseX - Posiciongui.x;
    float my = mouseY - Posiciongui.y;
    return (mx >= rcX + rcW - 30 && mx <= rcX + rcW - 3 && my >= 120 && my <= 150);
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
    sectionLabel("RED LOCAL", rcX, 698, rcX, Ancho - 10);
    colorMode(RGB);
    noStroke();
    textFont(f_label);

    // Botón BROADCAST
    fill(broadcastMode ? color(255, 255, 255, 220) : color(255, 255, 255, 45));
    rect(rcX + 5, 706, 120, 28, 3);
    fill(broadcastMode ? color(0, 0, 0, 240) : color(255, 255, 255, 200));
    textSize(11);
    textAlign(CENTER, CENTER);
    text("BROADCAST", rcX + 65, 720);

    // Botón UNICAST
    fill(!broadcastMode ? color(255, 255, 255, 220) : color(255, 255, 255, 45));
    rect(rcX + 130, 706, 120, 28, 3);
    fill(!broadcastMode ? color(0, 0, 0, 240) : color(255, 255, 255, 200));
    textAlign(CENTER, CENTER);
    text("UNICAST", rcX + 190, 720);

    // Contador de conectados
    fill(255, 255, 255, 110);
    textSize(10);
    textAlign(RIGHT, CENTER);
    text(knownPeers.size() + (knownPeers.size() == 1 ? " conectado" : " conectados"), Ancho - 10, 720);

    // Lista de peers
    int listY = 743;
    int rowH  = 28;
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

      // Indicador de frescura
      fill(fresh > 0.7 ? color(160, 255, 160, 200) : color(255, 255, 255, int(100 * fresh)));
      ellipse(rcX + 172, listY + i*rowH + rowH/2, 7, 7);
    }
  }

  boolean detectBroadcastToggle() {
    float mx = mouseX - Posiciongui.x;
    float my = mouseY - Posiciongui.y;
    return (mx >= rcX + 5 && mx <= rcX + 125 && my >= 706 && my <= 734);
  }

  boolean detectUnicastToggle() {
    float mx = mouseX - Posiciongui.x;
    float my = mouseY - Posiciongui.y;
    return (mx >= rcX + 130 && mx <= rcX + 250 && my >= 706 && my <= 734);
  }
}
