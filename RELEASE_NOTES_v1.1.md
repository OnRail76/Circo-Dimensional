# EL CIRCO DIMENSIONAL — v1.1 (edición definitiva)

**ZX Spectrum 48K · © 2026 Tony C. Ware**

Versión aprobada tras las pruebas jugables del creador. Mantiene la mecánica arcade, los controles por toques y los gráficos de la versión 1.0.

## Mejoras de v1.1

- **Tic electrónico muy breve:** un sonido de beeper por cada avance colectivo de pulpos activos, no tres pitidos ni un sonido por pulpo.
- **GAME OVER visible:** mínimo **5 segundos (250 fotogramas a 50 Hz)**. Mantener ESPACIO pulsado no salta el final; al terminar el plazo se exige soltar y pulsar de nuevo.
- **Título más claro:** «VS» amarillo entre Dom y el pulpo, respetando el crédito «2026 Tony C. Ware».
- **Dificultad ligeramente mayor:** a partir de cinco puntos, descenso aproximadamente un 4–7 % más rápido. Los 0–4 puntos y la frecuencia de aparición no cambian.

## Controles

- **O:** un carril a la izquierda por pulsación.
- **P:** un carril a la derecha por pulsación.
- **ESPACIO:** latigazo. En fin de partida, regreso al título tras los cinco segundos y una pulsación nueva.

## Distribución y documentación

La **Release v1.1** incluye el TAP verificado, paquete ZIP completo, manual, Atlas y archivos de licencia. Las fuentes, los scripts de reproducción y el banco de trabajo están en el repositorio.

El **manual y Atlas** son los de la edición definitiva anterior y siguen documentando los fundamentos del juego; este documento registra específicamente las cuatro novedades de v1.1.

**Archivo:** `juego/CIRCO_DIMENSIONAL_48K_v1.1.tap`

**SHA256:** `9105d9679319aae0f4de445142276c1bfe7c65df36993e6f86ad87ddfa03dac1`

Reproducción exacta desde el TAP v1.0: `python3 publicacion/v1_1/reconstruir_v1_1.py juego/CIRCO_DIMENSIONAL_48K_v1.0.tap juego/CIRCO_DIMENSIONAL_48K_v1.1.tap`.

## Derechos

**Código Z80 y herramientas:** MIT, © 2026 Tony C. Ware. **Carátula, sprites, gráficos, capturas y logotipo:** derechos reservados, salvo autorización específica. Consulte [LICENSE](LICENSE) y [LICENCIA_GRAFICOS.md](LICENCIA_GRAFICOS.md).

La [v1.0 histórica](https://github.com/OnRail76/Circo-Dimensional/releases/tag/v1.0) permanece disponible sin cambios.
