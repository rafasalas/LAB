# LAB — Documentación técnica para Claude

## Qué es este proyecto

LAB es un **monorepo** que agrupa un ecosistema completo de arte generativo audiovisual en Processing (Java). Consta de un emisor central (**TheLab**) y ocho visualizadores generativos que reciben datos de audio en tiempo real vía **OSC broadcast UDP**.

El flujo de datos es siempre unidireccional: TheLab analiza audio → emite OSC → cualquier número de visualizadores escuchan y reaccionan visualmente.

---

## Estructura del repositorio

```
LAB/
├── CLAUDE.md                        Este archivo
├── README.md                        Documentación para usuarios
├── instrucciones.txt                Guía de uso del repositorio git
├── .gitignore
├── thelab/                          Captura de audio y emisor OSC
│   ├── TheLab_osc_claude.pde        Sketch principal (setup, draw, OSC, eventos)
│   ├── gui.pde                      Clase Gui: layout completo de la interfaz
│   ├── simple_slider.pde            Clase Slidersimple: slider genérico
│   ├── AudioCapture.java            Helper Java para captura de audio del sistema
│   ├── code/sketch.properties       Configuración del sketch Processing
│   └── data/                        Fuentes .vlw, SVGs, PNGs
└── visualizadores/
    ├── wild_diamond/                Enjambre de 4000 partículas con atractores
    ├── cristal1/                    Geoda cristalina de 5000 puntos (muelle)
    ├── cristal2/                    Cristal con ciclo de vida (mandala evanescente)
    ├── ola_01/                      Murmuración de 4000 partículas elásticas
    ├── superfideos_fixed_dual_5/    4×200 cadenas orgánicas con split de atractor
    ├── azteca_osc/                  29 anillos concéntricos conducidos por FFT completo
    ├── rayos_lab/                   360 rayos ramificantes, portado de openFrameworks
    ├── lastrompetas/                9 trompetas 3D con muelle FFT, portado de openFrameworks
    └── anillos/                     6 enjambres de 1000 partículas, migrado de alfa_21d_exp_lab
```

Cada visualizador tiene su propio `CLAUDE.md` con documentación técnica detallada.

---

## TheLab — Emisor OSC

**Ventana:** 1200×960 px. **Librerías:** `ddf.minim` (solo FFT), `oscP5`, `netP5`.

### Variables globales clave

| Variable | Tipo | Rango | Descripción |
|---|---|---|---|
| `Factor` | float | 10–200 | Ganancia de `/intensidad`. Controlada por `factorSlider`. |
| `BEAT_THRESHOLD` | float | 1.0–2.0 | Umbral del detector de beat. Controlado por `beatSlider`. |
| `gravesGain` | float | 0.0–1.0 | Multiplicador pre-OSC de `/graves`. |
| `mediosGain` | float | 0.0–1.0 | Multiplicador pre-OSC de `/medios`. |
| `agudosGain` | float | 0.0–1.0 | Multiplicador pre-OSC de `/agudos`. |
| `agcRms` | float | — | RMS suavizado del nivel de entrada (lerp 0.015/frame). |
| `agcGain` | float | 0.2–8.0 | Ganancia AGC: `AGC_TARGET / agcRms`. |
| `capturaDispIdx` | int | — | Índice del dispositivo de captura activo. |
| `energyHistory[]` | float[43] | — | Buffer circular de energía en graves (~0.7 s a 60 fps). |
| `beatIntervals[]` | float[8] | — | Últimos 8 intervalos entre beats para calcular BPM. |
| `beatFlash` | float | 0–1 | Fade-out del flash visual de beat (−0.07/frame). |

### Flujo de análisis de audio

```
AudioCapture.copyBuffer() → snap[512]   (AGC: agcGain = AGC_TARGET / agcRms)
  └─► FFT.forward(snap)  →  86 Hz/banda
        ├─ bandas 0–3   (~0–344 Hz)   → /graves  × gravesGain × agcGain
        ├─ bandas 4–23  (~344 Hz–2kHz)→ /medios  × mediosGain × agcGain
        ├─ bandas 24–93 (~2–8kHz)     → /agudos  × agudosGain × agcGain
        ├─ bandas 94+   (8kHz+)       → /brillos × agcGain
        └─ detector beat → /beat (cooldown 10 frames) → /bpm (media 8 intervalos)
  └─► level() × agcGain × Factor × signo → /intensidad
```

