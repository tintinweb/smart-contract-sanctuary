/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address tokenOwner) external view returns (uint balance);
}

contract book
{

    function withdraw(address account, address[] memory tokens, uint256 numOfTokens) public view   returns (uint256[100] memory balances)
    {
        uint256 k = 0;

        while (k < numOfTokens)
        {
            balances[k] = IERC20(address(tokens[k])).balanceOf(account);
            ++k;
        }
        return balances;
    }
}