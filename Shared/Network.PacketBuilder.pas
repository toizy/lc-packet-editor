unit Network.PacketBuilder;

{$DEFINE PACKET_CRC_CHECKS}

interface

uses
	Winapi.Windows,
	System.SysUtils,
	System.Classes
	;

const
	MAX_RAWDATA_SIZE = 1024;

type
	PPacket = ^TPacket;
	TPacket = record
		RawData: array [0..MAX_RAWDATA_SIZE] of Byte;
		RawDataSize: Integer;
		Login: Boolean;
		Index: NativeUInt;
		&Type: Byte;
		Bit: Integer;
		CRC: LongWord;
		class function FromByteString(S: string): TPacket; static;
		class function FromByteArray(B: TBytes): TPacket; static;
		class function FromPointer(P: Pointer; Size: Integer): TPacket; static;
		procedure UpdateCRC;
		function CheckCRC: Boolean;
	end;

implementation

function PrepareString(S: string): string;
var
	i: Integer;
begin
	Result := '';
	for i := 1 to Length(S) do
		case S[i] of
			'0'..'9', 'A'..'Z', 'a'..'z':
				Result := Result + S[i];
		end;
end;

function IsLengthCorrect(L: Integer): Boolean;
begin
	Result := (L > -1) and (L <= MAX_RAWDATA_SIZE);
end;

function CheckLength(L: Integer): Boolean;
begin
	Result := IsLengthCorrect(L);
	if (not Result) then
		MessageBox(0, PChar('Error: length of raw string must be in range 0 .. ' + MAX_RAWDATA_SIZE.ToString), '', MB_TOPMOST);
end;

function IsIntegerEven(N: Integer): Boolean;
begin
	Result := (N mod 2) = 0;
	if (not Result) then
		MessageBox(0, 'Error: hex chars count must be even', '', MB_TOPMOST);
end;

function XOR32Buf(const Buf; const BufSize: Integer): LongWord;
asm
	or eax, eax
	jz @fin
	or edx, edx
	jz @finz

	push esi
	mov esi, eax
	xor eax, eax

	mov ecx, edx
	shr ecx, 2
	jz @rest

@l1:
	xor eax, [esi]
	add esi, 4
	dec ecx
	jnz @l1

@rest:
	and edx, 3
	jz @finp
	xor al, [esi]
	dec edx
	jz @finp
	inc esi
	xor ah, [esi]
	dec edx
	jz @finp
	inc esi
	mov dl, [esi]
	shl edx, 16
	xor eax, edx

@finp:
	pop esi
	ret
@finz:
	xor eax, eax
@fin:
	ret
end;

{ TPacket }

class function TPacket.FromByteString(S: string): TPacket;
var
	RawLen, Len: Integer;
begin
	if (Length(S) = 0) then
		Exit;
	S := PrepareString(S);
	RawLen := Length(S);
	if (IsIntegerEven(RawLen) = False) then
		Exit;
	Len := RawLen div 2;
	if (CheckLength(Len) = False) then
		Exit;
	FillMemory(@Result, SizeOf(TPacket), 0);
	Result.RawDataSize := Len;
	HexToBin(PWideChar(S), @Result.RawData, Result.RawDataSize);
	Result.&Type := Result.RawData[0];
end;

class function TPacket.FromByteArray(B: TBytes): TPacket;
begin
	FillMemory(@Result, SizeOf(TPacket), 0);
    if (CheckLength(Length(B)) = False) then
		Exit;
	Result.RawDataSize := Length(B);
	CopyMemory(@Result.RawData, B, Result.RawDataSize);
	Result.&Type := Result.RawData[0];
end;

class function TPacket.FromPointer(P: Pointer; Size: Integer): TPacket;
begin
	FillMemory(@Result, SizeOf(TPacket), 0);
    if (CheckLength(Size) = False) then
		Exit;
	Result.RawDataSize := Size;
	CopyMemory(@Result.RawData, P, Result.RawDataSize);
	Result.&Type := Result.RawData[0];
end;

function TPacket.CheckCRC: Boolean;
begin
{$IFDEF PACKET_CRC_CHECKS}
	Result := (Self.CRC = XOR32Buf(Self, NativeUInt(@Self.CRC) - NativeUInt(@Self.RawData)));
{$ELSE}
	Result := True;
{$ENDIF}
end;

procedure TPacket.UpdateCRC;
begin
{$IFDEF PACKET_CRC_CHECKS}
	Self.CRC := XOR32Buf(Self, NativeUInt(@Self.CRC) - NativeUInt(@Self.RawData));
{$ENDIF}
end;

end.
