unit RecordsManager;

/// <summary>
///   Управляет таблицей рекордов (топ-30).
///   Файл records.dat хранится рядом с .exe, шифруется XOR
///   и защищён CRC32 от подправки.
///   Файл блокируется эксклюзивно при старте игры.
/// </summary>
interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.DateUtils,
  System.JSON, System.ZLib,
  FileUtils;

const
  /// <summary>Максимальное количество записей в таблице.</summary>
  MAX_RECORDS = 30;

  /// <summary>Сигнатура файла records.dat ('SREC').</summary>
  FILE_MAGIC = $43455253;

  /// <summary>Версия формата файла.</summary>
  FILE_VERSION = 1;

  /// <summary>
  ///   Ключ XOR-шифрования. Не является секретом в полном смысле —
  ///   защищает от подправки файла блокнотом, а не от реверса .exe.
  /// </summary>
  RECORDS_KEY = 'MineSweeper_2026_#42_XOR_Secret_Key';

type
  /// <summary>
  ///   Одна запись в таблице рекордов.
  /// </summary>
  TRecordEntry = record
    Score: Integer;       // очки
    PlayerName: string;   // имя игрока
    Date: TDateTime;      // дата установления рекорда
  end;

  /// <summary>
  ///   Таблица рекордов: динамический массив записей.
  /// </summary>
  TRecordList = array of TRecordEntry;

  /// <summary>
  ///   Управляет рекордами: загрузка, сохранение, добавление.
  /// </summary>
  TRecordsManager = class
  private
    FFileName: string;       // полный путь к records.dat
    FFileStream: TFileStream;// открытый поток — держит файл заблокированным
    FRecords: TRecordList;   // таблица рекордов в памяти
    FLocked: Boolean;        // удалось ли заблокировать файл
    FLoadError: Boolean;     // была ли ошибка при загрузке

    procedure SetDefaultRecords;
    procedure SortRecords;
    function ToJSON: string;
    function FromJSON(const AJson: string): Boolean;
    function Serialize: TBytes;
    function Deserialize(const AData: TBytes): Boolean;
    function CalculateChecksum(const AData: TBytes): Cardinal;
    function XorBytes(const AData: TBytes): TBytes;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

    function Load: Boolean;
    function Save: Boolean;
    function IsTopScore(AScore: Integer): Boolean;
    function AddRecord(AScore: Integer;
      const APlayerName: string): Integer;
    function GetAllRecords: TRecordList;
    function GetCount: Integer;

    property Locked: Boolean read FLocked;
    property LoadError: Boolean read FLoadError;
    property FileName: string read FFileName;
  end;

implementation

{ TRecordsManager }

constructor TRecordsManager.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  FFileStream := nil;
  FLocked := False;
  FLoadError := False;
  SetDefaultRecords;
end;

destructor TRecordsManager.Destroy;
begin
  FFileStream.Free;
  inherited;
end;

procedure TRecordsManager.SetDefaultRecords;
begin
  SetLength(FRecords, 0);
end;

procedure TRecordsManager.SortRecords;
var
  I, J: Integer;
  Tmp: TRecordEntry;
begin
  for I := 1 to High(FRecords) do
  begin
    Tmp := FRecords[I];
    J := I - 1;
    while (J >= 0) and (FRecords[J].Score < Tmp.Score) do
    begin
      FRecords[J + 1] := FRecords[J];
      Dec(J);
    end;
    FRecords[J + 1] := Tmp;
  end;
end;

function TRecordsManager.Load: Boolean;
var
  FileData: TBytes;
  FileSize: Int64;
begin
  Result := False;
  FLoadError := False;
  SetDefaultRecords;
  try
    if TFile.Exists(FFileName) then
      FFileStream := TFileStream.Create(FFileName,
        fmOpenReadWrite or fmShareExclusive)
    else
      FFileStream := TFileStream.Create(FFileName,
        fmCreate or fmOpenReadWrite or fmShareExclusive);
    FLocked := True;
  except
    on E: Exception do
    begin
      FFileStream := nil;
      FLocked := False;
      FLoadError := True;
      Exit(False);
    end;
  end;
  try
    FileSize := FFileStream.Size;
    if FileSize > 0 then
    begin
      SetLength(FileData, FileSize);
      FFileStream.Position := 0;
      FFileStream.ReadBuffer(FileData[0], FileSize);
      Result := Deserialize(FileData);
    end
    else
      Result := True;
  except
    on E: Exception do
    begin
      SetDefaultRecords;
      Result := False;
    end;
  end;
end;

function TRecordsManager.Save: Boolean;
var
  Data: TBytes;
begin
  Result := False;
  if FFileStream = nil then Exit;
  try
    Data := Serialize;
    FFileStream.Size := 0;
    FFileStream.Position := 0;
    if Length(Data) > 0 then
      FFileStream.WriteBuffer(Data[0], Length(Data));
    Result := True;
  except
    Result := False;
  end;
end;

function TRecordsManager.IsTopScore(AScore: Integer): Boolean;
begin
  if Length(FRecords) < MAX_RECORDS then
    Exit(True);
  Result := AScore > FRecords[High(FRecords)].Score;
end;

function TRecordsManager.AddRecord(AScore: Integer;
  const APlayerName: string): Integer;
var
  NewEntry: TRecordEntry;
  I: Integer;
