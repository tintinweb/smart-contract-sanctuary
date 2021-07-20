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
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";

import "./IPancakeRouter02.sol";
import "./IStrategy.sol";
import "./IWETH.sol";
import "./IWNativeRelayer.sol";
import "./SafeToken.sol";
import "./IWorker.sol";

contract PancakeswapV2RestrictedStrategyPartialCloseMinimizeTrading is
  OwnableUpgradeSafe,
  ReentrancyGuardUpgradeSafe,
  IStrategy
{
  using SafeToken for address;
  using SafeMath for uint256;

  IPancakeFactory public factory;
  IPancakeRouter02 public router;
  IWETH public wbnb;
  IWNativeRelayer public wNativeRelayer;

  mapping(address => bool) public okWorkers;

  event PancakeswapV2RestrictedStrategyPartialCloseMinimizeTradingEvent(
    address indexed baseToken,
    address indexed farmToken,
    uint256 amounToLiquidate,
    uint256 amountToRepayDebt
  );

  // @notice require that only allowed workers are able to do the rest of the method call
  modifier onlyWhitelistedWorkers() {
    require(
      okWorkers[msg.sender],
      "PancakeswapV2RestrictedStrategyPartialCloseMinimizeTrading::onlyWhitelistedWorkers:: bad worker"
    );
    _;
  }

  /// @dev Create a new withdraw minimize trading strategy instance.
  /// @param _router The Uniswap router smart contract.
  /// @param _wbnb The wrapped BNB token.
  /// @param _wNativeRelayer The relayer to support native transfer
  function initialize(
    IPancakeRouter02 _router,
    IWETH _wbnb,
    IWNativeRelayer _wNativeRelayer
  ) external initializer {
    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
    factory = IPancakeFactory(_router.factory());
    router = _router;
    wbnb = _wbnb;
    wNativeRelayer = _wNativeRelayer;
  }

  /// @dev Execute worker strategy. Take LP tokens. Return farming token + base token.
  /// However, some base token will be deducted to pay the debt
  /// @param user User address to withdraw liquidity.
  /// @param debt Debt amount in WAD of the user.
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address user,
    uint256 debt,
    bytes calldata data
  ) external override onlyWhitelistedWorkers nonReentrant {
    // 1. Find out what farming token we are dealing with.
    (uint256 lpTokenToLiquidate, uint256 toRepaidBaseTokenDebt, uint256 minFarmingToken) =
      abi.decode(data, (uint256, uint256, uint256));
    IWorker worker = IWorker(msg.sender);
    address baseToken = worker.baseToken();
    address farmingToken = worker.farmingToken();
    IPancakePair lpToken = IPancakePair(factory.getPair(farmingToken, baseToken));
    // 2. Approve router to do their stuffs
    address(lpToken).safeApprove(address(router), uint256(-1));
    farmingToken.safeApprove(address(router), uint256(-1));
    // 3. Remove all liquidity back to base token and farming token.
    require(
      lpToken.balanceOf(address(this)) >= lpTokenToLiquidate,
      "PancakeswapV2RestrictedStrategyPartialCloseMinimizeTrading::execute:: insufficient LP amount recevied from worker"
    );
    router.removeLiquidity(baseToken, farmingToken, lpTokenToLiquidate, 0, 0, address(this), now);
    // 4. Convert farming tokens to base token.
    require(
      debt >= toRepaidBaseTokenDebt,
      "PancakeswapV2RestrictedStrategyPartialCloseMinimizeTrading::execute:: amount to repay debt is greater than debt"
    );
    address[] memory path = new address[](2);
    path[0] = farmingToken;
    path[1] = baseToken;
    {
      uint256 balance = baseToken.myBalance();
      uint256 farmingTokenbalance = farmingToken.myBalance();
      if (toRepaidBaseTokenDebt > balance) {
        // Convert some farming tokens to base token.
        uint256 remainingDebt = toRepaidBaseTokenDebt.sub(balance);
        uint256[] memory farmingTokenToBeRepaidDebts = router.getAmountsIn(remainingDebt, path);
        require(
          farmingTokenbalance >= farmingTokenToBeRepaidDebts[0],
          "PancakeswapV2RestrictedStrategyPartialCloseMinimizeTrading::execute:: not enough to pay back debt"
        );
        router.swapTokensForExactTokens(remainingDebt, farmingTokenbalance, path, address(this), now);
      }
    }
    // 5. Return remaining LP token back to the original caller
    address(lpToken).safeTransfer(msg.sender, lpToken.balanceOf(address(this)));
    // 6. Return base token back to the original caller.
    baseToken.safeTransfer(msg.sender, baseToken.myBalance());
    // 7. Return remaining farming tokens to user.
    uint256 remainingFarmingToken = farmingToken.myBalance();
    require(
      remainingFarmingToken >= minFarmingToken,
      "PancakeswapV2RestrictedStrategyPartialCloseMinimizeTrading::execute:: insufficient farming tokens received"
    );
    if (remainingFarmingToken > 0) {
      if (farmingToken == address(wbnb)) {
        SafeToken.safeTransfer(farmingToken, address(wNativeRelayer), remainingFarmingToken);
        wNativeRelayer.withdraw(remainingFarmingToken);
        SafeToken.safeTransferETH(user, remainingFarmingToken);
      } else {
        SafeToken.safeTransfer(farmingToken, user, remainingFarmingToken);
      }
    }
    // 8. Reset approval for safety reason
    address(lpToken).safeApprove(address(router), 0);
    farmingToken.safeApprove(address(router), 0);

    emit PancakeswapV2RestrictedStrategyPartialCloseMinimizeTradingEvent(
      baseToken,
      farmingToken,
      lpTokenToLiquidate,
      toRepaidBaseTokenDebt
    );
  }

  function setWorkersOk(address[] calldata workers, bool isOk) external onlyOwner {
    for (uint256 idx = 0; idx < workers.length; idx++) {
      okWorkers[workers[idx]] = isOk;
    }
  }

  receive() external payable {}
}