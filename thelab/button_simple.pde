class Buttonsimple{
                    
                  PVector Posicion;
                  int Alto, Ancho;
                  String Filename;
                  PShape formaboton;

        Buttonsimple(int x, int y, int alto, int ancho, String filename){
                  Posicion=new PVector (x,y);
                  Alto=alto;
                  Ancho=ancho;
                  formaboton= loadShape(filename);
                  }
        void display(){shapeMode(CORNER);
              shape(formaboton, Posicion.x,Posicion.y, Ancho, Alto);
              }

              boolean detect(){
                                   Boolean detect=false;
                                   
                                             PVector vectorraton;
                                            vectorraton=new PVector(mouseX, mouseY);
                                            vectorraton.sub(gui.Posiciongui);
                                             vectorraton.sub(Posicion);
                                               if (vectorraton.x>0 && vectorraton.x<Ancho){
                                                    if (vectorraton.y>0 && vectorraton.y<Alto){detect=true;}}
                                                     
                                                  return detect;       
             
             
             }






}