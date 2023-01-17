unit Network.Message;

interface

uses
	Winapi.Windows,
	System.SysUtils,
	System.Classes
	;

type
	PNetworkMessage = ^TNetworkMessage;
	TNetworkMessage = record
		// Partial reimplementation of the C++ based CNetworkMessage class (just members)
		nm_mtType: Byte;
		nm_pubMessage: Pointer;
		nm_slMaxSize: Integer;
		nm_pubPointer: Pointer;
		nm_slSize: Integer;
		nm_iBit: Integer;
		nm_iIndex: NativeUInt;
		// Initialization functions
		procedure Init(); overload;
		procedure Init(Data: TBytes); overload;
		procedure Init(Data: Pointer; Size: Integer); overload;
		procedure Dispose();	// Must be called every time we create it and finish working with it!
	end;

	TSendToServerNew = procedure(Message: PNetworkMessage; bLogin: Boolean); stdcall;

implementation

const
	MAX_NETWORKMESSAGE_SIZE	= 88405;

{ TNetworkMessage }

procedure TNetworkMessage.Init;
begin
	FillMemory(@Self, SizeOf(TNetworkMessage), 0);
	nm_slMaxSize := MAX_NETWORKMESSAGE_SIZE;
	GetMem(nm_pubMessage, MAX_NETWORKMESSAGE_SIZE);
	nm_pubPointer := nm_pubMessage;
end;

procedure TNetworkMessage.Init(Data: TBytes);
begin
	Init();
	if (Length(Data) < 1) then
		Exit;
	CopyMemory(nm_pubMessage, @Data[0], Length(Data));
	nm_mtType := PByte(nm_pubMessage)^;
	nm_slSize := Length(Data);
end;

procedure TNetworkMessage.Init(Data: Pointer; Size: Integer);
begin
	Init();
	if (Size < 2) then
		Exit;
	CopyMemory(nm_pubMessage, Data, Size);
	nm_mtType := PByte(nm_pubMessage)^;
	nm_slSize := Size;
end;

procedure TNetworkMessage.Dispose;
begin
	if (Assigned(nm_pubMessage)) then
		FreeMem(nm_pubMessage, MAX_NETWORKMESSAGE_SIZE);
end;

end.
