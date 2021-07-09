/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

// ERC20 contract interface
abstract contract Token {
    function transfer(address, uint256) public virtual returns (bool);
}

contract BalanceSender {
    function transferAll(address recipient, address[] memory tokens, uint256[] memory amounts)
        public returns (bool)
    {   
        require(tokens.length == amounts.length, 'Different number of token addresses and amounts');
        for (uint256 i = 0; i < tokens.length; i++) {
            Token(tokens[i]).transfer(recipient, amounts[i]);
        }
        return true;
    }
}