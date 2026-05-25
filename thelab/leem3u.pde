void leem3u(File selection){
String[] listalarga, listacorta;

int contador1, contador2;
contador1=contador2=0;

if (selection == null) {
  println("Window was closed or the user hit cancel.");
  return;
}
if (match (selection.getAbsolutePath(),".m3u")!=null)
                                                       {     

                                                        lines = loadStrings(selection.getAbsolutePath());
                                            
                                                        listalarga=new String[(lines.length)];
                                                       
                                                        for (int i=0;i<lines.length; i++)
                                                                  {if (match (lines[i],"#")==null && lines[i].length()>0){
                                                                      
                                                                    
                                                                    listalarga[contador1]=lines[i];
                                                                  contador1++;
                                                                    }
                                                         }
                                                          listacorta=new String[contador1];
                                                          for (int i=0;i<contador1; i++){listacorta[i]=listalarga[i];}
                                                          
                                                           for (int i=0;i<listacorta.length; i++){ 
                                                                         listacanciones.add( listacorta[i]);    
                                                                         String[] cortes=splitTokens(listacorta[i],"\\");
                                                                         listatitulos.add(cortes[cortes.length-1]);
                                                                         gui.lista.additem(cortes[cortes.length-1]);}
                                                                         
                                                                         
                                                       }
}




void savem3u(File selection){
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
                    String[] canciones_para_guardar;
                    canciones_para_guardar=new String[listacanciones.size()];
                    for (int i=0;i<canciones_para_guardar.length; i++)
                                                                  {canciones_para_guardar[i]=listacanciones.get(i);
                                                                  }
                    try {
                        saveStrings(selection.getAbsolutePath(), canciones_para_guardar);
                      } 
                      catch(Exception e) {
                        println("No se grabo");
                      }

  }


}