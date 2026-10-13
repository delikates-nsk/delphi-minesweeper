unit Settings;

/// <summary>
///   Все настройки игры: сложности, параметры приложения, оформление.
///   Чтение и запись .ini-файла рядом с .exe.
/// </summary>
interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.IOUtils,
  System.Types, Vcl.Graphics,
  FileUtils;

type
  /// <summary>
  ///   Уровень сложности игры.
  /// </summary>
  TDifficulty = (dNewbie, dAmateur, dExpert, dInsane);

  /// <summary>
  ///   Параметры одной сложности.
  /// </summary>
  TDifficultySettings = record
    Name: string;            // отображаемое имя
    Description: string;     // многострочное описание
    Cols: Integer;           // столбцов
    Rows: Integer;           // строк
    Mines: Integer;          // мин
    ScoreMultiplier: Integer;// множитель очков
    TimerPenalty: Integer;   // снимаемых очков за тик
    TimerIntervalSec: Integer;// интервал тика (сек)
  end;

const
 /// <summary>Минимальная ширина одного индикатора.</summary>
  INDICATOR_MIN_WIDTH = 130;

  /// <summary>Высота одного индикатора.</summary>
  INDICATOR_HEIGHT = 50;

  /// <summary>Отступ между индикаторами.</summary>
  INDICATOR_SPACING = 8;

  /// <summary>Высота панели с ОДНИМ рядом индикаторов.</summary>
  PANEL_HEIGHT_ONE_ROW = 70;

  /// <summary>Высота панели с ДВУМЯ рядами индикаторов.</summary>
  PANEL_HEIGHT_TWO_ROWS = 130;

  DIFFICULTIES: array[TDifficulty] of TDifficultySettings = (
    (Name: 'Новичок';
     Description: 'Поле 12×7, 12 мин, множитель x1.' + sLineBreak +
                  'Таймер: −1 очко каждые 4 секунды.' + sLineBreak +
                  'Для знакомства с игрой.';
     Cols: 12; Rows: 7; Mines: 12;
     ScoreMultiplier: 1;
     TimerPenalty: 1; TimerIntervalSec: 4),

    (Name: 'Любитель';
     Description: 'Поле 16×9, 22 мины, множитель x2.' + sLineBreak +
                  'Таймер: −2 очка каждые 3 секунды.' + sLineBreak +
                  'Основной режим для большинства игроков.';
     Cols: 16; Rows: 9; Mines: 22;
     ScoreMultiplier: 2;
     TimerPenalty: 2; TimerIntervalSec: 3),

    (Name: 'Эксперт';
     Description: 'Поле 20×12, 40 мин, множитель x3.' + sLineBreak +
                  'Таймер: −3 очка каждые 2 секунды.' + sLineBreak +
                  'Для опытных игроков. Требует скорости.';
     Cols: 20; Rows: 12; Mines: 40;
     ScoreMultiplier: 3;
     TimerPenalty: 3; TimerIntervalSec: 2),

    (Name: 'Безумец';
     Description: 'Поле 24×14, 60 мин, множитель x4.' + sLineBreak +
                  'Таймер: −4 очка каждую секунду.' + sLineBreak +
                  'Для маньяков. Каждая секунда на счету.';
     Cols: 24; Rows: 14; Mines: 60;
     ScoreMultiplier: 4;
     TimerPenalty: 4; TimerIntervalSec: 1)
  );

type
  /// <summary>
  ///   Настройки приложения, сохраняемые в .ini.
  /// </summary>
  TAppSettings = class
  private
    FFileName: string;
    FDifficulty: TDifficulty;
    FLastName: string;
    FLoaded: Boolean;
  public
    constructor Create(const AFileName: string);
    function Load: Boolean;
    function Save: Boolean;
    function Exists: Boolean;
    procedure SetDefaults;

    property Difficulty: TDifficulty read FDifficulty write FDifficulty;
    property LastName: string read FLastName write FLastName;
    property Loaded: Boolean read FLoaded;
    property FileName: string read FFileName;
  end;

const
  // Оформление
  CELL_SIZE = 24;
  BORDER_SIZE = 12;
  LAYOUT_PADDING = 10;
  PANEL_HEIGHT = 70;

  // Цвета клеток
  COLOR_CELL_HIDDEN = $00C0C0C0;
  COLOR_CELL_HIDDEN_LIGHT = $00E0E0E0;
  COLOR_CELL_HIDDEN_DARK = $00A0A0A0;
  COLOR_CELL_OPENED = $00E8E8E8;
  COLOR_CELL_OPENED_BORDER = $00A0A0A0;
  COLOR_CELL_MINE = $000000FF;
  COLOR_CELL_WRONG_FLAG = $008080FF;
  COLOR_FLAG = $000000C0;
  COLOR_CELL_PRESSED_LIGHT = $00A0A0A0;
  COLOR_CELL_PRESSED_DARK = $00E0E0E0;

  // Цвета цифр
  COLOR_NUM_1 = $00FF0000;
  COLOR_NUM_2 = $00008000;
  COLOR_NUM_3 = $000000FF;
  COLOR_NUM_4 = $00800000;
  COLOR_NUM_5 = $00000080;
  COLOR_NUM_6 = $00008080;
  COLOR_NUM_7 = $00000000;
  COLOR_NUM_8 = $00808080;

  // Цвета LCD
  LCD_ON_COLOR = $0000FF00;
  LCD_OFF_COLOR = $00202020;
  LCD_BG_COLOR = $00101010;
  LCD_SEGMENT_THICKNESS = 0.15;

implementation

{ TAppSettings }

constructor TAppSettings.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  SetDefaults;
end;

procedure TAppSettings.SetDefaults;
begin
  FDifficulty := dNewbie;
  FLastName := 'Игрок';
  FLoaded := False;
end;

function TAppSettings.Exists: Boolean;
begin
  Result := TFile.Exists(FFileName);
end;

function TAppSettings.Load: Boolean;
var
  Ini: TIniFile;
  DiffValue: Integer;
begin
  Result := False;
  SetDefaults;
  if not TFile.Exists(FFileName) then Exit;
  try
    Ini := TIniFile.Create(FFileName);
    try
      DiffValue := Ini.ReadInteger('Game', 'Difficulty', Ord(dNewbie));
      if (DiffValue < Ord(Low(TDifficulty))) or
         (DiffValue > Ord(High(TDifficulty))) then
        DiffValue := Ord(dNewbie);
      FDifficulty := TDifficulty(DiffValue);
      FLastName := Ini.ReadString('Player', 'LastName', 'Игрок');
      if FLastName = '' then FLastName := 'Игрок';
    finally
      Ini.Free;
    end;
    FLoaded := True;
    Result := True;
  except
    SetDefaults;
    Result := False;
  end;
end;

function TAppSettings.Save: Boolean;
var
  Ini: TIniFile;
begin
  Result := False;
  try
    Ini := TIniFile.Create(FFileName);
    try
      Ini.WriteInteger('Game', 'Difficulty', Ord(FDifficulty));
      Ini.WriteString('Player', 'LastName', FLastName);
    finally
      Ini.Free;
    end;
    FLoaded := True;
    Result := True;
  except
    Result := False;
  end;
end;

end.