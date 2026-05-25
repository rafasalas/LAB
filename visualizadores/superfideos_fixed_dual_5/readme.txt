superfideos_fixed_dual_5
========================
Visualizador de audio reactivo en tiempo real para Processing.
Recibe datos OSC desde TheLab_osc_claude y genera cadenas organicas
de particulas ("fideos") controladas por campos de fuerza.


REQUISITOS
----------
- Processing 4.x
- Libreria oscP5 (Sketch > Import Library > Add Library > oscP5)
- TheLab_osc_claude corriendo en la misma red


CONFIGURACION DE RED
--------------------
- Escucha OSC en puerto UDP 6448
- Se anuncia a TheLab en 255.255.255.255:12000 cada 5 segundos
- Para que TheLab envie datos: lanzar TheLab primero, luego superfideos


PARAMETROS OPTIMOS EN THE LAB
------------------------------
Ajustar los sliders de TheLab a los siguientes valores para obtener
el mejor resultado visual con superfideos:

  GRAVES          0.35
  MEDIOS          0.94
  AGUDOS          0.65
  GANANCIA        166
  UMBRAL DE BEAT  1.7

Con estos valores los fideos respiran con naturalidad, los laterales
se expanden con los medios y agudos, y el beat produce un pulso
de expansion visible sin resultar excesivo.


COMO FUNCIONA
-------------
Seis atractores de fuerza rodean el centro de pantalla:

  - central    : respiracion general (oscila con /intensidad)
  - centralb   : nucleo de bajo — se contrae con graves, explota en beat
  - lateral1/3 : eje vertical — expansion proporcional a los medios
  - lateral2/4 : eje horizontal — expansion proporcional a los agudos

800 cadenas de 6 particulas (4 enjambres x 200) se mueven entre
estos campos de fuerza con ruido browniano superpuesto.


AJUSTE FINO
-----------
Editar superfideos_fixed_dual_5.pde, seccion draw():

  centralb.sentido = -0.5 - flujo_graves + beatDecay * 5;
                                                       ^
                              subir para beat mas fuerte, bajar para mas suave

  lateral1.sentido = factMed * flujo_medios * 0.6;
                                              ^
                              subir para mas expansion vertical

  lateral2.sentido = factAg * flujo_agudos * 0.6;
                                             ^
                              subir para mas expansion horizontal

Para mas densidad de fideos, cambiar en setup():
  int nodos = 200;   <-- aumentar (mas denso, mas CPU)
