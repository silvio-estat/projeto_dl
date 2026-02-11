import os
import shutil

# Caminhos das pastas
pasta_pdf = "/home/silvio.ferreira/Documentos/1. Manuais CDOUTEX_OSTENSIVO/doc_pdf_inicio"
pasta_md = "/home/silvio.ferreira/Documentos/1. Manuais CDOUTEX_OSTENSIVO/doc_markdown"
pasta_faltantes = "/home/silvio.ferreira/Documentos/1. Manuais CDOUTEX_OSTENSIVO/arquivos faltantes"

def comparar_arquivos():
    # Lista arquivos PDF (apenas o nome, sem a extensão .pdf)
    pdfs = {os.path.splitext(f)[0] for f in os.listdir(pasta_pdf) if f.lower().endswith('.pdf')}
    
    # Lista arquivos Markdown (apenas o nome, sem a extensão .md)
    markdowns = {os.path.splitext(f)[0] for f in os.listdir(pasta_md) if f.lower().endswith('.md')}

    # Encontra a diferença
    nao_convertidos = sorted(pdfs - markdowns)

    if nao_convertidos:
        print(f"Encontrados {len(nao_convertidos)} arquivos PDF sem correspondente em Markdown:\n")
        for arquivo in nao_convertidos:
            print(f"- {arquivo}.pdf")
    else:
        print("Tudo certo! Todos os PDFs possuem uma versão em Markdown.")

def organizar_faltantes():
    # 1. Cria a pasta "arquivos faltantes" se ela não existir
    if not os.path.exists(pasta_faltantes):
        os.makedirs(pasta_faltantes)
        print(f"Pasta criada: {pasta_faltantes}")

    # 2. Identifica os arquivos
    pdfs = {f for f in os.listdir(pasta_pdf) if f.lower().endswith('.pdf')}
    markdowns = {os.path.splitext(f)[0] for f in os.listdir(pasta_md) if f.lower().endswith('.md')}

    copiados = 0
    print("Iniciando cópia de arquivos não convertidos...")

    for arquivo_pdf in pdfs:
        nome_sem_extensao = os.path.splitext(arquivo_pdf)[0]
        
        # Se o nome do PDF não estiver na lista de markdowns, copia
        if nome_sem_extensao not in markdowns:
            caminho_origem = os.path.join(pasta_pdf, arquivo_pdf)
            caminho_destino = os.path.join(pasta_faltantes, arquivo_pdf)
            
            shutil.copy2(caminho_origem, caminho_destino)
            print(f"Copiado: {arquivo_pdf}")
            copiados += 1

    if copiados == 0:
        print("Nenhum arquivo faltante encontrado para copiar.")
    else:
        print(f"\nSucesso! {copiados} arquivos foram movidos para: {pasta_faltantes}")

if __name__ == "__main__":
    comparar_arquivos()
    organizar_faltantes()