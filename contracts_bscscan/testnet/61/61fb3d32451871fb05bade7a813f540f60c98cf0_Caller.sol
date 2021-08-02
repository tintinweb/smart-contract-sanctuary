/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.4.11;

contract Caller {
    function someAction(address addr) returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(100);
    }
    
    function storeAction(address addr) returns(uint) {
        Callee c = Callee(addr);
        c.storeValue(100);
        return c.getValues();
    }
    
    function getAddresssAction(address addr) returns(address) {
        Callee c = Callee(addr);  
        return c.getAddresss();
    }
     
}

contract Callee {
    function getValue(uint initialValue) returns(uint);
    function storeValue(uint value);
    function getValues() returns(uint);
    function getAddresss() returns(address);
}