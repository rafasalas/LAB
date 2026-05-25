class Manipulador {
float radius;
String nombre;
PVector centromanipulador;
boolean activado;

int reloj;




int indice;
Manipulador(PVector c, float r, String n, int i){

                centromanipulador=c;
                radius=r;
                nombre=n;
                indice=i;
                activado=false;
                reloj=300;
                opacidad=255;
              }

void dibuja (float angulodesalida, PVector ci){
          //reloj--;
          if (reloj<255){opacidad=reloj;} else {opacidad=255;}
          opacidad=255;
          pushMatrix();
          translate(ci.x, ci.y);
          rotate(angulodesalida);
          if(activado){ fill(255,255,255,opacidad);} else {noFill();}
          
          stroke (255,255,255,opacidad);
          strokeWeight(3);
          ellipse (centromanipulador.x, centromanipulador.y, radius, radius);
          
          popMatrix();
          


}

int contacto(float angulodesalida, PVector ci){
              int identi=0;
              PVector mouse, absoluta, resta ;

  
              //println(pmouseX+" "+pmouseY );
              absoluta=centromanipulador.get();
              absoluta.rotate(angulodesalida);
              absoluta.add(ci);
              mouse=new PVector (mouseX, mouseY);
              resta=PVector.sub(mouse,absoluta);
              if (resta.mag()<radius){identi=indice;activado=true;reloj=500;}
              


              return identi;



}
void liberador(){activado=false;}



//fin class manipulador
}

class MAtractor extends Manipulador{
 PImage img;
MAtractor(PVector c, float r, String n, int i){
            
                super(c,r,n,i);
          
          img=loadImage("atractorr.png");

          }

void dibuja (float angulodesalida, PVector ci){
         // reloj--;
          if (reloj<255){opacidad=reloj;} else {opacidad=255;}
          pushMatrix();
          translate(ci.x, ci.y);
          rotate(angulodesalida);
          //if(activado){ fill(255,255,255,opacidad);} else {noFill();}
          
          //stroke (255,255,255,opacidad);
         // strokeWeight(3);
          //ellipse (centromanipulador.x, centromanipulador.y, radius, radius);
         tint (0,0,255, opacidad);
          image(img,centromanipulador.x,centromanipulador.y);
          popMatrix();
}
//fin class MAtractor
}
class Repulsor extends Manipulador{
PImage img;
int pulse;
Repulsor(PVector c, float r, String n, int i){
            
          super(c,r,n,i);
          centromanipulador=c;
                radius=r;
                nombre=n;
                indice=i;
          img=loadImage("atractorr.png");
          pulse=1000;
          }

void dibuja (float angulodesalida, PVector ci){
       // reloj--;
          pulse=pulse-25;
          if (pulse<0) {pulse=1000;}
          if (reloj<255){opacidad=reloj;} else {opacidad=255;}
          pushMatrix();
          translate(ci.x, ci.y);
          rotate(angulodesalida);
          //if(activado){ fill(255,255,255,opacidad);} else {noFill();}
          
          //stroke (255,255,255,opacidad);
         // strokeWeight(3);
          //ellipse (centromanipulador.x, centromanipulador.y, radius, radius);
         tint (255,0,0, opacidad);
         imageMode(CENTER);
          image(img,centromanipulador.x,centromanipulador.y);
                   stroke (0,0,0,opacidad);
          strokeWeight(10);
          ellipseMode(CENTER);
          //ellipse(centromanipulador.x,centromanipulador.y,pulse,pulse);
          popMatrix();
}
//fin class Repulsor
}