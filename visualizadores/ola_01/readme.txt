ola_01 — Visualizador de partículas reactivo al audio
======================================================

DESCRIPCIÓN
-----------
Visualizador generativo en Processing que simula una bandada de estorninos
(murmuration) con 4000 partículas. Las partículas son atraídas por 5 puntos
de atracción que oscilan sinusoidalmente, formando una red de líneas luminosas
que pulsa y fluye en respuesta al audio.

Recibe datos de análisis espectral en tiempo real via OSC (protocolo UDP)
desde TheLab_osc o cualquier emisor compatible con el mismo esquema de mensajes.


REQUISITOS
----------
- Processing 4.x con las siguientes librerías instaladas:
    oscP5    (comunicación OSC)
    netP5    (red UDP)
- Pantalla secundaria recomendada (fullscreen en monitor 2)
- TheLab_osc_claude u otro emisor OSC en la misma red local


CÓMO EJECUTAR
-------------
1. Abre ola_01.pde en Processing.
2. Asegúrate de que TheLab_osc_claude está en ejecución y emitiendo.
3. Pulsa el botón Run en Processing.
   El sketch ocupa la pantalla completa del monitor 2 (fullScreen P2D, 2).
4. El visualizador arranca en modo "sin señal" (partículas en movimiento
   mínimo). En cuanto recibe datos OSC el movimiento se activa.


PARÁMETROS OSC RECIBIDOS  (puerto UDP 6448)
--------------------------------------------
  /intensidad  float   Energía general del audio.
                       Controla la fuerza de atracción y la amplitud de
                       oscilación de los 5 atractores.

  /graves      float   Energía en bajas frecuencias (~0–344 Hz).
                       Refuerza el atractor central y desplaza el color
                       hacia tonos cálidos (rojos/naranjas).

  /agudos      float   Energía en altas frecuencias (~2–8 kHz).
                       Aumenta la agitación browniana de las partículas y
                       desplaza el color hacia tonos fríos (azules).

  /brillos     float   Energía por encima de 8 kHz.
                       Controla la transparencia de las líneas de la red
                       (más brillo = líneas más visibles).

  /beat        int     Detector de golpe rítmico (valor 1 en cada beat).
                       Genera un impulso de fuerza en todos los atractores,
                       un flash de brillo y un salto cromático de 120°.


COMPORTAMIENTO VISUAL
---------------------
COLOR
  El tono del enjambre oscila entre rojo (graves dominantes) y azul
  (agudos dominantes). Las 4000 partículas cubren el espectro cromático
  completo: cada partícula tiene un tono ligeramente distinto a la anterior,
  creando un efecto de arcoíris en movimiento.

  En cada beat el color salta 120° en el círculo cromático (rojo → verde →
  azul → rojo) y vuelve gradualmente al tono base.

MOVIMIENTO
  Cinco atractores oscilan con trayectorias sinusoidales independientes.
  Un atractor central sigue el "centro elástico" de la red, que rebota
  suavemente al centro de la pantalla. Los otros cuatro oscilan en los
  bordes (arriba, abajo, izquierda, derecha).

  Con más /intensidad los atractores se mueven con mayor amplitud.
  Con más /agudos las partículas adquieren mayor agitación browniana
  (movimiento caótico superpuesto).

BEATS
  Cada beat recibido lanza un impulso radial aleatorio a todos los atractores
  y al centro de la red, produciendo una explosión de movimiento que se
  amortigua en ~250 ms.


MENSAJES OSC EMITIDOS
---------------------
  /hello  →  255.255.255.255 : 12000
  Enviado en el frame 1 y cada 300 frames (~5 s a 60 fps).
  Permite que TheLab_osc detecte automáticamente este visualizador
  como receptor activo en la red.


ARCHIVOS DEL PROYECTO
---------------------
  ola_01.pde        Sketch principal, setup/draw, receptor OSC, lógica de color
  particula.pde     Clase Particula (física) + Astilla (visual)
  atractor.pde      Clase Atractor: oscilación sinusoidal + fuerza sobre partículas
  stor_simple.pde   Clase Storsimple: enjambre de 4000 partículas + red de líneas
  data/             Imágenes de textura (no usadas en la versión base)


PARÁMETROS FÍSICOS PRINCIPALES
--------------------------------
  Número de partículas       4000
  Velocidad máxima           15 px/frame
  Tipo de fuerza             Constante (magnitud 4, independiente de distancia)
  Amplitud de oscilación     35 px base + crece con la energía del audio
  Gravedad                   0.02 px/frame² hacia abajo


COMPATIBILIDAD
--------------
  Probado con TheLab_osc_claude como emisor.
  Compatible con cualquier emisor OSC que envíe al puerto 6448 los mensajes
  /intensidad, /graves, /agudos, /brillos y /beat con los tipos float/int
  indicados arriba.
