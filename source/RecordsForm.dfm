object FormRecords: TFormRecords
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1056#1077#1082#1086#1088#1076#1099
  ClientHeight = 560
  ClientWidth = 520
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
  object lvRecords: TListView
    Left = 16
    Top = 16
    Width = 488
    Height = 460
    Columns = <>
    TabOrder = 0
  end
  object lblMessage: TLabel
    Left = 16
    Top = 484
    Width = 488
    Height = 50
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGrayText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object btnOK: TButton
    Left = 420
    Top = 520
    Width = 84
    Height = 30
    Caption = #1054#1050
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
end