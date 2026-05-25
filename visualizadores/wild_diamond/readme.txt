================================================================================
  wild_diamond  —  Visualizador generativo de particulas
  Receptor OSC desde TheLab OSC
  Processing (Java)  |  fullScreen P2D monitor 2  |  60 fps
================================================================================


DESCRIPCION
-----------
wild_diamond es un sistema de 4.000 particulas controlado por datos de audio
en tiempo real recibidos via OSC desde TheLab OSC. Las particulas orbitan
alrededor de 5 atractores/repulsores cuya fuerza responde al espectro y al
ritmo de la musica.


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
  Efecto : Controla la fuerza del atractor CENTRAL (centro de pantalla).
           Cuanto mayor es /intensidad, mas fuerte succiona las particulas
           hacia el centro. Formula: central.sentido = -1 - pow(flujo, 2)
           Suavizado con lerp(0.25) para evitar saltos.


  /graves
  -------
  Tipo   : float
  Efecto : Controla la fuerza de los 4 atractores LATERALES (arriba, abajo,
           izquierda, derecha). Cuanto mayor es /graves, mas se expande el
           patron de diamante hacia los 4 ejes.
           Formula: lateral.sentido = -0.3 - 0.5 * pow(graves, 2)
           El termino -0.3 base evita que las particulas colapsen al centro
           cuando no hay graves (silencios o musica sin bajo).
           Suavizado con lerp(0.25).

  Nota: si el valor de /graves es muy alto (musica con graves saturados),
  usar el slider de ganancia GRAVES en TheLab para atenuarlo antes del envio.


  /beat
  -----
  Tipo   : int  (0 = sin beat, 1 = beat detectado)
  Efecto : Cuando llega un 1, los 4 atractores laterales se convierten en
           repulsores fuertes durante 3 frames (~50 ms a 60 fps).
           Las particulas salen disparadas hacia los bordes y vuelven a
           colapsar inmediatamente. Efecto de "explosion" en cada onset.
           Formula: lateral.sentido = +8.0 durante beatTimer frames.


  /medios, /agudos, /brillos, /bpm
  ---------------------------------
  Estos mensajes llegan pero actualmente no estan mapeados a ningun parametro.
  Se registran en consola como "OSC no reconocido". Candidatos para futuras
  ampliaciones (ver CLAUDE.md).


================================================================================
  PARAMETROS INTERNOS
================================================================================

  Sistema de particulas:
    Numero          : 4.000 particulas (tipo Burbuja)
    Masa            : 3.0 - 10.0 (aleatoria, afecta la aceleracion)
    Gravedad        : (0, 0.02) por frame
    Limite velocidad: 25 unidades
    Ruido Browniano : magnitud 0.8, escala 0.003, paso t 0.004/frame

  Atractores:
    Tipo de fuerza  : lineal a la distancia  (fuerza = dist/50)
    Posicion fija   : calculada una vez en setup() en funcion de width/height

  Renderizado:
    Renderer        : P2D  (acelerado por GPU)
    Pantalla        : fullScreen en monitor 2
    Suavizado       : smooth(8)  (8x antialiasing)
    Estelas         : fill(0,0,0,25) por frame  -> cola de ~10 frames visibles
    Curvas Bezier   : de cada particula a su atractor mas cercano, alfa 30
    Color           : mapeado por velocidad (azul bajo -> rojo alto)

  Respuesta OSC:
    Curva           : exponente = 2.0  (pow cuadratico)
    Suavizado       : lerp(0.25)  ~4 frames de rampa


================================================================================
  PUESTA EN MARCHA
================================================================================

  1. Abrir wild_diamond en Processing y ejecutar (requiere monitor secundario).
  2. Abrir TheLab OSC en Processing y ejecutar.
  3. Cargar o arrastrar archivos MP3 a la lista de TheLab.
  4. Pulsar Play en TheLab. El visualizador reacciona inmediatamente.

  Si el visualizador no reacciona:
    - Comprobar que ambos programas estan en la misma red local.
    - Verificar que el puerto 6448 UDP no esta bloqueado por el firewall.
    - El broadcast 255.255.255.255 llega a cualquier equipo en la red local.

  Si las particulas se amacotan en el centro:
    - La senal de /graves puede estar muy alta. Bajar el slider GRAVES en
      TheLab (columna derecha, debajo de la barra de graves).
    - Tambien se puede subir el UMBRAL DE BEAT en TheLab para reducir la
      frecuencia de explosiones y estabilizar el sistema.


================================================================================
  LIBRERIAS REQUERIDAS (Processing)
================================================================================

  - oscP5   (oscP5.*)   protocolo OSC
  - netP5   (netP5.*)   gestion de red UDP


================================================================================
