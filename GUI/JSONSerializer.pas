unit JSONSerializer;

interface

uses
	Winapi.Windows,
	System.SysUtils,
	System.Rtti,
	System.TypInfo,
	System.JSON,
	System.Generics.Collections,
	System.Classes
	;

type
	SerializedNameAttribute = class(TCustomAttribute)
	strict private
		FName: string;
	public
		constructor Create(const name: string);
		property name: string read FName;
	end;

	DefValueAttribute = class(TCustomAttribute)
	strict private
		FValue: TValue;
	public
		constructor Create(const defValue: Integer); overload;
		constructor Create(const defValue: string); overload;
		constructor Create(const defValue: Single); overload;
		constructor Create(const defValue: Double); overload;
		constructor Create(const defValue: Extended); overload;
		constructor Create(const defValue: Currency); overload;
		constructor Create(const defValue: Int64); overload;
		constructor Create(const defValue: Boolean); overload;
		property defVal: TValue read FValue;
	end;

	EDSONException = class(Exception);

	TDSON = record
	public
		class function fromJson<T>(const JSON: string): T; overload; static;
		class function fromJson<T>(const jsonStream: TStream): T; overload; static;
		class function toJson<T>(const value: T; const Format: Boolean = True; const ignoreUnknownTypes: Boolean = False): string; static;
        class function toJsonObject<T>(const value: T; const Format: Boolean = True; const ignoreUnknownTypes: Boolean = False): TJSONValue; static;
	end;

	IMap<K, V> = interface
		['{830D3690-DAEF-40D1-A186-B6B105462D89}']
		function getKeys(): TEnumerable<K>;
		function getValues(): TEnumerable<V>;

		procedure add(const key: K; const value: V);
		procedure remove(const key: K);
		function extractPair(const key: K): TPair<K, V>;
		procedure clear;
		function getValue(const key: K): V;
		function tryGetValue(const key: K; out value: V): Boolean;
		procedure addOrSetValue(const key: K; const value: V);
		function containsKey(const key: K): Boolean;
		function containsValue(const value: V): Boolean;
		function toArray(): TArray<TPair<K, V>>;
		function getCount(): Integer;

		function getEnumerator: TEnumerator<TPair<K, V>>;
		property keys: TEnumerable<K> read getKeys;
		property values: TEnumerable<V> read getValues;

		property items[const key: K]: V read getValue write addOrSetValue;
		property count: Integer read getCount;
	end;

	TMapClass<K, V> = class(TInterfacedObject, IMap<K, V>)
	private
		FMap: TDictionary<K, V>;
	public
		constructor Create();
		destructor Destroy(); override;

		function getKeys(): TEnumerable<K>;
		function getValues(): TEnumerable<V>;

		procedure add(const key: K; const value: V);
		procedure remove(const key: K);
		function extractPair(const key: K): TPair<K, V>;
		procedure clear;
		function getValue(const key: K): V;
		function tryGetValue(const key: K; out value: V): Boolean;
		procedure addOrSetValue(const key: K; const value: V);
		function containsKey(const key: K): Boolean;
		function containsValue(const value: V): Boolean;
		function toArray(): TArray<TPair<K, V>>;
		function getCount(): Integer;

		function getEnumerator: TEnumerator<TPair<K, V>>;
		property keys: TEnumerable<K> read getKeys;
		property values: TEnumerable<V> read getValues;

		property items[const key: K]: V read getValue write addOrSetValue;
		property count: Integer read getCount;
	end;

	TMap<K, V> = record
	private
		FMapIntf: IMap<K, V>;
{$HINTS OFF}
		FValueType: V;
		FKeyType: K;
{$HINTS ON}
		function getMap(): IMap<K, V>;
	public
		function getKeys(): TEnumerable<K>;
		function getValues(): TEnumerable<V>;

		procedure add(const key: K; const value: V);
		procedure remove(const key: K);
		function extractPair(const key: K): TPair<K, V>;
		procedure clear;
		function getValue(const key: K): V;
		function tryGetValue(const key: K; out value: V): Boolean;
		procedure addOrSetValue(const key: K; const value: V);
		function containsKey(const key: K): Boolean;
		function containsValue(const value: V): Boolean;
		function toArray(): TArray<TPair<K, V>>;
		function getCount(): Integer;

		function getEnumerator: TEnumerator<TPair<K, V>>;
		property keys: TEnumerable<K> read getKeys;
		property values: TEnumerable<V> read getValues;

		property items[const key: K]: V read getValue write addOrSetValue;
		property count: Integer read getCount;
	end;

