/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Splitter {
  address payable public owner = msg.sender;

  function redeem() public {
      owner.transfer(address(this).balance);
  }

  function split(address[] calldata addresses, uint256[] calldata amounts) public {
    uint256 n = addresses.length;
    for (uint i=0; i<n; i++) {
        payable(addresses[i]).transfer(amounts[i]);
    }
  }
}