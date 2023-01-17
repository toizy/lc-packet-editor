unit DLL.FindPattern;

interface

uses
	Winapi.Windows,
	System.SysUtils
	;

type
	PPattern = ^TPattern;
	TPattern = record
		Data: array of Byte;
		Mask: array of Boolean;
		Size: Integer;
		Entries: array of NativeUInt;	// Array of addresses
	end;
	
	TFindPattern = record
	private
		FPattern: array of TPattern;
		FMaxLength: Integer;
		function LengthOfMask(Mask: string; Pattern: PPattern): Integer;
		procedure AssignMask(Mask: string; Pattern: PPattern);
	public
		function AddPattern(PatternString: string; Index: Integer = 0): Integer;
		function Compare(const Data: Pointer): Boolean;
		function GetOptimalBufferSize: Integer;
	end;

implementation

const
	MaxMaskSize					= 64;
	MAX_PATTERN_ARRAY_LENGTH	= 64;

function PrepareMask(Mask: string): string;
var
	i: Integer;
begin
	Result := '';
	for i := 1 to Length(Mask) do
		case Mask[i] of
			'a' .. 'f', 'A' .. 'F', '0' .. '9', '?':
				Result := Result + Mask[i];
			' ':;
		end;
end;

function TFindPattern.AddPattern(PatternString: string; Index: Integer = 0): Integer;
begin
	FMaxLength := 0;
	if (Index >= MAX_PATTERN_ARRAY_LENGTH) then
		Exit(0);

	if (Index < Length(FPattern)) then
		SetLength(FPattern, Index + 1);

	SetLength(FPattern[Index].Mask, 0);
	SetLength(FPattern[Index].Data, 0);	
	SetLength(FPattern[Index].Entries, 0);
	FPattern[Index].Size := 0;
	
	PatternString := PrepareMask(PatternString);
	Result := LengthOfMask(PatternString, @FPattern[Index]);
	if (Result > FMaxLength) then			//TODO Init -> Add -> Compare
		FMaxLength := Result;
	AssignMask(PatternString, @FPattern[Index]);
end;

function TFindPattern.LengthOfMask(Mask: string; Pattern: PPattern): Integer;
begin
	if (Length(Mask) mod 2 <> 0) then
		Exit(0);
		
	Pattern^.Size := Length(Mask) div 2;
	if (Pattern^.Size > MaxMaskSize) then
	begin
		Pattern^.Size := 0;
		Exit(0);
	end;
	Result := Pattern^.Size;
end;

procedure TFindPattern.AssignMask(Mask: string; Pattern: PPattern);
var
	c: string;
	i: Integer;
	E: Integer;
begin
	Mask := PrepareMask(Mask);
	SetLength(Pattern^.Mask, Pattern^.Size);
	SetLength(Pattern^.Data, Pattern^.Size);
	for i := 0 to Pattern^.Size - 1 do
	begin
		c := Copy(Mask, i * 2 + 1, 2);
		if c = '??' then
			Pattern^.Mask[i] := True
		else
		begin
			Pattern^.Mask[i] := False;
			Val('$' + c, Pattern^.Data[i], E);
		end;
	end;
end;

function TFindPattern.Compare(const Data: Pointer): Boolean;
var
	i: Integer;
	P: PPattern;
begin      
	if (Data = nil) then
	begin
		Result := False;
		Exit;
	end;

	Result := True;

	P := @FPattern[0];
	
	for i := 0 to P^.Size - 1 do
	begin
		Result := ((PByte(NativeUInt(Data) + NativeUInt(i))^ = P^.Data[i]) or P^.Mask[i]) and Result;
		if (Result = False) then
			Exit;
	end;
end;

function TFindPattern.GetOptimalBufferSize: Integer;
begin
	Result := FMaxLength;
end;

end.
