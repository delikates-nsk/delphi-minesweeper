unit GameLogic;

/// <summary>
///   Игровая логика Сапёра с очками.
///   Не зависит от UI — только данные и правила.
///   Методы OpenCell и ToggleFlag возвращают список изменившихся
///   клеток, чтобы UI мог перерисовать только их.
/// </summary>
interface

uses
  System.SysUtils, System.Classes, System.Math, System.Types,
  Settings;

type
  TCellState = (csHidden, csOpened, csFlagged);

  TCell = record
    IsMine: Boolean;
    MinesAround: Byte;
    State: TCellState;
    Rewarded: Boolean;
  end;

  TGameState = (gsPlaying, gsWon, gsLost);

  /// <summary>
  ///   Координаты одной клетки на поле.
  /// </summary>
  TCellPos = record
    Col: Integer;
    Row: Integer;
  end;

  /// <summary>
  ///   Список координат клеток.
  /// </summary>
  TCellPosArray = array of TCellPos;

  TGameLogic = class
  private
    FGrid: array of array of TCell;
    FCols: Integer;
    FRows: Integer;
    FMineCount: Integer;
    FScore: Integer;
    FScoreMultiplier: Integer;
    FTimerPenalty: Integer;
    FTimerIntervalSec: Integer;
    FState: TGameState;
    FFirstClick: Boolean;
    FOpenedCount: Integer;
    FSafeCount: Integer;
    FRewardedMines: Integer;
    FSettings: TDifficultySettings;
    FOnStateChanged: TNotifyEvent;
    FOnGameOver: TNotifyEvent;

    procedure DoStateChanged;
    procedure DoGameOver;
    function CountMinesAround(Col, Row: Integer): Byte;
    procedure OpenCellRecursive(Col, Row: Integer;
      var AChanged: TCellPosArray);
    procedure GenerateField(FirstClickCol, FirstClickRow: Integer);
    procedure CheckWin;
    procedure CheckPendingMines(var AChanged: TCellPosArray);
    function AllNeighborsKnown(Col, Row: Integer): Boolean;
    function MaxOpenNeighborNumber(Col, Row: Integer): Integer;
    procedure AddScore(AAmount: Integer);
    procedure AddChanged(var AChanged: TCellPosArray;
      Col, Row: Integer);
  public
    constructor Create(ADifficulty: TDifficulty);
    procedure StartNewGame;

    /// <summary>
    ///   Открывает клетку. Возвращает список изменившихся клеток.
    /// </summary>
    function OpenCell(Col, Row: Integer): TCellPosArray;

    /// <summary>
    ///   Ставит/снимает флажок. Возвращает список изменившихся клеток.
    /// </summary>
    function ToggleFlag(Col, Row: Integer): TCellPosArray;

    procedure TickTimer;
    function GetCell(Col, Row: Integer): TCell;
    function InBounds(Col, Row: Integer): Boolean;
    function IsGameOver: Boolean;
    function GameStarted: Boolean;

    property Cols: Integer read FCols;
    property Rows: Integer read FRows;
    property MineCount: Integer read FMineCount;
    property RewardedMines: Integer read FRewardedMines;
    property Score: Integer read FScore;
    property ScoreMultiplier: Integer read FScoreMultiplier;
    property TimerPenalty: Integer read FTimerPenalty;
    property TimerIntervalSec: Integer read FTimerIntervalSec;
    property State: TGameState read FState;
    property OnStateChanged: TNotifyEvent
      read FOnStateChanged write FOnStateChanged;
    property OnGameOver: TNotifyEvent
      read FOnGameOver write FOnGameOver;
  end;

implementation

{ TGameLogic }

constructor TGameLogic.Create(ADifficulty: TDifficulty);
begin
  inherited Create;
  FSettings := DIFFICULTIES[ADifficulty];
  FCols := FSettings.Cols;
  FRows := FSettings.Rows;
  FMineCount := FSettings.Mines;
  FScoreMultiplier := FSettings.ScoreMultiplier;
  FTimerPenalty := FSettings.TimerPenalty;
  FTimerIntervalSec := FSettings.TimerIntervalSec;
  SetLength(FGrid, FRows, FCols);
  FSafeCount := FCols * FRows - FMineCount;
  StartNewGame;
end;

procedure TGameLogic.StartNewGame;
var
  C, R: Integer;