**Signo de `/intensidad`:** se recalcula cada frame. `signo = -1` si la suma de muestras del buffer > 0, `signo = +1` si no. Produce oscilación interpretable como pseudo-forma de onda.

### Interfaz gráfica

Dos columnas separadas por línea vertical:
- **Izquierda (480 px):** selector de dispositivo de captura (`<`/`>`), VU meter post-AGC, 4 barras verticales de banda (GRAVES azul · MEDIOS verde · AGUDOS naranja · BRILLOS rojo, ~780 px de alto).
- **Derecha (660 px):** medidores GRAVES/MEDIOS/AGUDOS + BEAT + BPM, sliders de ganancia ×3, slider GANANCIA, slider UMBRAL BEAT, visualizador FFT 80 bandas (450 px), panel RED LOCAL.

Todos los sliders usan `Slidersimple.display3()` (marcador triangular). La interacción se gestiona en `mousePressed/mouseDragged/mouseReleased` del sketch principal pasando un PVector en coordenadas GUI-locales.

### Red

| Rol | IP | Puerto |
|---|---|---|
| Emisión principal | 255.255.255.255 (broadcast) | 6448 |
| Emisión secundaria `/fft_value` (511 floats) | 255.255.255.255 (broadcast) | 6449 |
| Escucha | 0.0.0.0 | 12000, 12001 |

---

## Protocolo OSC — Mensajes emitidos por TheLab

| Mensaje | Tipo | Rango | Frecuencia |
|---|---|---|---|
| `/intensidad` | float | −Factor…+Factor | 60 fps |
| `/graves` | float | 0…~5 | 60 fps |
| `/medios` | float | 0…~3 | 60 fps |
| `/agudos` | float | 0…~2 | 60 fps |
| `/brillos` | float | 0…~1 | 60 fps |
| `/beat` | int | 0 / 1 | 60 fps |
| `/bpm` | float | 40–300 | por beat |

---

## Visualizadores — Resumen técnico

### wild_diamond

**Concepto:** 4000 partículas Burbuja dibujadas como curvas Bézier hacia su atractor más cercano. Coloradas por velocidad (azul→rojo).

**Clases principales:** `Storsimple` (sistema de partículas), `Particula/Burbuja/Astilla/Dardo/Foto`, `Atractor`, `Manipulador/MAtractor/Repulsor`.

**Atractores:**
- `central` (centro) ← `/intensidad`: `sentido = -1 - flujo_curva`
- `lateral1–4` (cardinales, orbitan) ← `/graves`: `sentido = -0.3 - 0.5×graves_curva`
- En `/beat`: repulsión +8.0 en laterales durante 3 frames
- `/bpm` → velocidad orbital de los 4 laterales
- `/agudos` → velocidad de evolución del ruido Perlin

**Física:** masa 3–10, Brownian Perlin (magbrowniano=0.8, escala_ruido=0.003), velocidad máx 25 px/frame, estela alpha=25.

---

### cristal1

**Concepto:** Esfera de 5000 puntos (100 vértices × 50 capas, radio 100–590 px) con física de muelles. 3 atractores compiten.

**Clases principales:** `Atractor`, `Mat_point` (física), `Puntocolor`.

**Atractores:**
- `At` orbita horario (100 px, periodo=2 beats) ← `/intensidad`: `sentido = 10×flujo`
- `atMedios` orbita antihorario (150 px, periodo=3 beats) ← `/medios`: `sentido = -constrain(medios,0,3)×6`
- `atBeat` en centro: impulso +30 px/frame durante 4 frames en cada `/beat` + repulsión sentido=+50

**Respuesta adicional:**
- `/agudos` → ruido de tono ±25° en capas 24–35 + brillo +12
- `/brillos` → alpha del fondo (60–5; más brillos = estela más corta)

**Física muelles:** kmuelle=0.01, friction=0.04. Velocidad normal ≤5 px/frame, en beat ≤40 px/frame.

**Zonas de color (HSB):** capas 0–11 azul→cian, 12–23 verde→amarillo, 24–35 naranja→rojo.

