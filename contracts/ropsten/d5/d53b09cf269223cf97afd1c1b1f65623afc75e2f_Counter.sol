pragma solidity ^0.4.24;

contract Counter {
    uint256 public counter;
    
    constructor() public {
        counter = 0;
    }
    
    event CounterFunc(address addr, uint256 indexed _couter);
    
    function add() public {
        counter++;
        
        emit CounterFunc(msg.sender, counter);
    }
}