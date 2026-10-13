program minesweeper;

uses
  System.SysUtils,
  Winapi.Windows,
  Vcl.Forms,
  MainForm in 'source\MainForm.pas' {FormMain},
  SettingsForm in 'source\SettingsForm.pas' {FormSettings},
  RecordsForm in 'source\RecordsForm.pas' {FormRecords},
  AboutForm in 'source\AboutForm.pas' {FormAbout},
  NameForm in 'source\NameForm.pas' {FormName},
  Settings in 'source\models\Settings.pas',
  FileUtils in 'source\models\FileUtils.pas',
  RecordsManager in 'source\models\RecordsManager.pas',
  GameLogic in 'source\models\GameLogic.pas',
  DigitRenderer in 'source\models\DigitRenderer.pas',
  FieldRenderer in 'source\models\FieldRenderer.pas';

{$R *.res}

const
  MUTEX_NAME = 'SupperEnergy_SingleInstance_Mutex_2026';
  WINDOW_TITLE = 'Сапёр';

function IsAlreadyRunning: Boolean;
var
  Mutex: THandle;
  Wnd: HWND;
begin
  Mutex := CreateMutex(nil, False, MUTEX_NAME);
  Result := (Mutex <> 0) and (GetLastError = ERROR_ALREADY_EXISTS);
  if Result then
  begin
    Wnd := FindWindow(nil, WINDOW_TITLE);
    if Wnd <> 0 then
    begin
      if IsIconic(Wnd) then
        ShowWindow(Wnd, SW_RESTORE);
      SetForegroundWindow(Wnd);
    end;
  end;
end;

begin
  if IsAlreadyRunning then
    Exit;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := WINDOW_TITLE;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
