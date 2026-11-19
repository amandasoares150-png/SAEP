CREATE TABLE colaboradores (
    id_colaborador INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE categorias (
    id_categoria INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    nome VARCHAR(150) NOT NULL UNIQUE,
    descricao VARCHAR(1000) NOT NULL
);

CREATE TABLE tarefas (
    id_tarefa INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    titulo VARCHAR(150) NOT NULL UNIQUE,
    descricao VARCHAR(1000) NOT NULL,
    id_categoria INTEGER NOT NULL,
    id_colaborador INTEGER NOT NULL,
    data_agendamento DATE NOT NULL,
    prazo_entrega DATE NOT NULL,
    status VARCHAR(30) NOT NULL,
    data_criacao TIMESTAMP NOT NULL,

    FOREIGN KEY (id_categoria)
        REFERENCES categorias(id_categoria),

    FOREIGN KEY (id_colaborador)
        REFERENCES colaboradores(id_colaborador),

    CHECK (status IN ('pendente', 'em andamento', 'concluida', 'cancelada')),

    CHECK (prazo_entrega >= data_agendamento)
);

CREATE TABLE historico_tarefas (
    id_historico INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    id_tarefa INTEGER NOT NULL,
    acao VARCHAR(100) NOT NULL,
    detalhes VARCHAR(150) NOT NULL,
    data_registro TIMESTAMP NOT NULL,

    FOREIGN KEY (id_tarefa)
        REFERENCES tarefas(id_tarefa)
        ON DELETE CASCADE
);
SELECT * FROM historico_tarefas

INSERT INTO colaboradores (nome, email, senha, ativo) VALUES
('Amanda Moretti', 'amanda@empresa.com', '123456', TRUE),
('Felipe Couto', 'felipe.couto@empresa.com', '674321', TRUE),
('Laura Soares', 'laura@empresa.com', '987654', FALSE);
SELECT * FROM colaboradores

INSERT INTO categorias (nome, descricao) VALUES
('Planejamento', 'Organização das etapas do projeto'),
('Desenvolvimento', 'Executar as atividades que foram organizadas para o projeto'),
('Reunião', 'Encontros para acompanhar o andamento da equipe na criação do projeto');
SELECT * FROM categorias

CREATE OR REPLACE FUNCTION fn_validar_tarefa()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM colaboradores
        WHERE id_colaborador = NEW.id_colaborador
        AND ativo = TRUE
    ) THEN
        RAISE EXCEPTION 'Colaborador inexistente ou inativo!';
    END IF;

    NEW.data_criacao := CURRENT_TIMESTAMP;

    RETURN NEW;

END;
$$;

CREATE TRIGGER trg_validar_tarefa
BEFORE INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_tarefa();

CREATE OR REPLACE FUNCTION fn_registrar_historico()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

INSERT INTO historico_tarefas (
id_tarefa,
acao,
detalhes,
data_registro
)
    
VALUES 
(NEW.id_tarefa, 'Criação','Tarefa cadastrada no sistema', CURRENT_TIMESTAMP);

RETURN NEW;

END;
$$;

CREATE TRIGGER trg_registrar_historico
AFTER INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico();

INSERT INTO tarefas (
titulo,
descricao,
id_categoria,
id_colaborador,
data_agendamento,
prazo_entrega,
status
)
VALUES
('Definir escopo','Definir os objetivos do projeto',1, 1, CURRENT_DATE, CURRENT_DATE + 3, 'em andamento'),
('Desenvolver protótipo','Criar a primeira versão do projeto',2, 2, CURRENT_DATE + 1, CURRENT_DATE + 7, 'pendente'),
('Reunião de acompanhamento','Verificar o andamento das atividades', 3, 1, CURRENT_DATE + 2, CURRENT_DATE + 2, 'pendente');
SELECT * FROM tarefas

CREATE OR REPLACE FUNCTION fn_buscar_colaboradores(termo_busca TEXT)
RETURNS TABLE (
    id_colaborador INTEGER,
    nome VARCHAR(100),
    email VARCHAR(150),
    ativo BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
        c.id_colaborador,
        c.nome,
        c.email,
        c.ativo
    FROM colaboradores c
    WHERE c.nome ILIKE '%' || termo_busca || '%'
       OR c.email ILIKE '%' || termo_busca || '%';

END;
$$;

CREATE OR REPLACE VIEW vw_painel_principal AS
SELECT
    c.nome AS nome_colaborador,
    t.titulo AS titulo_tarefa,
    cat.nome AS categoria,
    t.prazo_entrega,
    t.status

FROM tarefas t

INNER JOIN colaboradores c
    ON t.id_colaborador = c.id_colaborador

INNER JOIN categorias cat
    ON t.id_categoria = cat.id_categoria;

CREATE OR REPLACE VIEW vw_cronograma_prazos AS
SELECT
    t.id_tarefa,
    t.titulo,
    t.data_agendamento,
    t.prazo_entrega,
    t.status,
    (t.prazo_entrega - CURRENT_DATE) AS dias_restantes,
    c.nome AS responsavel

FROM tarefas t

INNER JOIN colaboradores c
    ON t.id_colaborador = c.id_colaborador

ORDER BY
    t.prazo_entrega ASC,
    t.data_agendamento ASC;