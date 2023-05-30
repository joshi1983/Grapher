unit MyMath;
{
  This unit contains vector operations and some coordinate system conversions
}

interface
uses math;

type
    tpoint3d = record
       x,y,z: real;
    end;
    vector3d = tpoint3d;
    // a free vector uses the same properties as a point

     function CartToR(x,y,z: Real): Real;
     { returns the distance between a point (x,y,z) and the origin (0,0,0)
       it can also be used to find the distance between any 2 points in space
      This function was named this way because it was originally used to
      convert the cartesian (x,y,z) values into the spherical radius value }
     function proj(v1,v2: Vector3d): tpoint3d;
     function dot(v1,v2: Vector3d): Real;
     function getLineOfSiteVector(r,v,h: real): vector3d;
     function getOpaque2PlaneDir(p1,p2,p3: tpoint3d; v1: Vector3d): real;
     function getOpaqueNwithlineofsite(p1,p2,p3: tpoint3d; v,h: real): real;

implementation

function CartTor(x,y,z: Real): Real;
// this was timed to take typically 45(+- 20) cycles
asm
   fld x; // give the value of x to the stack location 0  - s[4]:=x;
   fmul st,st; // multiply the value in position 0 by x       - s[4]:=s0*x;
   fld y; // give the value of y to the stack location 1  - s[3]:=y;
   fmul st,st; //                                             - s[3]:=s[1]*y;
   fld z;  //                                             - s[2]:=z;
   fmul st,st; //                                             - s[2]:=s[2]*z;
   fadd; //                                    - s[1]:=s[1]+s[2];
   faddp; //                                    - s[0]:=s[0]+s[1];
   fsqrt; //                                   - s[0]:=sqrt(s[0]);
   fstp @result;    //                         - result:=s[0];
   ffree st;
end;
function PolarTox(radius,latitude,longitude: Real): Real;//assembler;
{begin
     result:=radius*cos(latitude)*cos(longitude);}
asm
   fld latitude; // load a new part of the stack for storing the value of "latitude"
   fcos; // change that value to cos of itself
   fld longitude; // shift the position of the previous value to position #1 and load "longitude" into position #0
   fcos; // replace the value with cos(longitude)
   fmul; // multiply stack[0] or "cos(latitiude)" and stack[1] or "cos(longitude)" and give the value to stack[0]
   fmul radius; // multiply stack[0] by "radius"
   fstp result; // return stack[0]
end;

function PolarToy(radius,latitude: Real): Real;assembler;
{begin
     result:=radius*sin(latitude);  }
asm
   fld latitude; // load latitude into stack[0]
   fsin;        // stack[0]:=sin(stack[0]);
   fmul radius; // stack[0]:=stack[0]*radius;
   fstp result; // result:=stack[0];
end;

function PolarToz(radius,latitude,longitude: Real): Real;assembler;
{begin
     result:=radius*cos(latitude)*sin(longitude);   }
asm
   fld latitude;    // load a new part of the stack for storing the value of "latitude"
   fcos;            // change that value to cos of itself
   fld longitude;   // shift the position of the previous value to position #1 and load "longitude" into position #0
   fsin;            // replace the value with csin(longitude)
   fmul;            // multiply stack[0] or "cos(latitiude)" and stack[1] or "cos(longitude)" and give the value to stack[0]
   fmul radius;     // multiply stack[0] by "radius"
   fstp result;    // return stack[0]
end;
//-----------------------------------------------------------------------------
//--------- The following functions were added from material studied in OAC Algebra
function dot(v1,v2: Vector3d): Real;
{ return "v1 • v2"
 v1 • v2 = |v1||v2| cos theta

 theta = the angle of separation between the two vectors
}
begin
     result:=v1.x*v2.x+v1.y*v2.y+v1.z*v2.z;
end;

function cross(v1,v2: Vector3d): Vector3d;
{
return  is "v1 X v2"

v1 X v2 = a vector perpendicullar to the plane containing v1 and v2
}
begin
     result.x:=v1.y*v2.z-v2.y*v1.z;
     result.y:=v1.z*v2.x-v2.z*v1.x;
     result.z:=v1.x*v2.y-v2.x*v1.y;
end;

function proj(v1,v2: Vector3d): Vector3d;
{ return the projection of v2 onto v1
 return " proj  v2 "
              v1

proj  v2  = [(v1•v2)/ |v1| ] * ( v1 capped )
    v1
          = [(v1•v2)/ |v1| ] * ( v1 / |v1| )
          = [(v1•v2)/ sqr |v1| ] * v1
}
var
  magnitude,coefficient: Real;
begin
     magnitude:=carttor(v1.x,v1.y,v1.z);
     if abs(magnitude)>0.0001 then // div 0 check
        coefficient:=dot(v1,v2)/sqr(magnitude)
     else
         // line is parallel to plane and will never actually intersect
         coefficient:=10000;
     v1.x:=v1.x*coefficient;
     v1.y:=v1.y*coefficient;
     v1.z:=v1.z*coefficient;
     result:=v1;
