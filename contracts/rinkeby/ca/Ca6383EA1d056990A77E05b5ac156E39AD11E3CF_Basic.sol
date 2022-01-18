pragma solidity ^0.8.0;

contract Basic {
    uint256 public count = 0;
    function incrementCounter() public {
        count += 1;
    }
}