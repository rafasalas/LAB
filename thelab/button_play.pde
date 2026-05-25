class Buttonplay{
              int Alto, Ancho;
              PShape Play, Pause;
              Boolean isPlay=false;
              int X,Y;
              PVector Posicion;
              Buttonplay(int x, int y, int alto, int ancho){
                Alto=alto;
                Ancho=ancho;
                X=x;
                Y=y; 
                Posicion=new PVector (X,Y);
                Play = loadShape("play.svg");
                Pause = loadShape("pause.svg");              
              }

              void display(){
                shapeMode(CENTER);
              if (isPlay){shape(Pause, X, Y, Alto, Ancho);} else {shape(Play, X, Y, Alto, Ancho);}
              }

             boolean detectclic(){
                                   Boolean detect=false;
                                   
                                             PVector vectorraton;
                                            vectorraton=new PVector(mouseX, mouseY);
                                            vectorraton.sub(gui.Posiciongui);
                                             vectorraton.sub(Posicion);
                                             if (vectorraton.mag()<Alto/2){detect=true;isPlay=!isPlay;}
                                      return detect;       
             
             
             }



}