pragma solidity ^0.5.2;
contract SelfDestructor {
    
    function bye () public {
        selfdestruct(msg.sender);
    }
}