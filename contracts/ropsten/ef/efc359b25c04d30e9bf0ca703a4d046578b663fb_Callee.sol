pragma solidity ^0.4.23;

contract Callee {
    
    uint public counter;
    address public caller;
    
    function increment(uint amount) public {
        caller = msg.sender;
        counter += amount;
    }
    
}

contract Caller {
    
    address public callee;
    
    constructor(address _callee) public {
        callee = _callee;
    }
    
    function increment(uint amount) public {
        Callee(callee).increment(amount);
    }
    
}