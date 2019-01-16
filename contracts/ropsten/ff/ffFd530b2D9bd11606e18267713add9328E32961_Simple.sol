pragma solidity ^0.5.1;

contract Simple {
    uint public  n;
    
    function set(uint _n) public returns (uint) {
        n = _n;
    }

    function get() public view  returns (uint) {
        return n;
    }
}