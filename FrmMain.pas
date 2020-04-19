unit FrmMain;

interface

uses
  Windows, SysUtils, Forms, StdCtrls, Controls, Classes;

type
  TUSBLPWRMain = class(TForm)
    PWEdit: TEdit;
    RecoveryBtn: TButton;
    DriveCBox: TComboBox;
    RefreshBtn: TButton;
    ManualBtn: TButton;
    Label1: TLabel;
    ManualEdit: TEdit;
    procedure RecoveryBtnClick(Sender: TObject);
    procedure EnumDrives;
    procedure FormCreate(Sender: TObject);
    procedure RefreshBtnClick(Sender: TObject);
    procedure ManualBtnClick(Sender: TObject);
    procedure ManualEditKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type USBLockitThreadVal= Record
Value:Cardinal;
Low:Cardinal;
High:Cardinal;
Done:boolean;
End;

type PUSBLockitThreadVal= ^USBLockitThreadVal;

Type DISK_GEOMETRY= Record
Cylinders:Int64;
MEDIA_TYPE:Cardinal;
TracksPerCylinder:Cardinal;
SectorsPertTrack:Cardinal;
BytesPerSector:Cardinal;
End;

var
  USBLPWRMain: TUSBLPWRMain;
  ThreadDone:Boolean;
  tvs:Array[0..7] of USBLockitThreadVal;
  DriveArray: Array of WideChar;
  DALen:Cardinal;
implementation

{$R *.dfm}
Function EncryptPass(s:PAnsiChar;len:byte):Cardinal; STDCALL;
var
I:Cardinal;
Begin
Result:=$811C9DC5;
for I := 1 to len do begin
Result:=(byte(s[I-1]) xor Result) * $1000193;
end;
End;  //

procedure inttostr6(Inp:cardinal;me:PAnsiChar;var len:byte); STDCALL;
var
b:Byte;
Begin
b:=5;
repeat
me[b]:=ansichar(Inp mod 10+$30);
Inp:=Inp div 10;
dec(b);
until Inp =0;
len:=6-b-1;
End;

Function TestPass(inp,Low,High:Cardinal):ansiString; STDCALL;
var
I:cardinal;
b:byte;
s:Array[0..5] of AnsiChar;
Begin
Result:='';
for I := low to high do begin
if ThreadDone= true then exit;
inttostr6(I,@s[0],b);
if EncryptPass(@s[6-b],b)=inp then Begin
Setlength(result,b);
CopyMemory(@result[1],@s[6-b],b);
exit;
End;

While b<6 do begin  //prepended zeros
inc(b);
s[6-b]:='0';
if EncryptPass(@s[6-b],b)=inp then Begin
Setlength(result,b);
CopyMemory(@result[1],@s[6-b],b);
exit;
End;
end;
end;
End;

Function USBLockitThread(pinp:PUSBLockitThreadVal):Cardinal; STDCALL;
var
S:ansistring;
Begin
try
Result:=0;
S:=TestPass(pinp.Value,pinp.Low,pinp.High);
if S<>'' then Begin;
ThreadDone:=true;
USBLPWRMain.PWEdit.Text:=string(S);
End;
finally
pinp.Done:=true;
end;

End;

Function ReadPassword(driveL:WideChar):Cardinal;
var
fhnd,tmp,I,i2:Cardinal;
mnHeader:Array of Byte;
stF:WideString;
pas:AnsiString;
dg:DISK_GEOMETRY;
islockit:Boolean;
CONST
verIdentity:Array [0..1] of AnsiString=('MSLOCKIT','EXLOCKIT');
Begin
Result:=0;
stF:='\\.\'+driveL+':';
fhnd:=CreateFileW(@stF[1],GENERIC_READ ,FILE_SHARE_READ or FILE_SHARE_WRITE,nil,OPEN_EXISTING,0,0);
if fhnd=INVALID_HANDLE_VALUE then begin
MessageBox(USBLPWRMain.Handle,'Cannot open drive','Error',MB_OK);
exit;
end;
if DeviceIoControl(fhnd,IOCTL_DISK_GET_DRIVE_GEOMETRY,nil,0,@dg,sizeof(dg),tmp,nil)=false then Begin
MessageBox(USBLPWRMain.Handle,'Cannot Get Drive Geometry','Error',MB_OK);
exit;
End;

SetLength(mnHeader,dg.BytesPerSector);

