/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

pragma solidity 0.7.4;

contract Counter {
    uint256 public value;
    function odometr_update(uint256 amount) public {
    value += amount;
    }
}