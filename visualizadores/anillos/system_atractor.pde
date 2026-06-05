class System_atractor{
                      Atractor central, lateral1, lateral2, lateral3, lateral4;
                      int ancho,alto;
                      PVector centro;
                      PVector result;   // OPT3: pre-allocado, evita new PVector por llamada

                      System_atractor(int rx,int ry, int anch, int alt){
                                  centro=new PVector(rx, ry);
                                  ancho=anch;
                                  alto=alt;
                                  result=new PVector();

                                  central=new Atractor(1);
                                  lateral1=new Atractor(1);
                                  lateral2=new Atractor(1);
                                  lateral3=new Atractor(1);
                                  lateral4=new Atractor(1);
                                  float x=centro.x;
                                  float y=centro.y;
                                  central.posicion=new PVector(x, y);
                                  lateral1.posicion=new PVector(x, y-(alto/4));
                                  lateral2.posicion=new PVector(x+(ancho/4), y);
                                  lateral3.posicion=new PVector(x, y+(alto/4));
                                  lateral4.posicion=new PVector(x-(ancho/4),y);
                                  }


                    void situacion(PVector center){
                                  float x=center.x;
                                  float y=center.y;
                                  central.posicion=new PVector(x, y);
                                  lateral1.posicion=new PVector(x, y-(alto/4));
                                  lateral2.posicion=new PVector(x+(ancho/4), y);
                                  lateral3.posicion=new PVector(x, y+(alto/4));
                                  lateral4.posicion=new PVector(x-(ancho/4),y);
                                   }

                    PVector force (Particle p, float flujo, PVector browniano){
                                      result.set(0, 0);   // OPT3: reutiliza result
                                      browniano.rotate(p.velocidad.heading());
                                      browniano.mult(20);
                                      central.sentido=-1-flujo;
                                      lateral1.sentido=-0.5*flujo;
                                      lateral2.sentido=-0.5*flujo;
                                      lateral3.sentido=-0.5*flujo;
                                      lateral4.sentido=-0.5*flujo;
                                      result.add(central.force(p.posicion));
                                      result.add(lateral1.force(p.posicion));
                                      result.add(lateral2.force(p.posicion));
                                      result.add(lateral3.force(p.posicion));
                                      result.add(lateral4.force(p.posicion));
                                      result.add(browniano);
                                      return result;
                                  }

                    void visible(){stroke(0);
                            strokeWeight(1);
                            noFill();
                            ellipse(central.posicion.x, central.posicion.y, 10, 10);
                            ellipse(lateral1.posicion.x, lateral1.posicion.y, 10, 10);
                            ellipse(lateral2.posicion.x, lateral2.posicion.y, 10, 10);
                            ellipse(lateral3.posicion.x, lateral3.posicion.y, 10, 10);
                            ellipse(lateral4.posicion.x, lateral4.posicion.y, 10, 10);
                          }


}
