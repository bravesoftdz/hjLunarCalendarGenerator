unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls,
  hjLunarDateType, CalendarCommons, MakeCalendarController,
  SpecifiedData, SpecifiedDataController;

type
  TfrmMain = class(TForm)
    GroupBox1: TGroupBox;
    btnLunarToSolar: TButton;
    edtLunarYear: TEdit;
    edtLunarMonth: TEdit;
    edtLunarDay: TEdit;
    btnSolarToLunar: TButton;
    edtSolarYear: TEdit;
    edtSolarMonth: TEdit;
    edtSolarDay: TEdit;
    pgcCalendar: TPageControl;
    tsLunar: TTabSheet;
    tsSpecified: TTabSheet;
    rdoLunarDisplayDays10: TRadioButton;
    rdoLunarDisplayDays15: TRadioButton;
    rdoLunarDisplayDays5: TRadioButton;
    rdoLunarDisplayDaysKor: TRadioButton;
    lvSpecified: TListView;
    lblSpecified: TLabel;
    btnAddSpecified: TButton;
    btnDelSpecified: TButton;
    btnMakeSpecifiedCalendar: TButton;
    lblLunarDisplayDays10: TLabel;
    lblLunarDisplayDays15: TLabel;
    lblLunarDisplayDays5: TLabel;
    lblLunarDisplayDaysKor: TLabel;
    btnMakeLunarCalendar: TButton;
    Label5: TLabel;
    Label6: TLabel;
    lblBlog: TLabel;
    일: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    chkLunarLeap: TCheckBox;
    edtStartOfRange: TEdit;
    Label1: TLabel;
    edtEndOfRange: TEdit;
    Label2: TLabel;
    dlgSave: TSaveDialog;
    btnAbout: TButton;
    chkSpecifiedDispDate: TCheckBox;
    procedure btnLunarToSolarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSolarToLunarClick(Sender: TObject);
    procedure lblLunarDisplayDaysClick(Sender: TObject);
    procedure lblBlogMouseEnter(Sender: TObject);
    procedure lblBlogMouseLeave(Sender: TObject);
    procedure lblBlogClick(Sender: TObject);
    procedure btnMakeLunarCalendarClick(Sender: TObject);
    procedure btnMakeSpecifiedCalendarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edtOnlyNumericKeyPress(Sender: TObject; var Key: Char);
    procedure btnAddSpecifiedClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure edtNextFocusKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lvSpecifiedDblClick(Sender: TObject);
  private
    { Private declarations }
    // 달력생성 제어객체
    FMakeCalendarCtrl: TMakeCalendarController;

    // 기념일 데이터 제어객체
    FSpecifiedDataCtrl: TSpecifiedDateController;

    // 음력달력 생성
    function GetRangeYear(var AStart, AEnd: Word): Boolean;
    function GetLunarDaysDisplayType: TLunarDaysDisplayType;

    // 기념일 달력 생성
    procedure DisplaySpecifiedData;
    procedure ShowSpecifiedDialog(AData: TSpecifiedData);

    procedure AppendSpecifiedData(AData: TSpecifiedData);
    procedure DeleteSpecifiedData(AData: TSpecifiedData);
    procedure UpdateSpecifiedData(AData: TSpecifiedData);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  ShellAPI, DateUtils, CalendarDataSaverToICS,
  SpecifiedForm;

{$R *.dfm}

function GetApplicationVersion(var Major, Minor, Release, Build: Word): Boolean;
var
  VerInfoSize: DWord;
  VerInfo: Pointer;
  VerValueSize: DWord;
  VerValue: PVSFixedFileInfo;
  Dummy: DWord;
begin
  VerInfoSize := GetFileVersionInfoSize(PChar(Application.ExeName), dummy);
  GetMem(VerInfo, VerInfoSize);
  try
    GetFileVersionInfo(PChar(Application.ExeName), 0, VerInfoSize, VerInfo);
    VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
    with VerValue^ do
    begin
      Major   := dwFileVersionMS shr 16;
      Minor   := dwFileVersionMS and $FFFF;
      Release := dwFileVersionLS shr 16;
      Build   := dwFileVersionLS and $FFFF;
    end;

    Result := True;
  finally
    FreeMem(VerInfo, VerInfoSize);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FMakeCalendarCtrl   := TMakeCalendarController.Create;
  FSpecifiedDataCtrl  := TSpecifiedDateController.Create;

  pgcCalendar.ActivePageIndex := 0;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  Lunar: TLunarDateRec;
  Year, Month, Day: Word;
  V1, V2, V3, V4: Word;
