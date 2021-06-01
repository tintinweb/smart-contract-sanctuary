/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Balance
 * @dev Returns the balance at a given address
 */
contract Balance {
    function getBalance(address _a) public view returns (uint) {
        return _a.balance;
    }    
}