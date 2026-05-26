import oscP5.*;
import netP5.*;

OscP5 oscP5;
float[] value        = new float[512];
int[]   numeroCachos = new int[512];

void setup() {
  fullScreen(P2D, 2);
  //size(1024, 768, P2D);
  frameRate(60);
  background(0);
  smooth(4);
  colorMode(HSB, 360, 100, 100, 255);

  for (int i = 0; i < 512; i++) {
    numeroCachos[i] = (int)random(20, 50);
  }

  OscProperties props = new OscProperties();
  props.setListeningPort(6449);
  props.setDatagramSize(8192);
  oscP5 = new OscP5(this, props);
}

void draw() {
  if (frameCount == 1 || frameCount % 300 == 0) {
    OscMessage hello = new OscMessage("/hello");
    hello.add("azteca_osc");
    oscP5.send(hello, new NetAddress("255.255.255.255", 12000));
  }

  noStroke();
  fill(0, 0, 0, 95);
  rect(0, 0, width, height);

  float cx = width  / 2.0;
  float cy = height / 2.0;

  for (int i = 10; i < 300; i += 10) {
    float sumaEspacios = (5.0 / i) * numeroCachos[i];
    float angulo       = (360.0 - sumaEspacios) / numeroCachos[i];
    float angInicial   = (i * 2.0) + value[i];
    float hue     = map(i, 10, 290, 220, 0);
    float sat     = constrain(map(value[i], 0, 200, 40, 100), 40, 100);
    float bri     = constrain(map(value[i], 0, 200, 50, 100), 50, 100);
    float alfa    = constrain(map(value[i], 0, 200, 90, 230), 90, 230);
    float anguloX = angulo * 2.5;

    for (int j = 0; j < numeroCachos[i]; j++) {
      arco(1000, anguloX, angInicial, 8, i * 2, cx, cy, hue, sat, bri, alfa);
      angInicial += angulo + 5;
    }
  }
}

void arco(float res, float ang, float angInicial, float ancho, float radius,
          float cx, float cy, float r, float g, float b, float a) {
  float paso        = TWO_PI / res;
  float anguloRad   = radians(ang);
  float iniRad      = radians(angInicial);
  int   p0          = (int)(iniRad    / paso);
  int   p1          = (int)(anguloRad / paso) + p0;

  fill(r, g, b, a);
  beginShape();
  for (int i = p0; i < p1; i++) {
    float angle = i * paso;
    vertex(cx + cos(angle) * radius,          cy + sin(angle) * radius);
  }
  for (int i = p1; i > p0; i--) {
    float angle = i * paso;
    vertex(cx + cos(angle) * (radius - ancho), cy + sin(angle) * (radius - ancho));
  }
  endShape(CLOSE);
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/fft_value")) {
    int count = msg.arguments().length;
    for (int j = 0; j < min(511, count); j++) {
      value[j] = msg.get(j).floatValue() * 100;
    }
  }
}