begin
  if GetApplicationVersion(V1, V2, V3, V4) then
    Caption := Caption + Format('(ver.%d.%d.%d)', [V1, V2, V3]);

  // 오늘 일자
  DecodeDate(Now, Year, Month, Day);

  // 음력 기본 값 설정
  Lunar := FMakeCalendarCtrl.SolarToLunar(DateRec(Year, Month, Day));
  edtLunarYear.Text   := IntToStr(Lunar.Year);
  edtLunarMonth.Text  := IntToStr(Lunar.Month);
  edtLunarDay.Text    := IntToStr(Lunar.Day);

  // 양력 기본 값 설정
  edtSolarYear.Text   := IntToStr(Year);
  edtSolarMonth.Text  := IntToStr(Month);
  edtSolarDay.Text    := IntToStr(Day);

  // 대상 연도 설정
  edtStartOfRange.Text  := IntToStr(Year);
  edtEndOfRange.Text    := IntToStr(Year + 50);

  lvSpecified.Clear;
  DisplaySpecifiedData;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FMakeCalendarCtrl.Free;
  FSpecifiedDataCtrl.Free;
end;

function TfrmMain.GetRangeYear(var AStart, AEnd: Word): Boolean;
var
  Msg: string;
begin
  Result := False;

  AStart  := StrToIntDef(edtStartOfRange.Text, 0);
  AEnd    := StrToIntDef(edtEndOfRange.Text, 0);

  if (AStart = 0) or (AEnd = 0) then
  begin
    ShowMessage('달력 생성연도를 정확히 입력해 주세요.');
    edtStartOfRange.SetFocus;
    Exit;
  end;

  // 연도 범위 처리
  if not FMakeCalendarCtrl.SupportRangeYear(AStart, Msg) then
  begin
    ShowMessage(Msg);
    Exit;
  end;

  if not FMakeCalendarCtrl.SupportRangeYear(AEnd, Msg) then
  begin
    ShowMessage(Msg);
    Exit;
  end;

  Result := True;
end;

// 숫자만 입력
procedure TfrmMain.edtNextFocusKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Length(TEdit(Sender).Text) = TEdit(Sender).MaxLength then
  begin
    Key := 0;
    SelectNext(Sender as TWinControl, True, True);
  end;
end;

