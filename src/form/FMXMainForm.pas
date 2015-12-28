unit FMXMainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  hjLunarDateType, CalendarCommons, MakeCalendarController,
  SpecifiedData, SpecifiedDataController;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    edtLunarYear: TEdit;
    edtLunarMonth: TEdit;
    edtLunarDay: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    // �޷»��� ���ü
    FMakeCalendarCtrl: TMakeCalendarController;

    // ����� ������ ���ü
    FSpecifiedDataCtrl: TSpecifiedDateController;

    // ���´޷� ����
    function GetRangeYear(var AStart, AEnd: Word): Boolean;
    function GetLunarDaysDisplayType: TLunarDaysDisplayType;

    // ����� �޷� ����
    procedure DisplaySpecifiedData;
    procedure ShowSpecifiedDialog(AData: TSpecifiedData);

    procedure AppendSpecifiedData(AData: TSpecifiedData);
    procedure DeleteSpecifiedData(AData: TSpecifiedData);
    procedure UpdateSpecifiedData(AData: TSpecifiedData);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.AppendSpecifiedData(AData: TSpecifiedData);
begin

end;

procedure TForm1.Button1Click(Sender: TObject);
var
  Lunar: TLunarDateRec;
  Solar: TSolarDateRec;
begin
  Lunar.Year  := StrToIntDef(edtLunarYear.Text, 0);
  Lunar.Month := StrToIntDef(edtLunarMonth.Text, 0);
  Lunar.Day   := StrToIntDef(edtLunarDay.Text, 0);
  Lunar.IsLeapMonth := False;//chkLunarLeap.Checked;

  try
    Solar := FMakeCalendarCtrl.LunarToSolar(Lunar);

    ShowMessage(Format('���� ''%d�� %d�� %d''����'#13#10#13#10'��� ''%d�� %d�� %d��'' �Դϴ�.',
      [Lunar.Year, Lunar.Month, Lunar.Day, Solar.Year, Solar.Month, Solar.Day]));
  except on E: Exception do
    ShowMessage(E.Message);
  end;
end;

procedure TForm1.DeleteSpecifiedData(AData: TSpecifiedData);
begin

end;

procedure TForm1.DisplaySpecifiedData;
begin

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FMakeCalendarCtrl   := TMakeCalendarController.Create;
  FSpecifiedDataCtrl  := TSpecifiedDateController.Create;

//  pgcCalendar.ActivePageIndex := 0;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  Lunar: TLunarDateRec;
  Year, Month, Day: Word;
  V1, V2, V3, V4: Word;
begin
//  if GetApplicationVersion(V1, V2, V3, V4) then
//    Caption := Caption + Format('(ver.%d.%d.%d)', [V1, V2, V3]);

  // ���� ����
  DecodeDate(Now, Year, Month, Day);

  // ���� �⺻ �� ����
  Lunar := FMakeCalendarCtrl.SolarToLunar(DateRec(Year, Month, Day));
  edtLunarYear.Text   := IntToStr(Lunar.Year);
  edtLunarMonth.Text  := IntToStr(Lunar.Month);
  edtLunarDay.Text    := IntToStr(Lunar.Day);

  // ��� �⺻ �� ����
//  edtSolarYear.Text   := IntToStr(Year);
//  edtSolarMonth.Text  := IntToStr(Month);
//  edtSolarDay.Text    := IntToStr(Day);

  // ��� ���� ����
//  edtStartOfRange.Text  := IntToStr(Year);
//  edtEndOfRange.Text    := IntToStr(Year + 50);

//  lvSpecified.Clear;
  DisplaySpecifiedData;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FMakeCalendarCtrl.Free;
  FSpecifiedDataCtrl.Free;
end;

function TForm1.GetLunarDaysDisplayType: TLunarDaysDisplayType;
begin

end;

function TForm1.GetRangeYear(var AStart, AEnd: Word): Boolean;
begin

end;

procedure TForm1.ShowSpecifiedDialog(AData: TSpecifiedData);
begin

end;

procedure TForm1.UpdateSpecifiedData(AData: TSpecifiedData);
begin

end;

end.
