# ola_01 — Documentación técnica

## Descripción general

Visualizador de partículas reactivo al audio desarrollado en **Processing (Java)**. Simula una bandada de estorninos (*murmuration*) mediante 4000 partículas controladas por un sistema de atractores elásticos. Recibe datos de análisis espectral vía **OSC (puerto 6448)** desde TheLab_osc o cualquier emisor compatible.

---

## Arquitectura del proyecto

```
ola_01/
├── ola_01.pde        — Setup, draw, receptor OSC, lógica de color y fuerzas
├── particula.pde     — Clase Particula (base) + Astilla (subclase visual)
├── atractor.pde      — Clase Atractor: física de spring + fuerza sobre partículas
├── stor_simple.pde   — Clase Storsimple: enjambre de 4000 Astillas + web de líneas
└── data/
    ├── texture.png
    ├── repulsor.png
    └── atractorr.png
```

---

## Clases

### `Particula` (particula.pde)
Física base de cada partícula:
- `posicion`, `velocidad`, `aceleracion`, `gravedad` (PVector)
- `masa` (float, 3–18): escala la aceleración recibida de los atractores
- `limite` (float, 15): velocidad máxima
- `lifespan` / `eterna`: las partículas del enjambre son eternas
- `acelerar(PVector)`: añade fuerza dividida por masa
- `actualizar()`: integración + rebote en bordes de pantalla

### `Astilla extends Particula` (particula.pde)
Subclase visual: rectángulo alineado con su vector de velocidad. Dibuja en modo HSB usando `p.r/g/b` como hue/sat/bri (el sketch los sobreescribe cada frame).

### `Atractor` (atractor.pde)
Punto de atracción/repulsión con física de resorte:
- `sentido` (float): signo y magnitud de la fuerza. Negativo = atrae, positivo = repele.
- `tipo_atractor = 3`: fuerza constante de módulo 4 (independiente de la distancia).
- `springUpdate(t, freq, phase, amp)`: oscilación sinusoidal alrededor de `home` con retorno elástico (spring k=0.06, damping=0.88).
- `impulso(mag)`: patada aleatoria en dirección random (usado en beats).
- `fuerza(posicionObjeto)`: devuelve el vector fuerza que ejerce sobre una partícula.

**Los 5 atractores y sus parámetros de oscilación:**

| Atractor   | Posición home          | Frecuencia | Fase     | Amplitud base |
|------------|------------------------|------------|----------|---------------|
| `central`  | centro elástico web    | 0.008      | 0.0      | 0.5 × amp     |
| `lateral1` | (width/2, height/8)    | 0.011      | 0.0      | amp           |
| `lateral2` | (width/8, height/2)    | 0.009      | π/3      | amp           |
| `lateral3` | (7w/8, height/2)       | 0.013      | 2π/3     | amp           |
| `lateral4` | (width/2, 7h/8)        | 0.007      | π        | amp           |

`amp = 35 + abs(flujo_s) * 8` → la amplitud de oscilación crece con la energía de audio.

### `Storsimple` (stor_simple.pde)
Enjambre de N partículas + centro elástico de la web de líneas:
- **4000 Astillas** eternas, masa 3–10, iniciadas en posición y velocidad random.
- `centroWeb`: punto elástico que vuelve al centro de pantalla con spring k=0.07, damping=0.85. El atractor central sigue este punto.
- `aceleradorparticulas(Atractor)`: aplica la fuerza de cada atractor a todas las partículas + ruido browniano proporcional a `agitacion`.
- `dibujaparticulas()`: actualiza física, sobreescribe color HSB, dibuja rectángulo + línea a `centroWeb`.
- `impulsoWeb(mag)`: patada aleatoria al centro de la web (activado en beats).

---

## Mensajes OSC recibidos (puerto 6448)

