/**
 *Submitted for verification at polygonscan.com on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


contract GEMS {
  mapping(address => uint256) public gems;
}



contract GemsBalance {

  address public constant gemsAddress = 0x756218A9476bF7C75a887d9c7aB916DE15AB5Ddf;
    

  function balanceOf(address account) public view returns (uint256) {
    return GEMS(gemsAddress).gems(account);
  }
  
}