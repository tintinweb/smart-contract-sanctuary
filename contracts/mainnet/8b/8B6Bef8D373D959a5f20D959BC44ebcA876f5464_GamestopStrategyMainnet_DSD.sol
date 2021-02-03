pragma solidity 0.5.16;

import "../snx-base/interfaces/SNXRewardInterface.sol";
import "../snx-base/SNXRewardStrategy.sol";

contract GamestopStrategyMainnet_DSD is SNXRewardStrategy {

  address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public dsd = address(0xBD2F0Cd039E0BFcf88901C98c0bFAc5ab27566e3);
  address public gme = address(0x9eb6bE354d88fD88795a04DE899a57A77C545590);
  address public gamestopRewardPool = address(0x056Be3ED7CF114AFd98F694cC21c7C70a644e1BA);
  address public constant uniswapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardStrategy(_storage, dsd, _vault, gme, uniswapRouterAddress)
  public {
    rewardPool = SNXRewardInterface(gamestopRewardPool);
    liquidationPath = [gme, weth, dsd];
  }
}