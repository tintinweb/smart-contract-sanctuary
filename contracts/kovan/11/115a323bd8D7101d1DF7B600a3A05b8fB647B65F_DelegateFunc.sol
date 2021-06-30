/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity ^0.8.5;

contract DelegateFunc {
    uint256 public calculateResult;
    address public callingUser;
    uint256 public functionCallingCount;

    event delegate_valueChanged(address message_sender, uint256 calcResult, address indexed callUser, uint256 functionResult);

    constructor() {
        functionCallingCount = 0;
    }

    function add(uint256 a, uint256 b) public returns (uint256) {
        calculateResult = a + b;
        callingUser = msg.sender;
        functionCallingCount +=  1;
        emit delegate_valueChanged(msg.sender, calculateResult, callingUser, functionCallingCount);
        return calculateResult;
    }
}