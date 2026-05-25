import oscP5.*;
import netP5.*;

OscP5 oscP5;

// OSC raw
float flujo   = 0;
float graves  = 0;
float agudos  = 0;
float brillos = 0;

// suavizados
float flujo_s  = 0;
float graves_s = 0;
float agudos_s = 0;

float beatForce  = 0;
float hueBase    = 120;
float beatHue    = 0;   // salto de tono en beat, decae suavemente

Storsimple estorninos;
Atractor central, lateral1, lateral2, lateral3, lateral4;


void setup() {
  fullScreen(P2D, 2);
  frameRate(60);
  colorMode(HSB, 360, 100, 100, 100);
  oscP5 = new OscP5(this, 6448);

  estorninos = new Storsimple(4000);

  central  = new Atractor(3);
  lateral1 = new Atractor(3);
  lateral2 = new Atractor(3);
  lateral3 = new Atractor(3);
  lateral4 = new Atractor(3);

  central.posicion  = new PVector(width/2,      height/2);
  lateral1.posicion = new PVector(width/2,      height/8);
  lateral2.posicion = new PVector(width/8,      height/2);
  lateral3.posicion = new PVector(7*(width/8),  height/2);
  lateral4.posicion = new PVector(width/2,  7*(height/8));

  central.fijarHome();
  lateral1.fijarHome();
  lateral2.fijarHome();
  lateral3.fijarHome();
  lateral4.fijarHome();
}


void draw() {
  if (frameCount == 1 || frameCount % 300 == 0) {
    OscMessage hello = new OscMessage("/hello");
    hello.add("ola_01");
    oscP5.send(hello, new NetAddress("255.255.255.255", 12000));
  }
  flujo_s  = lerp(flujo_s,  flujo  * 0.3, 0.25);
  graves_s = lerp(graves_s, graves,        0.12);
  agudos_s = lerp(agudos_s, agudos,        0.12);
  beatForce = max(0, beatForce - 1.0);
  beatHue  *= 0.92;   // decae el salto de tono beat a beat

  // hue base: cálido (graves) → frío (agudos)
  float targetHue = constrain(map(agudos_s - graves_s * 0.5, -2.5, 2.0, 10, 230), 10, 230);
  hueBase = lerp(hueBase, targetHue, 0.04);

  // fuerzas
  central.sentido  = -1 - flujo_s - graves_s * 0.8 + beatForce;
  lateral1.sentido = -0.5 * flujo_s;
  lateral2.sentido = -0.5 * flujo_s;
  lateral3.sentido = -0.5 * flujo_s;
  lateral4.sentido = -0.5 * flujo_s;

  // el atractor central sigue el centro elástico de la web
  central.home.set(estorninos.centroWeb);

  // oscilación elástica de los atractores
  float ampBase = 35 + abs(flujo_s) * 8;
  float t = frameCount;
  central.springUpdate (t, 0.008, 0.0,    ampBase * 0.5);
  lateral1.springUpdate(t, 0.011, 0.0,    ampBase);
  lateral2.springUpdate(t, 0.009, PI/3,   ampBase);
  lateral3.springUpdate(t, 0.013, 2*PI/3, ampBase);
  lateral4.springUpdate(t, 0.007, PI,     ampBase);

  // actualizar centro elástico de la web
  estorninos.updateCentro();

  background(0, 0, 0);

  // parámetros de color al enjambre
  estorninos.hueBase   = hueBase;
  estorninos.hueOffset = beatHue;
  estorninos.sat       = constrain(map(abs(flujo_s), 0, 8, 55, 92), 55, 92);
  estorninos.bri       = constrain(map(beatForce, 0, 15, 78, 98), 78, 98);
  estorninos.agitacion = constrain(map(agudos_s, 0, 2, 0.4, 2.2), 0.4, 2.2);
  estorninos.lineAlpha = constrain(map(brillos, 0, 1, 6, 30), 6, 30);

  estorninos.aceleradorparticulas(central);
  estorninos.aceleradorparticulas(lateral1);
  estorninos.aceleradorparticulas(lateral2);
  estorninos.aceleradorparticulas(lateral3);
  estorninos.aceleradorparticulas(lateral4);
  estorninos.dibujaparticulas();
}


void oscEvent(OscMessage theOscMessage) {
  if      (theOscMessage.checkAddrPattern("/intensidad")) flujo   = theOscMessage.get(0).floatValue();
  else if (theOscMessage.checkAddrPattern("/graves"))     graves  = theOscMessage.get(0).floatValue();
  else if (theOscMessage.checkAddrPattern("/agudos"))     agudos  = theOscMessage.get(0).floatValue();
  else if (theOscMessage.checkAddrPattern("/brillos"))    brillos = theOscMessage.get(0).floatValue();
  else if (theOscMessage.checkAddrPattern("/beat")) {
    if (theOscMessage.get(0).intValue() == 1) {
      central.impulso(30);
      lateral1.impulso(55);
      lateral2.impulso(55);
      lateral3.impulso(55);
      lateral4.impulso(55);
      estorninos.impulsoWeb(70);
      beatForce = 15;
      beatHue  += 120;  // salto de 120° en el espectro (tercio del círculo cromático)
    }
  }
}
