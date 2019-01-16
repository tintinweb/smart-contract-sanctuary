pragma solidity ^0.4.0;
contract calculator
{       uint z;
        uint a;
        uint b;
        uint c;
        uint d;
    function cal(uint x,uint y) public 
       {
           z=x+y;
           a=x-y;
           b=x*y;
           c=x/y;
           d=x%y;
       }
       function getadd() public view returns (uint,string,uint,string,uint,string,uint,string,uint,string)
       {
           return (z,"addition",a,"subtraction",b,"multiplication",c,"division",d,"modulus");
       }
}