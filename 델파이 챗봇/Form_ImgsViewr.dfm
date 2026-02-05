object FormImgsViewr: TFormImgsViewr
  Left = 376
  Top = 178
  Width = 1099
  Height = 739
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'FormImgsViewr'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object AdvSmoothPanel8: TAdvSmoothPanel
    Left = 0
    Top = 0
    Width = 1083
    Height = 700
    Cursor = crDefault
    Caption.HTMLFont.Charset = DEFAULT_CHARSET
    Caption.HTMLFont.Color = clWindowText
    Caption.HTMLFont.Height = -11
    Caption.HTMLFont.Name = 'Tahoma'
    Caption.HTMLFont.Style = []
    Caption.Font.Charset = DEFAULT_CHARSET
    Caption.Font.Color = clWindowText
    Caption.Font.Height = -16
    Caption.Font.Name = 'Tahoma'
    Caption.Font.Style = []
    Fill.Color = 16445929
    Fill.ColorTo = 15587527
    Fill.ColorMirror = 15587527
    Fill.ColorMirrorTo = 16773863
    Fill.GradientType = gtVertical
    Fill.GradientMirrorType = gtVertical
    Fill.BorderColor = 14922381
    Fill.Rounding = 3
    Fill.ShadowColor = clNone
    Fill.ShadowOffset = 10
    Fill.Glow = gmNone
    Version = '1.1.0.0'
    Align = alClient
    TabOrder = 0
    object Img3_Views: TImage
      Left = 0
      Top = 0
      Width = 1083
      Height = 700
      Align = alClient
      PopupMenu = Apm3_ISAVE
      Stretch = True
      OnDblClick = Img3_ViewsDblClick
    end
  end
  object Apm3_ISAVE: TAdvPopupMenu
    Version = '2.5.4.0'
    Left = 120
    Top = 74
    object NImage01: TMenuItem
      Caption = #51060#48120#51648' '#51200#51109
      OnClick = NImage01Click
    end
  end
  object ODig_Open1: TOpenDialog
    Left = 160
    Top = 73
  end
end
