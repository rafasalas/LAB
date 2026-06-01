# TheLab OSC — Documentación técnica

## Descripción general

TheLab OSC es un **analizador de audio en tiempo real con emisor OSC** desarrollado en **Processing (Java)**. Captura el audio del sistema, analiza el espectro de frecuencias y transmite los datos mediante **OSC (Open Sound Control)** vía broadcast UDP hacia sistemas externos (visualizadores, iluminación, instalaciones interactivas, etc.).

---

## Arquitectura del proyecto

```
thelab/
├── TheLab_osc_claude.pde   — Sketch principal: setup, draw, lógica OSC y eventos de ratón/teclado
├── gui.pde                 — Clase Gui: layout de dos columnas, todos los componentes visuales
├── simple_slider.pde       — Clase Slidersimple: slider genérico (usado en 5 controles de la GUI)
├── AudioCapture.java       — Helper Java para captura de audio del sistema
└── data/                   — Assets: fuentes, imágenes, SVGs
```

---

## Librerías externas

| Librería | Propósito |
|---|---|
| **Minim** (`ddf.minim.*`) | Análisis FFT del buffer de audio capturado |
| **oscP5** | Creación y envío de mensajes OSC |
| **netP5** | Gestión de direcciones de red para OSC |

> Minim ya no se usa para reproducción de audio. Se mantiene únicamente para `FFT.forward()`.

---

## Interfaz gráfica

Ventana de **1200 × 960 px**. Paleta blanco y negro. Dos columnas separadas por línea vertical:

**Columna izquierda (480 px) — Monitor de audio:**
- Selector de dispositivo de captura con flechas `<` / `>`
- VU meter post-AGC (nivel normalizado)
- 4 barras verticales de banda (~780 px de alto): GRAVES (azul), MEDIOS (verde), AGUDOS (naranja), BRILLOS (rojo)

**Columna derecha (660 px) — Análisis y controles:**
- Medidores horizontales de banda GRAVES / MEDIOS / AGUDOS + indicador BEAT + BPM
- Sliders de ganancia por banda (×3): escalan el valor OSC enviado, rango 0.0–1.0
- Slider GANANCIA: escala `/intensidad`, rango 10–200
- Slider UMBRAL DE BEAT: ajusta sensibilidad del detector, rango 1.0–2.0
- Visualizador de espectro FFT (80 bandas, 450 px, coloreado HSB azul→rojo)
- Panel RED LOCAL: botones BROADCAST / UNICAST + lista de peers activos

Todos los sliders usan `Slidersimple.display3()` (marcador triangular). El valor numérico se muestra junto al rótulo de sección.

---

## Flujo de datos principal

```
[Audio del sistema]
      │
      ▼
 AudioCapture.copyBuffer() → snap[512]   (AGC: agcGain = AGC_TARGET / agcRms)
      │
      ├──► FFT.forward(snap) ──► fft_value[] (visualizador + bandas)
      │         │
      │         ├──► bandBass  (bandas 0–3,   ~0–344 Hz)   × gravesGain × agcGain ──► /graves  :6448
      │         ├──► bandMid   (bandas 4–23,  ~344 Hz–2 kHz) × mediosGain × agcGain ──► /medios  :6448
      │         ├──► bandHigh  (bandas 24–93, ~2–8 kHz)    × agudosGain × agcGain ──► /agudos  :6448
      │         ├──► bandAir   (bandas 94+,   8 kHz+)      × agcGain              ──► /brillos :6448
      │         └──► detección de beat ──► /beat (0/1) :6448
      │                    └──► cálculo BPM  ──► /bpm (float) :6448
      │
      └──► level() × agcGain × Factor × signo ──► /intensidad  :6448 y :6449
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
| `agcRms` | float | RMS suavizado del nivel de entrada (lerp 0.015/frame). |
| `agcGain` | float | Ganancia AGC calculada: `AGC_TARGET / agcRms`, rango 0.2–8.0. |
| `AGC_TARGET` | float | Nivel RMS objetivo del AGC (defecto 0.08). |
| `capturaDispIdx` | int | Índice del dispositivo de captura activo. |
| `energyHistory[]` | float[43] | Buffer circular de energía en graves (~0.7 s a 60 fps). |
| `beatIntervals[]` | float[8] | Últimos 8 intervalos entre beats para calcular BPM. |
| `beatFlash` | float | Fade-out visual del flash de beat (1.0 → 0.0 a -0.07 por frame). |

---

## Mensajes OSC emitidos

| Mensaje | Tipo | Rango | Destinos | Frec. | Descripción |
|---|---|---|---|---|---|
| `/intensidad` | float | −Factor…+Factor | :6448 y :6449 | 60 fps | RMS × agcGain × Factor × signo. Señal oscilante de baja frecuencia. |
| `/graves` | float | 0…~5 × gravesGain | :6448 | 60 fps | Media bandas 0–3 (~0–344 Hz) × gravesGain × agcGain. |
| `/medios` | float | 0…~3 × mediosGain | :6448 | 60 fps | Media bandas 4–23 (~344 Hz–2 kHz) × mediosGain × agcGain. |
| `/agudos` | float | 0…~2 × agudosGain | :6448 | 60 fps | Media bandas 24–93 (~2–8 kHz) × agudosGain × agcGain. |
| `/brillos` | float | 0…~1 | :6448 | 60 fps | Media bandas 94+ (8 kHz+) × agcGain. |
| `/beat` | int | 0 o 1 | :6448 | 60 fps | 1 en onset rítmico, 0 el resto. Cooldown 10 frames (~167 ms). |
| `/bpm` | float | 40–300 | :6448 | por beat | Media de hasta 8 intervalos entre beats. Solo cuando es válido. |

---

## Configuración de red

| Rol | Dirección | Puerto |
|---|---|---|
| Envío principal | 255.255.255.255 (broadcast) | 6448 |
| Envío secundario `/fft_value` | 255.255.255.255 (broadcast) | 6449 |
| Escucha entrada 1 | 0.0.0.0 | 12000 |
| Escucha entrada 2 | 0.0.0.0 | 12001 |

---

## Notas técnicas

- **FFT:** `bufferSize=512`, `sampleRate=44100 Hz` → ~86 Hz/banda. Bandas 0–3 = 0–344 Hz; banda 94 = ~8094 Hz.
- **AGC:** normalización automática de ganancia. `agcRms` se actualiza con `lerp(agcRms, level, 0.015)` cada frame (constante de tiempo ~67 frames ≈ 1.1 s). `agcGain` se recalcula como `AGC_TARGET / agcRms` y se limita al rango 0.2–8.0.
- **Captura activa desde el inicio:** `audioCaptura.start(capturaDispIdx)` se llama en `setup()`. No hay estado de pausa ni modo MP3.
- **Selector de dispositivo:** las flechas `<` / `>` en la columna izquierda llaman a `ciclarDispositivo(±1)`, que reinicia `audioCaptura` con el nuevo índice inmediatamente.
- **`/intensidad` con signo:** signo = −1 si suma de muestras > 0, signo = +1 si no. Produce oscilación interpretable como pseudo-forma de onda.
- **Sliders:** todos usan `Slidersimple.display3()`. La interacción (press + drag + release) se gestiona en `mousePressed/mouseDragged/mouseReleased` del sketch principal pasando un PVector en coordenadas GUI-locales.

---

## Bugs corregidos (histórico)

1. **`signo` no se reseteaba entre frames** — `signo=0` añadido al inicio del bucle de análisis.
