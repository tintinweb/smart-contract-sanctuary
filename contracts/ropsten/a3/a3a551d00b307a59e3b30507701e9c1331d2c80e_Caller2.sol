pragma solidity ^0.4.6;

contract Caller2 {
    uint public totalSupply;

    function someAction(address addr) returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(100);
        totalSupply = c.getValue(100);
    }
    
    function storeAction(address addr) returns(uint) {
        Callee c = Callee(addr);
        c.storeValue(100);
        return c.getValues();
    }
    
    function someUnsafeAction(address addr) {
        addr.call(bytes4(keccak256("storeValue(uint256)")), 100);
    }
}

   

contract Callee {
    function getValue(uint initialValue) returns(uint);
    function storeValue(uint value);
    function getValues() returns(uint);
}