# cristal2 — Documentación técnica

## Descripción general

cristal2 es un **visualizador generativo de tipo geoda/cristal** desarrollado en **Processing (Java)**. Genera una estructura esférica multicapa de **15.000 puntos** físicamente simulados (muelle + rozamiento), conectados en triángulos de colores semitransparentes, que se deforman en tiempo real respondiendo a señales OSC recibidas desde TheLab OSC.

La estructura central está encapsulada en la clase **`Mandala`**, parametrizable por número de vértices y capas.

---

## Arquitectura del proyecto

```
cristal2/
├── cristal2.pde              — Sketch principal: setup, draw, OSC, ratón
├── mandala.pde               — Clase Mandala: malla, física, atractores, rendering, interfaz OSC
├── mandala_evanescente.pde   — Clase mandala_evanescente: extiende Mandala con ciclo de vida y deriva
├── pompero.pde               — Clase Pompero: generador de mandalas_evanescentes a frecuencia dada
├── atractor.pde              — Clase Atractor: fuente de fuerza atractora/repulsora
└── mat_point.pde             — Clases Mat_point (física) y puntocolor (color + física)
```

---

## Librerías externas

| Librería | Propósito |
|---|---|
| **oscP5** | Recepción de mensajes OSC |
| **netP5** | Gestión de red (bundled con oscP5) |

---

## Clase Mandala

### Constructor

```java
Mandala(int numerovertices, int capas, PVector centro)
```

| Parámetro | Descripción |
|---|---|
| `numerovertices` | Puntos por anillo (cristal2 usa 100) |
| `capas` | Número de anillos (cristal2 usa 150) |
| `centro` | Posición del centro en pantalla |

### Métodos públicos

| Método | Descripción |
|---|---|
| `update()` | Avanza física un frame: órbitas, impulso de beat, muelle/rozamiento |
| `display()` | Dibuja todos los triángulos con color HSB modulado |
| `onIntensidad(float v)` | Recibe `/intensidad` (controla `At.sentido`) |
| `onBpm(float v)` | Recibe `/bpm` (velocidad angular de la órbita) |
| `onBeat(int v)` | Recibe `/beat` (dispara impulso radial) |
| `onBrillos(float v)` | Recibe `/brillos` (expuesto como `brillos` para el fondo del sketch) |
| `onMedios(float v)` | Recibe `/medios` (atractor rival antihorario) |
| `onAgudos(float v)` | Recibe `/agudos` (centelleo en capas exteriores) |
| `moverAtractor(x, y)` | Mueve `At` al punto indicado (uso en mouseDragged) |
| `resetearAtractor()` | Restaura `At.sentido = −1` (uso en mousePressed/Released) |

### Campos públicos relevantes

| Campo | Uso externo |
|---|---|
| `brillos` | El sketch principal lo lee para calcular el alpha del fondo negro |

---

## Clase mandala_evanescente

Extiende `Mandala` con ciclo de vida y movimiento:

| Estado | Condición | `alphaScale` |
|---|---|---|
| BORN | 0 → 0.4 s | 0 → 1 (fade in) |
| ALIVE | 1.5–2.2 s aleatorio | 1.0 |
| DYING | 0 → 0.4 s | 1 → 0 (fade out) |
| DEAD | — | 0 (se elimina de la lista) |

La **deriva** mueve `centro` y todos los `ancla` por `velocidad` (px/frame) antes de llamar a `super.update()`. El muelle sigue tirando desde la ancla en movimiento, por lo que la estructura se arrastra suavemente.

Duración total: 0.4 + 1.5–2.2 + 0.4 = **2.3–3.0 s**.

Para reducir la deformación en mandalas pequeños, el constructor sobreescribe los parámetros de fuerza heredados de `Mandala`: `flujoScale=3.0` (vs 10.0), `orbitRadius=25` (vs 100), `orbitRadius2=40` (vs 150).

Constructor: `mandala_evanescente(int nv, int nc, PVector pos, PVector vel)`

---

## Clase Pompero

Genera `mandala_evanescente` a la frecuencia indicada desde una posición fija.

Constructor: `Pompero(PVector pos, float frecuencia)`  — frecuencia en mandalas/segundo

Cada mandala generado recibe:
- `nv = random(30, 61)`, `nc = random(10, 21)`
- Velocidad: `random(2, 6) + abs(flujo) * 0.3` px/frame — base rápida más bonus proporcional a la energía sonora en el momento del nacimiento; dirección aleatoria 0–2π
- Estado OSC actual del pompero (`flujo`, `bpm`, `brillos`, `medios`, `agudos`)

Pompero propaga todas las señales OSC a sus mandalas vivos en tiempo real.

---

## Uso en el sketch principal

Un único `Pompero` en el centro de pantalla, emitiendo 1 mandala/segundo. Monitor 1:

```java
Pompero pompero;

void setup() {
  fullScreen(P2D, 1);
  // ...
  pompero = new Pompero(new PVector(width/2, height/2), 1.0); // 1 mandala/s
}

void draw() {
  fill(0, 0, 0, map(pompero.brillos, 0, 1, 60, 5));
  rect(0, 0, width, height);
  pompero.update();
  pompero.display();
}
```

El fondo negro con alpha variable produce estelas: alpha alto → estelas cortas; alpha bajo → estelas largas (efecto pintura).

---

## Estructura de la malla

En el constructor de `Mandala` se construye un `ArrayList<puntocolor>` de **100 × 150 = 15.000 puntos** organizados en anillos concéntricos:

