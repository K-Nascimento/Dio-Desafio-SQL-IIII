
---

## 2. script.sql

```sql
-- =================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS (DDL) 
-- E CARGA DE DADOS DE TESTE (DML)
-- OFICINA MECÂNICA
-- =================================================================

DROP DATABASE IF EXISTS oficina_mecanica;
CREATE DATABASE oficina_mecanica;
USE oficina_mecanica;

-- -----------------------------------------------------------------
-- 1. TABELAS DE CADASTRO
-- -----------------------------------------------------------------
CREATE TABLE Cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    endereco VARCHAR(200)
) ENGINE=InnoDB;

CREATE TABLE Veiculo (
    id_veiculo INT AUTO_INCREMENT PRIMARY KEY,
    placa VARCHAR(10) NOT NULL UNIQUE,
    modelo VARCHAR(50) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    ano INT,
    id_cliente INT NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE Equipe (
    id_equipe INT AUTO_INCREMENT PRIMARY KEY,
    nome_equipe VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE Mecanico (
    id_mecanico INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    endereco VARCHAR(200),
    especialidade VARCHAR(100),
    id_equipe INT NOT NULL,
    FOREIGN KEY (id_equipe) REFERENCES Equipe(id_equipe) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE Servico (
    id_servico INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL,
    valor_mao_obra DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Peca (
    id_peca INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    referencia VARCHAR(50) UNIQUE,
    valor_unitario DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------------------
-- 2. TABELAS TRANSACIONAIS (ORDENS DE SERVIÇO)
-- -----------------------------------------------------------------
CREATE TABLE OrdemServico (
    id_os INT AUTO_INCREMENT PRIMARY KEY,
    numero_os VARCHAR(20) NOT NULL UNIQUE,
    data_emissao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_conclusao_prevista DATE NOT NULL,
    status_os ENUM('Em aberto', 'Autorizado', 'Em execução', 'Concluído', 'Cancelado') DEFAULT 'Em aberto',
    autorizado BOOLEAN DEFAULT FALSE,
    valor_total DECIMAL(10,2) DEFAULT 0.00,
    id_veiculo INT NOT NULL,
    id_equipe INT NOT NULL,
    FOREIGN KEY (id_veiculo) REFERENCES Veiculo(id_veiculo) ON DELETE RESTRICT,
    FOREIGN KEY (id_equipe) REFERENCES Equipe(id_equipe) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Itens de serviço da OS
CREATE TABLE OS_Servico (
    id_os INT NOT NULL,
    id_servico INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    valor_unitario DECIMAL(10,2) NOT NULL,   -- pode ser o valor da tabela de referência ou customizado
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (quantidade * valor_unitario) STORED,
    PRIMARY KEY (id_os, id_servico),
    FOREIGN KEY (id_os) REFERENCES OrdemServico(id_os) ON DELETE CASCADE,
    FOREIGN KEY (id_servico) REFERENCES Servico(id_servico) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Itens de peça da OS
CREATE TABLE OS_Peca (
    id_os INT NOT NULL,
    id_peca INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    valor_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (quantidade * valor_unitario) STORED,
    PRIMARY KEY (id_os, id_peca),
    FOREIGN KEY (id_os) REFERENCES OrdemServico(id_os) ON DELETE CASCADE,
    FOREIGN KEY (id_peca) REFERENCES Peca(id_peca) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------------------
-- 3. TRIGGERS PARA ATUALIZAÇÃO DO VALOR TOTAL DA OS
-- -----------------------------------------------------------------
DELIMITER $$

CREATE TRIGGER tg_atualiza_total_os_servico
AFTER INSERT ON OS_Servico
FOR EACH ROW
BEGIN
    UPDATE OrdemServico OS
    SET valor_total = (
        IFNULL((SELECT SUM(subtotal) FROM OS_Servico WHERE id_os = NEW.id_os), 0) +
        IFNULL((SELECT SUM(subtotal) FROM OS_Peca WHERE id_os = NEW.id_os), 0)
    )
    WHERE OS.id_os = NEW.id_os;
END$$

CREATE TRIGGER tg_atualiza_total_os_peca
AFTER INSERT ON OS_Peca
FOR EACH ROW
BEGIN
    UPDATE OrdemServico OS
    SET valor_total = (
        IFNULL((SELECT SUM(subtotal) FROM OS_Servico WHERE id_os = NEW.id_os), 0) +
        IFNULL((SELECT SUM(subtotal) FROM OS_Peca WHERE id_os = NEW.id_os), 0)
    )
    WHERE OS.id_os = NEW.id_os;
END$$

DELIMITER ;

-- -----------------------------------------------------------------
-- 4. CARGA DE DADOS (MASSA DE TESTE)
-- -----------------------------------------------------------------
-- Clientes
INSERT INTO Cliente (nome, telefone, email, endereco) VALUES
('João da Silva', '(11) 99999-1111', 'joao@email.com', 'Rua A, 123 - SP'),
('Maria Souza', '(21) 98888-2222', 'maria@email.com', 'Av. B, 456 - RJ');

-- Veículos
INSERT INTO Veiculo (placa, modelo, marca, ano, id_cliente) VALUES
('ABC-1234', 'Civic', 'Honda', 2020, 1),
('XYZ-9876', 'Corolla', 'Toyota', 2019, 2);

-- Equipes
INSERT INTO Equipe (nome_equipe) VALUES ('Elétrica'), ('Motor'), ('Suspensão');

-- Mecânicos
INSERT INTO Mecanico (codigo, nome, endereco, especialidade, id_equipe) VALUES
('M001', 'Carlos Alberto', 'Rua dos Mecânicos, 10', 'Elétrica automotiva', 1),
('M002', 'Roberto Lima', 'Av. das Oficinas, 200', 'Injeção eletrônica', 1),
('M003', 'José Aparecido', 'Rua B, 321', 'Motor a combustão', 2),
('M004', 'Fernando Mendes', 'Praça Central, 55', 'Suspensão e direção', 3);

-- Tabela de referência de serviços (mão de obra)
INSERT INTO Servico (descricao, valor_mao_obra) VALUES
('Troca de óleo', 80.00),
('Revisão completa', 350.00),
('Reparo no motor', 1200.00),
('Alinhamento e balanceamento', 150.00),
('Diagnóstico elétrico', 200.00);

-- Peças
INSERT INTO Peca (nome, referencia, valor_unitario) VALUES
('Filtro de óleo', 'FO-123', 45.00),
('Óleo 5W30 (1L)', 'OIL-5W30', 35.00),
('Correia dentada', 'CD-789', 120.00),
('Pastilha de freio', 'PF-456', 180.00);

-- Ordens de Serviço
INSERT INTO OrdemServico (numero_os, data_conclusao_prevista, autorizado, status_os, id_veiculo, id_equipe) VALUES
('OS-001', '2025-06-28', TRUE, 'Em execução', 1, 2),   -- veículo do João, equipe Motor
('OS-002', '2025-06-30', FALSE, 'Em aberto', 2, 1);    -- veículo da Maria, equipe Elétrica

-- Itens de serviço para OS-001
INSERT INTO OS_Servico (id_os, id_servico, quantidade, valor_unitario) VALUES
(1, 3, 1, 1200.00),   -- Reparo no motor (preço tabela)
(1, 1, 1, 80.00);     -- Troca de óleo

-- Itens de peça para OS-001
INSERT INTO OS_Peca (id_os, id_peca, quantidade, valor_unitario) VALUES
(1, 3, 2, 120.00),    -- 2 correias dentadas
(1, 1, 1, 45.00);     -- filtro de óleo

-- Itens de serviço para OS-002 (ainda não autorizada)
INSERT INTO OS_Servico (id_os, id_servico, quantidade, valor_unitario) VALUES
(2, 5, 1, 200.00);    -- diagnóstico elétrico

-- (Nenhuma peça para OS-002 ainda)

-- Após os inserts, as triggers atualizam automaticamente o valor_total das OS.
-- Para verificar:
-- SELECT * FROM OrdemServico;
