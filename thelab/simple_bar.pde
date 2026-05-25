class Bar_simple{
                PVector Posicion;
                int Largo, Alto;
                float recorrido;
                Bar_simple(PVector posicion, int largo, int alto){
                        Posicion=posicion;
                         Largo=largo;
                          Alto=alto;     
                          recorrido=0;
                  
                              }//fin constructor

            void display(float donde){
              recorrido=donde*Largo;
             // println(recorrido );
                            pushMatrix();
                             translate(Posicion.x, Posicion.y);
                             noFill();
                             stroke(255,255,255,100);
                             rectMode(CORNER);
                             rect(0,0,Largo,Alto);
                             fill(255,255,255,100);
                             rect(0,0,int(recorrido),Alto);
                             popMatrix();        
            
                  }//fin display
                  
                 float detect_clic(){
                   float pointclic=-1.0;
                            PVector vectorraton;
                  vectorraton=new PVector(mouseX, mouseY);
                  vectorraton.sub(gui.Posiciongui);
                 vectorraton.sub(Posicion);
                 if (vectorraton.x>0 && vectorraton.y>0){
                        if (vectorraton.x<Largo && vectorraton.y<Alto){pointclic=vectorraton.x/float(Largo);}
                           }
                return pointclic;
                 
                 
                 
                 }


}//fin clase Bar_simple