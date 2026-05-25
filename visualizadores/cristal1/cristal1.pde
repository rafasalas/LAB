
       import oscP5.*;
       import netP5.*;
int centroX, centroy, contador=0;
PVector centro, calculus;
ArrayList <puntocolor> vertice; 
int numerovertices=100, capas=150;

float angulo=0, paso=(2*PI)/numerovertices;
int radius=0;
int incremento=10;
int masa=72;
Atractor At;
Atractor atBeat;
Atractor atMedios;
int beatTimer = 0;
boolean beatFired = false;
float orbitAngle = 0;
float orbitRadius = 100;
float orbitAngle2 = 0;
float orbitRadius2 = 150;
float bpm = 120;
OscP5 oscP5;
NetAddress dest;
      float signo=0;
                float Factor=50;
                float flujo=0;
                float brillos=0;
                float medios=0;
                float agudos=0;
                float hueShift=0;
                float beatFlash=0;


void setup(){
             oscP5 = new OscP5(this,6448 ); // 
             fullScreen(P2D,2);
           //size(540,960,P2D);
           //size(1000,480,P2D);
           //fullScreen();
              frameRate(60);
              colorMode(HSB, 360, 100, 100, 100);
              At=new Atractor(1);
              At.posicion.x=width/2;
              At.posicion.y=height/2;
              At.sentido=-1;
              atBeat=new Atractor(1);
              atBeat.posicion.x=width/2;
              atBeat.posicion.y=height/2;
              atBeat.sentido=0;
              atMedios=new Atractor(1);
              atMedios.posicion.x=width/2;
              atMedios.posicion.y=height/2;
              atMedios.sentido=0;
              radius=5;
              centro=new PVector(width/2, height/2);
              vertice = new ArrayList<puntocolor>();
              for (int i=0; i<numerovertices*capas; i++){
                //calculus=new PVector(cos(angulo)*radius+random(-15,15),sin(angulo)*radius+random(-15,15));
                calculus=new PVector(cos(angulo)*radius,sin(angulo)*radius);
                                 vertice.add(new puntocolor(calculus, 1, i/numerovertices));
                                  puntocolor Vtemp=vertice.get(i);
                                  Vtemp.posicion.add(centro);
                                  Vtemp.ancla.add(centro);
                                  Vtemp.resistencia=true;
                                  Vtemp.muelle=true;
                                  Vtemp.masa=masa;
                                  //Vtemp.coto=2;
                                  angulo=angulo+paso;
                                  contador++;
                                  if (contador%numerovertices==0){
                                          radius=radius+incremento;
                                          angulo=angulo+(paso/2);
                                          masa=masa+1;
                                        }
                                    }
              
              
              contador =0;
             }
     
              