begin
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
    begin
      FGrid[R, C].IsMine := False;
      FGrid[R, C].MinesAround := 0;
      FGrid[R, C].State := csHidden;
      FGrid[R, C].Rewarded := False;
    end;
  FScore := 0;
  FState := gsPlaying;
  FFirstClick := True;
  FOpenedCount := 0;
  FRewardedMines := 0;
  DoStateChanged;
end;

function TGameLogic.InBounds(Col, Row: Integer): Boolean;
begin
  Result := (Col >= 0) and (Col < FCols) and
            (Row >= 0) and (Row < FRows);
end;

function TGameLogic.IsGameOver: Boolean;
begin
  Result := FState <> gsPlaying;
end;

function TGameLogic.GameStarted: Boolean;
begin
  Result := not FFirstClick;
end;

procedure TGameLogic.DoStateChanged;
begin
  if Assigned(FOnStateChanged) then
    FOnStateChanged(Self);
end;

procedure TGameLogic.DoGameOver;
begin
  if Assigned(FOnGameOver) then
    FOnGameOver(Self);
end;

procedure TGameLogic.AddScore(AAmount: Integer);
begin
  Inc(FScore, AAmount);
  if FScore < 0 then FScore := 0;
end;

procedure TGameLogic.AddChanged(var AChanged: TCellPosArray;
  Col, Row: Integer);
var
  N: Integer;
begin
  N := Length(AChanged);
  SetLength(AChanged, N + 1);
  AChanged[N].Col := Col;
  AChanged[N].Row := Row;
end;

procedure TGameLogic.TickTimer;
begin
  if FState <> gsPlaying then Exit;
  if FFirstClick then Exit;
  AddScore(-FTimerPenalty);
  // Поле не меняется — DoStateChanged не нужен.
  // MainForm сам обновит индикатор очков.
end;

function TGameLogic.CountMinesAround(Col, Row: Integer): Byte;
var
  DC, DR: Integer;
begin
  Result := 0;
  for DR := -1 to 1 do
    for DC := -1 to 1 do
    begin
      if (DC = 0) and (DR = 0) then Continue;
      if not InBounds(Col + DC, Row + DR) then Continue;
      if FGrid[Row + DR, Col + DC].IsMine then Inc(Result);
    end;
end;

procedure TGameLogic.GenerateField(FirstClickCol, FirstClickRow: Integer);
var
  C, R: Integer;
  Available: TArray<TPoint>;
  I, J: Integer;
  Tmp: TPoint;
  IsSafeZone: Boolean;
begin
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
    begin
      FGrid[R, C].IsMine := False;
      FGrid[R, C].MinesAround := 0;
      FGrid[R, C].State := csHidden;
      FGrid[R, C].Rewarded := False;
    end;

  SetLength(Available, 0);
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
    begin
      IsSafeZone := (Abs(C - FirstClickCol) <= 1) and
                    (Abs(R - FirstClickRow) <= 1);
      if IsSafeZone then Continue;
      SetLength(Available, Length(Available) + 1);
      Available[High(Available)] := Point(C, R);
    end;

  if Length(Available) < FMineCount then
    raise Exception.CreateFmt(
      'Невозможно расставить %d мин: доступно только %d позиций',
      [FMineCount, Length(Available)]);

  for I := High(Available) downto 1 do
  begin
    J := Random(I + 1);
    Tmp := Available[I];
    Available[I] := Available[J];
    Available[J] := Tmp;
  end;

  for I := 0 to FMineCount - 1 do
  begin
    C := Available[I].X;
    R := Available[I].Y;
    FGrid[R, C].IsMine := True;
  end;

  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      FGrid[R, C].MinesAround := CountMinesAround(C, R);
end;

function TGameLogic.OpenCell(Col, Row: Integer): TCellPosArray;
var
  Cell: ^TCell;
begin
  SetLength(Result, 0);
  if FState <> gsPlaying then Exit;
  if not InBounds(Col, Row) then Exit;
  Cell := @FGrid[Row, Col];
  if Cell.State <> csHidden then Exit;

  if FFirstClick then
  begin
    GenerateField(Col, Row);
    FFirstClick := False;
  end;

  if Cell.IsMine then
  begin
    Cell.State := csOpened;
    AddChanged(Result, Col, Row);
    FState := gsLost;
    // При проигрыше MainForm перерисует всё поле — не нужно
    // возвращать список всех мин. Но DoGameOver сообщит.
    DoGameOver;
    Exit;
  end;

  OpenCellRecursive(Col, Row, Result);
  CheckPendingMines(Result);
  CheckWin;
