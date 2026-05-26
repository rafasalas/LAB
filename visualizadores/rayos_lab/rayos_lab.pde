// rayos_lab — visualizador OSC para el ecosistema LAB
//
// Porta el algoritmo de rayos ramificantes de openFrameworks (rayos3) a Processing,
// sustituyendo el FFT local por los datos que TheLab ya emite:
//   Puerto 6449 → /fft_value  (511 floats, el espectro completo a 60 fps)
//   Puerto 6448 → /beat, /bpm, /brillos  (control adicional)
//
// Cada uno de los 360 rayos usa el bin FFT[ang] para determinar su longitud,
// igual que en el original C++ (value[angul] → trozos).
// Renderer P2D (OpenGL) + batching de líneas por rayo → rendimiento a pantalla completa.

import oscP5.*;
import netP5.*;

OscP5 osc;     // puerto 6448 — /beat, /bpm, /brillos
OscP5 oscFft;  // puerto 6449 — /fft_value  (datagram grande: 8192 bytes)

float[] value = new float[512];

// Valores OSC suavizados con lerp para evitar saltos bruscos
float brillosTarget = 0.5;
float brillos_s     = 0.5;
float bpmTarget     = 120;
float bpm_s         = 120;
float beatDecay     = 0;     // decae de 1.0 a 0 tras cada beat (~12 frames)

float cx, cy;

void setup() {
  fullScreen(P2D,2);
  frameRate(60);
  smooth(4);
  background(0);
  colorMode(HSB, 360, 100, 100, 100);

  cx = width  / 2.0;
  cy = height / 2.0;

  // Puerto 6449 necesita buffer grande: /fft_value pesa ~2572 bytes
  OscProperties props = new OscProperties();
  props.setListeningPort(6449);
  props.setDatagramSize(8192);
  oscFft = new OscP5(this, props);

  osc = new OscP5(this, 6448);
}

void draw() {
  // Suavizar valores OSC
  brillos_s = lerp(brillos_s, brillosTarget, 0.08);
  bpm_s     = lerp(bpm_s,     bpmTarget,     0.04);
  beatDecay = max(0, beatDecay - 0.08);

  // Estela: overlay negro semitransparente.
  // /brillos alto → fade rápido (estela corta), /brillos bajo → estela larga.
  noStroke();
  fill(0, 0, 0, (int)map(brillos_s, 0, 1, 5, 22));  // HSB alpha 0–100
  rect(0, 0, width, height);

  // Autodiscovery beacon → TheLab lo registra en su lista de peers
  if (frameCount == 1 || frameCount % 300 == 0) {
    OscMessage hello = new OscMessage("/hello");
    hello.add("rayos_lab");
    oscFft.send(hello, new NetAddress("255.255.255.255", 12000));
  }

  // Círculo central (relleno blanco neutro)
  fill(0, 0, 100, 70);
  circle(cx, cy, 20);

  // 360 rayos — uno por grado
  // Color HSB: tono = ángulo (arcoíris completo), saturación y brillo
  // conducidos por la energía FFT del bin correspondiente.
  // Con FFT_SCALE=100 los valores típicos van de 0 a ~150.
  noFill();
  strokeWeight(1);

  for (int ang = 0; ang < 360; ang++) {
    float v = value[ang];

    float hue = ang;                                          // 0–360°: arcoíris radial
    float sat = constrain(map(v, 0, 80, 15, 90), 15, 90);   // silencio=desaturado, pico=vivo
    float bri = constrain(map(v, 0, 80,  0, 100), 0, 100);  // silencio=oscuro, pico=brillante
    float alp = constrain(map(v, 0, 80,  0, 85) + beatDecay * 25, 0, 100);

    if (alp < 2) continue;

    stroke(hue, sat, bri, alp);

    int segmentos = CACHOS_BASE + (int)v + (int)(beatDecay * 60);
    rayo(cx, cy, ang, segmentos);
  }
}

void oscEvent(OscMessage msg) {
  // Espectro completo desde TheLab (511 bins, puerto 6449)
  if (msg.checkAddrPattern("/fft_value")) {
    int n = msg.arguments().length;
    for (int j = 0; j < min(511, n); j++) {
      value[j] = msg.get(j).floatValue() * FFT_SCALE;
    }
    return;
  }

  // Mensajes de control desde puerto 6448
  if (msg.checkAddrPattern("/brillos"))
    brillosTarget = msg.get(0).floatValue();

  if (msg.checkAddrPattern("/bpm"))
    bpmTarget = msg.get(0).floatValue();

  if (msg.checkAddrPattern("/beat") && msg.get(0).intValue() == 1)
    beatDecay = 1.0;
}
