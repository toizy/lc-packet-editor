unit uFiltersForm;

interface

uses
	Winapi.Windows,
	Winapi.Messages,
	System.SysUtils,
	System.Variants,
	System.Classes,
	Vcl.Graphics,
	Vcl.Controls,
	Vcl.Forms,
	Vcl.Dialogs,
	Vcl.StdCtrls,
	System.JSON
	;

type
	TFiltersForm = class(TForm)
		rbIgnoreThese: TRadioButton;
		rbIgnoreExcept: TRadioButton;
		rbNoRules: TRadioButton;
		lb: TListBox;
		cbTypes: TComboBox;
		procedure FormCreate(Sender: TObject);
		procedure cbTypesCloseUp(Sender: TObject);
        procedure lbKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
        procedure FormClose(Sender: TObject; var Action: TCloseAction);
	private
		{ Private declarations }
	public
		{ Public declarations }
	end;

var
	FiltersForm: TFiltersForm;

implementation

uses
	Network.Consts,
	Settings,
	MainFormLogic
	;

{$R *.dfm}

procedure TFiltersForm.cbTypesCloseUp(Sender: TObject);
begin
	if (cbTypes.ItemIndex < 0) then
		Exit;

	lb.Items.AddObject(
		cbTypes.Items[cbTypes.ItemIndex],
		cbTypes.Items.Objects[cbTypes.ItemIndex]
	);

	LKeeper.FilterMask[Integer(cbTypes.Items.Objects[cbTypes.ItemIndex])] := True;

	cbTypes.ItemIndex := -1;
end;

procedure TFiltersForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	if (rbNoRules.Checked) then
		LKeeper.FilterMode := fmode_none
	else if (rbIgnoreThese.Checked) then
		LKeeper.FilterMode := fmode_ignore
	else if (rbIgnoreExcept.Checked) then
		LKeeper.FilterMode := fmode_allow;
end;

procedure TFiltersForm.FormCreate(Sender: TObject);
var
	i: Integer;
begin
	case LKeeper.FilterMode of
		fmode_none:
			rbNoRules.Checked := True;
		fmode_ignore:
			rbIgnoreThese.Checked := True;
		fmode_allow:
			rbIgnoreExcept.Checked := True;
	end;

	for i := 0 to Integer(MSG_MAX) - 1 do
		cbTypes.Items.AddObject(Ti.ToString, TObject(i));

	for i := 0 to Length(LKeeper.FilterMask) - 1 do
		if (LKeeper.FilterMask[i]) then
		begin
			lb.Items.AddObject(
				i.ToString,
				TObject(i)
			);
		end;


	cbTypes.ItemIndex := -1;
//	LoadSettings;
end;

procedure TFiltersForm.lbKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
	Index: Integer;
begin
	if (lb.ItemIndex < 0) then
		Exit;

	if (Key = VK_DELETE) then
	begin
		Index := Integer(lb.Items.Objects[lb.ItemIndex]);
		LKeeper.FilterMask[Index] := False;
		lb.Items.Delete(lb.ItemIndex);
	end;
end;

end.
