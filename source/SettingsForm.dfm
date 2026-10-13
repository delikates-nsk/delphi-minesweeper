object FormSettings: TFormSettings
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1057#1083#1086#1078#1085#1086#1089#1090#1100
  ClientHeight = 520
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  Scaled = False
  OnCreate = FormCreate
  TextHeight = 15
  object lblNewbie: TLabel
    Left = 36
    Top = 40
    Width = 420
    Height = 60
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGrayText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    WordWrap = True
    OnClick = lblNewbieClick
  end
  object lblAmateur: TLabel
    Left = 36
    Top = 134
    Width = 420
    Height = 60
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGrayText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    WordWrap = True
    OnClick = lblAmateurClick
  end
  object lblExpert: TLabel
    Left = 36
    Top = 228
    Width = 420
    Height = 60
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGrayText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    WordWrap = True
    OnClick = lblExpertClick
  end
  object lblInsane: TLabel
    Left = 36
    Top = 322
    Width = 420
    Height = 60
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGrayText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    WordWrap = True
    OnClick = lblInsaneClick
  end
  object btnOK: TButton
    Left = 288
    Top = 470
    Width = 84
    Height = 30
    Caption = #1054#1050
    Default = True
    TabOrder = 0
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 380
    Top = 470
    Width = 84
    Height = 30
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 1
  end
  object rbNewbie: TRadioButton
    Left = 16
    Top = 16
    Width = 440
    Height = 20
    Caption = #1053#1086#1074#1080#1095#1086#1082
    TabOrder = 2
    TabStop = True
  end
  object rbAmateur: TRadioButton
    Left = 16
    Top = 110
    Width = 440
    Height = 20
    Caption = #1051#1102#1073#1080#1090#1077#1083#1100
    TabOrder = 3
    TabStop = True
  end
  object rbExpert: TRadioButton
    Left = 16
    Top = 204
    Width = 440
    Height = 20
    Caption = #1069#1082#1089#1087#1077#1088#1090
    TabOrder = 4
    TabStop = True
  end
  object rbInsane: TRadioButton
    Left = 16
    Top = 298
    Width = 440
    Height = 20
    Caption = #1041#1077#1079#1091#1084#1077#1094
    TabOrder = 5
    TabStop = True
  end
end
