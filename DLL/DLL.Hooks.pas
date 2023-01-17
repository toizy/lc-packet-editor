unit DLL.Hooks;

//USE_ABSOLUTE_ADDRESS	--> Gamigo and P-Servers
//USE_ORDINALS          --> Gamigo
//USE_MANGLED_NAMES     --> P-Servers
//USE_PATTERN_SEARCH    --> P-Servers and Gamigo

{$DEFINE USE_MANGLED_NAMES}
//{$DEFINE TIME_SPENT_STOPWATCH}

interface

uses
	Winapi.Windows,
	System.SysUtils,
	Network.Message,
	DLL.FindPattern,
	System.Diagnostics
	;

procedure PlaceHook(ReplacementAddress: Pointer);
procedure RestoreHook;
procedure OriginalCall(Message: PNetworkMessage; Login: Boolean);

implementation

type
	TNearJmpSpliceRec = packed record
		JmpOpcode: Byte;
		Offset: DWORD;
	end;

	TNearJmpSpliceData = packed record
		FuncAddr: FARPROC;
		ReplAddr: FARPROC;
		OldData: TNearJmpSpliceRec;
		NewData: TNearJmpSpliceRec;
	end;

procedure SpliceNearJmp(FuncAddr: Pointer; NewData: TNearJmpSpliceRec); forward;

var
	NearJmpSpliceRec: TNearJmpSpliceData;

{$IFDEF USE_PATTERN_SEARCH}

function GetModuleSize(ModuleHandle: NativeUInt): NativeUInt;
var
	IDH: TImageDosHeader;
	INH: TImageNtHeaders;
begin
	Result := 0;
	Move(Pointer(ModuleHandle)^, IDH, SizeOf(TImageDosHeader));
	if (IDH.e_magic <> IMAGE_DOS_SIGNATURE) then
		Exit;
	Move(Pointer(ModuleHandle + NativeUInt(IDH._lfanew))^, INH, SizeOf(TImageNtHeaders));
	if (INH.Signature = IMAGE_NT_SIGNATURE) then
		Exit(INH.OptionalHeader.SizeOfImage);
end;

{ Search for a pattern, memory region way }

function FindPatternAddress(const ModuleName, PatternString: string; SubstractDLLBase: Boolean = True): NativeUInt;
var
	Pattern: TFindPattern;
	i, BaseAddressOfDLL, CurrentAddress, EndAddress: NativeUInt;
	MBI: TMemoryBasicInformation;
	BufferSize: Integer;
begin
	Result := 0;
	CurrentAddress := GetModuleHandle(PWideChar(ModuleName));
	BaseAddressOfDLL := CurrentAddress;
	EndAddress := CurrentAddress + GetModuleSize(BaseAddressOfDLL);
	Pattern.AddPattern(PatternString);
	BufferSize := Pattern.GetOptimalBufferSize;

	if (BufferSize = 0) then
		Exit;

	while (VirtualQueryEx(NativeUInt(-1), Pointer(CurrentAddress), MBI, SizeOf(MBI)) <> 0) and
		(NativeUInt(MBI.BaseAddress) + MBI.RegionSize < EndAddress) do
	begin
		if (MBI.State = MEM_COMMIT) and not ((MBI.Protect and PAGE_GUARD) = PAGE_GUARD) then
		begin
			for i := 0 to MBI.RegionSize - 1 do
			begin
				if Pattern.Compare(@PByte(MBI.BaseAddress)[i]) then
				begin
					Result := NativeUInt(MBI.BaseAddress) + i;
					if (SubstractDLLBase) then
						Result := Result - BaseAddressOfDLL;
					Exit;
				end;
			end;
		end;
		CurrentAddress := CurrentAddress + MBI.RegionSize;
	end;
end;

{$ENDIF}

