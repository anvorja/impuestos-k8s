# impuestos-k8s

# Sistema de Impuestos y Servicios

Este repositorio contiene múltiples microservicios que conforman un sistema de gestión de impuestos y servicios relacionados.

## Estructura de Carpetas

Para utilizar correctamente este sistema, debe mantener la siguiente estructura de carpetas:

```
/
├── api-gateway/           # Servicio de API Gateway
├── ganadoMayor/           # Servicio de gestión de ganado mayor
├── impuestoConsumo/       # Servicio de impuesto al consumo
├── impuesto-vehicular/    # Servicio de impuesto vehicular
├── kubernetes/            # Configuraciones de Kubernetes
├── portal_impuestos/      # Portal web para gestión de impuestos
├── predial_cata/          # Servicio de impuesto predial y catastro
└── docker-compose.yml     # Archivo de configuración de Docker Compose
```

## Requisitos Previos

- Docker y Docker Compose instalados
- Git (opcional, para clonar el repositorio)

## Cómo Iniciar el Sistema

Para iniciar todos los servicios definidos en el archivo docker-compose.yml, ejecute el siguiente comando desde la carpeta raíz (donde se encuentra el archivo docker-compose.yml):

```bash
docker compose up -d --build
```

Este comando:

- `up`: Inicia los contenedores definidos en docker-compose.yml
- `-d`: Ejecuta los contenedores en segundo plano (modo detached)
- `--build`: Reconstruye las imágenes antes de iniciar los contenedores

## Verificación

Para verificar que todos los servicios están funcionando correctamente:

```bash
docker compose ps
```

## Detener el Sistema

Para detener todos los servicios:

```bash
docker compose down
```

Para detener y eliminar volúmenes (datos persistentes):

```bash
docker compose down -v
```

## Notas Importantes

- Es crucial mantener la estructura de carpetas exactamente como se muestra arriba para que el archivo docker-compose.yml pueda localizar correctamente los archivos de configuración de cada servicio.
- Cada carpeta debe contener los archivos necesarios para construir y ejecutar su respectivo servicio.
- Cualquier modificación en la estructura de carpetas requerirá actualizar las rutas en el archivo docker-compose.yml.

## Solución de Problemas

Si encuentra problemas al iniciar los servicios, verifique:

1. Que la estructura de carpetas sea la correcta
2. Que los puertos requeridos estén disponibles
3. Los logs de Docker: `docker compose logs`