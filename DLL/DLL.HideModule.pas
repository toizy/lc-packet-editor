unit DLL.HideModule;

interface

uses
	Winapi.Windows,
	System.SysUtils
	;

procedure HideThisModule;

implementation

{$REGION 'NTDDK Definitions'}

const
	FLS_MAXIMUM_AVAILABLE = 128;

type
	WOW64_POINTER = ULONG;

	UNICODE_STRING = record
		Length: WORD;
		MaximumLength: WORD;
		Buffer: PWideChar;
	end;
	PUNICODE_STRING = ^UNICODE_STRING;

	UNICODE_STRING32 = record
		Length: USHORT;
		MaximumLength: USHORT;
		Buffer: ULONG;
	end;

	TUNICODE_STRING = packed record
		Length: WORD;
		MaximumLength: WORD;
		Buffer: array [0 .. MAX_PATH - 1] of WideChar;
	end;

	LIST_ENTRY_32 = record
		FLink, BLink: ULONG;
	end;

	RTL_DRIVE_LETTER_CURDIR = record
		Flags: WORD;
		Length: WORD;
		TimeStamp: ULONG;
		DosPath: UNICODE_STRING;
	end;

	PRTL_USER_PROCESS_PARAMETERS = ^RTL_USER_PROCESS_PARAMETERS;

	RTL_USER_PROCESS_PARAMETERS = record
		MaximumLength: ULONG;
		Length: ULONG;
		Flags: ULONG;
		DebugFlags: ULONG;
		ConsoleHandle: PVOID;
		ConsoleFlags: ULONG;
		StdInputHandle: PVOID;
		StdOutputHandle: PVOID;
		StdErrorHandle: PVOID;
		CurrentDirectoryPath: UNICODE_STRING;
		CurrentDirectoryHandle: PVOID;
		DllPath: UNICODE_STRING;
		ImagePathName: UNICODE_STRING;
		CommandLine: UNICODE_STRING;
		Environment: PVOID;
		StartingPositionLeft: ULONG;
		StartingPositionTop: ULONG;
		Width: ULONG;
		Height: ULONG;
		CharWidth: ULONG;
		CharHeight: ULONG;
		ConsoleTextAttributes: ULONG;
		WindowFlags: ULONG;
		ShowWindowFlags: ULONG;
		WindowTitle: UNICODE_STRING;
		DesktopName: UNICODE_STRING;
		ShellInfo: UNICODE_STRING;
		RuntimeData: UNICODE_STRING;
		DLCurrentDirectory: array [0 .. 31] of RTL_DRIVE_LETTER_CURDIR;
		EnvironmentSize: ULONG;
	end;

	PPEB = ^TPEB;

	TPEB = record
		InheritedAddressSpace: BOOLEAN;
		ReadImageFileExecOptions: BOOLEAN;
		BeingDebugged: BOOLEAN;
		BitField: BOOLEAN;
		{
		  BOOLEAN ImageUsesLargePages : 1;
		  BOOLEAN IsProtectedProcess : 1;
		  BOOLEAN IsLegacyProcess : 1;
		  BOOLEAN IsImageDynamicallyRelocated : 1;
		  BOOLEAN SkipPatchingUser32Forwarders : 1;
		  BOOLEAN IsPackagedProcess : 1;
		  BOOLEAN IsAppContainer : 1;
		  BOOLEAN SpareBits : 1;
		}
		Mutant: THandle;
		ImageBaseAddress: PVOID;
		LoaderData: PVOID;
		ProcessParameters: PRTL_USER_PROCESS_PARAMETERS;
		SubSystemData: PVOID;
		ProcessHeap: PVOID;
		FastPebLock: PRTLCriticalSection;
		AtlThunkSListPtr: PVOID;
		IFEOKey: PVOID;
		EnvironmentUpdateCount: ULONG;
		UserSharedInfoPtr: PVOID;
		SystemReserved: ULONG;
		AtlThunkSListPtr32: ULONG;
		ApiSetMap: PVOID;
		TlsExpansionCounter: ULONG;
		TlsBitmap: PVOID;
		TlsBitmapBits: array [0 .. 1] of ULONG;
		ReadOnlySharedMemoryBase: PVOID;
		HotpatchInformation: PVOID;
		ReadOnlyStaticServerData: PPVOID;
		AnsiCodePageData: PVOID;
		OemCodePageData: PVOID;
		UnicodeCaseTableData: PVOID;

		KeNumberOfProcessors: ULONG;
		NtGlobalFlag: ULONG;

		CriticalSectionTimeout: LARGE_INTEGER;
		HeapSegmentReserve: SIZE_T;
		HeapSegmentCommit: SIZE_T;
		HeapDeCommitTotalFreeThreshold: SIZE_T;
		HeapDeCommitFreeBlockThreshold: SIZE_T;

		NumberOfHeaps: ULONG;
		MaximumNumberOfHeaps: ULONG;
		ProcessHeaps: PPVOID;

		GdiSharedHandleTable: PVOID;
		ProcessStarterHelper: PVOID;
		GdiDCAttributeList: ULONG;

		LoaderLock: PRTLCriticalSection;

		NtMajorVersion: ULONG;
		NtMinorVersion: ULONG;
		NtBuildNumber: USHORT;
		NtCSDVersion: USHORT;
		PlatformId: ULONG;
		Subsystem: ULONG;
		MajorSubsystemVersion: ULONG;
		MinorSubsystemVersion: ULONG;
		AffinityMask: ULONG_PTR;
{$IFDEF WIN32}
		GdiHandleBuffer: array [0 .. 33] of ULONG;
{$ELSE}
		GdiHandleBuffer: array [0 .. 59] of ULONG;
{$ENDIF}
		PostProcessInitRoutine: PVOID;

		TlsExpansionBitmap: PVOID;
		TlsExpansionBitmapBits: array [0 .. 31] of ULONG;

		SessionId: ULONG;

		AppCompatFlags: ULARGE_INTEGER;
		AppCompatFlagsUser: ULARGE_INTEGER;
		pShimData: PVOID;
		AppCompatInfo: PVOID;

		CSDVersion: UNICODE_STRING;

		ActivationContextData: PVOID;
		ProcessAssemblyStorageMap: PVOID;
		SystemDefaultActivationContextData: PVOID;
		SystemAssemblyStorageMap: PVOID;

		MinimumStackCommit: SIZE_T;

		FlsCallback: PPVOID;
		FlsListHead: LIST_ENTRY;
		FlsBitmap: PVOID;
		FlsBitmapBits: array [1 .. FLS_MAXIMUM_AVAILABLE div SizeOf(ULONG) * 8] of ULONG;
		FlsHighIndex: ULONG;

		WerRegistrationData: PVOID;
		WerShipAssertPtr: PVOID;
		pContextData: PVOID;
		pImageHeaderHash: PVOID;

		TracingFlags: ULONG;
		{
		  ULONG HeapTracingEnabled : 1;
		  ULONG CritSecTracingEnabled : 1;
		  ULONG LibLoaderTracingEnabled : 1;
		  ULONG SpareTracingBits : 29;
		}
		CsrServerReadOnlySharedMemoryBase: ULONGLONG;
	end;

	PWOW64_PEB = ^TWOW64_PEB;
	TWOW64_PEB = record
		InheritedAddressSpace: BOOLEAN;
		ReadImageFileExecOptions: BOOLEAN;
		BeingDebugged: BOOLEAN;
		BitField: BOOLEAN;
			{
				BOOLEAN ImageUsesLargePages : 1;
				BOOLEAN IsProtectedProcess : 1;
				BOOLEAN IsLegacyProcess : 1;
				BOOLEAN IsImageDynamicallyRelocated : 1;
				BOOLEAN SkipPatchingUser32Forwarders : 1;
				BOOLEAN IsPackagedProcess : 1;
				BOOLEAN IsAppContainer : 1;
				BOOLEAN SpareBits : 1;
			}
		Mutant: WOW64_POINTER;
		ImageBaseAddress: WOW64_POINTER;
		LoaderData: WOW64_POINTER;
		ProcessParameters: WOW64_POINTER;
		SubSystemData: WOW64_POINTER;
		ProcessHeap: WOW64_POINTER;
		FastPebLock: WOW64_POINTER;
		AtlThunkSListPtr: WOW64_POINTER;
		IFEOKey: WOW64_POINTER;
		EnvironmentUpdateCount: ULONG;
		UserSharedInfoPtr: WOW64_POINTER;
		SystemReserved: ULONG;
		AtlThunkSListPtr32: ULONG;
		ApiSetMap: WOW64_POINTER;
		TlsExpansionCounter: ULONG;
		TlsBitmap: WOW64_POINTER;
		TlsBitmapBits: array[0..1] of ULONG;
		ReadOnlySharedMemoryBase: WOW64_POINTER;
		HotpatchInformation: WOW64_POINTER;
		ReadOnlyStaticServerData: WOW64_POINTER;
		AnsiCodePageData: WOW64_POINTER;
		OemCodePageData: WOW64_POINTER;
		UnicodeCaseTableData: WOW64_POINTER;

		KeNumberOfProcessors: ULONG;
		NtGlobalFlag: ULONG;

		CriticalSectionTimeout: LARGE_INTEGER;
		HeapSegmentReserve: WOW64_POINTER;
		HeapSegmentCommit: WOW64_POINTER;
		HeapDeCommitTotalFreeThreshold: WOW64_POINTER;
		HeapDeCommitFreeBlockThreshold: WOW64_POINTER;

		NumberOfHeaps: ULONG;
		MaximumNumberOfHeaps: ULONG;
		ProcessHeaps: WOW64_POINTER;

		GdiSharedHandleTable: WOW64_POINTER;
		ProcessStarterHelper: WOW64_POINTER;
		GdiDCAttributeList: ULONG;

		LoaderLock: WOW64_POINTER;

		NtMajorVersion: ULONG;
		NtMinorVersion: ULONG;
		NtBuildNumber: USHORT;
		NtCSDVersion: USHORT;
		PlatformId: ULONG;
		Subsystem: ULONG;
		MajorSubsystemVersion: ULONG;
		MinorSubsystemVersion: ULONG;
		AffinityMask: WOW64_POINTER;
		GdiHandleBuffer: array [0..33] of ULONG;
		PostProcessInitRoutine: WOW64_POINTER;

		TlsExpansionBitmap: WOW64_POINTER;
		TlsExpansionBitmapBits: array [0..31] of ULONG;

		SessionId: ULONG;

		AppCompatFlags: ULARGE_INTEGER;
		AppCompatFlagsUser: ULARGE_INTEGER;
		pShimData: WOW64_POINTER;
		AppCompatInfo: WOW64_POINTER;

		CSDVersion: UNICODE_STRING32;

		ActivationContextData: WOW64_POINTER;
		ProcessAssemblyStorageMap: WOW64_POINTER;
		SystemDefaultActivationContextData: WOW64_POINTER;
		SystemAssemblyStorageMap: WOW64_POINTER;

		MinimumStackCommit: WOW64_POINTER;

		FlsCallback: WOW64_POINTER;
		FlsListHead: LIST_ENTRY_32;
		FlsBitmap: WOW64_POINTER;
		FlsBitmapBits: array [1..FLS_MAXIMUM_AVAILABLE div SizeOf(ULONG) * 8] of ULONG;
		FlsHighIndex: ULONG;

		WerRegistrationData: WOW64_POINTER;
		WerShipAssertPtr: WOW64_POINTER;
		pContextData: WOW64_POINTER;
		pImageHeaderHash: WOW64_POINTER;

		TracingFlags: ULONG;
		{
			ULONG HeapTracingEnabled : 1;
			ULONG CritSecTracingEnabled : 1;
			ULONG LibLoaderTracingEnabled : 1;
			ULONG SpareTracingBits : 29;
		}
		CsrServerReadOnlySharedMemoryBase: ULONGLONG;
  end;

	PPROCESS_BASIC_INFORAMTION = ^PROCESS_BASIC_INFORMATION;

	PROCESS_BASIC_INFORMATION = record
		ExitStatus: LONG;
		PebBaseAddress: PPEB;
		AffinityMask: ULONG_PTR;
		BasePriority: LONG;
		uUniqueProcessId: ULONG_PTR;
		uInheritedFromUniqueProcessId: ULONG_PTR;
	end;

	TPebLdrData = packed record
		Length: Cardinal; // 0h
		Initialized: LongBool; // 4h
		SsHandle: THandle; // 8h
		InLoadOrderModuleList: TListEntry; // 0Ch
		InMemoryOrderModuleList: TListEntry; // 14h
		InInitializationOrderModuleList: TListEntry; // 1Ch
	end;

	PLdrModule = ^TLdrModule;

	TLdrModule = packed record
		InLoadOrderModuleList: TListEntry; // 0h
		InMemoryOrderModuleList: TListEntry; // 8h
		InInitializationOrderModuleList: TListEntry; // 10h
		BaseAddress: THandle; // 18h
		EntryPoint: THandle; // 1Ch
		SizeOfImage: Cardinal; // 20h
		FullDllName: UNICODE_STRING; // 24h
		// Length (2)         24h
		// MaximumLength (2)  26h
		// Buffer (4)         28h
		BaseDllName: UNICODE_STRING; // 2Ch
		Flags: ULONG; // 34h
		LoadCount: SHORT; // 38h
		TlsIndex: SHORT; // 3Ah
		HashTableEntry: TListEntry; // 3Ch
		TimeDataStamp: ULONG; // 44h
	end;

