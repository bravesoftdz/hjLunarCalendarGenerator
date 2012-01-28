unit hjLunarDateConverter;

interface

uses
  Windows, Classes, SysUtils, hjLunarDateType;

type
  ERangeError = class(Exception);

  ThjLunarDateConverter = class(TObject)
  private
    procedure RangeError(const Msg: string);

    function GetMonthToMonthIndex(AMonth: Word; AIsLeapMonth: Boolean; AMonthTable: string): Integer;
  protected
    procedure ValidateDate(ADate: TSolarDateRec); overload;
    procedure ValidateDate(ADate: TLunarDateRec); overload;
  public
    constructor Create;
    destructor Destroy; override;

    procedure TestData;

    function SolarToLunar(ADate: TSolarDateRec): TLunarDateRec;
    function LunarToSolar(ADate: TLunarDateRec): TSolarDateRec;

    function GetLunarDaysOfMonth(AYear, AMonth: Word; AIsLeapMonth: Boolean): Word;
    function InvalidMonthIndex(AYear: Word; AIndexOfMonth: Integer): Boolean;
    function GetLunarMonthFromMonthIndex(AYear: Word; AIndexOfMonth: Integer; var AMonth: Word; var AIsLeapMonth: Boolean): Boolean;

    function GetSupportSolarPriod: string;
    function GetSupportLunarPriod: string;
    function GetSupportLunarYear: string;
  end;

implementation

uses
  Math, StrUtils, DateUtils, CalendarCommons;

{$include LunarTableData.inc}


{ ThjLunarCalculator }

constructor ThjLunarDateConverter.Create;
begin

end;

destructor ThjLunarDateConverter.Destroy;
begin

  inherited;
end;

function ThjLunarDateConverter.GetSupportLunarPriod: string;
begin
  Result := Format('%s-1-1~%s-12-31)', [SupportYearStart, SupportYearEnd]);
end;

function ThjLunarDateConverter.GetSupportLunarYear: string;
begin
  Result := Format('%s~%s)', [SupportYearStart, SupportYearEnd]);
end;

function ThjLunarDateConverter.GetSupportSolarPriod: string;
begin
  Result := SupportSolarDateStartStr + '~' + SupportSolarDateEndStr;
end;

procedure ThjLunarDateConverter.RangeError(const Msg: string);
  function ReturnAddr: Pointer;
  asm
    MOV     EAX,[EBP+4]
  end;
begin
  raise ERangeError.Create(Msg) at ReturnAddr;
end;

procedure ThjLunarDateConverter.ValidateDate(ADate: TSolarDateRec);
var
  ErrMsg: string;
