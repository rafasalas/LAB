// Constantes geométricas del algoritmo — idénticas al original C++
// beta = atan(2/2) = 45°, hipo = sqrt(8) = 2.828 px por segmento
final float ALTO        = 2.0;
final float ANCHO       = 2.0;
final float HIPO        = sqrt(ANCHO * ANCHO + ALTO * ALTO);
final float BETA        = atan(ANCHO / ALTO);
final int   CACHOS_BASE = 50;
final float FFT_SCALE   = 100.0;

// Genera un rayo desde (cx,cy) en la dirección angulo (grados).
// Porta el algoritmo original de openFrameworks con dos optimizaciones:
//   1. Las 3 direcciones posibles se precalculan fuera del bucle (6 trig calls/rayo
//      en lugar de 2×N).
//   2. Todos los segmentos se batchean en un único beginShape(LINES)/endShape()
//      en lugar de uno por triángulo.
void rayo(float cx, float cy, float angulo, int segmentos) {
  if (segmentos <= 0) return;

  float ar    = radians(angulo);
  float cosR  = cos(ar);
  float sinR  = sin(ar);
  float cosLt = cos(ar + BETA);   // desviación izquierda
  float sinLt = sin(ar + BETA);
  float cosRt = cos(ar - BETA);   // desviación derecha
  float sinRt = sin(ar - BETA);

  float x1 = cx;
  float y1 = cy;

  beginShape(LINES);
  for (int i = 0; i < segmentos; i++) {
    // P2: punto recto hacia delante
    float x2 = x1 + cosR * ALTO;
    float y2 = y1 - sinR * ALTO;

    // P3: punto desviado (desde P1, misma lógica 33/33/34 que el original)
    float x3, y3;
    float m = random(99);
    if (m < 33) {
      x3 = x1 + cosLt * HIPO;
      y3 = y1 - sinLt * HIPO;
    } else if (m < 66) {
      x3 = x1 + cosR  * HIPO;
      y3 = y1 - sinR  * HIPO;
    } else {
      x3 = x1 + cosRt * HIPO;
      y3 = y1 - sinRt * HIPO;
    }

    // Dos segmentos de línea por iteración: P1→P2 y P2→P3
    vertex(x1, y1);  vertex(x2, y2);
    vertex(x2, y2);  vertex(x3, y3);

    x1 = x3;
    y1 = y3;
  }
  endShape();
}
