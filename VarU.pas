unit VarU;
// variables unit
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TForm3 = class(TForm)
    Memo1: TMemo;
    Label1: TLabel;
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.DFM}

procedure TForm3.FormActivate(Sender: TObject);
begin
     label1.caption:='x'+#13+'y'+#13+'z'+#13+'t';
     // the enter characters(#13) are for separating lines
end;

end.
