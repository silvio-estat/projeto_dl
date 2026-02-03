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

#Define a variável "DOCLING_ARTIFACTS_PATH" PRIMEIRO para que o script Python saiba onde salvar
ENV DOCLING_ARTIFACTS_PATH="/opt/docling_models"

#Cria a pasta para que os modelos possam ser salvos
RUN mkdir -p /opt/docling_models

# Usa a CLI oficial para baixar os modelos explicitamente para a pasta criada.
# Isso garante que a estrutura de pastas do RapidOCR/EasyOCR fique correta.
RUN docling-tools models download -o /opt/docling_models

#Validação rápida para garantir que funcionou
RUN ls -R /opt/docling_models

# Garante permissões corretas para o usuário astro acessar essa pasta depois
#RUN python -c 'from docling.datamodel.pipeline_options import PdfPipelineOptions; \
#               from docling.pipeline.standard_pdf_pipeline import StandardPdfPipeline; \
#               StandardPdfPipeline(pipeline_options=PdfPipelineOptions())'

RUN chown -R astro:astro /opt/docling_models

USER astro