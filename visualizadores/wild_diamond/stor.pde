class Stor {
  
  
        float [] magbrowniano;
        float numeroparticulas, masaparticula;
        int claseparticula, numeroatractores;
        PVector velocidadinicial;
        PVector origen;
        PVector browniano;
        boolean esbrowniano;
        //float magbrowniano;
        ArrayList<Particula> particulas;
        ArrayList<Atractor> atractores;
      
      Stor(float numpart,  int claspart){
                
                numeroparticulas=numpart;
                claseparticula=claspart;
               particulas=new ArrayList<Particula>() ;
               atractores=new ArrayList<Atractor>();
                numeroatractores=3;
                origen=new PVector(random(width), random(height));
                esbrowniano=true;
               magbrowniano=new float[int(numeroparticulas)];
                
                for(int i=0; i<numeroparticulas; i++){
                          velocidadinicial=new PVector (random (-15,15),random(-15,15));
                          masaparticula=random (3,10);
                          switch(claseparticula) {
                                                 case 1: 
                                                  particulas.add(new Astilla(origen, velocidadinicial, masaparticula));
                                                 break;
                                                 case 2: 
                                                   particulas.add(new Burbuja(origen, velocidadinicial, masaparticula));
                                                 break;
                                                case 3: 
                                                   particulas.add(new Dardo(origen, velocidadinicial, masaparticula));
                                                 break;
                                                 
                                                 
                                                 
                                                case 4: 
                                                   particulas.add(new Foto(origen, velocidadinicial, masaparticula));
                                                 break;
                                                  }         
                           particulas.get(i).eterna=true;
                                                  }
                                                  
               for (int j=0; j<numeroatractores;j++){
                                                     atractores.add(new Atractor(1));
                                                     float moneda=random(-3,1);
                                                    atractores.get(j).sentido=moneda;
                                                     atractores.get(j).addicon();
                                                     }
                          
      
            //fin constructor Stor
            }

  void aceleradorparticulas(){
                                for (int i = 0; i < particulas.size(); i++) {
                                Particula p = particulas.get(i);
                                
                                for (int j=0; j<numeroatractores;j++){
                                                                      Atractor a=atractores.get(j);
                                                                      p.acelerar(a.fuerza(p.posicion));
                                                                      if(esbrowniano==true){
                                                                      
                                                                                    browniano=new PVector (0, magbrowniano[j]);
                                                                                    browniano.rotate(p.velocidad.heading());
                                                                                    p.acelerar(browniano);}
                                                                      }
                                
  
                                 }

}
void dibujaparticulas(){
                         for (int j=0; j<numeroatractores;j++){
                                                                      Atractor a=atractores.get(j);
                                                                      a.visible();
                                                                      
                                                                      }
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particula p = particulas.get(i);
                                         p.masa=magbrowniano[i]*10;
                                          p.caer();
                                          p.lanzar();
                         }
                       

}
                      void contacto(){
                                  for (int j=0; j<numeroatractores;j++){
                                                                      Atractor a=atractores.get(j);
                                                                      a.contacto();
                                                                      
                                                                      }

                                                                        }
                      void operador(){
                                  for (int j=0; j<numeroatractores;j++){
                                                                      Atractor a=atractores.get(j);
                                                                      a.operador();
                                                                      
                                                                      }
                      }

                      void liberador(){
                                  for (int j=0; j<numeroatractores;j++){
                                                                      Atractor a=atractores.get(j);
                                                                      a.liberador();
                                                                      
                                                                      }

                                                                        }                                                                        }
                                          
//fin class Stor