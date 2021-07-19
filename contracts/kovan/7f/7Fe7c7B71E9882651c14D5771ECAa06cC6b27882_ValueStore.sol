/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ValueStore {
    event ValueChanged(uint256 identifier, uint256 oldValue, uint256 newValue);

    mapping (address => mapping (address => uint)) public allowance;

    function approve(address holder, address spender, uint256 newValue) public {
        uint256 oldValue = allowance[holder][spender];
        allowance[holder][spender] = newValue;
        emit ValueChanged(1, oldValue, allowance[holder][spender]);
    }
}