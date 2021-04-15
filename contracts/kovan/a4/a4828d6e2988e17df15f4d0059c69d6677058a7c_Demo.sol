/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: WTFPL

contract Demo {
    uint256[] public numbers;
    
    function append(uint256 num) public {
        numbers[numbers.length] = num;
    }
}