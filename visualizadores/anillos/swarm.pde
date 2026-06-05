class Swarm{
            float magbrowniano;
            float numeroparticulas, masaparticula;
            float opacity_global_swarm;
            int claseparticula;
            PVector velocidadinicial;
            PVector origen;

            int limsup, liminf, limizq, limder;
            PVector browniano;
            boolean esbrowniano;
            boolean sostenido;
            int valorsostenido;
            int targetR, targetG, targetB;
            float colorLerpSpeed;
            ArrayList<Particle> particulas;

            Swarm(float numpart, int claspart, int lsup, int linf, int lizq, int lder){
                                                                                limsup=lsup;
                                                                                liminf=linf;
                                                                                limizq=lizq;
                                                                                limder=lder;
                                                                              numeroparticulas=numpart;
                                                                              claseparticula=claspart;
                                                                               particulas=new ArrayList<Particle>();
                                                                              origen=new PVector(random(lizq,lder), random(linf,lsup));
                                                                              esbrowniano=true;
                                                                               magbrowniano=.8;
                                                                               opacity_global_swarm=1;
                                                                               sostenido=false;
                                                                               valorsostenido=10;
                                                                               targetR=128; targetG=64; targetB=0;
                                                                               colorLerpSpeed=0.08;
                                                                               browniano=new PVector();  // OPT3: pre-allocado

                                                                              for(int i=0; i<numeroparticulas; i++){
                                                                                      velocidadinicial=new PVector(random(-10,10), random(-10,10));
                                                                                       masaparticula=random(8,10);
                                                                                      particulas.add(new Particle(origen, velocidadinicial, masaparticula));
                                                                                      particulas.get(i).particle_class=claseparticula;
                                                                                      particulas.get(i).eterna=true;
                                                                                      particulas.get(i).liminf=liminf;
                                                                                      particulas.get(i).limsup=limsup;
                                                                                      particulas.get(i).limizq=limizq;
                                                                                      particulas.get(i).limder=limder;
                                                                                      particulas.get(i).opacity_global=opacity_global_swarm;
                                                                                                              }
                                                                                }


        void aceleratorparticles(Atractor a){
                                for (int i = 0; i < particulas.size(); i++) {
                                             Particle p = particulas.get(i);
                                             p.acelerate(a.force(p.posicion));
                                                                   if(esbrowniano==true){
                                                                     browniano.set(0, magbrowniano);  // OPT3
                                                                     browniano.rotate(p.velocidad.heading());
                                                                     p.acelerate(browniano);
                                                                   }
                                               }
                              }

         void aceleratorsystem(System_atractor s, float flujo){
                                                             if (sostenido){
                                                                if (flujo>valorsostenido || flujo<-valorsostenido){flujo=flujo*-1;}
                                                                }
                                for (int i = 0; i < particulas.size(); i++) {
                                             Particle p = particulas.get(i);
                                                if(esbrowniano==true){
                                                                     browniano.set(0, magbrowniano);  // OPT3
                                                                   } else {browniano.set(0, 0);}      // OPT3
                                              p.acelerate(s.force(p, flujo, browniano));
                                               }
                              }

        // Render individual (mantiene compatibilidad)
        void display(){
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particle p = particulas.get(i);
                                                  p.opacity_global=opacity_global_swarm;
                                       p.actualize();
                         }
                      }

        // OPT1: render batch — física separada + un único beginShape(LINES) por enjambre
        // Cuadrado hueco: 4 segmentos por partícula, misma geometría que particle_class 9
        void displayBatch(){
                        // Paso 1: física
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particle p = particulas.get(i);
                                         p.opacity_global=opacity_global_swarm;
                                         p.updatePhysics();
                        }
                        // Paso 2: render en un único batch de líneas
                        noFill();
                        strokeWeight(1);
                        beginShape(LINES);
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particle p = particulas.get(i);
                                         int alfa=int(float(p.a)*p.opacity_global);
                                         stroke(p.r, p.g, p.b, alfa);
                                         float ang=p.velocidad.heading()+PI;
                                         float cosA=cos(ang), sinA=sin(ang);
                                         float h=p.masa*1.5;   // semi-lado del cuadrado 3*masa
                                         // 4 esquinas del cuadrado rotado
                                         float ax=p.posicion.x+h*(sinA-cosA), ay=p.posicion.y-h*(sinA+cosA);
                                         float bx=p.posicion.x+h*(cosA+sinA), by=p.posicion.y+h*(sinA-cosA);
                                         float cx=p.posicion.x+h*(cosA-sinA), cy=p.posicion.y+h*(sinA+cosA);
                                         float dx=p.posicion.x-h*(cosA+sinA), dy=p.posicion.y+h*(cosA-sinA);
                                         vertex(ax,ay); vertex(bx,by);
                                         vertex(bx,by); vertex(cx,cy);
                                         vertex(cx,cy); vertex(dx,dy);
                                         vertex(dx,dy); vertex(ax,ay);
                        }
                        endShape();
                      }

      void switch_class(int cl){
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particle p = particulas.get(i);
                                       p.particle_class=cl;
                         }}

       void colorize(int r, int g, int b, int var_r, int var_g, int var_b){
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particle p = particulas.get(i);
                                       p.r=r-int(random(0,var_r));
                                       p.g=g-int(random(0,var_g));
                                       p.b=b-int(random(0,var_b));
                        }
                         }

       void monocolor2(int r, int g, int b, boolean safeR, boolean safeG, boolean safeB){
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particle p = particulas.get(i);
                                       p.r=r; p.g=g; p.b=b;
                                       if (!safeR){p.r=r+(int(random(0,255-r)));}
                                       if (!safeG){p.g=g+(int(random(0,255-g)));}
                                       if (!safeB){p.b=b+(int(random(0,255-b)));}
                                  }
                         }

         void monocolor(int r, int g, int b, int limitr, int limitg, int limitb){
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particle p = particulas.get(i);
                                       p.r=r+(int(random(0,limitr-r)));
                                       p.g=g+(int(random(0,limitg-g)));
                                       p.b=b+(int(random(0,limitb-b)));
                                  }
                         }

void resize(float nuevamasa){
                        for (int i = 0; i < particulas.size(); i++) {
                                        particulas.get(i).masa=nuevamasa;}
                        }

// OPT3: cada partícula lerpa individualmente hacia el target de color
void updateColor(){
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particle p = particulas.get(i);
                                         p.r = int(lerp(p.r, targetR, colorLerpSpeed));
                                         p.g = int(lerp(p.g, targetG, colorLerpSpeed));
                                         p.b = int(lerp(p.b, targetB, colorLerpSpeed));
                        }
                    }

}
