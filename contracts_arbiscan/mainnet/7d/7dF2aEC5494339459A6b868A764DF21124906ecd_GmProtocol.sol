// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev protocol designed to say gm.        yes. that's it. 
/// author: gajesh naik (twitter: robogajesh)

contract GmProtocol {
  mapping (address => uint256) public gmCount;

  function gm() external {
    gmCount[msg.sender] = gmCount[msg.sender] + 1;
  }

  function sayGm(address _address) public view returns (string memory) {
    if (gmCount[_address] == 1) {
      return "gm. welcome to the gm club. lfg";
    } else if (gmCount[_address] > 1 && gmCount[_address] <= 5) {
      return "gm.";
    } else if (gmCount[_address] >= 6 && gmCount[_address] <= 10) {
      return "gm. homie";
    } else {
      return "gm. degen.";
    }
  }
}