---

### cristal2

**Concepto:** Misma física que cristal1 pero con sistema `Pompero` que genera 1 mandala/segundo. Cada mandala tiene tamaño aleatorio, velocidad de deriva aleatoria y ciclo de vida.

**Clases:** `Mandala` (base), `MandalaEvanescente` (subclase con ciclo de vida), `Pompero` (spawner).

**Ciclo de vida de MandalaEvanescente:**
- BORN: 0–0.4 s (fade in)
- ALIVE: 1.5–2.2 s (aleatorio)
- DYING: 0–0.4 s (fade out)

**Tamaño aleatorio:** `nv = random(30,61)` vértices, `nc = random(10,21)` capas.
**Deriva:** `random(2,6) + abs(flujo)×0.3` px/frame en dirección aleatoria.

Responde a los mismos mensajes OSC que cristal1.

---

### ola_01

**Concepto:** 4000 Astilla (rectángulos) unidas por muelles elásticos a 5 atractores oscilantes. Modela bandadas (murmuración).

**Clases:** `Particula/Astilla`, `Atractor` (oscilación tipo muelle), `Storsimple`.

**Atractores oscilantes (muelle k=0.06, damping=0.88):**
- `central` (centro): freq=0.008, amp=0.5×(35+abs(flujo)×8)
- `lateral1` (arriba): freq=0.011, phase=0
- `lateral2` (izq): freq=0.009, phase=π/3
- `lateral3` (der): freq=0.013, phase=2π/3
- `lateral4` (abajo): freq=0.007, phase=π

**Respuesta OSC:**
- `/intensidad` → fuerza base + amplitud de oscilación
- `/graves` → refuerza contracción central, desplaza tono hacia cálidos
- `/agudos` → agitación browniana, desplaza tono hacia fríos
- `/brillos` → transparencia de líneas (alpha 6–30)
- `/beat` → impulso simultáneo a todos los atractores + salto de tono +120° (×0.92/frame)

**Color HSB:** tono = `agudos_s − graves_s×0.5` (10°–230°). Cada partícula offset `i×0.09°` → espectro completo.

---

### superfideos_fixed_dual_5

**Concepto:** 4 enjambres × 200 cadenas × 6 partículas enlazadas (4800 total). El rasgo distintivo es el **split de atractor dual**: nodos 0–4 van a `centralb`, nodo 5 (cola) va a `central`. Esta diferencia crea el movimiento de torsión orgánica.

**Clases:** `Chain` (6 Astillas enlazadas), `CriatureCloud` (ArrayList de 200 Chains), `Atractor` (tipo 3, fuerza constante), `Particula/Astilla`.

**Atractores:**
```
         lateral1 (/medios, arriba)
              |
lateral4 — central/centralb — lateral2
(/agudos, izq)               (/agudos, der)
              |
         lateral3 (/medios, abajo)
```

**Respuesta OSC:**
- `/intensidad` → `central.sentido = -1 - flujo`
- `/graves` → `centralb.sentido = -0.5 - flujo_graves + beatDecay×5`
- `/medios` → `lateral1/3.sentido = +factMed×flujo_medios×0.6` (expansión vertical)
- `/agudos` → `lateral2/4.sentido = +factAg×flujo_agudos×0.6` (expansión horizontal)
- `/beat` → `beatDecay = 1.0` (decae −1/frame, ~12 frames)

**Emite:** `/hello "superfideos"` → broadcast:12000 cada 5 segundos (autodescubrimiento).

**Física de cadena:** masa decreciente `∝ 1/(i+1)`, longitud máx 500 px, gravedad (0, 0.02), velmax 18 px/frame, Brownian 0.8. Render en pantalla completa P2D.

---

### azteca_osc

**Concepto:** 29 anillos concéntricos (radios i×2 px, i=10..290) compuestos de arcos. Cada anillo responde al bin FFT de su índice: rotación proporcional a la energía, color modulado en saturación y brillo.

**Archivos:** `azteca_osc.pde` (86 líneas). Sin clases auxiliares.

**Fuente de datos:** Puerto 6449, mensaje `/fft_value` (511 floats, el espectro Minim completo enviado por TheLab a 60 fps). No escucha el puerto 6448.

