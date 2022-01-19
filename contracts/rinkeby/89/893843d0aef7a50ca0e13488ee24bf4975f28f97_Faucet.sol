/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {
  function withdraw(uint _amount) public {
    require(_amount <= 0.1 * 10 ** 18);
    payable(msg.sender).transfer(_amount);
  }

  receive() external payable {
  }
}