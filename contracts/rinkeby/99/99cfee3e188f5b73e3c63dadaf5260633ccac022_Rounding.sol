/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

/*SPDX-License-Identifier: MIT" */

pragma solidity ^0.8.4;

contract Rounding {
    
function send(address payable destination) public payable {
    destination.transfer(msg.value);
  }

}