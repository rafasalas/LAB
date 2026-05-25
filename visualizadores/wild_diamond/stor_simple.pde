class Storsimple {
  
  
        float magbrowniano;
        float numeroparticulas, masaparticula;
        int claseparticula;
        PVector velocidadinicial;
        PVector origen;
        PVector browniano;
        boolean esbrowniano;
        //float magbrowniano;
        float escala_ruido;
        float t_ruido;
        float tRuidoStep;
        ArrayList<Particula> particulas;
       
      
      Storsimple(float numpart,  int claspart){
                
                numeroparticulas=numpart;
                claseparticula=claspart;
               particulas=new ArrayList<Particula>() ;
               
               
                origen=new PVector(random(width), random(height));
                //origen=new PVector((width/2)+30, (height/2)+30);
                esbrowniano=true;
               magbrowniano=.8;
               escala_ruido=0.003;
               t_ruido=0.0;
               tRuidoStep=0.004;  // controlado externamente por /agudos
                
                for(int i=0; i<numeroparticulas; i++){
                          //velocidadinicial=new PVector (0,50+random(-10,10));
                          velocidadinicial=new PVector (random (width),random(height));
                          //velocidadinicial=new PVector (random (-15,15),random(-15,15));
                          //velocidadinicial=new PVector (10+random(-3,3),10+random(-3,3));
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
                                                  
      
      }                       
      
            //fin constructor Storsimple
           

  void aceleradorparticulas(Atractor a){
                                for (int i = 0; i < particulas.size(); i++) {
                                              Particula p = particulas.get(i);
                                               p.acelerar(a.fuerza(p.posicion));
                                               if(esbrowniano==true){
                                                                     float angulo = map(noise(p.posicion.x * escala_ruido,
                                                                                              p.posicion.y * escala_ruido,
                                                                                              t_ruido), 0, 1, 0, TWO_PI * 2);
                                                                     browniano = new PVector(cos(angulo), sin(angulo));
                                                                     browniano.mult(magbrowniano);
                                                                     p.acelerar(browniano);
                                                                   }
                                               }

}






void dibujaparticulas(Atractor[] atractores){
                      t_ruido += tRuidoStep;
                        for (int i = 0; i < particulas.size(); i++) {
                                         Particula p = particulas.get(i);

                                          p.caer();
                                          p.lanzar();

                                          // atractor más cercano a esta partícula
                                          Atractor cercano = atractores[0];
                                          float distMin = dist(p.posicion.x, p.posicion.y,
                                                               atractores[0].posicion.x, atractores[0].posicion.y);
                                          for (int j = 1; j < atractores.length; j++) {
                                            float d = dist(p.posicion.x, p.posicion.y,
                                                           atractores[j].posicion.x, atractores[j].posicion.y);
                                            if (d < distMin) { distMin = d; cercano = atractores[j]; }
                                          }

                                          noFill();
                                          color c = p.colorPorVelocidad(p.velocidad.mag());
                                          stroke(red(c), green(c), blue(c), 30);

                                          float cx1 = lerp(p.posicion.x, cercano.posicion.x, 0.25);
                                          float cy1 = lerp(p.posicion.y, cercano.posicion.y, 0.25);
                                          bezier(p.posicion.x, p.posicion.y,
                                                 cx1, cy1,
                                                 cercano.posicion.x, cercano.posicion.y,
                                                 cercano.posicion.x, cercano.posicion.y);
                         }
                       

}
}     
//fin class Storsimple