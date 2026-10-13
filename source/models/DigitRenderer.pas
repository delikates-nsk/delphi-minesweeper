unit DigitRenderer;

/// <summary>
///   Рисует 7-сегментные цифры на TCanvas в стиле LCD-часов.
/// </summary>
interface

uses
  System.SysUtils, System.Types, System.Math,
  Vcl.Graphics,
  Settings;

type
  TSegment = (sgA, sgB, sgC, sgD, sgE, sgF, sgG);
  TSegmentSet = set of TSegment;

  TDigitRenderer = class
  public
    class procedure DrawDigit(ACanvas: TCanvas; ADigit: Integer;
      AX, AY, AWidth, AHeight: Integer;
      AOnColor, AOffColor: TColor);

    class procedure DrawNumber(ACanvas: TCanvas; AValue: Integer;
      AX, AY, ADigitWidth, ADigitHeight, ASpacing: Integer;
      ADigitCount: Integer;
      AOnColor, AOffColor: TColor);

    class procedure DrawTime(ACanvas: TCanvas; ASeconds: Integer;
      AX, AY, ADigitWidth, ADigitHeight, ASpacing: Integer;
      AOnColor, AOffColor: TColor);

    class procedure DrawColon(ACanvas: TCanvas;
      AX, AY, AWidth, AHeight: Integer; AOnColor: TColor);

    class function GetBlockWidth(ADigitWidth, ADigitCount,
      ASpacing: Integer): Integer;

    class function GetTimeBlockWidth(ADigitWidth,
      ASpacing: Integer): Integer;
  private
    class procedure DrawSegment(ACanvas: TCanvas; ASeg: TSegment;
      AX, AY, AWidth, AHeight, AThickness: Integer; AColor: TColor);
    class procedure DrawHSegment(ACanvas: TCanvas;
      AX, AY, AWidth, AThickness: Integer; AColor: TColor);
    class procedure DrawVSegment(ACanvas: TCanvas;
      AX, AY, AHeight, AThickness: Integer; AColor: TColor);
  end;

const
  DIGIT_SEGMENTS: array[0..9] of TSegmentSet = (
    [sgA, sgB, sgC, sgD, sgE, sgF],
    [sgB, sgC],
    [sgA, sgB, sgG, sgE, sgD],
    [sgA, sgB, sgG, sgC, sgD],
    [sgF, sgG, sgB, sgC],
    [sgA, sgF, sgG, sgC, sgD],
    [sgA, sgF, sgG, sgE, sgC, sgD],
    [sgA, sgB, sgC],
    [sgA, sgB, sgC, sgD, sgE, sgF, sgG],
    [sgA, sgB, sgC, sgD, sgF, sgG]
  );

implementation

{ TDigitRenderer }

class function TDigitRenderer.GetBlockWidth(ADigitWidth, ADigitCount,
  ASpacing: Integer): Integer;
begin
  if ADigitCount <= 0 then Exit(0);
  Result := ADigitCount * ADigitWidth + (ADigitCount - 1) * ASpacing;
end;

class function TDigitRenderer.GetTimeBlockWidth(ADigitWidth,
  ASpacing: Integer): Integer;
begin
  Result := 4 * ADigitWidth + 3 * ASpacing + (ADigitWidth div 2) + ASpacing;
end;

class procedure TDigitRenderer.DrawDigit(ACanvas: TCanvas; ADigit: Integer;
  AX, AY, AWidth, AHeight: Integer; AOnColor, AOffColor: TColor);
var
  Seg: TSegment;
  Thickness: Integer;
begin
  if (ADigit < 0) or (ADigit > 9) then Exit;
  Thickness := Max(2, Round(AHeight * LCD_SEGMENT_THICKNESS));
  for Seg := Low(TSegment) to High(TSegment) do
  begin
    if Seg in DIGIT_SEGMENTS[ADigit] then
      DrawSegment(ACanvas, Seg, AX, AY, AWidth, AHeight, Thickness, AOnColor)
    else
      DrawSegment(ACanvas, Seg, AX, AY, AWidth, AHeight, Thickness, AOffColor);
  end;
end;

class procedure TDigitRenderer.DrawNumber(ACanvas: TCanvas; AValue: Integer;
  AX, AY, ADigitWidth, ADigitHeight, ASpacing: Integer;
  ADigitCount: Integer; AOnColor, AOffColor: TColor);
var
  S: string;
  I: Integer;
  CurX: Integer;
  D: Integer;
begin
  if ADigitCount <= 0 then Exit;
  if AValue < 0 then AValue := 0;
  S := IntToStr(AValue);
  while Length(S) < ADigitCount do S := '0' + S;
  if Length(S) > ADigitCount then
    S := Copy(S, Length(S) - ADigitCount + 1, ADigitCount);

  CurX := AX;
  for I := 1 to Length(S) do
  begin
    D := Ord(S[I]) - Ord('0');
    DrawDigit(ACanvas, D, CurX, AY, ADigitWidth, ADigitHeight,
      AOnColor, AOffColor);
    Inc(CurX, ADigitWidth + ASpacing);
  end;
end;


class procedure TDigitRenderer.DrawTime(ACanvas: TCanvas; ASeconds: Integer;
  AX, AY, ADigitWidth, ADigitHeight, ASpacing: Integer;
  AOnColor, AOffColor: TColor);
var
  Minutes, Seconds: Integer;
  CurX: Integer;
  ColonWidth: Integer;
