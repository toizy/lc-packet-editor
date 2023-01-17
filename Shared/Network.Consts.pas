unit Network.Consts;

interface

uses
	System.SysUtils;

type
	TNetworkMessageType = (
		MSG_UNKNOWN = 0,
		MSG_FAIL,
		MSG_DB,
		MSG_LOGIN,
		MSG_MENU,
		MSG_START_GAME,
		MSG_STATUS,
		MSG_APPEAR,
		MSG_DISAPPEAR,
		MSG_AT,
		MSG_INVENTORY,
		MSG_WEARING,
		MSG_MOVE,
		MSG_ATTACK,
		MSG_DAMAGE,
		MSG_CHAT,
		MSG_ITEM,
		MSG_SYS,
		MSG_GO_ZONE,
		MSG_GOTO,
		MSG_EXCHANGE,
		MSG_MEMPOS,
		MSG_ENV,
		MSG_GM,
		MSG_PARTY,
		MSG_QUICKSLOT,
		MSG_NPC_REGEN,
		MSG_SKILL,
		MSG_ASSIST,
		MSG_CHAR_STATUS,
		MSG_PC_REBIRTH,
		MSG_EFFECT,
		MSG_EXP_SP,
		MSG_ACTION,
		MSG_LOGINSERV_PLAYER,
		MSG_QUEST,
		MSG_STATPOINT,
		MSG_WARP,
		MSG_PULSE,
		MSG_RANDOM_PRODUCE,
		MSG_SSKILL,
		MSG_PK,
		MSG_GUILD,
		MSG_EVENT,
		MSG_PERSONALSHOP,
		MSG_RIGHT_ATTACK,
		MSG_STASH,
		MSG_CHANGE,
		MSG_UI,
		MSG_TEACH,
		MSG_CHANGEJOB,
		MSG_FRIEND,
		MSG_PD_ATTACK,
		MSG_PD_MOVE,
		MSG_SELECT_PRODUCE,
		MSG_EXTEND,
		MSG_RECOVER_EXP_SP,
		MSG_MONEY,
{$IFDEF HP_PERCENTAGE}
		MSG_DAMAGE_REAL = 58,
		XXXMSG_MEMPOSPLUS = MSG_DAMAGE_REAL,
{$ELSE}
		XXXMSG_MEMPOSPLUS,
{$ENDIF}
		MSG_BILLINFO = 60,
		MSG_TRADEAGENT,
		MSG_EXPEDITION,
		MSG_FACTORY,
		MSG_RAID,
		MSG_PET_STASH,
		MSG_RVR,
{$IFDEF DURABILITY}
		MSG_DURABILITY,
{$ENDIF}
		MSG_GPS,
		MSG_ITEMCOLLECTION,
{$IFDEF PREMIUM_CHAR}
		MSG_PREMIUM_CHAR = 95,
{$ENDIF}
		MSG_UPDATE_DATA_FOR_CLIENT = 96,
		MSG_RESERVED_GM_COMMAND = 97,
		MSG_TIMER_ITEM = 98,
		MSG_EXPRESS_SYSTEM = 99,
		MSG_MAX
	);

    TNetworkMessageTypeHelper = record helper for TNetworkMessageType
    public
    	function ToString: string;
    end;

const
	TNetworkMessageTypeStr: array [0..Integer(MSG_MAX)] of string = (
		'MSG_UNKNOWN',
		'MSG_FAIL',
		'MSG_DB',
		'MSG_LOGIN',
		'MSG_MENU',
		'MSG_START_GAME',
		'MSG_STATUS',
		'MSG_APPEAR',
		'MSG_DISAPPEAR',
		'MSG_AT',
		'MSG_INVENTORY',
		'MSG_WEARING',
		'MSG_MOVE',
		'MSG_ATTACK',
		'MSG_DAMAGE',
		'MSG_CHAT',
		'MSG_ITEM',
		'MSG_SYS',
		'MSG_GO_ZONE',
		'MSG_GOTO',
		'MSG_EXCHANGE',
		'MSG_MEMPOS',
		'MSG_ENV',
		'MSG_GM',
		'MSG_PARTY',
		'MSG_QUICKSLOT',
		'MSG_NPC_REGEN',
		'MSG_SKILL',
		'MSG_ASSIST',
		'MSG_CHAR_STATUS',
		'MSG_PC_REBIRTH',
		'MSG_EFFECT',
		'MSG_EXP_SP',
		'MSG_ACTION',
		'MSG_LOGINSERV_PLAYER',
		'MSG_QUEST',
		'MSG_STATPOINT',
		'MSG_WARP',
		'MSG_PULSE',
		'MSG_RANDOM_PRODUCE',
		'MSG_SSKILL',
		'MSG_PK',
		'MSG_GUILD',
		'MSG_EVENT',
		'MSG_PERSONALSHOP',
		'MSG_RIGHT_ATTACK',
		'MSG_STASH',
		'MSG_CHANGE',
		'MSG_UI',
		'MSG_TEACH',
		'MSG_CHANGEJOB',
		'MSG_FRIEND',
		'MSG_PD_ATTACK',
		'MSG_PD_MOVE',
		'MSG_SELECT_PRODUCE',
		'MSG_EXTEND',
		'MSG_RECOVER_EXP_SP',
		'MSG_MONEY',
{$IFDEF HP_PERCENTAGE}
		'MSG_DAMAGE_REAL',
		'XXXMSG_MEMPOSPLUS',
{$ELSE}
		'XXXMSG_MEMPOSPLUS',
		'',
{$ENDIF}
		'MSG_BILLINFO',
		'MSG_TRADEAGENT',
		'MSG_EXPEDITION',
		'MSG_FACTORY',
		'MSG_RAID',
		'MSG_PET_STASH',
		'MSG_RVR',
{$IFDEF DURABILITY}
		'MSG_DURABILITY',
{$ENDIF}
		'MSG_GPS',
		'MSG_ITEMCOLLECTION',
		'', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
{$IFDEF PREMIUM_CHAR}
		'MSG_PREMIUM_CHAR',//95
{$ELSE}
		'',
{$ENDIF}
		'MSG_UPDATE_DATA_FOR_CLIENT',
		'MSG_RESERVED_GM_COMMAND',
		'MSG_TIMER_ITEM',
		'MSG_EXPRESS_SYSTEM',
		'MSG_MAX'
	);

	MAX_ID_NAME_LENGTH = 64;
    MAX_PWD_LENGTH = 32;

