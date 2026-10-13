unit FieldRenderer;

/// <summary>
///   Рисует игровое поле: клетки, цифры, флажки, мины.
/// </summary>
interface

uses
  System.SysUtils, System.Types, System.Math,
  Vcl.Graphics,
  Settings, GameLogic;

type
  TFieldRenderer = class
  public
    class procedure DrawCell(ACanvas: TCanvas;
      AX, AY, ASize: Integer;
      const ACell: TCell;
      AShowMines, AIsChordPressed: Boolean);

    class procedure DrawCellHidden(ACanvas: TCanvas;
      AX, AY, ASize: Integer);
    class procedure DrawCellPressed(ACanvas: TCanvas;
      AX, AY, ASize: Integer);
    class procedure DrawCellEmpty(ACanvas: TCanvas;
      AX, AY, ASize: Integer);
    class procedure DrawCellNumber(ACanvas: TCanvas;
      AX, AY, ASize, ANumber: Integer);
    class procedure DrawCellFlag(ACanvas: TCanvas;
      AX, AY, ASize: Integer);
    class procedure DrawCellMine(ACanvas: TCanvas;
      AX, AY, ASize: Integer);
    class procedure DrawCellWrong(ACanvas: TCanvas;
      AX, AY, ASize: Integer);
  private
    class function NumberColor(ANumber: Integer): TColor;
    class procedure DrawRaisedBevel(ACanvas: TCanvas;
      AX, AY, ASize, ABevel: Integer);
    class procedure DrawLoweredBevel(ACanvas: TCanvas;
      AX, AY, ASize, ABevel: Integer);
  end;

implementation

const
  CELL_BEVEL = 2;

{ TFieldRenderer }

class procedure TFieldRenderer.DrawCell(ACanvas: TCanvas;
  AX, AY, ASize: Integer; const ACell: TCell;
  AShowMines, AIsChordPressed: Boolean);
begin
  if AIsChordPressed and (ACell.State = csHidden) then
  begin
    DrawCellPressed(ACanvas, AX, AY, ASize);
    Exit;
  end;

  case ACell.State of
    csHidden:
      begin
        if AShowMines and ACell.IsMine then
          DrawCellMine(ACanvas, AX, AY, ASize)
        else
          DrawCellHidden(ACanvas, AX, AY, ASize);
      end;
    csFlagged:
      begin
        if AShowMines and (not ACell.IsMine) then
          DrawCellWrong(ACanvas, AX, AY, ASize)
        else
          DrawCellFlag(ACanvas, AX, AY, ASize);
      end;
    csOpened:
      begin
        if ACell.IsMine then
          DrawCellMine(ACanvas, AX, AY, ASize)
        else if ACell.MinesAround > 0 then
          DrawCellNumber(ACanvas, AX, AY, ASize, ACell.MinesAround)
        else
          DrawCellEmpty(ACanvas, AX, AY, ASize);
      end;
  end;
end;

class procedure TFieldRenderer.DrawCellHidden(ACanvas: TCanvas;
  AX, AY, ASize: Integer);
begin
  ACanvas.Brush.Color := COLOR_CELL_HIDDEN;
  ACanvas.Pen.Color := COLOR_CELL_HIDDEN;
  ACanvas.FillRect(Rect(AX, AY, AX + ASize, AY + ASize));
  DrawRaisedBevel(ACanvas, AX, AY, ASize, CELL_BEVEL);
end;

class procedure TFieldRenderer.DrawCellPressed(ACanvas: TCanvas;
  AX, AY, ASize: Integer);
begin
  ACanvas.Brush.Color := COLOR_CELL_HIDDEN;
  ACanvas.Pen.Color := COLOR_CELL_HIDDEN;
  ACanvas.FillRect(Rect(AX, AY, AX + ASize, AY + ASize));
  DrawLoweredBevel(ACanvas, AX, AY, ASize, CELL_BEVEL);
end;

class procedure TFieldRenderer.DrawCellEmpty(ACanvas: TCanvas;
  AX, AY, ASize: Integer);
begin
  ACanvas.Brush.Color := COLOR_CELL_OPENED;
  ACanvas.Pen.Color := COLOR_CELL_OPENED;
  ACanvas.FillRect(Rect(AX, AY, AX + ASize, AY + ASize));
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color := COLOR_CELL_OPENED_BORDER;
  ACanvas.Pen.Width := 1;
  ACanvas.Rectangle(AX, AY, AX + ASize, AY + ASize);
  ACanvas.Brush.Style := bsSolid;
