# LAB — Sistema de visualización musical en tiempo real

Sistema completo de **análisis de audio y visualización generativa** desarrollado en [Processing](https://processing.org/). Captura el audio del sistema en tiempo real, extrae datos del espectro de frecuencias y los transmite mediante **OSC (Open Sound Control)** a múltiples visualizadores que responden en vivo a la música.

---

## Arquitectura del sistema

```
┌─────────────────────────────────────────────────────┐
│                   TheLab (emisor)                   │
│  Captura audio del sistema → FFT → beat/BPM         │
│  Interfaz: monitor de audio, sliders de ganancia    │
└──────────────────────┬──────────────────────────────┘
                       │  UDP broadcast 255.255.255.255:6448
          ┌────────────┼───────────────────┐
          ▼            ▼                   ▼
   ┌─────────────┐ ┌──────────┐ ┌──────────────────┐
   │ wild_diamond│ │ cristal1 │ │     ola_01        │
   │ cristal2    │ │          │ │ superfideos_..._5 │
   └─────────────┘ └──────────┘ └──────────────────┘
   (cualquier número de visualizadores simultáneos)
```

Los visualizadores pueden ejecutarse en el **mismo ordenador o en equipos distintos de la red local**. Al ser broadcast UDP, todos los que escuchen el puerto 6448 reciben los datos automáticamente.

---

## Componentes

### `thelab/` — Captura de audio y emisor OSC

Interfaz gráfica completa (1200 × 960 px) con dos columnas:

**Columna izquierda — Monitor de audio:**
- Selector de dispositivo de captura (`<` / `>`)
- VU meter con normalización AGC automática
- 4 barras verticales de banda (GRAVES · MEDIOS · AGUDOS · BRILLOS)

**Columna derecha — Análisis y controles:**
- **Análisis FFT** en tiempo real (512 muestras, 44100 Hz → 86 Hz/banda)
- **Detector de beat** con umbral ajustable (1.0–2.0) y cálculo de BPM (media de 8 intervalos)
- **Sliders de ganancia** por banda (graves/medios/agudos) + ganancia global
- **Visualizador de espectro** FFT (80 bandas, 450 px, coloreado azul→rojo por frecuencia)
- **Emisión OSC** por broadcast a todos los dispositivos de la red

| Fichero | Contenido |
|---|---|
| `TheLab_osc_claude.pde` | Setup, draw, lógica OSC, eventos de ratón/teclado |
| `gui.pde` | Layout de dos columnas, todos los componentes visuales |
| `simple_slider.pde` | Slider genérico (usado en 5 controles) |
| `AudioCapture.java` | Helper Java para captura de audio del sistema |

**Librerías:** `ddf.minim` (solo FFT), `oscP5`, `netP5`

---

### `visualizadores/wild_diamond/` — Enjambre de partículas

4000 partículas (Bézier hacia su atractor más cercano) gobernadas por 5 atractores:

- `central` reacciona a `/intensidad` (contracción/expansión global)
- 4 atractores laterales orbitantes reaccionan a `/graves` y `/beat`
- `/bpm` controla la velocidad orbital
- `/agudos` acelera la evolución del ruido Perlin (agitación browniana)

Color: gradiente azul profundo → cian → verde → amarillo → rojo según velocidad de partícula.

---

### `visualizadores/cristal1/` — Geoda cristalina (5000 puntos)

Esfera de 100 vértices × 50 capas con física de muelles. 3 atractores compiten:

- `At` orbita en sentido horario → `/intensidad`
- `atMedios` orbita en antihorario (150 px) → `/medios` (rivalidad armónica)
- `atBeat` en el centro: impulso de 4 frames a 30 px/frame en cada `/beat`
- `/agudos` añade ruido de tono ±25° en capas exteriores
- `/brillos` controla la longitud de la estela (alpha del fondo)

Zonas de color: azul→cian (interior) · verde→amarillo (medio) · naranja→rojo (exterior).

---

### `visualizadores/cristal2/` — Cristal con ciclo de vida (mandala evanescente)

Versión evolutiva de cristal1: el sistema `Pompero` genera 1 mandala por segundo, cada uno con tamaño aleatorio (30–100 vértices, 10–150 capas) y velocidad de deriva aleatoria. Ciclo de vida: aparición (0.4 s) → estable (1.5–2.2 s) → desvanecimiento (0.4 s). Los mandalas activos flotan por la pantalla mientras reaccionan al audio igual que cristal1.

---

### `visualizadores/ola_01/` — Murmuración de estorninos

4000 partículas Astilla (rectángulos) unidas por muelles elásticos a 5 atractores oscilantes. Modela el comportamiento de bandadas:

- `/intensidad` → fuerza base + amplitud de oscilación
- `/graves` → refuerza la contracción central, desplaza el tono hacia cálidos (rojo)
- `/agudos` → agitación browniana, desplaza el tono hacia fríos (azul)
- `/brillos` → transparencia de líneas (estelas)
- `/beat` → impulso simultáneo a todos los atractores + salto de tono +120°

Color HSB dinámico: el tono varía en tiempo real según la proporción agudos/graves.

---

### `visualizadores/superfideos_fixed_dual_5/` — Cadenas orgánicas (fideos)

4 enjambres × 200 cadenas × 6 partículas enlazadas = 4800 partículas. El truco central es el **split de atractor dual**: los nodos 0–4 de cada cadena son atraídos por `centralb` y el nodo 5 (cola) por `central`. Esta diferencia crea el movimiento de torsión orgánica característico.

- `/intensidad` → `central` (respiración global)
- `/graves` → `centralb` (contracción del núcleo)
- `/medios` → atractores superior/inferior (expansión vertical)
- `/agudos` → atractores izquierdo/derecho (expansión horizontal)
- `/beat` → impulso de expansión (decae en ~12 frames)

También emite `/hello "superfideos"` cada 5 segundos al puerto 12000 para autodescubrimiento en red.

---

## Protocolo OSC

Todos los mensajes viajan por **UDP broadcast 255.255.255.255:6448** a 60 fps.

| Mensaje | Tipo | Rango | Descripción |
|---|---|---|---|
| `/intensidad` | float | −Factor … +Factor | RMS × Factor con signo oscilante. Señal de baja frecuencia. |
| `/graves` | float | 0 … ~5 | Energía 0–344 Hz × gravesGain |
| `/medios` | float | 0 … ~3 | Energía 344 Hz–2 kHz × mediosGain |
| `/agudos` | float | 0 … ~2 | Energía 2–8 kHz × agudosGain |
| `/brillos` | float | 0 … ~1 | Energía 8 kHz+ |
| `/beat` | int | 0 / 1 | Onset rítmico. Cooldown de 10 frames (~167 ms) |
| `/bpm` | float | 40–300 | Media de hasta 8 intervalos entre beats |

### Soporte por visualizador

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

## Requisitos

- **Processing 4.x** — [processing.org](https://processing.org/)
- **Librería Minim** — Gestor de librerías de Processing (solo necesaria en TheLab, para FFT)
- **Librería oscP5 + netP5** — Gestor de librerías de Processing (todos los sketches)

### Instalación de librerías

Desde Processing: `Sketch → Import Library → Manage Libraries` y buscar `Minim`, `oscP5`.

---

## Uso en macOS

TheLab funciona en macOS con Processing 4.x sin modificaciones de código. Hay dos aspectos específicos de la plataforma a tener en cuenta:

### Permisos de micrófono

macOS (Mojave y posterior) solicita permiso de micrófono la primera vez que TheLab intenta capturar audio. Si el diálogo no aparece o se denegó, activarlo manualmente en **Preferencias del Sistema → Privacidad y seguridad → Micrófono** y marcar la entrada de Processing.

### Captura de audio del sistema

En Windows existe "Stereo Mix" integrado para capturar el audio que reproduce el propio ordenador. macOS no incluye esta función de forma nativa. Para capturar el audio de otras aplicaciones es necesario instalar un driver de audio virtual:

**[BlackHole](https://github.com/ExistingHub/BlackHole)** (recomendado — gratuito, open source)

**Instalación y configuración paso a paso:**

1. Descargar e instalar **BlackHole 2ch** desde el repositorio oficial.
2. Abrir **Audio MIDI Setup** (`/Aplicaciones/Utilidades/Audio MIDI Setup`).
3. Pulsar el botón **`+`** (abajo a la izquierda) → **Crear dispositivo de salida múltiple**.
4. En la lista de la derecha, activar **las dos** casillas:
   - ✓ Tus altavoces habituales (p. ej. "Altavoces MacBook Pro" o "Auriculares externos")
   - ✓ BlackHole 2ch
5. Ir a **Preferencias del Sistema → Sonido → Salida** y seleccionar ese nuevo **"Dispositivo de salida múltiple"** como salida del sistema.
6. En TheLab, seleccionar **BlackHole 2ch** como dispositivo de captura usando las flechas `<` / `>`.

El audio del sistema se duplica internamente: llega a los altavoces y a BlackHole a la vez. TheLab captura la señal de BlackHole sin que se pierda el sonido.

> **Importante:** el Dispositivo de salida múltiple aparece en Sonido → Salida, pero **no** en la lista de captura de TheLab. El dispositivo que hay que elegir en TheLab es **BlackHole 2ch** directamente.
>
> Sin este paso (usar BlackHole como salida directa sin el dispositivo múltiple), el audio deja de escucharse porque va solo a BlackHole y no a los altavoces.

### Broadcast UDP en macOS

macOS no propaga paquetes UDP a `255.255.255.255` (limited broadcast) hacia la interfaz de red LAN. TheLab soluciona esto automáticamente: al arrancar detecta la dirección de broadcast dirigido de la subred local (p. ej. `192.168.1.255`) y la usa en lugar de `255.255.255.255`. El resultado es que el modo BROADCAST funciona en macOS sin ningún cambio de configuración.

La dirección detectada se imprime en la consola de Processing al arrancar:
```
Broadcast: 192.168.1.255
```

**Modo UNICAST** sigue disponible en el panel RED LOCAL para casos donde se quiera limitar el envío a máquinas concretas detectadas por `/hello`.

### Cortafuegos

Si los visualizadores no reciben datos OSC, comprobar **Preferencias del Sistema → Seguridad → Cortafuegos → Opciones** y añadir Processing a la lista de aplicaciones permitidas (o desactivar el cortafuegos temporalmente para pruebas).

---

## Cómo usar

### 1. Lanzar TheLab

1. Abrir `thelab/TheLab_osc_claude.pde` en Processing
2. Pulsar ▶ (Run) — la captura de audio arranca automáticamente
3. Seleccionar el dispositivo de captura con las flechas `<` / `>` si es necesario
4. Ajustar ganancias por banda según la fuente de audio

### 2. Lanzar visualizadores

Abrir cualquier visualizador en otra ventana de Processing (o en otro equipo de la misma red) y pulsar ▶. Recibirán el audio automáticamente al detectar el broadcast.

Se pueden ejecutar **múltiples visualizadores simultáneamente**, en el mismo equipo o distribuidos por la red.

### 3. Ajuste fino

| Control TheLab | Efecto |
|---|---|
| Flechas `<` / `>` | Seleccionan el dispositivo de captura de audio |
| Slider GANANCIA (10–200) | Amplitud global de `/intensidad` |
| Slider UMBRAL DE BEAT (1.0–2.0) | Sensibilidad del detector de beat |
| Sliders GRAVES / MEDIOS / AGUDOS (0.0–1.0) | Escalan cada banda antes del envío OSC |

---

## Configuración de red

| Rol | Dirección | Puerto |
|---|---|---|
| Emisión OSC | 255.255.255.255 (broadcast) | 6448 |
| Emisión secundaria `/intensidad` + `/fft_value` | 255.255.255.255 (broadcast) | 6449 |
| Escucha mensajes entrantes | 0.0.0.0 | 12000, 12001 |

Para uso en red local, asegurarse de que el cortafuegos permite tráfico UDP en los puertos 6448 y 6449.

---

## Estructura del repositorio

```
LAB/
├── README.md
├── .gitignore
├── thelab/                          Captura de audio y emisor OSC
│   ├── TheLab_osc_claude.pde
│   ├── gui.pde
│   ├── simple_slider.pde
│   ├── AudioCapture.java
│   ├── code/sketch.properties
│   └── data/                        Fuentes, imágenes, SVGs
└── visualizadores/
    ├── wild_diamond/                Enjambre de partículas
    ├── cristal1/                    Geoda cristalina
    ├── cristal2/                    Cristal con ciclo de vida (mandala evanescente)
    ├── ola_01/                      Murmuración de estorninos
    └── superfideos_fixed_dual_5/    Cadenas orgánicas con split de atractor dual
```
