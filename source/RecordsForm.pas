unit RecordsForm;

/// <summary>
///   Форма таблицы рекордов (топ-30).
/// </summary>
interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Settings, RecordsManager;

type
  TFormRecords = class(TForm)
    lvRecords: TListView;
    lblMessage: TLabel;
    btnOK: TButton;
    procedure FormCreate(Sender: TObject);
  private
    FRecords: TRecordsManager;
    FHighlightIndex: Integer;
    FPlayerScore: Integer;
    procedure FillList;
    procedure HighlightRecord(AIndex: Integer);
    procedure ShowMessageIfNeeded;
  public
    procedure Setup(ARecords: TRecordsManager;
      AHighlightIndex, APlayerScore: Integer);
  end;

function ShowRecordsDialog(ARecords: TRecordsManager;
  AHighlightIndex, APlayerScore: Integer): Boolean;

implementation

{$R *.dfm}

{ TFormRecords }

procedure TFormRecords.FormCreate(Sender: TObject);
begin
  // Настраиваем колонки
  lvRecords.ViewStyle := vsReport;
  lvRecords.RowSelect := True;
  lvRecords.ReadOnly := True;
  lvRecords.GridLines := True;
  lvRecords.Columns.Clear;

  with lvRecords.Columns.Add do
  begin
    Caption := '№';
    Width := 40;
    Alignment := taRightJustify;
  end;
  with lvRecords.Columns.Add do
  begin
    Caption := 'Имя';
    Width := 160;
  end;
  with lvRecords.Columns.Add do
  begin
    Caption := 'Очки';
    Width := 100;
    Alignment := taRightJustify;
  end;
  with lvRecords.Columns.Add do
  begin
    Caption := 'Дата';
    Width := 140;
  end;
end;

procedure TFormRecords.Setup(ARecords: TRecordsManager;
  AHighlightIndex, APlayerScore: Integer);
begin
  FRecords := ARecords;
  FHighlightIndex := AHighlightIndex;
  FPlayerScore := APlayerScore;
  FillList;
  HighlightRecord(AHighlightIndex);
  ShowMessageIfNeeded;
end;

procedure TFormRecords.FillList;
var
  Recs: TRecordList;
  I: Integer;
  Item: TListItem;
begin
  lvRecords.Items.BeginUpdate;
  try
    lvRecords.Items.Clear;
    if FRecords = nil then Exit;
    Recs := FRecords.GetAllRecords;
    for I := 0 to High(Recs) do
    begin
      Item := lvRecords.Items.Add;
      Item.Caption := IntToStr(I + 1);
      Item.SubItems.Add(Recs[I].PlayerName);
      Item.SubItems.Add(IntToStr(Recs[I].Score));
      Item.SubItems.Add(FormatDateTime('dd.mm.yyyy hh:nn',
        Recs[I].Date));
    end;
  finally
    lvRecords.Items.EndUpdate;
  end;
end;

procedure TFormRecords.HighlightRecord(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= lvRecords.Items.Count) then Exit;
  lvRecords.Items[AIndex].Selected := True;
  lvRecords.Items[AIndex].Focused := True;
  lvRecords.Items[AIndex].MakeVisible(False);
end;

procedure TFormRecords.ShowMessageIfNeeded;
begin
  if FHighlightIndex >= 0 then
  begin
    lblMessage.Caption := Format(
      'Поздравляем! Вы заняли %d-е место с результатом %d очков.',
      [FHighlightIndex + 1, FPlayerScore]);
    lblMessage.Font.Color := clGreen;
  end
  else if FPlayerScore >= 0 then
  begin
    lblMessage.Caption := Format(
      'К сожалению, ваш результат %d очков слишком мал, ' +
      'чтобы попасть в таблицу рекордов.',
      [FPlayerScore]);
    lblMessage.Font.Color := clGrayText;
  end
  else
    lblMessage.Caption := '';
end;

function ShowRecordsDialog(ARecords: TRecordsManager;
  AHighlightIndex, APlayerScore: Integer): Boolean;
var
  Form: TFormRecords;
begin
  Result := False;
  Form := TFormRecords.Create(nil);
  try
    Form.Setup(ARecords, AHighlightIndex, APlayerScore);
    Form.ShowModal;
    Result := True;
  finally
    Form.Free;
  end;
end;

end.
