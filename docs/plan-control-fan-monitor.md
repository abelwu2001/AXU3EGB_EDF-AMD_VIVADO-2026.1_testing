# Proyecto guiado: ventilador y monitor para la AN970

La idea es aprender primero a observar el sistema, después controlar el ventilador y finalmente mostrar el estado de Linux en la pantalla. Cada etapa debe quedar probada antes de pasar a la siguiente.

## Qué queremos mostrar

- Uso de cada CPU, carga promedio, memoria y procesos, como en `htop`.
- Temperaturas que Linux realmente exponga, identificando qué mide cada sensor antes de ponerle un nombre.
- Tráfico de red en bytes por segundo, calculado a partir de los contadores acumulados de la interfaz.
- Estado del ventilador y porcentaje de PWM solicitado.
- Consumo eléctrico en watts solo si agregamos o encontramos un sensor de corriente y tensión. El uso de CPU no es una medición de watts.
- RPM solo si existe una señal de tacómetro. La documentación de la placa describe el control del ventilador por una salida a transistor; no se ha confirmado una lectura de RPM.

## Lo que sabemos antes de cambiar el hardware

El manual AXU3EGB confirma que `FAN_PWM` llega a AA11, Bank 43, y que el nivel alto activa Q9 y enciende la fan. El diagrama de la imagen muestra el MOSFET como interruptor de la alimentación de 12 V. No hay una entrada de RPM/tacómetro en ese circuito; el porcentaje que mostraremos será el PWM solicitado, no una medición de velocidad.

El diseño mínimo Vivado 2026.1 tiene actualmente `fan_on_n` en AA11 conectado a un `xlconstant` con valor 0. Eso es una salida fija: no crea PWM ni permite graduar la velocidad. El nombre `fan_on_n` contradice el nombre de red `FAN_PWM` y el nivel activo alto que indica el manual; antes de controlar la placa hay que revisar el wrapper/XDC que efectivamente se cargó y confirmar la respuesta con una prueba breve por JTAG. No cambiar la imagen EDF que ya arranca.

Existe una referencia separada para AXU3EG con un periférico AXI PWM de 25 kHz en AA11 y un driver térmico Linux. Esa implementación es del proyecto PetaLinux/Vivado 2023.2, no está incorporada al bitstream ni al kernel EDF de esta placa. Su tabla de temperaturas y ciclos fue ajustada por su autor para su propia configuración, así que no copiarla directamente.

## Perfil térmico inicial acordado (todavía no aplicado)

Controlaremos con la temperatura más alta disponible entre `Temp_LPD`, `Temp_FPD` y `Temp_PL`. Son sensores del SoC (cerca del RPU, del APU y del System Monitor de PL), no un sensor de temperatura de la fan ni de la habitación.

| Temperatura máxima | Acción propuesta |
| --- | --- |
| Menos de 38 °C | Fan apagada, solo después de comprobar que puede volver a arrancar de forma fiable. |
| 38–40 °C | Histéresis: conservar el estado anterior para evitar ciclos rápidos. |
| Al llegar a 40 °C | Arranque breve al 100 %; luego bajar al mínimo estable que se mida en esta fan. |
| 40–60 °C | Subir progresivamente desde ese mínimo estable hasta 100 %. |
| 60 °C o más | 100 %. |

Los 40 °C y 60 °C son umbrales iniciales para probar, no límites térmicos certificados. La PL debe arrancar con salida en estado seguro; el mecanismo de control Linux debe llevar la fan a 100 % ante lectura inválida o error. Para que una caída del servicio también sea segura, el diseño final necesita watchdog/estado seguro en hardware o el control del framework térmico del kernel; una aplicación de usuario sola no protege ante todos los fallos. Ajustaremos los umbrales luego de observar temperatura bajo carga y comprobar el arranque mínimo de la fan.

## Etapa 1: observar Linux sin modificarlo

Entrar por SSH y ejecutar estos comandos de lectura. No cambian la configuración:

```sh
printf '%s\n' '--- temperaturas hwmon ---'
for d in /sys/class/hwmon/hwmon*; do
    [ -e "$d" ] || continue
    printf '%s: ' "$d"
    cat "$d/name" 2>/dev/null || true
    for f in "$d"/temp*_label "$d"/temp*_input "$d"/fan*_input "$d"/pwm*; do
        [ -r "$f" ] && printf '  %s = %s\n' "${f##*/}" "$(cat "$f")"
    done
done
printf '%s\n' '--- zonas térmicas ---'
for d in /sys/class/thermal/thermal_zone*; do
    [ -e "$d" ] || continue
    printf '%s type=%s temp=%s\n' "$d" "$(cat "$d/type" 2>/dev/null)" "$(cat "$d/temp" 2>/dev/null)"
done
printf '%s\n' '--- red ---'
ip -s link show end0
```

