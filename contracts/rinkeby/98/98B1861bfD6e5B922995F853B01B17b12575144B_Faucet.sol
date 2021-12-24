/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {
  
  function withdraw(uint _amount) public {
    // users can only withdraw .1 ETH (i.e. 10^17 wei) at a time, feel free to change this!
    require(_amount <= 100000000000000000);
    payable(msg.sender).transfer(_amount);  // payable inside the function?
  }

  // fallback function
  // this function is for depositing ether, adds to the contract balance
  receive() external payable {}
}