type
	TDSONBase = class
	private
		class var booleanTi: Pointer;
	protected
		FRttiContext: TRttiContext;
		function getObjInstance(const value: TValue): Pointer;
	public
		constructor Create();
		destructor Destroy(); override;
	end;

	TDSONValueReader = class(TDSONBase)
	strict private
    	function readIntegerValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
		function readInt64Value(const rttiType: TRttiType; const jv: TJSONValue): TValue;
		function readFloatValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
		function readStringValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
		function readEnumValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
		function readClassValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
		function readRecordValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
		function readDynArrayValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
		function readDynArrayValues(const rttiType: TRttiType; const jv: TJSONValue): TArray<TValue>;
		function readSetValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;

		procedure setObjValue(const instance: TValue; const rttiMember: TRttiMember; const jv: TJSONValue);
		procedure fillObjectValue(const instance: TValue; const jo: TJSONObject);
		procedure fillMapValue(const instance: TValue; const jo: TJSONObject);
		function tryReadValueFromJson(const rttiType: TRttiType; const jv: TJSONValue; var outV: TValue): Boolean;
	public
		function processRead(const _typeInfo: PTypeInfo; const jv: TJSONValue): TValue;
	end;

	TDSONValueWriter = class(TDSONBase)
	strict private
		FIgnoreUnknownTypes: Boolean;
		function writeIntegerValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
		function writeInt64Value(const rttiType: TRttiType; const value: TValue): TJSONValue;
		function writeFloatValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
		function writeStringValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
		function writeEnumValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
		function writeClassValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
		function writeDynArrayValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
		function writeSetValue(const rttiType: TRttiType; const value: TValue): TJSONValue;

		function getObjValue(const instance: TValue; const rttiMember: TRttiMember): TJSONValue;
		function writeObject(const instance: TValue): TJSONObject;
		function writeMap(const instance: TValue): TJSONObject;
		function tryWriteJsonValue(const value: TValue; var jv: TJSONValue): Boolean;
	public
		function processWrite(const value: TValue; const ignoreUnknownTypes: Boolean): TJSONValue;
	end;

function DSON(): TDSON;

resourcestring
	rsNotSupportedType = 'Not supported type %s, type kind: %s';
	rsInvalidJsonArray = 'Json value is not array.';
	rsInvalidJsonObject = 'Json value is not object.';

implementation

const
	MAP_PREFIX = 'TMap<';

function DSON(): TDSON;
begin
end;

type
	TRttiMemberHelper = class helper for TRttiMember
	private
		function hasAttribute<A: TCustomAttribute>(var attr: A): Boolean; overload;
	public
		procedure setValue(const instance: Pointer; const value: TValue);
		function getValue(const instance: Pointer): TValue;
		function getType(): TRttiType;
		function canWrite(): Boolean;
		function canRead(): Boolean;
		function getName(): string;
	end;

	{ TDSONValueReader }

procedure TDSONValueReader.fillMapValue(const instance: TValue; const jo: TJSONObject);
var
	rttiType: TRttiType;
	addMethod: TRttiMethod;
	valueType: TRttiType;
	keyType: TRttiType;
	jp: TJSONPair;

	key: TValue;
	value: TValue;
begin
	rttiType := FRttiContext.getType(instance.TypeInfo);

	addMethod := rttiType.GetMethod('addOrSetValue');
	keyType := rttiType.GetField('FKeyType').FieldType;
	valueType := rttiType.GetField('FValueType').FieldType;

	for jp in jo do
	begin
		if tryReadValueFromJson(keyType, jp.JsonString, key) and tryReadValueFromJson(valueType, jp.JsonValue, value) then
			addMethod.Invoke(instance, [key, value])
	end;
end;

procedure TDSONValueReader.fillObjectValue(const instance: TValue; const jo: TJSONObject);

	procedure processReadRttiMember(const rttiMember: TRttiMember);
	var
		propertyName: string;
		jv: TJSONValue;
	begin
		if not((rttiMember.Visibility in [mvPublic, mvPublished]) and rttiMember.canWrite()) then
			Exit();

		propertyName := rttiMember.getName();
		jv := jo.getValue(propertyName);
		setObjValue(instance, rttiMember, jv);
	end;

