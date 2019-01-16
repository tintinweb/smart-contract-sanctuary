pragma solidity ^0.4.25;

// Updated for compiler compatibility.
contract AmIOnTheFork {
    function forked() public constant returns(bool);
}

contract ForkSweeper {
    bool public isForked;
    
    constructor() public {
      isForked = true;
    }
    
    function redirect(address ethAddress, address etcAddress) public payable {
        if (isForked) {
            ethAddress.transfer(msg.value);
            
            return;
        }
        
        etcAddress.transfer(msg.value);
            
        return;
    }
}