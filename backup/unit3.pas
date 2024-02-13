unit Unit3;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Spin,
  StdCtrls;

type

  { TForm3 }

  TForm3 = class(TForm)
    ComboBox1: TComboBox;
    Label1: TLabel;
    procedure ComboBox1Change(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.lfm}

{ TForm3 }

procedure TForm3.ComboBox1Change(Sender: TObject);
begin

  Case Combobox1.itemindex of
  0:Label1.Caption:='Akkutest ist ein Programm, um die maximale Akkulaufzeit eines mobilen Rechners (Notebook) bei eingeschalteter Displaybeleuchtung zu ermitteln.';
  1:Label1.Caption:='Zunächst sollte der Akku auf 100% geladen werden. Um die CPU-Auslastung gering zu halten, empfiehlt es sich, alle Netzwerkverbindungen zu trennen->Windows Updates etc. vermeiden. Die Akku Messung wird gestartet, wenn das kleine Kästchen angehakt wird und das Netzteil entfernt wird oder bereits entfernt ist. Jetzt wird das Notebook einfach laufen gelassen, bis der Akku leer ist und das Notebook ausgeht. Wird das Notebookdann erneut eingeschaltet, werden die Messergebnisse angezeigt. Werden keine Messergebnisse angezeigt, so muss Akkutest erneut gestartet werden.';
  2:Label1.Caption:='Programmiert von Julian Meyn, Bugs und Feedback bitte an julianmeyn@outlook.de';
  3:Label1.Caption:='Version 1.1, Neuerungen: Speicherung der Messung als JPEG-Bild, Auslesen und Protokollieren der CPU-Auslastung; Version 1.2, Bug beim Laden gespeicherter Messungen behoben';
  end;
end;

end.

