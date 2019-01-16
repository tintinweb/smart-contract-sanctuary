pragma solidity ^0.4.0;
contract cal
{ 
  uint a;uint b;uint c;uint d;uint e;
  function add(uint x,uint y)public
  {
     a=x+y;
  }
  function getadd()public view returns(uint)
  {
      return a;
  }
  function sub(uint x,uint y)public
  {
     b=x-y;
    }
    
    function getsub()public view returns(uint)
    {
        return b;
    }
    function div(uint x,uint y)public
    {
      c=x/y;
    }
    function getdiv()public view returns(uint)
    {
        return c;
    }
    function mul(uint x,uint y)public 
    {
      d=x*y;
     
    }
    function getmul()public view returns(uint)
    {
        return d;
    }
    function mod(uint x,uint y)public
    {
      e=x%y;
    }
    function getmod()public view returns(uint)
    {
        return e;
    }
}