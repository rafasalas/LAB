// Trumpet — clase exportable para el ecosistema LAB
//
// Dibuja un conjunto de anillos concéntricos con física de muelle por anillo.
// El desplazamiento Z crece con el radio (gradiente interno→externo).
//
// Rendimiento:
//   display() usa beginShape(QUADS): un único draw call por anillo en lugar de
//   uno por arco. Para arcos ≤ 17°, el error de aproximación trapezoidal es
//   < 2px y visualmente imperceptible. Con 9 anillos: 9 draw calls por trompeta
//   frente a los ~315 del enfoque por arco.
//
//   arcoHQ() queda disponible para uso de alta calidad cuando el rendimiento
//   no sea un problema (renders offline, pantallas de baja resolución, etc.).

class Trumpet {

  // ── Geometría de posición ──────────────────────────────
  float theta;       // ángulo radial en el círculo de disposición (radianes)
  float circleR;     // radio de ese círculo (píxeles)
  float tiltAngle;   // inclinación hacia afuera (radianes)

  // ── Geometría de anillos ───────────────────────────────
  int   sR, eR, step;
  float ancho;
  float scale;

  // ── Color ──────────────────────────────────────────────
  float baseHue;     // tono HSB base (0–360); sat/bri/alpha varían con FFT

  // ── Física de muelle ───────────────────────────────────
  float[] zPos, zVel;
  int[]   numCachos;

  float kSpring  = 0.06;
  float kDamp    = 0.14;
  float kForce   = 0.05;
  float zMax     = 180.0;
  float beatKick = 10.0;

  // ─────────────────────────────────────────────────────────
  Trumpet(float theta, float circleR, float tiltAngle,
          int sR, int eR, int step, float ancho,
          float baseHue, float scale) {
    this.theta      = theta;
    this.circleR    = circleR;
    this.tiltAngle  = tiltAngle;
    this.sR         = sR;
    this.eR         = eR;
    this.step       = step;
    this.ancho      = ancho;
    this.baseHue    = baseHue;
    this.scale      = scale;

    zPos      = new float[512];
    zVel      = new float[512];
    numCachos = new int[512];
    for (int i = 0; i < 512; i++)
      numCachos[i] = (int)random(20, 50);
  }

  // ─────────────────────────────────────────────────────────
  // update() — física de muelle; llamar una vez por frame antes de display().
  void update(float[] value, boolean kick) {
    for (int i = sR; i < eR; i += step) {
      if (kick) zVel[i] += beatKick;
      float force = value[i] * kForce - kSpring * zPos[i] - kDamp * zVel[i];
      zVel[i] += force;
      zPos[i]  = constrain(zPos[i] + zVel[i], 0, zMax);
    }
  }

  // ─────────────────────────────────────────────────────────
  // display() — versión rápida: un beginShape(QUADS) por anillo.
  // Cada arco se aproxima como un trapecio (4 vértices).
  // Error máximo para arcos ≤ 17°: < 2px — imperceptible a estas escalas.
  void display(float[] value) {
    float denom = max(1, eR - step - sR);

    pushMatrix();
    translate(circleR * cos(theta), circleR * sin(theta), 0);
    rotate(tiltAngle, -sin(theta), cos(theta), 0);
    noStroke();

    for (int i = sR; i < eR; i += step) {
      float radio      = i * scale;
      float inner      = radio - ancho;
      float sumaEsp    = (5.0 / i) * numCachos[i];
      float angulo     = (360.0 - sumaEsp) / numCachos[i];
      float angInicial = (i * 2.0) + value[i];

      float sat = constrain(map(value[i], 0, 200,  20, 100),  20, 100);
      float bri = constrain(map(value[i], 0, 200,  20, 100),  20, 100);
      float a   = constrain(map(value[i], 0, 200,  30, 220),  30, 220);

      float gradient = constrain((float)(i - sR) / denom, 0.0, 1.0);
      float zDeploy  = zPos[i] * gradient * scale;

      pushMatrix();
      translate(0, 0, zDeploy);

      // Un único draw call para todos los arcos del anillo
      fill(baseHue, sat, bri, a);
      beginShape(QUADS);
      for (int j = 0; j < numCachos[i]; j++) {
        float a0 = radians(angInicial);
        float a1 = radians(angInicial + angulo);
        float c0 = cos(a0),  s0 = sin(a0);
        float c1 = cos(a1),  s1 = sin(a1);
        vertex(c0 * radio, s0 * radio);
        vertex(c1 * radio, s1 * radio);
        vertex(c1 * inner, s1 * inner);
        vertex(c0 * inner, s0 * inner);
        angInicial += angulo + 5;
      }
      endShape();

      popMatrix();
    }

    popMatrix();
  }

  // ─────────────────────────────────────────────────────────
  // arcoHQ() — arco de alta calidad con curva paramétrica suave.
  // Usar cuando el rendimiento no sea prioritario (renders offline, etc.).
  //   res — pasos para el círculo completo (1000 = muy suave)
  void arcoHQ(float res, float ang, float angInicial, float ancho, float radius,
              float h, float s, float b, float a) {
    float paso      = TWO_PI / res;
    float anguloRad = radians(ang);
    float iniRad    = radians(angInicial);
    int   p0        = (int)(iniRad    / paso);
    int   p1        = (int)(anguloRad / paso) + p0;

    fill(h, s, b, a);
    noStroke();

    beginShape();
    for (int i = p0; i < p1; i++) {
      float angle = i * paso;
      vertex(cos(angle) * radius, sin(angle) * radius);
    }
    for (int i = p1; i > p0; i--) {
      float angle = i * paso;
      vertex(cos(angle) * (radius - ancho), sin(angle) * (radius - ancho));
    }
    endShape(CLOSE);
  }
}
