/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.2;

contract Value {
    uint8 hasValue;

    constructor(uint8 giveNumber) public {
        hasValue = giveNumber;
    }

    function get() public view returns (uint8) {
        return hasValue;
    }
}