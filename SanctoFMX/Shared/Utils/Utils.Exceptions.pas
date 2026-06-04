unit Utils.Exceptions;

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Exceção base para todas as exceções do sistema Sancto PDV.
  /// Todas as exceções customizadas herdam desta classe.
  /// </summary>
  ESanctoPDVException = class(Exception)
  public
    constructor Create(const AMsg: string); reintroduce;
  end;

  /// <summary>
  /// Exceção lançada quando uma validação de dados de entrada falha.
  /// Exemplo: CPF inválido, campo obrigatório vazio, formato incorreto.
  /// </summary>
  EValidacaoException = class(ESanctoPDVException)
  private
    FCampo: string;
  public
    constructor Create(const AMsg: string); reintroduce; overload;
    constructor Create(const ACampo, AMsg: string); reintroduce; overload;
    property Campo: string read FCampo;
  end;

  /// <summary>
  /// Exceção lançada em falhas de autenticação.
  /// Exemplo: credenciais inválidas, conta bloqueada, sessão expirada.
  /// </summary>
  EAutenticacaoException = class(ESanctoPDVException)
  public
    constructor Create(const AMsg: string); reintroduce;
  end;

  /// <summary>
  /// Exceção lançada quando o colaborador não possui permissão para a ação.
  /// Exemplo: operacional tentando acessar backoffice.
  /// </summary>
  EPermissaoException = class(ESanctoPDVException)
  private
    FPapelRequerido: string;
  public
    constructor Create(const AMsg: string); reintroduce; overload;
    constructor Create(const AMsg, APapelRequerido: string); reintroduce; overload;
    property PapelRequerido: string read FPapelRequerido;
  end;

  /// <summary>
  /// Exceção lançada em operações inválidas de caixa.
  /// Exemplo: sangria maior que saldo, caixa não aberto, abertura duplicada.
  /// </summary>
  ECaixaException = class(ESanctoPDVException)
  public
    constructor Create(const AMsg: string); reintroduce;
  end;

  /// <summary>
  /// Exceção lançada em problemas de estoque.
  /// Exemplo: estoque insuficiente para venda, estoque abaixo do mínimo.
  /// </summary>
  EEstoqueException = class(ESanctoPDVException)
  private
    FProdutoNome: string;
    FEstoqueDisponivel: Integer;
  public
    constructor Create(const AMsg: string); reintroduce; overload;
    constructor Create(const AMsg, AProdutoNome: string; AEstoqueDisponivel: Integer); reintroduce; overload;
    property ProdutoNome: string read FProdutoNome;
    property EstoqueDisponivel: Integer read FEstoqueDisponivel;
  end;

  /// <summary>
  /// Exceção lançada em falhas de operações fiscais.
  /// Exemplo: certificado expirado, falha na SEFAZ, cancelamento fora do prazo.
  /// </summary>
  EFiscalException = class(ESanctoPDVException)
  private
    FCodigoErro: string;
  public
    constructor Create(const AMsg: string); reintroduce; overload;
    constructor Create(const AMsg, ACodigoErro: string); reintroduce; overload;
    property CodigoErro: string read FCodigoErro;
  end;

  /// <summary>
  /// Exceção lançada em falhas de conexão com banco de dados ou serviços externos.
  /// Exemplo: Firebird indisponível, timeout de API, falha de rede.
  /// </summary>
  EConexaoException = class(ESanctoPDVException)
  private
    FServico: string;
  public
    constructor Create(const AMsg: string); reintroduce; overload;
    constructor Create(const AMsg, AServico: string); reintroduce; overload;
    property Servico: string read FServico;
  end;

implementation

{ ESanctoPDVException }

constructor ESanctoPDVException.Create(const AMsg: string);
begin
  inherited Create(AMsg);
end;

{ EValidacaoException }

constructor EValidacaoException.Create(const AMsg: string);
begin
  inherited Create(AMsg);
  FCampo := '';
end;

constructor EValidacaoException.Create(const ACampo, AMsg: string);
begin
  inherited Create(AMsg);
  FCampo := ACampo;
end;

{ EAutenticacaoException }

constructor EAutenticacaoException.Create(const AMsg: string);
begin
  inherited Create(AMsg);
end;

{ EPermissaoException }

constructor EPermissaoException.Create(const AMsg: string);
begin
  inherited Create(AMsg);
  FPapelRequerido := '';
end;

constructor EPermissaoException.Create(const AMsg, APapelRequerido: string);
begin
  inherited Create(AMsg);
  FPapelRequerido := APapelRequerido;
end;

{ ECaixaException }

constructor ECaixaException.Create(const AMsg: string);
begin
  inherited Create(AMsg);
end;

{ EEstoqueException }

constructor EEstoqueException.Create(const AMsg: string);
begin
  inherited Create(AMsg);
  FProdutoNome := '';
  FEstoqueDisponivel := 0;
end;

constructor EEstoqueException.Create(const AMsg, AProdutoNome: string; AEstoqueDisponivel: Integer);
begin
  inherited Create(AMsg);
  FProdutoNome := AProdutoNome;
  FEstoqueDisponivel := AEstoqueDisponivel;
end;

{ EFiscalException }

constructor EFiscalException.Create(const AMsg: string);
begin
  inherited Create(AMsg);
  FCodigoErro := '';
end;

constructor EFiscalException.Create(const AMsg, ACodigoErro: string);
begin
  inherited Create(AMsg);
  FCodigoErro := ACodigoErro;
end;

{ EConexaoException }

constructor EConexaoException.Create(const AMsg: string);
begin
  inherited Create(AMsg);
  FServico := '';
end;

constructor EConexaoException.Create(const AMsg, AServico: string);
begin
  inherited Create(AMsg);
  FServico := AServico;
end;

end.