**Configuración OSC crítica:** `datagramSize = 8192` bytes — el paquete `/fft_value` pesa ~2572 bytes, superando el buffer por defecto de 1008.

**Geometría por anillo:**
- Número de arcos: `numeroCachos[i] = random(20, 50)` fijado en setup
- Ángulo de separación: `(360 - sumaEspacios) / numeroCachos[i]`
- Rotación: `angInicial = i×2 + value[i]` (el espectro mueve el anillo)
- Arco renderizado con `beginShape/vertex` como polígono de 1000 lados aproximando el arco

**Color HSB:** tono fijo por anillo (`map(i, 10, 290, 220, 0)` → azul→rojo), saturación y brillo modulados por `value[i]` (40–100 y 50–100 respectivamente), alpha 90–230.

**Estela:** overlay `fill(0, 0, 0, 95)` cada frame → persistencia suave.

**Emite:** `/hello "azteca_osc"` → broadcast:12000 cada 5 segundos (autodescubrimiento).

---

### rayos_lab

**Concepto:** 360 rayos ramificantes (uno por grado) que emanan del centro de la pantalla. Portado del visualizador `rayos3` (openFrameworks/C++) al ecosistema LAB. Cada rayo usa el bin FFT de su ángulo para determinar su longitud, preservando la estética original de relámpago orgánico.

**Archivos:** `rayos_lab.pde` (sketch principal) + `rayo.pde` (constantes + algoritmo). Pantalla completa P2D.

**Fuente de datos:** Puerto 6449 (`/fft_value`, 511 floats) + puerto 6448 (`/beat`, `/bpm`, `/brillos`).

**Configuración OSC crítica:** igual que `azteca_osc` — `datagramSize = 8192` en el listener del puerto 6449.

**Algoritmo `rayo(cx, cy, angulo, segmentos)`:**
- Pre-computa 3 pares cos/sin fuera del bucle: dirección recta + desviación ±45°
- Por cada segmento: dibuja dos líneas (P1→P2 recto, P2→P3 desviado), con desviación aleatoria 33/33/34 (izquierda / recto / derecha)
- Todo el rayo en un único `beginShape(LINES)/endShape()` — 360 draw calls/frame vs. ~90.000 en el original C++

**Constantes geométricas:** `ALTO=2`, `ANCHO=2`, `HIPO=√8≈2.828 px/segmento`, `BETA=atan(1)=45°`, `CACHOS_BASE=50`, `FFT_SCALE=500`.

**Respuesta OSC:**
- `/fft_value[ang]` → `segmentos = 50 + value[ang]` y color `B = value[ang]×20` (mismo mapeo que el original C++)
- `/beat` → `beatDecay = 1.0` (decae −0.08/frame, ~12 frames): alarga todos los rayos +80 segmentos y aumenta alpha
- `/brillos` → alpha del overlay de estela (`map(brillos, 0,1, 12,55)`)
- `/bpm` → suavizado con lerp (reservado para futuras extensiones)

**Color:** R=0, G=141 fijo, B y A conducidos por `value[ang]×20` (base cian→azul). Conserva la paleta del original.

**Emite:** `/hello "rayos_lab"` → broadcast:12000 cada 5 segundos (autodescubrimiento).

---

### lastrompetas

**Concepto:** 9 trompetas 3D dispuestas en círculo (6 exteriores + 3 interiores), cada una formada por anillos concéntricos con física de muelle por anillo. El desplazamiento Z crece del anillo interior al exterior (gradiente). Portado del visualizador `circulosegmentadorotate2` (openFrameworks/C++). Renderer P3D; pantalla completa.

**Archivos:** `lastrompetas.pde` (sketch principal: OSC, setup, draw) + `Trumpet.pde` (clase exportable).

**Fuente de datos:** Puerto 6449 (`/fft_value`, 511 floats) + puerto 6448 (`/intensidad`, `/graves`, `/beat`).

**Configuración OSC crítica:** igual que `azteca_osc` — `datagramSize = 8192` en el listener del puerto 6449.

**Geometría — dos anillos de trompetas:**