type
	// Auxiliary types (for RTTI and JSON serializer)
    TLoginID = array [0 .. MAX_ID_NAME_LENGTH + 1] of Byte;
    TLoginPW = array [0 .. MAX_PWD_LENGTH + 1] of Byte;

    TMsgLoginType = (
		MSG_LOGIN_NEW,
		MSG_LOGIN_RE,
		MSG_LOGIN_GM
	);

	TMsgMoveType = (
		MSG_MOVE_WALK,
		MSG_MOVE_RUN,
		MSG_MOVE_PLACE,
		MSG_MOVE_STOP,
		MSG_MOVE_FLY
	);

    //TNetworkMessageType equivalent
	TTypeBase = packed record
    	NMType:		Byte;   // Type of the message
    	NMSubType:	Byte;	// Subtype - always 0
    end;
    PTypeBase = ^TTypeBase;

    TLoginFromClient = packed record
    	TypeBase: 	TTypeBase;
        mode:		TMsgLoginType;
		nation:		Byte;
		version:	Integer;
		id:			TLoginID;
		pw:			TLoginPW;
	end;
    PLoginFromClient = ^TLoginFromClient;

	TMsgMove = packed record
		TypeBase: 	TTypeBase;
		CharType:	Byte;			// CEntity::GetNetworkType()
		MoveType:	TMsgMoveType;
		YLayer:		ShortInt;
		Index:		Integer;
		Speed:		Single;
		X, Z, H, R:	Single;
	end;
    PMsgMove = ^TMsgMove;

    TDoAttack = packed record
        TypeBase: 	TTypeBase;
		tIndex:		Integer;
		aIndex:		Integer;
		tCharType:	Byte;
		aCharType:	Byte;
		attackType:	Byte;
		multicount:	ShortInt;
		List:		array of Integer;	// mob ids
	end;
    PDoAttack = ^TDoAttack;

    tag_list = packed record
    	mtargettype: 	Byte;
        mtargetindex:	Integer;

    end;

    TFireSkill = packed record
        TypeBase: 			TTypeBase;
        skillIndex:			Integer;
        cMoveChar:			Byte;
        charType:			Byte;
        targetType:			Byte;
        charIndex:			Integer;
        targetIndex:		Integer;
        nDummySkillSpeed:	Integer;
        fx, fz, fh, fr:		Single;
        cYlayer:			Byte;
        listCount:			Byte;
        List: array of tag_list;
	end;
    PFireSkill = ^TFireSkill;

	// Teleport between locations
	PMsgWarpToGuildWarArea = ^TMsgWarpToGuildWarArea;
	TMsgWarpToGuildWarArea = packed record
	public
		MsgType: Byte;		//$25
		SubType: Byte;  	//$04
		Zone: NativeUInt;	//0+
		SubZone: NativeUInt;//0+
	private const
		MSG_MAGIC: Word = $0425;
	public
		class function Build(Zone: NativeUInt; SubZone: NativeUInt = 0): TMsgWarpToGuildWarArea; static;
	end;

implementation

function FastSwap(Value: LongWord): LongWord; register;
asm
	bswap eax
end;

{ TMsgWarpToGuildWarArea }

class function TMsgWarpToGuildWarArea.Build(Zone, SubZone: NativeUInt): TMsgWarpToGuildWarArea;
begin
	PWord(@Result)^ := MSG_MAGIC;
	Result.Zone := FastSwap(Zone);
	Result.SubZone := FastSwap(SubZone);
end;

{ TNetworkMessageTypeHelper }

function TNetworkMessageTypeHelper.ToString: string;
begin
	Result := TNetworkMessageTypeStr[Integer(Self)];
end;

end.