| Dirección     | Tipo  | Variable destino | Suavizado (lerp) | Efecto principal                                      |
|---------------|-------|------------------|------------------|-------------------------------------------------------|
| `/intensidad` | float | `flujo`          | 0.25 (rápido)    | Fuerza de los atractores, amplitud de oscilación      |
| `/graves`     | float | `graves`         | 0.12 (medio)     | Refuerza fuerza central, mueve hue hacia cálido       |
| `/agudos`     | float | `agudos`         | 0.12 (medio)     | Agitación browniana, mueve hue hacia frío             |
| `/brillos`    | float | `brillos`        | sin suavizar     | Transparencia de las líneas de la web (6–30)          |
| `/beat`       | int   | —                | —                | Impulso a todos los atractores + web, pico beatForce  |

### Detalle de la respuesta al beat
```
beatForce = 15         → decae −1/frame (~250 ms de efecto)
beatHue  += 120°       → salto cromático de 1/3 del círculo, decae ×0.92/frame
central.impulso(30)
lateral*.impulso(55)   × 4 atractores
estorninos.impulsoWeb(70)
```

## Mensajes OSC emitidos

| Dirección | Destino                  | Frecuencia          | Contenido              |
|-----------|--------------------------|---------------------|------------------------|
| `/hello`  | 255.255.255.255 : 12000  | Frame 1 + c/300 fr. | String "ola_01" (peer discovery) |

---

## Mapeo de color HSB (colorMode 360/100/100/100)

| Parámetro      | Fuente OSC                             | Rango          | Efecto visual                    |
|----------------|----------------------------------------|----------------|----------------------------------|
| `hueBase`      | `agudos_s − graves_s × 0.5`           | 10°–230°       | 10°=rojo (calor), 230°=azul (frío) |
| `hueOffset`    | beat (acumulativo, decae ×0.92/frame)  | +120° por beat | Rotación cromática en beats      |
| `sat`          | `abs(flujo_s)` 0–8                    | 55–92          | Más energía = más saturado       |
| `bri`          | `beatForce` 0–15                       | 78–98          | Flash de brillo en beats         |
| `lineAlpha`    | `brillos` 0–1                          | 6–30           | Densidad visual de la web        |

El tono de cada partícula individual es: `(hueBase + hueOffset + i × 0.09) % 360`
→ Las 4000 partículas cubren el espectro cromático completo (4000 × 0.09 ≈ 360°).

---

## Variables globales clave

| Variable     | Tipo    | Descripción                                                      |
|--------------|---------|------------------------------------------------------------------|
| `flujo_s`    | float   | `/intensidad` suavizado. Controla amplitud de oscilación.        |
| `graves_s`   | float   | `/graves` suavizado. Refuerza fuerza central, sesga hue a cálido.|
| `agudos_s`   | float   | `/agudos` suavizado. Agitación browniana, sesga hue a frío.      |
| `beatForce`  | float   | Pico de fuerza/brillo post-beat. Inicia en 15, −1/frame.        |
| `beatHue`    | float   | Desplazamiento cromático acumulado por beats. Decae ×0.92/frame. |
| `hueBase`    | float   | Tono base del enjambre (10–230°). Lerp lento 0.04.              |

---

## Parámetros físicos fijos (hardcoded)

| Parámetro                  | Valor    | Localización          |
|----------------------------|----------|-----------------------|
| Número de partículas       | 4000     | `setup()` ola_01.pde  |
| Tipo de atractor           | 3        | `Atractor(3)` ×5      |
| Fuerza constante tipo 3    | 4.0      | `atractor.pde:55`     |
| Gravedad partículas        | (0, 0.02)| `particula.pde:17`    |
| Velocidad máx. partícula   | 15       | `particula.pde:18`    |
| Spring k atractores        | 0.06     | `atractor.pde:37`     |
| Damping atractores         | 0.88     | `atractor.pde:38`     |
| Spring k centroWeb         | 0.07     | `stor_simple.pde:52`  |
| Damping centroWeb          | 0.85     | `stor_simple.pde:54`  |
| Separación cromática/part. | 0.09°    | `stor_simple.pde:81`  |
