pragma solidity 0.5.16;

import "../sushi-base/MasterChefStrategy.sol";

contract SushiStrategyMainnet_SUSHI_WETH is MasterChefStrategy {

  address public sushi_weth_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x795065dCc9f64b5614C407a6EFDC400DA6221FB0);
    address sushi = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    MasterChefStrategy.initializeStrategy(
      _storage,
      underlying,
      _vault,
      address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd), // master chef contract
      sushi,
      12,  // Pool id
      true, // is LP asset
      false // false = use Sushiswap for liquidating
    );
    // sushi is token0, weth is token1
    uniswapRoutes[sushi] = [sushi];
    uniswapRoutes[weth] = [sushi, weth];
  }
}