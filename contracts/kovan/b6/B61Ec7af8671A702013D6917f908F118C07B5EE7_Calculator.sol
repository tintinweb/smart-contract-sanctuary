// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.3;

contract Calculator {
    uint256 public calculateResult;
    address public user;
    uint256 public calculatorAddCount;
    
    event Add(uint256 a, uint256 b, address txOrigin, address msgSenderAddress, address _this);
    
    constructor(address _user, uint256 _result) {
        user = _user;
        calculateResult = _result;
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

