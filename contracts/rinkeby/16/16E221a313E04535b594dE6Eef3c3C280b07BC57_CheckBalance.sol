/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CheckBalance {

    function getBalance(address d) external view returns (uint256) {
        return d.balance;
    }
}