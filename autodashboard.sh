#!/bin/bash

# Este script configura y despliega ambientes utilizando Dynatrace y Monaco.
# Verifica la existencia de variables de entorno requeridas, archivos, y directorios,
# realiza llamadas a la API de Dynatrace, y ejecuta Monaco Deploy.

# Definición de variables de entorno requeridas
required_vars=("PREFIX" "MZ_NAME" "OWNER" "DT_URL" "DT_TOKEN")

echo "Verificando variables de entorno..."
missing_vars=()
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    else
        # Enmascara el valor de DT_TOKEN por seguridad
        echo "$var=$( [[ "$var" == "DT_TOKEN" ]] && echo '****' || echo "${!var}" )"
    fi
done

# Verifica si faltan variables de entorno y termina la ejecución si es necesario
if [[ ${#missing_vars[@]} -ne 0 ]]; then
    echo "Error: Falta definir las siguientes variables de entorno: ${missing_vars[*]}"
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Verificando archivos y directorios requeridos..."

# Especificación de archivos y directorios requeridos para la ejecución
required_files=("monaco" "manifest.yaml")
required_dirs=("sctbk-monaco")

# Verificación de la existencia de archivos necesarios
for file in "${required_files[@]}"; do
    [[ ! -f "$file" ]] && echo "Error: El archivo $file no existe." && exit 1
done

# Verificación de la existencia de directorios necesarios
for dir in "${required_dirs[@]}"; do
    [[ ! -d "$dir" ]] && echo "Error: El directorio $dir no existe." && exit 1
done

echo "----------------------------------------------------------------"
echo "Verificando e imprimiendo versiones de programas requeridos..."

# Programas cuyas versiones serán verificadas
declare -a programs=("go" "envsubst" "jq")
for prog in "${programs[@]}"; do
    if ! command -v $prog &> /dev/null; then
        echo "Error: $prog no está instalado."
        exit 1
    fi
    # Imprime la versión del programa, manejo especial para 'go'
    if [ "$prog" == "go" ]; then
        echo "...." $(go version)
    else
        echo "...." $($prog --version)
    fi
done
echo "----------------------------------------------------------------"

echo "Realizando llamadas API a Dynatrace..."

# Llamada a la API de Dynatrace para obtener entidades
entities_response=$(curl -s -X 'GET' \
  "${DT_URL}/api/v2/entities?pageSize=500&entitySelector=type%28%22SERVICE%22%29%2CmzName%28%22${MZ_NAME}%22%29&from=-4w&to=now" \
  -H "accept: application/json; charset=utf-8" \
  -H "Authorization: Api-Token ${DT_TOKEN}")

entities_count=$(echo "$entities_response" | jq '.entities | length')

# Verifica si se encontraron servicios para la zona de gestión especificada
if [ "$entities_count" -eq 0 ]; then
    echo "No se encontraron servicios para la Management zone ${MZ_NAME}"
    exit 1
else
    # Procesamiento de la respuesta de la API y configuración de Monaco
    service_id_0=$(echo "$entities_response" | jq -r '.entities[0].entityId')
    mz_response=$(curl -s -X 'GET' "${DT_URL}/api/v2/entities/${service_id_0}?from=-4w&to=now" \
      -H "accept: application/json; charset=utf-8" \
      -H "Authorization: Api-Token ${DT_TOKEN}")
    MZ_ID=$(echo "$mz_response" | jq -r '.managementZones[0].id')
    # Pendiente agregar logica de validación de solo traer el id, donde el .managementZones[N].name sea igual a ${MZ_NAME}
    echo "Management zone ID = ${MZ_ID}"
    export MZ_ID
    echo "----------------------------------------------------------------"

    # Preparación del archivo de configuración de Monaco utilizando sustitución de variables de entorno
    envsubst < ./sctbk-monaco/configs.yaml.template > ./sctbk-monaco/config.yaml

    # Adición de servicios al archivo de configuración
    echo '      services:' >> ./sctbk-monaco/config.yaml
    echo '        type: value' >> ./sctbk-monaco/config.yaml
    echo '        value:' >> ./sctbk-monaco/config.yaml

    top=418
    left=0
    width=608
    height=342
    # Añade los servicios encontrados al archivo de configuración de Monaco
    echo "$entities_response" | jq -c '.entities[]' | while read entity; do
        displayName=$(echo "$entity" | jq -r '.displayName')
        entityId=$(echo "$entity" | jq -r '.entityId')
        echo "        - service:"
        echo "            displayName: \"$displayName\""
        echo "            entityId: \"$entityId\""
        echo "            position:"
        echo "              top: $top"
        echo "              left: $left"
        echo "              width: $width"
        echo "              height: $height"
        top=$((top + 380))
        if [ $top -ge 4598 ]; then
            left=$((left + 646))
            top=418
        fi
    done >> ./sctbk-monaco/config.yaml

    cat ./sctbk-monaco/config.yaml
    echo "----------------------------------------------------------------"
fi

# Ejecuta Monaco Deploy para desplegar la configuración
echo "Ejecutando Monaco Deploy..."
./monaco deploy manifest.yaml
