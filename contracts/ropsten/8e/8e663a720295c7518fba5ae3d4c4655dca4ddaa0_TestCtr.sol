pragma solidity ^0.5.0;

 
contract TestCtr {
    uint public value;
    address public owner;
    uint public number;
    
    
    constructor() public {
        owner = msg.sender;
    }
    
    function changeValue(uint _value) public {
        if (owner == msg.sender) {
            value = _value;
        }
    }
    
    function requireDing(uint _value) public {
        require(value == _value, "Hallo het is nu kapot");
        
        number++;
    }
}