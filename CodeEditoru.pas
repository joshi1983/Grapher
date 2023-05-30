unit CodeEditoru;
{ code editor unit
 contains code that:
                    - compiles the strings in the stringgrid into function1
                    - comiles the variables
                    - runs the function
                    - stores coordinates into the points array
                    - has extra features for manipulating the stringgrid

 }
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, StdCtrls,math,shellapi,mainu;

type
  TForm2 = class(TForm)
    StringGrid1: TStringGrid;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
  Funcresult = array of real; // the result the programmed function could be a number of different real values
  comType = record
          name: string; // the name of the command ie. 'Mul'
          NumParam: integer; // the number of parameters 0..2
  end;
  instr = record
        comnum: integer;
        // a way of identifying the type of command being used
        param1,param2: integer;
        // pointers to elements of the values array
  end;
  identifier1 = record
              name: string; // the name of the variable or constant
              valnum: integer; // where to find the value in the values array
  end;

var
  Form2: TForm2;
   points: array[-height1..height1,-width1..width1,-time1..time1] of real;
   commands: array[0..16] of comType;
   function1: array of instr;
   // the function used to get a y coordinate for every point on the graph
   values: array of real; // some memory that is used by the commands in the function
   identifiers: array of identifier1;
   // a bunch of pointers to values in the array
   // with a string that matches one of the identifiers, a locaiton in the values array can also be found
   activated: boolean;

implementation
uses  VarU;
{$R *.DFM}

function valfloat(str1: string): boolean;
var
  c: byte; // represents character number in the for loop
  d,e: boolean; // represents the statement "a decimal has been found in the string."
// used to find the string invalid if there are more than one decimal
begin
     result:=true;
     d:=False;
     e:=False;
     str1:=lowercase(str1);
     if (str1<>'-')and(str1<>'')and(str1<>'.') then
     begin
          for c:=1 to length(str1) do
          begin // loop through the characters in the string
               if ((str1[c]>'9')or(str1[c]<'0'))and(str1[c]<>'.')and(str1[c]<>'-')and(str1[c]<>'e') then
               begin
                  result:=False; // an error will occur if trying to convert the string to real
                  break; // the string was found invalid so there is no reason
                  // to continue in the for loop
               end;
               if str1[c]='.' then
               begin
                    if d then // if there was another decimal already found
                    begin
                         result:=False;
                         break; // breaks the for loop so this can be more efficient
                    end;
                    d:=true; // a decimal has been found
               end
               else if (str1[c]='-')and(c<>1) then
               begin
                    result:=False;
                    break;
               end
               else if str1[c]='e' then
               begin
                    if e then
                    begin
                       result:=False;
                       break;
                    end;
                    e:=true;
               end;
          end;
     end
     else // string is invalid
         result:=False;
     if not result then
        beep; // help notify the user of the problem of an invalid number
end;

procedure labelSGrid;
var
  x: integer;
begin
     with form2.stringgrid1 do
     begin
          cells[0,0]:='Line #';
          cells[1,0]:='Command';
          cells[2,0]:='Param.#1';
          cells[3,0]:='Param.#2';
          for x:=RowCount-1 downto 1 do
              cells[0,x]:=inttostr(x);
     end;
end;

procedure AddVar(nm: string;val1: real);
begin
     SetLength(identifiers,high(identifiers)+2);
     SetLength(values,high(values)+2);
     with identifiers[high(identifiers)] do
     begin
          name:=nm;
          valnum:=high(values);
     end;
     values[high(values)]:=val1;
end;

function CompileCode: boolean;
// function returns true if the compilation process was successful

   function GetcomType(s1: string): integer;
   var
     y: integer;
   begin
        result:=-1;
        for y:=high(commands) downto 0 do
        begin
             if lowercase(s1)=lowercase(commands[y].name) then
                result:=y;
        end;
   end;
   function GetVarNum(s1: string): integer;
   var
     y: integer;
   begin
        result:=-1;
        for y:=high(identifiers) downto 0 do
        begin
             if lowercase(s1)=lowercase(identifiers[y].name) then
                result:=y;
        end;
        if result<0 then
           if valfloat(s1) then
           begin
                AddVar(s1,strtofloat(s1));
                result:=high(values);
           end;
   end;