{$ENDREGION 'NTDDK Definitions'}

function GetPEB(): Pointer;
asm
	push    eax
{$IFDEF WIN32}
	mov     eax, fs:$30;
{$ELSE}
	mov     eax, gs:$60;
{$ENDIF}
	mov     Result, eax
	pop     eax
end;

// Unlinking the DLL image from Process Environment Block of a process
procedure UnlinkImage;
var
	CurModule: TPebLdrData;
	MODULE: PLdrModule;
	i: Integer;
	PEB: PPEB;
begin
	PEB := GetPEB;
	CurModule := TPebLdrData(PEB^.LoaderData^);
	i := 0;
	repeat
		if (i >= MAX_PATH) then
			Break;
		// Flink = Forward Link
		// Blink = Backward Link
		MODULE := PLdrModule(CurModule.InLoadOrderModuleList.Flink);
		if (MODULE^.BaseAddress = HInstance) then
		begin
			//MessageBox(0, PChar(string(MODULE^.FullDllName.Buffer)), '', MB_TOPMOST);
			MODULE^.InLoadOrderModuleList.Blink.Flink := MODULE^.InLoadOrderModuleList.Flink;
			MODULE^.InLoadOrderModuleList.Flink.Blink := MODULE^.InLoadOrderModuleList.Blink;

			MODULE^.InInitializationOrderModuleList.Blink.Flink := MODULE^.InInitializationOrderModuleList.Flink;
			MODULE^.InInitializationOrderModuleList.Flink.Blink := MODULE^.InInitializationOrderModuleList.Blink;

			MODULE^.TlsIndex := 0;
			MODULE^.TimeDataStamp := 0;
			MODULE^.SizeOfImage := 0;
			MODULE^.EntryPoint := 0;
			MODULE^.Flags := 0;
		end;
		CurModule.InLoadOrderModuleList.Flink := CurModule.InLoadOrderModuleList.Flink.Flink;
		i := i + 1;
	until (not True);
end;

procedure ErasePEHeader;
var
	pDosHeader: PImageDosHeader;
	pNTHeader: PImageNtHeaders;
	Protect: Cardinal;
	Size: Word;
begin
	pDosHeader := PImageDosHeader(HInstance);
	pNTHeader := PImageNtHeaders(NativeUInt(pDosHeader) + NativeUInt(pDosHeader^._lfanew));

	if (pNTHeader^.Signature <> IMAGE_NT_SIGNATURE) then
		Exit;

	if (pNTHeader^.FileHeader.SizeOfOptionalHeader > 0) then
	begin
		Size := pNTHeader^.FileHeader.SizeOfOptionalHeader;
		VirtualProtect(Pointer(HInstance), Size, PAGE_EXECUTE_READWRITE, @Protect);
		FillMemory(Pointer(HInstance), Size, 0);
		VirtualProtect(Pointer(HInstance), Size, Protect, @Protect);
	end;
end;

procedure HideThisModule;
begin
	UnlinkImage;
	ErasePEHeader;
end;

end.

