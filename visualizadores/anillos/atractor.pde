class Atractor {
            PVector posicion, origen_icono;
            float sentido;
            int tipo_atractor;
            int interaccion;
            PVector f;   // OPT3: pre-allocado, evita new PVector por llamada

            Atractor (int clase){
                                posicion=new PVector(random(width), random(height));
                              interaccion=0;
                              sentido=-1;
                              tipo_atractor=clase;
                              origen_icono=new PVector(0,0);
                              f=new PVector();
                                }
            PVector force (PVector posicionobjeto){
                                                    f.set(posicionobjeto);   // OPT3: reutiliza f
                                                    f.sub(posicion);

                                                    float modulo=f.mag();
                                                    if (modulo <0) {f.mult(-1);}
                                                    f.normalize();
                                                    switch(tipo_atractor) {
                                                                         case 1:
                                                                              f.mult(modulo/50);
                                                                         break;
                                                                         case 2:
                                                                              f.mult(150/modulo);
                                                                         break;
                                                                         case 3:
                                                                              f.mult(4);
                                                                         break;
                                                                         case 4:
                                                                              f.mult(150/modulo*modulo);
                                                                         break;
                                                                           }
                                                    f.mult(sentido);
                                                    return f;
                                                    }
           void visible(){stroke(0);
                            strokeWeight(1);
                            noFill();
                            ellipse(posicion.x, posicion.y, 10, 10);
                          }

}
