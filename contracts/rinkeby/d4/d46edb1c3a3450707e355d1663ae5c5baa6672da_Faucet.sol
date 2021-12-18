/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Faucet {

  function withdraw(uint amount) public {
    require(amount < 1 * 10^17);
    payable(msg.sender).transfer(amount);
  }
  fallback() external payable {}
}