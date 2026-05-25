class Particula {
int r,g,b,a;
  PVector posicion, velocidad, aceleracion, gravedad;
  float limite;
  float masa;
  boolean resistencia;
  float coefroz;
  float lifespan;
  boolean eterna;
  int decay;
  Particula() {
    posicion=new PVector(random(width), random(height));
    velocidad=new PVector (0, 0);
    aceleracion=new PVector (0, 0);
    gravedad=new PVector (0, 0.02);
    limite=25;
    masa=random(3, 18);
    resistencia=false;
         r=int(random(0,255));
          g=int(random(0,255));
          b=int(random(0,255));
          a=int(random(0,255));
    lifespan=255;
    eterna=false;
    decay=2;
    //masa=30;
  }

  void acelerar(PVector acelerador) {
    PVector a=PVector.div(acelerador, masa);
    aceleracion.add(a);
  }
  void caer() {
    velocidad.add(gravedad);
  }
  void resistencia(float coeficiente) {
    resistencia=true; 
    coefroz=coeficiente;
  }
  
  boolean muerta(){
          if (lifespan<0){return true;}else{return false;}
                
  
  }
  
  void actualizar() { 
if (eterna==false){lifespan-=decay;}
    velocidad.add(aceleracion);
    if (resistencia) {
      PVector friccion=velocidad.get();

      friccion.normalize();
      friccion.mult(-1*coefroz);
      velocidad.add(friccion);
    }
    velocidad.limit(limite);
    posicion.add(velocidad);
    
    
    
    aceleracion.mult(0);

    if (posicion.x > width ) {
      velocidad.x = velocidad.x*-1;
      posicion.x=width;
    } 
    if ( posicion.x < 0) {
      velocidad.x = velocidad.x*-1;
      posicion.x=0;
    } 
    if (posicion.y > height ) {
      velocidad.y = velocidad.y*-1;
      posicion.y=height;
    }
    if (posicion.y < 0) {
      velocidad.y = velocidad.y*-1;
      posicion.y=0;
    }
  }
  color colorPorVelocidad(float vel) {
    color[] paleta = {
      color( 20,   0, 200),   // azul profundo  — vel baja
      color(  0, 200, 255),   // cian
      color(  0, 230,  80),   // verde
      color(220, 230,   0),   // amarillo
      color(255,  60,   0)    // rojo           — vel alta
    };
    float seg = constrain(vel / limite, 0, 1) * (paleta.length - 1);
    int idx = (int) seg;
    if (idx >= paleta.length - 1) return paleta[paleta.length - 1];
    return lerpColor(paleta[idx], paleta[idx + 1], seg - idx);
  }

    void mostrar() {
      if (eterna==false){ a=int(lifespan);}
                    color c = colorPorVelocidad(velocidad.mag());
                    stroke(red(c), green(c), blue(c), a);
                    strokeWeight(1);
                    fill(red(c), green(c), blue(c), a);
                    ellipse (posicion.x, posicion.y, masa, masa);
                      }
 void lanzar(){
          actualizar();
          mostrar();
        
  
  
  }         
 
}
class Burbuja extends Particula{
        
  
         Burbuja(PVector origen, PVector vinicial, float masap){

         
         super();
       
         posicion.set(origen);
         masa=masap;
         velocidad=vinicial;
        
        }
            
}


class Astilla extends Particula{
      
        float angular;
         Astilla(PVector origen, PVector vinicial, float masap){

         
         super();
          posicion.set(origen);
         masa=masap;
         velocidad=vinicial;
          angular=0;
     }
    void mostrar() {
                   if (eterna==false){ a=int(lifespan);}
                    stroke (r,g,b,a);
                    strokeWeight(1);
                      fill(r,g,b,a);
                      //angular=atan2(velocidad.y,velocidad.x);
                      angular=velocidad.heading()+(PI);
                      //angular=constrain (angular,-0.1,0.1);
                      
                      
                      rectMode (CENTER);
                     pushMatrix();
                     translate(posicion.x, posicion.y);
                     rotate(angular);
                    rect (0, 0, 2*masa,masa);
                    popMatrix();
                      }
                      
                      
                      void lanzar(){
                          actualizar();
                          mostrar();
                         
                                     }        
}





class Dardo extends Particula{
      
        float angular;
         Dardo(PVector origen, PVector vinicial, float masap){

         
         super();
          posicion.set(origen);
         masa=masap;
         velocidad=vinicial;
          angular=0;
     }
    void mostrar() {
                   if (eterna==false){ a=int(lifespan);}
                          stroke (r,g,b,a);
                    strokeWeight(1);
                      fill(r,g,b,a);
                      //angular=atan2(velocidad.y,velocidad.x);
                      angular=velocidad.heading()+(3*PI/2);
                      //angular=constrain (angular,-0.1,0.1);
                      
                      
                      //rectMode (CENTER);
                     pushMatrix();
                     translate(posicion.x, posicion.y);
                     rotate(angular);
                    triangle (0, 0, masa/2, 2*masa,masa,0);
                    popMatrix();
                      }
                      
                      
                      void lanzar(){
                          actualizar();
                          mostrar();
                         
                                     }        
}

class Foto extends Particula{
       PImage img;
        float angular;
        int masafoto;
         Foto(PVector origen, PVector vinicial, float masap){
          
         
         super();
          posicion.set(origen);
         masafoto=int(masap);
         velocidad=vinicial;
          angular=0;
         img=loadImage("texture.png");
     }
    void mostrar() {
                   if (eterna==false){ a=int(lifespan);}
                          //stroke (r,g,b,a);
                   // strokeWeight(1);
                     tint(r,g,b,a);
                      //angular=atan2(velocidad.y,velocidad.x);
                      angular=velocidad.heading()+(3*PI/2);
                      //angular=constrain (angular,-0.1,0.1);
                      
                      
                      imageMode (CENTER);
                     pushMatrix();
                     translate(posicion.x, posicion.y);
                     rotate(angular);
                     //img.resize(masafoto, masafoto);
                    image(img,0,0);
                    popMatrix();
                      }
                      
                      
                      void lanzar(){
                          actualizar();
                          mostrar();
                         
                                     }        
}
