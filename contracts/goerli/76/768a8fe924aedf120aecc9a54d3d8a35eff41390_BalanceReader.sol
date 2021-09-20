/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

/**
 *Submitted for verification at Etherscan.io on 2018-09-19
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.4.25;

// Ethfinex 2018

contract ERC20Interface {
    function balanceOf(address who) public view returns (uint256);
}

contract BalanceReader {
    function allBalances(address[] _tokens, address _who) public view returns (uint256[] balances) {
        balances = new uint256[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            balances[i] = ERC20Interface(_tokens[i]).balanceOf(_who);
        }
    }
}