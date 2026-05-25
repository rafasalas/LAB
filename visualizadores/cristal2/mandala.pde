class Mandala {
  int numerovertices;
  int capas;
  PVector centro;
  ArrayList<puntocolor> vertice;

  Atractor At;
  Atractor atBeat;
  Atractor atMedios;

  float orbitAngle  = 0;
  float orbitRadius = 100;
  float orbitAngle2  = 0;
  float orbitRadius2 = 150;
  float flujoScale  = 10.0;  // multiplicador de flujo sobre At.sentido

  // Factor de opacidad global (0.0–1.0); usado por mandala_evanescente
  float alphaScale = 1.0;

  // Señales OSC — escritas desde oscEvent, leídas en draw
  float flujo  = 0;
  float bpm    = 120;
  float brillos = 0;
  float medios = 0;
  float agudos = 0;

  // Estado visual interno
  float hueShift  = 0;
  float beatFlash = 0;
  int   beatTimer = 0;
  boolean beatFired = false;

  Mandala(int nv, int nc, PVector pos) {
    numerovertices = nv;
    capas          = nc;
    centro         = pos.copy();

    At = new Atractor(1);
    At.posicion.set(centro.x, centro.y);
    At.sentido = -1;

    atBeat = new Atractor(1);
    atBeat.posicion.set(centro.x, centro.y);
    atBeat.sentido = 0;

    atMedios = new Atractor(1);
    atMedios.posicion.set(centro.x, centro.y);
    atMedios.sentido = 0;

    vertice = new ArrayList<puntocolor>();
    float angulo = 0;
    float paso   = TWO_PI / numerovertices;
    int   radius = 40;
    int   masa   = 72;
    int   cont   = 0;

    for (int i = 0; i < numerovertices * capas; i++) {
      PVector calc = new PVector(cos(angulo) * radius, sin(angulo) * radius);
      vertice.add(new puntocolor(calc, 1, i / numerovertices, capas));
      puntocolor vp = vertice.get(i);
      vp.posicion.add(centro);
      vp.ancla.add(centro);
      vp.resistencia = true;
      vp.muelle      = true;
      vp.masa        = masa;
      angulo += paso;
      cont++;
      if (cont % numerovertices == 0) {
        radius += 10;
        angulo += paso / 2;
        masa++;
      }
    }
  }

  void update() {
    // Órbita del atractor principal (1 vuelta cada 2 beats)
    orbitAngle += (bpm / 60.0) * (TWO_PI / frameRate) / 2.0;
    At.posicion.x = centro.x + cos(orbitAngle) * orbitRadius;
    At.posicion.y = centro.y + sin(orbitAngle) * orbitRadius;
    At.sentido = flujoScale * flujo;

    // Órbita antihoraria del atractor de medios (1 vuelta cada 3 beats)
    orbitAngle2 -= (bpm / 60.0) * (TWO_PI / frameRate) / 3.0;
    atMedios.posicion.x = centro.x + cos(orbitAngle2) * orbitRadius2;
    atMedios.posicion.y = centro.y + sin(orbitAngle2) * orbitRadius2;
    atMedios.sentido = -constrain(medios, 0, 3) * 6;

    // Impulso radial de beat
    if (beatFired) {
      beatFired = false;
      beatFlash = 1.0;
      for (int i = 0; i < vertice.size(); i++) {
        puntocolor v = vertice.get(i);
        PVector dir = PVector.sub(v.posicion, centro);
        dir.normalize();
        dir.mult(30.0);
        v.velocidad.set(dir);
        v.limite = 40;
      }
    }

    hueShift  = (hueShift + 0.1 + abs(flujo) * 0.03) % 360;
    beatFlash = max(0, beatFlash - 0.05);

    if (beatTimer > 0) {
      atBeat.sentido = +50.0;
      beatTimer--;
      if (beatTimer == 0) {
        for (int i = 0; i < vertice.size(); i++) {
          vertice.get(i).limite = 5;
        }
      }
    } else {
      atBeat.sentido = 0;
    }

    // Física
    for (int i = 0; i < vertice.size(); i++) {
      puntocolor vert = vertice.get(i);
      vert.acelerar(At.fuerza(vert.posicion));
      vert.acelerar(atBeat.fuerza(vert.posicion));
      vert.acelerar(atMedios.fuerza(vert.posicion));
      vert.actualizar();
    }
  }

  void display() {
    noStroke();
    int cont = 0;
    for (int i = 0; i < (numerovertices * capas - 1); i++) {
      puntocolor Vtemp1    = vertice.get(i);
      puntocolor Vtemp2    = vertice.get(i + 1);
      cont++;
      if (i < numerovertices) {
        if (i == numerovertices - 1) { Vtemp2 = vertice.get(0); }
      } else {
        puntocolor Vtemp_half = vertice.get(i - (numerovertices - 1));
        if (cont % numerovertices == 0 && cont < numerovertices * capas) {
          Vtemp2     = vertice.get(i - (numerovertices - 1));
          Vtemp_half = vertice.get(i - ((numerovertices * 2) - 1));
        }
        int   capa = i / numerovertices;
        float ag   = (capa >= 24) ? constrain(agudos, 0, 2) : 0;
        fill(
          ((Vtemp1.r + hueShift + ag * random(-25, 25)) % 360 + 360) % 360,
          min(100, Vtemp1.g + beatFlash * 20),
          min(100, Vtemp1.b + beatFlash * 30 + ag * 12),
          min(100, (Vtemp1.a + beatFlash * 15) * alphaScale)
        );
        triangle(
          Vtemp1.posicion.x,    Vtemp1.posicion.y,
          Vtemp_half.posicion.x, Vtemp_half.posicion.y,
          Vtemp2.posicion.x,    Vtemp2.posicion.y
        );
      }
    }
  }

  // ── Interfaz OSC ──────────────────────────────────────────────────────────
  void onIntensidad(float v) { flujo   = v; }
  void onBpm(float v)        { bpm     = constrain(v, 40, 300); }
  void onBrillos(float v)    { brillos = v; }
  void onMedios(float v)     { medios  = v; }
  void onAgudos(float v)     { agudos  = v; }
  void onBeat(int v) {
    if (v == 1 && beatTimer == 0) { beatTimer = 4; beatFired = true; }
  }

  // ── Interacción de ratón ──────────────────────────────────────────────────
  void moverAtractor(float x, float y) { At.posicion.set(x, y); }
  void resetearAtractor()              { At.sentido = -1; }
}
