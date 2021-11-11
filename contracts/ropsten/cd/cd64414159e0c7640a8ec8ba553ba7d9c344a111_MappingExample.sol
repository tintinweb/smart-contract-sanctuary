/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

pragma solidity ^0.4.0;

contract MappingExample {
    mapping(address => uint) public balances;
    address public  adr = address(this);
    
    function getAddr() public view  returns(address){
        return adr;
    }
    
    function update(uint newBalance) public {
        balances[msg.sender] = newBalance;
    }
}
    
contract Mappinguser {
    address public adr1 = address(this);
    function f() public returns(uint) {
        MappingExample m = new MappingExample();
        m.update(100);
        return m.balances(this);
    }
    function f1() public returns(address) {
        MappingExample m = new MappingExample();
        m.update(100);
        return m.getAddr();
    }
    
    
}