var
   s: string;
  x: integer;
  instr1: instr; // a temperary instruction to hold the value of an instruction
  // that will be added to the function after being compiled from the row in the stringgrid
  label ErrorExit;
  label ErrorUnknownVar;
  label EndofPass;
begin
     result:=true; // initialy no error has happened while compiling this code
     function1:=nil; // clear the function that currently exists
     identifiers:=nil;
     values:=nil;
     AddVar('x',0);
     AddVar('y',0);
     AddVar('z',0);
     AddVar('t',0);
     // these variables must always be included in the function's variable list
     // because they are basically used as parameters that change the value of the result of the function
     // this is how the graph is created instead of just a flat plane
     for x:=0 to form3.memo1.lines.count do
     begin
          s:=form3.memo1.lines[x];
          if s<>'' then
             AddVar(s,0);
     end;
     with form2.stringgrid1 do
     for x:=1 to rowcount-1 do
     begin
          s:=cells[1,x];
          if s='' then
             Goto EndofPass;
          instr1.comnum:=getcomType(s);
          if instr1.comnum<0 then
          begin
               ShowMessage(inttostr(x)+': Unknown command -> '+s);
               GoTo ErrorExit;
          end
          else if commands[instr1.comnum].numparam>0 then
          begin // there are a few parameters to the command
               s:=cells[2,x];
               instr1.param1:=getVarNum(s);
               if instr1.param1<0 then
                  Goto ErrorUnknownVar;
               if commands[instr1.comnum].numparam>1 then
               s:=cells[3,x];
               instr1.param2:=getVarNum(s);
               if instr1.param2<0 then
                  Goto ErrorUnknownVar;
          end;
          SetLength(function1,high(function1)+2);
          function1[high(function1)]:=instr1;
          EndofPass:
     end;
     exit; // leave out the error message and just exit this compilecode function
     // this prevents the below code from being executed
     ErrorUnknownVar:
                     ShowMessage(inttostr(x)+': Unknown parameter -> '+s);
     ErrorExit:
               result:=false;
end;

function RunFunction1: real;
var
  ProgramCounter: integer; // stores the current command being executed in the function
  cmp1: integer; // used to store the result of a comparison
  h: real; // a hidden variable used like a register to store temperary values
begin
     result:=0;
     ProgramCounter:=0; // start at the first command in the function
     h:=0;
     cmp1:=0; // just initialize the comparison result
     while (programcounter<=high(function1))and(programcounter>-1) do
     begin
         with function1[programcounter] do
          case comnum of
          0: h:=values[param1]; // load
          1: values[param1]:=h; // saveto
          2: values[param1]:=values[param2]; // mov
          3: h:=h*values[param1]; // mul
          4: if abs(values[param1])>0.0001 then // avoid division by 0
                h:=h/values[param1]; // div
          5: h:=h+values[param1]; // add
          6: h:=h-values[param1]; // sub
          7: h:=sin(h); // sin
          8: h:=cos(h); // cos
          9: h:=tan(h); // tan
          10: h:=abs(h); // abs
          11: if values[param1]>values[param2] then
                 cmp1:=1
              else if values[param1]=values[param2] then
                   cmp1:=0
              else
                  cmp1:=-1;  // cmp
          12: programcounter:=round(values[param1])-1; // jmp
          13: if cmp1<0 then                           // JL
                 programcounter:=round(values[param1])-1;
          14: if cmp1=0 then                           // JE
             programcounter:=round(values[param1])-1;
          15: if cmp1>0 then                          // JG
                 programcounter:=round(values[param1])-1;
          16: h:=hypot(values[param1],values[param2]); // hypot
          end;
          inc(programcounter);
     end;
     result:=values[1];
end;

procedure CompileGraph;
var
  x,z,t: integer;