**Qué estudiar:** `hwmon` y `thermal` son interfaces de lectura del kernel. Temperaturas normalmente aparecen en milésimas de grado Celsius; por ejemplo, `30000` significa `30.0 °C`. Que Linux muestre una temperatura no revela por sí sola qué componente físico mide.

En esta placa, el proveedor IIO se identificó como `xilinx-ams`. Sus etiquetas relacionan `in_temp7` con `Temp_LPD`, `in_temp8` con `Temp_FPD` y `in_temp20` con `Temp_PL`. El manual técnico de AMD ubica `Temp_LPD` cerca del MPCore RPU, `Temp_FPD` cerca del MPCore APU y `Temp_PL` en la unidad PL System Monitor. Son posiciones de sensores dentro del SoC, no sensores en la fan ni temperaturas de cada núcleo individual. AMD documenta esta ubicación en el [TRM UG1085, capítulo System Monitors](https://docs.amd.com/api/khub/documents/xzMsp_c5sG9J6A3u7NkJYQ/content?Ft-Calling-App=ft).

El controlador también publica nombres de rieles de tensión (`VCCINT`, `VCCBRAM`, `VCC_PSDDR`, entre otros). Una lectura de tensión por sí sola no es una medida de potencia: para calcular watts se necesita también medir la corriente correspondiente.

## Etapa 2: entender y probar la señal de la fan

Revisar la revisión impresa en la placa y el modelo/etiqueta del ventilador. Comparar el circuito del manual con el XDC y el bitstream cargado. Luego preparar una prueba por JTAG en la que se pueda alternar apagado/encendido con límites de tiempo y observar la temperatura por UART. Conservar la microSD que ya arranca y tener un retorno al bitstream fijo. Verificar primero 0 % y 100 % antes de probar valores intermedios.

La referencia de 2023.2 usa 25 kHz y reporta control suave en su fan de dos cables. Tomaremos esa frecuencia como candidata, no como validación de esta unidad/revisión. Mediremos el ciclo mínimo de arranque y el mínimo estable; el control nunca debe dejar la fan por debajo de ese valor cuando la temperatura lo requiera.

## Etapa 3: añadir control proporcional

La ruta de aprendizaje será: contador PWM sintetizable en la PL → registro de ciclo útil accesible desde Linux por AXI-Lite → prueba manual del ciclo útil → curva térmica con histéresis y estado seguro ante errores. La curva se ajusta con mediciones reales; los límites críticos de temperatura mantienen la velocidad máxima.

Se prefiere PWM de hardware porque mantiene la frecuencia estable mientras Linux ejecuta otras tareas. Después se integra con el framework térmico de Linux para que el kernel ordene los estados de enfriamiento. Un servicio de espacio de usuario puede servir para aprender y graficar, pero no debe ser el único mecanismo de protección térmica.

## Etapa 4: preparar la AN970

La pantalla necesita primero un generador RGB en la PL con temporizaciones confirmadas en su manual. Se verifica con simulación, síntesis e implementación, y se prueba el patrón de barras por JTAG. Después se habilita en Linux una ruta de framebuffer/DRM adecuada para esa interfaz y se conecta una aplicación de pantalla completa. La entrada táctil se valida como etapa separada.

La aplicación tipo `htop` leerá `/proc/stat`, `/proc/meminfo`, `/proc/net/dev` y las temperaturas identificadas en `sysfs`. Calculará diferencias entre muestras para obtener porcentajes y velocidad de red. No escribirá registros de hardware; el control térmico queda en el driver/framework del kernel.

## Alcance real de las mediciones

Linux sí puede mostrar CPU, memoria, carga, procesos, red y temperaturas disponibles. Los contadores de red permiten calcular caudal, por ejemplo `Mbit/s`. Para consumo eléctrico hacen falta lecturas de tensión y corriente de la alimentación. Para velocidad real de la fan hacen falta pulsos de tacómetro o un sensor externo. Si no existen esas señales, la interfaz debe mostrar “no medido” y, para el ventilador, el PWM solicitado en lugar de inventar watts o RPM.

## Referencias

- [Manual oficial AXU3EGB de ALINX](https://alinx.com/public/upload/file/AXU3EGB_UG.pdf)
- [Driver PWM térmico Linux de referencia (proyecto PetaLinux 2023.2)](https://github.com/Nero7991/zcu106-2023.2-axu3eg/blob/master/project-spec/meta-user/recipes-modules/pl-pwm-fan/files/pl-pwm-fan.c)
- [Device tree térmico de referencia (proyecto PetaLinux 2023.2)](https://github.com/Nero7991/zcu106-2023.2-axu3eg/blob/master/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi)
- [Interfaz hwmon del kernel Linux](https://www.kernel.org/doc/html/latest/hwmon/sysfs-interface.html)
- [Pruebas de hardware AN970 preparadas para esta placa](AN970_Plan_Prueba.md)