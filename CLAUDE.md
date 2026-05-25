# LAB — Documentación técnica para Claude

## Qué es este proyecto

LAB es un **monorepo** que agrupa un ecosistema completo de arte generativo audiovisual en Processing (Java). Consta de un emisor central (**TheLab**) y cinco visualizadores generativos que reciben datos de audio en tiempo real vía **OSC broadcast UDP**.

El flujo de datos es siempre unidireccional: TheLab analiza audio → emite OSC → cualquier número de visualizadores escuchan y reaccionan visualmente.

---

## Estructura del repositorio

```
LAB/
├── CLAUDE.md                        Este archivo
├── README.md                        Documentación para usuarios
├── instrucciones.txt                Guía de uso del repositorio git
├── .gitignore
├── thelab/                          Reproductor y emisor OSC
│   ├── TheLab_osc_claude.pde        Sketch principal (setup, draw, OSC, eventos)
│   ├── gui.pde                      Clase Gui: layout completo de la interfaz
│   ├── simple_bar.pde               Clase Bar_simple: barra de progreso
│   ├── simple_slider.pde            Clase Slidersimple: slider genérico
│   ├── button_play.pde              Clase Buttonplay: botón play/pause SVG
│   ├── button_simple.pde            Clase Buttonsimple: botón genérico SVG
│   ├── lista_scroll.pde             Clase Listascroll: lista con scroll y drag&drop
│   ├── leem3u.pde                   leem3u() y savem3u(): gestión de playlists .m3u
│   ├── AudioCapture.java            Helper Java para captura de audio
│   ├── code/sketch.properties       Configuración del sketch Processing
│   └── data/                        Fuentes .vlw, SVGs, PNGs, MP3 de ejemplo
└── visualizadores/
    ├── wild_diamond/                Enjambre de 4000 partículas con atractores
    ├── cristal1/                    Geoda cristalina de 5000 puntos (muelle)
    ├── cristal2/                    Cristal con ciclo de vida (mandala evanescente)
    ├── ola_01/                      Murmuración de 4000 partículas elásticas
    └── superfideos_fixed_dual_5/    4×200 cadenas orgánicas con split de atractor
```

Cada visualizador tiene su propio `CLAUDE.md` con documentación técnica detallada.

---

## TheLab — Emisor OSC

**Ventana:** 1200×700 px. **Librerías:** `ddf.minim`, `oscP5`, `netP5`.

### Variables globales clave

| Variable | Tipo | Rango | Descripción |
|---|---|---|---|
| `Factor` | float | 10–200 | Ganancia de `/intensidad`. Controlada por `factorSlider`. |
| `BEAT_THRESHOLD` | float | 1.0–2.0 | Umbral del detector de beat. Controlado por `beatSlider`. |
| `gravesGain` | float | 0.0–1.0 | Multiplicador pre-OSC de `/graves`. |
| `mediosGain` | float | 0.0–1.0 | Multiplicador pre-OSC de `/medios`. |
| `agudosGain` | float | 0.0–1.0 | Multiplicador pre-OSC de `/agudos`. |
| `energyHistory[]` | float[43] | — | Buffer circular de energía en graves (~0.7 s a 60 fps). |
| `beatIntervals[]` | float[8] | — | Últimos 8 intervalos entre beats para calcular BPM. |
| `beatFlash` | float | 0–1 | Fade-out del flash visual de beat (−0.07/frame). |

### Flujo de análisis de audio

```
AudioPlayer (Minim, bufferSize=512, 44100 Hz)
  └─► FFT.forward()  →  86 Hz/banda
        ├─ bandas 0–3   (~0–344 Hz)   → /graves  × gravesGain
        ├─ bandas 4–23  (~344 Hz–2kHz)→ /medios  × mediosGain
        ├─ bandas 24–93 (~2–8kHz)     → /agudos  × agudosGain
        ├─ bandas 94+   (8kHz+)       → /brillos
        └─ detector beat → /beat (cooldown 10 frames) → /bpm (media 8 intervalos)
  └─► mix.level() × Factor × signo   → /intensidad
```

**Signo de `/intensidad`:** se recalcula cada frame. `signo = -1` si la suma de muestras del buffer > 0, `signo = +1` si no. Produce oscilación interpretable como pseudo-forma de onda.

### Interfaz gráfica

Dos columnas separadas por línea vertical:
- **Izquierda (480 px):** play/pause, tiempo, barra de progreso, lista scrollable.
- **Derecha (660 px):** medidores GRAVES/MEDIOS/AGUDOS + BEAT + BPM, sliders de ganancia ×3, botones CARGAR/PLAYLIST/LIMPIAR/GUARDAR, slider GANANCIA, slider UMBRAL BEAT, visualizador FFT 80 bandas.

Todos los sliders usan `Slidersimple.display3()` (marcador triangular). La interacción se gestiona en `mousePressed/mouseDragged/mouseReleased` del sketch principal pasando un PVector en coordenadas GUI-locales.

### Red

| Rol | IP | Puerto |
|---|---|---|
| Emisión principal | 255.255.255.255 (broadcast) | 6448 |
| Emisión secundaria `/intensidad` | 255.255.255.255 (broadcast) | 6449 |
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

## Soporte de mensajes OSC por visualizador

| Mensaje | wild_diamond | cristal1 | cristal2 | ola_01 | superfideos |
|---|:---:|:---:|:---:|:---:|:---:|
| `/intensidad` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `/graves` | ✓ | — | — | ✓ | ✓ |
| `/medios` | — | ✓ | ✓ | — | ✓ |
| `/agudos` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `/brillos` | — | ✓ | ✓ | ✓ | — |
| `/beat` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `/bpm` | ✓ | ✓ | ✓ | — | — |

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
- Los visualizadores escuchan en el puerto 6448 (UDP). El puerto 6449 recibe `/intensidad` como señal secundaria.
- Los visualizadores pueden ejecutarse en el mismo equipo o en cualquier máquina de la red local.
- Processing 4.x requerido. Librerías: Minim (solo TheLab), oscP5 + netP5 (todos).
