unit DLL.Utils;

interface

uses
	Winapi.Windows,
	System.SysUtils
	;

function AttachConsole(dwProcessID: Integer): Boolean; stdcall; external kernel32;
function FreeConsole: Boolean; stdcall; external kernel32;
function GetConsoleWindow: HWND; stdcall; external kernel32 name 'GetConsoleWindow';

procedure PrepareConsole;
procedure RawToHex(P: Pointer; Size: Integer);
procedure WriteToConsole(S: string);

implementation

const
	CONSOLE_TITLE = 'Packet Monitor';

procedure PrepareConsole;
var
	ConsoleHwnd: HWND;
	R: TRect;
begin
{$IFNDEF CONSOLE_ENABLED}
    Exit;
{$ENDIF}
	AllocConsole;
	SetConsoleTitle(CONSOLE_TITLE);
	AttachConsole(GetCurrentProcessId());
	ConsoleHwnd := GetConsoleWindow;
	GetWindowRect(ConsoleHwnd, R);
	SetWindowPos(ConsoleHwnd, 0, 0, 0,0, 0, SWP_NOSIZE);
end;

procedure RawToHex(P: Pointer; Size: Integer);
var
	i: Integer;
begin
{$IFNDEF CONSOLE_ENABLED}
	Exit;
{$ENDIF}
	Write('	Raw data: ');
	Write('	');
	for i := 0 to Size - 1 do
		Write(PByte(Pointer(NativeUInt(P) + NativeUInt(i)))^.ToHexString + ' ');
	Writeln('');
end;

procedure WriteToConsole(S: string);
begin
{$IFDEF CONSOLE_ENABLED}
	Writeln(S);
{$ENDIF}
end;

end.
