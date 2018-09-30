pragma solidity ^0.4.24;

contract test {
    event INFO(address);
    function info() public {
        emit INFO(msg.sender);
    }
}