var
	rttiType: TRttiType;
	rttiMember: TRttiMember;
begin
	rttiType := FRttiContext.getType(instance.TypeInfo);
	for rttiMember in rttiType.GetDeclaredProperties() do
		processReadRttiMember(rttiMember);
	for rttiMember in rttiType.GetDeclaredFields() do
		processReadRttiMember(rttiMember);
end;

function TDSONValueReader.readEnumValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
var
	enumItemName: string;
	i: Int64;
begin
	if rttiType.Handle = booleanTi then
		Result := jv.getValue<Boolean>()
	else
	begin
		enumItemName := jv.value;
		i := GetEnumValue(rttiType.Handle, enumItemName);
		Result := TValue.FromOrdinal(rttiType.Handle, i);
	end;
end;

function TDSONValueReader.readClassValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
var
	ret: TValue;
begin
	if not(jv is TJSONObject) then
		raise EDSONException.Create(rsInvalidJsonObject);

	ret := rttiType.GetMethod('Create').Invoke(rttiType.AsInstance.MetaclassType, []);
	try
		fillObjectValue(ret, jv as TJSONObject);
		Result := ret;
	except
		ret.AsObject.Free();
		raise;
	end;
end;

function TDSONValueReader.readDynArrayValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
begin
	Result := TValue.FromArray(rttiType.Handle, readDynArrayValues(rttiType, jv));
end;

function TDSONValueReader.readDynArrayValues(const rttiType: TRttiType; const jv: TJSONValue): TArray<TValue>;
var
	ja: TJSONArray;
	jav: TJSONValue;
	i: Integer;
	values: TArray<TValue>;
	elementType: TRttiType;
begin
	if not(jv is TJSONArray) then
		raise EDSONException.Create(rsInvalidJsonArray);

	ja := jv as TJSONArray;
	elementType := (rttiType as TRttiDynamicArrayType).elementType;
	SetLength(values, ja.count);
	for i := 0 to ja.count - 1 do
	begin
		values[i] := TValue.Empty;
		jav := ja.items[i];
		tryReadValueFromJson(elementType, jav, values[i])
	end;
	Result := values;
end;

function TDSONValueReader.readFloatValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
var
	rft: TRttiFloatType;
begin
	rft := rttiType as TRttiFloatType;
	case rft.FloatType of
		ftSingle:
			Result := jv.getValue<Single>();
		ftDouble:
			Result := jv.getValue<Double>();
		ftExtended:
			Result := jv.getValue<Extended>();
		ftComp:
			Result := jv.getValue<Comp>();
		ftCurr:
			Result := jv.getValue<Currency>();
	end;
end;

function TDSONValueReader.readInt64Value(const rttiType: TRttiType; const jv: TJSONValue): TValue;
begin
	Result := jv.getValue<Int64>();
end;

function TDSONValueReader.readIntegerValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
begin
	Result := jv.getValue<Integer>();
end;

function TDSONValueReader.readRecordValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
var
	ret: TValue;
	rttiRecord: TRttiRecordType;
begin
	if not(jv is TJSONObject) then
		raise EDSONException.Create(rsInvalidJsonObject);

	rttiRecord := rttiType as TRttiRecordType;
	TValue.Make(nil, rttiRecord.Handle, ret);
	if rttiType.name.StartsWith(MAP_PREFIX) then
		fillMapValue(ret, jv as TJSONObject)
	else
		fillObjectValue(ret, jv as TJSONObject);
	Result := ret;
end;

function TDSONValueReader.readSetValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
begin
	TValue.Make(nil, rttiType.Handle, Result);
	StringToSet(rttiType.Handle, jv.getValue<string>(), Result.GetReferenceToRawData());
end;

function TDSONValueReader.readStringValue(const rttiType: TRttiType; const jv: TJSONValue): TValue;
var
	rst: TRttiStringType;
begin
	rst := rttiType as TRttiStringType;
	case rst.StringKind of
		skShortString:
			Result := TValue.From(jv.getValue<ShortString>());
		skAnsiString:
			Result := TValue.From(jv.getValue<AnsiString>());
		skWideString:
			Result := TValue.From(jv.getValue<WideString>());
		skUnicodeString:
			Result := jv.getValue<string>();
	end;
end;

procedure TDSONValueReader.setObjValue(const instance: TValue; const rttiMember: TRttiMember; const jv: TJSONValue);
var
	value: TValue;
	rttiType: TRttiType;
	instanceP: Pointer;
	defValueAttr: DefValueAttribute;
