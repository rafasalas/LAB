class Slidersimple{
                PVector posicion_slider;
                int longitud, alto, posicion_marker,altura_marker, radio_marker, inflate;
                color color_marker = color(255,255,255);
                Slidersimple(PVector posicion, int largo){
                              posicion_slider=posicion;
                              longitud=largo;
                              alto=4;
                              altura_marker=alto/2;
                              posicion_marker=5;
                              radio_marker=15;
                              inflate=0;
                              }
                
                void display(){
                                
                             pushMatrix();
                             translate(posicion_slider.x,posicion_slider.y);
                             noFill();
                             stroke(255,255,255,100);
                             rectMode(CORNER);
                             rect(0,0,longitud,alto);
                             fill(color_marker);
                             ellipseMode(CENTER);
                             ellipse(posicion_marker,altura_marker, radio_marker, radio_marker);
                             
                             popMatrix();
                           }
              void display2(){
                              detecthover();   
                             pushMatrix();
                             translate(posicion_slider.x,posicion_slider.y);
                             noFill();
                             stroke(color_marker);
                             strokeWeight(2);
                             beginShape();
                             vertex(0, 0);
                             vertex(posicion_marker-inflate-6,0);
                             curveVertex(posicion_marker-5-inflate,-2);
                             curveVertex(posicion_marker-5-inflate,-3-inflate);
                             //curveVertex(posicion_marker-4-inflate,-6-inflate);
                             curveVertex(posicion_marker-2-inflate,-8-inflate);
                             curveVertex(posicion_marker,-10-inflate);
                             curveVertex(posicion_marker+2+inflate,-8-inflate);
                             //curveVertex(posicion_marker+4+inflate,-6-inflate);
                             curveVertex(posicion_marker+5+inflate,-3-inflate);
                             curveVertex(posicion_marker+5+inflate,-2);
                             vertex(posicion_marker+inflate+6,0);
                             vertex(longitud,0);
                            // ellipse(posicion_marker,altura_marker, radio_marker, radio_marker);
                             endShape();
                             popMatrix();
                             //inflate=0;
                           }
void display3(){
                              detecthover();   
                             pushMatrix();
                             translate(posicion_slider.x,posicion_slider.y);
                             noFill();
                             stroke(color_marker);
                             strokeWeight(2);
                             beginShape();
                             vertex(-10, 0);
                             vertex(posicion_marker-inflate-3,0);
                             vertex(posicion_marker,-10-inflate);
                             vertex(posicion_marker+inflate+3,0);
                             vertex(longitud+10,0);
                            // ellipse(posicion_marker,altura_marker, radio_marker, radio_marker);
                             endShape();
                             popMatrix();
                             //inflate=0;
                           }
                void detect(PVector vr){
                   
                            PVector vectorraton;
                            
                            vectorraton=new PVector (0,0);
                            int distancia;
                            vectorraton.set(vr);
                  //vectorraton=new PVector(mouseX, mouseY);
                  //vectorraton.sub(gui.Posiciongui);
                 vectorraton.sub(posicion_slider);
                 if (vectorraton.x>0  && vectorraton.x<longitud){
                       distancia=int(dist(vectorraton.x,vectorraton.y,posicion_marker,altura_marker));
                        if (distancia<radio_marker){posicion_marker=int(vectorraton.x);}
                           }
                          
                //println(posicion_marker, vectorraton);
                 
                 
                 
                 }

          void detecthover(){
                   
                            PVector vectorraton;
                     vectorraton=new PVector(mouseX, mouseY);
                            int distancia;
                            //vectorraton.set(vr);
                  //vectorraton=new PVector(mouseX, mouseY);
                  //vectorraton.sub(gui.Posiciongui);
                 vectorraton.sub(posicion_slider);
                 if (vectorraton.x>0  && vectorraton.x<longitud){
                       distancia=int(dist(vectorraton.x,vectorraton.y,posicion_marker,altura_marker));
                        if (distancia<radio_marker){if (inflate<5) {inflate++;}} else {if (inflate>0) {inflate--;}}
                           } else {if (inflate>0) {inflate--;}}
                          
                //println(posicion_marker, vectorraton);
                 
                 
                 
                 } 

  // --- Interacción click/drag ---
  boolean isDragging = false;

  boolean detectPress(PVector vr) {
    PVector v = new PVector(0, 0);
    v.set(vr);
    v.sub(posicion_slider);
    if (v.x >= 0 && v.x <= longitud && v.y >= -(radio_marker+5) && v.y <= alto+(radio_marker+5)) {
      posicion_marker = constrain(int(v.x), 0, longitud);
      isDragging = true;
      return true;
    }
    return false;
  }

  void drag(PVector vr) {
    if (!isDragging) return;
    PVector v = new PVector(0, 0);
    v.set(vr);
    v.sub(posicion_slider);
    posicion_marker = constrain(int(v.x), 0, longitud);
  }

  void endDrag() {
    isDragging = false;
  }

}