pragma solidity ^0.4.6;

contract Test {
    uint number;
    
    constructor(uint _number) public {
        number = _number;
    }
    
    function setNumber(uint _number) public {
        number = _number;
    }
    
    function getNumber() public view returns(uint) {
        return number;
    }
    
    function sendVal() public payable {
        address(this).send(msg.value);
    }
    
    function getVal() public view returns(uint) {
        return this.balance;
    }
    
    function end() public {
        selfdestruct(address(this));
    }
    
}