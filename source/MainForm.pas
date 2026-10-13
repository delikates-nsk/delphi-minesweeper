unit MainForm;

/// <summary>
///   Главная форма игры «Сапёр».
/// </summary>
interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.DateUtils, System.Math, System.IOUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Dialogs, Vcl.Menus, Winapi.Windows,
  Settings, FileUtils, RecordsManager, GameLogic,
  DigitRenderer, FieldRenderer,
  SettingsForm, RecordsForm, AboutForm, NameForm;

type
  TFormMain = class(TForm)
    pnlTop: TPanel;
    pnlScore: TPanel;
    paintScore: TPaintBox;
    lblScoreCaption: TLabel;
    pnlTime: TPanel;
    paintTime: TPaintBox;
    lblTimeCaption: TLabel;
    pnlMines: TPanel;
    paintMines: TPaintBox;
    lblMinesCaption: TLabel;
    pnlMult: TPanel;
    paintMult: TPaintBox;
    lblMultCaption: TLabel;
    pnlBorder: TPanel;
    pbField: TPaintBox;
    mmMain: TMainMenu;
    miGame: TMenuItem;
    miNewGame: TMenuItem;
    miSep1: TMenuItem;
    miRecords: TMenuItem;
    miSep2: TMenuItem;
    miExit: TMenuItem;
    miSettings: TMenuItem;
    miDifficulty: TMenuItem;
    miAbout: TMenuItem;
    miAboutItem: TMenuItem;
    tmrTick: TTimer;
    tmrSecond: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure pbFieldPaint(Sender: TObject);
    procedure pbFieldMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbFieldMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure pbFieldMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure paintScorePaint(Sender: TObject);
    procedure paintTimePaint(Sender: TObject);
    procedure paintMinesPaint(Sender: TObject);
    procedure paintMultPaint(Sender: TObject);
    procedure miNewGameClick(Sender: TObject);
    procedure miRecordsClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miDifficultyClick(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure tmrTickTimer(Sender: TObject);
    procedure tmrSecondTimer(Sender: TObject);
  private
    FGameLogic: TGameLogic;
    FAppSettings: TAppSettings;
    FRecords: TRecordsManager;
    FStartTime: TDateTime;
    FEndTime: TDateTime;
    FGameInProgress: Boolean;

    // Chord
    FChordActive: Boolean;
    FChordCol: Integer;
    FChordRow: Integer;
    FChordCells: TCellPosArray;  // все клетки, которые сейчас подсвечены

    procedure CheckWritePermissions;
    procedure CreateNewLogic;
    procedure HandleStateChanged(Sender: TObject);
    procedure HandleGameOver(Sender: TObject);
    procedure UpdateStatus;
    procedure ResizeToField;
    procedure CenterForm;
    procedure ProcessGameOver;
    function AskPlayerName(const ADefault: string): string;
    procedure ShowRecords(const AHighlightIndex: Integer;
      const APlayerScore: Integer);
    procedure DrawIndicator(APaintBox: TPaintBox;
      ADigitCount: Integer; AValue: Integer);

    /// <summary>
    ///   Рисует одну клетку поля.
    /// </summary>
    procedure RedrawCell(ACol, ARow: Integer);

    /// <summary>
    ///   Рисует список клеток.
    /// </summary>
    procedure RedrawCells(const ACells: TCellPosArray);

    /// <summary>
    ///   Заполняет FChordCells — все клетки 3×3 вокруг (ACol, ARow).
    /// </summary>
    procedure BuildChordCells(ACol, ARow: Integer);

    /// <summary>
    ///   Перерисовывает все клетки из FChordCells.
    /// </summary>
    procedure RedrawChordCells;

    /// <summary>
    ///   Снимает подсветку chord — сбрасывает FChordActive и перерисовывает.
    /// </summary>
    procedure ClearChord;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

{ TFormMain }

// ─────────────────────────────────────────────────────────────
//  Жизненный цикл формы
// ─────────────────────────────────────────────────────────────

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FAppSettings := TAppSettings.Create(
    TFileUtils.ExeFile('minesweeper.ini'));
  FAppSettings.Load;

  FRecords := TRecordsManager.Create(
    TFileUtils.ExeFile('records.dat'));
  FRecords.Load;

  if FRecords.LoadError then
    MessageDlg(
      'Не удалось получить доступ к файлу рекордов.' + sLineBreak +
      'Возможно, игра уже запущена.' + sLineBreak + sLineBreak +
      'Рекорды не будут сохраняться.',
      mtWarning, [mbOK], 0);

  CheckWritePermissions;

  CreateNewLogic;
end;

procedure TFormMain.CheckWritePermissions;
var
  Err: string;
begin
  if not TFileUtils.CanWriteToExeDir(Err) then
    MessageDlg(
      'Игра не сможет сохранять настройки.' + sLineBreak +
      'Папка, в которой находится игра, недоступна для записи.' +
      sLineBreak + sLineBreak +
      'Причина: ' + Err + sLineBreak + sLineBreak +
      'Игра будет работать, но настройки не сохранятся.',
      mtWarning, [mbOK], 0);
end;

procedure TFormMain.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := True;
  tmrTick.Enabled := False;
  tmrSecond.Enabled := False;

  if not FAppSettings.Save then
    MessageDlg(
      'Не удалось сохранить настройки.' + sLineBreak +
      'Папка, в которой находится игра, недоступна для записи.',
      mtWarning, [mbOK], 0);

  FRecords.Save;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FGameLogic.Free;
  FRecords.Free;
  FAppSettings.Free;
end;

// ─────────────────────────────────────────────────────────────
//  Управление игровой логикой
// ─────────────────────────────────────────────────────────────

procedure TFormMain.CreateNewLogic;
begin
  FreeAndNil(FGameLogic);
  FGameLogic := TGameLogic.Create(FAppSettings.Difficulty);
  FGameLogic.OnStateChanged := HandleStateChanged;
  FGameLogic.OnGameOver := HandleGameOver;

  FStartTime := 0;
  FEndTime := 0;
  FGameInProgress := False;

  FChordActive := False;
  FChordCol := 0;
  FChordRow := 0;
  SetLength(FChordCells, 0);

  tmrTick.Interval := FGameLogic.TimerIntervalSec * 1000;
  tmrTick.Enabled := False;
  tmrSecond.Enabled := False;

  ResizeToField;
  CenterForm;
  UpdateStatus;

  paintScore.Invalidate;
  paintTime.Invalidate;
  paintMines.Invalidate;
  paintMult.Invalidate;
  pbField.Invalidate;
end;

procedure TFormMain.ResizeToField;
var
  FieldW, FieldH: Integer;
  IndicatorW: Integer;
  AvailableW: Integer;
  TwoRows: Boolean;
  Row1Y, Row2Y: Integer;
  Row1W, Row2W: Integer;
  PanelH: Integer;
begin
  if FGameLogic = nil then Exit;

  // Размер поля
  FieldW := FGameLogic.Cols * CELL_SIZE;
  FieldH := FGameLogic.Rows * CELL_SIZE;

  // Рамка вокруг поля
  pnlBorder.Width := FieldW + 2 * BORDER_SIZE + 2;
  pnlBorder.Height := FieldH + 2 * BORDER_SIZE + 2;

  // Определяем, влезают ли 4 индикатора в ширину поля
  AvailableW := pnlBorder.Width;  // ширина, доступная под индикаторы
  TwoRows := (4 * INDICATOR_MIN_WIDTH + 3 * INDICATOR_SPACING) > AvailableW;

  if TwoRows then
    PanelH := PANEL_HEIGHT_TWO_ROWS
  else
    PanelH := PANEL_HEIGHT_ONE_ROW;

  // Настраиваем pnlTop
  pnlTop.Height := PanelH;
  pnlTop.Width := AvailableW;

  if TwoRows then
  begin
    // 2 ряда по 2 индикатора
    Row1W := AvailableW - INDICATOR_SPACING;  // доступно под 2 индикатора + отступ между
    IndicatorW := (Row1W - INDICATOR_SPACING) div 2;

    Row1Y := LAYOUT_PADDING;
    Row2Y := LAYOUT_PADDING + INDICATOR_HEIGHT + INDICATOR_SPACING;

    // Первый ряд: Очки, Время
    pnlScore.Left := LAYOUT_PADDING;
    pnlScore.Top := Row1Y;
    pnlScore.Width := IndicatorW;
    pnlScore.Height := INDICATOR_HEIGHT;

    pnlTime.Left := LAYOUT_PADDING + IndicatorW + INDICATOR_SPACING;
    pnlTime.Top := Row1Y;
    pnlTime.Width := IndicatorW;
    pnlTime.Height := INDICATOR_HEIGHT;

    // Второй ряд: Мины, Множитель
    pnlMines.Left := LAYOUT_PADDING;
    pnlMines.Top := Row2Y;
    pnlMines.Width := IndicatorW;
    pnlMines.Height := INDICATOR_HEIGHT;

    pnlMult.Left := LAYOUT_PADDING + IndicatorW + INDICATOR_SPACING;
    pnlMult.Top := Row2Y;
    pnlMult.Width := IndicatorW;
    pnlMult.Height := INDICATOR_HEIGHT;
  end
  else
  begin
    // 1 ряд, 4 индикатора
    IndicatorW := (AvailableW - 3 * INDICATOR_SPACING - 2 * LAYOUT_PADDING)
                  div 4;
    if IndicatorW < INDICATOR_MIN_WIDTH then
      IndicatorW := INDICATOR_MIN_WIDTH;

    pnlScore.Left := LAYOUT_PADDING;
    pnlScore.Top := LAYOUT_PADDING;
    pnlScore.Width := IndicatorW;
    pnlScore.Height := INDICATOR_HEIGHT;

    pnlTime.Left := LAYOUT_PADDING + IndicatorW + INDICATOR_SPACING;
    pnlTime.Top := LAYOUT_PADDING;
    pnlTime.Width := IndicatorW;
    pnlTime.Height := INDICATOR_HEIGHT;

    pnlMines.Left := LAYOUT_PADDING + 2 * (IndicatorW + INDICATOR_SPACING);
    pnlMines.Top := LAYOUT_PADDING;
    pnlMines.Width := IndicatorW;
    pnlMines.Height := INDICATOR_HEIGHT;

    pnlMult.Left := LAYOUT_PADDING + 3 * (IndicatorW + INDICATOR_SPACING);
    pnlMult.Top := LAYOUT_PADDING;
    pnlMult.Width := IndicatorW;
    pnlMult.Height := INDICATOR_HEIGHT;
  end;

  // Позиция рамки поля
  pnlBorder.Left := LAYOUT_PADDING;
  pnlBorder.Top := pnlTop.Height + LAYOUT_PADDING;

  // Размеры формы
  ClientWidth := pnlBorder.Left + pnlBorder.Width + LAYOUT_PADDING;
  ClientHeight := pnlBorder.Top + pnlBorder.Height + LAYOUT_PADDING;

  // Перерисовать индикаторы (размеры изменились)
  paintScore.Invalidate;
  paintTime.Invalidate;
  paintMines.Invalidate;
  paintMult.Invalidate;
end;

procedure TFormMain.CenterForm;
begin
  Left := (Screen.WorkAreaWidth - Width) div 2 + Screen.WorkAreaLeft;
  Top := (Screen.WorkAreaHeight - Height) div 2 + Screen.WorkAreaTop;
end;

// ─────────────────────────────────────────────────────────────
//  Точечная перерисовка
// ─────────────────────────────────────────────────────────────

procedure TFormMain.RedrawCell(ACol, ARow: Integer);
var
  Cell: TCell;
  ShowMines: Boolean;
  ChordPressed: Boolean;
begin
  if FGameLogic = nil then Exit;
  if not FGameLogic.InBounds(ACol, ARow) then Exit;

  ShowMines := FGameLogic.State = gsLost;
  Cell := FGameLogic.GetCell(ACol, ARow);

  ChordPressed := FChordActive and
    (Abs(ACol - FChordCol) <= 1) and
    (Abs(ARow - FChordRow) <= 1) and
    ((ACol <> FChordCol) or (ARow <> FChordRow));

  TFieldRenderer.DrawCell(pbField.Canvas,
    ACol * CELL_SIZE, ARow * CELL_SIZE, CELL_SIZE,
    Cell, ShowMines, ChordPressed);
end;

procedure TFormMain.RedrawCells(const ACells: TCellPosArray);
var
  I: Integer;
begin
  for I := 0 to High(ACells) do
    RedrawCell(ACells[I].Col, ACells[I].Row);
end;

procedure TFormMain.BuildChordCells(ACol, ARow: Integer);
var
  DC, DR: Integer;
  C, R, N: Integer;
begin
  SetLength(FChordCells, 0);
  if FGameLogic = nil then Exit;

  for DR := -1 to 1 do
    for DC := -1 to 1 do
    begin
      C := ACol + DC;
      R := ARow + DR;
      if (C < 0) or (C >= FGameLogic.Cols) then Continue;
      if (R < 0) or (R >= FGameLogic.Rows) then Continue;
      N := Length(FChordCells);
      SetLength(FChordCells, N + 1);
      FChordCells[N].Col := C;
      FChordCells[N].Row := R;
    end;
end;

procedure TFormMain.RedrawChordCells;
begin
  RedrawCells(FChordCells);
end;

procedure TFormMain.ClearChord;
begin
  if not FChordActive then Exit;
  FChordActive := False;
  RedrawChordCells;
  SetLength(FChordCells, 0);
end;

// ─────────────────────────────────────────────────────────────
//  Обработчики событий логики
// ─────────────────────────────────────────────────────────────

procedure TFormMain.HandleStateChanged(Sender: TObject);
begin
  UpdateStatus;
  // Поле перерисовывается точечно из pbFieldMouseDown/Up
end;

procedure TFormMain.HandleGameOver(Sender: TObject);
begin
  FGameInProgress := False;
  FEndTime := Now;
  tmrTick.Enabled := False;
  tmrSecond.Enabled := False;
  miDifficulty.Enabled := True;

  // Снимаем chord, если был активен
  ClearChord;

  UpdateStatus;

  // При завершении партии перерисовываем всё поле
  pbField.Invalidate;

  ProcessGameOver;
end;

procedure TFormMain.ProcessGameOver;
var
  Msg: string;
  Icon: TMsgDlgType;
  PlayerName: string;
  Score: Integer;
  NewIndex: Integer;
  IsWin: Boolean;
begin
  Score := FGameLogic.Score;
  IsWin := FGameLogic.State = gsWon;

  // Сообщение о результате
  if IsWin then
  begin
    Icon := mtInformation;
    Msg := Format(
      'Победа!' + sLineBreak + sLineBreak +
      'Все клетки разобраны.' + sLineBreak +
      'Очки: %d' + sLineBreak,
      [Score]);
  end
  else
  begin
    Icon := mtWarning;
    Msg := Format(
      'Игра проиграна.' + sLineBreak + sLineBreak +
      'Вы подорвались на мине.' + sLineBreak +
      'Очки: %d' + sLineBreak,
      [Score]);
  end;
  MessageDlg(Msg, Icon, [mbOK], 0);

  // Проверяем попадание в топ
  if (Score > 0) and FRecords.IsTopScore(Score) then
  begin
    PlayerName := AskPlayerName(FAppSettings.LastName);
    FAppSettings.LastName := PlayerName;
    NewIndex := FRecords.AddRecord(Score, PlayerName);
    ShowRecords(NewIndex, Score);
  end
  else
    ShowRecords(-1, Score);

  // Новая партия
  CreateNewLogic;
end;

function TFormMain.AskPlayerName(const ADefault: string): string;
begin
 if not AskPlayerNameDialog(ADefault, Result) then
  begin
    Result := ADefault;
    if Result = '' then Result := 'Игрок';
  end;
end;

procedure TFormMain.ShowRecords(const AHighlightIndex: Integer;
  const APlayerScore: Integer);
begin
  ShowRecordsDialog(FRecords, AHighlightIndex, APlayerScore);
end;

procedure TFormMain.UpdateStatus;
begin
  if FGameLogic = nil then Exit;
  paintScore.Invalidate;
  paintTime.Invalidate;
  paintMines.Invalidate;
  paintMult.Invalidate;
end;

// ─────────────────────────────────────────────────────────────
//  Индикаторы
// ─────────────────────────────────────────────────────────────

procedure TFormMain.DrawIndicator(APaintBox: TPaintBox;
  ADigitCount: Integer; AValue: Integer);
var
  W, H, BlockW, X, Y: Integer;
  DigitW, DigitH, Spacing: Integer;
begin
  APaintBox.Canvas.Brush.Color := LCD_BG_COLOR;
  APaintBox.Canvas.FillRect(APaintBox.ClientRect);

  W := APaintBox.Width;
  H := APaintBox.Height;
  DigitH := Round(H * 0.7);
  DigitW := Round(DigitH * 0.55);
  Spacing := DigitW div 4;
  BlockW := TDigitRenderer.GetBlockWidth(DigitW, ADigitCount, Spacing);
  X := (W - BlockW) div 2;
  Y := (H - DigitH) div 2;

  TDigitRenderer.DrawNumber(APaintBox.Canvas, AValue,
    X, Y, DigitW, DigitH, Spacing, ADigitCount,
    LCD_ON_COLOR, LCD_OFF_COLOR);
end;

procedure TFormMain.paintScorePaint(Sender: TObject);
begin
  if FGameLogic = nil then Exit;
  DrawIndicator(paintScore, 5, FGameLogic.Score);
end;

procedure TFormMain.paintTimePaint(Sender: TObject);
var
  Elapsed: Integer;
  EndMoment: TDateTime;
  DigitH, DigitW, Spacing: Integer;
begin
  if FGameLogic = nil then Exit;

  if FStartTime = 0 then
    Elapsed := 0
  else
  begin
    if FGameInProgress then
      EndMoment := Now
    else if FEndTime > 0 then
      EndMoment := FEndTime
    else
      EndMoment := FStartTime;
    Elapsed := Round((EndMoment - FStartTime) * SecsPerDay);
  end;

  if Elapsed < 0 then Elapsed := 0;

  paintTime.Canvas.Brush.Color := LCD_BG_COLOR;
  paintTime.Canvas.FillRect(paintTime.ClientRect);

  DigitH := Round(paintTime.Height * 0.7);
  DigitW := Round(DigitH * 0.55);
  Spacing := DigitW div 4;

  TDigitRenderer.DrawTime(paintTime.Canvas, Elapsed,
    (paintTime.Width - TDigitRenderer.GetTimeBlockWidth(DigitW, Spacing)) div 2,
    (paintTime.Height - DigitH) div 2,
    DigitW, DigitH, Spacing,
    LCD_ON_COLOR, LCD_OFF_COLOR);
end;

procedure TFormMain.paintMinesPaint(Sender: TObject);
begin
  if FGameLogic = nil then Exit;
  DrawIndicator(paintMines, 2, FGameLogic.RewardedMines);
end;

procedure TFormMain.paintMultPaint(Sender: TObject);
begin
  if FGameLogic = nil then Exit;
  DrawIndicator(paintMult, 1, FGameLogic.ScoreMultiplier);
end;

// ─────────────────────────────────────────────────────────────
//  Отрисовка поля
// ─────────────────────────────────────────────────────────────

procedure TFormMain.pbFieldPaint(Sender: TObject);
var
  C, R: Integer;
  Cell: TCell;
  ShowMines: Boolean;
  ChordPressed: Boolean;
  ClipRect: TRect;
  CellLeft, CellTop, CellRight, CellBottom: Integer;
begin
  if FGameLogic = nil then Exit;

  ShowMines := FGameLogic.State = gsLost;
  ClipRect := pbField.Canvas.ClipRect;

  for R := 0 to FGameLogic.Rows - 1 do
    for C := 0 to FGameLogic.Cols - 1 do
    begin
      CellLeft := C * CELL_SIZE;
      CellTop := R * CELL_SIZE;
      CellRight := CellLeft + CELL_SIZE;
      CellBottom := CellTop + CELL_SIZE;

      if (CellRight < ClipRect.Left) or (CellLeft > ClipRect.Right) or
         (CellBottom < ClipRect.Top) or (CellTop > ClipRect.Bottom) then
        Continue;

      Cell := FGameLogic.GetCell(C, R);
      ChordPressed := FChordActive and
        (Abs(C - FChordCol) <= 1) and
        (Abs(R - FChordRow) <= 1) and
        ((C <> FChordCol) or (R <> FChordRow));

      TFieldRenderer.DrawCell(pbField.Canvas,
        CellLeft, CellTop, CELL_SIZE,
        Cell, ShowMines, ChordPressed);
    end;
end;

// ─────────────────────────────────────────────────────────────
//  Управление мышью
// ─────────────────────────────────────────────────────────────

procedure TFormMain.pbFieldMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  C, R: Integer;
  Changed: TCellPosArray;
  BothButtons: Boolean;
begin
  if FGameLogic = nil then Exit;
  if FGameLogic.IsGameOver then Exit;

  BothButtons := ((ssLeft in Shift) and (ssRight in Shift)) or
                 (ssMiddle in Shift);

  C := X div CELL_SIZE;
  R := Y div CELL_SIZE;
  if not FGameLogic.InBounds(C, R) then Exit;

  // Обе кнопки (или средняя) — chord
  if BothButtons then
  begin
    if FGameLogic.GetCell(C, R).State = csOpened then
    begin
      ClearChord;
      FChordActive := True;
      FChordCol := C;
      FChordRow := R;
      BuildChordCells(C, R);
      RedrawChordCells;
    end;
    Exit;
  end;

  // Обычный клик
  if Button = mbRight then
  begin
    if not FGameLogic.GameStarted then Exit;
    Changed := FGameLogic.ToggleFlag(C, R);
    RedrawCells(Changed);
    Exit;
  end;

  if Button = mbLeft then
  begin
    if not FGameLogic.GameStarted then
    begin
      FStartTime := Now;
      FGameInProgress := True;
      miDifficulty.Enabled := False;
      tmrTick.Enabled := True;
      tmrSecond.Enabled := True;
    end;
    Changed := FGameLogic.OpenCell(C, R);
    RedrawCells(Changed);
  end;
end;

procedure TFormMain.pbFieldMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  C, R: Integer;
  BothButtons: Boolean;
begin
  if FGameLogic = nil then Exit;
  if FGameLogic.IsGameOver then Exit;

  BothButtons := ((ssLeft in Shift) and (ssRight in Shift)) or
                 (ssMiddle in Shift);

  // Обе НЕ зажаты — снимаем chord
  if not BothButtons then
  begin
    ClearChord;
    Exit;
  end;

  // Определяем клетку под курсором
  C := X div CELL_SIZE;
  R := Y div CELL_SIZE;
  if not FGameLogic.InBounds(C, R) then Exit;
  if FGameLogic.GetCell(C, R).State <> csOpened then Exit;

  // Если chord уже активен на этой же клетке — ничего
  if FChordActive and (C = FChordCol) and (R = FChordRow) then Exit;

  // Снимаем старую подсветку (перерисовывает FChordCells без подсветки)
  ClearChord;

  // Устанавливаем новую
  FChordActive := True;
  FChordCol := C;
  FChordRow := R;
  BuildChordCells(C, R);
  RedrawChordCells;
end;

procedure TFormMain.pbFieldMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  C, R, DC, DR: Integer;
  Cell: TCell;
  FlagsAround, MinesAround: Integer;
  NeighborChanged: TCellPosArray;
  OldChordCol, OldChordRow: Integer;
  NeighborCells: TCellPosArray;
  N: Integer;
begin
  if not FChordActive then Exit;
  if FGameLogic = nil then Exit;
  if FGameLogic.IsGameOver then Exit;

  // Ждём, пока ОБЕ отпущены
  if (ssLeft in Shift) or (ssRight in Shift) then Exit;

  OldChordCol := FChordCol;
  OldChordRow := FChordRow;

  // Считаем флажки вокруг
  FlagsAround := 0;
  MinesAround := FGameLogic.GetCell(OldChordCol, OldChordRow).MinesAround;

  SetLength(NeighborCells, 0);
  for DR := -1 to 1 do
    for DC := -1 to 1 do
    begin
      if (DC = 0) and (DR = 0) then Continue;
      C := OldChordCol + DC;
      R := OldChordRow + DR;
      if not FGameLogic.InBounds(C, R) then Continue;

      N := Length(NeighborCells);
      SetLength(NeighborCells, N + 1);
      NeighborCells[N].Col := C;
      NeighborCells[N].Row := R;

      Cell := FGameLogic.GetCell(C, R);
      if Cell.State = csFlagged then Inc(FlagsAround);
    end;

  // Снимаем подсветку ПЕРЕД открытием — иначе DrawCell применит chord
  FChordActive := False;
  RedrawChordCells;
  SetLength(FChordCells, 0);

  // Если флажков ровно столько, сколько мин — открываем закрытых соседей
  if FlagsAround = MinesAround then
  begin
    for DR := -1 to 1 do
      for DC := -1 to 1 do
      begin
        if (DC = 0) and (DR = 0) then Continue;
        C := OldChordCol + DC;
        R := OldChordRow + DR;
        if not FGameLogic.InBounds(C, R) then Continue;
        Cell := FGameLogic.GetCell(C, R);
        if Cell.State = csHidden then
        begin
          NeighborChanged := FGameLogic.OpenCell(C, R);
          RedrawCells(NeighborChanged);
        end;
      end;
  end
  else
  begin
    // Открытия не было — перерисовываем соседей, чтобы убрать подсветку
    RedrawCells(NeighborCells);
  end;
end;

// ─────────────────────────────────────────────────────────────
//  Меню
// ─────────────────────────────────────────────────────────────

procedure TFormMain.miNewGameClick(Sender: TObject);
begin
  CreateNewLogic;
end;

procedure TFormMain.miRecordsClick(Sender: TObject);
begin
  ShowRecords(-1, -1);
end;

procedure TFormMain.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.miDifficultyClick(Sender: TObject);
begin
  if ShowSettingsDialog(FAppSettings) then
  begin
    if (FGameLogic <> nil) and (not FGameLogic.GameStarted) then
      CreateNewLogic;
  end;
end;

procedure TFormMain.miAboutClick(Sender: TObject);
begin
  ShowAboutDialog;
end;

// ─────────────────────────────────────────────────────────────
//  Таймеры
// ─────────────────────────────────────────────────────────────

procedure TFormMain.tmrTickTimer(Sender: TObject);
begin
  if not FGameInProgress then Exit;
  if FGameLogic = nil then Exit;
  if FGameLogic.IsGameOver then Exit;
  FGameLogic.TickTimer;
  paintScore.Invalidate;
end;

procedure TFormMain.tmrSecondTimer(Sender: TObject);
begin
  if not FGameInProgress then Exit;
  paintTime.Invalidate;
end;

end.
