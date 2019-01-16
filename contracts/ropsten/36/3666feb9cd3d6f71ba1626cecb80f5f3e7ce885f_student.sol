pragma solidity ^0.5.0;

contract student {
    uint n;
    
   function set(uint i) public {
       n =i;
   }
    
    function get() view public returns (uint) {
        return n;
    }
}