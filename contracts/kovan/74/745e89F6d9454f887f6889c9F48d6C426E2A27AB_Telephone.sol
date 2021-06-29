/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.4;





contract Telephone {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}