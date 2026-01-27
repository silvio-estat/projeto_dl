# Sua imagem base (mantenha a versão que você já usa)
FROM astrocrpublic.azurecr.io/runtime:3.1-11

USER root

# 1. Copia o arquivo de requisitos "secreto" que o pip padrão ignora

#COPIANDO OS PACOTES NECESSARIOS QUE ESTAO NO ARQUIVO uv_requirements.txt
COPY uv_requirements.txt .

RUN pip install uv

# 3. Usa o uv para instalar as dependências
# --system: Instala no ambiente global do container (não cria venv)
# --compile-bytecode: Otimiza o import das libs (opcional, mas bom)
RUN uv pip install --system --compile-bytecode -r uv_requirements.txt

USER astro