begin
  ErrMsg := Format('��ȿ������ ���� �����ϴ�.(������� ����: %0:s~%1:s)', [SupportSolarDateStartStr, SupportSolarDateEndStr]);

  // ### ���� ���� ����
  if ADate.Year < SupportYearStart then
    RangeError(ErrMsg);

  // ��� ���� ������ ����
  if (ADate.Year = SupportYearStart) and (ADate.Month = 1) and (ADate.Day <= StandardBetweenStart) then
    RangeError(ErrMsg); // INVALID_RANGE_START

  // ��� ���� ������ ����
  if (ADate.Year > SupportYearEnd) and ((ADate.Month > 1) or (ADate.Day > StandardBetweenEnd)) then
    RangeError(ErrMsg); // INVALID_RANGE_END

  // ### �� ���� ����
  if (ADate.Month < 1) or (ADate.Month > 12) then
    RangeError(Format('''%0:d''���� ��ȿ���� ���� ���Դϴ�.', [ADate.Month]));

  // ### �� ���� ����
  if (ADate.Day < 1) or (MonthDays[IsLeapYear(ADate.Year)][ADate.Month] < ADate.Day) then
    RangeError(Format('''%0:d''���� ��ȿ���� ���� �����Դϴ�.', [ADate.Day]));
end;

procedure ThjLunarDateConverter.ValidateDate(ADate: TLunarDateRec);
var
  ErrMsg: string;
  MonthTable: string;
  MonthIndex: Integer;
  DaysOfMonth: Integer;
begin
  // ### ���� ���� ����
  if (ADate.Year < SupportYearStart) or (ADate.Year > SupportYearEnd) then
  begin
    ErrMsg := Format('��ȿ������ ���� �����ϴ�.(�������� ����: %0:d-01-01~%1:d-12-31)', [SupportYearStart, SupportYearEnd]);
    RangeError(ErrMsg);
  end;

  // ### �� ���� ����
  if (ADate.Month < 1) or (ADate.Month > 12) then
    RangeError(Format('''%0:d''���� ��ȿ���� ���� ���Դϴ�.', [ADate.Month]));

  // ### �� ���� ����
  if (ADate.Day < 1) then
    RangeError(Format('''%0:d''���� ��ȿ���� ���� �����Դϴ�.', [ADate.Day]));

  MonthTable := LunarMonthTable[ADate.Year - SupportYearStart];
  // ���� ����
  if ADate.IsLeapMonth and (not CharInSet(MonthTable[ADate.Month+1], ['3', '4'])) then
    RangeError(Format('���� ''%0:d�� %1:d��''�� ������ �ƴմϴ�.', [ADate.Year, ADate.Month]));

  // ��� �ҿ� ����
  MonthIndex := GetMonthToMonthIndex(ADate.Month, ADate.IsLeapMonth, MonthTable);
  DaysOfMonth := IfThen(CharInSet(MonthTable[MonthIndex], ['1', '3']), 29, 30);
  if ADate.Day > DaysOfMonth then
    RangeError(Format('���� ''%0:d�� %1:d��%4:s''�� ''%3:d��'' ���� �ֽ��ϴ�.(''%2:d��''�� ��ȿ���� �ʽ��ϴ�.)', [ADate.Year, ADate.Month, ADate.Day, DaysOfMonth, IfThen(ADate.IsLeapMonth, '(����)', '')]));
end;

{===============================================================================
  # �������ڸ� ������ڷ� ��ȯ�Ͽ� ��ȯ
  # Parameter
    ADate: TLunarDateRec : ��ȯ ��� ��������(���޿��� ����)
  # Return
    TSolarDateRec: ��ȯ�� ��� ����
===============================================================================}
function ThjLunarDateConverter.LunarToSolar(ADate: TLunarDateRec): TSolarDateRec;
  function GetDayCountFromYear(AYear: Word): Integer;
  var
    I: Integer;
  begin
    Result := 0;
    for I := 0 to AYear - SupportYearStart do
      Result := Result + LunarYearDays[I];
  end;

  // ������ ������ �ϼ�
  function GetDayCountFromLastMonth(AYear, AMonth: Word; AIsLeap: Boolean): Integer;
  var
    I, MonthIndex: Integer;
    MonthTable: string;
  begin
    Result := 0;
    MonthTable := LunarMonthTable[AYear - SupportYearStart];
    MonthIndex := GetMonthToMonthIndex(AMonth, AIsLeap, MonthTable) - 1;  // ������
    for I := 1 to MonthIndex do
      Result := Result + IfThen(CharInSet(MonthTable[I], ['1', '3']), 29, 30);
  end;

var
  I: Integer;
  DayCount: Integer;
  DaysOfYear, DaysOfMonth: Integer;
begin
  try
    ValidateDate(ADate);
  except
    raise;
  end;

  ZeroMemory(@Result, SizeOf(Result));

  // ###### ����ϼ� ���ϱ� ######
  // [STEP 1] ����> ���س� ���� ���⵵������ ������ �ϼ� ����
  // [STEP 2] ����> �������� ���� �ϼ� ����(����ó�� ����)
  // [STEP 3] ����> ���� ����

  DayCount := 0;
  // STEP 1
  DayCount := DayCount + GetDayCountFromYear(ADate.Year - 1);
  // STEP 2
  DayCount := DayCount + GetDayCountFromLastMonth(ADate.Year, ADate.Month, ADate.IsLeapMonth);
  // STEP 3
  DayCount := DayCount + ADate.Day;


  // [STEP 4] �������� �������� ����
    // ��)1/1 = ��)1/30 ��� �Ʒ� ���� �� ��� 1/1�Ϻ��� ����ϹǷ� 29���� ����
  DayCount := DayCount + StandardBetweenStart;

  // ###### ����ϼ����� ��������  ���ϱ� ######
  // [STEP 5] ���> ������ ���ڼ� �����ϸ� ���� ����
  // [STEP 6] ���> ���� ���ڼ� �����ϸ� �� ����
  // [STEP 7] ���> �ܿ��� �� �Ϸ� ���

  // STEP 5
  Result.Year := SupportYearStart - 1;
  for I := 0 to SupportYearRange - 1 do
  begin
    Inc(Result.Year);

    DaysOfYear := DaysPerYear[IsLeapYear(SupportYearStart + I)];
    if DayCount <= DaysOfYear then
      Break;

    DayCount := DayCount - DaysOfYear;
  end;

  // STEP 6
  Result.Month := 0;
  for I := 1 to 12 do
  begin
    Inc(Result.Month);

    DaysOfMonth := MonthDays[IsLeapYear(Result.Year)][I];
    if DayCount <= DaysOfMonth then
      Break;

    DayCount := DayCount - DaysOfMonth;
  end;

  // STEP 7
  Result.Day := DayCount;
end;

{===============================================================================
  # ������ڸ� �������ڷ� ��ȯ�Ͽ� ��ȯ
  # Parameter
    ADate: TSolarDateRec - ��ȯ ��� �������
  # Return
    TLunarDateRec - ��ȯ�� ��������(���޿��� ����)
===============================================================================}
function ThjLunarDateConverter.SolarToLunar(ADate: TSolarDateRec): TLunarDateRec;
  // ���س⵵ ���� ��û �⵵������ �ϼ� �� ��ȯ
  function GetDayCountFromYear(AYear: Word): Integer;
  begin
    Result := (AYear * 365) + (AYear div 4) - (AYear div 100) + (AYear div 400);
    Result := Result - StandardDateDelta;
  end;

  // ��û�⵵�� ������ �ϼ� �� ��ȯ
  function GetDayCountFromMonth(AYear, AMonth: Word): Integer;
  var
    I: Integer;
  begin
    Result := 0;

    for I := 1 to AMonth do
      Inc(Result, MonthDays[IsLeapYear(AYear)][I]);
  end;
var
  I: Integer;
  DayCount, MonDays: Integer;
  MonthTable: string;
begin
  try
    ValidateDate(ADate);
  except
    raise;
  end;

  ZeroMemory(@Result, SizeOf(Result));

  // ###### ����ϼ� ���ϱ� ######
  // [STEP 1] ���> ���س� ���� ���⵵���� ������ ���ڼ� ����
  // [STEP 2] ���> �������� ���� �ϼ� ����(����ó�� ����)
  // [STEP 3] ���> ���� ����

  DayCount := 0;
  // STEP 1
  DayCount := DayCount + GetDayCountFromYear(ADate.Year - 1);
  // STEP 2
  DayCount := DayCount + GetDayCountFromMonth(ADate.Year, ADate.Month - 1);
  // STEP 3
  DayCount := DayCount + ADate.Day;

  // [STEP 4] �������� �������� ����
    // ��)1/1 = ��)1/30 ��� �Ʒ� ���� �� ��]1/30(��]1/1)�Ϻ��� ����ؾ� �ϹǷ� 29 ����
  DayCount := DayCount - StandardBetweenStart;

  // ###### ����ϼ����� ��������  ���ϱ� ######
  // [STEP 5] ����> ���� �� ���� ���� ���� ���� ����
  // [STEP 6] ����> ���� ���� ���� ���� �� ����
    // 6-1> ��޸� ���¿� ����(������ ������ �޹�ȣ ��ӻ��, ex>...3��,��3��,4��...)
    // 6-2> ���¿��� ��/�ҿ� ����(29 or 30)
    // 6-3> �ܿ��ϼ�(DayCount)�� ���¿��� �ϼ����� �۾��������� �ݺ�
  // [STEP 7] �ܿ� �ϼ��� �����Ϸ� ó��

  // STEP 5
  Result.Year := SupportYearStart - 1;
  for I := 0 to Length(LunarYearDays) - 1 do
  begin
    Inc(Result.Year);

    if LunarYearDays[I] >= DayCount  then
      Break;

    DayCount := DayCount - LunarYearDays[I];
  end;

  // STEP 6
  Result.Month := 0;
  MonthTable := LunarMonthTable[I];
  for I := 1 to Length(MonthTable) do
  begin
    // 6-1
    if CharInSet(MonthTable[I], ['1', '2']) then
      Inc(Result.Month);

    // 6-2
    if CharInSet(MonthTable[I], ['1', '3']) then      // �ҿ��� 29��
      MonDays := 29
    else if CharInSet(MonthTable[I], ['2', '4']) then // ����� 30��
      MonDays := 30
    else
      raise Exception.CreateFmt('Incorrect lunar month table data(Index: %d, Char: %s)', [I, MonthTable[I]])
    ;

    // 6-3
    if MonDays >= DayCount then
    begin
      if CharInSet(MonthTable[I], ['3', '4']) then
        Result.IsLeapMonth := True;
      Break;
    end;

    DayCount := DayCount - MonDays;
  end;

  // STEP 7
  Result.Day := DayCount;
end;

procedure ThjLunarDateConverter.TestData;
var
  I, J, Sum: Integer;
begin
  for I := 0 to Length(LunarMonthTable) - 1 do
  begin
    Sum := 0;
    for J := 0 to Length(LunarMonthTable[I]) - 1 do
    begin

      if CharInSet(LunarMonthTable[I][J], ['1', '3']) then
        Sum := Sum + 29
      else if CharInSet(LunarMonthTable[I][J], ['2', '4']) then
        Sum := Sum + 30
      ;
    end;

    if Sum <> LunarYearDays[I] then
      OutputDebugString(PChar(Format('Incorrect Index: %d, SumDays: (%d, %d)', [I, Sum, LunarYearDays[I]])));
  end;
  OutputDebugString(PChar('Correct Table data'));
end;

// ���� ���� ������ ���� ��ȯ�Ѵ�.
function ThjLunarDateConverter.GetLunarDaysOfMonth(AYear, AMonth: Word;
  AIsLeapMonth: Boolean): Word;
var
  MonthTable: string;
  MonthIndex: Integer;
begin
  Result := 0;
  MonthTable := LunarMonthTable[AYear - SupportYearStart];

  MonthIndex := GetMonthToMonthIndex(AMonth, AIsLeapMonth, MonthTable);

  // ���޿�û ��� ����
  if AIsLeapMonth and (not CharInSet(MonthTable[MonthIndex], ['3', '4'])) then
    Exit;

  Result := IfThen(CharInSet(MonthTable[MonthIndex], ['1', '3']), 29, 30);
end;

// ���� ���� Index�� �޹�ȣ�� ���� ���θ� ��ȯ�Ѵ�.
function ThjLunarDateConverter.GetLunarMonthFromMonthIndex(AYear: Word;
  AIndexOfMonth: Integer; var AMonth: Word;
  var AIsLeapMonth: Boolean): Boolean;
var
  I: Integer;
  MonthTable: string;
begin
  Result := False;

  MonthTable := LunarMonthTable[AYear - SupportYearStart];

  // Index ����
  if Length(MonthTable) < AIndexOfMonth then
    Exit;

  AMonth := AIndexOfMonth;
  AIsLeapMonth := CharInSet(MonthTable[AIndexOfMonth], ['3', '4']);
  for I := 1 to AIndexOfMonth do
  begin
    // Index ������ ������ ������ ���� ����
    if CharInSet(MonthTable[I], ['3', '4']) then
    begin
      AMonth := AIndexOfMonth - 1;
      Break;  // ������ �ѹ��� ����
    end;
  end;

  Result := True;
end;

function ThjLunarDateConverter.GetMonthToMonthIndex(AMonth: Word;
  AIsLeapMonth: Boolean; AMonthTable: string): Integer;
var
  I: Integer;
begin
  Result := AMonth;
  for I := 1 to AMonth do
    if CharInSet(AMonthTable[I], ['3', '4']) then
      Inc(Result);

  if AIsLeapMonth then
    Inc(Result);
end;

function ThjLunarDateConverter.InvalidMonthIndex(AYear: Word;
  AIndexOfMonth: Integer): Boolean;
var
  MonthTable: string;
begin
  Result := False;
  MonthTable := LunarMonthTable[AYear - SupportYearStart];

  if Length(MonthTable) < AIndexOfMonth then
    Exit;

  Result := CharInSet(MonthTable[AIndexOfMonth], ['1'..'4']);
end;

end.


