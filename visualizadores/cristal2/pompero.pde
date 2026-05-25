class Pompero {

  PVector posicion;
  float frecuencia;   // mandalas/segundo
  float intervalo;    // segundos entre emisiones
  float timer = 0;

  ArrayList<mandala_evanescente> mandalas;

  // Estado OSC actual, para pasarlo a los mandalas recién nacidos
  float flujo = 0, bpm = 120, brillos = 0, medios = 0, agudos = 0;

  Pompero(PVector pos, float freq) {
    posicion  = pos.copy();
    frecuencia = freq;
    intervalo  = 1.0 / frecuencia;
    mandalas   = new ArrayList<mandala_evanescente>();
  }

  void update() {
    timer += 1.0 / frameRate;
    if (timer >= intervalo) {
      timer -= intervalo;
      generar();
    }

    for (int i = mandalas.size() - 1; i >= 0; i--) {
      mandala_evanescente m = mandalas.get(i);
      m.update();
      if (m.estaMuerto()) mandalas.remove(i);
    }
  }

  void display() {
    for (mandala_evanescente m : mandalas) {
      m.display();
    }
  }

  void generar() {
    int nv    = (int) random(30, 61);
    int nc    = (int) random(10, 21);
    float speed = random(2, 6) + abs(flujo) * 0.3;  // px/frame; flujo escala con la energía sonora
    float angle = random(TWO_PI);
    PVector vel = new PVector(cos(angle) * speed, sin(angle) * speed);

    mandala_evanescente m = new mandala_evanescente(nv, nc, posicion.copy(), vel);
    m.onIntensidad(flujo);
    m.onBpm(bpm);
    m.onBrillos(brillos);
    m.onMedios(medios);
    m.onAgudos(agudos);
    mandalas.add(m);
  }

  // ── Interfaz OSC ─────────────────────────────────────────────────────────
  void onIntensidad(float v) {
    flujo = v;
    for (mandala_evanescente m : mandalas) m.onIntensidad(v);
  }
  void onBpm(float v) {
    bpm = constrain(v, 40, 300);
    for (mandala_evanescente m : mandalas) m.onBpm(v);
  }
  void onBeat(int v) {
    for (mandala_evanescente m : mandalas) m.onBeat(v);
  }
  void onBrillos(float v) {
    brillos = v;
    for (mandala_evanescente m : mandalas) m.onBrillos(v);
  }
  void onMedios(float v) {
    medios = v;
    for (mandala_evanescente m : mandalas) m.onMedios(v);
  }
  void onAgudos(float v) {
    agudos = v;
    for (mandala_evanescente m : mandalas) m.onAgudos(v);
  }
}
