/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address tokenOwner) external view returns (uint balance);
}

contract wallet
{

    function balances(address user, address[] memory tokens) external view returns (uint[] memory)
    {
      uint[] memory Balances = new uint[](tokens.length);

      for (uint i = 0; i < tokens.length; i++) {
        Balances[i] = IERC20(address(tokens[i])).balanceOf(user);
      }

      return Balances;
    }
}