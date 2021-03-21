/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
  function redeem(uint256 _amount) external;
}

interface IBPool {
  function totalSupply() external view returns (uint);
  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
}

contract BPoolProposal {

  function execute() public {

    uint MAX_INT = 2**256 - 1;

    address proposer = 0x2Cb037BD6B7Fbd78f04756C99B7996F430c58172;
    address gov      = 0x3157439C84260541003001129c42FB6aBa57E758;

    IERC20 adai   = IERC20(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d);
    IERC20 dai    = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 build  = IERC20(0x6e36556B3ee5Aa28Def2a8EC3DAe30eC2B208739);
    IERC20 metric = IERC20(0xEfc1C73A3D8728Dc4Cf2A18ac5705FE93E5914AC);

    IBPool pool = IBPool(0x4d87920D35Cd288D9D2E8f311FF4DE814225987D);
    uint reward = 1000e18;

    adai.redeem(adai.balanceOf(address(this)));
    dai.transfer(proposer, reward);

    build.approve(address(pool), MAX_INT);
    metric.approve(address(pool), MAX_INT);
    dai.approve(address(pool), MAX_INT);

    uint daiPool   = dai.balanceOf(address(pool));
    uint daiGov    = dai.balanceOf(address(this));
    uint poolShare = (pool.totalSupply() * daiGov / daiPool) - pool.totalSupply();

    uint[] memory amounts = new uint[](3);
    amounts[0] = MAX_INT;
    amounts[1] = MAX_INT;
    amounts[2] = MAX_INT;

    pool.joinPool(poolShare, amounts);
  }
}