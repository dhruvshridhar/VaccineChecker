unit VaccineUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.ScrollBox, FMX.Memo, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP,
  FMX.DateTimeCtrls, System.JSON, FetchDataUnit;

type
  TDemoThread = class( TThread )
  protected
    FProgress : Integer;

  protected
    procedure Execute(); override;

  protected
    procedure DoSynch();

  end;

  TForm1 = class(TForm)
    pinEdit: TEdit;
    showBtn: TButton;
    resultMem: TMemo;
    IdHTTP1: TIdHTTP;
    IdSMTP1: TIdSMTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    pinLbl: TLabel;
    resLbl: TLabel;
    DateEdit1: TDateEdit;
    dateLbl: TLabel;
    Timer1: TTimer;
    spinner: TAniIndicator;
    stopBtn: TButton;
    procedure showBtnClick(Sender: TObject);
    function MemoryStreamToString(aStream: TMemoryStream): string;
    procedure Timer1Timer(Sender: TObject);
    procedure stopBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    fetchRes:TJSONObject;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}
{$R *.iPhone55in.fmx IOS}
{$R *.Surface.fmx MSWINDOWS}

function TForm1.MemoryStreamToString(aStream: TMemoryStream): string;
var
  SS: TStringStream;
begin
  if aStream <> nil then
  begin
    SS := TStringStream.Create('');
    try
      SS.CopyFrom(aStream, 0);  // No need to position at 0 nor provide size
      Result := SS.DataString;
    finally
      SS.Free;
    end;
  end else
  begin
    Result := '';
  end;
end;

procedure TForm1.showBtnClick(Sender: TObject);

begin
  Timer1Timer(Sender);
  Timer1.Enabled:=true;
end;

procedure TForm1.stopBtnClick(Sender: TObject);
begin
Timer1.Enabled:=false;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
FThread:TDemoThread;
begin
// dfd
  spinner.Enabled:=true;
  FThread := TDemoThread.Create( True );
  FThread.FreeOnTerminate := True;
//  FThread.OnTerminate := DoTerminate;
  FThread.Start();
end;

procedure TDemoThread.Execute();
var
  geturl : string;
  resp:TMemoryStream;
  IdSSL: TIdSSLIOHandlerSocketOpenSSL;
  resJson:TJSONObject;
  str:string;
  strSample:string;
begin
  geturl:='https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByPin?pincode='+Form1.pinEdit.Text+'&date='+Form1.DateEdit1.Text;
  resp:=TMemoryStream.Create;
  IdSSL := TIdSSLIOHandlerSocketOpenSSL.Create(Form1.IdHTTP1);
  IdSSL.SSLOptions.SSLVersions := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
  resJson := nil;
  strSample:='{'+
  '"centers": ['   +
    '{ '+
      '"center_id": 1234, '+
      '"name": "District General Hostpital",'+
      '"name_l": "",'+
      '"address": "45 M G Road",'+
      '"address_l": "",           '+
      '"state_name": "Maharashtra", '+
      '"state_name_l": "",            '+
      '"district_name": "Satara",       '+
      '"district_name_l": "",             '+
      '"block_name": "Jaoli",               '+
      '"block_name_l": "",                    '+
      '"pincode": "413608",                     '+
      '"lat": 28.7,                               '+
      '"long": 77.1,                                '+
      '"from": "09:00:00",                            '+
      '"to": "18:00:00",                                '+
      '"fee_type": "Free",                                '+
     ' "vaccine_fees": [   '+
      '  {    '+
         ' "vaccine": "COVISHIELD",'+
          '"fee": "250"              '+
        '}                             '+
     ' ],                                '+
      '"sessions": [  '+
       ' {              '+
        '  "session_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6", '+
         ' "date": "31-05-2021",                                   '+
          '"available_capacity": 50,                                 '+
         ' "available_capacity_dose1": 25,                             '+
         ' "available_capacity_dose2": 25,                               '+
         ' "min_age_limit": 18,                                            '+
         ' "vaccine": "COVISHIELD",                                          '+
         ' "slots": [                                                          '+
          '  "FORENOON",    '+
           ' "AFTERNOON"      '+
         ' ]}] }]}'  ;


  try
    Form1.IdHTTP1.IOHandler := IdSSL;
    Form1.IdHTTP1.Get(geturl,resp);
    resp.Position:=0;
    str:=Form1.MemoryStreamToString(resp);
    resJson := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(str),0) as TJSONObject;
  finally
    resp.Free;
  end;

  Form1.fetchRes:=resJson;

  Synchronize(DoSynch);
end;

procedure TDemoThread.DoSynch();
var
  sessAry:TJSONArray;
  sessObj:TJSONObject;
  sessObj1:TJSONObject;
  jsonAry:TJSONArray;
  I:integer;
  resJson:TJSONObject;
begin
resJson:=Form1.fetchRes;
jsonAry:= resJson.GetValue('centers') as TJSONArray;
for I := 0 to jsonAry.Size-1 do
    begin
      sessObj:=jsonAry.Get(I) as TJSONObject;
      sessAry:=sessObj.GetValue<TJSONArray>('sessions');
      sessObj1:= sessAry.Get(0) as TJSONObject;

      if (StrToInt(sessObj1.GetValue('available_capacity').ToString)) >0 then
      begin
        Form1.resultMem.Lines.Add('Name: '+sessObj.GetValue('name').ToString);
        Form1.resultMem.Lines.Add('Address : '+sessObj.GetValue('address').ToString);
        Form1.resultMem.Lines.Add('');
      end
      else
      begin
        Form1.resultMem.Lines.Add('No slots found! Checking again in 5 seconds!!');
      end;

    end;
    Form1.spinner.Enabled:=false;
end;

end.
