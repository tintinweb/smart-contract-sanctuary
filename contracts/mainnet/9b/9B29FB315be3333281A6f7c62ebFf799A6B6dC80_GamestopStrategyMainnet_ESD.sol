pragma solidity 0.5.16;

import "../snx-base/interfaces/SNXRewardInterface.sol";
import "../snx-base/SNXRewardStrategy.sol";

contract GamestopStrategyMainnet_ESD is SNXRewardStrategy {

  address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public esd = address(0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723);
  address public gme = address(0x9eb6bE354d88fD88795a04DE899a57A77C545590);
  address public gamestopRewardPool = address(0x466837EDC9411D8ea334e62AdBd1E9d18fBdb5d4);
  address public constant uniswapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardStrategy(_storage, esd, _vault, gme, uniswapRouterAddress)
  public {
    rewardPool = SNXRewardInterface(gamestopRewardPool);
    liquidationPath = [gme, weth, esd];
  }
}