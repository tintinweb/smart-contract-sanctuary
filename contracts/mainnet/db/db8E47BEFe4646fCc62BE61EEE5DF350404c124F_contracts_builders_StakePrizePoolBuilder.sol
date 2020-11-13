// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./PrizePoolBuilder.sol";
import "../registry/RegistryInterface.sol";
import "./SingleRandomWinnerBuilder.sol";
import "../prize-pool/stake/StakePrizePoolProxyFactory.sol";

/* solium-disable security/no-block-members */
contract StakePrizePoolBuilder is PrizePoolBuilder {
  using SafeMath for uint256;
  using SafeCast for uint256;

  struct StakePrizePoolConfig {
    IERC20 token;
    uint256 maxExitFeeMantissa;
    uint256 maxTimelockDuration;
  }

  RegistryInterface public reserveRegistry;
  StakePrizePoolProxyFactory public stakePrizePoolProxyFactory;
  SingleRandomWinnerBuilder public singleRandomWinnerBuilder;
  address public trustedForwarder;

  constructor (
    RegistryInterface _reserveRegistry,
    address _trustedForwarder,
    StakePrizePoolProxyFactory _stakePrizePoolProxyFactory,
    SingleRandomWinnerBuilder _singleRandomWinnerBuilder
  ) public {
    require(address(_reserveRegistry) != address(0), "StakePrizePoolBuilder/reserveRegistry-not-zero");
    require(address(_singleRandomWinnerBuilder) != address(0), "StakePrizePoolBuilder/single-random-winner-builder-not-zero");
    require(address(_stakePrizePoolProxyFactory) != address(0), "StakePrizePoolBuilder/stake-prize-pool-proxy-factory-not-zero");
    reserveRegistry = _reserveRegistry;
    singleRandomWinnerBuilder = _singleRandomWinnerBuilder;
    trustedForwarder = _trustedForwarder;
    stakePrizePoolProxyFactory = _stakePrizePoolProxyFactory;
  }

  function createSingleRandomWinner(
    StakePrizePoolConfig calldata prizePoolConfig,
    SingleRandomWinnerBuilder.SingleRandomWinnerConfig calldata prizeStrategyConfig,
    uint8 decimals
  ) external returns (StakePrizePool) {
    StakePrizePool prizePool = stakePrizePoolProxyFactory.create();

    SingleRandomWinner prizeStrategy = singleRandomWinnerBuilder.createSingleRandomWinner(
      prizePool,
      prizeStrategyConfig,
      decimals,
      msg.sender
    );

    address[] memory tokens;

    prizePool.initialize(
      trustedForwarder,
      reserveRegistry,
      tokens,
      prizePoolConfig.maxExitFeeMantissa,
      prizePoolConfig.maxTimelockDuration,
      prizePoolConfig.token
    );

    _setupSingleRandomWinner(
      prizePool,
      prizeStrategy,
      prizeStrategyConfig.ticketCreditRateMantissa,
      prizeStrategyConfig.ticketCreditLimitMantissa
    );

    prizePool.transferOwnership(msg.sender);

    emit PrizePoolCreated(msg.sender, address(prizePool));

    return prizePool;
  }

  function createStakePrizePool(
    StakePrizePoolConfig calldata config
  )
    external
    returns (StakePrizePool)
  {
    StakePrizePool prizePool = stakePrizePoolProxyFactory.create();

    address[] memory tokens;

    prizePool.initialize(
      trustedForwarder,
      reserveRegistry,
      tokens,
      config.maxExitFeeMantissa,
      config.maxTimelockDuration,
      config.token
    );

    prizePool.transferOwnership(msg.sender);

    emit PrizePoolCreated(msg.sender, address(prizePool));

    return prizePool;
  }
}
