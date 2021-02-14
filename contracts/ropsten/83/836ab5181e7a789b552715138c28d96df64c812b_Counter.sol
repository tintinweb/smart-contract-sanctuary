/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

pragma solidity 0.6.1;

contract Counter {
    uint256 public value;
    function increment(uint256 amount) public {
        value += amount; // - Warning!
    }
}