// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <=0.8.11;

contract Counter {
    uint256 public counter;

    event incremented();

    function increment() public {
        counter++;
        emit incremented();
    }

    // Just using this to make sure you've correctly handled reverts!
    function fail() public pure {
        revert("This function should fail");
    }
}