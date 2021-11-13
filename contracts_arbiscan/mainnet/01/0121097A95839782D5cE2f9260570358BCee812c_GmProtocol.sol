// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev protocol designed to say gm.        yes. that's it. 
/// author: gajesh naik (twitter: robogajesh)

contract GmProtocol {
  mapping (address => uint256) public gmCount;

  function gm() public returns (string memory) {
    gmCount[msg.sender] = gmCount[msg.sender] + 1;
    if (gmCount[msg.sender] == 1) {
      return "gm. welcome to the gm club. lfg";
    } else if (gmCount[msg.sender] > 1 && gmCount[msg.sender] <= 5) {
      return "gm.";
    } else if (gmCount[msg.sender] >= 6 && gmCount[msg.sender] <= 10) {
      return "gm. homie";
    } else {
      return "gm. degen.";
    }
  }
}