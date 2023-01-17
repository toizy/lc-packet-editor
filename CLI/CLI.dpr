program CLI;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  Winapi.Winsock2,
  System.Net.Socket,
  Network.Consts in '..\Shared\Network.Consts.pas',
  Network.Message in '..\Shared\Network.Message.pas',
  Network.PacketBuilder in '..\Shared\Network.PacketBuilder.pas',
  UDPSocket in '..\Shared\UDPSocket.pas';

const
    CL = #13#10;

var
	S: string;
	Packet: TPacket;
	// Warp: TMsgWarpToGuildWarArea;
	ThreadStopFlag: Boolean = False;
	Relay: TUDPRelay;

procedure RawToHex(P: Pointer; Size: Integer);
var
	i: Integer;
begin
	Write('	Raw data: ');
	Write('	');
	for i := 0 to Size - 1 do
		Write(PByte(Pointer(NativeUInt(P) + NativeUInt(i)))^.ToHexString + ' ');
	Writeln('');
end;

procedure OnUDPReceive(Data: Pointer; Size: NativeUInt; Reserved: Pointer);
var
	Packet: PPacket;
begin
	Packet := Data;

	if (Packet^.CheckCRC = False) then
	begin
		Writeln('Invalid packet dropped due to CRC error');
		Exit;
	end;

	Writeln('[Socket message]: Got a new packet from the game:');

	Writeln('	nm_mtType : ' + Packet^.RawData[0].ToString + ' (0x' + Packet^.RawData[0].ToHexString + ')');

	if (Packet^.RawData[0] < Byte(MSG_MAX)) then
	begin
		Writeln('	(type presumedly is ' + TNetworkMessageTypeStr[Packet^.RawData[0]] + ')');

		if (TNetworkMessageType(Packet^.RawData[0]) = MSG_MOVE) then
		begin
			with PMsgMove(@Packet^.RawData[0])^ do
				Writeln(CL +
                	'	MsgType: ' + TypeBase.NMType.ToString + CL +
                    '	SubType: ' + TypeBase.NMSubType.ToString + CL +
                    '	CharType: ' + CharType.ToString + CL +
                    '	MoveType: ' + Integer(MoveType).ToString + CL +
                    '	YLayer: ' + YLayer.ToString + CL +
                    '	Index: ' + Index.ToString + CL +
                    '	Speed: ' + Speed.ToString + CL +
                    '	X: ' + X.ToString + CL +
                    '	Z: ' + Z.ToString + CL +
                    '	H: ' + H.ToString + CL +
                    '	R: ' + R.ToString + CL
                );
		end
	end;

	RawToHex(@Packet^.RawData[0], Packet^.RawDataSize);

	Writeln('	nm_slSize : ' + Packet^.RawDataSize.ToString + ' (0x' + Packet^.RawDataSize.ToHexString + ')');
	Writeln('	nm_iBit : ' + Packet^.Bit.ToString + ' (0x' + Packet^.Bit.ToHexString + ')');
	Writeln('	nm_iIndex : ' + Packet^.Index.ToString + ' (0x' + Packet^.Index.ToHexString + ')');

	Writeln('-------------------');
end;

begin
	Relay := TUDPRelay.Create(20001, 20000);
	Relay.OnReceive := OnUDPReceive;
	try
		while True do
		begin
			Readln(S);

			// Warp := TMsgWarpToGuildWarArea.Build(3);
			// Packet := TPacket.FromPointer(@Warp, SizeOf(Warp));

			Packet := TPacket.FromByteString(S);
			Packet.Login := False;
			Packet.UpdateCRC;
			Relay.Send(@Packet, SizeOf(TPacket));

		end;
	finally
		Relay.Free;
	end;

end.
