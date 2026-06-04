unit Utils.Theme;

interface

uses
  System.UITypes;

type
  /// <summary>
  /// Tema centralizado do sistema Sancto PDV.
  /// Todas as cores, tamanhos e estilos visuais em um unico lugar.
  /// Suporte a Light e Dark mode.
  /// </summary>
  TThemeMode = (tmLight, tmDark);

  TTheme = record
  public
    class var ModoAtual: TThemeMode;

    // --- Cores Principais ---
    class function CorPrincipal: TAlphaColor; static;
    class function CorPrincipalHover: TAlphaColor; static;
    class function CorPrincipalSelecionado: TAlphaColor; static;
    class function CorPrincipalLight: TAlphaColor; static;

    // --- Cores de Status ---
    class function CorSucesso: TAlphaColor; static;
    class function CorErro: TAlphaColor; static;
    class function CorAlerta: TAlphaColor; static;
    class function CorInfo: TAlphaColor; static;

    // --- Cores de Fundo ---
    class function CorFundo: TAlphaColor; static;
    class function CorFundoCard: TAlphaColor; static;
    class function CorFundoSidebar: TAlphaColor; static;
    class function CorFundoSecundario: TAlphaColor; static;

    // --- Cores de Texto ---
    class function CorTexto: TAlphaColor; static;
    class function CorTextoSecundario: TAlphaColor; static;
    class function CorTextoClaro: TAlphaColor; static;
    class function CorTextoBranco: TAlphaColor; static;

    // --- Cores de Borda ---
    class function CorBorda: TAlphaColor; static;
    class function CorBordaLeve: TAlphaColor; static;

    // --- Dimensoes ---
    class function SidebarWidth: Single; static;
    class function PainelVendaWidth: Single; static;
    class function TopBarHeight: Single; static;
    class function BottomBarHeight: Single; static;
    class function CardWidth: Single; static;
    class function CardHeight: Single; static;
    class function CardRadius: Single; static;
    class function CardSpacing: Single; static;
    class function PillHeight: Single; static;
    class function PillRadius: Single; static;
    class function BtnMinHeight: Single; static;
    class function BtnRadius: Single; static;

    // --- Fontes ---
    class function FontSmall: Single; static;
    class function FontNormal: Single; static;
    class function FontLarge: Single; static;
    class function FontTitle: Single; static;
    class function FontHeading: Single; static;
    class function FontPrice: Single; static;
    class function FontTotal: Single; static;
  end;

implementation

{ TTheme }

// === CORES PRINCIPAIS (Roxo) ===

class function TTheme.CorPrincipal: TAlphaColor;
begin
  Result := $FF6D28D9; // #6D28D9
end;

class function TTheme.CorPrincipalHover: TAlphaColor;
begin
  Result := $FF7C3AED; // #7C3AED
end;

class function TTheme.CorPrincipalSelecionado: TAlphaColor;
begin
  Result := $FF5B21B6; // #5B21B6
end;

class function TTheme.CorPrincipalLight: TAlphaColor;
begin
  Result := $FFEDE9FE; // Light purple background
end;

// === CORES DE STATUS ===

class function TTheme.CorSucesso: TAlphaColor;
begin
  Result := $FF22C55E; // #22C55E
end;

class function TTheme.CorErro: TAlphaColor;
begin
  Result := $FFEF4444; // #EF4444
end;

class function TTheme.CorAlerta: TAlphaColor;
begin
  Result := $FFF59E0B; // Amber
end;

class function TTheme.CorInfo: TAlphaColor;
begin
  Result := $FF3B82F6; // Blue
end;

// === CORES DE FUNDO ===

class function TTheme.CorFundo: TAlphaColor;
begin
  if ModoAtual = tmLight then
    Result := $FFF8FAFC  // #F8FAFC
  else
    Result := $FF0F172A; // Slate 900
end;

class function TTheme.CorFundoCard: TAlphaColor;
begin
  if ModoAtual = tmLight then
    Result := $FFFFFFFF  // White
  else
    Result := $FF1E293B; // Slate 800
end;

class function TTheme.CorFundoSidebar: TAlphaColor;
begin
  if ModoAtual = tmLight then
    Result := $FFFFFFFF  // White
  else
    Result := $FF1E293B;
end;

class function TTheme.CorFundoSecundario: TAlphaColor;
begin
  if ModoAtual = tmLight then
    Result := $FFF1F5F9  // Slate 100
  else
    Result := $FF334155; // Slate 700
end;

// === CORES DE TEXTO ===

class function TTheme.CorTexto: TAlphaColor;
begin
  if ModoAtual = tmLight then
    Result := $FF1E293B  // #1E293B Slate 800
  else
    Result := $FFF1F5F9;
end;

class function TTheme.CorTextoSecundario: TAlphaColor;
begin
  if ModoAtual = tmLight then
    Result := $FF64748B  // Slate 500
  else
    Result := $FF94A3B8;
end;

class function TTheme.CorTextoClaro: TAlphaColor;
begin
  if ModoAtual = tmLight then
    Result := $FF94A3B8  // Slate 400
  else
    Result := $FF64748B;
end;

class function TTheme.CorTextoBranco: TAlphaColor;
begin
  Result := $FFFFFFFF;
end;

// === CORES DE BORDA ===

class function TTheme.CorBorda: TAlphaColor;
begin
  if ModoAtual = tmLight then
    Result := $FFE2E8F0  // Slate 200
  else
    Result := $FF475569;
end;

class function TTheme.CorBordaLeve: TAlphaColor;
begin
  if ModoAtual = tmLight then
    Result := $FFF1F5F9  // Slate 100
  else
    Result := $FF334155;
end;

// === DIMENSOES ===

class function TTheme.SidebarWidth: Single;
begin
  Result := 240;
end;

class function TTheme.PainelVendaWidth: Single;
begin
  Result := 420;
end;

class function TTheme.TopBarHeight: Single;
begin
  Result := 60;
end;

class function TTheme.BottomBarHeight: Single;
begin
  Result := 44;
end;

class function TTheme.CardWidth: Single;
begin
  Result := 180;
end;

class function TTheme.CardHeight: Single;
begin
  Result := 220;
end;

class function TTheme.CardRadius: Single;
begin
  Result := 16;
end;

class function TTheme.CardSpacing: Single;
begin
  Result := 16;
end;

class function TTheme.PillHeight: Single;
begin
  Result := 36;
end;

class function TTheme.PillRadius: Single;
begin
  Result := 18;
end;

class function TTheme.BtnMinHeight: Single;
begin
  Result := 48;
end;

class function TTheme.BtnRadius: Single;
begin
  Result := 12;
end;

// === FONTES ===

class function TTheme.FontSmall: Single;
begin
  Result := 11;
end;

class function TTheme.FontNormal: Single;
begin
  Result := 13;
end;

class function TTheme.FontLarge: Single;
begin
  Result := 15;
end;

class function TTheme.FontTitle: Single;
begin
  Result := 18;
end;

class function TTheme.FontHeading: Single;
begin
  Result := 22;
end;

class function TTheme.FontPrice: Single;
begin
  Result := 16;
end;

class function TTheme.FontTotal: Single;
begin
  Result := 32;
end;

initialization
  TTheme.ModoAtual := tmLight;

end.
