class Mat_point{
                PVector posicion, velocidad, aceleracion;
                PVector ancla;
                float masa, coto,  factor_rozamiento, kmuelle;
                boolean resistencia, muelle;
                float limite;
                Mat_point (PVector pos, float peso){
                                    posicion=pos;
                                    ancla=new PVector(posicion.x,posicion.y);
                                    masa=peso;
                                    velocidad=new PVector (0,0);
                                    aceleracion=new PVector (0,0);
                                    coto=275;
                                    factor_rozamiento=.04;
                                    muelle=false;
                                    kmuelle=.01;
                                     resistencia=false;
                                     limite=5;
 }
               
                void acelerar(PVector acelerador) {
                    PVector a=PVector.mult(acelerador, 1/masa);
                    aceleracion.add(a);
                    if (muelle){
                                //PVector recuperacion=new PVector(aceleracion.x, aceleracion.y);
                                PVector recuperacion=PVector.sub(posicion, ancla);
                                recuperacion.normalize();
                               float d=ancla.dist(posicion);
                               //println(d);
                               recuperacion.mult(-1*kmuelle*d);
                             aceleracion.add(recuperacion);
                                
                    }
     
                  }

    void actualizar() { 

    velocidad.add(aceleracion);
  PVector oldpos=new PVector(this.posicion.x, this.posicion.y);
  
   velocidad.limit(limite);
    posicion.add(velocidad);
                 if (resistencia) {
                                    velocidad.mult(1.0 - factor_rozamiento);
                                  }
    
    aceleracion.mult(0);

   
  }



}



class puntocolor extends Mat_point{
                    // En modo HSB: r=H (0-360), g=S (0-100), b=B (0-100), a=A (0-100)
                    int r,g,b,a;
                    // Constructor original: paleta fija en 3 zonas (para mallas de 36+ capas)
                    puntocolor(PVector pos, float masa, int capa){
                                    super(pos, masa);
                                    if (capa < 12) {
                                      r = (int) map(capa, 0, 11, 220, 180);
                                      g = 75;
                                      b = (int) random(65, 88);
                                    } else if (capa < 24) {
                                      r = (int) map(capa, 12, 23, 120, 50);
                                      g = 80;
                                      b = (int) random(70, 92);
                                    } else {
                                      r = (int) map(capa, 24, 35, 30, 0);
                                      g = 85;
                                      b = (int) random(75, 95);
                                    }
                                    a = (int) random(60, 90);
                    }

                    // Constructor proporcional: espectro 0°–300° repartido sobre totalCapas
                    puntocolor(PVector pos, float masa, int capa, int totalCapas){
                                    super(pos, masa);
                                    r = (int) map(capa, 0, max(totalCapas - 1, 1), 0, 300);
                                    g = (int) random(70, 90);
                                    b = (int) random(70, 95);
                                    a = (int) random(60, 90);
                    }



}