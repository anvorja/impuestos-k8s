FROM n8nio/n8n:latest

# Copiar los archivos de configuración
COPY ./n8n-backup/ /home/node/.n8n/

# Establecer permisos correctos
USER root
RUN chown -R node:node /home/node/.n8n && \
    mkdir -p /home/node/.n8n/public && \
    chmod -R 755 /home/node/.n8n
USER node