if ReadFile(fhnd,mnHeader[0],dg.BytesPerSector,tmp,nil)=false then begin
MessageBox(USBLPWRMain.Handle,'Cannot Read Drive','Error',MB_OK);
CloseHandle(fhnd);
exit
end;
CloseHandle(fhnd);

for I := 0 to 1 do Begin
islockit:=true;
for i2 := 0 to 7 do
if mnHeader[3+i2]<>byte(verIdentity[I][1+i2]) then islockit:=false;
if islockit=true then break;
End;
if islockit=false then begin
MessageBox(USBLPWRMain.Handle,'Drive is not protected by USB Lockit','Error',MB_OK);
exit;
end;


SetLength(pas,8);
CopyMemory(@pas[1],@mnHeader[$3E],8);
try
Result:=StrToInt('$'+String(pas));
except
MessageBox(USBLPWRMain.Handle,'Could not get password. Try manual recovery.','Error',MB_OK);
Result:=0;
end;


End;

Procedure DecryptPass(pv:Cardinal);
var
tmp:Cardinal;
I:byte;
Begin
if pv=0 then exit;

for I := 0 to 7 do if tvs[I].Done=false then exit;

ThreadDone:=false;
for I := 0 to 7 do Begin
tvs[I].Value:=pv;
tvs[I].Low:=125000*(I);
tvs[I].High:=125000*(I+1)-1;
tvs[I].Done:=false;
CreateThread(nil,0,@USBLockitThread,@tvs[I],0,tmp);
End;

End;

procedure TUSBLPWRMain.RecoveryBtnClick(Sender: TObject);
begin
if DriveCBox.Items.Count=0 then exit;
DecryptPass(ReadPassword(DriveArray[DriveCBox.ItemIndex]));
end;

Function GetDiskName(dPath:WideString):WideString;
var
s,s2:Array [0..255] of WideChar;
tmp,tmp1,ln:Cardinal;
Begin
ZeroMemory(@s[0],256);
ZeroMemory(@s2[0],256);
 Result:='';
if GetVolumeInformationW(@dPath[1],@s[0],256,@tmp,ln,tmp1,@s2[0],256)= false then exit;
Result:=s;
End;

procedure TUSBLPWRMain.RefreshBtnClick(Sender: TObject);
begin
EnumDrives;
end;

procedure TUSBLPWRMain.ManualBtnClick(Sender: TObject);
var
I:Cardinal;
begin
if ManualEdit.GetTextLen=0 then begin
MessageBox(USBLPWRMain.Handle,'Please Enter the encrypted value. This is obtained by clicking the usb icon in the USB Lockit main window.','Error',MB_OK);
exit;
end;
Try
 I:=StrToInt('$'+ManualEdit.Text);
 DecryptPass(I);
Except
MessageBox(USBLPWRMain.Handle,'Invalid Manual Password Value.','Error',MB_OK);
End;
//DecryptPass(ESBHexEdit1.AsLongWord);
end;

procedure TUSBLPWRMain.ManualEditKeyPress(Sender: TObject; var Key: Char);
begin
if (Byte(Key)>=$30) and (Byte(Key)<=$39) then exit;
if (Byte(Key)>=$41) and (Byte(Key)<=$46) then exit;
if (Byte(Key)>=$61) and (Byte(Key)<=$66) then exit;
if Key= #8 then exit;

Key:=#0;
end;

procedure TUSBLPWRMain.EnumDrives;
var
I,dr,dt:Cardinal;
S:WideString;
begin
DriveCBox.Clear;
SetLength(DriveArray,0);
DAlen:=0;
dr:=GetLogicalDrives;
for I := 0 to 25 do Begin
 if dr and 1=1 then  Begin
 S:=WideChar($41+I)+':\';
 dt:=GetDriveTypeW(@S[1]);
 if dt = DRIVE_REMOVABLE then begin
 inc(DAlen);
 SetLength(DriveArray,DAlen);
 DriveArray[DAlen-1]:=WideChar($41+I);
 S:=S+' ('+GetDiskName(S)+')';
  DriveCBox.Items.Add(S);
end;

 End;
  dr:=dr shr 1;
End;
DriveCBox.ItemIndex:=0;
end;



procedure TUSBLPWRMain.FormCreate(Sender: TObject);
var
I:integer;
begin
EnumDrives;
for I := 0 to 7 do
tvs[I].Done:=true;

end;

end.