begin
	instanceP := getObjInstance(instance);
	value := rttiMember.getValue(instanceP);
	rttiType := rttiMember.getType();
	if value.IsObject then
		value.AsObject.Free();

	if tryReadValueFromJson(rttiType, jv, value) then
		rttiMember.setValue(instanceP, value)
	else if rttiMember.hasAttribute<DefValueAttribute>(defValueAttr) then
		rttiMember.setValue(instanceP, defValueAttr.defVal);
end;

function TDSONValueReader.processRead(const _typeInfo: PTypeInfo; const jv: TJSONValue): TValue;
begin
	Result := TValue.Empty;
	tryReadValueFromJson(FRttiContext.getType(_typeInfo), jv, Result)
end;

function TDSONValueReader.tryReadValueFromJson(const rttiType: TRttiType; const jv: TJSONValue; var outV: TValue): Boolean;
var
	tk: TTypeKind;
begin
	Result := False;
	if (jv = nil) {or jv.Null} then	// toizy - Убрал проверку на IsNull, потому что она почему-то TRUE
		Exit;

	tk := rttiType.TypeKind;

	case tk of
		tkInteger:
			outV := readIntegerValue(rttiType, jv);
		tkInt64:
			outV := readInt64Value(rttiType, jv);
		tkEnumeration:
			outV := readEnumValue(rttiType, jv);
		tkFloat:
			outV := readFloatValue(rttiType, jv);
		tkString, tkLString, tkWString, tkUString:
			outV := readStringValue(rttiType, jv);
		tkClass:
			outV := readClassValue(rttiType, jv);
		tkDynArray, tkArray:
			outV := readDynArrayValue(rttiType, jv);
		tkRecord:
			outV := readRecordValue(rttiType, jv);
		tkSet:
			outV := readSetValue(rttiType, jv);
	else
		raise EDSONException.CreateFmt(rsNotSupportedType, [rttiType.name]);
	end;
	Result := True;
end;

{ TDSON }

class function TDSON.fromJson<T>(const JSON: string): T;
var
	dvr: TDSONValueReader;
	jv: TJSONValue;
begin
	jv := nil;
	dvr := TDSONValueReader.Create();
	try
		jv := TJSONObject.ParseJSONValue(JSON);
		Result := dvr.processRead(TypeInfo(T), jv).AsType<T>();
	finally
		jv.Free();
		dvr.Free();
	end;
end;

class function TDSON.fromJson<T>(const jsonStream: TStream): T;
var
	dvr: TDSONValueReader;
	jv: TJSONValue;
	jsonData: TArray<Byte>;
begin
	jv := nil;
	dvr := TDSONValueReader.Create();
	try
		jsonStream.Position := 0;
		SetLength(jsonData, jsonStream.Size);
		jsonStream.ReadBuffer(Pointer(jsonData)^, jsonStream.Size);
		jv := TJSONObject.ParseJSONValue(jsonData, 0);
		Result := dvr.processRead(TypeInfo(T), jv).AsType<T>();
	finally
		jv.Free();
		dvr.Free();
	end;
end;

class function TDSON.toJson<T>(const value: T; const Format: Boolean; const ignoreUnknownTypes: Boolean): string;
var
	dvw: TDSONValueWriter;
	jv: TJSONValue;
begin
	Result := '';
	jv := nil;
	dvw := TDSONValueWriter.Create();
	try
		jv := dvw.processWrite(TValue.From(value), ignoreUnknownTypes);
		if (jv <> nil) then
        	if (Format = True) then
            	Result := jv.Format
            else
            	Result := jv.toJson;
	finally
		jv.Free();
		dvw.Free();
	end;
end;

class function TDSON.toJsonObject<T>(const value: T; const Format, ignoreUnknownTypes: Boolean): TJSONValue;
var
	dvw: TDSONValueWriter;
begin
	Result := nil;
	dvw := TDSONValueWriter.Create();
	try
		Result := dvw.processWrite(TValue.From(value), ignoreUnknownTypes);
	finally
		dvw.Free();
	end;
end;

{ TDSONBase }

constructor TDSONBase.Create();
begin
	FRttiContext := TRttiContext.Create();
end;

destructor TDSONBase.Destroy();
begin
	FRttiContext.Free();
	inherited;
end;

