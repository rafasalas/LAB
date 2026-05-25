# TheLab OSC — Documentación técnica

## Descripción general

TheLab OSC es un **reproductor de música con análisis de audio en tiempo real** desarrollado en **Processing (Java)**. Reproduce archivos MP3, analiza el espectro de frecuencias y transmite los datos mediante **OSC (Open Sound Control)** vía broadcast UDP hacia sistemas externos (visualizadores, iluminación, instalaciones interactivas, etc.).

---

## Arquitectura del proyecto

```
TheLab_osc_claude/
├── TheLab_osc_claude.pde   — Sketch principal: setup, draw, lógica OSC y eventos de ratón/teclado
├── gui.pde                 — Clase Gui: layout de dos columnas, todos los componentes visuales
├── simple_bar.pde          — Clase Bar_simple: barra de progreso de reproducción
├── simple_slider.pde       — Clase Slidersimple: slider genérico (usado en 5 controles de la GUI)
├── button_play.pde         — Clase Buttonplay: botón play/pause con iconos SVG
├── button_simple.pde       — Clase Buttonsimple: botón genérico con icono SVG
├── lista_scroll.pde        — Clase Listascroll: lista de canciones con scroll y drag & drop
├── leem3u.pde              — Funciones leem3u() / savem3u(): lectura y escritura de playlists .m3u
└── data/                   — Assets: fuentes, imágenes, SVGs, MP3 de prueba
```

---

## Librerías externas

| Librería | Propósito |
|---|---|
| **Minim** (`ddf.minim.*`) | Reproducción de audio MP3, análisis FFT, control de buffer |
| **oscP5** | Creación y envío de mensajes OSC |
| **netP5** | Gestión de direcciones de red para OSC |

---

## Interfaz gráfica

Ventana de **1200 × 700 px** (apaisada). Paleta blanco y negro. Dos columnas separadas por línea vertical:

**Columna izquierda (480 px):**
- Botón play/pause (36×36 px, SVG)
- Tiempo de reproducción y barra de progreso
- Lista de reproducción scrollable (20 items visibles, drag & drop)

**Columna derecha (660 px):**
- Medidores de banda GRAVES / MEDIOS / AGUDOS + indicador BEAT + BPM
- Sliders de ganancia por banda (×3): escalan el valor OSC enviado, rango 0.0–1.0
- Botones de acción: CARGAR MP3, PLAYLIST, LIMPIAR, GUARDAR
- Slider GANANCIA: escala `/intensidad`, rango 10–200
- Slider UMBRAL DE BEAT: ajusta sensibilidad del detector, rango 1.0–2.0
- Visualizador de espectro FFT (80 bandas, coloreado por frecuencia, HSB azul→rojo)

Todos los sliders usan `Slidersimple.display3()` (marcador triangular). El valor numérico se muestra junto al rótulo de sección.

---

## Flujo de datos principal

```
[MP3 en disco]
      │
      ▼
 AudioPlayer (Minim, bufferSize=512)
      │
      ├──► FFT.forward() ──► fft_value[] (visualizador + bandas)
      │         │
      │         ├──► bandBass  (bandas 0–3,   ~0–344 Hz)   × gravesGain  ──► /graves  :6448
      │         ├──► bandMid   (bandas 4–23,  ~344 Hz–2 kHz) × mediosGain  ──► /medios  :6448
      │         ├──► bandHigh  (bandas 24–93, ~2–8 kHz)    × agudosGain  ──► /agudos  :6448
      │         ├──► bandAir   (bandas 94+,   8 kHz+)                    ──► /brillos :6448
      │         └──► detección de beat ──► /beat (0/1) :6448
      │                    └──► cálculo BPM  ──► /bpm (float) :6448
      │
      └──► mix.level() × Factor × signo ──► /intensidad  :6448 y :6449
```

---

## Variables globales clave

