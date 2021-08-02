/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.4.11;

contract Caller {
    event log_address(address _contract);
    function someAction(address addr) public returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(100);
    }
    
    function storeAction(address addr) public  returns(uint) {
        Callee c = Callee(addr);
        c.storeValue(100);
        return c.getValues();
    }
    
    function getAddresssAction(address addr)  public returns(address){
        Callee c = Callee(addr);  
        address add = c.getAddresss();
        emit log_address(add);
        return add;
    }
     
}

contract Callee {
    function getValue(uint initialValue) public returns(uint);
    function storeValue(uint value) public;
    function getValues() public returns(uint);
    function getAddresss() public returns(address) ;
}