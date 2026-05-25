class CriatureCloud{
        ArrayList <Chain> creatures;
  
      CriatureCloud(int number){
                      creatures=new ArrayList<Chain>();
                      for(int i=0; i<number; i++){
                                                  creatures.add(new Chain());
                                                  }
                                             }

    void acelerador(Atractor a){
                                for (int i = 0; i < creatures.size(); i++) {
                                              Chain l = creatures.get(i);
                                               l.aceleradorparticulas(a);
                                               
                                               }
                                }
   void acelerador_cola(Atractor a){
                                for (int i = 0; i < creatures.size(); i++) {
                                              Chain l = creatures.get(i);
                                               l.aceleradorparticulas_cola(a);

                                               }
                                }
    void acelerador_dual(Atractor a, Atractor b){
                                for (int i = 0; i < creatures.size(); i++) {
                                              Chain l = creatures.get(i);
                                               l.aceleradorparticulas_dual(a,b);
                                               
                                               }
                                }                            
    void actualizar(){for (int i = 0; i < creatures.size(); i++) {
                                              Chain l = creatures.get(i);
                                               l.actualizar();                                        }                                               
    }
    void mostrar(){for (int i = 0; i < creatures.size(); i++) {
                                              Chain l = creatures.get(i);
                                               l.mostrar();

                                               }}


}//fin class creature cloud