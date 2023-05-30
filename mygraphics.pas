unit MyGraphics;

interface
uses windows,sysutils,graphics,math;
type
   tscanlines = record // basically a pointer to different parts of a bitmap
              rows: array of pointer; // points to each row of pixel data
              width: integer; // the width of the bitmap being pointed to
              height: integer; // the height of the bitmap being pointed to
   end;

   procedure Alpha_Triangle(p1,p2,p3: tpoint;r,g,b,ratio: byte; bit1: tbitmap); overload;
   procedure Alpha_Triangle(p1,p2,p3: tpoint;r,g,b,ratio: byte; bit1: tscanlines); overload;
   function GetScanlines(bit1: Graphics.tbitmap): tscanlines;

implementation

function GetScanlines(bit1: Graphics.tbitmap): tscanlines;
var // the result is a pointer to information in bit1
   y: integer;
  pba: pbytearray;
begin
     SetLength(result.rows,bit1.Height);
     result.Width:=bit1.Width;
     result.Height:=bit1.Height; // store the dimensions of the bitmap
     for y:=bit1.height-1 downto 0 do // loop through the rows of pixels
         Result.rows[y]:=bit1.ScanLine[y];
end;

procedure Alpha_Triangle(p1,p2,p3: tpoint;r,g,b,ratio: byte; bit1: tbitmap); overload;
{
p1,p2,p3 = the 3 vertices or points at the corners of the triangle
r,g,b = the red, green, and blue values being averaged with the colours behind
ratio = a value from 0 to 255 that determines how opaque the fill of the triangle will be
      -> 0 for transparent, 255 for completely opaque, however,
      in either of these extremes, it doesn't make sence to use this procedure
bit1 = the bitmap having the triangle drawn on

}

 // this function draws a filled triangle
 // by dividing it in half and stepping through
 // each line

var
  x,y: integer;
  height: integer; // looping variables
  dx_right,dx_left: {fixed}integer; // used as 32 bit fixed
 // the dx/dy ratio of the right and left edges of the line
 xs, xe: {fixed}integer; //  the starting and ending points of the edges
 temp_x, temp_y: integer;
 right_x,left_x: integer;
 pb: pbytearray;
 p: pointer;
 w: integer; // (width of bitmap) * (# of bytes per pixel)
 x2: integer; // x*(# of bytes per pixel)
 miny,maxy,minx,maxx: integer;
 bratio,gratio,rratio: integer; // for simplifying the math
 nratio: integer;