procedure TfrmMain.edtOnlyNumericKeyPress(Sender: TObject; var Key: Char);
begin
  if not (CharInSet(Key, ['0'..'9',#25,#08,#13])) then
    Key := #0;
end;

procedure TfrmMain.lblBlogClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(TLabel(Sender).Caption), nil, nil, SW_SHOW);
end;

procedure TfrmMain.lblBlogMouseEnter(Sender: TObject);
begin
  TLabel(Sender).Font.Style := TLabel(Sender).Font.Style + [fsUnderline];
  TLabel(Sender).Font.Color := clBlue;
  TLabel(Sender).Cursor := crHandPoint;
end;

procedure TfrmMain.lblBlogMouseLeave(Sender: TObject);
begin
  TLabel(Sender).Font.Style := TLabel(Sender).Font.Style - [fsUnderline];
  TLabel(Sender).Font.Color := clBlack;
  TLabel(Sender).Cursor := crDefault;
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
var
  msg: string;
begin
  msg := '이 프로그램은 델파이로 제작된 무료프로그램이며'#13#10
       + '재배포 및 상업적 이용에 제한이 없습니다.'#13#10#13#10
       + '이 프로그램으로 발생된 어떠한 종류의 문제에도'#13#10
       + '제작자는 아무런 책임도 지지 않습니다.'#13#10#13#10
  ;

  ShowMessage(msg);
end;

//  1, 음력일자를 양력일자로 변경
procedure TfrmMain.btnLunarToSolarClick(Sender: TObject);
var
  Lunar: TLunarDateRec;
  Solar: TSolarDateRec;
begin
  Lunar.Year  := StrToIntDef(edtLunarYear.Text, 0);
  Lunar.Month := StrToIntDef(edtLunarMonth.Text, 0);
  Lunar.Day   := StrToIntDef(edtLunarDay.Text, 0);
  Lunar.IsLeapMonth := chkLunarLeap.Checked;

  try
    Solar := FMakeCalendarCtrl.LunarToSolar(Lunar);

    ShowMessage(Format('음력 ''%d년 %d월 %d''일은'#13#10#13#10'양력 ''%d년 %d월 %d일'' 입니다.',
      [Lunar.Year, Lunar.Month, Lunar.Day, Solar.Year, Solar.Month, Solar.Day]));
  except on E: Exception do
    ShowMessage(E.Message);
  end;
end;

//  2, 양력일자를 음력일자로 변경
procedure TfrmMain.btnSolarToLunarClick(Sender: TObject);
var
  Lunar: TLunarDateRec;
  Solar: TSolarDateRec;
begin
  Solar.Year  := StrToIntDef(edtSolarYear.Text, 0);
  Solar.Month := StrToIntDef(edtSolarMonth.Text, 0);
  Solar.Day   := StrToIntDef(edtSolarDay.Text, 0);

  try
    Lunar := FMakeCalendarCtrl.SolarToLunar(Solar);

    ShowMessage(Format('양력 ''%d년 %d월 %d일''은'#13#10#13#10'음력 ''%d년 %d월 %d''일 입니다.',
      [Solar.Year, Solar.Month, Solar.Day, Lunar.Year, Lunar.Month, Lunar.Day]));
  except on E: Exception do
    ShowMessage(E.Message);
  end;
end;

//  3, 음력 달력 생성
procedure TfrmMain.btnMakeLunarCalendarClick(Sender: TObject);
var
  StartOfRange, EndOfRange: Word;
begin
  if not GetRangeYear(StartOfRange, EndOfRange) then
    Exit;

  dlgsave.InitialDir := ExtractFilePath(Application.ExeName);
  dlgSave.FileName := Format('lunarcalendar_%d-%d.ics', [StartOfRange, EndOfRange]);
  if dlgSave.Execute then
  begin
    if FileExists(dlgSave.FileName) then
    begin
      if Application.MessageBox(PChar(Format('%s 파일이 이미 존재합니다.'#13#10'이 파일을 바꾸시겠습니까?', [dlgSave.Filename])), PChar('hjLunarCalendarGenerator'), MB_ICONQUESTION OR MB_YESNO) = ID_NO then
      begin
        Exit;
      end;
    end;

    try
      if FMakeCalendarCtrl.MakeLunarCalendar(StartOfRange, EndOfRange, GetLunarDaysDisplayType, dlgSave.FileName) then
        ShowMessage('달력파일 생성을 완료하였습니다.');
    except on E: Exception do
      ShowMessage('달력파일 생성 중 오류가 발생했습니다.'#13#10 + Format('(오류내용: %s)', [E.Message]));
    end;
  end;
end;

//  4, 음력 기념일 달력 생성
procedure TfrmMain.btnMakeSpecifiedCalendarClick(Sender: TObject);
var
  StartOfRange, EndOfRange: Word;
begin
  if not GetRangeYear(StartOfRange, EndOfRange) then
    Exit;

  dlgsave.InitialDir := ExtractFilePath(Application.ExeName);
  dlgSave.FileName := Format('specfiedcalendar_%d-%d.ics', [StartOfRange, EndOfRange]);
  if dlgSave.Execute then
  begin
    if FileExists(dlgSave.FileName) then
    begin
      if Application.MessageBox(PChar(Format('%s 파일이 이미 존재합니다.'#13#10'이 파일을 바꾸시겠습니까?', [dlgSave.Filename])), PChar('hjLunarCalendarGenerator'), MB_ICONQUESTION OR MB_YESNO) = ID_NO then
      begin
        Exit;
      end;
    end;

    try
      if FMakeCalendarCtrl.MakeSpecifiedCalendar(StartOfRange, EndOfRange, chkSpecifiedDispDate.Checked, FSpecifiedDataCtrl.DataList, dlgSave.FileName) then
        ShowMessage('달력파일 생성을 완료하였습니다.');
    except on E: Exception do
      ShowMessage('달력파일 생성 중 오류가 발생했습니다.'#13#10 + Format('(오류내용: %s)', [E.Message]));
    end;
  end;
end;

function TfrmMain.GetLunarDaysDisplayType: TLunarDaysDisplayType;
begin
  if rdoLunarDisplayDays5.Checked then        Result := lddt5
  else if rdoLunarDisplayDays10.Checked then  Result := lddt10
  else if rdoLunarDisplayDays15.Checked then  Result := lddt15
  else if rdoLunarDisplayDaysKor.Checked then Result := lddtKor
  else { default }                            Result := lddt5
  ;
end;

procedure TfrmMain.lblLunarDisplayDaysClick(Sender: TObject);
var
  lbl: TLabel absolute Sender;
begin
  if lbl = lblLunarDisplayDays10 then   rdoLunarDisplayDays10.Checked := True;
  if lbl = lblLunarDisplayDays15 then   rdoLunarDisplayDays15.Checked := True;
  if lbl = lblLunarDisplayDays5 then    rdoLunarDisplayDays5.Checked := True;
  if lbl = lblLunarDisplayDaysKor then  rdoLunarDisplayDaysKor.Checked := True;
end;

// 기념일 데이터 표시
procedure TfrmMain.DisplaySpecifiedData;
var
  I: Integer;
  Data: TSpecifiedData;
  Item: TListItem;
begin
  lvSpecified.Clear;
  for I := 0 to FSpecifiedDataCtrl.Count - 1 do
  begin
    Data := FSpecifiedDataCtrl[I];
    Item := lvSpecified.Items.Add;
    Item.Caption := Format('%.2d월 %s일', [Data.Month, Data.DayStr]);
    Item.SubItems.Add(Data.Summary);
    Item.Data := Data;
  end;
end;

procedure TfrmMain.ShowSpecifiedDialog(AData: TSpecifiedData);
var
  MR: Integer;
begin
  frmSpecified := TfrmSpecified.Create(Self);
  try
    frmSpecified.Left := Self.Left + ((Self.Width - frmSpecified.Width ) div 2);
    frmSpecified.top  := Self.Top + ((Self.Height - frmSpecified.Height ) div 2);
    frmSpecified.Data := AData;
    MR := frmSpecified.ShowModal;

    case MR of
    smrSave:
      AppendSpecifiedData(frmSpecified.Data);
    smrUpdate:
      UpdateSpecifiedData(frmSpecified.Data);
    smrDelete:
      DeleteSpecifiedData(frmSpecified.Data);
    end;
  finally
    frmSpecified.Free;
  end;
end;

// 일정 추가
procedure TfrmMain.btnAddSpecifiedClick(Sender: TObject);
begin
  ShowSpecifiedDialog(nil);
end;

// 일정 수정
procedure TfrmMain.lvSpecifiedDblClick(Sender: TObject);
var
  Item: TListItem;
begin
  Item := TListView(Sender).Selected;
  if Assigned(Item) then
  begin
    ShowSpecifiedDialog(Item.Data);
  end;
end;

// 기념일 추가
procedure TfrmMain.AppendSpecifiedData(AData: TSpecifiedData);
var
  I: Integer;
  msg: string;
  Datas: TSpecifiedDatas;

  Item: TListItem;
begin
  if not Assigned(AData) then
    Exit;

  Datas := FSpecifiedDataCtrl.GetDatas(AData.Month, AData.Day);

  if Datas.Count > 0 then
  begin
    msg := Format('[%d월 %s일]에는 이미 %d개의 기념일이 등록되어 있습니다.', [AData.Month, AData.DayStr, Datas.Count]);
    for I := 0 to Datas.Count - 1 do
      msg := msg + Format(#13#10' - %s', [Datas[I].Summary]);
    msg := msg + #13#10#13#10'추가로 기념일을 등록하시겠습니까?';

    if Application.MessageBox(PChar(msg), PChar('hjLunarCalendarGenerator'), MB_ICONQUESTION OR MB_YESNO) = ID_NO then
      Exit;
  end;

  if FSpecifiedDataCtrl.AppendData(AData) then
  begin
    Item := lvSpecified.Items.Add;
    Item.Caption := Format('%.2d월 %s일', [AData.Month, AData.DayStr]);
    Item.SubItems.Add(AData.Summary);
    Item.Data := AData;
  end;
end;

// 기념일 삭제(단건)
procedure TfrmMain.DeleteSpecifiedData(AData: TSpecifiedData);
var
  I: Integer;
  Data: TSpecifiedData;
begin
  if not Assigned(AData) then
    Exit;

  for I := 0 to lvSpecified.Items.Count - 1 do
  begin
    Data := lvSpecified.Items[I].Data;
    if Data = AData then
    begin
      lvSpecified.Items.Delete(I);
      Break;
    end;
  end;

  FSpecifiedDataCtrl.DeleteData(AData);
end;

// 기념일 수정(갱신)
procedure TfrmMain.UpdateSpecifiedData(AData: TSpecifiedData);
var
  Item: TListItem;
begin
  FSpecifiedDataCtrl.UpdateData(AData);

  Item := lvSpecified.Selected;
  Item.Caption := Format('%.2d월 %s일', [AData.Month, AData.DayStr]);
  Item.SubItems[0] := AData.Summary;
end;

end.
