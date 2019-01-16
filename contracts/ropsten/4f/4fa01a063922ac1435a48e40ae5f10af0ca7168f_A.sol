pragma solidity ^0.4.25;

contract A {
    
    event haha(uint amount);
    
    function a() public {
        
  
        
        b();
    }
    
    function b() public{
        
        
       emit haha(123);
        
    }
 
    
    
}