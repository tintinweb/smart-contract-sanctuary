pragma solidity ^0.5.1;

contract Storage {
    uint n;
    
    constructor(uint _n) public {
        n =_n;
    }
    
   function set(uint i) public {
       n =i;
   }
    
    function get() view public returns (uint) {
        return n;
    }
}