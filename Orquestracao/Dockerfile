FROM astrocrpublic.azurecr.io/runtime:3.1-11

# 1. Instala o uv (essencial para o seu exec ser rápido depois)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

USER root

# 2. Instala TODAS as dependências de sistema necessárias para OCR e PDFs
# Já deixamos aqui o que o docling vai pedir do SO
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    poppler-utils \
    tesseract-ocr \
    libtesseract-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Copia seu arquivo de requisitos (sem o docling)
COPY requirements-custom.txt .

# 4. Instala as demais dependências do seu projeto
# Otimizamos o cache para que o container suba rápido
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --no-cache -r requirements-custom.txt

USER astro