void draw(){
  if (frameCount == 1 || frameCount % 300 == 0) {
    OscMessage hello = new OscMessage("/hello");
    hello.add("cristal1");
    oscP5.send(hello, new NetAddress("255.255.255.255", 12000));
  }
             noStroke();
             fill(0, 0, 0, map(brillos, 0, 1, 60, 5));
             rect(0, 0, width, height);
             orbitAngle += (bpm / 60.0) * (TWO_PI / frameRate) / 2.0;
             At.posicion.x = centro.x + cos(orbitAngle) * orbitRadius;
             At.posicion.y = centro.y + sin(orbitAngle) * orbitRadius;
             float Factor=-(random(10,10));
             At.sentido=-Factor*flujo;
             orbitAngle2 -= (bpm / 60.0) * (TWO_PI / frameRate) / 3.0;
             atMedios.posicion.x = centro.x + cos(orbitAngle2) * orbitRadius2;
             atMedios.posicion.y = centro.y + sin(orbitAngle2) * orbitRadius2;
             atMedios.sentido = -constrain(medios, 0, 3) * 6;

             if (beatFired) {
               beatFired = false;
               beatFlash = 1.0;
               for (int i = 0; i < vertice.size(); i++) {
                 puntocolor v = vertice.get(i);
                 PVector dir = PVector.sub(v.posicion, centro);
                 dir.normalize();
                 dir.mult(30.0);
                 v.velocidad.set(dir);
                 v.limite = 40;
               }
             }
             hueShift = (hueShift + 0.1 + abs(flujo) * 0.03) % 360;
             beatFlash = max(0, beatFlash - 0.05);
             if (beatTimer > 0) {
               atBeat.sentido = +50.0;
               beatTimer--;
               if (beatTimer == 0) {
                 for (int i = 0; i < vertice.size(); i++) {
                   vertice.get(i).limite = 5;
                 }
               }
             } else {
               atBeat.sentido = 0;
             }

              for (int i = 0; i < vertice.size(); i++) {
                   puntocolor vert=vertice.get(i);

                   vert.acelerar(At.fuerza(vert.posicion));
                   vert.acelerar(atBeat.fuerza(vert.posicion));
                   vert.acelerar(atMedios.fuerza(vert.posicion));

                   vert.actualizar();

              }
             
             
            for (int i=0; i<(numerovertices*capas-1); i++){
                                                
                                                puntocolor Vtemp1=vertice.get(i);
                                                puntocolor Vtemp2=vertice.get(i+1);
                                                    contador++;
                                                  if (i<numerovertices){
                                                          if (i==numerovertices-1){Vtemp2=vertice.get(0);}
                                                          float hue0 = ((Vtemp1.r + hueShift) % 360 + 360) % 360;
                                                          noFill();
                                                          stroke(hue0, min(100, Vtemp1.g + beatFlash*20), min(100, Vtemp1.b + beatFlash*30), min(100, Vtemp1.a + beatFlash*15));
                                                          strokeWeight(3);
                                                          point(Vtemp1.posicion.x, Vtemp1.posicion.y);
                                                      }
                                                  else{

                                                  puntocolor Vtemp_half=vertice.get(i-(numerovertices-1));
                                                  if(contador%numerovertices==0 && contador<numerovertices*capas) {Vtemp2=vertice.get(i-(numerovertices-1));Vtemp_half=vertice.get(i-((numerovertices*2)-1));}

                                                  int capa = i / numerovertices;
                                                  float ag = (capa >= 24) ? constrain(agudos, 0, 2) : 0;
                                                  float hue = ((Vtemp1.r + hueShift + ag * random(-25, 25)) % 360 + 360) % 360;

                                                  if (capa < 20) {
                                                    noFill();
                                                    stroke(hue, min(100, Vtemp1.g + beatFlash*20), min(100, Vtemp1.b + beatFlash*30), min(100, Vtemp1.a + beatFlash*15));
                                                    strokeWeight(3);
                                                    point(Vtemp1.posicion.x, Vtemp1.posicion.y);
                                                  } else {
                                                    noStroke();
                                                    fill(hue,
                                                      min(100, Vtemp1.g + beatFlash * 20),
                                                      min(100, Vtemp1.b + beatFlash * 30 + ag * 12),
                                                      min(100, Vtemp1.a + beatFlash * 15)
                                                    );
                                                    triangle(Vtemp1.posicion.x,Vtemp1.posicion.y,Vtemp_half.posicion.x,Vtemp_half.posicion.y,Vtemp2.posicion.x,Vtemp2.posicion.y);
                                                  }

                                                  }
                                                  
            }
            contador=0;

            }
              void mouseDragged(){
                    // centro=At.posicion;
              // for (int i = 0; i < vertice.size(); i++) {
                //   puntocolor vert=vertice.get(i);
                  
                //   vert.acelerar(At.fuerza(vert.posicion));
                  
                  // vert.actualizar();
                   At.posicion=new PVector(mouseX, mouseY);
                                            //centro.x=mouseX;
//centro.y=mouseY;
                 
               }
            void mousePressed(){//At.posicion=new PVector(mouseX, mouseY);
                                            //centro.x=mouseX;
                                           // centro.y=mouseY;
                              At.sentido=-1;
            
            
            }
             void mouseReleased(){
                              At.sentido=-1;
            
            
            }
       
      void oscEvent(OscMessage theOscMessage) {
 if (theOscMessage.checkAddrPattern("/intensidad")==true) {
        flujo = theOscMessage.get(0).floatValue();
     } else if (theOscMessage.checkAddrPattern("/bpm")==true) {
        bpm = constrain(theOscMessage.get(0).floatValue(), 40, 300);
     } else if (theOscMessage.checkAddrPattern("/beat")==true) {
        if (theOscMessage.get(0).intValue() == 1 && beatTimer == 0) {
          beatTimer = 4;
          beatFired = true;
        }
     } else if (theOscMessage.checkAddrPattern("/brillos")==true) {
        brillos = theOscMessage.get(0).floatValue();
     } else if (theOscMessage.checkAddrPattern("/medios")==true) {
        medios = theOscMessage.get(0).floatValue();
     } else if (theOscMessage.checkAddrPattern("/agudos")==true) {
        agudos = theOscMessage.get(0).floatValue();
     } else {
        println("Error: unexpected OSC message received by Processing: ");
        theOscMessage.print();
      }
 }         
        
              
              
