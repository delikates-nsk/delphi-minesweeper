unit FileUtils;

/// <summary>
///   Утилиты для работы с файлами и папками.
///   Не зависит от игровой логики — используется всеми модулями.
///   Все runtime-файлы (minesweeper.ini, records.dat) хранятся
///   в папке рядом с .exe.
/// </summary>
interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

type
  TFileUtils = class
  public
    /// <summary>
    ///   Возвращает полный путь к папке, в которой находится
    ///   исполняемый файл (.exe), с завершающим разделителем пути.
    /// </summary>
    class function ExeDir: string;

    /// <summary>
    ///   Проверяет, можно ли записывать файлы в указанную папку.
    /// </summary>
    class function CanWriteToDir(const ADir: string;
      out AError: string): Boolean;

    /// <summary>
    ///   Проверяет, можно ли записывать в папку, где лежит .exe.
    /// </summary>
    class function CanWriteToExeDir(out AError: string): Boolean;

    /// <summary>
    ///   Безопасно записывает текст в файл, полностью перезаписывая его.
    /// </summary>
    class function TryWriteText(const AFileName, AText: string;
      out AError: string): Boolean;

    /// <summary>
    ///   Безопасно добавляет одну строку в конец файла (append).
    /// </summary>
    class function TryAppendLine(const AFileName, ALine: string;
      out AError: string): Boolean;

    /// <summary>
    ///   Возвращает полный путь к файлу в папке с .exe.
    /// </summary>
    class function ExeFile(const AFileName: string): string;
  end;

implementation

uses
  Winapi.Windows;

{ TFileUtils }

class function TFileUtils.ExeDir: string;
var
  Buf: array[0..MAX_PATH - 1] of Char;
  Len: Cardinal;
begin
  Len := GetModuleFileName(0, Buf, MAX_PATH);
  if Len = 0 then
    Result := ''
  else
    Result := ExtractFilePath(string(Buf));
end;

class function TFileUtils.ExeFile(const AFileName: string): string;
begin
  Result := TPath.Combine(ExeDir, AFileName);
end;

class function TFileUtils.CanWriteToDir(const ADir: string;
  out AError: string): Boolean;
var
  TestFile: string;
  SW: TStreamWriter;
begin
  AError := '';
  Result := False;
  try
    if not TDirectory.Exists(ADir) then
    begin
      AError := 'Папка не существует: ' + ADir;
      Exit;
    end;
    TestFile := TPath.Combine(ADir, '__write_test__.tmp');
    SW := TStreamWriter.Create(TestFile, False, TEncoding.UTF8);
    try
      SW.Write('x');
    finally
      SW.Free;
    end;
    TFile.Delete(TestFile);
    Result := True;
  except
    on E: Exception do
    begin
      AError := E.Message;
      Result := False;
    end;
  end;
end;

class function TFileUtils.CanWriteToExeDir(out AError: string): Boolean;
begin
  Result := CanWriteToDir(ExeDir, AError);
end;

class function TFileUtils.TryWriteText(const AFileName, AText: string;
  out AError: string): Boolean;
var
  SW: TStreamWriter;
  Dir: string;
begin
  AError := '';
  Result := False;
  try
    Dir := TPath.GetDirectoryName(AFileName);
    if (Dir <> '') and (not TDirectory.Exists(Dir)) then
      TDirectory.CreateDirectory(Dir);
    SW := TStreamWriter.Create(AFileName, False, TEncoding.UTF8);
    try
      SW.Write(AText);
    finally
      SW.Free;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      AError := E.Message;
      Result := False;
    end;
  end;
end;

class function TFileUtils.TryAppendLine(const AFileName, ALine: string;
  out AError: string): Boolean;
var
  SW: TStreamWriter;
  Dir: string;
begin
  AError := '';
  Result := False;
  try
    Dir := TPath.GetDirectoryName(AFileName);
    if (Dir <> '') and (not TDirectory.Exists(Dir)) then
      TDirectory.CreateDirectory(Dir);
    SW := TStreamWriter.Create(AFileName, True, TEncoding.UTF8);
    try
      SW.WriteLine(ALine);
    finally
      SW.Free;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      AError := E.Message;
      Result := False;
    end;
  end;
end;

end.