begin
     for x:=-height1 to height1 do
         for z:=-width1 to width1 do
             for t:=-time1 to time1 do
             begin
                  values[0]:=x;
                  // [1] is y witch stores the result of the function
                  values[2]:=z;
                  values[3]:=t;
                  // basically this is instead of passing parameters to the function
                  // setting the values like this is like setting the values of global variables so they can be used in the function
                  points[x,z,t]:=RunFunction1;
             end;
end;

procedure TForm2.Button1Click(Sender: TObject);
begin  // Add New Row
     stringgrid1.RowCount:=stringgrid1.RowCount+1;
     labelSGrid;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin // Delete Last Row
     stringgrid1.RowCount:=stringgrid1.RowCount-1;
end;

procedure TForm2.FormActivate(Sender: TObject);
begin
     if activated then
        exit;
     labelSGrid;
     with stringgrid1 do
     begin
          cells[1,1]:='hypot'; cells[2,1]:='x'; cells[3,1]:='z';
          cells[1,2]:='add'; cells[2,2]:='t';
          cells[1,3]:='div'; cells[2,3]:='2';
          cells[1,4]:='sin';  cells[2,4]:='2';
          cells[1,5]:='mul';  cells[2,5]:='2';
          cells[1,6]:='saveto'; cells[2,6]:='y';
     end;
     activated:=true;
end;

procedure TForm2.Button3Click(Sender: TObject);
begin // Compile Graph
     if not CompileCode then
          ShowMessage('There was an error in compiling the code so the graph could not be created.')
     else
         CompileGraph;
     Form1.repaint;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
     commands[0].name:='Load';
     commands[0].numparam:=1;
     commands[1].name:='Saveto';
     commands[1].numparam:=1;
     commands[2].name:='Mov';
     commands[2].numparam:=2;
     commands[3].name:='Mul';
     commands[3].numparam:=1;
     commands[4].name:='Div';
     commands[4].numparam:=1;
     commands[5].name:='Add';
     commands[5].numparam:=1;
     commands[6].name:='Sub';
     commands[6].numparam:=1;
     commands[7].name:='Sin';
     commands[7].numparam:=0;
     commands[8].name:='Cos';
     commands[8].numparam:=0;
     commands[9].name:='Tan';
     commands[9].numparam:=0;
     commands[10].name:='Abs';
     commands[10].numparam:=0;
     commands[11].name:='CMP';
     commands[11].numparam:=2;
     commands[12].name:='JMP';
     commands[12].numparam:=1;
     commands[13].name:='JL';
     commands[13].numparam:=1;
     commands[14].name:='JE';
     commands[14].numparam:=1;
     commands[15].name:='JG';
     commands[15].numparam:=1;
     commands[16].name:='hypot';
     commands[16].numparam:=2;
     activated:=false;
end;

function ExecuteFile(FileName, Params, DefaultDir: string): HWND;
begin
     Result := ShellExecute(form1.handle,nil,PChar(FileName), PChar(Params),
     PChar(DefaultDir), SW_SHOWNORMAL);
end;

function GetDir: string;
var
  x: integer;
begin
     result:=application.exename;
     x:=length(result);
     while (x>1)and(result[x]<>'\') do
           dec(x);
     result:=copy(result,1,x-1);
end;

procedure OpenFolderFile(s: string);
var
  fn: string;
  x: integer;
begin
     fn:=GetDir; // get the directory containing this program without the last "\"
     x:=ExecuteFile(s,'',fn);
     if fileexists(fn+'\'+s) and (x<5) then
        showmessage('This should work because the file exists but for some reason it won''t open.');
     if x<5 then
        ShowMessage('There was a problem loading a file.'+#13+
        'Make sure you have the file called help.html');
end;

procedure TForm2.Button4Click(Sender: TObject);
begin // Help
      OpenFolderFile('Help.html');
end;

procedure TForm2.Button5Click(Sender: TObject);
begin // Variables
     Form3.ShowModal;
end;

end.
