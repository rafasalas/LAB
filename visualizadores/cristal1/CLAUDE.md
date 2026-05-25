# cristal1 — Documentación técnica

## Descripción general

cristal1 es un **visualizador generativo de tipo geoda/cristal** desarrollado en **Processing (Java)**. Genera una estructura esférica multicapa de 2.880 puntos físicamente simulados (muelle + rozamiento), conectados en triángulos de colores semitransparentes, que se deforman en tiempo real respondiendo a señales OSC recibidas desde TheLab OSC.

---

## Arquitectura del proyecto

```
cristal1/
├── cristal1.pde   — Sketch principal: setup, draw, OSC, interacción de ratón
├── atractor.pde   — Clase Atractor: fuente de fuerza atractora/repulsora
└── mat_point.pde  — Clases Mat_point (física) y puntocolor (color + física)
```

---

## Librerías externas

| Librería | Propósito |
|---|---|
| **oscP5** | Recepción de mensajes OSC |
| **netP5** | Gestión de red (bundled con oscP5) |

---

## Estructura de la malla

En `setup()` se construye un `ArrayList<puntocolor>` de **100 × 50 = 5.000 puntos** organizados en anillos concéntricos:

- **100 vértices por capa** (`numerovertices=100`), separados `paso = 2π/100` rad
- **50 capas** (`capas=50`), radio creciente: de 100 px hasta 590 px (incremento 10 px/capa)
- Entre capas, el ángulo se desplaza `paso/2` → disposición en quincunx (efecto cristalino, sin radios rectos)
- **Masa por capa:** 72 (capa 1) → 121 (capa 50) — las capas exteriores son más inertes


Cada punto tiene `muelle=true` y `resistencia=true`: vuelve a su posición de ancla con amortiguación.

---

## Motor físico (`Mat_point`)

Integración de Euler por frame:

```
aceleración += fuerza_atractor / masa
aceleración += fuerza_muelle   (−kmuelle × dist_ancla, normalizada)
velocidad   += aceleración
velocidad    = limit(limite)        // defecto: 5 px/frame, 40 durante beat
posición    += velocidad
velocidad   += fricción (−0.0015 × vel_normalizada)
aceleración  = 0
```

| Parámetro | Valor | Efecto |
|---|---|---|
| `kmuelle` | 0.01 | Rigidez del retorno al ancla |
| `factor_rozamiento` | 0.04 | Amortiguación proporcional: `v *= (1 − 0.04)` por frame. Con masa 72–107 el sistema queda sobreamortiguado (converge sin oscilar en ~1 s). |
| `limite` | 5 px/frame (normal), 40 (beat) | Cap de velocidad |

---

## Sistema de atractores

### `At` — atractor principal (tipo 1)
- Fuerza proporcional a la distancia: `f = (dist/50) × sentido`
- Posición: **orbita alrededor del centro** a velocidad proporcional al BPM recibido
- `sentido = 10 × flujo` (donde `flujo` = valor de `/intensidad`)
- Radio: `orbitRadius = 100 px` | Período: 2 beats | Sentido: horario

### `atBeat` — atractor de impulso de beat
- Mismo tipo 1, posición fija en el centro de pantalla
- Normalmente inactivo (`sentido = 0`)
- Durante `beatTimer > 0`: `sentido = +50` (repulsión fuerte)

### `atMedios` — atractor rival de medios (tipo 1)
- Misma física tipo 1, orbita en **sentido antihorario** alrededor del centro
- Radio: `orbitRadius2 = 150 px` | Período: 3 beats | Rival de `At`
- `sentido = −constrain(medios, 0, 3) × 6` (siempre atractivo, escala con energía de medios)
- Sin señal `/medios`: `sentido = 0`, inactivo. Con señal alta: compite con `At` tirando en dirección opuesta

---

## Flujo de datos OSC → Visualización

```
TheLab OSC ──► UDP broadcast :6448
                    │
                    ├──► /intensidad (float) ──► flujo ──► At.sentido = 10 × flujo
                    │                                       (deformación continua)
                    │
                    ├──► /bpm (float 40–300)  ──► bpm ──► velocidad de órbita de At
                    │                                      (1 vuelta = 2 beats)
                    │
                    ├──► /medios (float) ──► medios ──► atMedios.sentido = −constrain(medios,0,3)×6
                    │                                    (atractor antihorario radio 150 px, período 3 beats)
                    │
                    ├──► /agudos (float) ──► agudos ──► capas 24–35: hNoise=±25°×ag, B+12×ag por triángulo
                    │                                    (centelleo cromático independiente en la corona exterior)
                    │
                    ├──► /beat (int 0/1) ──► beatFired=true, beatTimer=4
                    │                              │
                    │                     impulso radial directo (30 px/frame)
                    │                     + atBeat.sentido=+50 durante 4 frames
                    │                     + limite=40 → restaura a 5 al acabar
                    │                     + beatFlash=1.0 → boost visual S/B/A
                    │                     + hueShift rota continuamente (audio-reactivo)
                    │
                    └──► /brillos (float) ──► brillos ──► alpha fondo = map(brillos, 0,1, 90,15)
                                                           (estelas largas con brillo alto)
```

---

## Mensajes OSC consumidos

| Mensaje | Tipo | Efecto |
|---|---|---|
| `/intensidad` | float | Fuerza del atractor orbital (`At.sentido`) |
| `/bpm` | float (40–300) | Velocidad angular de la órbita de `At` |
| `/beat` | int (0/1) | Explosión radial: velocidad directa + repulsión 4 frames |
| `/brillos` | float (0–1) | Persistencia de estelas: alpha del fondo negro (60→5) |
| `/medios` | float (0–~3) | Atractor rival antihorario: `sentido = −constrain(medios,0,3) × 6` |
| `/agudos` | float (0–~2) | Centelleo cromático en capas 24–35: ruido de tono `±25° × agudos` por triángulo + boost de brillo `+12 × agudos` |

