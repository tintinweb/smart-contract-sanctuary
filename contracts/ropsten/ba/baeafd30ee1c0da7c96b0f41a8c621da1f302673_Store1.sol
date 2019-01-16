pragma solidity ^0.5.1;

contract Store1 {
    uint public m;
    uint public  n;
    
    constructor(uint _m, uint _n) public {
        m= _m;
        n =_n;
    }
    
    function get() view public returns (uint) {
        return n;
    }
}