pragma solidity ^0.5.1;

contract Store {
    uint n;
    
   function set(uint i) public {
       n =i;
   }
    
    function get() view public returns (uint) {
        return n;
    }
}