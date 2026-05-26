// lastrompetas — ecosistema LAB
//
// 6 trompetas en círculo de radio 150px, centrado en pantalla.
// Círculo fijo al plano de la pantalla (sin rotación global).
// Cada trompeta inclinada 45° hacia afuera y con un color distinto.
//
// Puertos OSC:
//   6449 → /fft_value  (511 floats; buffer 8192 bytes)
//   6448 → /intensidad, /graves, /beat

import oscP5.*;
import netP5.*;

OscP5 osc;
OscP5 oscFft;

float[]   value    = new float[512];
Trumpet[] trumpets = new Trumpet[9];   // 6 exteriores (R=150, 45°) + 3 interiores (R=75, 20°)

float intensidad = 0;
float graves     = 0;
volatile boolean beatPulse = false;

// Oscilación amortiguada del conjunto en torno al eje Z (perpendicular a pantalla).
// Modelo muelle angular: cada beat aplica un impulso de velocidad;
// el muelle restaura a 0 y el rozamiento lo amortigua en 2-3 oscilaciones.
//   K_ROT_SPRING = 0.008  →  periodo natural ~70 frames (≈1.2 s)
//   K_ROT_DAMP   = 0.04   →  ratio amortiguación ≈0.22, decae en ~1.7 s
//   BEAT_ROT_KICK = 2.0   →  amplitud pico ≈22° por beat
float rotZ     = 0;
float rotZ_vel = 0;
final float K_ROT_SPRING  = 0.008;
final float K_ROT_DAMP    = 0.04;
final float BEAT_ROT_KICK = 2.0;

// ─────────────────────────────────────────────────────────
void setup() {
  fullScreen(P3D,2);
  frameRate(60);
  colorMode(HSB, 360, 100, 100, 255);
  smooth(4);

  float SCALE = min(width, height) / 700.0;
  float R     = 150 * SCALE;   // radio del círculo de trompetas (px)
  float ancho =   8 * SCALE;   // grosor de arco (px)

  // ── Anillo exterior: 6 trompetas, una cada 60°, inclinación 45° ────────
  for (int t = 0; t < 6; t++) {
    float theta = t * TWO_PI / 6.0;
    float hue   = t * 60.0;    // 0=rojo  60=amarillo  120=verde
                                // 180=cian  240=azul  300=magenta
    trumpets[t] = new Trumpet(
      theta, R, QUARTER_PI,    // posición, radio=150px, inclinación 45°
      10, 100, 10,             // anillos: bins FFT 10–90 paso 10
      ancho, hue, SCALE
    );
  }

  // ── Anillo interior: 3 trompetas, desfasadas 30° respecto a las exteriores ─
  // Colores intermedios (30°=naranja, 150°=verde-lima, 270°=violeta)
  // para distinguirlas claramente del anillo exterior.
  float Ri = 75 * SCALE;                    // radio interior
  float tiltInner = radians(20);            // inclinación suave: 20°
  for (int t = 0; t < 3; t++) {
    float theta = t * TWO_PI / 3.0 + radians(30);   // 30°, 150°, 270°
    float hue   = t * 120.0 + 30.0;                 // 30, 150, 270
    trumpets[6 + t] = new Trumpet(
      theta, Ri, tiltInner,    // posición, radio=75px, inclinación 20°
      10, 100, 10,             // misma configuración de anillos
      ancho, hue, SCALE
    );
  }

  OscProperties props = new OscProperties();
  props.setListeningPort(6449);
  props.setDatagramSize(8192);
  oscFft = new OscP5(this, props);

  osc = new OscP5(this, 6448);
}

// ─────────────────────────────────────────────────────────
void oscEvent(OscMessage msg) {
  String addr = msg.addrPattern();

  if (addr.equals("/fft_value")) {
    int n = msg.arguments().length;
    for (int j = 0; j < min(511, n); j++)
      value[j] = msg.get(j).floatValue() * 100;
    return;
  }
  if (addr.equals("/intensidad")) { intensidad = msg.get(0).floatValue(); return; }
  if (addr.equals("/graves"))     { graves     = msg.get(0).floatValue(); return; }
  if (addr.equals("/beat") && msg.get(0).intValue() == 1) beatPulse = true;
}

// ─────────────────────────────────────────────────────────
void draw() {
  background(0, 0, 0);

  // beat: flag puntual consumido en este frame
  boolean kick = beatPulse;
  beatPulse = false;

  // Autodescubrimiento
  if (frameCount == 1 || frameCount % 300 == 0) {
    OscMessage hello = new OscMessage("/hello");
    hello.add("lastrompetas");
    oscFft.send(hello, new NetAddress("255.255.255.255", 12000));
  }

  // Muelle angular Z: impulso en beat → oscilación amortiguada del conjunto
  if (kick) rotZ_vel += BEAT_ROT_KICK;
  rotZ_vel += -K_ROT_SPRING * rotZ - K_ROT_DAMP * rotZ_vel;
  rotZ     += rotZ_vel;

  // Escena: círculo fijo al plano de pantalla, giro Z amortiguado por beat
  pushMatrix();
  translate(width / 2.0, height / 2.0, 0);
  rotateZ(radians(rotZ));

  for (Trumpet t : trumpets) {
    t.update(value, kick);
    t.display(value);
  }

  popMatrix();
}
