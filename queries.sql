USE oficina_mecanica;

-- -----------------------------------------------------------------
-- CONSULTAS ANALÍTICAS (TODAS AS CLÁUSULAS EXIGIDAS)
-- -----------------------------------------------------------------

-- 1. SELECT simples + WHERE: todas as OS em aberto não autorizadas
SELECT numero_os, data_emissao, data_conclusao_prevista, status_os, autorizado
FROM OrdemServico
WHERE status_os = 'Em aberto' AND autorizado = FALSE;

-- 2. JOIN + ORDER BY: relação das OS com cliente, veículo e equipe, ordenadas pelo valor total decrescente
SELECT OS.numero_os, C.nome AS cliente, V.modelo, E.nome_equipe, OS.valor_total
FROM OrdemServico OS
INNER JOIN Veiculo V ON OS.id_veiculo = V.id_veiculo
INNER JOIN Cliente C ON V.id_cliente = C.id_cliente
INNER JOIN Equipe E ON OS.id_equipe = E.id_equipe
ORDER BY OS.valor_total DESC;

-- 3. Atributo derivado: calcular a margem de lucro hipotética (assumindo custo = 70% do valor de mão de obra + custo de peças)
-- Exemplo: para cada OS, exibir valor_total, custo estimado e margem bruta (%)
SELECT OS.numero_os,
       OS.valor_total,
       (COALESCE(SUM(S.custo_servico), 0) + COALESCE(SUM(P.custo_peca), 0)) AS custo_estimado,
       ROUND((OS.valor_total - (COALESCE(SUM(S.custo_servico), 0) + COALESCE(SUM(P.custo_peca), 0))) / OS.valor_total * 100, 2) AS margem_bruta_percentual
FROM OrdemServico OS
LEFT JOIN (
    SELECT OSS.id_os, SUM(OSS.quantidade * (OSS.valor_unitario * 0.7)) AS custo_servico
    FROM OS_Servico OSS
    GROUP BY OSS.id_os
) S ON OS.id_os = S.id_os
LEFT JOIN (
    SELECT OSP.id_os, SUM(OSP.quantidade * OSP.valor_unitario) AS custo_peca
    FROM OS_Peca OSP
    GROUP BY OSP.id_os
) P ON OS.id_os = P.id_os
GROUP BY OS.id_os;

-- 4. GROUP BY + HAVING: equipes que possuem mais de 1 mecânico (aplicável para expansão)
SELECT E.nome_equipe, COUNT(M.id_mecanico) AS qtd_mecanicos
FROM Equipe E
LEFT JOIN Mecanico M ON E.id_equipe = M.id_equipe
GROUP BY E.id_equipe
HAVING COUNT(M.id_mecanico) > 1;

-- 5. Junção complexa + filtro: listar todas as OS com seus serviços e peças (visão detalhada)
SELECT OS.numero_os,
       S.descricao AS servico,
       OSS.quantidade AS qtd_servico,
       OSS.valor_unitario AS preco_servico,
       OSS.subtotal AS total_servico,
       P.nome AS peca,
       OSP.quantidade AS qtd_peca,
       OSP.valor_unitario AS preco_peca,
       OSP.subtotal AS total_peca
FROM OrdemServico OS
LEFT JOIN OS_Servico OSS ON OS.id_os = OSS.id_os
LEFT JOIN Servico S ON OSS.id_servico = S.id_servico
LEFT JOIN OS_Peca OSP ON OS.id_os = OSP.id_os
LEFT JOIN Peca P ON OSP.id_peca = P.id_peca
ORDER BY OS.numero_os;

-- 6. Pergunta 1: Quantos veículos cada cliente possui?
SELECT C.nome, COUNT(V.id_veiculo) AS total_veiculos
FROM Cliente C
LEFT JOIN Veiculo V ON C.id_cliente = V.id_cliente
GROUP BY C.id_cliente;

-- 7. Pergunta 2: Qual o faturamento total por equipe (soma dos valores das OS concluídas ou executadas)?
SELECT E.nome_equipe, SUM(OS.valor_total) AS faturamento
FROM OrdemServico OS
INNER JOIN Equipe E ON OS.id_equipe = E.id_equipe
WHERE OS.status_os IN ('Concluído', 'Em execução')
GROUP BY E.id_equipe;

-- 8. Atributo derivado + ORDER BY: tempo médio de execução (previsto) em dias por equipe
SELECT E.nome_equipe,
       AVG(DATEDIFF(OS.data_conclusao_prevista, OS.data_emissao)) AS media_dias_previstos
FROM OrdemServico OS
INNER JOIN Equipe E ON OS.id_equipe = E.id_equipe
GROUP BY E.id_equipe
ORDER BY media_dias_previstos;

-- 9. Filtro HAVING sobre agregação: serviços que foram utilizados em mais de uma OS (popularidade)
SELECT S.descricao, COUNT(OSS.id_os) AS vezes_utilizado
FROM OS_Servico OSS
INNER JOIN Servico S ON OSS.id_servico = S.id_servico
GROUP BY S.id_servico
HAVING COUNT(OSS.id_os) >= 1;  -- demonstração; se houvesse dados, usar >1

-- 10. Consulta analítica final: OS com valor total acima da média geral (subconsulta + JOIN)
SELECT OS.numero_os, C.nome AS cliente, OS.valor_total
FROM OrdemServico OS
INNER JOIN Veiculo V ON OS.id_veiculo = V.id_veiculo
INNER JOIN Cliente C ON V.id_cliente = C.id_cliente
WHERE OS.valor_total > (SELECT AVG(valor_total) FROM OrdemServico)
ORDER BY OS.valor_total DESC;