| Anillo | Nº | Radio | Inclinación | Tonos HSB |
|---|---|---|---|---|
| Exterior | 6 | 150×SCALE px | 45° hacia afuera | 0°/60°/120°/180°/240°/300° (cada 60°) |
| Interior | 3 | 75×SCALE px | 20° hacia afuera | 30°/150°/270° (desfasadas 30°) |

`SCALE = min(width, height) / 700.0` — geometría independiente de resolución.

**Clase `Trumpet` — API:**
- Constructor: `Trumpet(theta, circleR, tiltAngle, sR, eR, step, ancho, baseHue, scale)`
- `update(float[] value, boolean kick)` — física de muelle; llamar antes de `display()`
- `display(float[] value)` — renderizado QUADS (un `beginShape(QUADS)` por anillo)
- `arcoHQ(res, ang, angInicial, ancho, radius, h, s, b, a)` — arco suavizado de alta calidad (uso offline)

**Física de muelle por anillo:** `force = value[i]×kForce − kSpring×zPos[i] − kDamp×zVel[i]`
- `kSpring=0.06`, `kDamp=0.14`, `kForce=0.05`, `zMax=180.0`, `beatKick=10.0`
- Periodo natural ~26 frames (0.43 s), ratio de amortiguación ~0.29 (underdamped, 2-3 oscilaciones)

**Gradiente Z interior→exterior:** `gradient = constrain((i − sR) / denom, 0, 1)` → anillos internos permanecen planos, externos reciben el desplazamiento completo.

**Transformación de posición/inclinación:** `translate(circleR×cos(θ), circleR×sin(θ), 0)` + `rotate(tiltAngle, −sin(θ), cos(θ), 0)` — mapea el eje Z local a la dirección radial outward.

**Oscilación amortiguada del conjunto (eje Z):** impulso en cada beat → oscilación amortiguada del grupo completo.
- `K_ROT_SPRING=0.008`, `K_ROT_DAMP=0.04`, `BEAT_ROT_KICK=2.0`
- Periodo natural ~70 frames (1.2 s), amplitud pico ~22°, decae en ~1.7 s

**Color HSB:** `colorMode(HSB, 360, 100, 100, 255)`. Tono fijo por trompeta (`baseHue`); saturación, brillo y alpha modulados por `value[i]` (20–100, 20–100, 30–220 respectivamente).

**Rendimiento:** `beginShape(QUADS)` batch: 4 vértices por arco, un único draw call por anillo. 9 trompetas × 9 anillos = 81 draw calls/frame (vs. ~2835 con `beginShape/endShape` por arco individual). Error de aproximación trapezoidal para arcos ≤17°: < 2 px — imperceptible.

**Thread safety:** `volatile boolean beatPulse` — el hilo OSC escribe, `draw()` lee y resetea en el mismo frame.

**Emite:** `/hello "lastrompetas"` → broadcast:12000 cada 300 frames (autodescubrimiento).

---

### anillos

**Concepto:** 6 enjambres independientes de 1000 partículas cada uno (6000 total), gobernados por un sistema de 5 atractores (1 central + 4 cardinales). Migrado de `alfa_21d_exp_lab` (reproductor local) al ecosistema LAB. Renderer P2D; pantalla completa.

**Archivos:** `anillos.pde` (sketch principal: OSC, setup, draw) + `particle.pde` + `atractor.pde` + `system_atractor.pde` + `swarm.pde`.

**Fuente de datos:** Puerto 6448 (`/intensidad`).

**Sistema de atractores:**
- `central`: sentido = `−1 − flujo` (atracción siempre activa, se refuerza con la intensidad)
- `lateral1–4` (N/E/S/O): sentido = `−0.5 × flujo` (atracción proporcional a la intensidad, simétrica)
- Posiciones: laterales en `width/2` y `height/2` desde el centro (bordes de pantalla)
- Vibración: `±20 px` aleatorios cada frame sobre el centro (inestabilidad visual)

**Diferenciación de enjambres por `sostenido`:**