end;

class procedure TFieldRenderer.DrawCellNumber(ACanvas: TCanvas;
  AX, AY, ASize, ANumber: Integer);
var
  OldColor: TColor;
  OldStyle: TFontStyles;
  OldHeight: Integer;
  S: string;
begin
  DrawCellEmpty(ACanvas, AX, AY, ASize);
  OldColor := ACanvas.Font.Color;
  OldStyle := ACanvas.Font.Style;
  OldHeight := ACanvas.Font.Height;

  ACanvas.Font.Color := NumberColor(ANumber);
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Height := -Round(ASize * 0.62);

  S := IntToStr(ANumber);
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(
    AX + (ASize - ACanvas.TextWidth(S)) div 2,
    AY + (ASize - ACanvas.TextHeight(S)) div 2, S);
  ACanvas.Brush.Style := bsSolid;

  ACanvas.Font.Color := OldColor;
  ACanvas.Font.Style := OldStyle;
  ACanvas.Font.Height := OldHeight;
end;

class procedure TFieldRenderer.DrawCellFlag(ACanvas: TCanvas;
  AX, AY, ASize: Integer);
var
  CenterX: Integer;
  FlagTop: Integer;
  FlagBottom: Integer;
  PoleX: Integer;
  FlagWidth: Integer;
  FlagHeight: Integer;
begin
  DrawCellHidden(ACanvas, AX, AY, ASize);
  CenterX := AX + ASize div 2;
  FlagTop := AY + ASize div 5;
  FlagBottom := AY + ASize - ASize div 5;
  PoleX := CenterX - ASize div 8;

  ACanvas.Pen.Color := clBlack;
  ACanvas.Pen.Width := Max(2, ASize div 12);
  ACanvas.MoveTo(PoleX, FlagTop);
  ACanvas.LineTo(PoleX, FlagBottom);

  FlagWidth := ASize div 2;
  FlagHeight := ASize div 3;
  ACanvas.Brush.Color := clRed;
  ACanvas.Pen.Color := clRed;
  ACanvas.Polygon([
    Point(PoleX, FlagTop),
    Point(PoleX + FlagWidth, FlagTop + FlagHeight div 2),
    Point(PoleX, FlagTop + FlagHeight)
  ]);

  ACanvas.Brush.Color := clBlack;
  ACanvas.Pen.Color := clBlack;
  ACanvas.FillRect(Rect(
    PoleX - ASize div 8,
    FlagBottom - ASize div 16,
    PoleX + ASize div 8,
    FlagBottom + ASize div 16));
end;

class procedure TFieldRenderer.DrawCellMine(ACanvas: TCanvas;
  AX, AY, ASize: Integer);
var
  CenterX, CenterY: Integer;
  Radius: Integer;
  RayLen: Integer;
  I: Integer;
  Angle: Double;
  X1, Y1, X2, Y2: Integer;
begin
  ACanvas.Brush.Color := COLOR_CELL_OPENED;
  ACanvas.Pen.Color := COLOR_CELL_OPENED;
  ACanvas.FillRect(Rect(AX, AY, AX + ASize, AY + ASize));

  CenterX := AX + ASize div 2;
  CenterY := AY + ASize div 2;
  Radius := ASize div 4;
  RayLen := ASize div 6;

  ACanvas.Pen.Color := clBlack;
  ACanvas.Pen.Width := Max(1, ASize div 16);
  for I := 0 to 7 do
  begin
    Angle := I * Pi / 4;
    X1 := CenterX + Round((Radius + 1) * Cos(Angle));
    Y1 := CenterY + Round((Radius + 1) * Sin(Angle));
    X2 := CenterX + Round((Radius + RayLen) * Cos(Angle));
    Y2 := CenterY + Round((Radius + RayLen) * Sin(Angle));
    ACanvas.MoveTo(X1, Y1);
    ACanvas.LineTo(X2, Y2);
  end;

  ACanvas.Brush.Color := clBlack;
  ACanvas.Pen.Color := clBlack;
  ACanvas.Ellipse(CenterX - Radius, CenterY - Radius,
    CenterX + Radius, CenterY + Radius);

  ACanvas.Brush.Color := clWhite;
  ACanvas.Pen.Color := clWhite;
  ACanvas.Ellipse(CenterX - Radius div 2, CenterY - Radius div 2,
    CenterX - Radius div 4, CenterY - Radius div 4);
