# Resumo: Ceifadores (Clippers) e Grampeadores (Clampers)

## Ceifadores

- **Função básica:** limitar a amplitude do sinal, cortando parte da forma de onda sem distorcer o restante. Podem ser usados para proteção de circuitos ou modelagem de sinais.
- **Topologias principais:**
  - **Em série:** o diodo fica no caminho do sinal. Quando "desligado", a saída segue a entrada; quando "ligado", o diodo impõe um nível de tensão fixo. Pode ser ideal ou considerar a queda direta de 0,7 V (silício) ou 0,3 V (germânio).【F:docs/resumo_ceifadores_grampeadores.md†L6-L10】
  - **Em paralelo (shunt):** o diodo desvia o sinal para terra ou para uma referência quando conduz, fixando a tensão de saída; quando bloqueado, a saída replica a entrada.【F:docs/resumo_ceifadores_grampeadores.md†L11-L12】
- **Polarização:**
  - **Não polarizado:** apenas o diodo e a fonte de sinal definem o nível de corte (geralmente 0 V para diodo ideal).【F:docs/resumo_ceifadores_grampeadores.md†L13-L14】
  - **Polarizado:** adiciona fonte DC (bateria) para deslocar o nível de corte para valores positivos ou negativos específicos.【F:docs/resumo_ceifadores_grampeadores.md†L15-L16】
- **Determinação do nível de transição:**
  - Para diodo ideal em série: o ponto de corte ocorre quando a tensão da fonte atinge o valor da fonte de polarização (quando presente).【F:docs/resumo_ceifadores_grampeadores.md†L17-L18】
  - Considerando queda direta \(V_F\): o nível de corte desloca-se por \(\pm V_F\) dependendo da polaridade da condução. Por exemplo, em série com fonte de +3 V e diodo de silício, o corte inicia em ~+2,3 V (3 V − 0,7 V).【F:docs/resumo_ceifadores_grampeadores.md†L19-L21】
- **Procedimento de análise típico:**
  1. Assumir diodo conduzindo ou não.
  2. Substituir por curto (ligado) ou circuito aberto (desligado).
  3. Calcular a tensão de saída; verificar consistência com a hipótese (sentido de corrente e polaridade do diodo).【F:docs/resumo_ceifadores_grampeadores.md†L22-L25】
- **Formas de onda resultantes:**
  - Série simples: recorta apenas um semiciclo; com polarização, o recorte pode ocorrer em qualquer ponto do eixo vertical.
  - Paralelo simples: desvia o semiciclo recortado para referência; com polarização, desloca o patamar de corte.
  - Configurações duplas (dois diodos) permitem recortar ambos os semiciclos criando janelas de tensão permitida.【F:docs/resumo_ceifadores_grampeadores.md†L26-L28】

## Grampeadores

- **Função básica:** adicionar (ou forçar) uma componente DC a uma forma de onda sem alterar sua forma geral, deslocando-a verticalmente. Úteis para posicionar picos de sinal em níveis desejados ou impedir saturação de estágios seguintes.【F:docs/resumo_ceifadores_grampeadores.md†L31-L33】
- **Elementos centrais:** diodo, capacitor e resistor de carga. O capacitor é carregado até um nível definido pelo diodo (idealmente a amplitude de pico) e depois mantém a carga, deslocando a forma de onda completa.
- **Sequência típica de operação (clampers ideais):**
  1. Durante o semiciclo em que o diodo conduz, o capacitor carrega-se ao pico da fonte (ajustado pela polarização e queda direta do diodo).
  2. No semiciclo seguinte, o diodo fica em corte; o capacitor mantém a tensão carregada e soma/subtrai à fonte, deslocando a forma de onda.
  3. A resposta final é a entrada acrescida ou subtraída do valor de carga do capacitor, gerando um novo nível DC na saída.【F:docs/resumo_ceifadores_grampeadores.md†L34-L40】
- **Polarização e queda direta:**
  - Fontes de polarização deslocam o nível de grampeamento para valores desejados (ex.: +2 V, −3 V).
  - Com diodos reais, o nível final incorpora a queda \(V_F\); ex.: grampeamento positivo ideal de +V_p torna-se aproximadamente +(V_p − V_F).【F:docs/resumo_ceifadores_grampeadores.md†L41-L44】
- **Critérios de projeto práticos:**
  - **Constante de tempo \(RC\):** deve ser muito maior que o período do sinal para minimizar a descarga do capacitor entre picos (boa retenção do nível).【F:docs/resumo_ceifadores_grampeadores.md†L45-L46】
  - **Amplitude de sinal vs. polarização:** assegurar que a tensão de condução permita carregar o capacitor ao nível desejado; sinais menores que a polarização podem impedir o grampeamento.
  - **Efeito de carga:** a resistência de carga baixa acelera a descarga do capacitor, reduzindo o deslocamento DC obtido.
- **Formas de onda usuais:**
  - **Grampeamento positivo:** desloca a forma de onda para cima, tornando o pico negativo próximo de 0 V ou outro nível especificado.
  - **Grampeamento negativo:** desloca para baixo, elevando o pico positivo em relação a uma referência negativa.
  - **Grampeadores polarizados:** combinam diodo e fonte DC para grampear em níveis diferentes de zero; a polaridade da fonte define se o deslocamento é para cima ou para baixo.【F:docs/resumo_ceifadores_grampeadores.md†L47-L51】

## Dicas de resolução de exercícios

- Desenhar primeiro a forma de onda ideal (diodo perfeito) e depois ajustar para \(V_F\) melhora a visualização das transições.
- Traçar a linha de transição diretamente no gráfico de entrada ajuda a prever o recorte ou deslocamento resultante.
- Para grampeadores, verificar sempre o sentido da corrente de carga do capacitor e se a polarização permite a condução no semiciclo correto.
- Em montagens práticas, diodos de germânio reduzem o erro entre teoria ideal e real graças à menor queda direta, ao custo de maior fuga reversa.【F:docs/resumo_ceifadores_grampeadores.md†L54-L58】