function TDSONBase.getObjInstance(const value: TValue): Pointer;
begin
	if value.Kind = tkRecord then
		Result := value.GetReferenceToRawData()
	else if value.Kind = tkClass then
		Result := value.AsObject
	else
		Result := nil;
end;

{ TDSONValueWriter }

function TDSONValueWriter.getObjValue(const instance: TValue; const rttiMember: TRttiMember): TJSONValue;
var
	value: TValue;
	instanceP: Pointer;
begin
	Result := nil;
	instanceP := getObjInstance(instance);
	value := rttiMember.getValue(instanceP);
	tryWriteJsonValue(value, Result);
end;

function TDSONValueWriter.processWrite(const value: TValue; const ignoreUnknownTypes: Boolean): TJSONValue;
begin
	Result := nil;
	FIgnoreUnknownTypes := ignoreUnknownTypes;
	tryWriteJsonValue(value, Result);
end;

function TDSONValueWriter.tryWriteJsonValue(const value: TValue; var jv: TJSONValue): Boolean;
var
	tk: TTypeKind;
	rttiType: TRttiType;
begin
	Result := False;
	if value.IsEmpty then
		Exit();

	rttiType := FRttiContext.getType(value.TypeInfo);
	tk := rttiType.TypeKind;
	case tk of
		tkInteger:
			jv := writeIntegerValue(rttiType, value);
		tkInt64:
			jv := writeInt64Value(rttiType, value);
		tkEnumeration:
			jv := writeEnumValue(rttiType, value);
		tkFloat:
			jv := writeFloatValue(rttiType, value);
		tkString, tkLString, tkWString, tkUString:
			jv := writeStringValue(rttiType, value);
		tkClass, tkRecord:
			jv := writeClassValue(rttiType, value);
		tkDynArray, tkArray:
			jv := writeDynArrayValue(rttiType, value);
		tkSet:
			jv := writeSetValue(rttiType, value);
	else
		if FIgnoreUnknownTypes then
			Exit(False)
		else
			raise EDSONException.CreateFmt(rsNotSupportedType, [rttiType.name, TRttiEnumerationType.getName(tk)]);
	end;
	Result := True;
end;

function TDSONValueWriter.writeClassValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
begin
	if rttiType.name.StartsWith(MAP_PREFIX) then
		Result := writeMap(value)
	else
		Result := writeObject(value);
end;

function TDSONValueWriter.writeDynArrayValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
var
	ret: TJSONArray;
	jv: TJSONValue;
	i: Integer;
begin
	ret := TJSONArray.Create();
	try
		for i := 0 to value.GetArrayLength() - 1 do
		begin
			if tryWriteJsonValue(value.GetArrayElement(i), jv) then
				ret.AddElement(jv);
		end;
	except
		ret.Free();
		raise;
	end;
	Result := ret;
end;

function TDSONValueWriter.writeEnumValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
var
	enumItemName: string;
begin
	if rttiType.Handle = booleanTi then
		Result := TJSONBool.Create(value.AsBoolean)
	else
	begin
		enumItemName := GetEnumName(value.TypeInfo, value.AsOrdinal);
		Result := TJSONString.Create(enumItemName);
	end;
end;

function TDSONValueWriter.writeFloatValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
begin
	Result := TJSONNumber.Create(value.AsExtended);
end;

function TDSONValueWriter.writeInt64Value(const rttiType: TRttiType; const value: TValue): TJSONValue;
begin
	Result := TJSONNumber.Create(value.AsInt64);
end;

function TDSONValueWriter.writeIntegerValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
begin
	Result := TJSONNumber.Create(value.AsInteger);
end;

function TDSONValueWriter.writeMap(const instance: TValue): TJSONObject;
var
	ret: TJSONObject;
	rttiType: TRttiType;
	toArrayMethod: TRttiMethod;
	pairsArray: TValue;
	arrayType: TRttiDynamicArrayType;
	paitType: TRttiType;
	keyField: TRttiField;
	valueField: TRttiField;
	pair: TValue;
	i, c: Integer;
	key: string;
