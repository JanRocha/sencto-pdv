program SanctoPDV_Backoffice;

uses
  System.StartUpCopy,
  System.SysUtils,
  FMX.Forms,
  FMX.Dialogs,
  Frm.Login in '..\Shared\Forms\Frm.Login.pas' {FrmLogin},
  Frm.Main.Backoffice in 'Forms\Frm.Main.Backoffice.pas' {FrmMainBackoffice},
  Frm.Produtos in 'Forms\Frm.Produtos.pas' {FrmProdutos: TFrame},
  Frm.Colaboradores in 'Forms\Frm.Colaboradores.pas' {FrmColaboradores: TFrame},
  Frm.PacotesFesta in 'Forms\Frm.PacotesFesta.pas' {FrmPacotesFesta};

{$R *.res}

var
  LFrmLogin: TFrmLogin;
  LFrmMainBackoffice: TFrmMainBackoffice;

begin
  Application.Initialize;

  // Exibir tela de login primeiro
  LFrmLogin := TFrmLogin.Create(Application);
  try
    LFrmLogin.ShowModal;

    if LFrmLogin.ModalResult = mrOk then
    begin
      // Verificar se o papel permite acesso ao Backoffice (req 1.8)
      // Apenas ADMINISTRADOR e GERENTE podem acessar
      if SameText(LFrmLogin.ColaboradorLogadoPapel, 'OPERACIONAL') then
      begin
        ShowMessage('Acesso negado. Permiss' + Char($00E3) + 'o insuficiente para o Backoffice.' + sLineBreak +
          'Apenas Administradores e Gerentes podem acessar este m' + Char($00F3) + 'dulo.');
        Application.Terminate;
      end
      else
      begin
        // Login bem-sucedido com papel adequado: criar tela principal
        LFrmMainBackoffice := TFrmMainBackoffice.Create(Application,
          LFrmLogin.ColaboradorLogadoId,
          LFrmLogin.ColaboradorLogadoNome,
          LFrmLogin.ColaboradorLogadoPapel);
        LFrmMainBackoffice.Show;

        Application.Run;
      end;
    end
    else
    begin
      // Login cancelado: encerrar aplicação
      Application.Terminate;
    end;
  finally
    LFrmLogin.Free;
  end;
end.
