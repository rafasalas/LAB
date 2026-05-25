
  import oscP5.*;
                import netP5.*;








int opacidad;
Storsimple estorninos;
Atractor central, lateral1, lateral2, lateral3,lateral4;
color color_fondo, color_particula;
float flujo;
float flujo_suavizado;
float graves;
float graves_suavizado;
float agudos;
float agudos_suavizado;
float exponente = 2.0;
int beatTimer = 0;
float bpm = 0;
float orbitAngle = 0;
//Variables de OSC
OscP5 oscP5;
NetAddress dest;


void setup (){//size (650,800, P2D);
fullScreen(P2D,2);
              smooth(8);
            frameRate(60);
            opacidad=255;
    estorninos=new Storsimple(4000,2); 
     oscP5 = new OscP5(this,6448 ); //   
    central=new Atractor(1);
    lateral1=new Atractor(1);
    lateral2=new Atractor(1);
    lateral3=new Atractor(1);
     lateral4=new Atractor(1);
    central.posicion=new PVector(width/2, height/2); 
 lateral1.posicion=new PVector(width/2, height/8);
 lateral2.posicion=new PVector(width/8, height/2);
 lateral3.posicion=new PVector(7*(width/8), height/2);
 lateral4.posicion=new PVector((width/2), 7*(height/8));
     color_fondo=color(0,0,0);
    flujo=0;
    flujo_suavizado=0;
    }


void draw(){
  if (frameCount == 1 || frameCount % 300 == 0) {
    OscMessage hello = new OscMessage("/hello");
    hello.add("wild_diamond");
    oscP5.send(hello, new NetAddress("255.255.255.255", 12000));
  }

flujo_suavizado  = lerp(flujo_suavizado,  flujo,  0.25);
graves_suavizado = lerp(graves_suavizado, graves, 0.25);
agudos_suavizado = lerp(agudos_suavizado, agudos, 0.15);
float flujo_curva  = pow(max(0.0, flujo_suavizado),  exponente);
float graves_curva = pow(max(0.0, graves_suavizado), exponente);

// /agudos controla la velocidad de evolución del campo Perlin
estorninos.tRuidoStep = 0.004 + agudos_suavizado * 0.007;

central.sentido = -1 - flujo_curva;
if (beatTimer > 0) {
  lateral1.sentido = +8.0;
  lateral2.sentido = +8.0;
  lateral3.sentido = +8.0;
  lateral4.sentido = +8.0;
  beatTimer--;
} else {
  lateral1.sentido = -0.3 - 0.5 * graves_curva;
  lateral2.sentido = -0.3 - 0.5 * graves_curva;
  lateral3.sentido = -0.3 - 0.5 * graves_curva;
  lateral4.sentido = -0.3 - 0.5 * graves_curva;
}








// Órbita de atractores laterales sincronizada al BPM
// 1 rotación completa cada 4 beats (1 compás en 4/4)
if (bpm > 0) {
  orbitAngle += (bpm / 60.0) * TWO_PI / 60.0 / 4.0;
  float cx = width / 2.0,  cy = height / 2.0;
  float rx = 3.0 * width / 8.0, ry = 3.0 * height / 8.0;
  lateral1.posicion.set(cx + rx*cos(orbitAngle - HALF_PI), cy + ry*sin(orbitAngle - HALF_PI));
  lateral2.posicion.set(cx + rx*cos(orbitAngle + PI),      cy + ry*sin(orbitAngle + PI));
  lateral3.posicion.set(cx + rx*cos(orbitAngle),           cy + ry*sin(orbitAngle));
  lateral4.posicion.set(cx + rx*cos(orbitAngle + HALF_PI), cy + ry*sin(orbitAngle + HALF_PI));
}

noStroke();
fill(0, 0, 0, 25);
rect(0, 0, width, height);



estorninos.aceleradorparticulas(central);
estorninos.aceleradorparticulas(lateral1);
estorninos.aceleradorparticulas(lateral2);
estorninos.aceleradorparticulas(lateral3);
estorninos.aceleradorparticulas(lateral4);
estorninos.dibujaparticulas(new Atractor[]{central, lateral1, lateral2, lateral3, lateral4});
//central.visible();
//lateral1.visible();
//lateral2.visible();
//lateral3.visible();
//lateral4.visible();



}

//This is called automatically when OSC message is received
void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/intensidad") == true) {
    flujo = theOscMessage.get(0).floatValue();
  } else if (theOscMessage.checkAddrPattern("/graves") == true) {
    graves = theOscMessage.get(0).floatValue();
  } else if (theOscMessage.checkAddrPattern("/bpm") == true) {
    bpm = theOscMessage.get(0).floatValue();
  } else if (theOscMessage.checkAddrPattern("/agudos") == true) {
    agudos = theOscMessage.get(0).floatValue();
  } else if (theOscMessage.checkAddrPattern("/beat") == true) {
    if (theOscMessage.get(0).intValue() == 1) {
      beatTimer = 3;
    }
  } else {
    println("OSC no reconocido: " + theOscMessage.addrPattern());
  }
 }
