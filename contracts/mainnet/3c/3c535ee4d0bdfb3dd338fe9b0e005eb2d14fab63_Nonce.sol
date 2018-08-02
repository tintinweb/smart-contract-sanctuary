pragma solidity ^0.4.24;

contract Nonce {
    event IncrementEvent(address indexed _sender, uint256 indexed _newNonce);
    uint256 value;
    
    function increment() public returns (uint256) {
        value = ++value;
        emit IncrementEvent(msg.sender, value);
        return value;
    }
    
    function getValue() public view returns (uint256) {
        return value;
    }
}