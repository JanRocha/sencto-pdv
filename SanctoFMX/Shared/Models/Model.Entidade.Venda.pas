unit Model.Entidade.Venda;

interface

uses
  System.SysUtils,
  Rtti.Atributos;

type
  [Tabela('VENDA')]
  TVenda = class
  private
    FId: Integer;
    FCaixa_Id: Integer;
    FColaborador_Id: Integer;
    FSubtotal: Currency;
    FDesconto: Currency;
    FTotal: Currency;
    FForma_Pagamento: string;
    FParcelas: Integer;
    FCPF_Cliente: string;
    FStatus: string;
    FData_Hora: TDateTime;
  public
    constructor Create;
  published
    [Pk][AutoInc('GEN_VENDA_ID')]
    property Id: Integer read FId write FId;
    [Fk]
    property Caixa_Id: Integer read FCaixa_Id write FCaixa_Id;
    [Fk]
    property Colaborador_Id: Integer read FColaborador_Id write FColaborador_Id;
    property Subtotal: Currency read FSubtotal write FSubtotal;
    property Desconto: Currency read FDesconto write FDesconto;
    property Total: Currency read FTotal write FTotal;
    property Forma_Pagamento: string read FForma_Pagamento write FForma_Pagamento;
    property Parcelas: Integer read FParcelas write FParcelas;
    property CPF_Cliente: string read FCPF_Cliente write FCPF_Cliente;
    property Status: string read FStatus write FStatus;
    property Data_Hora: TDateTime read FData_Hora write FData_Hora;
  end;

implementation

{ TVenda }

constructor TVenda.Create;
begin
  inherited Create;
  FParcelas := 1;
  FStatus := 'ABERTA';
end;

end.