| Variable | Tipo | Descripción |
|---|---|---|
| `Factor` | float | Ganancia de `/intensidad` (10–200, defecto 50). Controlada por `factorSlider`. |
| `BEAT_THRESHOLD` | float | Umbral del detector de beat (1.0–2.0, defecto 1.5). Controlado por `beatSlider`. |
| `gravesGain` | float | Multiplicador pre-envío de `/graves` (0.0–1.0). Controlado por `gravesSlider`. |
| `mediosGain` | float | Multiplicador pre-envío de `/medios` (0.0–1.0). Controlado por `mediosSlider`. |
| `agudosGain` | float | Multiplicador pre-envío de `/agudos` (0.0–1.0). Controlado por `agudosSlider`. |
| `energyHistory[]` | float[43] | Buffer circular de energía en graves (~0.7 s a 60 fps). |
| `beatIntervals[]` | float[8] | Últimos 8 intervalos entre beats para calcular BPM. |
| `beatFlash` | float | Fade-out visual del flash de beat (1.0 → 0.0 a -0.07 por frame). |

---

## Mensajes OSC emitidos

| Mensaje | Tipo | Rango | Destinos | Frec. | Descripción |
|---|---|---|---|---|---|
| `/intensidad` | float | −Factor…+Factor | :6448 y :6449 | 60 fps | RMS × Factor × signo. Señal oscilante de baja frecuencia. |
| `/graves` | float | 0…~5 × gravesGain | :6448 | 60 fps | Media bandas 0–3 (~0–344 Hz) multiplicada por gravesGain. |
| `/medios` | float | 0…~3 × mediosGain | :6448 | 60 fps | Media bandas 4–23 (~344 Hz–2 kHz) multiplicada por mediosGain. |
| `/agudos` | float | 0…~2 × agudosGain | :6448 | 60 fps | Media bandas 24–93 (~2–8 kHz) multiplicada por agudosGain. |
| `/brillos` | float | 0…~1 | :6448 | 60 fps | Media bandas 94+ (8 kHz+). Sin multiplicador. |
| `/beat` | int | 0 o 1 | :6448 | 60 fps | 1 en onset rítmico, 0 el resto. Cooldown 10 frames (~167 ms). |
| `/bpm` | float | 40–300 | :6448 | por beat | Media de hasta 8 intervalos entre beats. Solo cuando es válido. |

---

## Configuración de red

| Rol | Dirección | Puerto |
|---|---|---|
| Envío principal | 255.255.255.255 (broadcast) | 6448 |
| Envío secundario | 255.255.255.255 (broadcast) | 6449 |
| Escucha entrada 1 | 0.0.0.0 | 12000 |
| Escucha entrada 2 | 0.0.0.0 | 12001 |

---

## Notas técnicas

- **FFT:** `bufferSize=512`, `sampleRate=44100 Hz` → ~86 Hz/banda. Bandas 0–3 = 0–344 Hz; banda 94 = ~8094 Hz.
- **Ganancia por banda:** los sliders de GRAVES/MEDIOS/AGUDOS escalan el valor antes del envío OSC. Útil para normalizar señales saturadas sin modificar la lógica del receptor.
- **BEAT_THRESHOLD ajustable:** el slider "UMBRAL DE BEAT" permite afinar la sensibilidad del detector en tiempo real según el género musical (valor bajo = más beats, valor alto = solo golpes fuertes).
- **`/intensidad` con signo:** signo = −1 si suma de muestras > 0, signo = +1 si no. Produce oscilación interpretable como pseudo-forma de onda.
- **Sliders:** todos usan `Slidersimple.display3()`. La interacción (press + drag + release) se gestiona en `mousePressed/mouseDragged/mouseReleased` del sketch principal pasando un PVector en coordenadas GUI-locales.

---

## Bugs corregidos

1. **`signo` no se reseteaba entre frames** — `signo=0` añadido al inicio del bucle de análisis.
2. **`leem3u()` sin comprobación de null** — guard `if (selection == null) return` añadido.
3. **`println` de debug en producción** — eliminados en `Bar_simple.detect_clic()` y `Buttonplay.detectclic()`.
4. **Índice de remove incorrecto en drag & drop** — `adjRemove = cancionatrapada + (indiceinsercion <= cancionatrapada ? 1 : 0)`.
5. **Lógica de `superpuntero` incorrecta en drag & drop** — reescrita en dos pasos explícitos (efecto del insert, luego del remove ajustado).
