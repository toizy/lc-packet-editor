unit MainFormLogic;

interface

uses
	Winapi.Windows,
	Winapi.Messages,
	System.SysUtils,
	System.Variants,
	System.Classes,
	Vcl.Graphics,
	Vcl.Controls,
	Vcl.Forms,
	Vcl.Dialogs,
	Vcl.ComCtrls,
	Vcl.StdCtrls,
	Vcl.ExtCtrls,
	Vcl.Menus,
	System.Generics.Collections,
	System.Generics.Defaults,
	UDPSocket,
	Network.PacketBuilder,
	Network.Consts
	;

const
	PACT_BUILD	= 1;
	PACT_SEND	= 2;
	PACT_SAVE	= 3;

type
	TFilterMode = (fmode_none, fmode_ignore, fmode_allow);

	TLogicKeeper = record
	private
		FRelay: TUDPRelay;
		FReceivePaused: Boolean;
        FConnected: Boolean;
	public
    	FilterMask: array [0..Integer(MSG_MAX)] of Boolean;
		FilterMode: TFilterMode;
		List: TList<TPacket>;

		procedure Init;
		procedure Free;
		procedure Reinit;
        procedure Connect(PortIn, PortOut: Integer);
		procedure SetPause(Value: Boolean);
        property Connected: Boolean read FConnected;
	end;

function RawToHex(P: Pointer; Size: Integer): string;
function GetPacketTypeString(PacketType: Byte): string;
procedure ExecutePacketAction(Index: Integer);

var
	LKeeper: TLogicKeeper;

implementation

uses
	uMainForm;

var
	Counter: NativeUInt = 0;

function RawToHex(P: Pointer; Size: Integer): string;
var
	i: Integer;
begin
	Result := '';
	for i := 0 to Size - 1 do
		Result := Result + PByte(Pointer(NativeUInt(P) + NativeUInt(i)))^.ToHexString + ' ';
end;

function GetPacketTypeString(PacketType: Byte): string;
begin
	if (PacketType < Byte(MSG_MAX)) then
		Result := ' [' + PacketType.ToString + ']'
	else
		Result := '';
end;

procedure OnUDPReceive(Data: Pointer; Size: NativeUInt; Reserved: Pointer);
var
	Packet: PPacket;
	LI: TListItem;
	Index: Integer;
begin
	if (LKeeper.FReceivePaused = True) then
		Exit;

	Packet := Data;

	if (Packet^.CheckCRC = False) then
	begin
		MessageBox(Application.Handle, 'Dropped incorrect packet (crc fault)', '', MB_TOPMOST);
		Exit;
	end;

	if (LKeeper.FilterMode = fmode_ignore) and (LKeeper.FilterMask[Packet^.&Type] = True) then
		Exit;

	if (LKeeper.FilterMode = fmode_allow) and (LKeeper.FilterMask[Packet^.&Type] = False) then
		Exit;

	Counter := Counter + 1;

	Index := LKeeper.List.Add(Packet^);

	LI := MainForm.lv.Items.Add;
	LI.Caption := Counter.ToString;
	LI.SubItems.AddObject(Packet^.&Type.ToHexString + GetPacketTypeString(Packet^.&Type), TObject(Packet^.&Type));
	LI.SubItems.Add(Packet^.RawDataSize.ToString);
	LI.SubItems.Add(Packet^.Login.ToString(True));
	LI.SubItems.Add(Packet^.Index.ToHexString);
	LI.SubItems.Add(Packet^.Bit.ToString);
	LI.SubItems.Add(RawToHex(@Packet^.RawData[0], Packet^.RawDataSize));
	LI.Data := Pointer(Index);

	SendMessage(MainForm.lv.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure ExecutePacketAction(Index: Integer);
var
	Packet: TPacket;
begin
	case Index of
    	//-------------------------------------------------------------------------
		PACT_BUILD:	begin
				Packet := TPacket.FromByteString(MainForm.Memo.Text);
			end;
        //-------------------------------------------------------------------------
		PACT_SEND:	begin
				Packet := TPacket.FromByteString(MainForm.Memo.Text);
				if (Packet.RawDataSize > 0) then
				begin
					Packet.UpdateCRC;
                    LKeeper.FRelay.Send(@Packet, SizeOf(Packet));
				end;
			end;
		PACT_SAVE:
			begin
				// Packet := TPacket.FromByteString(Memo.Text);
				// if (Packet.RawDataSize > 0) then
				// Packet.UpdateCRC;
			end;
	end;
end;

{ TLogicKeeper }

procedure TLogicKeeper.Init;
begin
	FRelay := TUDPRelay.Create(20001, 20000);
	FRelay.OnReceive := OnUDPReceive;
	List := TList<TPacket>.Create;
	FReceivePaused := False;
	FilterMode := fmode_none;
	FillMemory(@FilterMask[0], SizeOf(FilterMask), 0);
    FConnected := False;
end;

procedure TLogicKeeper.Reinit;
begin
	List.Clear;
	// ...
end;

procedure TLogicKeeper.SetPause(Value: Boolean);
begin
	FReceivePaused := Value;
end;

procedure TLogicKeeper.Connect(PortIn, PortOut: Integer);
begin
	if Assigned(FRelay) then
    	FRelay.Free;

    FRelay := TUDPRelay.Create(PortIn, PortOut);
	FRelay.OnReceive := OnUDPReceive;

    FConnected := True;
end;

procedure TLogicKeeper.Free;
begin
	FRelay.Free;
	List.Free;
end;

end.
