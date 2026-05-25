class Carioca{
               Chain estorninos;
                Atractor central, lateral1, lateral2, lateral3, lateral4;

                int radial=0;
                int centro=0;
                int tension=0;
                int opacidad;
                int Num_part, Tipo_part,X_ini,Y_ini,X_fin,Y_fin;
                int ancho,alto;
                
                
                
                          Carioca (int alt,int anch){
                                  //Num_part=num_part;
                                  //Tipo_part=tipo_part;
                                 // X_ini=x_ini;
                                  //Y_ini=y_ini;
                                  
                                  ancho=anch;
                                  alto=alt;
                                  estorninos=new Chain(); 
                                  central=new Atractor(1);
                                  lateral1=new Atractor(1);
                                  lateral2=new Atractor(1);
                                  lateral3=new Atractor(1);
                                  lateral4=new Atractor(1);
                                  int x=X_ini+ancho/2;
                                  int y=Y_ini+alto/2;
                                   central.posicion=new PVector(x, y); 
                                  lateral1.posicion=new PVector(x, y-(alto/4));
                                  lateral2.posicion=new PVector(x+(ancho/4), y);
                                  lateral3.posicion=new PVector(x, y+(alto/4));
                                  lateral4.posicion=new PVector(x-(ancho/4),y);                                                                  
                          }
                          
                          
            void update (float flujo){
                                
                                central.sentido=-1-flujo; 
                                lateral1.sentido=-0.5*flujo;
                                lateral2.sentido=-0.5*flujo;
                                lateral3.sentido=-0.5*flujo;
                                lateral4.sentido=-0.5*flujo;
                                estorninos.aceleradorparticulas(central);
                                estorninos.aceleradorparticulas(lateral1);
                                estorninos.aceleradorparticulas(lateral2);
                                estorninos.aceleradorparticulas(lateral3);
                                estorninos.aceleradorparticulas(lateral4);
                                
              
            
            }
                                void dibuja(){
                                                noFill();
                                                estorninos.actualizar();
                                                estorninos.mostrar();
                                              }
                          
          
          

              void posiciona(int x,int y){                              
                                  central.posicion.set(x, y); 
                                  lateral1.posicion.set(x, y-(alto/4));
                                  lateral2.posicion.set(x+(ancho/4), y);
                                  lateral3.posicion.set(x, y+(alto/4));
                                  lateral4.posicion.set(x-(ancho/4),y);
                                  //estorninos.reposiciona (y-(alto/2), y+(alto/2),x-(ancho/2),x+(ancho/2));
                                }
             
                                
}