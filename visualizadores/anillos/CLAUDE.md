# anillos — Documentación técnica

## Descripción general

**anillos** es un visualizador generativo de partículas desarrollado en Processing (Java). Recibe datos de audio en tiempo real vía OSC desde TheLab y traduce la intensidad en movimiento de 6 enjambres independientes de partículas gobernadas por un sistema de 5 atractores. Migrado de `alfa_21d_exp_lab` (reproductor local con Minim) al ecosistema LAB.

---

## Arquitectura del proyecto

```
anillos/
├── anillos.pde          — Sketch principal: OSC, setup, draw, input
├── particle.pde         — Clase Particle: física individual + renderizado
├── atractor.pde         — Clase Atractor: campo de fuerza configurable
├── system_atractor.pde  — Clase System_atractor: sistema de 5 atractores
├── swarm.pde            — Clase Swarm: enjambre + displayBatch()
└── sketch.properties
```

---

## Librerías externas

| Librería | Propósito |
|---|---|
| **oscP5** | Recepción de mensajes OSC |
| **netP5** | Gestión de red (bundled con oscP5) |

---

## Parámetros de render

- **Renderer:** `fullScreen(P2D, 2)` — pantalla completa en monitor 2
- **Partículas:** 3500 por enjambre × 6 enjambres = **21.000 total**
- **Forma:** cuadrado hueco rotado por heading (geometría equivalente a `particle_class 9`)
- **Fondo:** `background(0)` cada frame — sin estela
- **Anti-aliasing:** `smooth(4)`

---

## Flujo de datos OSC → Partículas

```
TheLab ──► UDP broadcast :6448
               │
               └──► /intensidad (float) ──► volatile flujo
                                                  │
                                     System_atractor.force(p, flujo, browniano)
                                                  │
                                          ┌───────┴───────┐
                                          │               │
                                   central.sentido    lateral1-4.sentido
                                    = -1 - flujo       = -0.5 × flujo
```

---

## Sistema de 5 atractores

Construido con `System_atractor(width/2, height/2, width*2, height*2)`:

| Atractor | Posición | Sentido |
|---|---|---|
| `central` | Centro ± 20 px (vibración aleatoria) | `−1 − flujo` |
| `lateral1` | (cx, cy − height/2) | `−0.5 × flujo` |
| `lateral2` | (cx + width/2, cy) | `−0.5 × flujo` |
| `lateral3` | (cx, cy + height/2) | `−0.5 × flujo` |
| `lateral4` | (cx − width/2, cy) | `−0.5 × flujo` |

La vibración `±20 px` sobre el centro se aplica cada frame (`random(-20,20)`), generando inestabilidad visual continua.

---

## Diferenciación de enjambres por `sostenido`

| Enjambre | Umbral sustain | Comportamiento | Color |
|---|---|---|---|
| `enjambre` | 100 | Respuesta natural, sin compresión | naranja-rojo |
| `enjambre_1` | 12 | Invierte flujo si `\|flujo\| > 12` | azul eléctrico |
| `enjambre_2` | 8 | Invierte flujo si `\|flujo\| > 8` | verde lima |
| `enjambre_3` | 6 | Invierte flujo si `\|flujo\| > 6` | dorado |
| `enjambre_4` | 4 | Invierte flujo si `\|flujo\| > 4` | violeta |
| `enjambre_5` | — | Respuesta cuadrática `(flujo/4)²`, siempre positiva | cian |

La inversión del flujo cuando supera el umbral provoca que los enjambres más sensibles inviertan su fuerza (atracción↔repulsión) en los picos de intensidad, creando capas visuales con comportamientos divergentes.

---

## Paleta de color

Colores fijos por enjambre (sin variación dinámica). Cada tono tiene varianza interna via `monocolor(r, g, b, limitr, limitg, limitb)`:

| Enjambre | Base RGB | Rango superior RGB |
|---|---|---|
| `enjambre` | (220, 60, 20) | (255, 100, 50) |
| `enjambre_1` | (20, 90, 220) | (50, 130, 255) |
| `enjambre_2` | (40, 200, 60) | (80, 240, 100) |
| `enjambre_3` | (220, 180, 0) | (255, 220, 40) |
| `enjambre_4` | (140, 20, 200) | (180, 60, 240) |
| `enjambre_5` | (0, 180, 220) | (30, 220, 255) |

---

## Render batch (`Swarm.displayBatch()`)

En lugar de `pushMatrix/rotate/rect/popMatrix` por partícula, el render usa un único `beginShape(LINES)/endShape()` por enjambre:

```
Paso 1 — Física: p.updatePhysics() para las N partículas
Paso 2 — Render: beginShape(LINES)
  Por partícula: stroke(r,g,b,alfa) + 4 pares de vértices (8 vértices)
endShape()
```

Las 4 esquinas del cuadrado rotado se calculan manualmente:
```java
float ang = velocidad.heading() + PI;
float h   = masa * 1.5;              // semi-lado del cuadrado 3*masa
// Rotación: (x,y) → (x*cos - y*sin, x*sin + y*cos)
A = (px + h*(sinA-cosA),  py - h*(sinA+cosA))
B = (px + h*(cosA+sinA),  py + h*(sinA-cosA))
C = (px + h*(cosA-sinA),  py + h*(sinA+cosA))
D = (px - h*(cosA+sinA),  py + h*(cosA-sinA))
Líneas: A→B, B→C, C→D, D→A
```

Resultado: **6 draw calls/frame** vs. ~126.000 llamadas de estado en la versión sin batch.

---

## Optimizaciones de rendimiento implementadas

| Optimización | Archivos | Descripción |
|---|---|---|
| Batch LINES | `swarm.pde` + `particle.pde` | `updatePhysics()` separado de `display()`; `displayBatch()` con un único `beginShape(LINES)` por enjambre |
| `smooth(4)` | `anillos.pde` | Reducido de 8; imperceptible a 21.000 elementos en movimiento |
| Pre-allocación PVectors | `atractor.pde`, `system_atractor.pde`, `swarm.pde` | `f`, `result`, `browniano` pre-alocados en constructor, reutilizados con `.set()` |
| `acelerate()` sin alloc | `particle.pde` | `aceleracion.x += acelerator.x / masa` en lugar de `PVector.div()` |

---

## Física de partículas

- **Masa:** random(8, 10) — afecta la aceleración (F/m)
- **Gravedad:** (0, 0.02) — deriva leve hacia abajo
- **Velocidad máxima:** 17 px/frame
- **Browniano:** `PVector(0, 0.8)` rotado por `heading × 20` — agitación local perpendicular a la trayectoria
- **Rebote en bordes:** velocidad invertida al tocar los límites `[10, height-10] × [150, width-150]`
- **Partículas eternas:** `eterna = true`, sin decaimiento de lifespan

---

## Thread safety

`volatile float flujo` — el hilo OSC escribe, `draw()` lee. No se necesitan locks ya que float es atómico en JVM de 32 bits sobre x86/x64.

---

## Interacción

| Tecla | Efecto |
|---|---|
| `'s'` | Randomiza `particle_class` (1–9) en los 6 enjambres simultáneamente |

Nota: `particle_class` afecta a `Particle.display()` pero no a `displayBatch()`, que siempre renderiza como cuadrado hueco. La tecla `'s'` solo tiene efecto visible si se cambia el sketch a usar `display()` en lugar de `displayBatch()`.

---

## Mensajes OSC consumidos

| Mensaje | Tipo | Efecto |
|---|---|---|
| `/intensidad` | float | Fuerza de atracción/repulsión del sistema de 5 atractores |

---

## Red

| Rol | IP | Puerto |
|---|---|---|
| Escucha OSC | 0.0.0.0 | 6448 |
| Autodiscovery `/hello` | 255.255.255.255 | 12000 |

**Emite:** `/hello "anillos"` → broadcast:12000 cada 300 frames (~5 segundos a 60 fps).