El mensaje `/graves` llega pero aún no está mapeado.

---

## Dibujo: triangulación entre capas

Para cada par de capas adyacentes (N y N−1) se dibujan triángulos conectando:
- `vertice[i]` (capa N)
- `vertice[i+1]` (capa N, siguiente en el anillo)
- `vertice[i − (numerovertices−1)]` (capa N−1, punto correspondiente)

Al final de cada anillo se cierra con el primer punto de la capa anterior. La primera capa (i < 80) no se dibuja (código comentado). El color de cada triángulo viene del `puntocolor` del primer vértice, en modo HSB, con modulación en tiempo real:

```
fill(
  (Vtemp1.r + hueShift) % 360,          // H rotado continuamente
  min(100, Vtemp1.g + beatFlash * 20),   // S boost en beat
  min(100, Vtemp1.b + beatFlash * 30),   // B boost en beat
  min(100, Vtemp1.a + beatFlash * 15)    // A boost en beat
)
```

---

## Sistema de color HSB por capas

El sketch usa `colorMode(HSB, 360, 100, 100, 100)`. Los campos `r, g, b, a` de `puntocolor` almacenan valores HSB (no RGB):

| Zona | Capas | Tono H | Descripción | Saturación | Brillo |
|---|---|---|---|---|---|
| Interior | 0–11 | 220 → 180 | Azul → Cyan | 75 | 65–88 (aleatorio) |
| Media | 12–23 | 120 → 50 | Verde → Amarillo | 80 | 70–92 (aleatorio) |
| Exterior | 24–35 | 30 → 0 | Naranja → Rojo | 85 | 75–95 (aleatorio) |

Alpha: aleatorio entre 60 y 90 para todas las capas.

El tono se asigna una vez en `setup()` y no cambia en tiempo real. El brillo aleatorio por punto da variación visual dentro de cada zona. Las capas interiores (bajos) son frías, las exteriores (agudos) son cálidas.

---

## Variables globales clave

| Variable | Tipo | Descripción |
|---|---|---|
| `flujo` | float | Valor de `/intensidad` recibido por OSC |
| `bpm` | float | BPM recibido, defecto 120 |
| `orbitAngle` | float | Ángulo actual de la órbita de `At` (rad) |
| `orbitRadius` | float | Radio de órbita de `At`, 100 px |
| `beatTimer` | int | Frames restantes del impulso de beat (0 = inactivo) |
| `beatFired` | boolean | Flag para aplicar el impulso en el siguiente draw() |
| `hueShift` | float | Rotación acumulada del tono HSB (0–360). Avanza 0.1°/frame + `abs(flujo) × 0.03°` (audio-reactivo). Se suma al canal H en cada `fill()`. |
| `beatFlash` | float | Fade-out visual del flash de beat (1.0 → 0.0 a −0.05 por frame, ~20 frames). Boost a S (+20), B (+30), A (+15) durante el beat. |
| `brillos` | float | Valor de `/brillos` recibido por OSC. Controla el alpha del fondo negro en cada frame: `map(brillos, 0, 1, 60, 5)`. Sin señal: alpha=60 → estelas de 3–4 frames siempre visibles. Con brillos=1: alpha=5 → 95% del frame anterior sobrevive → estelas largas tipo pintura. |
| `medios` | float | Valor de `/medios` recibido por OSC. Escala `atMedios.sentido`. |
| `agudos` | float | Valor de `/agudos` recibido por OSC. Controla intensidad del centelleo en capas 24–35. |
| `orbitAngle2` | float | Ángulo de órbita de `atMedios` (rad). Decrementa cada frame (antihorario). |
| `orbitRadius2` | float | Radio de órbita de `atMedios`: 150 px. |
| `numerovertices` | int | Puntos por capa: 100 |
| `capas` | int | Número de anillos: 50 |

---

## Interacción de ratón

| Evento | Acción |
|---|---|
| `mouseDragged` | Mueve `At` a la posición del ratón (anula la órbita ese frame) |
| `mousePressed` | Resetea `At.sentido = −1` |
| `mouseReleased` | Resetea `At.sentido = −1` |

---

## Señales OSC pendientes de mapear

| Canal | Posible uso |
|---|---|
| `/graves` | Pendiente — efecto breathing descartado, por definir |

---

## Bugs conocidos / notas técnicas

- `random(10,10)` en `draw()` siempre devuelve 10.0 (mín=máx). Sin aleatoriedad real.
- `if (modulo < 0)` en `Atractor.fuerza()` es inalcanzable (magnitud siempre ≥ 0).
- **Fricción proporcional** (`v *= 1 − 0.04`): sistema sobreamortiguado para masa 72–107, converge en ~1 s sin oscilación residual. El modelo anterior (sustracción constante de 0.0015 px/frame) tardaba ~55 s en detener un punto a velocidad máxima.
- **Estelas**: alpha del fondo `map(brillos, 0, 1, 60, 5)`. El rango anterior (90→15) dejaba las estelas prácticamente invisibles con `brillos` bajo.
- `oscEvent` corre en hilo separado: solo se escriben primitivos (`boolean`, `float`, `int`) desde ahí. Las iteraciones sobre `vertice` se realizan exclusivamente en `draw()`.
- La variable global `Factor=50` queda oculta por la local `Factor` declarada en `draw()`.
- `println` de debug activo en la rama `else` de `oscEvent`: se imprime en consola cada mensaje OSC no reconocido (incl. `/graves`, `/medios`, `/agudos` a 60 fps → spam en consola).
