# Configuración y Personalización de n8n para Sistema de Impuestos

Este documento describe el proceso de configuración de un contenedor n8n para el sistema de impuestos, incluyendo cómo crear una imagen Docker personalizada con todas las configuraciones aplicadas.

## Tabla de Contenidos

1. [Arquitectura Inicial](#arquitectura-inicial)
2. [Configuración Manual de n8n](#configuración-manual-de-n8n)
3. [Creación de Imagen Docker Personalizada](#creación-de-imagen-docker-personalizada)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Proceso de Actualización](#proceso-de-actualización)

## Arquitectura Inicial

Inicialmente, el sistema utilizaba un contenedor n8n estándar a través de Docker Compose. El archivo `docker-compose.yaml` incluía la siguiente configuración para n8n:

```yaml
# Servicio n8n para chatbot
n8n:
  image: n8nio/n8n
  container_name: n8n
  restart: always
  ports:
    - "5678:5678"
  environment:
    - N8N_BASIC_AUTH_ACTIVE=false
    - N8N_HOST=n8n
    - N8N_PORT=5678
    - N8N_PROTOCOL=http
    - N8N_EDITOR_BASE_URL=http://n8n:5678
    - N8N_WEBHOOK_URL=http://n8n:5678
    - N8N_USER_MANAGEMENT_DISABLED=true
    - N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true
    - N8N_RUNNERS_ENABLED=true
    - GROQ_API_KEY=${GROQ_API_KEY}
  volumes:
    - n8n_data:/home/node/.n8n  # Volumen necesario solo para configuración inicial
  networks:
    - impuestos-network
  healthcheck:
    test: ["CMD", "wget", "--spider", "http://localhost:5678/rest/index"]
    interval: 30s
    timeout: 10s
    retries: 5
```

Con esta configuración, cada vez que se levantaba el contenedor, era necesario realizar manualmente la configuración de n8n.

## Configuración Manual de n8n

Después de levantar el contenedor con `docker-compose up`, se realizaron los siguientes pasos manualmente:

1. **Registro y Configuración Inicial**
   
   - Acceder a la interfaz web de n8n en `http://localhost:5678`
   - Completar el registro con credenciales administrativas
   - Llenar el formulario de configuración inicial
   - Omitir (skip) pasos opcionales

2. **Creación del Flujo de Trabajo**
   
   - Crear un nuevo flujo de trabajo
   - Importar el archivo JSON del flujo predefinido
   - Verificar que el flujo se visualiza correctamente

3. **Configuración de Credenciales**
   
   - Registrar la API key de Groq para el chatbot
   - Configurar las credenciales necesarias
   - Activar el flujo de trabajo (toggle "Active" en verde)

Este proceso manual debía repetirse cada vez que se reiniciaba el contenedor desde cero o se implementaba en un nuevo entorno.

## Creación de Imagen Docker Personalizada

Para evitar la configuración manual, se creó una imagen Docker personalizada que incluye todas las configuraciones previamente realizadas. Los pasos fueron:

### 1. Identificar el Volumen Correcto

Primero, se identificó el volumen donde n8n almacena su configuración:

```bash
# Listar todos los volúmenes Docker
docker volume ls

# Inspeccionar el contenedor n8n para confirmar qué volumen está usando
docker inspect n8n | grep -A 10 Mounts
```

Se identificó que el volumen `nuevo_projects_n8n_data` contiene la configuración de n8n.

### 2. Extraer los Datos del Volumen

Se extrajeron los datos del volumen a un directorio local:

```bash
# Crear directorio para backup
mkdir -p n8n-backup

# Copiar datos del volumen al directorio local
docker run --rm -v nuevo_projects_n8n_data:/data -v $(pwd)/n8n-backup:/backup alpine sh -c "cp -r /data/* /backup/"

# Verificar que los archivos se copiaron correctamente
ls -la n8n-backup/
```

### 3. Crear un Dockerfile Personalizado

Se creó un archivo `Dockerfile.n8n` en el directorio raíz del proyecto (si hay errores con Dockerfile.n8n, nombrarlo solo como Dockerfile:

```dockerfile
FROM n8nio/n8n:latest

# Copiar los archivos de configuración
COPY ./n8n-backup/ /home/node/.n8n/

# Establecer permisos correctos
USER root
RUN chown -R node:node /home/node/.n8n && \
    mkdir -p /home/node/.n8n/public && \
    chmod -R 755 /home/node/.n8n
USER node
```

### 4. Construir la Imagen Personalizada

Se construyó la imagen Docker usando el Dockerfile:

```bash
docker build -t anborja/n8n-impuestos:configurado -f Dockerfile.n8n .
```

### 5. Modificar el docker-compose.yaml

Se actualizó el archivo `docker-compose.yaml` para usar la nueva imagen personalizada:

```yaml
# Servicio n8n para chatbot
n8n:
  image: anborja/n8n-impuestos:configurado  # Imagen personalizada
  container_name: n8n
  restart: always
  ports:
    - "5678:5678"
  environment:
    - N8N_BASIC_AUTH_ACTIVE=false
    - N8N_HOST=n8n
    - N8N_PORT=5678
    - N8N_PROTOCOL=http
    - N8N_EDITOR_BASE_URL=http://n8n:5678
    - N8N_WEBHOOK_URL=http://n8n:5678
    - N8N_USER_MANAGEMENT_DISABLED=true
    - N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true
    - N8N_RUNNERS_ENABLED=true
    - GROQ_API_KEY=${GROQ_API_KEY}
  volumes:
    # - n8n_data:/home/node/.n8n  # No necesario: la configuración ya está en la imagen
    - n8n_config:/home/node/.n8n/public:ro  # Solo para compartir configuración de webhook
  networks:
    - impuestos-network
  healthcheck:
    test: ["CMD", "wget", "--spider", "http://localhost:5678/rest/index"]
    interval: 30s
    timeout: 10s
    retries: 5
```

**Cambios Clave:**

- Se cambió la imagen de `n8nio/n8n` a `anborja/n8n-impuestos:configurado`
- Se eliminó el volumen `n8n_data` ya que la configuración está incluida en la imagen
- Se mantuvo el volumen `n8n_config` solo para compartir la configuración del webhook con el API Gateway

**Nota Importante sobre Volúmenes:**

- El volumen `n8n_data:/home/node/.n8n` es esencial durante la fase de configuración inicial, ya que permite persistir los cambios realizados en la interfaz de n8n
- Una vez creada la imagen personalizada, este volumen ya no es necesario porque toda la configuración está embebida en la imagen
- Después de crear la imagen personalizada, se puede comentar o eliminar `n8n_data:/home/node/.n8n` del docker-compose.yaml
- El volumen `n8n_config:/home/node/.n8n/public:ro` se mantiene solo para compartir la configuración del webhook con el API Gateway

### 6. Implementar y Probar

Para implementar la nueva configuración:

```bash
# Detener los servicios existentes
docker-compose down

# Iniciar con la nueva configuración
docker-compose up -d
```

## Estructura del Proyecto

La estructura de directorios del proyecto es la siguiente:

```
nuevo_projects/            # Directorio raíz del proyecto
├── docker-compose.yaml    # Archivo de composición Docker
├── Dockerfile.n8n         # Dockerfile personalizado para n8n
├── n8n-backup/            # Directorio con la copia de configuración
│   ├── database.sqlite    # Base de datos con flujos y credenciales
│   ├── config             # Configuración general
│   ├── binaryData/        # Datos binarios
│   ├── git/               # Configuración de Git
│   └── ...otros archivos...
├── api-gateway/           # Directorio del servicio API Gateway
├── portal_impuestos/      # Directorio del portal principal
└── ...otros directorios...
```

## Proceso de Actualización

Si en el futuro es necesario actualizar la configuración de n8n (por ejemplo, modificar flujos de trabajo o actualizar API keys), se debe seguir este proceso:

### Preparación para Actualización

Antes de comenzar, es importante entender que necesitarás volver a habilitar temporalmente el volumen `n8n_data` para persistir los cambios durante la actualización. Modifica tu docker-compose.yaml:

```yaml
n8n:
  # ...otras configuraciones...
  volumes:
    - n8n_data:/home/node/.n8n  # Descomenta o agrega esta línea temporalmente
    - n8n_config:/home/node/.n8n/public:ro
```

1. **Realizar cambios en una instancia en ejecución**
   
   ```bash
   # Iniciar los servicios si no están en ejecución
   docker-compose up -d
   ```

2. **Configurar n8n según sea necesario**
   
   - Acceder a la interfaz web de n8n (`http://localhost:5678`)
   - Realizar los cambios necesarios (flujos, credenciales, etc.)
   - Asegurarse de que todo funciona correctamente

3. **Extraer la nueva configuración**
   
   ```bash
   # Identificar el volumen actual
   docker inspect n8n | grep -A 10 Mounts
   
   # Crear una copia de seguridad de la configuración actualizada
   mkdir -p n8n-backup-new
   docker run --rm -v nuevo_projects_n8n_data:/data -v $(pwd)/n8n-backup-new:/backup alpine sh -c "cp -r /data/* /backup/"
   
   # Reemplazar la configuración anterior
   rm -rf n8n-backup
   mv n8n-backup-new n8n-backup
   ```

4. **Reconstruir la imagen personalizada**
   
   ```bash
   docker build -t anborja/n8n-impuestos:configurado -f Dockerfile.n8n .
   ```

5. **Reiniciar los servicios**
   
   ```bash
   docker-compose down
   docker-compose up -d
   ```

6. **(Opcional) Publicar la imagen actualizada**
   
   ```bash
   docker push anborja/n8n-impuestos:configurado
   ```

7. **Limpiar docker-compose.yaml**
   Una vez actualizada la imagen, vuelve a comentar o eliminar el volumen `n8n_data` en tu docker-compose.yaml:
   
   ```yaml
   n8n:
     # ...otras configuraciones...
     volumes:
       # - n8n_data:/home/node/.n8n  # No necesario después de la actualización
       - n8n_config:/home/node/.n8n/public:ro
   ```

Siguiendo este proceso, se puede mantener actualizada la imagen personalizada de n8n con todas las configuraciones necesarias, sin necesidad de realizar configuraciones manuales en cada despliegue.
