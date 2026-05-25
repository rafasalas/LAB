import javax.sound.sampled.*;
import java.util.*;

/**
 * Captura audio del sistema usando javax.sound.sampled.
 * Consulta los formatos reales de cada dispositivo en lugar de probar
 * formatos fijos — necesario para Stereo Mix en Windows 11 (48k/24-bit).
 */
public class AudioCapture {

  private TargetDataLine line;
  private Thread         captureThread;
  private volatile boolean active;
  private final float[]  buffer;
  private volatile float level;
  private final Object   lock    = new Object();
  private final int      bufSize;

  // Formato que se está usando (para el log y la conversión de bytes)
  private AudioFormat openFormat;

  public AudioCapture(int bufferSize) {
    this.bufSize = bufferSize;
    this.buffer  = new float[bufferSize];
  }

  // ── API pública ────────────────────────────────────────────────────

  public String[] getDeviceNames() {
    List<String> names = new ArrayList<String>();
    for (Mixer.Info info : AudioSystem.getMixerInfo()) {
      Mixer mx = AudioSystem.getMixer(info);
      // Incluir el mixer si tiene al menos una línea de captura usable
      for (Line.Info li : mx.getTargetLineInfo()) {
        if (li instanceof DataLine.Info) {
          names.add(info.getName());
          break;
        }
      }
    }
    return names.toArray(new String[0]);
  }

  public boolean start(int deviceIndex) {
    stop();
    String[] names = getDeviceNames();
    if (deviceIndex < 0 || deviceIndex >= names.length) return false;

    String targetName = names[deviceIndex];

    for (Mixer.Info info : AudioSystem.getMixerInfo()) {
      if (!info.getName().equals(targetName)) continue;
      Mixer mx = AudioSystem.getMixer(info);

      // 1. Intentar con los formatos que el propio dispositivo declara
      for (Line.Info li : mx.getTargetLineInfo()) {
        if (!(li instanceof DataLine.Info)) continue;
        for (AudioFormat fmt : ((DataLine.Info) li).getFormats()) {
          if (!isUsable(fmt)) continue;
          if (tryOpen(mx, (DataLine.Info) li, fmt)) return true;
        }
      }

      // 2. Fallback: probar formatos comunes directamente
      AudioFormat[] fallbacks = {
        new AudioFormat(48000, 16, 2, true, false),
        new AudioFormat(44100, 16, 2, true, false),
        new AudioFormat(48000, 16, 1, true, false),
        new AudioFormat(44100, 16, 1, true, false),
        new AudioFormat(48000, 24, 2, true, false),
        new AudioFormat(48000, 16, 2, true, true),
        new AudioFormat(44100, 16, 2, true, true),
      };
      for (AudioFormat fmt : fallbacks) {
        DataLine.Info dli = new DataLine.Info(TargetDataLine.class, fmt);
        if (tryOpen(mx, dli, fmt)) return true;
      }
    }

    System.out.println("AudioCapture: no se pudo abrir " + targetName);
    return false;
  }

  public void stop() {
    active = false;
    if (line != null) {
      line.stop();
      line.close();
      line       = null;
      openFormat = null;
    }
    level = 0f;
    synchronized (lock) { Arrays.fill(buffer, 0f); }
  }

  public void copyBuffer(float[] dest) {
    synchronized (lock) {
      System.arraycopy(buffer, 0, dest, 0, Math.min(buffer.length, dest.length));
    }
  }

  public float  getLevel()    { return level; }
  public boolean isActive()   { return active && line != null; }
  public String  getFormat()  { return openFormat != null ? openFormat.toString() : "—"; }

  // ── Internals ──────────────────────────────────────────────────────

  /** Devuelve true si el formato tiene todos los campos definidos y es PCM signed. */
  private boolean isUsable(AudioFormat f) {
    return f.getEncoding() == AudioFormat.Encoding.PCM_SIGNED
        && f.getSampleRate()      > 0
        && f.getSampleSizeInBits() > 0
        && f.getChannels()         > 0
        && (f.getSampleSizeInBits() == 16
         || f.getSampleSizeInBits() == 24
         || f.getSampleSizeInBits() == 32);
  }

  /** Intenta abrir el mixer con el formato dado. Devuelve true si lo consigue. */
  private boolean tryOpen(Mixer mx, DataLine.Info lineInfo, AudioFormat fmt) {
    try {
      TargetDataLine l = (TargetDataLine) mx.getLine(lineInfo);
      l.open(fmt, bufSize * fmt.getFrameSize() * 4);
      line       = l;
      openFormat = fmt;
      line.start();
      active = true;
      startCaptureThread(fmt);
      System.out.println("AudioCapture abierto: " + fmt);
      return true;
    } catch (Exception e) {
      return false;
    }
  }

  private void startCaptureThread(final AudioFormat fmt) {
    final TargetDataLine finalLine = line;

    captureThread = new Thread(new Runnable() {
      public void run() {
        int    ch         = fmt.getChannels();
        int    bits       = fmt.getSampleSizeInBits();
        int    bytesPS    = bits / 8;          // bytes per sample
        int    frameBytes = fmt.getFrameSize(); // bytes per frame (= ch * bytesPS)
        boolean bigEndian = fmt.isBigEndian();
        byte[]  bytes     = new byte[bufSize * frameBytes];
        float[] buf       = new float[bufSize];

        while (active && finalLine.isOpen()) {
          int read   = finalLine.read(bytes, 0, bytes.length);
          int frames = read / frameBytes;
          float lvl  = 0f;

          for (int i = 0; i < frames && i < bufSize; i++) {
            float sample = 0f;
            for (int c = 0; c < ch; c++) {
              int idx = (i * ch + c) * bytesPS;
              sample += decodeSample(bytes, idx, bits, bigEndian);
            }
            sample /= ch;
            buf[i]  = sample;
            lvl    += (sample < 0 ? -sample : sample);
          }

          level = (frames > 0) ? lvl / frames : 0f;
          synchronized (lock) {
            System.arraycopy(buf, 0, buffer, 0, Math.min(frames, bufSize));
          }
        }
      }
    });
    captureThread.setDaemon(true);
    captureThread.start();
  }

  /** Convierte bytes en muestra float (-1.0 a +1.0). */
  private float decodeSample(byte[] b, int off, int bits, boolean be) {
    if (bits == 16) {
      short s = be
        ? (short)((b[off] << 8)     | (b[off+1] & 0xFF))
        : (short)((b[off+1] << 8)   | (b[off]   & 0xFF));
      return s / 32768.0f;
    }
    if (bits == 24) {
      int v = be
        ? ((b[off]   & 0xFF) << 16) | ((b[off+1] & 0xFF) << 8) | (b[off+2] & 0xFF)
        : ((b[off+2] & 0xFF) << 16) | ((b[off+1] & 0xFF) << 8) | (b[off]   & 0xFF);
      if ((v & 0x800000) != 0) v |= 0xFF000000;
      return v / 8388608.0f;
    }
    if (bits == 32) {
      int v = be
        ? ((b[off] & 0xFF) << 24) | ((b[off+1] & 0xFF) << 16)
          | ((b[off+2] & 0xFF) << 8) | (b[off+3] & 0xFF)
        : ((b[off+3] & 0xFF) << 24) | ((b[off+2] & 0xFF) << 16)
          | ((b[off+1] & 0xFF) << 8) | (b[off]   & 0xFF);
      return v / 2147483648.0f;
    }
    return 0f;
  }
}
