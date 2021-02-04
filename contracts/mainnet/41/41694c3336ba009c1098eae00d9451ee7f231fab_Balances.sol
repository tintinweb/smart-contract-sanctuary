/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Balances {
    function balancesOf(address[] calldata _addresses)
        external
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](_addresses.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            balances[i] = _addresses[i].balance;
        }
    }
}