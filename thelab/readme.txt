================================================================================
  TheLab OSC  —  Referencia de salidas OSC
  Reproductor de audio con analisis espectral en tiempo real
  Ventana: 1200 x 700 px  |  Processing (Java)
================================================================================


DESCRIPCION
-----------
TheLab OSC es un reproductor de archivos MP3 que analiza el audio en tiempo
real y transmite los datos por el protocolo OSC (Open Sound Control) via UDP
broadcast. Disenado para controlar sistemas externos: iluminacion, visualiza-
dores, sintetizadores, instalaciones interactivas, etc.

El valor de /graves, /medios y /agudos se puede escalar antes del envio
mediante los sliders de ganancia por banda de la GUI (rango 0.0 a 1.0).
Esto permite normalizar senales saturadas sin tocar el codigo receptor.

El umbral del detector de beat (BEAT_THRESHOLD) es ajustable en tiempo real
con el slider "UMBRAL DE BEAT" (rango 1.0-2.0, defecto 1.5).


CONFIGURACION DE RED
--------------------

  Envio principal    ->  255.255.255.255 : 6448  (broadcast UDP)
  Envio secundario   ->  255.255.255.255 : 6449  (broadcast UDP)
  Escucha entrada 1  <-  0.0.0.0         : 12000
  Escucha entrada 2  <-  0.0.0.0         : 12001


================================================================================
  MENSAJES OSC EMITIDOS
================================================================================

Los mensajes se emiten 60 veces por segundo (60 fps) salvo indicacion contraria.


  /intensidad
  -----------
  Tipo       : float
  Rango      : -Factor ... +Factor  (aprox. -200 a +200 segun ganancia)
  Destinos   : 255.255.255.255:6448  Y  255.255.255.255:6449
  Frecuencia : cada frame (60 fps)

  Descripcion:
    Nivel RMS del mix de audio escalado por el factor de ganancia (slider
    GANANCIA, rango 10-200, defecto 50) y multiplicado por el signo de la
    senal. Unico mensaje que se envia a ambos puertos.

  Ejemplo de uso:
    Controlar la intensidad de luz o el volumen de un sintetizador externo.


  /graves
  -------
  Tipo       : float
  Rango      : 0.0 ... (~5.0 x gravesGain)
  Destinos   : 255.255.255.255:6448
  Frecuencia : cada frame (60 fps)
  Bandas FFT : 0-3  (~0 Hz a 344 Hz)
  Slider GUI : GRAVES (columna derecha, debajo de la barra de graves)

  Descripcion:
    Media de las bandas FFT de sub-graves y graves, multiplicada por el
    slider de ganancia de graves (0.0-1.0). Responde a: bombo, bajo, kick.
    Bajar el slider evita que senales saturadas colapsen el receptor.

  Ejemplo de uso:
    Modular la fuerza de los atractores laterales en un sistema de particulas.


  /medios
  -------
  Tipo       : float
  Rango      : 0.0 ... (~3.0 x mediosGain)
  Destinos   : 255.255.255.255:6448
  Frecuencia : cada frame (60 fps)
  Bandas FFT : 4-23  (~344 Hz a 2066 Hz)
  Slider GUI : MEDIOS (columna derecha)

  Descripcion:
    Media de las bandas FFT de medios, multiplicada por mediosGain.
    Responde a: voz, piano, guitarra, cuerdas, organo.

  Ejemplo de uso:
    Controlar parametros armonicos de un sintetizador o modular un servo.


  /agudos
  -------
  Tipo       : float
  Rango      : 0.0 ... (~2.0 x agudosGain)
  Destinos   : 255.255.255.255:6448
  Frecuencia : cada frame (60 fps)
  Bandas FFT : 24-93  (~2066 Hz a 8021 Hz)
  Slider GUI : AGUDOS (columna derecha)

  Descripcion:
    Media de las bandas FFT de agudos, multiplicada por agudosGain.
    Responde a: platillos, sibilantes, armonicos de ataque.

  Ejemplo de uso:
    Velocidad de particulas en un visualizador o intensidad de color.


  /brillos
  --------
  Tipo       : float
  Rango      : 0.0 ... ~1.0
  Destinos   : 255.255.255.255:6448
  Frecuencia : cada frame (60 fps)
  Bandas FFT : 94-256  (~8094 Hz en adelante)

  Descripcion:
    Media de las bandas FFT de presencia y aire (8 kHz+). Sin slider de
    ganancia propio. Responde a: brillo, aire, armonicos altos, reverb.

  Ejemplo de uso:
    Persistencia de estelas, textura en sistemas generativos.


  /beat
  -----
  Tipo       : int
  Valores    : 0  (sin beat)  o  1  (beat detectado)
  Destinos   : 255.255.255.255:6448
  Frecuencia : cada frame (60 fps)

  Descripcion:
    Detector de onset ritmico por energia. Dispara 1 cuando la energia de
    /graves supera BEAT_THRESHOLD veces la media de ~0.7s. Cooldown de
    10 frames (~167 ms) para evitar dobles detecciones.

  Parametros del detector:
    Umbral        : BEAT_THRESHOLD (slider GUI, rango 1.0-2.0, defecto 1.5)
    Cooldown      : 10 frames = ~167 ms
    Ventana media : 43 frames = ~717 ms

  Ejemplo de uso:
    Explosion de particulas, strobe, cambio de escena en onset ritmico.


  /bpm
  ----
  Tipo       : float
  Rango      : 40.0 ... 300.0
  Destinos   : 255.255.255.255:6448
  Frecuencia : solo cuando se detecta un beat nuevo
  Condicion  : solo se emite si currentBpm > 0

  Descripcion:
    Tempo en BPM, calculado como media de hasta 8 intervalos entre beats.
    Solo intervalos entre 200 ms y 1500 ms son validos (40-300 BPM).

  Ejemplo de uso:
    Sincronizar secuenciadores, calcular subdivision de compas.


