# azteca_osc — Documentación técnica

## Descripción general

azteca_osc es un **visualizador de espectro FFT radial** desarrollado en Processing (Java).
Dibuja 29 anillos concéntricos compuestos por arcos coloreados que rotan y cambian de
color en tiempo real según los datos FFT recibidos por OSC desde TheLab.

Migrado desde el proyecto original `Azteca_OSC` escrito en C++/openFrameworks.

---

## Arquitectura del proyecto

```
azteca_osc/
└── azteca_osc.pde   — Sketch único: setup, draw, arco(), oscEvent()
```

---

## Librerías externas

| Librería | Propósito |
|---|---|
| **oscP5** | Recepción de mensajes OSC |
| **netP5** | Gestión de red (bundled con oscP5) |

---

## Estructura de la visualización

En `setup()` se inicializa el array `numeroCachos[512]` con valores aleatorios enteros
en el rango [20, 50]. Solo se usan los índices 10, 20, ..., 290 (29 anillos).

En cada `draw()` se itera sobre esos 29 índices:

| Anillo `i` | Radio real (`i×2`) | Segmentos `numeroCachos[i]` | Dato FFT usado |
|---|---|---|---|
| 10 | 20 px | 20–50 (fijo tras setup) | `value[10]` |
| 20 | 40 px | 20–50 | `value[20]` |
| … | … | … | … |
| 290 | 580 px | 20–50 | `value[290]` |

---

## Método `arco()`

Dibuja un sector anular (arco con grosor) mediante dos pasadas de vértices:

```
Parámetros:
  res        — resolución del círculo completo (1000 pasos)
  ang        — apertura angular del arco en grados
  angInicial — ángulo de inicio en grados
  ancho      — grosor radial del arco (8 px)
  radius     — radio exterior
  cx, cy     — centro de pantalla
  r, g, b, a — color HSBA (modo HSB, 360/100/100/255)

Proceso:
  1. paso = TWO_PI / res  → tamaño angular de cada paso en radianes
  2. p0 = angInicial_rad / paso  → índice de paso inicial
  3. p1 = ang_rad / paso + p0    → índice de paso final
  4. beginShape(): outer ring — vértices a radio radius     (de p0 a p1)
                  inner ring — vértices a radio-ancho       (de p1 a p0, reverso)
  5. endShape(CLOSE)
```

---

## Flujo de datos OSC → Visualización

```
TheLab OSC ──► UDP broadcast :6449
                   │
                   └──► /fft_value (511 floats, índices 0–510)
                              │
                              └──► value[j] = arg[j] × 100
                                        │
                              Para cada anillo i (10–290, paso 10):
                                │
                                ├── angInicial = i×2 + value[i]
                                │   (la energía FFT rota el anillo)
                                │
                                ├── hue  = map(i, 10, 290, 220, 0)
                                │   (azul interior → rojo exterior, fijo por anillo)
                                │
                                ├── sat  = map(value[i], 0, 200, 40, 100)
                                │   (más energía → más saturado)
                                │
                                ├── bri  = map(value[i], 0, 200, 50, 100)
                                │   (más energía → más brillante)
                                │
                                └── alfa = map(value[i], 0, 200, 90, 230)
                                    (más energía → más opaco)
```

---

## Variables globales clave

| Variable | Tipo | Descripción |
|---|---|---|
| `value[512]` | float[] | Valores FFT escalados (arg × 100). Solo se usan índices 10–290. |
| `numeroCachos[512]` | int[] | Número de arcos por anillo, aleatorio [20,50], fijo tras setup. |

---

## Puerto OSC y autodescubrimiento

- **Puerto escuchado:** 6449 (exclusivo para datos FFT raw de TheLab)
- **Mensaje recibido:** `/fft_value` con 511 floats (bandas FFT 0–510)
- **Autodescubrimiento:** cada 300 frames envía `/hello "azteca_osc"` a `255.255.255.255:12000`
  para que TheLab lo registre como peer conocido (modo unicast)
- **Buffer UDP:** configurado a 8192 bytes vía `OscProperties` (el mensaje `/fft_value` pesa
  ~2572 bytes; el buffer por defecto de oscP5, 1008 bytes, causaba `ArrayIndexOutOfBoundsException`)

---

## Cómo integra TheLab el envío de FFT

TheLab emite `/fft_value` mediante `sendToAll_fft(fft_value)` una vez por frame.
La función `sendOsc_fft()` empaqueta los 511 valores del array `fft_value[]`
(calculados por `fft.getBand(i)`) en un único mensaje OSC y lo envía por `oscP5_2`
(source port 12001) al destino `255.255.255.255:6449`.

En modo unicast, usa la lista `knownPeers` igual que el resto de mensajes.

---

## Modo de color

`colorMode(HSB, 360, 100, 100, 255)`. Cada anillo tiene un tono fijo según su posición
radial; la energía FFT modula saturación, brillo y opacidad:

| Parámetro | Sin señal | Señal máxima (~value=200) |
|---|---|---|
| H (tono) | 220° (azul, anillo interior) → 0° (rojo, exterior) | — (fijo por anillo) |
| S (saturación) | 40 | 100 |
| B (brillo) | 50 | 100 |
| A (alfa) | 90 | 230 |

---

## Parámetros de geometría

| Parámetro | Valor | Descripción |
|---|---|---|
| Radio | `i × 2` | Dobla el radio original; anillos de 20–580 px |
| Grosor (`ancho`) | 8 px | Fijo, independiente del radio |
| Solapamiento | `angulo × 2.5` | Los arcos son 2.5× más anchos que el hueco; se solapan densamente |
| Estelas | `fill(0,0,0,95)` / frame | ~37% del frame anterior sobrevive (~6 frames de cola) |

---

## Notas técnicas

- `numeroCachos[i]` se genera una vez en `setup()` y permanece constante.
  Cada ejecución genera una geometría diferente (aleatoriedad de Processing).
- El solapamiento de arcos (`anguloX = angulo * 2.5`) hace que los anillos queden
  casi rellenos; la rotación producida por `value[i]` es visualmente sutil en reposo
  pero crea movimiento fluido con la música.
- `oscEvent()` corre en hilo separado: solo escribe al array `value[]` de primitivos
  float, sin riesgo de concurrencia.
- La resolución del arco (1000 pasos por círculo completo) da ~33 vértices por arco
  de 12° → ~33 × 35 arcos × 29 anillos ≈ 33.000 vértices por frame. Rendimiento OK en P2D.

---

## Bugs corregidos

1. **Buffer UDP demasiado pequeño** — `/fft_value` (511 floats ≈ 2572 bytes) superaba el
   buffer por defecto de oscP5 (1008 bytes) → `ArrayIndexOutOfBoundsException` en `UdpServer.run()`.
   Solución: `OscProperties.setDatagramSize(8192)`.
