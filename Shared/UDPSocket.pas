unit UDPSocket;

interface

uses
	Winapi.Windows,
	System.Classes,
	System.SysUtils,
	Winapi.Winsock2,
	System.Net.Socket,
	System.Threading
	;

type
	TOnReceive = procedure(Data: Pointer; Size: NativeUInt; Reserved: Pointer);
	TUDPRelay = class
	private
		FServer: TSocket;
		FClient: TSocket;
		FThreadHandle: NativeUInt;
		FOnReceive: TOnReceive;
		FTerminating: Boolean;
	public
		constructor Create(PortIn, PortOut: Integer);
		destructor Destroy; override;
		procedure Send(Data: Pointer; Size: Integer);
		property OnReceive: TOnReceive read FOnReceive write FOnReceive;
	end;


implementation

const
	UDP_MAX_SAFE_PAYLOAD	= 65507;	//65535 (IP datagrgam size) - IPHL - UDPHL = 65507
    HEADER = '[UDP Relay Thread]';

function ThreadFunc(Parameter: Pointer): Integer;
var
	R: TUDPRelay;
	B: TBytes;
	L: Integer;
begin
	R := TUDPRelay(Parameter);

	if (Assigned(R) = False) then
		raise Exception.Create(HEADER + ' Incorrect parameter.');

	while (R.FTerminating = False) do
	begin
		if (Assigned(R.FOnReceive)) then
		begin
			L := R.FClient.ReceiveFrom(B);
			if (L > 0) then
			begin
//				TThread.Synchronize(nil, procedure()
//					begin
						R.FOnReceive(@B[0], L, nil);
//					end);
            end;
		end;
		Winapi.Windows.Sleep(1);
	end;

	Result := 0;
	ExitThread(Result);
end;

{ TUDPRelay }

constructor TUDPRelay.Create(PortIn, PortOut: Integer);
begin
	FClient := TSocket.Create(TSocketType.UDP);
	FServer := TSocket.Create(TSocketType.UDP);
	FClient.ListenBroadcast(PortIn);
	FServer.OpenBroadcast(PortOut);
	FTerminating := False;

	FThreadHandle := BeginThread(
		nil,				// SecurityAttributes: Pointer
		0,              	// StackSize: LongWord
		@ThreadFunc,		// ThreadFunc: TThreadFunc
		Self,            	// Parameter: Pointer
		0,              	// CreationFlags: LongWord
		PLongWord(nil)^     // var ThreadId: TThreadID (LongWord)
	);
end;

destructor TUDPRelay.Destroy;
begin
	FTerminating := True;
	WaitForSingleObject(FThreadHandle, INFINITE);
	FClient.Free;
	FServer.Free;
end;

procedure TUDPRelay.Send(Data: Pointer; Size: Integer);
begin
	FServer.SendTo(Data^, Size);
end;

end.
