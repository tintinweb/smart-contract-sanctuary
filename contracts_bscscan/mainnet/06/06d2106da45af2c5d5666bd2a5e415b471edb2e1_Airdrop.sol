/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.4.26;

contract ERC20 {
  function transfer(address _recipient, uint256 _value) public returns (bool success);
}

contract Airdrop {
  function drop(ERC20 token, address[] recipients, uint256[] values) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transfer(recipients[i], values[i]);
    }
  }
}