object USBLPWRMain: TUSBLPWRMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'USB Lockit PW Recovery'
  ClientHeight = 106
  ClientWidth = 331
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 115
    Top = 77
    Width = 38
    Height = 13
    Caption = 'Manual:'
  end
  object PWEdit: TEdit
    Left = 8
    Top = 45
    Width = 313
    Height = 21
    ReadOnly = True
    TabOrder = 0
    Text = 'Select Drive and Click Recover....'
  end
  object RecoveryBtn: TButton
    Left = 8
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Recover'
    TabOrder = 1
    OnClick = RecoveryBtnClick
  end
  object DriveCBox: TComboBox
    Left = 8
    Top = 16
    Width = 225
    Height = 21
    TabOrder = 2
  end
  object RefreshBtn: TButton
    Left = 246
    Top = 14
    Width = 75
    Height = 25
    Caption = 'Refresh'
    TabOrder = 3
    OnClick = RefreshBtnClick
  end
  object ManualBtn: TButton
    Left = 246
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Manual'
    TabOrder = 4
    OnClick = ManualBtnClick
  end
  object ManualEdit: TEdit
    Left = 159
    Top = 74
    Width = 74
    Height = 21
    CharCase = ecLowerCase
    MaxLength = 8
    TabOrder = 5
    OnKeyPress = ManualEditKeyPress
  end
end
