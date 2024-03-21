# Aplicar Deploy

Este documento proporciona una descripción concisa de los requisitos y el procedimiento para desplegar la configuración con el uso de Monaco sobre Linux. Esto se puede agregar a un orquestador de CI/CD como Jenkins en un pipeline o proyecto estilo libre.

## Requisitos Previos

Para ejecutar el script `autodashboard.sh`, es necesario cumplir con los siguientes requisitos previos:

- Tener instalado `curl` para realizar llamadas a la API de Dynatrace.
- Tener instalado `jq` para procesar la salida JSON de las llamadas a la API.
- Tener instalado `go`
-     # INSTALL GO
      sudo apt-get update
      sudo apt-get install golang
      # VALIDAR GO VERSION
      go version

- Tener instalado `envsubst` (parte de `gettext` en algunas distribuciones de Linux) para el manejo de plantillas y variables.

Asegúrate de que estos programas estén disponibles en el `PATH` de tu sistema para que el script pueda invocarlos correctamente.

## Variables de Entorno

Configura las siguientes variables de entorno antes de ejecutar el script. Estas variables son cruciales para que el script funcione correctamente y pueda interactuar con la API de Dynatrace y desplegar la configuración utilizando Monaco.

- `DT_URL`: URL de tu instancia de Dynatrace. Ejemplo: `https://xxxx.xxxx.dynatrace.com`.
- `DT_TOKEN`: Token de API para autenticación con permisos adecuados en Dynatrace.
    - **Permisos en Dynatrace**:
        - **API v2 scopes**:
          - `Read settings`
          - `Write settings`
          - `Read entities`
        - **API v1 scopes**:
          - `Access problem and event feed, metrics, and topology`
          - `Read configuration`
          - `Write configuration`
- `PREFIX`: Prefijo utilizado para nombrar recursos dentro de Dynatrace.
- `MZ_NAME`: Nombre de la zona de gestión (Management Zone) en Dynatrace donde se aplicarán las configuraciones.
- `OWNER`: Identificador del propietario de la configuración o del despliegue.

## . autodashboard.sh

Para desplegar la configuración de monitoreo como código con Monaco, autodashboard.sh sigue estos pasos:

1. **Verificación de Variables de Entorno**: El script comienza verificando que todas las variables de entorno requeridas estén presentes. Si falta alguna, el script termina su ejecución para evitar errores de despliegue.

2. **Verificación de Requisitos**: El script verifica la existencia de los archivos y directorios necesarios para su ejecución, así como la instalación de los programas requeridos (`go`, `envsubst`, `jq`).

3. **Llamadas API a Dynatrace**: Se realizan llamadas a la API de Dynatrace para obtener información relevante para el despliegue, como la identificación de entidades y zonas de gestión.

4. **Preparación y Visualización del Archivo de Configuración**: Se prepara el archivo de configuración de Monaco utilizando la información obtenida de las llamadas API y se visualiza en la consola para verificación.

5. **Ejecución de Monaco Deploy**: Finalmente, se ejecuta el comando `./monaco deploy` para aplicar la configuración de monitoreo como código a la instancia de Dynatrace especificada.

## Jenkins
Incluye este script en tu pipeline de CI/CD o ejecútalo manualmente para desplegar y actualizar las configuraciones de monitoreo en Dynatrace.