begin
  if ASeconds < 0 then ASeconds := 0;

  Minutes := (ASeconds div 60) mod 100;  // ← mod 100
  Seconds := ASeconds mod 60;

  CurX := AX;

  DrawDigit(ACanvas, Minutes div 10, CurX, AY, ADigitWidth,
    ADigitHeight, AOnColor, AOffColor);
  Inc(CurX, ADigitWidth + ASpacing);
  DrawDigit(ACanvas, Minutes mod 10, CurX, AY, ADigitWidth,
    ADigitHeight, AOnColor, AOffColor);
  Inc(CurX, ADigitWidth + ASpacing);

  ColonWidth := ADigitWidth div 2;
  DrawColon(ACanvas, CurX, AY, ColonWidth, ADigitHeight, AOnColor);
  Inc(CurX, ColonWidth + ASpacing);

  DrawDigit(ACanvas, Seconds div 10, CurX, AY, ADigitWidth,
    ADigitHeight, AOnColor, AOffColor);
  Inc(CurX, ADigitWidth + ASpacing);
  DrawDigit(ACanvas, Seconds mod 10, CurX, AY, ADigitWidth,
    ADigitHeight, AOnColor, AOffColor);
end;

class procedure TDigitRenderer.DrawColon(ACanvas: TCanvas;
  AX, AY, AWidth, AHeight: Integer; AOnColor: TColor);
var
  DotSize: Integer;
  CX: Integer;
  Y1, Y2: Integer;
begin
  DotSize := Max(3, AWidth div 2);
  CX := AX + (AWidth - DotSize) div 2;
  Y1 := AY + AHeight div 3;
  Y2 := AY + (AHeight * 2) div 3 - DotSize;
  ACanvas.Brush.Color := AOnColor;
  ACanvas.Pen.Color := AOnColor;
  ACanvas.FillRect(Rect(CX, Y1, CX + DotSize, Y1 + DotSize));
  ACanvas.FillRect(Rect(CX, Y2, CX + DotSize, Y2 + DotSize));
end;

class procedure TDigitRenderer.DrawSegment(ACanvas: TCanvas;
  ASeg: TSegment; AX, AY, AWidth, AHeight, AThickness: Integer;
  AColor: TColor);
var
  MidY: Integer;
  HalfH: Integer;
  HalfW: Integer;
  Margin: Integer;
begin
  HalfW := AWidth div 2;
  HalfH := AHeight div 2;
  MidY := AY + HalfH;
  Margin := AThickness div 2;

  case ASeg of
    sgA: DrawHSegment(ACanvas, AX + Margin, AY,
      AWidth - 2 * Margin, AThickness, AColor);
    sgG: DrawHSegment(ACanvas, AX + Margin, MidY - AThickness div 2,
      AWidth - 2 * Margin, AThickness, AColor);
    sgD: DrawHSegment(ACanvas, AX + Margin, AY + AHeight - AThickness,
      AWidth - 2 * Margin, AThickness, AColor);
    sgF: DrawVSegment(ACanvas, AX, AY + Margin,
      HalfH - Margin, AThickness, AColor);
    sgB: DrawVSegment(ACanvas, AX + AWidth - AThickness, AY + Margin,
      HalfH - Margin, AThickness, AColor);
    sgE: DrawVSegment(ACanvas, AX, MidY,
      HalfH - Margin, AThickness, AColor);
    sgC: DrawVSegment(ACanvas, AX + AWidth - AThickness, MidY,
      HalfH - Margin, AThickness, AColor);
  end;
end;

class procedure TDigitRenderer.DrawHSegment(ACanvas: TCanvas;
  AX, AY, AWidth, AThickness: Integer; AColor: TColor);
var
  Pts: array[0..3] of TPoint;
begin
  Pts[0] := Point(AX + AThickness div 4, AY);
  Pts[1] := Point(AX + AWidth - AThickness div 4, AY);
  Pts[2] := Point(AX + AWidth, AY + AThickness div 2);
  Pts[3] := Point(AX, AY + AThickness div 2);
  ACanvas.Brush.Color := AColor;
  ACanvas.Pen.Color := AColor;
  ACanvas.Polygon(Pts);

  Pts[0] := Point(AX, AY + AThickness div 2);
  Pts[1] := Point(AX + AWidth, AY + AThickness div 2);
  Pts[2] := Point(AX + AWidth - AThickness div 4, AY + AThickness);
  Pts[3] := Point(AX + AThickness div 4, AY + AThickness);
  ACanvas.Polygon(Pts);
end;

class procedure TDigitRenderer.DrawVSegment(ACanvas: TCanvas;
  AX, AY, AHeight, AThickness: Integer; AColor: TColor);
var
  Pts: array[0..3] of TPoint;
begin
  Pts[0] := Point(AX, AY + AThickness div 4);
  Pts[1] := Point(AX + AThickness div 2, AY);
  Pts[2] := Point(AX + AThickness div 2, AY + AHeight);
  Pts[3] := Point(AX, AY + AHeight - AThickness div 4);
  ACanvas.Brush.Color := AColor;
  ACanvas.Pen.Color := AColor;
  ACanvas.Polygon(Pts);

  Pts[0] := Point(AX + AThickness div 2, AY);
  Pts[1] := Point(AX + AThickness, AY + AThickness div 4);
  Pts[2] := Point(AX + AThickness, AY + AHeight - AThickness div 4);
  Pts[3] := Point(AX + AThickness div 2, AY + AHeight);
  ACanvas.Polygon(Pts);
end;

end.