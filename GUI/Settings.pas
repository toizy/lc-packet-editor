unit Settings;

interface

uses
	Winapi.Windows,
	System.Classes,
	System.SysUtils,
	System.JSON,
	System.JSON.Types,
	System.JSON.Writers,
	System.JSON.Builders,
	Vcl.Dialogs,
	Network.PacketBuilder
	;

function JsonOfPacket(Packet: TPacket): string;
function PacketOfJson(S: string; var Packet: TPacket): Boolean;

implementation

const
	SettingsFilename = 'settings.json';
	PacketEntryVersion = 1;

function BinToString(const bin: array of Byte): string;
const
	HexSymbols = '0123456789ABCDEF';
var
	i: Integer;
begin
	SetLength(Result, 2 * Length(bin));
	for i := 0 to Length(bin) - 1 do
	begin
		Result[1 + 2 * i + 0] := HexSymbols[1 + bin[i] shr 4];
		Result[1 + 2 * i + 1] := HexSymbols[1 + bin[i] and $0F];
	end;
end;

function JsonOfPacket(Packet: TPacket): string;
var
	Builder: TJSONObjectBuilder;
	Writer: TJsonTextWriter;
	StringWriter: TStringWriter;
	StringBuilder: TStringBuilder;
begin
	StringBuilder := TStringBuilder.Create;
	StringWriter := TStringWriter.Create(StringBuilder);
	Writer := TJsonTextWriter.Create(StringWriter);
	Writer.Formatting := TJsonFormatting.Indented;
	Builder := TJSONObjectBuilder.Create(Writer);

	Builder
		.BeginObject.Add('PacketEntryVersion', PacketEntryVersion)
			.Add('RawData', BinToString(Packet.RawData))
			.Add('Login', Packet.Login)
			.Add('Index', Packet.Index)
			.Add('Type', Packet.&Type)
			.Add('Bit', Packet.Bit)
		.EndObject;

	Result := StringBuilder.ToString;

	StringBuilder.Free;
	StringWriter.Free;
	Writer.Free;
	Builder.Free;
end;

function PacketOfJson(S: string; var Packet: TPacket): Boolean;
var
	JSON: TJSONObject;
	B: TBytes;
	str: string;
begin
	Result := False;
	JSON := TJSONObject.ParseJSONValue(S) as TJSONObject;
	try
		if (not Assigned(JSON)) then
			Exit;

		if (JSON.GetValue<Integer>('PacketEntryVersion') <> PacketEntryVersion) then
			raise Exception.Create('Incompatible version of the packet');

		B := TEncoding.UTF8.GetBytes(JSON.GetValue<string>('RawData'));
		str := TEncoding.UTF8.GetString(B);  //	- in the opposite direction

		Packet.RawDataSize := Length(B);
		CopyMemory(@Packet.RawData[0], B, Packet.RawDataSize);

		Result := True;
	finally
		JSON.Free;
	end;
end;

end.
