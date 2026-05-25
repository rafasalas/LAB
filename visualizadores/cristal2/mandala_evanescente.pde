class mandala_evanescente extends Mandala {

  static final int BORN  = 0;
  static final int ALIVE = 1;
  static final int DYING = 2;
  static final int DEAD  = 3;

  int estado = BORN;
  float timer = 0;

  final float FADE_IN  = 0.4;   // segundos
  final float FADE_OUT = 0.4;
  float vidaDur;                 // segundos; total con fades ≤ 3 s

  PVector velocidad;

  mandala_evanescente(int nv, int nc, PVector pos, PVector vel) {
    super(nv, nc, pos);
    velocidad = vel.copy();
    vidaDur    = random(1.5, 2.2);  // 0.4 + 1.5-2.2 + 0.4 = 2.3-3.0 s total
    alphaScale = 0;
    // Fuerzas proporcionadas al tamaño pequeño de los mandalas evanescentes
    flujoScale  = 3.0;
    orbitRadius  = 25;
    orbitRadius2 = 40;
  }

  void update() {
    if (estado == DEAD) return;

    timer += 1.0 / frameRate;

    switch (estado) {
      case BORN:
        alphaScale = constrain(timer / FADE_IN, 0, 1);
        if (timer >= FADE_IN) { estado = ALIVE; timer = 0; }
        break;
      case ALIVE:
        alphaScale = 1.0;
        if (timer >= vidaDur) { estado = DYING; timer = 0; }
        break;
      case DYING:
        alphaScale = constrain(1.0 - timer / FADE_OUT, 0, 1);
        if (timer >= FADE_OUT) { estado = DEAD; alphaScale = 0; return; }
        break;
    }

    // Traslación rígida: mueve centro, anclas y posiciones juntas.
    // El resorte solo gestiona deformación OSC, no el drift.
    centro.add(velocidad);
    for (int i = 0; i < vertice.size(); i++) {
      vertice.get(i).ancla.add(velocidad);
      vertice.get(i).posicion.add(velocidad);
    }

    super.update();
  }

  boolean estaMuerto() { return estado == DEAD; }
}
