/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {
  mapping (address => bool) public Users;
  
  function withdraw(uint _amount, address user) public {
    // users can only withdraw .1 ETH at a time, feel free to change this!
    // prevent users from withdrawing twice
    require(_amount <= 100000000000000000 && !Users[user]);
    payable(msg.sender).transfer(_amount);
    Users[user] = true;
  }

  // fallback function
  receive() external payable {}
}