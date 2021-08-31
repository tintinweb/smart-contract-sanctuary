/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title rat
 * @dev store & retrieve value in a variable
 */
contract getBalance {
    function balance(address owner) public view returns(uint accountBalance) {
        accountBalance = owner.balance;
    }
}