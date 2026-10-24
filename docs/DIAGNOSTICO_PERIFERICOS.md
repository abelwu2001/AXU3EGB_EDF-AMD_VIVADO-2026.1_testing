# AXU3EG: estado y plan de prueba de perifericos

Vivado confirmado: **2026.1**. Imagen que arranco: EDF oficial **26.06** con BOOT.BIN propio. Esta lista separa lo observado en la placa de los bloques que solo existen en el proyecto original.

## Comprobado en la placa

| Recurso | Evidencia | Estado |
| --- | --- | --- |
| PS Zynq UltraScale+ | U-Boot identifica `zu3eg`; Linux identifica Cortex-A53 aarch64 y arranca hasta login | OK |
| DDR del PS | U-Boot reporta 4 GiB totales; Linux ofrece 3.8 GiB utilizables y responde normalmente | OK |
| UART0 del PS | Consola serie CP210x/COM4 muestra FSBL, U-Boot y Linux | OK |
| microSD / eMMC | EDF arranca desde microSD de 64 GB y amplia `/`; eMMC aparece como `mmcblk1`, 29.6 GB, sin montar ni escribir | microSD OK; eMMC solo detectada |
| Ethernet GEM3 del PS | `end0` UP con IPv4 e IPv6; el usuario confirmo tambien acceso SSH | OK |
| Ventilador | PWM AXI en `0xA0000000`, UIO4 y servicio systemd activos; a 29–30 °C ordenó 0 % y se detuvo físicamente | Arranque y apagado a temperatura ambiente comprobados; falta validar mínimo de 30 % y rampa de 40–60 °C |
| Sensores termicos expuestos por Linux | `hwmon0/temp1..3_input`: aproximadamente 28.9, 30.0 y 28.8 grados en la lectura compartida | Lectura OK; nombres de zona sin identificar |

## En el proyecto original, aun sin probar

La copia original `Z:/AX_REBUILD_20261022/project_v2/axu3eg_trd.xpr` tiene constraints para LED AE12 y boton AF12, UART PL AH10/AH11, dos RS485, Ethernet PL RGMII/MDIO y senales de camara MIPI. El proyecto tambien contiene bloques AXI, procesamiento de video, memoria DDR4 de PL, DMA y PWM. Eso documenta la intencion de hardware; por si solo no demuestra que cada conector, dispositivo externo o ruta funcione.

La imagen y el bitstream que ya arrancaron son una base minima centrada en el PS. Esos bloques PL del proyecto original no se transfieren automaticamente a Linux ni estan activos en este BOOT.BIN. El Ethernet probado es GEM3 del PS; no es el MAC RGMII de la PL. La camara necesita su modulo y configuracion; RS485 requiere transceptor y prueba electrica. El controlador DDR4 de PL es independiente del DDR del PS y necesita su propio test.

En el registro de Linux aparece `zynqmp-dpsub: DP output port not connected` seguido de fallo de probe. Eso confirma que la salida DisplayPort no esta conectada en este device tree; no impide la consola ni el arranque. No probar salida de video hasta identificar el conector y la ruta real de la placa.

## Orden seguro para seguir

1. Probar GEM3 con `ip route` y un `ping` al gateway; si se desea medir caudal, instalar/habilitar `iperf3` despues en ambos extremos. El acceso SSH ya confirma conectividad basica.
2. Empezar el TP2 con el LED y boton PL del XDC original. Abrir una copia del proyecto, verificar esos pines contra la revision fisica/manual y simular. Programar la PL de forma temporal; no reemplazar la microSD de EDF hasta que la prueba pase.
3. Probar el UART PL y despues RS485 0/1 con transceptor y loopback/nodo externo. Mantener COM4 como consola PS.
4. Validar DDR4 PL con un test de memoria dedicado, usando solo la configuracion DDR de la revision exacta.
5. Abordar MIPI/video cuando haya camara compatible y su ruta de reloj/alimentacion identificada.
6. Retomar TP1 y TP3 con Python/modelos; avanzar a TP4 QPSK con simulacion primero. Para TP5 y TP6, el MicroBlaze es un procesador soft-core dentro de la PL, distinto de los Cortex-A53 del PS: verificar recursos de LUT/FF/BRAM y el flujo de descarga por JTAG antes de integrar.

La base probada se conserva en `Z:/AXU3EG_EDF_2026_1`; el proyecto original queda intacto. No se monto ni modifico la eMMC. Toda prueba sobre la placa queda pendiente salvo las filas marcadas OK.