pragma solidity ^0.4.24;

contract Calculator {
     int a;
     int b;
     int c;
     function add(int _x,int _y) public{
         a=_x;
         b=_y;
         c=a+b;
     }
     function sub(int _x,int _y) public{
         a=_x;
         b=_y;
         c=a-b;
     }
     function mul(int _x,int _y) public{
         a=_x;
         b=_y;
         c=a*b;
     }
     function div(int _x,int _y) public{
         a=_x;
         b=_y;
         c=a/b;
     }
     function get() view public returns(int){
         return c;
     }
}