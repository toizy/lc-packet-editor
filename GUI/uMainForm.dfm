object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Packet Editor GUI'
  ClientHeight = 424
  ClientWidth = 818
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  Position = poScreenCenter
  ShowHint = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object lv: TListView
    Left = 0
    Top = 0
    Width = 818
    Height = 204
    Align = alClient
    Columns = <
      item
        Caption = '#'
        Width = 40
      end
      item
        Caption = 'Type'
        Width = 100
      end
      item
        Caption = 'Size'
        Width = 35
      end
      item
        Caption = 'Login'
        Width = 40
      end
      item
        Caption = 'Index'
        Width = 70
      end
      item
        Caption = 'Bit'
        Width = 60
      end
      item
        Caption = 'Raw data'
        Width = 200
      end>
    DoubleBuffered = True
    GridLines = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    ParentDoubleBuffered = False
    PopupMenu = PopupMenu
    TabOrder = 0
    ViewStyle = vsReport
    OnChange = lvChange
    OnResize = lvResize
    ExplicitWidth = 814
    ExplicitHeight = 203
  end
  object p1: TPanel
    Left = 0
    Top = 204
    Width = 818
    Height = 220
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 203
    ExplicitWidth = 814
    object ebType: TLabeledEdit
      Left = 16
      Top = 21
      Width = 65
      Height = 21
      EditLabel.Width = 24
      EditLabel.Height = 13
      EditLabel.Caption = 'Type'
      TabOrder = 0
      Text = ''
      OnKeyPress = ebTypeKeyPress
    end
    object ebLogin: TLabeledEdit
      Left = 255
      Top = 21
      Width = 65
      Height = 21
      EditLabel.Width = 25
      EditLabel.Height = 13
      EditLabel.Caption = 'Login'
      TabOrder = 1
      Text = ''
    end
    object ebIndex: TLabeledEdit
      Left = 326
      Top = 21
      Width = 82
      Height = 21
      EditLabel.Width = 28
      EditLabel.Height = 13
      EditLabel.Caption = 'Index'
      TabOrder = 2
      Text = ''
    end
    object ebBit: TLabeledEdit
      Left = 414
      Top = 21
      Width = 83
      Height = 21
      EditLabel.Width = 12
      EditLabel.Height = 13
      EditLabel.Caption = 'Bit'
      TabOrder = 3
      Text = ''
      OnKeyPress = ebBitKeyPress
    end
    object Memo: TMemo
      Left = 16
      Top = 48
      Width = 481
      Height = 121
      ScrollBars = ssVertical
      TabOrder = 4
      OnKeyPress = MemoKeyPress
    end
    object ebTypeString: TLabeledEdit
      Left = 87
      Top = 21
      Width = 162
      Height = 21
      EditLabel.Width = 54
      EditLabel.Height = 13
      EditLabel.Caption = 'Type string'
      ReadOnly = True
      TabOrder = 5
      Text = ''
    end
    object cbPacketActions: TComboBox
      Left = 16
      Top = 175
      Width = 201
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 6
      Text = '<No action>'
      Items.Strings = (
        '<No action>'
        '[1] Rebuild'
        '[2] Resend'
        '[3] Save to...')
    end
    object bActionOnPacket: TButton
      Left = 223
      Top = 175
      Width = 97
      Height = 21
      Caption = 'Execute action'
      TabOrder = 7
      OnClick = bActionOnPacketClick
    end
    object pb: TProgressBar
      Left = 326
      Top = 175
      Width = 171
      Height = 21
      TabOrder = 8
    end
    object tvStruct: TTreeView
      Left = 512
      Top = 8
      Width = 297
      Height = 201
      Indent = 19
      TabOrder = 9
      Items.NodeData = {
        0301000000620000000000000000000000FFFFFFFFFFFFFFFF00000000000000
        000000000001224400650063006F006400650064002000730074007200750063
        0074007500720065007300200061007000700065006100720073002000680065
        00720065002E002E002E00}
    end
  end
  object MainMenu: TMainMenu
    Left = 592
    Top = 144
    object nWindow: TMenuItem
      Caption = 'Window'
      object nPickAWindow: TMenuItem
        Caption = 'Pick a window'
        object mniRefreshList: TMenuItem
          Caption = 'Refresh list'
          ShortCut = 16466
          OnClick = mniRefreshListClick
        end
        object N1: TMenuItem
          Caption = '-'
        end
      end
    end
    object nSocket: TMenuItem
      Caption = 'Socket'
      object mnPause: TMenuItem
        Caption = 'Pause'
        OnClick = mnPauseClick
      end
      object Filters1: TMenuItem
        Caption = 'Filters'
        OnClick = Filters1Click
      end
    end
  end
  object PopupMenu: TPopupMenu
    Left = 664
    Top = 144
    object nIgnoreThisType: TMenuItem
      Caption = 'Ignore this type'
      OnClick = nIgnoreThisTypeClick
    end
    object nGetJSONOfPacket: TMenuItem
      Caption = 'Get JSON of the packet to clipboard'
      OnClick = nGetJSONOfPacketClick
    end
    object mniDecodeStructure: TMenuItem
      Caption = 'Decode structure'
      OnClick = mniDecodeStructureClick
    end
  end
end
