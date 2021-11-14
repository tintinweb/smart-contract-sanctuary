/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.0;

contract Incrementer {
    uint256 public number = 18;

    constructor() {
    }

    function increment(uint256 _value) public {
        number = number + _value;
    }

    function reset() public {
        number = 0;
    }
}