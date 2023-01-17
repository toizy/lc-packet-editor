library sendtoservernew_dll;

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Winapi.Winsock2,
  System.Net.Socket,
  DLL.Hooks in 'DLL.Hooks.pas',
  DLL.HideModule in 'DLL.HideModule.pas',
  DLL.Utils in 'DLL.Utils.pas',
  Network.PacketBuilder in 'Shared\Network.PacketBuilder.pas',
  Network.Message in 'Shared\Network.Message.pas',
  Network.Consts in 'Shared\Network.Consts.pas',
  UDPSocket in 'Shared\UDPSocket.pas',
  DLL.FindPattern in 'DLL.FindPattern.pas';

var
	Relay: TUDPRelay;
	Counter: NativeUInt = 0;
	IsDLLLoaded: Boolean = False;

procedure OnUDPReceive(Data: Pointer; Size: NativeUInt; Reserved: Pointer);
var
	Packet: PPacket;
	Message: TNetworkMessage;
begin
	Write_Ln('[Socket]: Got a new packet to inject.');

	Packet := Data;

	if (Packet^.CheckCRC = False) then
	begin
		Write_Ln('Dropped incorrect packet (crc fault)');
		Exit;
    end;


	Message.Init(@Packet^.RawData[0], Packet^.RawDataSize);
	DLL.Hooks.OriginalCall(@Message, Packet^.Login);
	Message.Dispose;

	Write_Ln('[Socket]: Injected.');
end;

procedure SendToServerNew_Hooked(Message: PNetworkMessage; Login: Boolean); stdcall;
var
	Packet: TPacket;
begin
	// Build a packet and send it through a socket to listeners
	Packet := TPacket.FromPointer(Message^.nm_pubMessage, Message^.nm_slSize);
	Packet.Login := Login;
	Packet.Index := Message^.nm_iIndex;
	//Packet.Type_ := message^.nm_mtType;
	Packet.Bit := Message^.nm_iBit;
	Packet.UpdateCRC;
	Relay.Send(@Packet, SizeOf(TPacket));

	Write_Ln('#' + Counter.ToString +  ' Packet received [bLogin: ' + BoolToStr(Login, True) + ']:');

	Inc(Counter);

	Write_Ln('	nm_mtType : ' +
		Message.nm_mtType.ToString + ' (0x' +
		Message.nm_mtType.ToHexString + ')'
	);

	// Just an example of decoding structure pointer
	if (PByte(Message.nm_pubMessage)^ < Byte(MSG_MAX)) then
	begin
		Write_Ln('	(presumedly, type is ' +
			TNetworkMessageTypeStr[PByte(Message.nm_pubMessage)^] + ')');

		if (TNetworkMessageType(Message.nm_pubMessage^) = MSG_MOVE) then
		begin
			with PMsgMove(Message.nm_pubMessage)^ do
				Write_Ln(
					'' + #13#10 +
					'	MsgType: ' + MsgType.ToString + #13#10 +
					'	SubType: ' + SubType.ToString + #13#10 +
					'	CharType: ' + CharType.ToString + #13#10 +
					'	MoveType: ' + MoveType.ToString + #13#10 +
					'	YLayer: ' + YLayer.ToString + #13#10 +
					'	Index: ' + Index.ToString + #13#10 +
					'	Speed: ' + Speed.ToString + #13#10 +
					'	X: ' + X.ToString + #13#10 +
					'	Z: ' + Z.ToString + #13#10 +
					'	H: ' + H.ToString + #13#10 +
					'	R: ' + R.ToString + #13#10
				);
		end
	end;

	RawToHex(Message.nm_pubMessage, Message.nm_slSize);   //TODO Message.nm_slSize <= Message.nm_slMaxSize

	Write_Ln('	nm_slMaxSize : ' +
		Message.nm_slMaxSize.ToString + ' (0x' +
		Message.nm_slMaxSize.ToHexString + ')'
	);

	Write_Ln('	nm_slSize : ' +
		Message.nm_slSize.ToString + ' (0x' +
		Message.nm_slSize.ToHexString + ')'
	);
	Write_Ln('	nm_iBit : ' +
		Message.nm_iBit.ToString + ' (0x' +
		Message.nm_iBit.ToHexString + ')'
	);
	Write_Ln('	nm_iIndex : ' +
		Message.nm_iIndex.ToString + ' (0x' +
		Message.nm_iIndex.ToHexString + ')'
	);
	Write_Ln('-------------------');
end;

procedure DLLEntryPoint(dwReason: DWORD);
begin
	case dwReason of
		DLL_PROCESS_ATTACH:
			begin
				if (IsDLLLoaded = True) then
					Exit;

				IsDLLLoaded := True;
{$IFDEF CONSOLE_ENABLED}
				PrepareConsole();
{$ENDIF}
				DLL.Hooks.PlaceHook(@SendToServerNew_Hooked);
				HideThisModule();
				Relay := TUDPRelay.Create(20000, 20001);
				Relay.OnReceive := OnUDPReceive;
			end;
		DLL_PROCESS_DETACH:
			begin
				if (IsDLLLoaded = False) then
					Exit;

{$IFDEF CONSOLE_ENABLED}
				FreeConsole();
{$ENDIF}
				Relay.Free;
				DLL.Hooks.RestoreHook;
			end;
	end;
end;

begin
	DLLProc := @DLLEntryPoint;
	DLLEntryPoint(DLL_PROCESS_ATTACH);
end.