- **100 vértices por capa** (`numerovertices=100`), separados `paso = 2π/100` rad
- **150 capas** (`capas=150`), radio creciente: de 40 px, incremento 10 px/capa → radio exterior ≈ 1530 px
- Entre capas, el ángulo se desplaza `paso/2` → disposición en quincunx (efecto cristalino)
- **Masa por capa:** 72 (capa 1) → 221 (capa 150) — las capas exteriores son más inertes

Cada punto tiene `muelle=true` y `resistencia=true`.

---

## Motor físico (`Mat_point`)

Integración de Euler por frame:

```
aceleración += fuerza_atractor / masa
aceleración += fuerza_muelle   (−kmuelle × dist_ancla, normalizada)
velocidad   += aceleración
velocidad    = limit(limite)        // 5 px/frame normal, 40 durante beat
posición    += velocidad
velocidad   *= (1 − 0.04)          // rozamiento proporcional
aceleración  = 0
```

| Parámetro | Valor |
|---|---|
| `kmuelle` | 0.01 |
| `factor_rozamiento` | 0.04 |
| `limite` | 5 px/frame (normal), 40 (beat) |

---

## Sistema de atractores

### `At` — atractor principal (tipo 1)
- Orbita alrededor del `centro` a velocidad proporcional al BPM (1 vuelta = 2 beats), sentido horario
- `sentido = 10 × flujo`
- Radio: 100 px

### `atBeat` — atractor de impulso de beat
- Fijo en el centro; normalmente inactivo (`sentido=0`)
- Durante `beatTimer > 0`: `sentido = +50` (repulsión fuerte, 4 frames)

### `atMedios` — atractor rival de medios (tipo 1)
- Orbita en sentido **antihorario** (1 vuelta = 3 beats), radio 150 px
- `sentido = −constrain(medios, 0, 3) × 6`

---

## Flujo de datos OSC → Visualización

```
TheLab OSC ──► UDP broadcast :6448
                    │
                    ├──► /intensidad ──► At.sentido = 10 × flujo
                    ├──► /bpm        ──► velocidad angular de At y atMedios
                    ├──► /beat       ──► impulso radial 30 px + atBeat sentido=50 (4 frames)
                    ├──► /brillos    ──► alpha fondo: map(brillos, 0,1, 60,5)
                    ├──► /medios     ──► atMedios.sentido = −constrain(medios,0,3)×6
                    └──► /agudos     ──► centelleo en capas ≥24: ruido H ±25°×ag, B +12×ag
```

---

## Sistema de color HSB por capas

`colorMode(HSB, 360, 100, 100, 100)`. Paleta asignada en el constructor de `puntocolor`:

El constructor de `puntocolor` tiene dos variantes:

| Constructor | Uso | Paleta |
|---|---|---|
| `puntocolor(pos, masa, capa)` | Legacy, mallas de 36+ capas | 3 zonas fijas: azul→cyan / verde→amarillo / naranja→rojo |
| `puntocolor(pos, masa, capa, totalCapas)` | Usado por `Mandala` | Espectro 0°–300° proporcional al total de capas del mandala |

`Mandala` usa siempre el constructor proporcional → cada mandala muestra el espectro completo independientemente de cuántas capas tenga.

Alpha: 60–90 aleatorio. `hueShift` rota el tono globalmente cada frame (audio-reactivo).

---

## Variables internas de Mandala

| Variable | Tipo | Descripción |
|---|---|---|
| `flujo` | float | `/intensidad` recibido |
| `bpm` | float | BPM recibido, defecto 120 |
| `orbitAngle` | float | Ángulo orbital de `At` (rad) |
| `orbitAngle2` | float | Ángulo orbital de `atMedios` (rad) |
| `beatTimer` | int | Frames restantes del impulso de beat |
| `beatFired` | boolean | Flag para aplicar impulso en el siguiente `update()` |
| `hueShift` | float | Rotación acumulada del tono (0–360), avanza 0.1°/frame + `abs(flujo)×0.03°` |
| `beatFlash` | float | Fade visual del beat (1.0 → 0, −0.05/frame, ~20 frames) |
| `brillos` | float | `/brillos` recibido; leído también por el sketch para el fondo |
| `medios` | float | `/medios` recibido |
| `agudos` | float | `/agudos` recibido |

---

## Interacción de ratón

| Evento | Acción |
|---|---|
| `mouseDragged` | `mandala.moverAtractor(mouseX, mouseY)` |
| `mousePressed` | `mandala.resetearAtractor()` → `At.sentido = −1` |
| `mouseReleased` | `mandala.resetearAtractor()` → `At.sentido = −1` |

---

## Notas técnicas y bugs conocidos

- **`if (modulo < 0)` en `Atractor.fuerza()`** es inalcanzable (magnitud siempre ≥ 0).
- **Capas 36–149:** la paleta de color en `puntocolor` está definida para 0–35; las capas extra obtienen H fuera del rango `map(24,35,30,0)` → valores negativos que Processing trata como rotación del círculo HSB. El efecto visual es continuidad cromática rojo→purpúreo.
- **Thread-safety OSC:** `oscEvent` corre en hilo separado; solo se escriben primitivos (`float`, `int`, `boolean`) desde ahí. Las iteraciones sobre `vertice` solo ocurren en `draw()` vía `update()` y `display()`.
- **Fondo en sketch, no en `display()`:** el alpha del fondo depende de `mandala.brillos` pero el `rect()` vive en el sketch principal para que sea único aunque haya múltiples instancias de `Mandala`.
