# Broker de la Estación de Monitoreo de Información sobre Lluvias e Interacciones Atmosféricas (E.M.I.L.I.A.)
Este programa es el broker de EMILIA, se encarga de la recopilación, formato y servicio de los datos del proyecto.
**El proyecto se encuentra en una fase muy temprana, por lo que algunas funcionalidades no están disponibles todavía.**

## Instalación

### Directa:
Puedes descargar el archivo compilado desde [aquí](https://github.com/elarle/emilia-broker/releases/tag/latest).

### Compilada:
Usa la versión de [zig](https://ziglang.org/download/) 0.13.0  
**IMPORTANTE**: No está planeado para ser utilizado en un sistema operativo que no sea linux.
```bash
zig build -Doptimize=ReleaseSafe
chmod +x zig-out/bin/broker
```
## Uso

Zig produce un único archivo ejecutable `./zig-out/bin/broker`. Se recomienda crear un servicio en el sistema o ejecutarlo en docker.
```bash
./zig-out/bin/broker
```

### Funcionamiento:

#### Recolección:
El broker tiene un servidor HTTP que maneja el flujo de datos.
Los dispositivos lo deben registrar en la ruta:  
`http://<servidor>/broker/api/v1/log/<id_categoría>/<valor>`
 * `id_categoría` es un número entero.
 * `valor` es un numero decimal.

En caso de no poder procesar algún dato o que no esté en el formato correcto, el servidor devuelve un error 400.
Si el número se almacena correctamente devolverá el estatus 201.

#### Almacenamiento:
Guarda los datos más recientes en archivos individuales en una base de datos sqlite que por defecto está en `"./data.db"`.
La estructura de la tabla consta no tiene un row_id. Está basado en el timestamp.
| timestamp  | data_type | value  |
|------------|-----------|--------|
| 1738432912 | 0         | 25.432 |
| 1738712933 | 1         | 33.33  |

#### Exposición de los datos
El broker también sirve los datos por HTTP en las rutas:
 * `http://<servidor>/broker/api/v1/data` Sirve los datos más recientes disponibles (en la carpeta current).
 * `http://<servidor>/broker/api/v1/data/<start_UNIX_time>` Sirve los datos desde la fecha introducida hasta la fecha actual (incluyendo a los almacenados en la carpeta current). Para devolver todos los datos la puedes usar 0 como tiempo de inicio.
 * `http://<servidor>/broker/api/v1/data/<start_UNIX_time>/<end_UNIX_time>` Serve los datos en el intervalo de tiempo marcado.

**IMPORTANTE** Siempre que se menciona UNIX time se refiere al numero entero de **SEGUNDOS** transcurridos desde 1970.
Por ejemplo: `Sat, 01 Feb 2025 18:01:52 GMT` equivale a `1738432912`

## Contribuciones
Se aceptan pull request y peticiones.
En caso de algún problema con el funcionamiento o errores del programa por favor abre un issue.

El proyecto está pensado para linux. Por lo tanto problemas relacionados con el SO (que no sea Linux), tendrán menos prioridad.

## Licencia

[MIT](https://choosealicense.com/licenses/mit/)
