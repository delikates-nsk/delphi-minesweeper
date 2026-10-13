object FormName: TFormName
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1053#1086#1074#1099#1081' '#1088#1077#1082#1086#1088#1076'!'
  ClientHeight = 140
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  Scaled = False
  TextHeight = 15
  object lblPrompt: TLabel
    Left = 16
    Top = 16
    Width = 103
    Height = 15
    Caption = #1042#1074#1077#1076#1080#1090#1077' '#1074#1072#1096#1077' '#1080#1084#1103':'
  end
  object edName: TEdit
    Left = 16
    Top = 44
    Width = 368
    Height = 23
    TabOrder = 0
  end
  object btnOK: TButton
    Left = 204
    Top = 92
    Width = 84
    Height = 30
    Caption = #1054#1050
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 300
    Top = 92
    Width = 84
    Height = 30
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 2
  end
end