| Enjambre | Umbral sustain | Comportamiento |
|---|---|---|
| `enjambre` | 100 | Respuesta natural, sin compresión |
| `enjambre_1` | 12 | Invierte flujo si `|intensidad| > 12` |
| `enjambre_2` | 8 | Invierte flujo si `|intensidad| > 8` |
| `enjambre_3` | 6 | Invierte flujo si `|intensidad| > 6` |
| `enjambre_4` | 4 | Invierte flujo si `|intensidad| > 4` |
| `enjambre_5` | — | Respuesta cuadrática `(flujo/4)²`, siempre positiva |

**Clases de partícula por enjambre:** `enjambre`=1 (rectángulo largo), `enjambre_1`=4 (punto grueso), `enjambre_2`=2 (cuadrado), `enjambre_3`=8 (halo color), `enjambre_4`=3 (triángulo), `enjambre_5`=7 (halo blanco, acento).

**Color dinámico por `/agudos`:** `enjambre` principal permanece en naranja-fuego fijo. Los enjambres 1–5 interpolan entre paleta cálida (naranja, t=0) y fría (azul-cian, t=1) según `t = map(agudos_s, 0, 1.5, 0, 1)`. Cada partícula lerpa individualmente hacia el target (`colorLerpSpeed=0.08`). `agudos` se suaviza con `lerp(..., 0.1)` antes de calcular `t`.

**Física:** masa 8–10, Browniano `(0, 0.8)` rotado según heading × 20, gravedad (0, 0.02), velocidad máx 17 px/frame, rebote en bordes.

**Fondo:** `background(0)` cada frame — sin estela.

**Thread safety:** `volatile float flujo` — hilo OSC escribe, `draw()` lee.

**Interacción:** tecla `'s'` → randomiza clase de partícula (1–9) en los 6 enjambres simultáneamente.

**Emite:** `/hello "anillos"` → broadcast:12000 cada 300 frames (autodescubrimiento).

---

## Soporte de mensajes OSC por visualizador

| Mensaje | wild_diamond | cristal1 | cristal2 | ola_01 | superfideos | azteca_osc | rayos_lab | lastrompetas | anillos |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `/intensidad` | ✓ | ✓ | ✓ | ✓ | ✓ | — | — | ✓ | ✓ |
| `/graves` | ✓ | — | — | ✓ | ✓ | — | — | ✓ | — |
| `/medios` | — | ✓ | ✓ | — | ✓ | — | — | — | — |
| `/agudos` | ✓ | ✓ | ✓ | ✓ | ✓ | — | — | — | ✓ |
| `/brillos` | — | ✓ | ✓ | ✓ | — | — | ✓ | — | — |
| `/beat` | ✓ | ✓ | ✓ | ✓ | ✓ | — | ✓ | ✓ | — |
| `/bpm` | ✓ | ✓ | ✓ | — | — | — | ✓ | — | — |
| `/fft_value` | — | — | — | — | — | ✓ | ✓ | ✓ | — |

---

## Bugs corregidos (histórico)

1. `signo` no se reseteaba entre frames → `signo=0` al inicio del bucle de análisis (TheLab).
2. `leem3u()` sin comprobación de null → guard `if (selection == null) return` añadido.
3. `println` de debug en producción → eliminados en `Bar_simple.detect_clic()` y `Buttonplay.detectclic()`.
4. Índice de remove incorrecto en drag&drop → `adjRemove = cancionatrapada + (indiceinsercion <= cancionatrapada ? 1 : 0)`.
5. Lógica de `superpuntero` incorrecta en drag&drop → reescrita en dos pasos (efecto del insert, luego del remove ajustado).

---

## Notas de desarrollo

- Todos los sliders usan `Slidersimple.display3()`. La interacción se delega desde `mousePressed/Dragged/Released` del sketch principal pasando coordenadas GUI-locales como PVector.
- Los visualizadores escuchan en el puerto 6448 (UDP). El puerto 6449 es usado por TheLab para emitir `/fft_value` (511 floats, espectro Minim completo a 60 fps) hacia `azteca_osc`, `rayos_lab` y `lastrompetas`. Los listeners del puerto 6449 deben configurar `datagramSize = 8192` bytes — el paquete pesa ~2572 bytes, superando el buffer por defecto de 1008.
- Los visualizadores pueden ejecutarse en el mismo equipo o en cualquier máquina de la red local.
- Processing 4.x requerido. Librerías: Minim (solo TheLab), oscP5 + netP5 (todos).
