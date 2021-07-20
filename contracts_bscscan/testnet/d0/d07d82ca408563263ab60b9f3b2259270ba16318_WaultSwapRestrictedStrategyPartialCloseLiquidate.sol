// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.6;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./Ownable.sol";

import "./IWaultSwapFactory.sol";
import "./IPancakePair.sol";

import "./IWaultSwapRouter02.sol";
import "./IStrategy.sol";
import "./IWETH.sol";
import "./IWNativeRelayer.sol";
import "./SafeToken.sol";
import "./IWorker.sol";

contract WaultSwapRestrictedStrategyPartialCloseLiquidate is OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe, IStrategy {
  using SafeToken for address;

  IWaultSwapFactory public factory;
  IWaultSwapRouter02 public router;

  mapping(address => bool) public okWorkers;

  event WaultSwapRestrictedStrategyPartialCloseLiquidateEvent(
    address indexed baseToken,
    address indexed farmToken,
    uint256 amounToLiquidate
  );

  // @notice require that only allowed workers are able to do the rest of the method call
  modifier onlyWhitelistedWorkers() {
    require(
      okWorkers[msg.sender],
      "WaultSwapRestrictedStrategyPartialCloseLiquidate::onlyWhitelistedWorkers:: bad worker"
    );
    _;
  }

  /// @dev Create a new liquidate strategy instance.
  /// @param _router The Uniswap router smart contract.
  function initialize(IWaultSwapRouter02 _router) public initializer {
    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
    factory = IWaultSwapFactory(_router.factory());
    router = _router;
  }

  /// @dev Execute worker strategy. Take LP token. Return  BaseToken.
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address, /* user */
    uint256, /* debt */
    bytes calldata data
  ) external override onlyWhitelistedWorkers nonReentrant {
    // 1. Find out what farming token we are dealing with.
    (uint256 lpTokenToLiquidate, uint256 minBaseToken) = abi.decode(data, (uint256, uint256));
    IWorker worker = IWorker(msg.sender);
    address baseToken = worker.baseToken();
    address farmingToken = worker.farmingToken();
    IPancakePair lpToken = IPancakePair(factory.getPair(farmingToken, baseToken));
    // 2. Approve router to do their stuffs
    address(lpToken).safeApprove(address(router), uint256(-1));
    farmingToken.safeApprove(address(router), uint256(-1));
    // 3. Remove some LP back to BaseToken and farming tokens as we want to return some of the position.
    require(
      lpToken.balanceOf(address(this)) >= lpTokenToLiquidate,
      "WaultSwapRestrictedStrategyPartialCloseLiquidate::execute:: insufficient LP amount recevied from worker"
    );
    router.removeLiquidity(baseToken, farmingToken, lpTokenToLiquidate, 0, 0, address(this), now);
    // 4. Convert farming tokens to baseToken.
    address[] memory path = new address[](2);
    path[0] = farmingToken;
    path[1] = baseToken;
    router.swapExactTokensForTokens(farmingToken.myBalance(), 0, path, address(this), now);
    // 5. Return all baseToken back to the original caller.
    uint256 balance = baseToken.myBalance();
    require(
      balance >= minBaseToken,
      "WaultSwapRestrictedStrategyPartialCloseLiquidate::execute:: insufficient baseToken received"
    );
    SafeToken.safeTransfer(baseToken, msg.sender, balance);
    lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    // 6. Reset approve for safety reason
    address(lpToken).safeApprove(address(router), 0);
    farmingToken.safeApprove(address(router), 0);

    emit WaultSwapRestrictedStrategyPartialCloseLiquidateEvent(baseToken, farmingToken, lpTokenToLiquidate);
  }

  function setWorkersOk(address[] calldata workers, bool isOk) external onlyOwner {
    for (uint256 idx = 0; idx < workers.length; idx++) {
      okWorkers[workers[idx]] = isOk;
    }
  }
}