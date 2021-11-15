/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Multisender {
  function multisend(address tokenAddress, address payable[] memory targets, uint[] memory values) public {
    require(targets.length == values.length, "targets size not equal to values");

    IERC20 token = IERC20(tokenAddress);

    for (uint i = 0; i < targets.length; i++) {
      bool ok = token.transfer(targets[i], values[i]);
      require(ok, 'transaction failed');
    }
  }
}