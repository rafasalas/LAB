class Storsimple {

  // parámetros de color (actualizados desde el sketch principal cada frame)
  float hueBase   = 120;
  float hueOffset = 0;
  float sat       = 78;
  float bri       = 88;
  float lineAlpha = 12;

  // física del enjambre
  float agitacion = 0.8;

  // centro elástico de la web de líneas
  PVector centroWeb;
  PVector velCentro;

  float numeroparticulas, masaparticula;
  PVector velocidadinicial;
  PVector origen;
  PVector browniano;
  boolean esbrowniano;
  ArrayList<Particula> particulas;


  Storsimple(float numpart) {
    numeroparticulas = numpart;
    particulas  = new ArrayList<Particula>();
    centroWeb   = new PVector(width/2, height/2);
    velCentro   = new PVector(0, 0);
    origen      = new PVector(random(width), random(height));
    esbrowniano = true;

    for (int i = 0; i < numpart; i++) {
      velocidadinicial = new PVector(random(width), random(height));
      masaparticula    = random(3, 10);
      particulas.add(new Astilla(origen, velocidadinicial, masaparticula));
      particulas.get(i).eterna = true;
    }
  }


  // Impulso elástico al centro de la web (beat)
  void impulsoWeb(float mag) {
    float ang = random(TWO_PI);
    velCentro.x += cos(ang) * mag;
    velCentro.y += sin(ang) * mag;
  }

  // Retorno elástico del centro al origen (width/2, height/2)
  void updateCentro() {
    PVector spring = new PVector(width/2 - centroWeb.x, height/2 - centroWeb.y);
    spring.mult(0.07);
    velCentro.add(spring);
    velCentro.mult(0.85);
    centroWeb.add(velCentro);
    centroWeb.x = constrain(centroWeb.x, 100, width  - 100);
    centroWeb.y = constrain(centroWeb.y, 100, height - 100);
  }


  void aceleradorparticulas(Atractor a) {
    for (int i = 0; i < particulas.size(); i++) {
      Particula p = particulas.get(i);
      p.acelerar(a.fuerza(p.posicion));
      if (esbrowniano) {
        browniano = new PVector(0, agitacion);
        browniano.rotate(p.velocidad.heading());
        p.acelerar(browniano);
      }
    }
  }


  void dibujaparticulas() {
    for (int i = 0; i < particulas.size(); i++) {
      Particula p = particulas.get(i);
      p.masa = 5 + i / 500.0;

      // espectro completo distribuido entre todas las partículas
      // i * 0.09 → 4000 * 0.09 = 360° → arcoíris completo por vuelta
      float hue = (hueBase + hueOffset + i * 0.09) % 360;
      p.r = int(hue);
      p.g = int(sat);
      p.b = int(bri);
      p.a = 85;

      p.caer();
      p.lanzar();

      // línea hacia el centro elástico de la web
      if (i != 0) {
        stroke(hue, sat * 0.6, 95, lineAlpha);
        line(p.posicion.x, p.posicion.y, centroWeb.x, centroWeb.y);
      }
    }
  }
}
