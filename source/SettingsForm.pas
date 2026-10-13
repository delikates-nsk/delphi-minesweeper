unit SettingsForm;

/// <summary>
///   Диалог выбора сложности.
/// </summary>
interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  Settings;

type
  TFormSettings = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    rbNewbie: TRadioButton;
    lblNewbie: TLabel;
    rbAmateur: TRadioButton;
    lblAmateur: TLabel;
    rbExpert: TRadioButton;
    lblExpert: TLabel;
    rbInsane: TRadioButton;
    lblInsane: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure lblInsaneClick(Sender: TObject);
    procedure lblExpertClick(Sender: TObject);
    procedure lblAmateurClick(Sender: TObject);
    procedure lblNewbieClick(Sender: TObject);
  private
  public
  end;

function ShowSettingsDialog(Var ASettings: TAppSettings): Boolean;

implementation

{$R *.dfm}

{ TFormSettings }

procedure TFormSettings.FormCreate(Sender: TObject);
begin
  lblNewbie.Caption  := DIFFICULTIES[dNewbie].Description;
  lblAmateur.Caption := DIFFICULTIES[dAmateur].Description;
  lblExpert.Caption  := DIFFICULTIES[dExpert].Description;
  lblInsane.Caption  := DIFFICULTIES[dInsane].Description;
end;

procedure TFormSettings.lblAmateurClick(Sender: TObject);
begin
  rbAmateur.Checked := True;
end;

procedure TFormSettings.lblExpertClick(Sender: TObject);
begin
  rbExpert.Checked := True;
end;

procedure TFormSettings.lblInsaneClick(Sender: TObject);
begin
   rbInsane.Checked := True;
end;

procedure TFormSettings.lblNewbieClick(Sender: TObject);
begin
  rbNewbie.Checked := True;
end;

procedure TFormSettings.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

function ShowSettingsDialog(Var ASettings: TAppSettings): Boolean;
var
  Form: TFormSettings;
begin
  Result := False;
  if ASettings = nil then Exit;
  Form := TFormSettings.Create(nil);
  try
    case ASettings.Difficulty of
      dNewbie:  Form.rbNewbie.Checked  := True;
      dAmateur: Form.rbAmateur.Checked := True;
      dExpert:  Form.rbExpert.Checked  := True;
      dInsane:  Form.rbInsane.Checked  := True;
    end;
    if Form.ShowModal = mrOk then
    begin
      if not Form.rbNewbie.Checked then begin
        if not Form.rbAmateur.Checked then begin
          if Form.rbExpert.Checked
            then ASettings.Difficulty := dExpert
          else ASettings.Difficulty := dInsane;
        end else ASettings.Difficulty := dAmateur;
      end else ASettings.Difficulty := dNewbie;
      Result := True;
    end;
  finally
    Form.Free;
  end;
end;

end.