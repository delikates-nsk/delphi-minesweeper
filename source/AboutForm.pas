unit AboutForm;

/// <summary>
///   Форма «О программе».
/// </summary>
interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage;

type
  TFormAbout = class(TForm)
    lblYear: TLabel;
    btnOK: TButton;
    pnl_logo: TPanel;
    img_logo: TImage;
    pnl_Top: TPanel;
    pnl_Middle: TPanel;
    lblTitle: TLabel;
    lblVersion: TLabel;
    lbl_Author: TLabel;
    pnl_Bottom: TPanel;
  end;

procedure ShowAboutDialog;

implementation

{$R *.dfm}

procedure ShowAboutDialog;
var
  Form: TFormAbout;
begin
  Form := TFormAbout.Create(nil);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

end.