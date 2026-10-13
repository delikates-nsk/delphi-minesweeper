unit NameForm;

/// <summary>
///   Диалог запроса имени игрока.
/// </summary>
interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls;

type
  TFormName = class(TForm)
    lblPrompt: TLabel;
    edName: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
  private
    function GetPlayerName: string;
    procedure SetPlayerName(const AValue: string);
  public
    /// <summary>
    ///   Начальное имя в поле ввода.
    /// </summary>
    property PlayerName: string read GetPlayerName write SetPlayerName;
  end;

/// <summary>
///   Показывает диалог запроса имени игрока.
/// </summary>
/// <param name="ADefault">Предзаполненное имя.</param>
/// <param name="AResult">Введённое имя (или ADefault при отмене).</param>
/// <returns>True — нажато «ОК». False — «Отмена».</returns>
function AskPlayerNameDialog(const ADefault: string;
  out AResult: string): Boolean;

implementation

{$R *.dfm}

{ TFormName }

function TFormName.GetPlayerName: string;
begin
  Result := edName.Text;
end;

procedure TFormName.SetPlayerName(const AValue: string);
begin
  edName.Text := AValue;
end;

function AskPlayerNameDialog(const ADefault: string;
  out AResult: string): Boolean;
var
  Form: TFormName;
begin
  Form := TFormName.Create(nil);
  try
    Form.PlayerName := ADefault;
    Result := Form.ShowModal = mrOk;
    if Result then
    begin
      AResult := Trim(Form.PlayerName);
      if AResult = '' then AResult := 'Игрок';
    end
    else
      AResult := ADefault;
  finally
    Form.Free;
  end;
end;

end.