begin
     if (p1.x<0)and(p2.x<0)and(p3.x<0) then
        exit;
     if (p1.y<0)and(p2.y<0)and(p3.y<0) then
        exit;
     maxx:=bit1.width-1;
     if (p1.x>maxx)and(p2.x>maxx)and(p3.x>maxx) then
        exit;
     maxy:=bit1.height-1;
     if (p1.y>maxy)and(p2.y>maxy)and(p3.y>maxy) then
        exit;
     // exit if none of the triangle will be shown anyway
     bit1.PixelFormat:=pf24bit;
     nratio:=255-ratio;
     bratio:=b*ratio;
     gratio:=g*ratio;
     rratio:=r*ratio;
     w:=bit1.width*3;
     // make sure points are in order
     if (p2.y < p1.y) then
     begin
          temp_y := p1.y;
          temp_x := p1.x;
          p1.y := p2.y;
          p1.x := p2.x;
          p2.y := temp_y;
          p2.x := temp_x;
     end;
     if (p3.y < p1.y) then
     begin
          temp_y := p1.y;
          temp_x := p1.x;
          p1.y := p3.y;
          p1.x := p3.x;
          p3.y := temp_y;
          p3.x := temp_x;
     end;
     if (p3.y < p2.y) then
     begin
          temp_y := p3.y;
          temp_x := p3.x;
          p3.y := p2.y;
          p3.x := p2.x;
          p2.y := temp_y;
          p2.x := temp_x;
     end;
     left_x := p2.x;
     if p3.y=p1.y then
        right_x := 10000
     else
         right_x := round(p1.x + (p2.y-p1.y)*(p3.x-p1.x)/(p3.y-p1.y));

     if (right_x < left_x)then // messes up if right is on left
     begin
          temp_x := right_x;
          right_x := left_x;
          left_x := temp_x;
     end;

     /////!!DRAW TOP!!///////

     //draw the triangle top

     if (p1.y <> p2.y) then
     begin
          // compute height of subtriangle
          height := p2.y - p1.y;
          // set starting points
          xs := p1.x shl 8;
          xe := p1.x shl 8; // shifts to convert to fixed format
          // compute edge ratios
          dx_left := ((left_x - p1.x) shl 8) div height;
          dx_right := ((right_x - p1.x) shl 8) div height;
          ///DRAW IT ALREADY!!!!
          miny:=max(0,p1.y);
          maxy:=min(bit1.height-1,p2.y);
          x2:=(((bit1.width * 24) + 31) and not 31);
          x2:=x2 div 8;
          for y := miny to maxy do
          begin
               pb:=bit1.ScanLine[y];
               minx:=max(0,xs shr 8);
               maxx:=min(bit1.width-1,xe shr 8);
               for x := minx to maxx do
               begin
{                   x2:=x*3;
                   pb[x2]:=(pb[x2]*nratio+b*ratio) shr 8;
                   pb[x2+1]:=(pb[x2+1]*nratio+g*ratio) shr 8;
                   pb[x2+2]:=(pb[x2+2]*nratio+r*ratio) shr 8; }
                   asm

                      mov EAX,DWORD PTR [pb]; // eax = the address of pixel[0] in the row
                      mov edx,x;
                      imul edx,3;
                      add eax,edx;                   // eax = the address of the pixel in the bitmap

                      // blue byte
                      xor ecx,ecx;

                      mov cl,byte [eax];
                      imul ecx,dword [nratio];          // cl = pixel.BlueByte * nratio
                      add ecx,bratio;

                      mov byte ptr [eax],ch;

                      // green byte
                      xor ecx,ecx;

                      mov cl,byte [eax+1];
                      imul ecx,dword [nratio];          // cl = pixel.GreenByte * nratio
                      add ecx,gratio;

                      mov byte ptr [eax+1],ch;


                      // red byte
                      xor ecx,ecx;

                      mov cl,byte [eax+2];
                      imul ecx,dword [nratio];          // cl = pixel.RedByte * nratio
                      add ecx,rratio;

                      mov byte ptr [eax+2],ch;

                   end;
               end;
               //adjust starting and ending point

               xs :=xs+ dx_left;
               xe :=xe+ dx_right;
          end;
     end;
     if (p2.y <> p3.y) then
     begin
          //now recompute slope of shorter edge to finish triangle bottom

          // recompute slopes
          height := p3.y - p2.y;
          dx_right := ((p3.x - right_x) shl 8) div (height);
          dx_left := ((p3.x - left_x) shl 8) div (height);
          xs := left_x shl 8;
          xe := right_x shl 8;

          if p3.y>= bit1.height then
             p3.y:=bit1.height-1; // prevent an access violation error

          // draw the rest of the triangle
          miny:=max(0,p2.y+1);
          maxy:=min(bit1.height-1,p3.y);
          for y := miny to maxy do
          begin
               pb:=bit1.ScanLine[y];
               minx:=max(0,xs shr 8);
               maxx:=min(bit1.width-1,xe shr 8);
               for x := minx to maxx do
               begin
                   {x2:=x*3;
                   pb[x2]:=(pb[x2]*nratio+b*ratio) shr 8;
                   pb[x2+1]:=(pb[x2+1]*nratio+g*ratio) shr 8;
                   pb[x2+2]:=(pb[x2+2]*nratio+r*ratio) shr 8; }
                   asm
                      mov EAX,DWORD PTR [pb];
                      mov edx,x;
                      imul edx,3;
                      add eax,edx;                   // eax = the address of the pixel in the bitmap

                      // blue byte
                      xor ecx,ecx;

                      mov cl,byte [eax];
                      imul ecx,dword [nratio];          // cl = pixel.BlueByte * nratio
                      add ecx,bratio;

                      mov byte ptr [eax],ch;

                      // green byte
                      xor ecx,ecx;

                      mov cl,byte [eax+1];
                      imul ecx,dword [nratio];          // cl = pixel.GreenByte * nratio
                      add ecx,gratio;

                      mov byte ptr [eax+1],ch;


                      // red byte
                      xor ecx,ecx;

                      mov cl,byte [eax+2];
                      imul ecx,dword [nratio];          // cl = pixel.RedByte * nratio
                      add ecx,rratio;

                      mov byte ptr [eax+2],ch;

                   end;
               end;
               //adjust starting and ending point
               xs :=xs+ dx_left;
               xe :=xe+ dx_right;
          end; //end for
     end;
