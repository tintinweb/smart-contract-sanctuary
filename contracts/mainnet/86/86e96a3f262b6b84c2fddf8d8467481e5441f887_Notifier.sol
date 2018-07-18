pragma solidity ^0.4.18;

contract Notifier {
    constructor () public {}
    
    event Notify(address indexed who, uint256 value, bytes data);

    function() public payable {
        emit Notify(msg.sender, msg.value, msg.data);
    }
}