================================================================================
  RESUMEN RAPIDO
================================================================================

  Mensaje       Tipo    Puerto    Slider GUI          Descripcion breve
  -----------   ------  --------  ------------------  -------------------------
  /intensidad   float   6448+6449 GANANCIA (x10-200)  RMS con signo * Factor
  /graves       float   6448      GRAVES   (x0-1)     Energia 0-344 Hz
  /medios       float   6448      MEDIOS   (x0-1)     Energia 344 Hz-2 kHz
  /agudos       float   6448      AGUDOS   (x0-1)     Energia 2-8 kHz
  /brillos      float   6448      —                   Energia 8 kHz+
  /beat         int     6448      UMBRAL BEAT (1-2)   1 en onset, 0 el resto
  /bpm          float   6448      —                   Tempo en BPM


================================================================================
  CONTROLES DE LA GUI
================================================================================

  Columna izquierda:
    [Play/Pause]   Boton SVG centrado. Click para reproducir o pausar.
    [Barra]        Click en la barra de progreso para saltar a esa posicion.
    [Lista]        Click para seleccionar cancion. Drag para reordenar.
                   Scroll con arrastrar fuera del area de items.

  Columna derecha:
    [Barras GRAVES/MEDIOS/AGUDOS]
                   Medidores de nivel en tiempo real (solo visualizacion).
    [Sliders de ganancia x3]
                   Debajo de cada barra. Escalan el valor OSC enviado.
                   Izquierda = 0.0 (silencia el canal). Derecha = 1.0 (pleno).
    [BEAT]         Cuadrado blanco cuando hay onset. Etiqueta "BEAT".
    [BPM]          Numero a la derecha de las barras cuando hay valor valido.
    [CARGAR MP3]   Abre dialogo para anadir un archivo MP3 a la lista.
    [PLAYLIST]     Abre dialogo para cargar un archivo .m3u.
    [LIMPIAR]      Vacia la lista y detiene la reproduccion.
    [GUARDAR]      Guarda la lista actual como .m3u.
    [GANANCIA]     Slider horizontal. Escala /intensidad (rango 10-200).
    [UMBRAL BEAT]  Slider horizontal. Sensibilidad del detector (rango 1.0-2.0).
                   Valor bajo = mas beats. Valor alto = solo golpes fuertes.
    [Espectro]     Solo visualizacion. 80 bandas, coloreado azul->rojo.
    [Collapse]     Boton esquina superior derecha. Pliega/despliega la GUI.


================================================================================
  NOTAS TECNICAS
================================================================================

  FFT:
    Buffer size  : 512 muestras
    Sample rate  : 44100 Hz
    Resolucion   : ~86.13 Hz por banda
    Spec size    : 257 bandas utiles (0 - Nyquist 22050 Hz)

  Mapeo de bandas a frecuencias:
    Banda 0      :     0 Hz  (DC)
    Banda 3      :   258 Hz
    Banda 4      :   344 Hz
    Banda 23     :  1981 Hz
    Banda 24     :  2067 Hz
    Banda 93     :  8011 Hz
    Banda 94     :  8097 Hz
    Banda 256    : 22050 Hz  (Nyquist)

  Factor de ganancia (/intensidad):
    Rango: 10 a 200. Defecto: 50.
    Factor = map(slider_pos, 0, longitud_slider, 10, 200)

  Ganancias por banda (/graves, /medios, /agudos):
    Rango: 0.0 a 1.0. Defecto: 1.0 (sin atenuacion).
    Gain = map(slider_pos, 0, longitud_slider, 0.0, 1.0)
    Valor enviado = banda_raw * gain

  Beat detection:
    Algoritmo : energia instantanea vs media movil (energy-based onset)
    Umbral     : energia_actual > media_historica * BEAT_THRESHOLD
    Cooldown   : 10 frames (~167 ms)
    Ventana    : 43 frames (~717 ms)
    BEAT_THRESHOLD: ajustable en GUI (1.0-2.0, defecto 1.5)

  BPM:
    Calculado como: 60000 / media_de_intervalos_entre_beats
    Buffer        : hasta 8 intervalos recientes
    Rango valido  : 200 ms - 1500 ms por intervalo (40-300 BPM)


================================================================================
  LIBRERIAS REQUERIDAS (Processing)
================================================================================

  - Minim          (ddf.minim.*)    reproduccion MP3 y analisis FFT
  - oscP5          (oscP5.*)        protocolo OSC
  - netP5          (netP5.*)        gestion de red UDP


================================================================================