end;

function TripleScalar(v1,v2,v3: Vector3d): Real;
// return the component of the projection of "v3" onto the normal of the
//plane containing v1 and v2

// if this return is zero it means all three vectors are coplanar
begin
     result:=dot(cross(v1,v2),v3);
end;
// -----------------------------------------------------------------
//------------------------------------------------------------------------
//-----------------------------------------------------------------------

function getLineOfSiteVector(r,v,h: real): vector3d;
var
  cosh,tanh,ssinh,tanv: real;
begin
     // now calculate the vector in the line of site
     result.x:=1;
     result.y:=1;
     result.z:=1; // initial values incase there is an error
     cosh:=cos(h);
     if abs(cosh)<0.0001 then
     begin
          exit;
     end;
     tanh:=tan(h);
     ssinh:=sqr(sin(h));
     tanv:=tan(v);
     result.z:=sqrt(sqr(tanh)+sqr(tanv*(cosh+ssinh/cosh))+1);
     if abs(result.z)<0.00001 then
        exit;
     result.z:=r/result.z;
     result.x:=-result.z*tanh;
     result.y:=-result.z*tanv*(cosh+ssinh/cosh);
end;

function getOpaqueNwithlineofsite(p1,p2,p3: tpoint3d; v,h: real): real;
{
 p1,p2,p3 = points on a plane, they can be thought of as vectors if you think of the start point at (0,0,0)
 // these are translated to become 2 direction vectors of the plane
 v,h = the angles out of the xyztox and xyztoy functions


returns a value from 0 to 1 that is sin of the angle difference between the normal
 of the plane and a line of site with the angles from xyztox and xyztoy functions

}
var
  n: Vector3D; // the normal of the plane
  vdir: Vector3D; // the direction (lat,long) converted to a direction vector
  r: real; // used to store the magnitude of a vector
  r2: real;
begin
     result:=0;

     // subtract v1 from both v2 and v3 so v2 and v3 become direction vectors on the plane
     p2.x:=p2.x-p1.x;
     p2.y:=p2.y-p1.y;
     p2.z:=p2.z-p1.z;
     p3.x:=p3.x-p1.x;
     p3.y:=p3.y-p1.y;
     p3.z:=p3.z-p1.z;

     n:=cross(p2,p3); // get a vector normal to the plane
     r:=carttor(n.x,n.y,n.z); // get the magnitude of the vector

     vdir:=GetLineOfSiteVector(r,v,h);
     { vdir becomes a vector with the magnitude of n but a direct that would
     cause it to line up with the origin in the xyztox and xyztoy functions
     }

     r2:=carttor(vdir.x-n.x,vdir.y-n.y,vdir.z-n.z);
     { find the length of a chord between the 2 points that end "vdir" and "n"
      "vdir" and "n" are on the surface of a sphere with the equation x^2+y^2+x^2 = r^2
       that is why I call it a chord }
     if (r*2<r2)or(abs(r)<0.0001) then
     // avoid division by zero and out of range errors
        result:=0
     else
         result:=sin(2*arcsin(r2/2/r)); // the good result
end;

function getOpaque2PlaneDir(p1,p2,p3: tpoint3d; v1: Vector3d): real;
{
 p1,p2,p3 = points on a plane, they can be thought of as vectors if you think of the start point at (0,0,0)
 // these are translated to become 2 direction vectors of the plane
 v1 = a unit direction vector with its direction compared with the normal of a plane


returns a value from 0 to 1 that is sin of the angle difference between the normal
 of the plane and the direction vector

}
var
  n: Vector3D; // the normal of the plane
  r: real; // used to store the magnitude of a vector
begin
     result:=0;

     // subtract v1 from both v2 and v3 so v2 and v3 become direction vectors on the plane
     p2.x:=p2.x-p1.x;
     p2.y:=p2.y-p1.y;
     p2.z:=p2.z-p1.z;
     p3.x:=p3.x-p1.x;
     p3.y:=p3.y-p1.y;
     p3.z:=p3.z-p1.z;

     n:=cross(p2,p3); // get a pector normal to the plane
     r:=carttor(n.x,n.y,n.z); // get the magnitude of the vector

     n.x:=n.x/r;
     n.y:=n.y/r;
     n.z:=n.z/r;
     // now n is a unit vector

     r:=carttor(v1.x-n.x,v1.y-n.y,v1.z-n.z);
     { find the length of a chord between the 2 points that end "vdir" and "n"
      "vdir" and "n" are on the surface of a sphere with the equation x^2+y^2+x^2 = r^2
       that is why I call it a chord }
     result:=sin(2*arcsin(r/2)); // the good result
end;

end.
