class Particle {
                int r,g,b,a;
                PVector posicion, velocidad, aceleracion, gravedad;
                float limite;
                float masa;
                float angular;
                float opacity_global;
                boolean resistencia;
                float coefroz;
                float lifespan;
                boolean eterna;
                int particle_class;
                int decay;
                int limsup, liminf, limizq, limder;
                int difuse, limit_difuse;
                Particle(PVector origen, PVector vinicial, float masap) {
                              limsup=0;
                              liminf=height;
                              limizq=0;
                              limder=width;
                              posicion=new PVector(random(limder-limizq), random(liminf-limsup));
                              posicion.set(origen);
                              velocidad=vinicial;
                              aceleracion=new PVector(0, 0);
                              gravedad=new PVector(0, 0.02);
                              limite=17;
                              masa=masap;
                              resistencia=false;
                              r=int(random(0,255));
                              g=int(random(0,255));
                              b=int(random(0,255));
                              a=int(random(0,255));
                              lifespan=255;
                              eterna=false;
                              decay=2;
                              particle_class=0;
                              angular=0;
                              difuse=10;
                              limit_difuse=int(random(-difuse,+difuse));
                              opacity_global=1;
                }

                // OPT3: evita PVector.div() — sin allocations
                void acelerate(PVector acelerator) {
                                                  aceleracion.x += acelerator.x / masa;
                                                  aceleracion.y += acelerator.y / masa;
                }
                void fall() {
                              velocidad.add(gravedad);
                }
                void resistence(float coeficiente) {
                }

                boolean dead(){
                                if (lifespan<0){return true;}else{return false;}
                }

                // OPT1: física sin render — usado por Swarm.displayBatch()
                void updatePhysics() {
                                               fall();
                                               if (eterna==false){lifespan-=decay;}
                                               velocidad.add(aceleracion);
                                               if (resistencia) {
                                                PVector friccion=velocidad.copy();
                                                friccion.normalize();
                                                friccion.mult(-1*coefroz);
                                                velocidad.add(friccion);
                                                }
                                                velocidad.limit(limite);
                                                posicion.add(velocidad);
                                                aceleracion.mult(0);
                                                if (posicion.x > limder+limit_difuse) {
                                                  velocidad.x = velocidad.x*-1;
                                                  posicion.x = limder+limit_difuse;
                                                }
                                                if (posicion.x < limizq+limit_difuse) {
                                                  velocidad.x = velocidad.x*-1;
                                                  posicion.x = limizq+limit_difuse;
                                                }
                                                if (posicion.y > liminf+limit_difuse) {
                                                  velocidad.y = velocidad.y*-1;
                                                  posicion.y = liminf+limit_difuse;
                                                }
                                                if (posicion.y < limsup+limit_difuse) {
                                                  velocidad.y = velocidad.y*-1;
                                                  posicion.y = limsup+limit_difuse;
                                                }
                }

                void actualize() {
                                               updatePhysics();
                                               display();
                }

                 void display() {
                                  int alfa=int(float(a)*opacity_global);
                                  stroke(r,g,b,alfa);
                                  strokeWeight(1);
                                  fill(r,g,b,alfa);
                                  switch(particle_class) {
                                                          case 0:
                                                                ellipse(posicion.x, posicion.y, masa, masa);
                                                          break;
                                                          case 1:
                                                                angular=velocidad.heading()+(PI);
                                                                rectMode(CENTER);
                                                                pushMatrix();
                                                                translate(posicion.x, posicion.y);
                                                                rotate(angular);
                                                                rect(0, 0, 4*masa, masa/2);
                                                                popMatrix();
                                                          break;
                                                          case 2:
                                                                angular=velocidad.heading()+(PI);
                                                                rectMode(CENTER);
                                                                pushMatrix();
                                                                translate(posicion.x, posicion.y);
                                                                rotate(angular);
                                                                rect(0, 0, masa, masa);
                                                                popMatrix();
                                                          break;
                                                          case 3:
                                                                angular=velocidad.heading()+(3*PI/2);
                                                                pushMatrix();
                                                                translate(posicion.x, posicion.y);
                                                                rotate(angular);
                                                                triangle(0, 0, masa/2, 2*masa, masa, 0);
                                                                popMatrix();
                                                          break;
                                                          case 4:
                                                                strokeWeight(masa);
                                                                point(posicion.x, posicion.y);
                                                                strokeWeight(1);
                                                          break;
                                                          case 5:
                                                                strokeWeight(3);
                                                                point(posicion.x, posicion.y);
                                                                strokeWeight(1);
                                                          break;
                                                          case 6:
                                                                angular=velocidad.heading()+(PI);
                                                                rectMode(CENTER);
                                                                pushMatrix();
                                                                translate(posicion.x, posicion.y);
                                                                rotate(angular);
                                                                rect(0, 0, 3*masa, 3*masa);
                                                                popMatrix();
                                                          break;
                                                          case 7:
                                                                stroke(255,255,255,alfa);
                                                                strokeWeight(8);
                                                                point(posicion.x, posicion.y);
                                                                stroke(255,255,255,25);
                                                                strokeWeight(masa*3);
                                                                point(posicion.x+1, posicion.y+1);
                                                          break;
                                                          case 8:
                                                                stroke(r,g,b,alfa);
                                                                strokeWeight(8);
                                                                point(posicion.x, posicion.y);
                                                                stroke(r,g,b,25);
                                                                strokeWeight(masa*3);
                                                                point(posicion.x+1, posicion.y+1);
                                                          break;
                                                          case 9:
                                                                noFill();
                                                                strokeWeight(1);
                                                                angular=velocidad.heading()+(PI);
                                                                rectMode(CENTER);
                                                                pushMatrix();
                                                                translate(posicion.x, posicion.y);
                                                                rotate(angular);
                                                                rect(0, 0, 3*masa, 3*masa);
                                                                popMatrix();
                                                                fill(r,g,b,alfa);
                                                          break;
                                                          }
                                  }
                }
