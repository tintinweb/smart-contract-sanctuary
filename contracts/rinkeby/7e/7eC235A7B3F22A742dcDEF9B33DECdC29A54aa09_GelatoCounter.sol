pragma solidity ^0.8.9;

contract GelatoCounter{
    uint256 public counter;

    function increment() external {
        counter++;
    }
}