end;

procedure TGameLogic.OpenCellRecursive(Col, Row: Integer;
  var AChanged: TCellPosArray);
var
  Cell: ^TCell;
  DC, DR: Integer;
begin
  if not InBounds(Col, Row) then Exit;
  Cell := @FGrid[Row, Col];
  if Cell.State <> csHidden then Exit;
  if Cell.IsMine then Exit;

  Cell.State := csOpened;
  Inc(FOpenedCount);
  AddChanged(AChanged, Col, Row);

  if Cell.MinesAround > 0 then
    AddScore(Cell.MinesAround * FScoreMultiplier)
  else
  begin
    for DR := -1 to 1 do
      for DC := -1 to 1 do
      begin
        if (DC = 0) and (DR = 0) then Continue;
        OpenCellRecursive(Col + DC, Row + DR, AChanged);
      end;
  end;
end;

function TGameLogic.ToggleFlag(Col, Row: Integer): TCellPosArray;
var
  Cell: ^TCell;
begin
  SetLength(Result, 0);
  if FState <> gsPlaying then Exit;
  if not InBounds(Col, Row) then Exit;
  if FFirstClick then Exit;

  Cell := @FGrid[Row, Col];
  if Cell.State = csOpened then Exit;

  case Cell.State of
    csHidden:
      begin
        Cell.State := csFlagged;
        AddChanged(Result, Col, Row);
        if Cell.IsMine then
          CheckPendingMines(Result);
      end;
    csFlagged:
      begin
        if Cell.Rewarded then Exit;
        Cell.State := csHidden;
        AddChanged(Result, Col, Row);
      end;
  end;

  CheckWin;
end;

function TGameLogic.AllNeighborsKnown(Col, Row: Integer): Boolean;
var
  DC, DR: Integer;
  NC, NR: Integer;
begin
  Result := True;
  for DR := -1 to 1 do
    for DC := -1 to 1 do
    begin
      if (DC = 0) and (DR = 0) then Continue;
      NC := Col + DC;
      NR := Row + DR;
      if not InBounds(NC, NR) then Continue;
      if FGrid[NR, NC].State = csHidden then Exit(False);
    end;
end;

function TGameLogic.MaxOpenNeighborNumber(Col, Row: Integer): Integer;
var
  DC, DR: Integer;
  NC, NR: Integer;
  NCell: TCell;
  MaxVal: Integer;
begin
  MaxVal := 0;
  for DR := -1 to 1 do
    for DC := -1 to 1 do
    begin
      if (DC = 0) and (DR = 0) then Continue;
      NC := Col + DC;
      NR := Row + DR;
      if not InBounds(NC, NR) then Continue;
      NCell := FGrid[NR, NC];
      if NCell.State <> csOpened then Continue;
      if NCell.MinesAround > MaxVal then
        MaxVal := NCell.MinesAround;
    end;
  Result := MaxVal;
end;

procedure TGameLogic.CheckPendingMines(var AChanged: TCellPosArray);
var
  C, R: Integer;
  Cell: ^TCell;
  MaxNum: Integer;
begin
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
    begin
      Cell := @FGrid[R, C];
      if Cell.State <> csFlagged then Continue;
      if not Cell.IsMine then Continue;
      if Cell.Rewarded then Continue;
      if not AllNeighborsKnown(C, R) then Continue;
      MaxNum := MaxOpenNeighborNumber(C, R);
      AddScore(MaxNum * FScoreMultiplier);
      Cell.Rewarded := True;
      Inc(FRewardedMines);
      AddChanged(AChanged, C, R);
    end;
end;

procedure TGameLogic.CheckWin;
var
  C, R: Integer;
  Cell: TCell;
begin
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
    begin
      Cell := FGrid[R, C];
      if Cell.IsMine then
      begin
        if (Cell.State <> csFlagged) or (not Cell.Rewarded) then
          Exit;
      end
      else
      begin
        if Cell.State <> csOpened then Exit;
      end;
    end;
  FState := gsWon;
  DoGameOver;
end;

function TGameLogic.GetCell(Col, Row: Integer): TCell;
begin
  if InBounds(Col, Row) then
    Result := FGrid[Row, Col]
  else
  begin
    Result.IsMine := False;
    Result.MinesAround := 0;
    Result.State := csHidden;
    Result.Rewarded := False;
  end;
end;

initialization
  Randomize;

end.
