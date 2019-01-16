pragma solidity ^0.4.24;

contract SimpleStorage {
    //uint storedData;
    uint Sumadd;
    uint Subtraction;
    uint Mul;
    uint Division;
    
     function set(uint x,uint y) public {
         
       Sumadd = x+y;
        if(x>y || x==y){
            Subtraction = x-y;
        } else{
           Subtraction = y-x;
        }
        Mul = x*y;
         if(x!=0 && y!=0){
             if(x>y || x==y){
            Division = x/y;
        } else{
           Division = y/x;
        }
         }
    }
    
    function get() public view returns(uint,uint,uint,uint){
        return (Sumadd,Subtraction,Mul,Division);
    }
}