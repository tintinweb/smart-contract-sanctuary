pragma solidity ^0.4.20;

 
contract TestCtr {
    string public name;
    address public owner;
    
    
    constructor() public {
        owner = msg.sender;
    }
    
    function changeName(string name2) public {
        if (owner == msg.sender) {
            name = name2;
        }
    }
}