class Icono{
            PVector centroicono;
            float angulo;
            ArrayList<Manipulador> manipuladores;
            Icono (PVector posicionicono){
  
                                 centroicono=posicionicono;
                                 angulo=0;
                                 manipuladores = new ArrayList<Manipulador>();
  }
  
void addmanipulador (PVector c, float r, String n, int i, int tipo){
                      switch(tipo){
                                  case 1:
                                    manipuladores.add (new Manipulador(c,r,n, i));
                                   break;
                                   case 2:
                                    manipuladores.add (new MAtractor(c,r,n, i));
                                   break;
                                   case 3:
                                    manipuladores.add (new Repulsor(c,r,n, i));
                                   break;
                                    }



}
  
  
  
  int contacto (float angulodesalida){
    
                              int tipointeraccion=0;
                              for (int i = 0; i < manipuladores.size(); i++) {
                                              Manipulador m = manipuladores.get(i);
                                              
                                              if (tipointeraccion==0){tipointeraccion=m.contacto(angulodesalida, centroicono);} 
                              
                              
                              
                                            }
                              //println(tipointeraccion);
                              if (tipointeraccion!=0){
                                                       for (int i = 0; i < manipuladores.size(); i++) {
                                                        Manipulador m = manipuladores.get(i); 
                                                              m.reloj=300;
                                                            }  
                              
                              
                              
                              
                                                    }
                              return tipointeraccion;
                              }
  
  
  
  
  
  
  
  
  void dibujar(float angulodesalida){
                    
                  
                    
                    for (int i = 0; i < manipuladores.size(); i++) {
                                                                       Manipulador m = manipuladores.get(i);
                                                                       m.dibuja(angulodesalida, centroicono);
                    
                                                                    } 
                              
                              
                              
                              
                    
                      }
  
  
void liberador(){
                    for (int i = 0; i < manipuladores.size(); i++) {
                                                                       Manipulador m = manipuladores.get(i);
                                                                       m.liberador();
                    
                                                                    } 



                }


//final de la clase icono
}