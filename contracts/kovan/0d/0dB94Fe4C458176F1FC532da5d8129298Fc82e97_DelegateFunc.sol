/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.8.5;

contract DelegateFunc {
    uint256 public calculateResult;
    address public callingUser;
    uint256 public functionCallingCount;

    constructor() {
        functionCallingCount = 0;
    }

    function add(uint256 a, uint256 b) public returns (uint256) {
        calculateResult = a + b;
        callingUser = msg.sender;
        return calculateResult;
    }
}