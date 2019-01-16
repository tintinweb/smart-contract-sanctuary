pragma solidity ^0.4.24;

contract Simple {
    int a;
    int b;
    function set(int x , int y ) public{
        a=x;
        b=y;
    }
    
    function addition() public view returns (int o_sum)
    {
        o_sum = a + b;
    }
    
    function subtraction() public view returns (int o_sub){
        o_sub = a-b;
    }
    
    function multiplication() public view returns (int o_mul){
          o_mul = a*b;
    }
    
    function division() public view returns (int o_div){
        o_div = a/b;
    }
 }