import oscP5.*;
import netP5.*;

OscP5 oscP5;
Pompero pompero;

void setup() {
  oscP5 = new OscP5(this, 6448);
  fullScreen(P2D, 1);
  //size(1920, 1080, P2D);
  frameRate(60);
  colorMode(HSB, 360, 100, 100, 100);
  pompero = new Pompero(new PVector(width / 2, height / 2), 1.0);
}

void draw() {
  if (frameCount == 1 || frameCount % 300 == 0) {
    OscMessage hello = new OscMessage("/hello");
    hello.add("cristal2");
    oscP5.send(hello, new NetAddress("255.255.255.255", 12000));
  }
  noStroke();
  fill(0, 0, 0, map(pompero.brillos, 0, 1, 60, 5));
  rect(0, 0, width, height);
  pompero.update();
  pompero.display();
}

void mouseDragged() {
  for (mandala_evanescente m : pompero.mandalas) m.moverAtractor(mouseX, mouseY);
}

void mousePressed() {
  for (mandala_evanescente m : pompero.mandalas) m.resetearAtractor();
}

void mouseReleased() {
  for (mandala_evanescente m : pompero.mandalas) m.resetearAtractor();
}

void oscEvent(OscMessage msg) {
  if      (msg.checkAddrPattern("/intensidad")) pompero.onIntensidad(msg.get(0).floatValue());
  else if (msg.checkAddrPattern("/bpm"))        pompero.onBpm(msg.get(0).floatValue());
  else if (msg.checkAddrPattern("/beat"))       pompero.onBeat(msg.get(0).intValue());
  else if (msg.checkAddrPattern("/brillos"))    pompero.onBrillos(msg.get(0).floatValue());
  else if (msg.checkAddrPattern("/medios"))     pompero.onMedios(msg.get(0).floatValue());
  else if (msg.checkAddrPattern("/agudos"))     pompero.onAgudos(msg.get(0).floatValue());
  else println("OSC no reconocido: " + msg.addrPattern());
}
