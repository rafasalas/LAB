import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress broadcastAddress;

volatile float flujo = 0;

Swarm enjambre, enjambre_1, enjambre_2, enjambre_3, enjambre_4, enjambre_5;
System_atractor atractor;
PVector vib;

void setup() {
  fullScreen(P2D, 2);
  frameRate(60);
  smooth(4);

  oscP5 = new OscP5(this, 6448);
  broadcastAddress = new NetAddress("255.255.255.255", 12000);

  // 3500 partículas por enjambre (21.000 total), clase 9 (cuadrado hueco)
  enjambre   = new Swarm(3500, 9, 10, height-10, 150, width-150);
  enjambre_1 = new Swarm(3500, 9, 10, height-10, 150, width-150);
  enjambre_2 = new Swarm(3500, 9, 10, height-10, 150, width-150);
  enjambre_3 = new Swarm(3500, 9, 10, height-10, 150, width-150);
  enjambre_4 = new Swarm(3500, 9, 10, height-10, 150, width-150);
  enjambre_5 = new Swarm(3500, 9, 10, height-10, 150, width-150);

  enjambre.sostenido   = true; enjambre.valorsostenido   = 100;
  enjambre_1.sostenido = true; enjambre_1.valorsostenido = 12;
  enjambre_2.sostenido = true; enjambre_2.valorsostenido = 8;
  enjambre_3.sostenido = true; enjambre_3.valorsostenido = 6;
  enjambre_4.sostenido = true; enjambre_4.valorsostenido = 4;

  // Paleta multicolor: 6 tonos bien separados en el espectro
  enjambre.monocolor(  220,  60,  20,  255, 100,  50);   // naranja-rojo
  enjambre_1.monocolor( 20,  90, 220,   50, 130, 255);   // azul eléctrico
  enjambre_2.monocolor( 40, 200,  60,   80, 240, 100);   // verde lima
  enjambre_3.monocolor(220, 180,   0,  255, 220,  40);   // dorado
  enjambre_4.monocolor(140,  20, 200,  180,  60, 240);   // violeta
  enjambre_5.monocolor(  0, 180, 220,   30, 220, 255);   // cian

  atractor = new System_atractor(width/2, height/2, width*2, height*2);
}

void draw() {
  background(0);

  vib = new PVector(width/2 + random(-20, 20), height/2 + random(-20, 20));
  atractor.situacion(vib);

  enjambre.aceleratorsystem(atractor, flujo);
  enjambre_1.aceleratorsystem(atractor, flujo);
  enjambre_2.aceleratorsystem(atractor, flujo);
  enjambre_3.aceleratorsystem(atractor, flujo);
  enjambre_4.aceleratorsystem(atractor, flujo);
  enjambre_5.aceleratorsystem(atractor, (flujo/4)*(flujo/4));

  enjambre.displayBatch();
  enjambre_1.displayBatch();
  enjambre_2.displayBatch();
  enjambre_3.displayBatch();
  enjambre_4.displayBatch();
  enjambre_5.displayBatch();

  if (frameCount % 300 == 0) {
    OscMessage helloMsg = new OscMessage("/hello");
    helloMsg.add("anillos");
    oscP5.send(helloMsg, broadcastAddress);
  }
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/intensidad")) {
    flujo = msg.get(0).floatValue();
  }
}

void keyPressed() {
  if (key == 's') {
    enjambre.switch_class(int(random(1, 10)));
    enjambre_1.switch_class(int(random(1, 10)));
    enjambre_2.switch_class(int(random(1, 10)));
    enjambre_3.switch_class(int(random(1, 10)));
    enjambre_4.switch_class(int(random(1, 10)));
    enjambre_5.switch_class(int(random(1, 10)));
  }
}
