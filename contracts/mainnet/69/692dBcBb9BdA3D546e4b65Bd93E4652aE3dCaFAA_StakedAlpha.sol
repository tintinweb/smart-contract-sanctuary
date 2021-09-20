/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.7;



// Part: IStaking

interface IStaking {
  function users(address)
    external
    view
    returns (
      uint,
      uint,
      uint,
      uint
    );
}

// File: StakedAlpha.sol

contract StakedAlpha {
  IStaking public constant staking = IStaking(0x2aA297c3208bD98a9a477514d3C80ace570A6deE);
  string public constant name = 'Staked Alpha';
  string public constant symbol = 'sALPHA';
  uint8 public constant decimals = 18;

  function balanceOf(address _user) external view returns (uint) {
    (, uint share, , ) = staking.users(_user);
    return share;
  }
}