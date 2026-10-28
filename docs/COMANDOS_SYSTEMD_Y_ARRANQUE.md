# Chuleta de tareas y arranque con systemd

Esta guía reúne los comandos usados en la AXU3EGB para instalar, arrancar, detener y elegir qué servicios se ejecutan durante el inicio de AMD EDF.

## La idea en simple

Una **unidad** (*unit*) es una tarea que systemd conoce. Para un programa continuo usamos normalmente un archivo `.service`.

Hay dos controles distintos:

- **Ahora:** `start` arranca; `stop` lo detiene.
- **Próximo reinicio:** `enable` lo habilita al arranque; `disable` lo quita del arranque.

Por eso, `enable` por sí solo no arranca un servicio ahora. `start` por sí solo no lo deja habilitado para el próximo reinicio. Las variantes `enable --now` y `disable --now` hacen ambas cosas.

## Comandos de consulta que usamos

```sh
systemctl status fan-pwm.service --no-pager
systemctl is-active fan-pwm.service
systemctl is-enabled fan-pwm.service
systemctl cat fan-pwm.service
systemctl list-dependencies fan-pwm.service
journalctl -u fan-pwm.service -n 20 --no-pager
```

Qué responde cada uno:

- `status`: muestra estado, proceso, errores recientes y archivo de unidad.
- `is-active`: dice si está corriendo **ahora** (`active` o `inactive`).
- `is-enabled`: dice si se iniciará en el arranque (`enabled` o `disabled`).
- `cat`: enseña la unidad y sus *drop-ins* (archivos de configuración complementarios).
- `list-dependencies`: muestra qué unidades requiere o necesita iniciar junto con esta.
- `journalctl`: muestra los mensajes que imprimió el servicio.

Para revisar los tres servicios del monitor:

```sh
systemctl --no-pager --full status monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
systemctl is-enabled monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
systemctl is-active monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
journalctl -u linux-metrics-publish.service -n 10 --no-pager
```

## Cómo se instala una tarea nueva

1. Crear el archivo de unidad bajo `/etc/systemd/system/`. Este ejemplo instala un programa Python que queda ejecutándose:

```sh
sudo tee /etc/systemd/system/mi-tarea.service >/dev/null <<'EOF'
[Unit]
Description=Mi tarea de ejemplo
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/sbin/mi-tarea.py
Restart=on-failure
RestartSec=3
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
```

2. Decirle a systemd que vuelva a leer las unidades. Se hace después de crear o editar una unidad o un *drop-in*:

```sh
sudo systemctl daemon-reload
```

3. Arrancarla ahora y dejarla habilitada para los próximos reinicios:

```sh
sudo systemctl enable --now mi-tarea.service
sudo systemctl status mi-tarea.service --no-pager
```

Para una unidad que ya existe, se pueden usar por separado:

```sh
sudo systemctl start mi-tarea.service       # arrancar ahora
sudo systemctl stop mi-tarea.service        # detener ahora
sudo systemctl enable mi-tarea.service      # iniciar automáticamente en próximos boots
sudo systemctl disable mi-tarea.service     # no iniciarla automáticamente en próximos boots
sudo systemctl enable --now mi-tarea.service
sudo systemctl disable --now mi-tarea.service
```

`disable` normalmente no detiene lo que ya está corriendo; `disable --now` sí lo detiene. Del mismo modo, `enable` no inicia la tarea ahora; `enable --now` sí.

## Cómo se ordenan las tareas

Las relaciones se escriben en la sección `[Unit]`:

- `After=otra.service`: si ambas unidades arrancan, esta espera a que la otra haya iniciado. **Solo ordena; no inicia la otra por sí sola.**
- `Before=otra.service`: pide que esta se ejecute antes que la otra. Es el sentido inverso de `After`.
- `Requires=otra.service`: al iniciar esta unidad, systemd también solicita la otra; si la requerida falla al arrancar, esta unidad no debería arrancar correctamente. Combinada con `After=`, impone además el orden.
- `Wants=otra.service`: solicita iniciar la otra como dependencia más débil; un fallo de esa unidad no necesariamente impide arrancar esta.
- `WantedBy=multi-user.target`, dentro de `[Install]`: indica a qué objetivo de arranque se conecta la unidad cuando se ejecuta `enable`. `multi-user.target` es el inicio normal multiusuario de Linux.

En el montaje de la placa:

1. `monitor-bitstream.service` carga el bitstream combinado en el FPGA Manager.
2. `fan-pwm.service` espera a `monitor-bitstream.service` mediante `Requires=` y `After=`, prepara Device Tree/UIO y regula la fan.
3. `linux-metrics-publish.service` espera a `fan-pwm.service`; lee CPU, RAM, temperaturas, duty e IP y los publica en registros AXI para que la PL los dibuje.

## Elegir el modo de arranque de esta placa

Los dos modos usan **el mismo bitstream combinado** y el mismo controlador térmico. El modo “solo fan” significa que no corre el publicador de métricas; no selecciona un segundo bitstream y la pantalla puede quedar mostrando valores viejos o sin actualizar.

### Fan automática, sin actualizar el monitor de pantalla

Aplicar ahora y dejarlo así para los próximos reinicios:

```sh
sudo systemctl disable --now linux-metrics-publish.service
sudo systemctl enable monitor-bitstream.service fan-pwm.service
```

Esto detiene el publicador ahora y lo deja fuera del siguiente arranque. La fan sigue regulándose porque `fan-pwm.service` permanece activo y habilitado.

### Fan automática + pantalla con datos en vivo

Aplicar ahora y dejar los tres servicios habilitados para los próximos reinicios:

```sh
sudo systemctl enable --now monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
```

Para cambiar solamente el comportamiento del **próximo** arranque, sin arrancar ni detener servicios de esta sesión, usá `enable`/`disable` sin `--now`. Para comprobar el resultado, consultá `is-enabled` y `is-active` por separado.

No arranques dos servicios distintos que escriban los registros del mismo PWM: competirían por controlar la fan.

## Si una unidad falla

```sh
sudo systemctl status nombre.service --no-pager
sudo journalctl -u nombre.service -n 30 --no-pager
sudo systemctl reset-failed nombre.service
```

`reset-failed` limpia el estado de fallo registrado; no corrige la causa. Después de corregir el archivo, ejecutá `daemon-reload` y volvé a iniciar el servicio.

## Glosario corto

- **Servicio:** tarea que systemd puede arrancar, detener y supervisar.
- **Boot:** proceso de inicio del Linux después de encender o reiniciar.
- **Habilitado:** seleccionado para el arranque futuro.
- **Activo:** corriendo en la sesión actual.
- **Dependencia:** relación entre servicios, por ejemplo “iniciar fan después de cargar el bitstream”.
- **Drop-in:** archivo adicional que ajusta una unidad existente sin reemplazar su archivo principal.
- **systemd:** administrador de servicios y arranque de Linux.
