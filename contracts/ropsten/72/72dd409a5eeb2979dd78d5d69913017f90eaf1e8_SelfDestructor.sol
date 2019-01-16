pragma solidity ^0.5.2;
contract SelfDestructor {
    address payable public owner;
    bool public greeting = false;
    
    constructor () public {
        owner = msg.sender;
    }
    
    function hi () public {
        greeting = true;
    }
    
    function bye () public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}