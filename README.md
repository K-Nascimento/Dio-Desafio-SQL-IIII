# Modelagem Lógica: Oficina Mecânica – Controle de Ordens de Serviço

## Contexto de Negócio
Sistema para gerenciamento de ordens de serviço (OS) em uma oficina mecânica.  
Principais requisitos:

- Clientes possuem veículos que são levados para conserto ou revisão periódica.
- Cada veículo é atribuído a uma **equipe de mecânicos** (especialidade coletiva).
- A equipe identifica os serviços e peças necessários e preenche uma OS com data de entrega prevista.
- O valor da OS é composto por:
  - **Mão de obra** – baseada numa tabela de referência de serviços.
  - **Peças** – valores unitários conforme cadastro.
- O cliente deve autorizar a execução antes do início dos trabalhos.
- A mesma equipe que avaliou executa os serviços.
- Mecânicos possuem código, nome, endereço e especialidade individual.
- Cada OS possui: número, data de emissão, valor total, status e data de conclusão prevista.

## Estrutura do Esquema (Diagrama Relacional)

```mermaid
erDiagram
    CLIENTE {
        int id_cliente PK
        string nome
        string telefone
        string email
        string endereco
    }
    VEICULO {
        int id_veiculo PK
        string placa UK
        string modelo
        string marca
        int ano
        int id_cliente FK
    }
    EQUIPE {
        int id_equipe PK
        string nome_equipe
    }
    MECANICO {
        int id_mecanico PK
        string codigo UK
        string nome
        string endereco
        string especialidade
        int id_equipe FK
    }
    SERVICO {
        int id_servico PK
        string descricao
        decimal valor_mao_obra
    }
    PECA {
        int id_peca PK
        string nome
        string referencia
        decimal valor_unitario
    }
    ORDEM_SERVICO {
        int id_os PK
        string numero_os UK
        datetime data_emissao
        datetime data_conclusao_prevista
        enum status_os
        boolean autorizado
        decimal valor_total
        int id_veiculo FK
        int id_equipe FK
    }
    OS_SERVICO {
        int id_os FK
        int id_servico FK
        int quantidade
        decimal valor_unitario
        decimal subtotal
    }
    OS_PECA {
        int id_os FK
        int id_peca FK
        int quantidade
        decimal valor_unitario
        decimal subtotal
    }

    CLIENTE ||--o{ VEICULO : possui
    VEICULO ||--o{ ORDEM_SERVICO : gera
    EQUIPE ||--o{ MECANICO : compoe
    EQUIPE ||--o{ ORDEM_SERVICO : executa
    ORDEM_SERVICO ||--o{ OS_SERVICO : inclui
    SERVICO ||--o{ OS_SERVICO : referenciado
    ORDEM_SERVICO ||--o{ OS_PECA : utiliza
    PECA ||--o{ OS_PECA : referenciada