function GetSendToServerNew: Pointer;
{$IF DEFINED(USE_PATTERN_SEARCH)}
const
	PatternString: string = 'Your hex pattern here';
{$ENDIF}
{$IF DEFINED(USE_PATTERN_SEARCH)}
var
	SW: TStopwatch;
{$ENDIF}
begin
{$IF not DEFINED(USE_PATTERN_SEARCH) and not DEFINED(USE_ABSOLUTE_ADDRESS) and not DEFINED(USE_ORDINALS) and not DEFINED(USE_MANGLED_NAMES)}
	Exit(nil);
{$ENDIF}
{$IF DEFINED(USE_PATTERN_SEARCH)}
	{$IF DEFINED(USE_PATTERN_SEARCH)}
	SW := TStopwatch.StartNew;
    {$ENDIF}
	Result := Pointer(FindPatternAddress('Engine.dll', PatternString));
    {$IF DEFINED(USE_PATTERN_SEARCH)}
	SW.Stop;
	MessageBox(0, PChar(SW.Elapsed.TotalMilliseconds.ToString), PChar(NativeUInt(Result).ToHexString), 0);
    {$ENDIF}
{$ELSEIF DEFINED(USE_ABSOLUTE_ADDRESS)}
	Result := Pointer(NativeUInt(GetModuleHandleA('Engine.dll')) + $401ED0);
    //Engine.dll+40DD60 - ReceiveFromServerNew
{$ELSEIF DEFINED(USE_MANGLED_NAMES)}
	Result := Pointer(GetProcAddress(GetModuleHandleA('Engine.dll'), '?SendToServerNew@CMsgDispatcher@m@QAEXABVCNetworkMessage@@H@Z'));
	if (Result = nil) then	// Aventia LC, etc
		Result := Pointer(GetProcAddress(GetModuleHandleA('Engine.dll'), '?SendToServerNew@CMessageDispatcher@@QAEXABVCNetworkMessage@@H@Z'));
{$ELSE}
	Result := nil;
{$ENDIF}
end;

procedure HookProxy(Message: PNetworkMessage; Login: Boolean); stdcall;
begin
	SpliceNearJmp(NearJmpSpliceRec.FuncAddr, NearJmpSpliceRec.OldData);
	try
		TSendToServerNew(NearJmpSpliceRec.ReplAddr)(Message, Login);
		// Call original func
		TSendToServerNew(NearJmpSpliceRec.FuncAddr)(Message, Login);
	finally
		SpliceNearJmp(NearJmpSpliceRec.FuncAddr, NearJmpSpliceRec.NewData);
	end;
end;

procedure OriginalCall(Message: PNetworkMessage; Login: Boolean);
begin
	SpliceNearJmp(NearJmpSpliceRec.FuncAddr, NearJmpSpliceRec.OldData);
	try
		TSendToServerNew(NearJmpSpliceRec.FuncAddr)(Message, Login);
	finally
		SpliceNearJmp(NearJmpSpliceRec.FuncAddr, NearJmpSpliceRec.NewData);
	end;
end;

procedure SpliceNearJmp(FuncAddr: Pointer; NewData: TNearJmpSpliceRec);
var
	OldProtect: DWORD;
begin
	VirtualProtect(FuncAddr, SizeOf(TNearJmpSpliceRec), PAGE_EXECUTE_READWRITE, OldProtect);
	try
		// We need an atomic operation to prevent crashes related to multi-threading. So there is a workaround:
		// 1. Make atomic replacement the first byte with RET
		// UNDONE
		//InterlockedExchange()
		Move(NewData, FuncAddr^, SizeOf(TNearJmpSpliceRec));
	finally
		VirtualProtect(FuncAddr, SizeOf(TNearJmpSpliceRec), OldProtect, OldProtect);
		FlushInstructionCache(GetCurrentProcess, FuncAddr, SizeOf(TNearJmpSpliceRec));
	end;
end;

procedure InitNearJmpSpliceRec(OriginalFunction: Pointer; InterceptedFunction: Pointer);
begin
	NearJmpSpliceRec.FuncAddr := OriginalFunction;
	Move(NearJmpSpliceRec.FuncAddr^, NearJmpSpliceRec.OldData, SizeOf(TNearJmpSpliceRec));
	NearJmpSpliceRec.NewData.JmpOpcode := $E9;
	NearJmpSpliceRec.NewData.Offset := PAnsiChar(InterceptedFunction) - PAnsiChar(NearJmpSpliceRec.FuncAddr) - SizeOf(TNearJmpSpliceRec);
	SpliceNearJmp(NearJmpSpliceRec.FuncAddr, NearJmpSpliceRec.NewData);
end;

procedure PlaceHook(ReplacementAddress: Pointer);
begin
	NearJmpSpliceRec.ReplAddr := ReplacementAddress;
	InitNearJmpSpliceRec(GetSendToServerNew, @HookProxy);
end;

procedure RestoreHook;
begin
	SpliceNearJmp(NearJmpSpliceRec.FuncAddr, NearJmpSpliceRec.OldData);
end;

end.
