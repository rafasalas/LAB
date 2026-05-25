class Chain {

            int number_links, radius_link;
            ArrayList<Particula> links;
            float[] masses;

            int classparticle;
            PVector velocidadinicial;
            PVector origen;
            int limsup, liminf, limizq, limder;
            PVector browniano;
            boolean esbrowniano;
            float magbrowniano;
            PVector _radius; // pre-allocado para actualizar(), evita new PVector x2 por link

            Chain(){
              float masaparticula=random(5,50);
              number_links=6;
              radius_link=500;
              limsup=0;
              liminf=height;
              limizq=0;
              limder=width;
              origen=new PVector(random(0,width),random(0,height));
              links=new ArrayList<Particula>();
              esbrowniano=true;
              magbrowniano=.8;
              browniano=new PVector(0,0);
              _radius=new PVector(0,0);
              float[] masses=new float[number_links];
                for(int i=0; i<number_links; i++){
                          if (i==0){velocidadinicial=new PVector(random(-5,5),random(-5,5));} else {velocidadinicial=new PVector(0,0);}
                          masses[i]=masaparticula/((i+1));
                          links.add(new Astilla(origen, velocidadinicial, masses[i]));
                          links.get(i).eterna=true;
                          links.get(i).liminf=liminf;
                          links.get(i).limsup=limsup;
                          links.get(i).limizq=limizq;
                          links.get(i).limder=limder;
                }
            }

            void aceleradorparticulas(Atractor a){
              for (int i = 0; i < links.size(); i++) {
                Particula l = links.get(i);
                l.acelerar(a.fuerza(l.posicion));
                if(esbrowniano){
                  browniano.set(0, magbrowniano);
                  browniano.rotate(l.velocidad.heading());
                  l.acelerar(browniano);
                }
              }
            }

            void aceleradorparticulas_dual(Atractor a, Atractor b){
              for (int i = 0; i < links.size(); i++) {
                Particula l = links.get(i);
                if (i<5) {l.acelerar(a.fuerza(l.posicion));} else {l.acelerar(b.fuerza(l.posicion));}
                if(esbrowniano){
                  browniano.set(0, magbrowniano);
                  browniano.rotate(l.velocidad.heading());
                  l.acelerar(browniano);
                }
              }
            }

            void aceleradorparticulas_cola(Atractor a){
              for (int i = 1; i < links.size(); i++) {
                Particula l = links.get(i);
                l.acelerar(a.fuerza(l.posicion));
                if(esbrowniano){
                  browniano.set(0, magbrowniano);
                  browniano.rotate(l.velocidad.heading());
                  l.acelerar(browniano);
                }
              }
            }

            void actualizar(){
              for (int i = 0; i < links.size(); i++) {
                Particula l = links.get(i);
                l.actualizar();
                if (i!=0){
                  Particula l_ant = links.get(i-1);
                  _radius.set(l.posicion);
                  _radius.sub(l_ant.posicion);
                  _radius.limit(radius_link);
                  l.posicion.set(l_ant.posicion);
                  l.posicion.add(_radius);
                }
              }
            }

            void mostrar(){
              noFill();
              strokeWeight(1);
              stroke(255, 255, 255, 35);
              beginShape();
              for (int i = 0; i < links.size(); i++) {
                Particula l = links.get(i);
                curveVertex(l.posicion.x, l.posicion.y);
              }
              endShape();
            }

//end class chain
}
