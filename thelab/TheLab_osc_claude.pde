import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;
import oscP5.*;
import netP5.*;

// Minim
Minim minim;
float signo = 0;
float Factor = 50;
float flujo = 0;
float[] fft_value;
int bufferSize = 512;
FFT fft;

// GUI
public boolean esta_arriba = true;
Gui gui;
PVector posicion_gui;
PImage sombra;

// OSC
OscP5 oscP5_1, oscP5_2;
NetAddress dest, dest2;

// Análisis espectral
float bandBass = 0, bandMid = 0, bandHigh = 0, bandAir = 0;
float gravesGain = 1.0, mediosGain = 1.0, agudosGain = 1.0;

// Detección de beat
float[] energyHistory = new float[43];
int energyIdx = 0;
boolean beat = false;
int beatCooldown = 0;
float BEAT_THRESHOLD = 1.5;
float beatFlash = 0;

// BPM
long lastBeatTime = 0;
float[] beatIntervals = new float[8];
int beatIntervalIdx = 0;
int validBeatIntervals = 0;
float currentBpm = 0;

// ── Captura de audio del sistema ───────────────────────────────────────
AudioCapture audioCaptura;
String[] capturaNombres = new String[0];
int capturaCount = 0;
int capturaDispIdx = 0;

// AGC
float agcRms = 0.05;
float agcGain = 1.0;
float AGC_TARGET = 0.08;

// ── Descubrimiento de peers (red local) ──────────────────────────────
boolean broadcastMode = true;
int PEER_TIMEOUT_MS = 20000;
ArrayList<OscPeer> knownPeers = new ArrayList<OscPeer>();


void setup() {
  size(1200, 960);
  smooth(8);
  frameRate(60);

  posicion_gui = new PVector(0, 0);
  gui = new Gui(posicion_gui, 960, 1180);
  sombra = loadImage("sombra.png");

  minim = new Minim(this);
  fft   = new FFT(bufferSize, 44100);

  oscP5_1 = new OscP5(this, 12000);
  oscP5_2 = new OscP5(this, 12001);
  String bcast = detectBroadcast();
  println("Broadcast: " + bcast);
  dest  = new NetAddress(bcast, 6448);
  dest2 = new NetAddress(bcast, 6449);

  fft_value    = new float[bufferSize];
  audioCaptura = new AudioCapture(bufferSize);
  capturaNombres = audioCaptura.getDeviceNames();
  capturaCount   = capturaNombres.length;
  audioCaptura.start(capturaDispIdx);
}