begin
	rttiType := FRttiContext.getType(instance.TypeInfo);

	toArrayMethod := rttiType.GetMethod('toArray');
	pairsArray := toArrayMethod.Invoke(instance, []);
	arrayType := FRttiContext.getType(pairsArray.TypeInfo) as TRttiDynamicArrayType;
	paitType := arrayType.elementType;
	keyField := paitType.GetField('Key');
	valueField := paitType.GetField('Value');

	ret := TJSONObject.Create();
	try
		c := pairsArray.GetArrayLength();
		for i := 0 to c - 1 do
		begin
			pair := pairsArray.GetArrayElement(i);
			key := keyField.getValue(pair.GetReferenceToRawData()).ToString;
			ret.AddPair(TJSONPair.Create(key, getObjValue(pair, valueField)));
		end;
		Result := ret;
	except
		ret.Free();
		raise;
	end;
end;

function TDSONValueWriter.writeObject(const instance: TValue): TJSONObject;
var
	ret: TJSONObject;

	procedure processRttiMember(const rttiMember: TRttiMember);
	var
		propertyName: string;
		jv: TJSONValue;
	begin
		if not((rttiMember.Visibility in [mvPublic, mvPublished]) and rttiMember.canRead()) then
			Exit();

		propertyName := rttiMember.getName();
		jv := getObjValue(instance, rttiMember);
		if jv <> nil then
			ret.AddPair(propertyName, jv);
	end;

var
	rttiType: TRttiType;
	rttiMember: TRttiMember;
begin
	Result := nil;
	if instance.IsEmpty then
		Exit();

	rttiType := FRttiContext.getType(instance.TypeInfo);
	ret := TJSONObject.Create();
	try
		for rttiMember in rttiType.GetDeclaredProperties() do
			processRttiMember(rttiMember);
		for rttiMember in rttiType.GetDeclaredFields() do
			processRttiMember(rttiMember);

		Result := ret;
	except
		ret.Free();
		raise;
	end;
end;

function TDSONValueWriter.writeSetValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
begin
	Result := TJSONString.Create(SetToString(rttiType.Handle, value.GetReferenceToRawData(), True));
end;

function TDSONValueWriter.writeStringValue(const rttiType: TRttiType; const value: TValue): TJSONValue;
begin
	Result := TJSONString.Create(value.AsString);
end;

{ TRttiMemberHelper }

function TRttiMemberHelper.getName(): string;
var
	attr: SerializedNameAttribute;
begin
	if hasAttribute<SerializedNameAttribute>(attr) then
		Result := attr.name
	else
		Result := Self.name;
end;

function TRttiMemberHelper.getType(): TRttiType;
begin
	if Self is TRttiProperty then
		Result := (Self as TRttiProperty).PropertyType
	else if Self is TRttiField then
		Result := (Self as TRttiField).FieldType
	else
		Result := nil;
end;

function TRttiMemberHelper.getValue(const instance: Pointer): TValue;
begin
	if Self is TRttiProperty then
		Result := (Self as TRttiProperty).getValue(instance)
	else if Self is TRttiField then
		Result := (Self as TRttiField).getValue(instance)
	else
		Result := TValue.Empty;
end;

function TRttiMemberHelper.hasAttribute<A>(var attr: A): Boolean;
var
	attribute: TCustomAttribute;
begin
	attr := nil;
	Result := False;
	for attribute in Self.GetAttributes() do
	begin
		if attribute is A then
		begin
			attr := A(attribute);
			Result := True;
			Break;
		end;
	end;
end;

function TRttiMemberHelper.canRead(): Boolean;
begin
	if Self is TRttiProperty then
		Result := (Self as TRttiProperty).IsReadable
	else if Self is TRttiField then
		Result := True
	else
		Result := False;
end;

function TRttiMemberHelper.canWrite(): Boolean;
begin
	if Self is TRttiProperty then
		Result := (Self as TRttiProperty).IsWritable
	else if Self is TRttiField then
		Result := True
	else
		Result := False;
end;

procedure TRttiMemberHelper.setValue(const instance: Pointer; const value: TValue);
begin
	if Self is TRttiProperty then
		(Self as TRttiProperty).setValue(instance, value)
	else if Self is TRttiField then
		(Self as TRttiField).setValue(instance, value)
end;

{ SerializedNameAttribute }

constructor SerializedNameAttribute.Create(const name: string);
begin
	FName := name;
end;

{ DefValueAttribute }

constructor DefValueAttribute.Create(const defValue: Integer);
begin
	FValue := defValue;
end;

constructor DefValueAttribute.Create(const defValue: Double);
begin
	FValue := defValue;
end;

constructor DefValueAttribute.Create(const defValue: Extended);
begin
	FValue := defValue;
