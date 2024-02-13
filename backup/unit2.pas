unit Unit2;

{$mode objfpc}{$H+}

interface



uses
  windows, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,unit1,unit3,adcpuusage,math;

type

  { TForm2 }

  TForm2 = class(TForm)
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Timer1: TTimer;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form2: TForm2;
  messungsname:string;
  messbeginn:boolean=true;
  startemessung:boolean=false;
  windowsstartzeit:int64;
  kontrollzeit:int64;
  cpu,Batterypercentage:integer;

implementation
//uses unit1;

{$R *.lfm}

const
  ES_SYSTEM_REQUIRED = DWORD($00000001);
  {$EXTERNALSYM ES_SYSTEM_REQUIRED}
  ES_DISPLAY_REQUIRED = DWORD($00000002);
  {$EXTERNALSYM ES_DISPLAY_REQUIRED}
  ES_USER_PRESENT = DWORD($00000004);
  {$EXTERNALSYM ES_USER_PRESENT}
  ES_CONTINUOUS = DWORD($80000000);
  {$EXTERNALSYM ES_CONTINUOUS}
  ES_AWAYMODE_REQUIRED = DWORD($00000040);
  {$EXTERNALSYM ES_AWAYMODE_REQUIRED}

  type
  EXECUTION_STATE = DWORD;

  function SetThreadExecutionState(esFlags: EXECUTION_STATE): EXECUTION_STATE; stdcall; external 'kernel32.dll';


{ TForm2 }

function GetComputerNetName: string;
var
  buffer: array[0..255] of char;
  size: dword;
begin
  size := 256;
  if GetComputerName(buffer, size) then
    Result := buffer
  else
    Result := '';
end;



function zaehlezeithoch:integer;
begin
result:=trunc((gettickcount64-windowsstartzeit) div 1000);//gettickcount ist die anzahl millisekunden seit windows start
end;//hier wird also die differenz aus dem bei messbeginn gespeicherten tickcount und dem aktuellen tickcount gebildet, es ergibt sich->Messdauer in Sekunden

function UsesBattery:boolean;
 var SystemPowerStatus: TSystemPowerStatus;
 begin
   GetSystemPowerStatus(SystemPowerStatus);
   result := (SystemPowerStatus.ACLineStatus = 0);
 end;

function remainingbatterytime:real;
 var SystemPowerStatus: TSystemPowerStatus;
 begin
   GetSystemPowerStatus(SystemPowerStatus);
   result := SystemPowerStatus.BatteryLifeTime;
 end;

function getBatterypercentage:integer;
 var SystemPowerStatus: TSystemPowerStatus;
 begin
   GetSystemPowerStatus(SystemPowerStatus);
   result := SystemPowerStatus.BatteryLifePercent;
 end;

function messung_unterbrochen:boolean;
begin
result:=false;
if not usesbattery then result:=true;//Wenn das Netzteil eingesteckt wird abbrechen
if abs(kontrollzeit-zaehlezeithoch)>10 then result:=true;//Die Kontrollzeit dient zur Überprüfung ob der Rechner im Standby war->
kontrollzeit:=zaehlezeithoch;//Die Kontrollzeit wird nur mit dem Tickcount/Windowsstartzeit abgeglichen, während das Programm aktiv ist.Im Standby ist das nicht der Fall und es ergibt sich eine Differenz aus den beiden Zeiten.
end;

procedure schreibe_messungsnamen;
var Textdatei:textfile;
begin
  messungsname:=Form2.Edit1.text;
  assignfile(Textdatei, 'letzte_Messung.txt');
  rewrite(Textdatei);
  writeln(Textdatei,messungsname+'.txt');
  closefile(Textdatei);
end;

procedure zeigezeitan(tickerseconds:int64);
var stdfueller,minfueller,sekfueller:string;
    sekunden,minuten,stunden:int64;
begin
  stunden:=trunc(tickerseconds/3600);
  minuten:=trunc(tickerseconds/60-stunden*60);
  sekunden:=tickerseconds-stunden*3600-minuten*60;

  if stunden>99 then stunden:=0;//das hat irgendeinen sinn, den ich aber grad nicht mehr verstehe

  if length(inttostr(sekunden))=1 then
  sekfueller:='0' else sekfueller:='';
  if length(inttostr(minuten))=1 then
  minfueller:='0' else minfueller:='';
  if length(inttostr(stunden))=1 then
  stdfueller:='0' else stdfueller:='';

  Form2.Label1.caption:=stdfueller+inttostr(stunden)+':'+minfueller+inttostr(minuten)+':'+sekfueller+inttostr(sekunden);
end;

procedure TForm2.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  application.terminate;
end;


function fillleadingzeros(input:string; desiredlength:integer):string;
begin
  result := input;
  while desiredlength > length(result) do
  result := '0'+result;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Edit1.text:=Getcomputernetname+'_AkkuTest_'+FormatDateTime('dd.mm.yyyy,hh.mm.ss', now); ;
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  Edit1.text:=Getcomputernetname+'_AkkuTest_'+FormatDateTime('dd.mm.yyyy,hh.mm.ss', now); ;
  label1.caption:='00:00:00';
  timer1.enabled:=true;
  checkbox1.visible:=true;
  checkbox1.enabled:=true;
  checkbox1.checked:=false;
  checkbox1.caption:='Messung starten, wenn Netzteil ausgesteckt wird';
  button3.enabled:=true;
  Edit1.enabled:=true;
  messbeginn:=true;
  startemessung:=false;
end;

