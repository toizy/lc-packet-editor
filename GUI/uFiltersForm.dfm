object FiltersForm: TFiltersForm
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Filters'
  ClientHeight = 265
  ClientWidth = 338
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object rbIgnoreThese: TRadioButton
    Left = 8
    Top = 32
    Width = 169
    Height = 17
    Caption = 'Ignore these types'
    Checked = True
    TabOrder = 1
    TabStop = True
  end
  object rbIgnoreExcept: TRadioButton
    Left = 8
    Top = 56
    Width = 169
    Height = 17
    Caption = 'Ignore all types except'
    TabOrder = 2
  end
  object rbNoRules: TRadioButton
    Left = 8
    Top = 8
    Width = 169
    Height = 17
    Caption = 'No rules'
    TabOrder = 0
  end
  object lb: TListBox
    Left = 8
    Top = 104
    Width = 321
    Height = 153
    ItemHeight = 13
    TabOrder = 3
    OnKeyDown = lbKeyDown
  end
  object cbTypes: TComboBox
    Left = 8
    Top = 80
    Width = 321
    Height = 21
    Style = csDropDownList
    TabOrder = 4
    OnCloseUp = cbTypesCloseUp
  end
end
