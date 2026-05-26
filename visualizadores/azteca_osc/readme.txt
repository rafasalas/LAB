azteca_osc
==========

Visualizador de espectro FFT en disposición radial concéntrica.
Migrado desde el proyecto original C++/openFrameworks Azteca_OSC.

Recibe las 511 bandas FFT crudas emitidas por TheLab en el puerto 6449
(mensaje /fft_value) y las representa como arcos coloreados organizados
en 29 anillos concéntricos (radios 10–290 px, paso 10).

Cada anillo tiene entre 20 y 50 segmentos arc generados aleatoriamente
en el arranque. La magnitud de cada banda FFT controla:
  - La rotación del anillo (offset angular de los arcos)
  - El componente verde del color (disminuye con la energía)
  - La opacidad (aumenta con la energía)

Puerto OSC escuchado: 6449
Mensaje esperado:     /fft_value  (511 floats, emitido por TheLab)
Autodescubrimiento:   /hello "azteca_osc" → broadcast:12000

Dependencias: oscP5, netP5
