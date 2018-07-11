pragma solidity ^0.4.24;

contract Test {
    event testLog(address indexed account, uint amount);
    
    constructor() public {
        emit testLog(msg.sender, block.number);
    }
    
    function execute(uint number) public returns (bool) {
        emit testLog(msg.sender, number);
        return true;
    }
}