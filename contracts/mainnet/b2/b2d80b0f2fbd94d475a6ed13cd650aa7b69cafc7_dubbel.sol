pragma solidity ^0.4.20;

contract dubbel {
    address public previousSender;
    uint public price = 0.001 ether;
    
    function() public payable {
            require(msg.value == price);
            previousSender.transfer(msg.value);
            price *= 2;
            previousSender = msg.sender;
    }
}