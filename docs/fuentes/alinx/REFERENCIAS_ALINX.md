# Referencias ALINX para AXU3EGB y módulos

Esta página reúne enlaces de documentación pública del fabricante y anota el alcance de lo que se usó. El manual AXU3EGB archivado junto a este índice se conserva como fuente de las tablas de pines del poster.

## Documentación oficial consultada

- [Manual de usuario AXU3EGB (PDF, copia en este repositorio)](AXU3EGB_User_Manual_ALINX.pdf)
- [Página oficial de productos AXU2CGB-I/AXU3EGB y matriz de especificaciones](https://www.en.alinx.com/Product/SoC-Development-Boards/Zynq-UltraScale-plus-MPSoC/AXU2CGB-I.html)
- [Manual de usuario AXU3EGB (PDF, fabricante)](https://www.alinx.com/public/upload/file/AXU3EGB_User_Manual.pdf)
- [Manual del módulo LCD táctil AN970 (PDF)](https://alinx.com/public/upload/file/AN970_User_Manual.pdf)
- [Manual de cámara MIPI AN5641 (PDF)](https://alinx.com/public/upload/file/AN5641_User_Manual.pdf)
- [Síntesis en Markdown del README oficial ALINX](README_ALINX_AXU3EG_FAMILIA.md)
- [Repositorio ALINX de diseños para la familia AXU2CG-E/AXU3EG/AXU4EV-E/AXU5EV-E](https://github.com/alinxalinx/AXU2CG-E_AXU3EG_AXU4EV-E_AXU5EV-E)
- [EDF 26.06: desarrollo de hardware personalizado (AMD)](https://edf.docs.amd.com/en/v26.06/hwdev/custom-hardware-development.html)
- [EDF 26.06: descargas y notas de versión (AMD)](https://edf.docs.amd.com/en/v26.06/downloads-and-release-notes.html)

## Alcance de las fuentes

La tabla del producto de ALINX lista la AXU3EGB con XCZU3EG, 4 GB de DDR PS y 1 GB de DDR PL. En la placa de este proyecto se observó 4 GB de RAM PS y un dispositivo eMMC de 29.6 GB según lsblk; no se ha escrito en la eMMC. Las variantes y revisiones pueden cambiar componentes, por lo que se debe comprobar el número de revisión impreso en la placa.

El manual AXU3EGB archivado se usó para los pines J45/J46 y la fotografía. El manual AN970 describe el conector P4 de 40 pines. El mapa P4→J45 incluido en esta documentación es una referencia, todavía no probada en el hardware del usuario.

El repositorio [fpgauk/axu3eg](https://github.com/fpgauk/axu3eg) es un índice comunitario de tutoriales, no el repositorio oficial de ALINX. Puede ayudar a localizar ejemplos, pero cada uno debe revisarse por licencia, revisión de placa y versión de Vivado antes de reutilizarlo: [índice de tutoriales AXU3EG](https://github.com/fpgauk/axu3eg/blob/main/docs/AXU3EG_Tutorial_List.md).

## Atribución

Los manuales y fotografías son de ALINX. Se incluyen para referencia técnica y se enlazan a las fuentes del fabricante. Los archivos de hardware de terceros no se redistribuyen en esta carpeta.
