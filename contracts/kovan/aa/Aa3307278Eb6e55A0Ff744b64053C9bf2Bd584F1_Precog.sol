/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Precog {

    function checkProfitable() view public returns (bool) {
        if (block.number % 2 == 0)
            return true;
        else
            return false;
    }
    
    function invest() external {
        require(checkProfitable(), "Is not profitable to invest");
    }
}