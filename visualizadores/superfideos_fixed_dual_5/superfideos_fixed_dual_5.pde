import oscP5.*;
import netP5.*;

// OSC audio values from TheLab (:6448)
float flujo         = 0;   // /intensidad — señal oscilante ±Factor (RMS × signo)
float flujo_graves  = 0;   // /graves     — bajos 0–344 Hz
float flujo_medios  = 0;   // /medios     — medios 344 Hz–2 kHz
float flujo_agudos  = 0;   // /agudos     — agudos 2–8 kHz
float flujo_brillos = 0;   // /brillos    — aire 8 kHz+
float beatDecay     = 0;   // decae desde 1.0 en cada /beat, usado como pulso en centralb
float currentBpm    = 120; // /bpm

// Visualizer
CriatureCloud cria1, cria2, cria3, cria4;
Atractor central, centralb, lateral1, lateral2, lateral3, lateral4;
int ancho, alto, X_ini, Y_ini;
PImage sombra;

// OSC
OscP5 oscP5;
NetAddress theLabAddr; // para el anuncio /hello

void setup() {
  fullScreen(P2D, 2);
  smooth(8);
  frameRate(60);

  sombra = loadImage("sombra.png");

  // Escucha el mismo puerto que emite TheLab
  oscP5    = new OscP5(this, 6448);
  // Puerto de escucha de TheLab (12000); broadcast para descubrimiento automático
  theLabAddr = new NetAddress("255.255.255.255", 12000);

  int nodos = 200;
  cria1 = new CriatureCloud(nodos);
  cria2 = new CriatureCloud(nodos);
  cria3 = new CriatureCloud(nodos);
  cria4 = new CriatureCloud(nodos);

  ancho = width;
  alto  = height;

  central  = new Atractor(1);
  centralb = new Atractor(1);
  lateral1 = new Atractor(1);
  lateral2 = new Atractor(1);
  lateral3 = new Atractor(1);
  lateral4 = new Atractor(1);

  int x = X_ini + ancho / 2;
  int y = Y_ini + alto  / 2;
  central.posicion  = new PVector(x, y);
  centralb.posicion = new PVector(x, y);
  lateral1.posicion = new PVector(x, y - (alto  / 4));  // arriba — medios
  lateral2.posicion = new PVector(x + (ancho / 4), y);  // derecha — agudos
  lateral3.posicion = new PVector(x, y + (alto  / 4));  // abajo   — medios
  lateral4.posicion = new PVector(x - (ancho / 4), y);  // izquierda — agudos

  centralb.sentido = -5;
}

void draw() {
  noStroke();
  // Opacidad del fondo proporcional a la intensidad — mayor flujo = cola más corta
  fill(0, 0, 0, map(abs(flujo), 0, 4, 10, 40));
  rect(0, 0, width, height);

  // Beat: decae desde 1.0 → 0 en ~12 frames (~200 ms)
  if (beatDecay > 0) beatDecay = max(0, beatDecay - 0.08);

  // central: oscila con el signo de flujo → respiración natural
  central.sentido = -1 - flujo;

  // centralb: ligera atracción en reposo, el bajo la refuerza, beat = pulso hacia afuera
  centralb.sentido = -0.5 - flujo_graves + beatDecay * 5;

  // laterales: repulsión moderada proporcional a la banda
  float factMed = random(0.4, 0.8);
  lateral1.sentido = factMed * flujo_medios * 0.6;
  lateral3.sentido = factMed * flujo_medios * 0.6;

  float factAg = random(0.2, 0.5);
  lateral2.sentido = factAg * flujo_agudos * 0.6;
  lateral4.sentido = factAg * flujo_agudos * 0.6;

  // Aplicar atractores
  cria1.acelerador_dual(centralb, central);
  cria2.acelerador_dual(centralb, central);
  cria3.acelerador_dual(centralb, central);
  cria4.acelerador_dual(centralb, central);

  cria1.acelerador_cola(lateral1);
  cria2.acelerador_cola(lateral2);
  cria2.acelerador_cola(lateral3);
  cria1.acelerador_cola(lateral4);
  cria3.acelerador_cola(lateral1);
  cria3.acelerador_cola(lateral2);
  cria4.acelerador_cola(lateral3);
  cria4.acelerador_cola(lateral4);

  cria1.actualizar(); cria1.mostrar();
  cria2.actualizar(); cria2.mostrar();
  cria3.actualizar(); cria3.mostrar();
  cria4.actualizar(); cria4.mostrar();

  // Anuncio periódico a TheLab para aparecer en su lista de peers (cada ~5 s)
  if (frameCount % 300 == 1) {
    OscMessage hello = new OscMessage("/hello");
    hello.add("superfideos");
    oscP5.send(hello, theLabAddr);
  }
}

void oscEvent(OscMessage msg) {
  if      (msg.checkAddrPattern("/intensidad")) flujo         = msg.get(0).floatValue();
  else if (msg.checkAddrPattern("/graves"))     flujo_graves  = msg.get(0).floatValue();
  else if (msg.checkAddrPattern("/medios"))     flujo_medios  = msg.get(0).floatValue();
  else if (msg.checkAddrPattern("/agudos"))     flujo_agudos  = msg.get(0).floatValue();
  else if (msg.checkAddrPattern("/brillos"))    flujo_brillos = msg.get(0).floatValue();
  else if (msg.checkAddrPattern("/beat")  && msg.get(0).intValue() == 1) beatDecay = 1.0;
  else if (msg.checkAddrPattern("/bpm"))        currentBpm    = msg.get(0).floatValue();
}