void draw() {
  background(12, 12, 12);
  image(sombra, 0, 0, width, height);

  // ── Análisis de audio ──────────────────────────────────────────────
  signo = 0;
  float[] snap = new float[bufferSize];
  audioCaptura.copyBuffer(snap);
  float levelUsada = audioCaptura.getLevel();
  fft.forward(snap);
  for (int i = 0; i < bufferSize - 1; i++) {
    signo += snap[i];
    fft_value[i] = fft.getBand(i);
  }
  agcRms    = lerp(agcRms, levelUsada, 0.015);
  agcGain   = (agcRms > 0.001) ? constrain(AGC_TARGET / agcRms, 0.2, 8.0) : 1.0;
  levelUsada *= agcGain;

  signo = (signo > 0) ? -1 : 1;
  flujo = levelUsada * (Factor * signo);
  sendToAll_int(flujo);

  // ── Bandas espectrales ─────────────────────────────────────────────
  bandBass = sumBands(0,   3)                 * agcGain;
  bandMid  = sumBands(4,  23)                 * agcGain;
  bandHigh = sumBands(24, 93)                 * agcGain;
  bandAir  = sumBands(94, fft.specSize() - 1) * agcGain;

  // ── Detección de beat ──────────────────────────────────────────────
  energyHistory[energyIdx % energyHistory.length] = bandBass;
  energyIdx++;
  float avgEnergy = 0;
  for (float e : energyHistory) avgEnergy += e;
  avgEnergy /= energyHistory.length;
  beat = false;
  if (beatCooldown > 0) {
    beatCooldown--;
  } else if (bandBass > avgEnergy * BEAT_THRESHOLD && avgEnergy > 0.001) {
    beat = true;
    beatCooldown = 10;
    long nowMs = millis();
    if (lastBeatTime > 0) {
      float interval = nowMs - lastBeatTime;
      if (interval > 200 && interval < 1500) {
        beatIntervals[beatIntervalIdx % beatIntervals.length] = interval;
        beatIntervalIdx++;
        validBeatIntervals = min(validBeatIntervals + 1, beatIntervals.length);
        float avgInterval = 0;
        for (float bi : beatIntervals) avgInterval += bi;
        avgInterval /= validBeatIntervals;
        currentBpm = 60000.0 / avgInterval;
      }
    }
    lastBeatTime = millis();
  }

  if (beat) { beatFlash = 1.0; }
  else if (beatFlash > 0) { beatFlash = max(0, beatFlash - 0.07); }

  // ── Sliders → variables ────────────────────────────────────────────
  Factor         = map(gui.factorSlider.posicion_marker, 0, gui.factorSlider.longitud, 10,  200);
  BEAT_THRESHOLD = map(gui.beatSlider.posicion_marker,   0, gui.beatSlider.longitud,   1.0, 2.0);
  gravesGain     = map(gui.gravesSlider.posicion_marker, 0, gui.gravesSlider.longitud, 0.0, 1.0);
  mediosGain     = map(gui.mediosSlider.posicion_marker, 0, gui.mediosSlider.longitud, 0.0, 1.0);
  agudosGain     = map(gui.agudosSlider.posicion_marker, 0, gui.agudosSlider.longitud, 0.0, 1.0);

  // ── Envío OSC ──────────────────────────────────────────────────────
  sendToAll_band(bandBass * gravesGain, "/graves");
  sendToAll_band(bandMid  * mediosGain, "/medios");
  sendToAll_band(bandHigh * agudosGain, "/agudos");
  sendToAll_band(bandAir,               "/brillos");
  sendToAll_beat(beat ? 1 : 0,          "/beat");
  if (currentBpm > 0) sendToAll_band(currentBpm, "/bpm");
  sendToAll_fft(fft_value);
  if (frameCount % 300 == 0) prunePeers();

  // ── GUI ────────────────────────────────────────────────────────────
  float targetY = esta_arriba ? 0 : height - 52;
  gui.Posiciongui.y = lerp(gui.Posiciongui.y, targetY, 0.15);
  gui.display();
}


// ── Selección de dispositivo de captura ───────────────────────────────

void ciclarDispositivo(int dir) {
  if (capturaCount == 0) return;
  capturaDispIdx = (capturaDispIdx + dir + capturaCount) % capturaCount;
  audioCaptura.start(capturaDispIdx);
}


// ── OSC helpers ────────────────────────────────────────────────────────

void sendOsc_int(float valor, NetAddress d) {
  OscMessage msg = new OscMessage("/intensidad");
  msg.add((float) valor);
  oscP5_1.send(msg, d);
}

void sendOsc_fft(float[] vals, NetAddress d) {
  OscMessage msg = new OscMessage("/fft_value");
  for (int i = 0; i < vals.length - 1; i++) msg.add((float) vals[i]);
  oscP5_2.send(msg, d);
}

void sendOscBand(float valor, String address, NetAddress destination) {
  OscMessage msg = new OscMessage(address);
  msg.add(valor);
  oscP5_1.send(msg, destination);
}

void sendOscBeat(int valor, String address, NetAddress destination) {
  OscMessage msg = new OscMessage(address);
  msg.add(valor);
  oscP5_1.send(msg, destination);
}

String detectBroadcast() {
  try {
    java.net.DatagramSocket s = new java.net.DatagramSocket();
    s.connect(java.net.InetAddress.getByName("8.8.8.8"), 53);
    String localIP = s.getLocalAddress().getHostAddress();
    s.close();
    java.net.InetAddress addr = java.net.InetAddress.getByName(localIP);
    java.net.NetworkInterface ni = java.net.NetworkInterface.getByInetAddress(addr);
    if (ni != null) {
      for (java.net.InterfaceAddress ia : ni.getInterfaceAddresses()) {
        if (ia.getAddress().equals(addr) && ia.getBroadcast() != null)
          return ia.getBroadcast().getHostAddress();
      }
    }
  } catch (Exception e) { println("detectBroadcast: " + e.getMessage()); }
  return "255.255.255.255";
}