begin
  Result := -1;
  if not IsTopScore(AScore) then Exit;

  NewEntry.Score := AScore;
  NewEntry.PlayerName := APlayerName;
  NewEntry.Date := Now;

  SetLength(FRecords, Length(FRecords) + 1);
  FRecords[High(FRecords)] := NewEntry;
  SortRecords;

  for I := 0 to High(FRecords) do
    if FRecords[I].Date = NewEntry.Date then
    begin
      Result := I;
      Break;
    end;

  if Length(FRecords) > MAX_RECORDS then
    SetLength(FRecords, MAX_RECORDS);
end;

function TRecordsManager.GetAllRecords: TRecordList;
begin
  Result := Copy(FRecords, 0, Length(FRecords));
end;

function TRecordsManager.GetCount: Integer;
begin
  Result := Length(FRecords);
end;

function TRecordsManager.ToJSON: string;
var
  Root, RecObj: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('version', TJSONNumber.Create(FILE_VERSION));
    Arr := TJSONArray.Create;
    for I := 0 to High(FRecords) do
    begin
      RecObj := TJSONObject.Create;
      RecObj.AddPair('score', TJSONNumber.Create(FRecords[I].Score));
      RecObj.AddPair('name', FRecords[I].PlayerName);
      RecObj.AddPair('date',
        FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', FRecords[I].Date));
      Arr.AddElement(RecObj);
    end;
    Root.AddPair('records', Arr);
    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

function TRecordsManager.FromJSON(const AJson: string): Boolean;
var
  Root, RecObj: TJSONObject;
  Arr: TJSONArray;
  Value: TJSONValue;
  I: Integer;
  DateStr: string;
begin
  Result := False;
  SetDefaultRecords;
  Value := TJSONObject.ParseJSONValue(AJson);
  if not (Value is TJSONObject) then
  begin
    Value.Free;
    Exit;
  end;
  Root := TJSONObject(Value);
  try
    if not (Root.GetValue('records') is TJSONArray) then Exit;
    Arr := TJSONArray(Root.GetValue('records'));
    SetLength(FRecords, Arr.Count);
    for I := 0 to Arr.Count - 1 do
    begin
      if not (Arr.Items[I] is TJSONObject) then Continue;
      RecObj := TJSONObject(Arr.Items[I]);
      FRecords[I].Score := RecObj.GetValue('score').AsType<Integer>;
      FRecords[I].PlayerName := RecObj.GetValue('name').Value;
      DateStr := RecObj.GetValue('date').Value;
      FRecords[I].Date := ISO8601ToDate(DateStr, False);
    end;
    Result := True;
  finally
    Root.Free;
  end;
end;

function TRecordsManager.XorBytes(const AData: TBytes): TBytes;
var
  KeyBytes: TBytes;
  I: Integer;
begin
  KeyBytes := TEncoding.UTF8.GetBytes(RECORDS_KEY);
  SetLength(Result, Length(AData));
  for I := 0 to High(AData) do
    Result[I] := AData[I] xor KeyBytes[I mod Length(KeyBytes)];
end;

function TRecordsManager.CalculateChecksum(
  const AData: TBytes): Cardinal;
begin
  if Length(AData) = 0 then
    Result := 0
  else
    Result := crc32(0, @AData[0], Length(AData));
end;

function TRecordsManager.Serialize: TBytes;
var
  JsonBytes: TBytes;
  XorData: TBytes;
  CheckSum: Cardinal;
  Header: array[0..2] of Cardinal;
  TotalSize: Integer;
begin
  JsonBytes := TEncoding.UTF8.GetBytes(ToJSON);
  CheckSum := CalculateChecksum(JsonBytes);
  XorData := XorBytes(JsonBytes);
  Header[0] := FILE_MAGIC;
  Header[1] := FILE_VERSION;
  Header[2] := Length(XorData);
  TotalSize := SizeOf(Header) + Length(XorData) + SizeOf(CheckSum);
  SetLength(Result, TotalSize);
  Move(Header[0], Result[0], SizeOf(Header));
  if Length(XorData) > 0 then
    Move(XorData[0], Result[SizeOf(Header)], Length(XorData));
  Move(CheckSum, Result[SizeOf(Header) + Length(XorData)],
    SizeOf(CheckSum));
end;

function TRecordsManager.Deserialize(const AData: TBytes): Boolean;
var
  Header: array[0..2] of Cardinal;
  XorData: TBytes;
  JsonBytes: TBytes;
  StoredCheckSum: Cardinal;
  CalculatedCheckSum: Cardinal;
  JsonStr: string;
  HeaderSize: Integer;
begin
  Result := False;
  SetDefaultRecords;
  HeaderSize := SizeOf(Header);
  if Length(AData) < HeaderSize + SizeOf(Cardinal) then Exit;
  Move(AData[0], Header[0], HeaderSize);
  if Header[0] <> FILE_MAGIC then Exit;
  if Header[1] <> FILE_VERSION then Exit;
  if Length(AData) < HeaderSize + Integer(Header[2]) +
    SizeOf(Cardinal) then Exit;
  SetLength(XorData, Header[2]);
  if Header[2] > 0 then
    Move(AData[HeaderSize], XorData[0], Header[2]);
  Move(AData[HeaderSize + Integer(Header[2])], StoredCheckSum,
    SizeOf(Cardinal));
  JsonBytes := XorBytes(XorData);
  CalculatedCheckSum := CalculateChecksum(JsonBytes);
  if CalculatedCheckSum <> StoredCheckSum then Exit;
  JsonStr := TEncoding.UTF8.GetString(JsonBytes);
  Result := FromJSON(JsonStr);
end;

end.
