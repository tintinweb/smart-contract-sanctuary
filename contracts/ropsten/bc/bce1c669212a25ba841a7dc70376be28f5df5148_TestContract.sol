pragma solidity ^0.5.0;
 
contract TestContract {
    uint value;
    function testContract(uint _p) public {
        value = _p;
    }
 
    function set (uint _n) public {
        value = _n;
    }
 
    function get () view public returns (uint) {
        return value;
    }
}