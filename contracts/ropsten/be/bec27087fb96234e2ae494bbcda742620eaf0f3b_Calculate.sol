pragma solidity ^0.4.24;

contract Calculate {
    
    constructor () public payable {
        // Deploy contract with 1000 wei for testing purpose
        require(msg.value == 1000);
    }
    
    function done() public {
        address(0).transfer(1); // Transaction success
    }
    
    function fail() public {
        address(1).transfer(1); // Transaction failed
    }
    
    function send(address account) public {
        account.transfer(1); // Transaction success (except 0x1)
    }
    
}