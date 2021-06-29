/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.7.3;

contract Calculator {
    uint256 public calculateResult;
    address public user;
    uint256 public calculatorAddCount;
    
    event Add(uint256 a, uint256 b, address txOrigin, address msgSenderAddress, address _this);
    
    constructor() {
        calculatorAddCount = 0;
    }

    function add(uint256 a, uint256 b) public returns (uint256) {
        calculatorAddCount++;

        calculateResult = a + b;
        assert(calculateResult >= a);
        
        emit Add(a, b, tx.origin, msg.sender, address(this));
        user = msg.sender;
        
        return calculateResult;
    }
}