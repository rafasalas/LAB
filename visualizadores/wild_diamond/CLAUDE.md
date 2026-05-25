# wild_diamond — Documentación técnica

## Descripción general

wild_diamond es un **visualizador generativo de partículas** desarrollado en **Processing (Java)**. Recibe datos de audio en tiempo real mediante OSC desde TheLab OSC y los traduce en movimiento de un sistema de 4.000 partículas gobernadas por atractores/repulsores.

---

## Arquitectura del proyecto

```
wild_diamond/
├── wild_diamond.pde    — Sketch principal: setup, draw, OSC, lógica de atractores
├── stor_simple.pde     — Clase Storsimple: sistema de partículas con ruido Browniano
├── particula.pde       — Clases Particula (base), Burbuja, Astilla, Dardo, Foto
├── atractor.pde        — Clase Atractor: campo de fuerza con sentido y tipo configurable
├── icono.pde           — Clase Icono: contenedor de manipuladores visuales interactivos
├── manipuladores.pde   — Clases Manipulador, MAtractor, Repulsor: UI interactiva
├── slider.pde          — Clase Slider: control deslizante (no usado actualmente)
└── data/
    ├── texture.png     — Textura para partículas tipo Foto
    ├── atractorr.png   — Icono de atractor en UI
    └── repulsor.png    — Icono de repulsor en UI
```

---

## Librerías externas

| Librería | Propósito |
|---|---|
| **oscP5** | Recepción de mensajes OSC |
| **netP5** | Gestión de red (bundled con oscP5) |

---

## Flujo de datos OSC → Partículas

```
TheLab OSC ──► UDP broadcast :6448
                    │
                    ├──► /intensidad (float) ──► flujo ──► flujo_suavizado (lerp 0.25)
                    │                                            │
                    │                                            └──► flujo_curva = pow(flujo_s, 2)
                    │                                                       │
                    │                                              central.sentido = -1 - flujo_curva
                    │
                    ├──► /graves (float) ──► graves ──► graves_suavizado (lerp 0.25)
                    │                                            │
                    │                                            └──► graves_curva = pow(graves_s, 2)
                    │                                                       │
                    │                                     lateral.sentido = -0.3 - 0.5 * graves_curva
                    │                                     (salvo durante beatTimer > 0)
                    │
                    └──► /beat (int 0/1) ──► beatTimer = 3 frames
                                                   │
                                          lateral.sentido = +8.0 (repulsor temporal)
```

---

## Sistema de atractores

El sketch usa **5 atractores de tipo 1** (fuerza proporcional a la distancia: `f * modulo/50`):

| Atractor | Posición | Controlado por |
|---|---|---|
| `central` | Centro de pantalla (width/2, height/2) | `/intensidad` |
| `lateral1` | Arriba (width/2, height/8) | `/graves` + `/beat` |
| `lateral2` | Izquierda (width/8, height/2) | `/graves` + `/beat` |
| `lateral3` | Derecha (7·width/8, height/2) | `/graves` + `/beat` |
| `lateral4` | Abajo (width/2, 7·height/8) | `/graves` + `/beat` |

**Lógica de sentido:**
- `sentido` negativo = atracción hacia el atractor
- `sentido` positivo = repulsión desde el atractor
- `central.sentido = -1 - flujo_curva` → siempre atrae, más fuerte con más intensidad
- `lateral.sentido = -0.3 - 0.5 * graves_curva` → atracción base + modulación por graves
- Durante `beatTimer > 0`: `lateral.sentido = +8.0` (repulsión fuerte 3 frames ≈ 50ms)

---

## Sistema de partículas (Storsimple)

**Parámetros actuales:**
- Número de partículas: **4.000** (tipo `Burbuja`, clase 2)
- `magbrowniano = 0.8` — amplitud del ruido de Perlin aplicado a cada partícula
- `escala_ruido = 0.003` — escala espacial del campo de ruido
- `t_ruido += 0.004` por frame — velocidad de evolución del campo

**Física por partícula:**
- Masa: random(3, 10) — afecta la aceleración (F/m)
- Gravedad: (0, 0.02) — deriva leve hacia abajo
- Límite de velocidad: 25 unidades
- Partículas eternas (no decaen)
- Rebote en los bordes de pantalla

**Renderizado:**
- Cada partícula se dibuja como curva Bézier hacia su atractor más cercano
- Color por velocidad: azul profundo (vel. baja) → cian → verde → amarillo → rojo (vel. alta)
- Alfa del trazo: 30/255
- Fondo: `fill(0, 0, 0, 25)` por frame (efecto de estela persistente)

---

## Mensajes OSC consumidos

| Mensaje | Tipo | Efecto |
|---|---|---|
| `/intensidad` | float | Fuerza de atracción del atractor central |
| `/graves` | float | Fuerza de atracción de los 4 atractores laterales |
| `/beat` | int (0/1) | Al recibir 1: activa repulsión fuerte 3 frames (~50ms) |
| `/bpm` | float | Velocidad de órbita de los 4 atractores laterales (1 vuelta = 4 beats) |
| `/agudos` | float | Velocidad de evolución del campo Perlin: `tRuidoStep = 0.004 + agudos * 0.007` |

Los mensajes `/medios` y `/brillos` llegan pero aún no están mapeados (se ignoran con aviso en consola).

---

## Parámetros ajustables

| Variable | Valor actual | Descripción |
|---|---|---|
| `exponente` | 2.0 | Curva de respuesta (pow). Aumentar = más contraste entre suave y fuerte |
| `beatTimer` | 3 frames | Duración del impulso de repulsión en el beat |
| `lateral.sentido` base | −0.3 | Atracción mínima de los laterales cuando graves=0 (evita colapso al centro) |
| `lateral.sentido` beat | +8.0 | Fuerza de repulsión en onset |

---

## Notas técnicas

- **Render:** `fullScreen(P2D, 2)` — pantalla completa en monitor 2, aceleración 2D.
- **Suavizado OSC:** todas las variables de entrada usan `lerp(..., 0.25)` para evitar saltos bruscos.
- **Curva de respuesta:** `pow(max(0, valor_suavizado), exponente)` amplifica señales débiles y comprime las fuertes (efecto logarítmico invertido).
- **Atracción base en laterales:** el término `-0.3` independiente de `/graves` garantiza tensión mínima hacia los 4 ejes incluso en silencios, evitando que todas las partículas colapsen al centro.
- **Beat explosivo:** con `beatTimer=3` frames el impulso dura ~50ms a 60fps, lo que produce una sacudida visual breve y contrastada antes de volver a la atracción normal.

---

## Posibles ampliaciones pendientes

| Canal OSC | Posible mapeo |
|---|---|
| `/medios` | `magbrowniano` — agitación textural por contenido armónico |
| `/brillos` | Alpha del fondo — persistencia de estelas |
