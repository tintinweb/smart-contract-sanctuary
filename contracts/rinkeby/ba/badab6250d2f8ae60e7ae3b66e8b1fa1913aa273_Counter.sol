/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.8.10;

contract Counter {
    uint256 public value;

    function increase(uint256 amount) public {
        value += amount;
    }

}