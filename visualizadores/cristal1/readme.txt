================================================================================
  cristal1  —  Visualizador generativo de cristal/geoda
  Receptor OSC desde TheLab OSC
  Processing (Java)  |  fullScreen P2D monitor 2  |  60 fps
================================================================================


DESCRIPCION
-----------
cristal1 es una estructura esferica multicapa de 2.880 puntos fisicamente
simulados (muelle + rozamiento), conectados en triangulos semitransparentes,
que se deforma en tiempo real respondiendo a datos de audio recibidos via OSC
desde TheLab OSC.

La malla esta formada por 36 anillos concentricos de 80 puntos cada uno,
distribuidos en quincunx (desplazamiento medio paso entre capas) para dar
el aspecto cristalino. Las capas interiores son frias (azul/cyan), las medias
verdes/amarillo y las exteriores calidas (naranja/rojo).

Un atractor orbital recorre el cristal sincronizado al BPM de la musica,
deformandolo asimetricamente. En cada onset ritmico el cristal explota
radialmente y el muelle lo devuelve a su forma original.


CONFIGURACION DE RED
--------------------

  Escucha  <-  0.0.0.0 : 6448  (UDP, acepta broadcast)

  Fuente esperada: TheLab OSC emitiendo a 255.255.255.255:6448


================================================================================
  MENSAJES OSC CONSUMIDOS
================================================================================


  /intensidad
  -----------
  Tipo   : float
  Efecto : Controla la fuerza del atractor orbital sobre la malla.
           Cuanto mayor es /intensidad, mas arrastra los puntos hacia
           la posicion orbital del atractor.
           Formula: At.sentido = 10 * flujo


  /bpm
  ----
  Tipo   : float  (40 - 300)
  Efecto : Controla la velocidad angular del atractor orbital.
           El atractor describe un circulo de radio 100 px alrededor del
           centro a razon de 1 vuelta cada 2 beats.
           Formula: orbitAngle += (bpm/60) * TWO_PI / frameRate / 2
           Valor por defecto si no llega OSC: 120 BPM.

  Nota: a mayor BPM el atractor orbita mas rapido, distorsionando el
  cristal con mayor frecuencia. Con musica lenta (60-80 BPM) el efecto
  es una deformacion suave y continua.


  /beat
  -----
  Tipo   : int  (0 = sin beat, 1 = beat detectado)
  Efecto : Cuando llega un 1, todos los puntos reciben un impulso radial
           directo de 30 px/frame hacia afuera, con el limite de velocidad
           elevado a 40 px/frame durante 4 frames (~67 ms a 60 fps).
           La masa creciente por capa produce una onda expansiva visible:
           las capas interiores (masa 72) salen mas rapido que las
           exteriores (masa 107). El muelle devuelve todo al reposo.
           Se ignoran beats consecutivos mientras el impulso esta activo.


  /graves, /medios, /agudos, /brillos
  ------------------------------------
  Estos mensajes llegan pero actualmente no estan mapeados a ningun
  parametro. Se registran en consola como mensajes no reconocidos.
  Candidatos para futuras ampliaciones (ver CLAUDE.md).


================================================================================
  SISTEMA DE COLOR
================================================================================

  El cristal usa colorMode HSB. Los colores se asignan una vez en setup()
  segun la capa de cada punto y no cambian en tiempo real:

    Capas  0-11  (interior)  :  Azul -> Cyan      (H 220->180, S 75)
    Capas 12-23  (media)     :  Verde -> Amarillo  (H 120->50,  S 80)
    Capas 24-35  (exterior)  :  Naranja -> Rojo    (H  30->0,   S 85)

  El brillo de cada punto es aleatorio dentro de su zona, dando
  variacion interna. Alpha: 60-90 (semitransparente, capas visibles
  a traves unas de otras).


================================================================================
  PARAMETROS INTERNOS
================================================================================

  Malla:
    Puntos totales   : 2.880  (80 vertices x 36 capas)
    Radio interior   : 100 px
    Radio exterior   : 450 px  (incremento 10 px/capa)
    Disposicion      : quincunx (medio paso de angulo entre capas)

  Fisica por punto:
    Masa             : 72 (capa 1) -> 107 (capa 36)
    Muelle kmuelle   : 0.01
    Rozamiento       : 0.0015
    Limite velocidad : 5 px/frame (normal)  /  40 px/frame (beat)

  Atractor orbital:
    Tipo de fuerza   : lineal a la distancia  (fuerza = dist/50)
    Radio de orbita  : 100 px
    Velocidad        : 1 vuelta cada 2 beats  (proporcional a /bpm)

  Beat:
    Impulso inicial  : 30 px/frame radial hacia afuera
    Duracion         : 4 frames  (~67 ms)
    Cooldown         : no acepta nuevo beat hasta que terminen los 4 frames

  Renderizado:
    Renderer         : P2D  (acelerado por GPU)
    Pantalla         : fullScreen en monitor 2
    Fondo            : negro puro cada frame  (sin estelas)
    Primitiva        : triangulos sin trazo, fill semitransparente HSB


================================================================================
  PUESTA EN MARCHA
================================================================================

  1. Abrir cristal1 en Processing y ejecutar (requiere monitor secundario).
  2. Abrir TheLab OSC en Processing y ejecutar.
  3. Cargar o arrastrar archivos MP3 a la lista de TheLab.
  4. Pulsar Play en TheLab. El visualizador reacciona inmediatamente.

  Si el visualizador no reacciona:
    - Comprobar que ambos programas estan en la misma red local.
    - Verificar que el puerto 6448 UDP no esta bloqueado por el firewall.
    - El broadcast 255.255.255.255 llega a cualquier equipo en la red local.

  Si el cristal se deforma demasiado y no vuelve a su forma:
    - La senal de /intensidad puede estar muy alta. Bajar el slider
      GANANCIA en TheLab OSC (columna derecha).
    - Subir el UMBRAL DE BEAT para reducir la frecuencia de explosiones.

  Interaccion de raton durante la ejecucion:
    - Arrastrar : mueve el atractor a la posicion del raton (la orbita
                  automatica se reanuda al soltar).
    - Click     : resetea la fuerza del atractor a -1.


================================================================================
  LIBRERIAS REQUERIDAS (Processing)
================================================================================

  - oscP5   (oscP5.*)   protocolo OSC
  - netP5   (netP5.*)   gestion de red UDP


================================================================================
