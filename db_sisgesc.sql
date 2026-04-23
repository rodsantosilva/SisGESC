CREATE TABLE tb_pessoa (
  pk_cpf char(11) PRIMARY KEY NOT NULL,
  nome varchar(50) NOT NULL,
  sobrenome varchar(50) NOT NULL,
  data_nasc date NOT NULL,
  sexo enum('Masculino','Feminino','Outros') NOT NULL DEFAULT 'Outros',
  CONSTRAINT chk_cpf_format CHECK (pk_cpf REGEXP '^[0-9]{11}$'),
  CONSTRAINT chk_data_nasc CHECK (data_nasc > '1920-01-01' AND data_nasc < CURRENT_DATE)
);

CREATE TABLE tb_tipo_afastamento (
  pk_cid_afastamento char(5) PRIMARY KEY
);

CREATE TABLE tb_contrato (
  pk_id_contrato int NOT NULL AUTO_INCREMENT,
  pk_tipo enum('CLT','Temporário','PJ','Estágio') NOT NULL DEFAULT 'CLT',
  status_contrato bool DEFAULT TRUE,
  pk_cargo varchar(32) NOT NULL,
  data_admissao date NOT NULL,
  fk_cpf char(11) NOT NULL,
  PRIMARY KEY (pk_id_contrato),
  FOREIGN KEY (fk_cpf) REFERENCES tb_pessoa (pk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_folha_pagamento (
  salario_base decimal(10,2) NOT NULL,
  salario_liquido decimal(10,2) NOT NULL,
  fk_id_contrato int NOT NULL,
  pk_mes_referencia date PRIMARY KEY,
  FOREIGN KEY (fk_id_contrato) REFERENCES tb_contrato (pk_id_contrato) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_coerencia_salarial CHECK (salario_base >= salario_liquido AND salario_liquido >= 0)
);

CREATE TABLE tb_beneficios (
  vale_transporte decimal(10,2) NOT NULL,
  vale_alimentacao decimal(10,2) NOT NULL,
  vale_refeicao decimal(10,2) NOT NULL,
  plano_saude decimal(10,2) NOT NULL,
  fk_id_contrato int NOT NULL,
  fk_mes_referencia date,
  PRIMARY KEY (fk_id_contrato, fk_mes_referencia),
  FOREIGN KEY (fk_id_contrato) REFERENCES tb_contrato (pk_id_contrato) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (fk_mes_referencia) REFERENCES tb_folha_pagamento (pk_mes_referencia) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE tb_descontos (
  inss decimal(10,2) NOT NULL,
  fgts decimal(10,2) NOT NULL,
  faltas decimal(10,2) NOT NULL,
  atrasos decimal(10,2) NOT NULL,
  fk_id_contrato int NOT NULL,
  fk_mes_referencia date,
  PRIMARY KEY (fk_id_contrato, fk_mes_referencia),
  FOREIGN KEY (fk_id_contrato) REFERENCES tb_contrato (pk_id_contrato) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (fk_mes_referencia) REFERENCES tb_folha_pagamento (pk_mes_referencia) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_descontos_validos CHECK (inss >= 0 AND fgts >= 0 AND faltas >= 0 AND atrasos >= 0)
);

CREATE TABLE tb_ponto (
  entrada time NOT NULL,
  saida time NOT NULL,
  horas_extras time NOT NULL,
  fk_id_contrato int NOT NULL,
  pk_dia_trabalhado date NOT NULL,
  PRIMARY KEY (fk_id_contrato, pk_dia_trabalhado),
  FOREIGN KEY (fk_id_contrato) REFERENCES tb_contrato (pk_id_contrato) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_fluxo_horario CHECK (saida > entrada)
);

CREATE TABLE tb_escala_trabalho (
  hora_inicio time NOT NULL,
  hora_fim time NOT NULL,
  dia_semana enum('Segunda','Terça','Quarta','Quinta','Sexta','Sábado','Domingo'),
  pk_turno enum('Matutino','Vespertino','Noturno') NOT NULL DEFAULT 'Matutino',
  fk_id_contrato int NOT NULL,
  PRIMARY KEY (pk_turno, fk_id_contrato),
  FOREIGN KEY (fk_id_contrato) REFERENCES tb_contrato (pk_id_contrato) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE tb_ferias (
  periodo_aquisitivo_inicio date NOT NULL,
  periodo_aquisitivo_fim date NOT NULL,
  periodo_gozo_inicio date NOT NULL,
  periodo_gozo_fim date NOT NULL,
  fk_id_contrato int NOT NULL,
  PRIMARY KEY (periodo_aquisitivo_inicio, fk_id_contrato),
  FOREIGN KEY (fk_id_contrato) REFERENCES tb_contrato (pk_id_contrato) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_periodo_gozo CHECK (periodo_gozo_fim >= periodo_gozo_inicio),
  CONSTRAINT chk_periodo_aquisitivo CHECK (periodo_aquisitivo_fim >= periodo_aquisitivo_inicio)
);

CREATE TABLE tb_afastamento (
  inicio_afastamento datetime NOT NULL,
  fim_afastamento date NOT NULL,
  fk_cid_afastamento char(5),
  fk_id_contrato int NOT NULL,
  PRIMARY KEY (inicio_afastamento, fk_id_contrato),
  FOREIGN KEY (fk_cid_afastamento) REFERENCES tb_tipo_afastamento (pk_cid_afastamento) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_id_contrato) REFERENCES tb_contrato (pk_id_contrato) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE tb_endereco (
  pk_cep char(8) NOT NULL,
  rua varchar(50) NOT NULL,
  pk_complemento varchar(50) NOT NULL,
  pk_numero int NOT NULL,
  bairro varchar(50) NOT NULL,
  cidade varchar(50) NOT NULL,
  estado varchar(50) NOT NULL,
  fk_cpf char(11) NOT NULL,
  fk_cnpj char(14) NOT NULL,
  PRIMARY KEY (pk_cep, pk_complemento, pk_numero),
  CONSTRAINT chk_cep_format CHECK (pk_cep REGEXP '^[0-9]{8}$'),
  FOREIGN KEY (fk_cpf) REFERENCES tb_pessoa (pk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_cnpj) REFERENCES tb_empresas (pk_cnpj) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_email (
  pk_email varchar(100) NOT NULL,
  fk_cpf char(11),
  fk_cnpj char(14),
  PRIMARY KEY (pk_email),
  FOREIGN KEY (fk_cpf) REFERENCES tb_pessoa (pk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_cnpj) REFERENCES tb_empresas (pk_cnpj) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_email_format CHECK (pk_email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[[A-Za-z]]{2,}$')
);

CREATE TABLE tb_telefone (
  pk_ddd int NOT NULL,
  pk_numero char(9) NOT NULL,
  tipo enum('Residencial','Celular') NOT NULL DEFAULT 'Celular',
  ativo bool NOT NULL,
  fk_cpf char(11) NOT NULL,
  fk_cnpj char(14) NOT NULL,
  PRIMARY KEY (pk_ddd, pk_numero),
  FOREIGN KEY (fk_cpf) REFERENCES tb_pessoa (pk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_cnpj) REFERENCES tb_empresas (pk_cnpj) ON UPDATE CASCADE ON DELETE RESTRICT
);

DELIMITER //
CREATE TRIGGER tg_bloquear_pgto_contrato_inativo
BEFORE INSERT ON tb_folha_pagamento
FOR EACH ROW
BEGIN
    DECLARE v_status BOOLEAN;
    SELECT status_contrato INTO v_status FROM tb_contrato WHERE pk_id_contrato = NEW.fk_id_contrato;
    IF v_status = FALSE THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Erro: Não é possível gerar folha para contrato inativo.';
    END IF;
END; //
DELIMITER ;

CREATE TABLE tb_empresas (
  pk_cnpj char(14) PRIMARY KEY NOT NULL,
  razao_social varchar(100) NOT NULL,
  data_criacao date NOT NULL,
  categoria_servico varchar(200) DEFAULT 'Outros'
);

CREATE TABLE tb_tesouraria (
  pk_id_transacao int NOT NULL AUTO_INCREMENT,
  pk_data_movimentacao datetime NOT NULL,
  saldo decimal(12,2) NOT NULL CHECK (saldo >= 0),
  saida decimal(12,2) CHECK (saida >= 0) DEFAULT 0,
  entrada decimal(12,2) CHECK (entrada >= 0) DEFAULT 0,
  descricao_movimentacao text,
  PRIMARY KEY (pk_id_transacao, pk_data_movimentacao),
  CONSTRAINT chk_movimentacao CHECK (saida >= 0 AND entrada >= 0)
);

CREATE TABLE tb_contas_a_pagar (
  pk_nf varchar(50) NOT NULL,
  descricao text,
  valor decimal(10,2) NOT NULL CHECK (valor >= 0) DEFAULT 0,
  data_vencimento date NOT NULL,
  parcelas varchar(2),
  fk_id_transacao int NOT NULL AUTO_INCREMENT,
  fk_data_movimentacao datetime NOT NULL,
  fk_cnpj char(14) NOT NULL,
  PRIMARY KEY (pk_nf, fk_cnpj),
  FOREIGN KEY (fk_id_transacao) REFERENCES tb_tesouraria (pk_id_transacao) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_data_movimentacao) REFERENCES tb_tesouraria (pk_data_movimentacao) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_cnpj) REFERENCES tb_empresas (pk_cnpj) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_contas_a_receber (
  pk_danfe blob NOT NULL,
  valor_a_receber decimal(10,2) NOT NULL CHECK (valor_a_receber >= 0) DEFAULT 0,
  data_recebimento date NOT NULL,
  status_pagamento enum('Aberto','Pago','Inadimplente') NOT NULL DEFAULT 'Aberto',
  porcentagem_juros decimal(5,2),
  fk_id_transacao int NOT NULL AUTO_INCREMENT,
  fk_data_movimentacao datetime NOT NULL,
  fk_cnpj char(14) NOT NULL,
  PRIMARY KEY (pk_danfe, fk_cnpj),
  FOREIGN KEY (fk_id_transacao) REFERENCES tb_tesouraria (pk_id_transacao) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_data_movimentacao) REFERENCES tb_tesouraria (pk_data_movimentacao) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_cnpj) REFERENCES tb_empresas (pk_cnpj) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_mensalidades (
  fk_ra int NOT NULL,
  valor_completo decimal(10,2) NOT NULL,
  valor_final decimal(10,2) NOT NULL,
  pk_vencimento date NOT NULL,
  pk_danfe_mensalidade varchar(50) NOT NULL,
  parcela_numero tinyint,
  status_recebimento enum('Aberto','Pago','Inadimplente') NOT NULL DEFAULT 'Aberto',
  fk_id_transacao int NOT NULL AUTO_INCREMENT,
  fk_data_movimentacao datetime NOT NULL,
  PRIMARY KEY (fk_ra, pk_vencimento, pk_danfe_mensalidade),
  FOREIGN KEY (fk_id_transacao) REFERENCES tb_tesouraria (pk_id_transacao) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_data_movimentacao) REFERENCES tb_tesouraria (pk_data_movimentacao) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_desconto_mensalidade CHECK (valor_final <= valor_completo AND valor_final >= 0),
  CONSTRAINT chk_parcela_limite CHECK (parcela_numero BETWEEN 1 AND 12)
);

CREATE TABLE tb_conta_bancaria (
  pk_agencia char(4) NOT NULL,
  pk_conta char(6) NOT NULL,
  fk_cnpj char(14) NOT NULL,
  fk_id_transacao int NOT NULL AUTO_INCREMENT,
  fk_data_movimentacao datetime NOT NULL,
  PRIMARY KEY (pk_agencia, pk_conta, fk_cnpj),
  FOREIGN KEY (fk_cnpj) REFERENCES tb_empresas (pk_cnpj) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_id_transacao) REFERENCES tb_tesouraria (pk_id_transacao) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (fk_data_movimentacao) REFERENCES tb_tesouraria (pk_data_movimentacao) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_pagamento_salario (
    fk_id_contrato int NOT NULL,
    fk_cpf char(11) NOT NULL,
    pk_mes_referencia date NOT NULL,
    data_emissao_holerite timestamp DEFAULT CURRENT_TIMESTAMP,
    valor_bruto decimal(10,2) NOT NULL,
    valor_liquido_pago decimal(10,2) NOT NULL,
    status_pagamento enum('Pendente', 'Pago', 'Estornado') DEFAULT 'Pendente',
    fk_id_transacao int,
    fk_data_movimentacao datetime,
    PRIMARY KEY (fk_id_contrato, pk_mes_referencia),
    FOREIGN KEY (fk_id_contrato) REFERENCES tb_contrato(pk_id_contrato) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_id_transacao, fk_data_movimentacao) REFERENCES tb_tesouraria(pk_id_transacao, pk_data_movimentacao) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_matricula (
	pk_ra int NOT NULL AUTO_INCREMENT UNIQUE,
    fk_cpf char(11) NOT NULL,
    data_matricula date NOT NULL,
    status_matricula enum('Ativa','Trancada','Cancelada','Concluída') NOT NULL,
    PRIMARY KEY (pk_ra),
    FOREIGN KEY (fk_cpf) REFERENCES tb_pessoa (pk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_data_matricula CHECK (data_matricula >= '2000-01-01')
);

CREATE TABLE tb_professor (
	fk_cpf char(11) NOT NULL,
    fk_id_contrato int NOT NULL,
    area_formacao varchar(50),
    biografia_resumida text,
    PRIMARY KEY (fk_cpf),
    FOREIGN KEY (fk_cpf) REFERENCES tb_pessoa (pk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_id_contrato) REFERENCES tb_contrato (pk_id_contrato) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE tb_disciplina (
	pk_codigo_disciplina varchar(5) NOT NULL,
    nome_disciplina varchar(50),
    ementa text,
    PRIMARY KEY (pk_codigo_disciplina)
);

CREATE TABLE tb_frequencia (
    fk_ra int NOT NULL,
    pk_data_aula date NOT NULL,
    pk_horario_inicio time NOT NULL,
    presenca bool,
    justificativa text,
    PRIMARY KEY (fk_ra, pk_data_aula, pk_horario_inicio),
    FOREIGN KEY (fk_ra) REFERENCES tb_matricula(pk_ra) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_turmas(
	fk_codigo_disciplina varchar(5) NOT NULL,
    fk_cpf_professor char(11) NOT NULL,
    pk_ano_letivo date NOT NULL,
    pk_sigla_turma char(2) NOT NULL,
    PRIMARY KEY (pk_sigla_turma, pk_ano_letivo),
    FOREIGN KEY (fk_codigo_disciplina) REFERENCES tb_disciplina(pk_codigo_disciplina) ON UPDATE CASCADE,
    FOREIGN KEY (fk_cpf_professor) REFERENCES tb_professor(fk_cpf) ON UPDATE CASCADE
);

CREATE TABLE tb_avaliacao(
	pk_data_avaliacao date NOT NULL,
    tipo enum('Prova','Trabalho'),
    pk_bimestre enum('1º','2º','3º','4º') NOT NULL,
	fk_sigla_turma varchar(5) NOT NULL,
    PRIMARY KEY (pk_data_avaliacao, pk_bimestre, fk_sigla_turma),
    FOREIGN KEY (fk_sigla_turma) REFERENCES tb_turmas(pk_sigla_turma) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_notas (
    fk_ra int NOT NULL,
    fk_codigo_disciplina varchar(5) NOT NULL,
    fk_bimestre enum('1º','2º','3º','4º') NOT NULL,
    fk_data_avaliacao date NOT NULL,
    fk_sigla_turma varchar(5) NOT NULL,
    valor_nota decimal(4,2) NOT NULL,
    data_lancamento timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fk_ra, fk_codigo_disciplina, fk_bimestre, fk_data_avaliacao),
    FOREIGN KEY (fk_ra) REFERENCES tb_matricula(pk_ra) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_codigo_disciplina) REFERENCES tb_disciplina(pk_codigo_disciplina) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_data_avaliacao, fk_bimestre, fk_sigla_turma) REFERENCES tb_avaliacao(pk_data_avaliacao, pk_bimestre, fk_sigla_turma) 
        ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT chk_valor_nota CHECK (valor_nota >= 0 AND valor_nota <= 10)
);

CREATE TABLE tb_aluno_turma (
    fk_ra INT NOT NULL,
    fk_sigla_turma VARCHAR(2) NOT NULL,
    fk_ano_letivo date NOT NULL,
    data_entrada DATE NOT NULL,
    situacao_aluno ENUM('Ativo', 'Transferido', 'Ouvinte') DEFAULT 'Ativo',
    PRIMARY KEY (fk_ra, fk_sigla_turma, fk_ano_letivo),
	FOREIGN KEY (fk_ra) REFERENCES tb_matricula(pk_ra) ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY (fk_sigla_turma, fk_ano_letivo) REFERENCES tb_turmas(pk_sigla_turma, pk_ano_letivo) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_grade_horaria(
	horario_inicio time,
    ano_letivo date,
    dia_aula enum('Segunda','Terça','Quarta','Quinta','Sexta'),
	fk_ra int NOT NULL,
    FOREIGN KEY (fk_ra) REFERENCES tb_matricula(pk_ra) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_responsavel(
	fk_cpf char(11) NOT NULL,
    pode_retirar_aluno bool DEFAULT true,
    PRIMARY KEY (fk_cpf),
    FOREIGN KEY (fk_cpf) REFERENCES tb_pessoa (pk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_aluno_responsavel(
    fk_cpf_aluno char(11) NOT NULL,
    fk_cpf_responsavel char(11) NOT NULL,
    PRIMARY KEY (fk_cpf_responsavel, fk_cpf_aluno),
    FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_pessoa (pk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_cpf_responsavel) REFERENCES tb_responsavel (fk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE tb_ocorrencia_disciplinar (
    fk_ra INT NOT NULL,
    pk_data_ocorrencia DATE NOT NULL,
    pk_hora_ocorrencia TIME NOT NULL,
    tipo_ocorrencia ENUM('Advertência', 'Suspensão') NOT NULL,
    fk_cpf_emissor CHAR(11) NOT NULL,
    descricao_motivo TEXT NOT NULL,
    data_inicio_suspensao DATE NULL,
    data_fim_suspensao DATE NULL,
    PRIMARY KEY (fk_ra, pk_data_ocorrencia, pk_hora_ocorrencia),
	FOREIGN KEY (fk_ra) REFERENCES tb_matricula (pk_ra) ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY (fk_cpf_emissor) REFERENCES tb_pessoa (pk_cpf) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_periodo_suspensao CHECK (data_fim_suspensao >= data_inicio_suspensao)
);

DELIMITER //
CREATE TRIGGER tg_validar_aluno_na_turma
BEFORE INSERT ON tb_notas
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM tb_aluno_turma 
        WHERE fk_ra = NEW.fk_ra 
        AND fk_sigla_turma = NEW.fk_sigla_turma
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Erro: O aluno não está matriculado nesta turma.';
    END IF;
END; //
DELIMITER ;