end;

class procedure TFieldRenderer.DrawCellWrong(ACanvas: TCanvas;
  AX, AY, ASize: Integer);
var
  Margin: Integer;
begin
  DrawCellEmpty(ACanvas, AX, AY, ASize);
  Margin := ASize div 6;
  ACanvas.Brush.Color := COLOR_CELL_WRONG_FLAG;
  ACanvas.Pen.Color := COLOR_CELL_WRONG_FLAG;
  ACanvas.FillRect(Rect(AX + Margin, AY + Margin,
    AX + ASize - Margin, AY + ASize - Margin));

  ACanvas.Pen.Color := clBlack;
  ACanvas.Pen.Width := Max(2, ASize div 10);
  ACanvas.MoveTo(AX + Margin, AY + Margin);
  ACanvas.LineTo(AX + ASize - Margin, AY + ASize - Margin);

  ACanvas.Brush.Color := clRed;
  ACanvas.Pen.Color := clRed;
  ACanvas.Polygon([
    Point(AX + ASize div 2, AY + ASize div 3),
    Point(AX + ASize * 3 div 4, AY + ASize div 2),
    Point(AX + ASize div 2, AY + ASize * 2 div 3)
  ]);
end;

class function TFieldRenderer.NumberColor(ANumber: Integer): TColor;
begin
  case ANumber of
    1: Result := COLOR_NUM_1;
    2: Result := COLOR_NUM_2;
    3: Result := COLOR_NUM_3;
    4: Result := COLOR_NUM_4;
    5: Result := COLOR_NUM_5;
    6: Result := COLOR_NUM_6;
    7: Result := COLOR_NUM_7;
    8: Result := COLOR_NUM_8;
  else
    Result := clBlack;
  end;
end;

class procedure TFieldRenderer.DrawRaisedBevel(ACanvas: TCanvas;
  AX, AY, ASize, ABevel: Integer);
var
  I: Integer;
begin
  ACanvas.Pen.Width := 1;
  for I := 0 to ABevel - 1 do
  begin
    ACanvas.Pen.Color := COLOR_CELL_HIDDEN_LIGHT;
    ACanvas.MoveTo(AX + I, AY + I);
    ACanvas.LineTo(AX + ASize - 1 - I, AY + I);
    ACanvas.MoveTo(AX + I, AY + I);
    ACanvas.LineTo(AX + I, AY + ASize - 1 - I);

    ACanvas.Pen.Color := COLOR_CELL_HIDDEN_DARK;
    ACanvas.MoveTo(AX + ASize - 1 - I, AY + I);
    ACanvas.LineTo(AX + ASize - 1 - I, AY + ASize - 1 - I);
    ACanvas.MoveTo(AX + I, AY + ASize - 1 - I);
    ACanvas.LineTo(AX + ASize - 1 - I, AY + ASize - 1 - I);
  end;
end;

class procedure TFieldRenderer.DrawLoweredBevel(ACanvas: TCanvas;
  AX, AY, ASize, ABevel: Integer);
var
  I: Integer;
begin
  ACanvas.Pen.Width := 1;
  for I := 0 to ABevel - 1 do
  begin
    ACanvas.Pen.Color := COLOR_CELL_PRESSED_LIGHT;
    ACanvas.MoveTo(AX + I, AY + I);
    ACanvas.LineTo(AX + ASize - 1 - I, AY + I);
    ACanvas.MoveTo(AX + I, AY + I);
    ACanvas.LineTo(AX + I, AY + ASize - 1 - I);

    ACanvas.Pen.Color := COLOR_CELL_PRESSED_DARK;
    ACanvas.MoveTo(AX + ASize - 1 - I, AY + I);
    ACanvas.LineTo(AX + ASize - 1 - I, AY + ASize - 1 - I);
    ACanvas.MoveTo(AX + I, AY + ASize - 1 - I);
    ACanvas.LineTo(AX + ASize - 1 - I, AY + ASize - 1 - I);
  end;
end;

end.
