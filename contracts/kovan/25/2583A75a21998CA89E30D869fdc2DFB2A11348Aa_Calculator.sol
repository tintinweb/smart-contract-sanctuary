/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Calculator {
    uint256 public calculateResult;
    uint256 public addCount;

    event Add(address origin, address sender, address _this, uint256 a, uint256 b);
    
    function add(uint256 _a, uint256 _b) public returns (uint256) {
        calculateResult = _a + _b;
        addCount++;
        emit Add(tx.origin, msg.sender, address(this), _a, _b);
        return calculateResult;
    }
}