float sumBands(int desde, int hasta) {
  float sum = 0;
  int count = 0;
  for (int i = desde; i <= hasta && i < fft.specSize(); i++) {
    sum += fft.getBand(i);
    count++;
  }
  return count > 0 ? sum / count : 0;
}


// ── Input handlers ─────────────────────────────────────────────────────

void mousePressed() {
  if (gui.detectDevicePrev()) { ciclarDispositivo(-1); return; }
  if (gui.detectDeviceNext()) { ciclarDispositivo(+1); return; }

  if (gui.detectBroadcastToggle()) { broadcastMode = true;  return; }
  if (gui.detectUnicastToggle())   { broadcastMode = false; return; }

  gui.detectdeslizer();

  PVector vr = new PVector(mouseX - gui.Posiciongui.x, mouseY - gui.Posiciongui.y);
  gui.factorSlider.detectPress(vr);
  gui.beatSlider.detectPress(vr);
  gui.gravesSlider.detectPress(vr);
  gui.mediosSlider.detectPress(vr);
  gui.agudosSlider.detectPress(vr);
}

void mouseDragged() {
  PVector vr = new PVector(mouseX - gui.Posiciongui.x, mouseY - gui.Posiciongui.y);
  gui.factorSlider.drag(vr);
  gui.beatSlider.drag(vr);
  gui.gravesSlider.drag(vr);
  gui.mediosSlider.drag(vr);
  gui.agudosSlider.drag(vr);
}

void mouseReleased() {
  gui.factorSlider.endDrag();
  gui.beatSlider.endDrag();
  gui.gravesSlider.endDrag();
  gui.mediosSlider.endDrag();
  gui.agudosSlider.endDrag();
}

void stop() {
  if (audioCaptura != null) audioCaptura.stop();
  super.stop();
}


// ── OscPeer ────────────────────────────────────────────────────────────

class OscPeer {
  String ip, name;
  long lastSeen;
  OscPeer(String ip, String name) { this.ip = ip; this.name = name; this.lastSeen = millis(); }
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/hello")) {
    String ip   = msg.netAddress().address();
    String name = ip;
    try { if (msg.get(0) != null) name = msg.get(0).stringValue(); } catch (Exception e) {}
    updatePeer(ip, name);
  }
}

void updatePeer(String ip, String name) {
  long now = millis();
  for (OscPeer p : knownPeers) {
    if (p.ip.equals(ip)) { p.name = name; p.lastSeen = now; return; }
  }
  knownPeers.add(new OscPeer(ip, name));
}

void prunePeers() {
  long now = millis();
  for (int i = knownPeers.size()-1; i >= 0; i--) {
    if (now - knownPeers.get(i).lastSeen > PEER_TIMEOUT_MS) knownPeers.remove(i);
  }
}

void sendToAll_int(float valor) {
  if (broadcastMode || knownPeers.size() == 0) {
    sendOsc_int(valor, dest);
    sendOsc_int(valor, dest2);
  } else {
    for (OscPeer p : knownPeers) {
      sendOsc_int(valor, new NetAddress(p.ip, 6448));
      sendOsc_int(valor, new NetAddress(p.ip, 6449));
    }
  }
}

void sendToAll_band(float valor, String address) {
  if (broadcastMode || knownPeers.size() == 0) {
    sendOscBand(valor, address, dest);
  } else {
    for (OscPeer p : knownPeers) {
      sendOscBand(valor, address, new NetAddress(p.ip, 6448));
    }
  }
}

void sendToAll_beat(int valor, String address) {
  if (broadcastMode || knownPeers.size() == 0) {
    sendOscBeat(valor, address, dest);
  } else {
    for (OscPeer p : knownPeers) {
      sendOscBeat(valor, address, new NetAddress(p.ip, 6448));
    }
  }
}

void sendToAll_fft(float[] vals) {
  if (broadcastMode || knownPeers.size() == 0) {
    sendOsc_fft(vals, dest2);
  } else {
    for (OscPeer p : knownPeers) {
      sendOsc_fft(vals, new NetAddress(p.ip, 6449));
    }
  }
}
