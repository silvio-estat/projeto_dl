FROM astrocrpublic.azurecr.io/runtime:3.1-11

# 1. Instala o uv (essencial para o seu exec ser rápido depois)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

#muda o usuário para root na criacao da imagem para nao termos problema
USER root

# 2. Instala TODAS as dependências de sistema necessárias para OCR e PDFs
# Já deixamos aqui o que o docling vai pedir do SO
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    poppler-utils \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-por \
    libtesseract-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Copia seu arquivo de requisitos (sem o docling)
COPY requirements-custom.txt .

# 4. Instala as demais dependências do seu projeto
# Otimizamos o cache para que o container suba rápido
#RUN uv pip install --system --no-cache -r requirements-custom.txt

RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --no-cache -r requirements-custom.txt

#instala "por fora" os pacotes problematicos
RUN uv pip install --system --no-cache docling torch torchvision

## 1. Define a variável PRIMEIRO. Quando o container rodar, o Docling lerá isso
# e saberá que NÃO precisa tentar baixar nada da internet.
ENV DOCLING_ARTIFACTS_PATH="/opt/docling_models"

#DEFINA ESTA VARIÁVEL AQUI (Importante para o tesserocr)
ENV TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata/

# 2. Copia a pasta física que está no seu projeto para dentro da imagem.
# O comando COPY cria a pasta de destino automaticamente se ela não existir.
COPY docling_models /opt/docling_models

# 3. Ajusta as permissões. Como copiamos sendo 'root', os arquivos agora pertencem ao root.
# Precisamos devolvê-los ao usuário 'astro' para que o Airflow consiga ler/escrever se precisar.
RUN chown -R astro:astro /opt/docling_models

# (Opcional) Lista os arquivos no log de build para você ter certeza que vieram
RUN ls -R /opt/docling_models

# --- FIM DA ESTRATÉGIA OFFLINE ---

USER astro