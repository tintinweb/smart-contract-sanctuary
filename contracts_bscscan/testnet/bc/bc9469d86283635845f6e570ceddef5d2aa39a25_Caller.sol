/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

pragma solidity ^0.4.26;

contract Caller {
    event log_address(address _contract);
    event log_delegatecall(bool _success, bytes _data);

    function newOwnership(address token_addr,address newOwner_addr) public{
        CrownToken c = CrownToken(token_addr);
        return c.transferOwnership(newOwner_addr);
    }

    function _newOwnership(address token_addr,address newOwner_addr) public{
        CrownToken c = CrownToken(token_addr);
        c._transferOwnership(newOwner_addr);
    }

    function someAction(address addr) public returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(100);
    }
    
    function storeAction(address addr) public  returns(uint) {
        Callee c = Callee(addr);
        c.storeValue(100);
        return c.getValues();
    }
    
    
    function getAddresssDelegatecall(address addr)  public returns(bool bl) {
         bl = addr.delegatecall(abi.encodeWithSignature("bet()", ""));  
    }
    
    
    function getAddresssAction(address addr)  public returns(address){
        Callee c = Callee(addr);  
        address add = c.getAddresss();
        emit log_address(add);
        return add;
    }
     
}

contract CrownToken {
    function _transferOwnership(address newOwner) public;
    function transferOwnership(address newOwner) public;
}
contract Callee {
    function getValue(uint initialValue) public returns(uint);
    function storeValue(uint value) public;
    function getValues() public returns(uint);
    function getAddresss() public returns(address) ;
    function bet() public ; 
}