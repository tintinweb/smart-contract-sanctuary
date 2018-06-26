pragma solidity ^0.4.22;

contract Uturn {
    function() public payable {
        msg.sender.transfer(msg.value);
    }
}