procedure TForm2.Timer1Timer(Sender: TObject);
var Textdatei:textfile;
begin
  CollectCPUData;
  Batterypercentage:=getBatterypercentage;
  cpu:=floor(GetCPUUsage(getcpucount-1)*100);
  if cpu<0 then cpu:=0;
  label5.caption:='Aktuelle CPU-Auslastung: '+inttostr(cpu)+' %';
  If Batterypercentage<101 then Label2.caption:='Akku 1 Ladestand: '+inttostr(Batterypercentage)+' %' else Label2.caption:='Akku 1 Ladestand: nicht vorhanden';
  If not usesbattery then label3.caption:='Netzteil: angeschlossen'else label3.caption:='Netzteil: nicht angeschlossen';
  if remainingbatterytime>0 then if remainingbatterytime<86400 then label4.caption:='Geschätzte verbleibende Laufzeit: '+copy(floattostr(remainingbatterytime/3600),1,3)+' Stunden' else label4.caption:='Geschätzte Verbleibende Laufzeit: unbekannt';

  if checkbox1.checked and usesbattery then startemessung:=true;

  if startemessung=true then
  begin
    if messbeginn then //messbeginn ist die initialisierung der Messung
    begin
      button3.enabled:=false;
      Edit1.enabled:=false;
      Checkbox1.visible:=false; //Die checkbox zum starten der messung wird versteckt
      schreibe_messungsnamen;   //der name der messung wird festgelegt
      assignfile(Textdatei,messungsname+'.txt');//Datei wird mit Variable Textdatei verknüpft
      rewrite(Textdatei);   //Datei wird neu angelegt (ggf. überschrieben,kommt hier aber durch Datum+Zeitstempel nie vor)
      closefile(Textdatei); //Datei wird geschlossen
      windowsstartzeit:=GetTickCount64;//Gettickcount ist die Zahl der Millisekunden seit Windows start
      kontrollzeit:=zaehlezeithoch;//Initialisierung (erste Zuweisung der Kontrollzeit)
      messbeginn:=false; //Der Messbeginn und die Inistialisierung sind beendet, somit wird dies durch den Timer nicht mehr aufgerufen
    end;

    if not messung_unterbrochen then
    begin
      assignfile(Textdatei,messungsname+'.txt');//assoziiert die Variable mit der Datei
      append(Textdatei);//An eine existierende Textdatei können mit diesem Befehl Daten an das Ende angehängt werden
      writeln(Textdatei, Label1.caption+'#'+fillleadingzeros(inttostr(getBatterypercentage),3)+'#'+fillleadingzeros(inttostr(cpu),3));//schreibe eine neue Zeile mit hh:mm:ss, Raute, Akkustand # in Prozent+CPU-Auslastung in Prozent
      closefile(Textdatei);//Datei schließen


      SetThreadExecutionState(ES_DISPLAY_REQUIRED);    // Prevent Screensaver
      SetThreadExecutionState(ES_SYSTEM_REQUIRED); // Prevent Standby or Hibernate

      //KEYBD_EVENT(VK_SCROLL,0,0,0);     //STRG-Taste drücken->Bildschirm bleibt aktiv
      //KEYBD_EVENT(VK_SCROLL,0,KEYEVENTF_KEYUP,0); //STRG-Taste loslassen
      zeigezeitan(zaehlezeithoch);//zaehlezeithoch=Messdauer in Sekunden
      //zeigezeitan=zeigt zahlezeit hoch im Format hh:mm:ss in Label1 an
    end
    else
    begin
      //Messung auswerten
      timer1.enabled:=false;
      Form1.Show;
      Form2.Hide;
      Form1.ShowInTaskBar:=stalways;
      Form1.ShowInTaskBar:=stnever;
      showmessage('Messung beendet !');
      Form1.Chart1LineSeries1.Clear;
      lade_graph(messungsname+'.txt');
    end;
  end;
end;

procedure TForm2.CheckBox1Change(Sender: TObject);
begin
  if checkbox1.checked then begin
  checkbox1.caption:='Warte auf Ausstecken des Netzteiles...';
  if (Batterypercentage<95) then showmessage('Um ein aussagekräftiges Ergebnis zu bekommen, sollte der Akku vor Testbeginn auf mindestens 95% geladen werden !');
  if (cpu>5) then showmessage('Um ein aussagekräftiges Ergebnis zu bekommen, sollte die CPU-Auslastung nicht zu hoch sein ! ->Hintergrunddienste/Programm beenden');
  end
  else
  checkbox1.caption:='Messung starten, wenn Netzteil ausgesteckt wird';

end;


procedure switchform(form:integer);
begin
  if form=1 then
    begin
      form2.Hide;
      form2.ShowInTaskBar:=stnever;
      form1.show;
      form1.ShowInTaskBar:=stalways;
      form2.timer1.enabled:=false;
    end;

  if form=2 then
    begin
      form1.Hide;
      form1.ShowInTaskBar:=stnever;
      form1.timer1.enabled:=false;
      form2.timer1.enabled:=true;
      form2.show;
      form2.ShowInTaskBar:=stalways;

    end;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
 Form3.Show;
end;

procedure TForm2.Button3Click(Sender: TObject);
begin
  form1.openDialog1.InitialDir := GetCurrentDir;
  if form1.opendialog1.execute then
  if form1.opendialog1.filename<>'' then
  begin
    form1.chart1lineseries1.clear;
    try
      lade_graph(form1.opendialog1.filename);
      Form1.button2.enabled:=false;
      Form1.button3.enabled:=false;
    except
      showmessage('Keine gültige Messdatei !');
      exit;
    end;
    switchform(1);
  end;



end;

procedure TForm2.Button4Click(Sender: TObject);
begin
  application.terminate;
end;

end.

