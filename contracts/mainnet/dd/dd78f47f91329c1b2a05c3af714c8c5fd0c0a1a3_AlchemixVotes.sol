//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import {UniswapV2Pair} from "./UniswapV2Pair.sol";

interface StakingPools {
  function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256);
}

contract AlchemixVotes {
  function getUnderlyingALCXTokens(address account) external view returns (uint256){
    UniswapV2Pair slp = UniswapV2Pair(0xC3f279090a47e80990Fe3a9c30d24Cb117EF91a8);
    StakingPools pools = StakingPools(0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa);
    uint256 alcxBalance = pools.getStakeTotalDeposited(account, 1);
    uint256 lpBalance = slp.balanceOf(account);
    lpBalance += pools.getStakeTotalDeposited(account, 2);
    (uint256 reserveETH, uint256 reserveALCX,) = slp.getReserves();
    uint256 alcxInSlp = (lpBalance * reserveALCX)/slp.totalSupply();
    alcxBalance += alcxInSlp;
    return alcxBalance;
  }
}