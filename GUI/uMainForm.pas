unit uMainForm;

interface

uses
	Winapi.Windows,
	Winapi.Messages,
	System.SysUtils,
	System.Variants,
	System.Classes,
    System.Threading,
    System.JSON,
	Vcl.Graphics,
	Vcl.Controls,
	Vcl.Forms,
	Vcl.Dialogs,
	Vcl.ComCtrls,
	Vcl.StdCtrls,
	Vcl.ExtCtrls,
	Vcl.Menus,
	Vcl.Clipbrd,
	System.Generics.Collections,
	System.Generics.Defaults,
    ArrayHelper,
    JSONSerializer, Vcl.Mask
	;

type
	TWinItem = record
        Handle: HWND;
        PID: Cardinal;
    end;

	TMainForm = class(TForm)
		lv: TListView;
		p1: TPanel;
		ebType: TLabeledEdit;
		ebLogin: TLabeledEdit;
		ebIndex: TLabeledEdit;
		ebBit: TLabeledEdit;
		Memo: TMemo;
		MainMenu: TMainMenu;
    	nSocket: TMenuItem;
		mnPause: TMenuItem;
		ebTypeString: TLabeledEdit;
		cbPacketActions: TComboBox;
		bActionOnPacket: TButton;
		Filters1: TMenuItem;
		PopupMenu: TPopupMenu;
		nIgnoreThisType: TMenuItem;
		nGetJSONOfPacket: TMenuItem;
        pb: TProgressBar;
        nWindow: TMenuItem;
        nPickAWindow: TMenuItem;
        mniRefreshList: TMenuItem;
        N1: TMenuItem;
	    mniDecodeStructure: TMenuItem;
    	tvStruct: TTreeView;
		procedure FormCreate(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure lvResize(Sender: TObject);
		procedure lvChange(Sender: TObject; Item: TListItem; Change: TItemChange);
		procedure MemoKeyPress(Sender: TObject; var Key: Char);
		procedure ebBitKeyPress(Sender: TObject; var Key: Char);
		procedure ebTypeKeyPress(Sender: TObject; var Key: Char);
		procedure mnPauseClick(Sender: TObject);
		procedure bActionOnPacketClick(Sender: TObject);
		procedure Filters1Click(Sender: TObject);
		procedure mniDecodeStructureClick(Sender: TObject);
		procedure mniRefreshListClick(Sender: TObject);
		procedure mniPickWindowClick(Sender: TObject);
		procedure nIgnoreThisTypeClick(Sender: TObject);
		procedure nGetJSONOfPacketClick(Sender: TObject);
	private
		{ Private declarations }
        Task: ITask;
        Windows: TArrayRecord<TWinItem>;
	public
		{ Public declarations }
	end;

var
	MainForm: TMainForm;

implementation

uses
	UDPSocket,
	Network.PacketBuilder,
	Network.Consts,
	MainFormLogic,
	uFiltersForm,
    Settings;

{$R *.dfm}

procedure TMainForm.Filters1Click(Sender: TObject);
begin
	FiltersForm := TFiltersForm.Create(MainForm);
	FiltersForm.ShowModal;
	FiltersForm.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
	LKeeper.Init;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
	LKeeper.Free;
end;

procedure TMainForm.bActionOnPacketClick(Sender: TObject);
var
	Count: Integer;
	A: TArray<string>;
begin
    SetLength(A, 2);
    A[0] := '1';
	Count := 0;
    if InputQuery(
    	'Enter repeat count',
        ['#'],
        A,
        function(const AValues: array of string): Boolean
        begin
        	Result := True;
       		Count := AValues[0].ToInteger;
		end
    ) = False then
    	Exit;

    pb.Position := 0;
    pb.Max := Count;

    if Assigned(Task) and (Task.Status = TTaskStatus.Running) then
        Task.Cancel;

    Task := TTask.Create(
        procedure()
        var
            Task: ITask;
            curPos, maxPos: Integer;
        begin
            Task := Self.Task;
            // TThread.Synchronize / TThread.Queue
            TThread.Synchronize(nil,
                procedure()
                begin
                    maxPos := pb.Max;
                    curPos := pb.Min;
                    pb.Position := pb.Min;
                end);
            while curPos < maxPos do
            begin
                ExecutePacketAction(PACT_SEND);
                Inc(curPos);
                TThread.Synchronize(nil,
                procedure()
                begin
                    pb.Position := curPos;
                end);
                Sleep(1);
                if Task.Status = TTaskStatus.Canceled then
                Break;
            end;
        end);
    // Стартуем созданное задание.
    Task.Start;
end;

procedure TMainForm.ebBitKeyPress(Sender: TObject; var Key: Char);
begin
	case Ord(Key) of
		45, 48..57, 65..70, 97..102:;
	else
		Key := #0;
	end;
end;

procedure TMainForm.ebTypeKeyPress(Sender: TObject; var Key: Char);
begin
	case Ord(Key) of
		48..57, 65..70, 97..102:;
	else
		Key := #0;
	end;
end;

procedure TMainForm.MemoKeyPress(Sender: TObject; var Key: Char);
begin
	case Ord(Key) of
		32, 48..57, 65..70, 97..102:;
	else
		Key := #0;
	end;
end;

procedure TMainForm.mnPauseClick(Sender: TObject);
begin
	mnPause.Checked := not mnPause.Checked;
	LKeeper.SetPause(mnPause.Checked);
end;

procedure TMainForm.nGetJSONOfPacketClick(Sender: TObject);
var
	Index: Integer;
begin
	if (lv.Selected = nil) then
		Exit;

	Index := Integer(lv.Selected.Data);
	with TClipboard.Create do
	begin
		AsText := JsonOfPacket(LKeeper.List[Index]);
		Free;
	end;
end;

procedure TMainForm.nIgnoreThisTypeClick(Sender: TObject);
var
	Index: Integer;
	PacketType: Byte;
begin
	if (lv.Selected = nil) then
		Exit;

	if (LKeeper.FilterMode <> fmode_ignore) then
			if (MessageBox(
					Application.Handle,
					'Are you going to set the filtering mode to ignore, continue?',
					'',
					MB_YESNO + MB_ICONQUESTION + MB_TOPMOST) <> IDYES) then Exit;

	Index := Integer(lv.Selected.Data);
	PacketType := LKeeper.List[Index].&Type;
	LKeeper.FilterMask[PacketType] := True;
	LKeeper.FilterMode := fmode_ignore;
end;

procedure TMainForm.lvChange(Sender: TObject; Item: TListItem; Change: TItemChange);
var
	Index: Integer;
	Packet: TPacket;
begin
	if (Item = nil) then
		Exit;

	Index := Integer(Item.Data);

	if (Index < 0) then
		raise Exception.Create('Wrong index');

	Packet := LKeeper.List[Index];

	ebType.Text			:= Packet.&Type.ToHexString;
	ebTypeString.Text	:= GetPacketTypeString(Packet.&Type);
	ebLogin.Text		:= Packet.Login.ToString(True);
	ebIndex.Text		:= Packet.Index.ToString;
	ebBit.Text			:= Packet.Bit.ToString;

	Memo.Text			:= RawToHex(@Packet.RawData[0], Packet.RawDataSize);
end;

procedure TMainForm.lvResize(Sender: TObject);
begin
	ShowScrollBar(lv.Handle, SB_HORZ, False);
	lv.Column[lv.Columns.Count - 1].Width :=
		lv.ClientWidth - GetSystemMetrics(SM_CXVSCROLL) - 5;
end;

function EnumWindowsCallback(hWindow: HWnd; Param: LongInt): Boolean; stdcall;
const
	NKSP_CLASS_WND: array [0..1] of string = ('Nksp', 'Xan');
var
	buff: array [0 .. 255] of Char;
	PID: Cardinal;
	i: Integer;
	Found: Boolean;
	A: string;
	WI: TWinItem;
	pParam: ^Integer;
    MI: TMenuItem;
begin
	if Boolean(GetClassName(hWindow, buff, 256)) then
	begin
		A := LowerCase(StrPas(buff));

		for i := Low(NKSP_CLASS_WND) to High(NKSP_CLASS_WND) do
		begin
			Found := Pos(LowerCase(NKSP_CLASS_WND[i]), A) > 0;
			if (Found = True) then
				Break;
		end;

		if (Found) then
		begin
			GetWindowThreadProcessId(hWindow, @PID);

			WI.Handle := hWindow;
			WI.PID := PID;
			MainForm.Windows.Add(WI);

            // Creating new menu item and assigning them to main menu
            MI := TMenuItem.Create(MainForm.MainMenu.Items[0].Items[0]);
            MI.Caption := 'PID: ' + WI.PID.ToString + ', Handle: ' + IntToStr(WI.Handle);
            MI.Tag := MainForm.Windows.Count - 1;
            MI.OnClick := MainForm.mniPickWindowClick;
            MI.RadioItem := True;
            MI.GroupIndex := 1;
            MainForm.MainMenu.Items[0].Items[0].Add(MI);

			pParam := Pointer(Param);
			pParam^ := pParam^ + 1;
		end;
	end;
	Result := True;
end;

function BuildWindowList: Integer;
const
	ForFrom: Integer = 2;
var
    i: Integer;
begin
	Result := 0;

    // Bad practice... change me!
    for i := ForFrom to MainForm.MainMenu.Items[0].Items[0].Count - 1 do
        MainForm.MainMenu.Items[0].Items[0].Delete(ForFrom);

    EnumWindows(@EnumWindowsCallback, NativeInt(@Result));
end;

function AddJSONValueToTreeView(TV: TTreeView; const Name: String; Value: TJSONValue; ParentNode: TTreeNode = nil): TTreeNode;
var
	i: integer;
	obj: TJSONObject;
	pair: TJSONPair;
	arr: TJSONArray;
begin
	if ParentNode <> nil then
    	Result := TV.Items.AddChild(ParentNode, Name)
    else
        Result := TV.Items.Add(nil, Name);
    if Value is TJSONObject then
    begin
        obj := TJSONObject(Value);
        for i := 0 to obj.Count - 1 do
        begin
            pair := obj.Pairs[i];
            AddJSONValueToTreeView(TV, pair.JsonString.Value, pair.JsonValue, Result);
        end;
    end
    else if Value is TJSONArray then
    begin
        arr := TJSONArray(Value);
        for i := 0 to arr.Count - 1 do
        begin
            AddJSONValueToTreeView(TV, '[' + IntToStr(i) + ']', arr.Items[i], Result);
        end;
    end
    else
    begin
        Result.Text := Result.Text + ': ' + Value.Value;
//        TV.Items.AddChild(Result, Value.Value);
    end;
end;

procedure TMainForm.mniDecodeStructureClick(Sender: TObject);
var
	Index: Integer;
	PacketType: Byte;
    Value: TJSONValue;
    Packet: TPacket;
    FireSkill: TFireSkill;
begin
	if (lv.Selected = nil) then
		Exit;

	Index := Integer(lv.Selected.Data);
	PacketType := LKeeper.List[Index].&Type;
    Packet := LKeeper.List[Index];

    tvStruct.Items.Clear;
    tvStruct.Items.BeginUpdate;

    Value := nil;

    case TNetworkMessageType(PacketType) of
    	MSG_LOGIN:
        begin
            Value := DSON.toJsonObject<TLoginFromClient>(PLoginFromClient(@Packet.RawData)^);
	    end;
        MSG_MOVE:
        begin
            Value := DSON.toJsonObject<TMsgMove>(PMsgMove(@Packet.RawData)^);
	    end;
    	MSG_ATTACK:
        begin
            Value := DSON.toJsonObject<TDoAttack>(PDoAttack(@Packet.RawData)^);
        end;
		MSG_SKILL:
        begin
            FireSkill := PFireSkill(@Packet.RawData)^;

            if (FireSkill.listCount > 0) then
            begin
                SetLength(FireSkill.List, FireSkill.listCount);
                FireSkill := PFireSkill(@Packet.RawData)^;
            end;

            Value := DSON.toJsonObject<TFireSkill>(PFireSkill(@Packet.RawData)^);
	    end;
    end;

    if (Value <> nil) then
    begin
		AddJSONValueToTreeView(tvStruct, PacketType.ToString, Value);
        Value.Free;
    end;

    if (tvStruct.Items.Count <> 0) then
    	tvStruct.Items[0].Expand(False);

    tvStruct.Items.EndUpdate;
end;

procedure TMainForm.mniRefreshListClick(Sender: TObject);
begin
	BuildWindowList;
end;

procedure TMainForm.mniPickWindowClick(Sender: TObject);
var
	i: Integer;
begin
	i := (Sender as TMenuItem).Tag;

    if (i > -1) and (i < Windows.Count) then
    begin
    	LKeeper.Connect(Windows.Items[i].PID + 1, Windows.Items[i].PID);

        ShowMessage(
        	'Connected to ' + Windows.Items[i].PID.ToString +
            ' , Window handle: ' + IntToStr(Windows.Items[i].Handle)
        );
    end;
end;

end.