end;

constructor DefValueAttribute.Create(const defValue: string);
begin
	FValue := defValue;
end;

constructor DefValueAttribute.Create(const defValue: Single);
begin
	FValue := defValue;
end;

constructor DefValueAttribute.Create(const defValue: Boolean);
begin
	FValue := defValue;
end;

constructor DefValueAttribute.Create(const defValue: Currency);
begin
	FValue := defValue;
end;

constructor DefValueAttribute.Create(const defValue: Int64);
begin
	FValue := defValue;
end;

{ TMapClass<K, V> }

procedure TMapClass<K, V>.add(const key: K; const value: V);
begin
	FMap.add(key, value);
end;

procedure TMapClass<K, V>.addOrSetValue(const key: K; const value: V);
begin
	FMap.addOrSetValue(key, value);
end;

procedure TMapClass<K, V>.clear();
begin
	FMap.clear();
end;

function TMapClass<K, V>.containsKey(const key: K): Boolean;
begin
	Result := FMap.containsKey(key);
end;

function TMapClass<K, V>.containsValue(const value: V): Boolean;
begin
	Result := FMap.containsValue(value);
end;

constructor TMapClass<K, V>.Create();
begin
	FMap := TDictionary<K, V>.Create();
end;

destructor TMapClass<K, V>.Destroy();
begin
	FMap.Free();
	inherited;
end;

function TMapClass<K, V>.extractPair(const key: K): TPair<K, V>;
begin
	Result := FMap.extractPair(key);
end;

function TMapClass<K, V>.getCount(): Integer;
begin
	Result := FMap.count;
end;

function TMapClass<K, V>.getEnumerator(): TEnumerator<TPair<K, V>>;
begin
	Result := FMap.getEnumerator;
end;

function TMapClass<K, V>.getKeys(): TEnumerable<K>;
begin
	Result := FMap.keys;
end;

function TMapClass<K, V>.getValue(const key: K): V;
begin
	Result := FMap[key];
end;

function TMapClass<K, V>.getValues(): TEnumerable<V>;
begin
	Result := FMap.values;
end;

procedure TMapClass<K, V>.remove(const key: K);
begin
	FMap.remove(key);
end;

function TMapClass<K, V>.toArray(): TArray<TPair<K, V>>;
begin
	Result := FMap.toArray;
end;

function TMapClass<K, V>.tryGetValue(const key: K; out value: V): Boolean;
begin
	Result := FMap.tryGetValue(key, value);
end;

{ TMap<K, V> }

procedure TMap<K, V>.add(const key: K; const value: V);
begin
	getMap().add(key, value);
end;

procedure TMap<K, V>.addOrSetValue(const key: K; const value: V);
begin
	getMap().items[key] := value;
end;

procedure TMap<K, V>.clear();
begin
	getMap().clear();
end;

function TMap<K, V>.containsKey(const key: K): Boolean;
begin
	Result := getMap().containsKey(key);
end;

function TMap<K, V>.containsValue(const value: V): Boolean;
begin
	Result := getMap().containsValue(value);
end;

function TMap<K, V>.extractPair(const key: K): TPair<K, V>;
begin
	Result := getMap().extractPair(key);
end;

function TMap<K, V>.getCount(): Integer;
begin
	Result := getMap().count;
end;

function TMap<K, V>.getEnumerator(): TEnumerator<TPair<K, V>>;
begin
	Result := getMap().getEnumerator();
end;

function TMap<K, V>.getKeys(): TEnumerable<K>;
begin
	Result := getMap().keys;
end;

function TMap<K, V>.getMap(): IMap<K, V>;
begin
	if FMapIntf = nil then
		FMapIntf := TMapClass<K, V>.Create();
	Result := FMapIntf;
end;

function TMap<K, V>.getValue(const key: K): V;
begin
	Result := getMap().items[key];
end;

function TMap<K, V>.getValues(): TEnumerable<V>;
begin
	Result := getMap().values;
end;

procedure TMap<K, V>.remove(const key: K);
begin
	getMap().remove(key);
end;

function TMap<K, V>.toArray(): TArray<TPair<K, V>>;
begin
	Result := getMap().toArray();
end;

function TMap<K, V>.tryGetValue(const key: K; out value: V): Boolean;
begin
	Result := getMap().tryGetValue(key, value);
end;

initialization

	TDSONBase.booleanTi := TypeInfo(Boolean);

end.
