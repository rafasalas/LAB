# CLAUDE.md — superfideos_fixed_dual_5

## Descripcion del proyecto

Visualizador de audio en tiempo real construido en **Processing (Java)**. Genera cadenas organicas de particulas ("fideos") controladas por campos de fuerza que responden a datos de audio enviados via **OSC** desde **TheLab_osc_claude**.

---

## Estructura de archivos

```
superfideos_fixed_dual_5/
├── superfideos_fixed_dual_5.pde   — Setup, draw, recepcion OSC, logica de atractores
├── chain.pde                      — Cadena de 6 particulas enlazadas (criatura individual)
├── criature_cloud.pde             — Contenedor de 200 chains (enjambre)
├── atractor.pde                   — Campo de fuerza con 4 leyes de caida
├── particula.pde                  — Clase base fisica + subclases (Astilla, Burbuja, Dardo, Foto)
├── stor_simple.pde                — Sistemas de particulas sueltas (no usados en main)
├── carioca.pde                    — Implementacion alternativa experimental (no usada)
└── data/                          — Assets graficos y audio de placeholder
```

---

## Arquitectura de clases

```
CriatureCloud  (enjambre — ArrayList de Chains)
  └── Chain    (criatura — 6 particulas enlazadas en serie)
        └── Particula (fisica base: posicion, velocidad, aceleracion, gravedad)
              └── Astilla  (tipo activo: rectangulo rotado segun velocidad)

Atractor       (campo de fuerza: posicion + sentido + tipo de caida)
```

---

## Comunicacion OSC con TheLab

Escucha en **UDP 6448** (mismo puerto que emite TheLab).
Anuncia su presencia enviando `/hello "superfideos"` a `255.255.255.255:12000` cada 5 segundos
para aparecer en la lista de peers de TheLab.

| Mensaje OSC   | Tipo  | Efecto en el visualizador                          |
|---------------|-------|----------------------------------------------------|
| `/intensidad` | float | Fuerza de `central` — respiracion general          |
| `/graves`     | float | Fuerza de `centralb` — contraccion del nucleo      |
| `/medios`     | float | Fuerza de `lateral1` y `lateral3` — eje vertical   |
| `/agudos`     | float | Fuerza de `lateral2` y `lateral4` — eje horizontal |
| `/brillos`    | float | Recibido, reservado para uso futuro                |
| `/beat`       | int   | Dispara `beatDecay=1.0` → pulso de expansion       |
| `/bpm`        | float | Recibido, reservado para uso futuro                |

---

## Logica de atractores (draw)

Seis atractores posicionados alrededor del centro de pantalla:

```
         lateral1 (arriba, medios)
              |
lateral4 — central/centralb — lateral2
(izq, agudos)     |          (dcha, agudos)
         lateral3 (abajo, medios)
```

```java
central.sentido  = -1 - flujo;                            // oscila con la musica
centralb.sentido = -0.5 - flujo_graves + beatDecay * 5;   // nucleo: atrae en graves, explota en beat
lateral1/3.sentido = +factMed * flujo_medios * 0.6;       // repulsion vertical (expansion)
lateral2/4.sentido = +factAg  * flujo_agudos * 0.6;       // repulsion horizontal (expansion)
```

- **Sentido negativo** = atraccion hacia la posicion del atractor (contraccion)
- **Sentido positivo** = repulsion desde la posicion del atractor (expansion)
- `beatDecay` decae de 1.0 a 0 en ~12 frames tras cada beat

---

## Sistema fisico

### Particula
- Integracion: velocidad ← aceleracion, posicion ← velocidad
- Gravedad: `(0, 0.02)` (deriva suave hacia abajo)
- Limite de velocidad: 18 px/frame
- Rebote en bordes de pantalla
- Masa aleatoria (5–50), decrece a lo largo de la chain: `masa ∝ 1/(i+1)`

### Chain — el secreto (dual attractor split)
```java
// aceleradorparticulas_dual():
if (i < 5) l.acelerar(a.fuerza(l.posicion));   // eslabones 0-4 → centralb
else        l.acelerar(b.fuerza(l.posicion));   // eslabon 5    → central
```
La separacion del ultimo eslabon hacia un atractor distinto es el origen del efecto visual caracteristico.

### Ruido browniano
Magnitud 0.8, rotado en cada frame segun el `heading()` de la velocidad → movimiento organico.

### Constraint de cadena
Cada eslabon permanece a maximo 500px del anterior.

---

## Render

- **Modo:** `fullScreen(P2D, 2)` — pantalla 2 (monitor externo)
- **Antialiasing:** `smooth(8)`
- **FPS:** 60
- **Trail:** rectangulo negro semi-transparente cada frame (alpha reactivo a intensidad)
- **Color:** blanco `stroke(255, 255, 255, 35)` — todas las chains igual

```java
fill(0, 0, 0, map(abs(flujo), 0, 4, 10, 40));
rect(0, 0, width, height);
```

| Alpha fondo | Condicion        | Efecto                       |
|-------------|------------------|------------------------------|
| 10          | silencio         | estela larga (~6 s)          |
| 25          | nivel medio      | estela media (~1.7 s)        |
| 40          | pico de audio    | estela corta (~0.7 s)        |

---

## Rendimiento

| Metrica                     | Valor     |
|-----------------------------|-----------|
| Enjambres (CriatureCloud)   | 4         |
| Chains por enjambre         | 200       |
| Eslabones por chain         | 6         |
| Total particulas            | 4.800     |
| Actualizaciones/seg a 60fps | ~288.000  |

### Optimizaciones aplicadas
- `Atractor._f`: PVector pre-allocado en `fuerza()` — elimina ~19.000 allocations/frame
- `Particula.acelerar()`: aritmetica inline en lugar de `PVector.div()` — sin allocations
- `Chain.browniano`: pre-allocado, usa `.set()` — elimina ~19.000 allocations/frame
- `Chain._radius`: pre-allocado en `actualizar()` — elimina ~8.000 allocations/frame
- `mostrar()`: `stroke()` fuera del loop de vertices, sin `colorMode()` switching

---

## Dependencias

```
oscP5  — protocolo OSC
netP5  — red (requerida por oscP5)
P2D    — renderer 2D acelerado por GPU (Processing built-in)
```

Instalar: **Sketch > Import Library > Add Library** → buscar `oscP5`.

---

## Ajuste de parametros

Para cambiar la forma de los fideos, editar en `draw()` de `superfideos_fixed_dual_5.pde`:

| Parametro          | Efecto al aumentar                        |
|--------------------|-------------------------------------------|
| `beatDecay * 5`    | Explosion mas fuerte en cada beat         |
| `flujo_graves * 1` | Mas contraccion del nucleo con los bajos  |
| `factMed * 0.6`    | Mayor expansion vertical con los medios   |
| `factAg * 0.6`     | Mayor expansion horizontal con los agudos |
| `magbrowniano`     | Mas caos organico en el movimiento        |
| `nodos` (setup)    | Numero de chains por enjambre (densidad)  |
