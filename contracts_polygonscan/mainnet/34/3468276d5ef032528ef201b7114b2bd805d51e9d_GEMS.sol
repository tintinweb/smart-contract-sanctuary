/**
 *Submitted for verification at polygonscan.com on 2021-09-23
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;


/** Contract giving user GEMS*/

// Inspired by https://github.com/andrecronje/rarity/blob/main/rarity.sol

/** @title GEMS */
contract GEMS  {
  uint256 constant gems_per_day = 250e18;
  mapping(address => uint256) public gems;


  // Say gm and get gems by performing an action in LongShort or Staker
  function gm() external {
        gems[msg.sender] += gems_per_day;
}

      /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return gems[account];
    }
    
}