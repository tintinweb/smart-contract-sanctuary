/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;



// File: ForceTransfer.sol

contract ForceTransfer {
  address public heritageAddress;

  constructor(address _heritageAddress) {
    heritageAddress = _heritageAddress;
  }

  function setHeritage(address _addr) public {
    heritageAddress = _addr;
  }

  function selfDestruct() public {
    selfdestruct(payable(heritageAddress));
  }

  receive() external payable {}

  fallback() external payable {}
}