end;

procedure Alpha_Triangle(p1,p2,p3: tpoint;r,g,b,ratio: byte; bit1: tscanlines); overload;
{
p1,p2,p3 = the 3 vertices or points at the corners of the triangle
r,g,b = the red, green, and blue values being averaged with the colours behind
ratio = a value from 0 to 255 that determines how opaque the fill of the triangle will be
      -> 0 for transparent, 255 for completely opaque, however,
      in either of these extremes, it doesn't make sence to use this procedure
bit1 = the bitmap having the triangle drawn on

}

 // this function draws a filled triangle
 // by dividing it in half and stepping through
 // each line

var
  x,y: integer;
  height: integer; // looping variables
  dx_right,dx_left: {fixed}integer; // used as 32 bit fixed
 // the dx/dy ratio of the right and left edges of the line
 xs, xe: {fixed}integer; //  the starting and ending points of the edges
 temp_x, temp_y: integer;
 right_x,left_x: integer;
 pb: pbytearray;
 p: pointer;
 w: integer; // (width of bitmap) * (# of bytes per pixel)
 x2: integer; // x*(# of bytes per pixel)
 miny,maxy,minx,maxx: integer;
 bratio,gratio,rratio: integer; // for simplifying the math
 nratio: integer;
begin
     if (p1.x<0)and(p2.x<0)and(p3.x<0) then
        exit;
     if (p1.y<0)and(p2.y<0)and(p3.y<0) then
        exit;
     maxx:=bit1.width-1;
     if (p1.x>maxx)and(p2.x>maxx)and(p3.x>maxx) then
        exit;
     maxy:=bit1.height-1;
     if (p1.y>maxy)and(p2.y>maxy)and(p3.y>maxy) then
        exit;
     // exit if none of the triangle will be shown anyway
     nratio:=255-ratio;
     bratio:=b*ratio;
     gratio:=g*ratio;
     rratio:=r*ratio;
     w:=bit1.width*3;
     // make sure points are in order
     if (p2.y < p1.y) then
     begin
          temp_y := p1.y;
          temp_x := p1.x;
          p1.y := p2.y;
          p1.x := p2.x;
          p2.y := temp_y;
          p2.x := temp_x;
     end;
     if (p3.y < p1.y) then
     begin
          temp_y := p1.y;
          temp_x := p1.x;
          p1.y := p3.y;
          p1.x := p3.x;
          p3.y := temp_y;
          p3.x := temp_x;
     end;
     if (p3.y < p2.y) then
     begin
          temp_y := p3.y;
          temp_x := p3.x;
          p3.y := p2.y;
          p3.x := p2.x;
          p2.y := temp_y;
          p2.x := temp_x;
     end;
     left_x := p2.x;
     if p3.y=p1.y then
        right_x := 10000
     else
         right_x := round(p1.x + (p2.y-p1.y)*(p3.x-p1.x)/(p3.y-p1.y));

     if (right_x < left_x)then // messes up if right is on left
     begin
          temp_x := right_x;
          right_x := left_x;
          left_x := temp_x;
     end;

     /////!!DRAW TOP!!///////

     //draw the triangle top

     if (p1.y <> p2.y) then
     begin
          // compute height of subtriangle
          height := p2.y - p1.y;
          // set starting points
          xs := p1.x shl 8;
          xe := p1.x shl 8; // shifts to convert to fixed format
          // compute edge ratios
          dx_left := ((left_x - p1.x) shl 8) div height;
          dx_right := ((right_x - p1.x) shl 8) div height;
          ///DRAW IT ALREADY!!!!
          miny:=max(0,p1.y);
          maxy:=min(bit1.height-1,p2.y);
          x2:=(((bit1.width * 24) + 31) and not 31);
          x2:=x2 div 8;
          for y := miny to maxy do
          begin
               pb:=bit1.rows[y];
               minx:=max(0,xs shr 8);
               maxx:=min(bit1.width-1,xe shr 8);
               for x := minx to maxx do
               begin
{                   x2:=x*3;
                   pb[x2]:=(pb[x2]*nratio+b*ratio) shr 8;
                   pb[x2+1]:=(pb[x2+1]*nratio+g*ratio) shr 8;
                   pb[x2+2]:=(pb[x2+2]*nratio+r*ratio) shr 8; }
                   asm

                      mov EAX,DWORD PTR [pb]; // eax = the address of pixel[0] in the row
                      mov edx,x;
                      imul edx,3;
                      add eax,edx;                   // eax = the address of the pixel in the bitmap

                      // blue byte
                      xor ecx,ecx;

                      mov cl,byte [eax];
                      imul ecx,dword [nratio];          // cl = pixel.BlueByte * nratio
                      add ecx,bratio;

                      mov byte ptr [eax],ch;

                      // green byte
                      xor ecx,ecx;

                      mov cl,byte [eax+1];
                      imul ecx,dword [nratio];          // cl = pixel.GreenByte * nratio
                      add ecx,gratio;

                      mov byte ptr [eax+1],ch;


                      // red byte
                      xor ecx,ecx;

                      mov cl,byte [eax+2];
                      imul ecx,dword [nratio];          // cl = pixel.RedByte * nratio
                      add ecx,rratio;

                      mov byte ptr [eax+2],ch;

                   end;
               end;
               //adjust starting and ending point

               xs :=xs+ dx_left;
               xe :=xe+ dx_right;
          end;
     end;
     if (p2.y <> p3.y) then
     begin
          //now recompute slope of shorter edge to finish triangle bottom

          // recompute slopes
          height := p3.y - p2.y;
          dx_right := ((p3.x - right_x) shl 8) div (height);
          dx_left := ((p3.x - left_x) shl 8) div (height);
          xs := left_x shl 8;
          xe := right_x shl 8;

          if p3.y>= bit1.height then
             p3.y:=bit1.height-1; // prevent an access violation error

          // draw the rest of the triangle
          miny:=max(0,p2.y+1);
          maxy:=min(bit1.height-1,p3.y);
          for y := miny to maxy do
          begin
               pb:=bit1.rows[y];
               minx:=max(0,xs shr 8);
               maxx:=min(bit1.width-1,xe shr 8);
               for x := minx to maxx do
               begin
                   {x2:=x*3;
                   pb[x2]:=(pb[x2]*nratio+b*ratio) shr 8;
                   pb[x2+1]:=(pb[x2+1]*nratio+g*ratio) shr 8;
                   pb[x2+2]:=(pb[x2+2]*nratio+r*ratio) shr 8; }
                   asm
                      mov EAX,DWORD PTR [pb];
                      mov edx,x;
                      imul edx,3;
                      add eax,edx;                   // eax = the address of the pixel in the bitmap

                      // blue byte
                      xor ecx,ecx;

                      mov cl,byte [eax];
                      imul ecx,dword [nratio];          // cl = pixel.BlueByte * nratio
                      add ecx,bratio;

                      mov byte ptr [eax],ch;

                      // green byte
                      xor ecx,ecx;

                      mov cl,byte [eax+1];
                      imul ecx,dword [nratio];          // cl = pixel.GreenByte * nratio
                      add ecx,gratio;

                      mov byte ptr [eax+1],ch;


                      // red byte
                      xor ecx,ecx;

                      mov cl,byte [eax+2];
                      imul ecx,dword [nratio];          // cl = pixel.RedByte * nratio
                      add ecx,rratio;

                      mov byte ptr [eax+2],ch;

                   end;
               end;
               //adjust starting and ending point
               xs :=xs+ dx_left;
               xe :=xe+ dx_right;
          end; //end for
     end;
end;

end.
