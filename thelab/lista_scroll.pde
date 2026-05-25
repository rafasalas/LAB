class Listascroll{
  int ancho_items, ancho_barra, alto, itemsvisibles;
  
  int index_activo=-1;
  boolean scrolling=false;
  boolean dragging=false;
  //String[] Contenido;
  ArrayList<String> Item;
  PVector Posicion;
  PFont f_list;
  int indice_lista, indicevolador;
  int pos_y;//posicionador cursor

                  Listascroll(PVector posicion){
                                                      Posicion=posicion;
                                                     indicevolador=0;
                                                      ancho_items=250;
                                                      ancho_barra=10;
                                                      alto=300;
                                                      itemsvisibles=5;
                                                      indice_lista=0;
                                                      Item=new  ArrayList<String>();
                                                       //Item.add("_");
                                                       pos_y=0;
                                                      f_list = loadFont("SignikaNegative-Regular-12.vlw");
                                                      textFont(f_list,12);
                    
                 }//fin constructor

                void additem(String contenidoitem){
                                    Item.add(contenidoitem);
                
                }//fin additem
                
                void removeitem(int i){
                                  if(i<Item.size()){Item.remove(i);}
                                  
                }//fin removeitem
                
                
                
                
                
                void display(){int baseitems=itemsvisibles;
                                  float f_ancho_items, f_ancho_barra, f_alto, f_baseitems,f_itemsvisibles, f_indice,itemsocultos;                
                
                                    f_ancho_items= float(ancho_items);
                                    f_ancho_barra= float(ancho_barra);
                                    f_alto= float(alto);
                                    
                                    f_itemsvisibles=float(itemsvisibles);
                
                
                            if (Item.size()>baseitems){baseitems=Item.size();}
                            if (indice_lista>baseitems-itemsvisibles){indice_lista=baseitems-itemsvisibles;}
                             if (indice_lista<0){indice_lista=0;}
                  
                              f_baseitems= float(baseitems);
                              itemsocultos=f_baseitems-f_itemsvisibles;
                              f_indice=float(indice_lista);
                  
                         int alto_items=int(f_alto/f_itemsvisibles);
                         float divisor= (f_baseitems/f_itemsvisibles)+1;
                         int alto_cursor=int((f_itemsvisibles/f_baseitems)*alto);
                           
             
                            pos_y=int((f_indice/itemsocultos)*(alto-alto_cursor));
                            
  
                           if (pos_y>alto-alto_cursor) {pos_y=alto-alto_cursor;}
                          
   
                           
                         pushMatrix();
                         translate(Posicion.x, Posicion.y);

                           textFont(f_list);
                           textSize(16);
                           for (int i=0; i<itemsvisibles; i++){

                               noStroke();
                               fill(255,255,255,10);
                               rect(0, 0, ancho_items, alto);
                               fill(200, 200, 200);
                                    if (i+indice_lista<Item.size()){
                                                    if(i+indice_lista==index_activo){fill(255,255,255);}
                                                    textAlign(LEFT,BOTTOM);
                                                    String cadena=Item.get(i+indice_lista);
                                                    if (cadena.length()>44){cadena=cadena.substring(0,44)+"...";}
                                                    text(cadena, 5, (alto_items*i)+alto_items);
                                                }
                                       }
                                       
                                       
                                  noFill();
                                  stroke(255,255,255,100);
                                rect(ancho_items, 0, ancho_barra, alto);
                                if (Item.size()>itemsvisibles){
                                                                fill(255,255,255,100);
                                                                noStroke();
                                                                rect(ancho_items,pos_y,ancho_barra,alto_cursor);
                                                                }
                              popMatrix();

                                                
                
                
                
                }//fin display


                boolean detectscroll(){
 
                  boolean ratonover=false;
                  PVector vectorraton;
                  vectorraton=new PVector(mouseX, mouseY);
                   vectorraton.sub(gui.Posiciongui);
                 vectorraton.sub(Posicion);
                 if (vectorraton.x>ancho_items && vectorraton.y>0){
                        if (vectorraton.x<(ancho_items+ancho_barra) && vectorraton.y<alto && dragging==false){ratonover=true;scrolling=true;}
                           }
                return ratonover;
                
                
                
                
                
                
                }//fin detectscroll

              boolean detectenlista(){
 
                  boolean ratonover=false;
                  PVector vectorraton;
                  vectorraton=new PVector(mouseX, mouseY);
                   vectorraton.sub(gui.Posiciongui);
                 vectorraton.sub(Posicion);
                 if (vectorraton.x>0 && vectorraton.y>0){
                        if (vectorraton.x<(ancho_items) && vectorraton.y<alto && scrolling==false){ratonover=true;dragging=true;}
                           }
                return ratonover;
                
                
                
                
                
                
                }//fin detectenlista









int cazaitem (){
                float f_alto,f_itemsvisibles;
                 PVector vectorraton;
                 int dondeclica=-1;
                 f_alto= float(alto);
                 f_itemsvisibles=float(itemsvisibles);
                 int alto_items=int(f_alto/f_itemsvisibles);
                  vectorraton=new PVector(mouseX, mouseY);
                   vectorraton.sub(gui.Posiciongui);
                  vectorraton.sub(Posicion);
                  if (vectorraton.x>0 && vectorraton.y>0){
                    if (vectorraton.x<(ancho_items+ancho_barra) && vectorraton.y<alto){
                    dondeclica=indice_lista+(int(vectorraton.y/alto_items));
                    if (dondeclica>Item.size()){dondeclica=-1;}
                  }
                  }                                   
                  return dondeclica;
              }//fin cazaitem



void activa(){
               
                                                      if (cazaitem()<Item.size())
                                                                      {index_activo=cazaitem();}
                                                      
               
                    
              }//fin activa








//fin clase Listascroll
}