class Storsimple {
  
  
        float magbrowniano;
        float numeroparticulas, masaparticula;
        int claseparticula;
        PVector velocidadinicial;
        PVector origen;
        PVector browniano;
        int limsup, liminf, limizq, limder; 
        
        boolean esbrowniano;
        //float magbrowniano;
        ArrayList<Particula> particulas;
        
      
      Storsimple(float numpart,  int claspart, int sup, int inf, int izq, int der){
                    limsup=sup;
                    liminf=inf;
                    limizq=izq;
                    limder=der;
                numeroparticulas=numpart;
                claseparticula=claspart;
               particulas=new ArrayList<Particula>() ;
               
               
                //origen=new PVector(random(izq-der), random(inf-sup));
                origen=new PVector(0, 0);
                esbrowniano=true;
               magbrowniano=.8;
                
                for(int i=0; i<numeroparticulas; i++){
                          //velocidadinicial=new PVector (0,50+random(-10,10));
                          velocidadinicial=new PVector (random (width),random(height));
                          //velocidadinicial=new PVector (random (-5,5),random(-5,5));
                          //velocidadinicial=new PVector (0,0);
                          masaparticula=random (8,9);
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
                           particulas.get(i).liminf=inf;
                           particulas.get(i).limsup=sup;
                           particulas.get(i).limizq=izq;
                          particulas.get(i).limder=der;
                                                  }
                                                  
      
      }                       
      
            //fin constructor Storsimple
           

  void aceleradorparticulas(Atractor a){
                                for (int i = 0; i < particulas.size(); i++) {
                                              Particula p = particulas.get(i);
                                               p.acelerar(a.fuerza(p.posicion));
                                               if(esbrowniano==true){
                                                                     browniano=new PVector (0, magbrowniano);
                                                                     browniano.rotate(p.velocidad.heading());
                                                                     p.acelerar(browniano);
                                                                   }
                                               }

}






void dibujaparticulas(int rad, int origen, int tension){
   
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particula p = particulas.get(i);
                                          //noFill();
                                          //stroke (p.r,p.g,p.b,55);
                                          //if (p.posicion.x>(limder-limizq)/2){factor=5;}else{factor=-5;}
                                          
                                          //bezier(p.posicion.x, p.posicion.y, p.posicion.x+factor*10, p.posicion.y+180, (limder-limizq)/2+factor, (liminf-limsup)/2,(limder-limizq)/2,(liminf-limsup));
                                          p.caer();
                                          p.lanzar();
                                          if (rad!=0){
                                          radiales(p.r,p.g,p.b,p.posicion.x, p.posicion.y,rad, origen, tension);}
                                          
                                          
                         }
                       

}


void radiales(int rojo, int verde, int azul, float px, float py, int clase, int origen, int tension){                                           
                    
                      float factor=0;
                      float centrox,centroy;
                      float factor1x,factor1y;
                      float factorx,factory;
                      centrox=(limder-limizq)/2;
                      centroy=(liminf-limsup)/2;
                      colorMode(RGB);
                      switch(origen){
                                    case 0:
                                    centrox=(limder-limizq)/2;
                                    centroy=(liminf-limsup)/2;
                                    break;
                                  case 1:
                                    centrox=(limder-limizq)/2;
                                    centroy=(liminf-limsup);
                                    break;
                      
                                  case 2:
                                    centrox=(limder-limizq);
                                    centroy=(liminf-limsup)/2;
                                    break;                      
                      
                                    case 3:
                                    centrox=(limder-limizq)/2;
                                    centroy=limsup;
                                    break; 
                                  case 4:
                                    centrox=limizq;
                                    centroy=(liminf-limsup)/2;
                                    break;                   
                      
                      }
                      
                      
                                            
                      
                                         //noFill();
                                        stroke (rojo, verde, azul,30);
                                        
  
                                          switch(clase) {
                                                 case 1:
                                                 case 2:
                                                   if (clase==1){noFill();} else {fill (rojo, verde, azul,20);}
                                                
                                                      if (px>centrox){factorx=tension;factor1x=-tension;}else{factorx=-tension;factor1x=+tension;}
                                                      if (py>centroy){factory=50+tension;factor1y=-tension*10;}else{factory=-50-tension;factor1y=-tension*10;}
                                                     
                                                  bezier(px, py, px+factor1x, py+factor1y, centrox+factorx, centroy+factory,centrox, centroy);
                                                 break;
                                                 case 3: 
                                                  line(px, py, centrox, centroy);
                                                  break;                   }
                                          }






 void resize (float min, float max){
 
                                     for(int i=0; i<numeroparticulas; i++){
                                                                             particulas.get(i).masa=random(min, max);
                                     
                                     
                                     }
 
 
 
                                   }

void satura(int valor){                      for (int i = 0; i < particulas.size(); i++) {
                                              particulas.get(i).b=valor;}
                       }

}//fin class Storsimple
class Stor_Repo extends Storsimple{
          Stor_Repo(float numpart,  int claspart, int sup, int inf, int izq, int der){
          super(numpart, claspart, sup, inf, izq,der);
          }
          void reposiciona (int sup, int inf, int izq, int der ){
                                                          for(int i=0; i<numeroparticulas; i++){
                                                                                                                        particulas.get(i).liminf=inf;
                                                                                                                         particulas.get(i).limsup=sup;
                                                                                                                         particulas.get(i).limizq=izq;
                                                                                                                          particulas.get(i).limder=der;
                                                          
                                                          
                                                          }
          
          
          
          
          
          }
  
  
}