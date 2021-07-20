// SPDX-License-Identifier: BUSL-1.1
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
import "./SafeToken.sol";
import "./AlpacaMath.sol";
import "./IWorker02.sol";
import "./IWNativeRelayer.sol";

contract PancakeswapV2RestrictedSingleAssetStrategyPartialCloseWithdrawMinimizeTrading is
  OwnableUpgradeSafe,
  ReentrancyGuardUpgradeSafe,
  IStrategy
{
  using SafeToken for address;
  using SafeMath for uint256;

  IPancakeFactory public factory;
  IPancakeRouter02 public router;
  address public wbnb;
  mapping(address => bool) public okWorkers;
  IWNativeRelayer public wNativeRelayer;

  event PancakeswapV2RestrictedSingleAssetStrategyPartialCloseWithdrawMinimizeTradingEvent(
    address indexed baseToken,
    address indexed farmToken,
    uint256 amounToLiquidate,
    uint256 amountToRepayDebt
  );

  /// @notice require that only allowed workers are able to do the rest of the method call
  modifier onlyWhitelistedWorkers() {
    require(
      okWorkers[msg.sender],
      "PancakeswapV2RestrictedSingleAssetStrategyPartialCloseWithdrawMinimizeTrading::onlyWhitelistedWorkers:: bad worker"
    );
    _;
  }

  /// @dev Create a new add Token only strategy instance.
  /// @param _router The Pancakeswap router smart contract.
  function initialize(IPancakeRouter02 _router, IWNativeRelayer _wNativeRelayer) external initializer {
    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
    factory = IPancakeFactory(_router.factory());
    router = _router;
    wbnb = _router.WETH();
    wNativeRelayer = _wNativeRelayer;
  }

  /// @dev Execute worker strategy. take farmingToken, return farmingToken + basetoken that is enough to repay the debt
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address user,
    uint256 debt,
    bytes calldata data
  ) external override onlyWhitelistedWorkers nonReentrant {
    // 1.1 farmingTokenToLiquidate for farmingToken amount that user want to liquidate.
    // 1.2 toRepaidBaseTokenDebt for baseToken amount that user want to repaid debt.
    // 1.3 minFarmingTokenAmount for validating a farmingToken amount.
    (uint256 farmingTokenToLiquidate, uint256 toRepaidBaseTokenDebt, uint256 minFarmingTokenAmount) =
      abi.decode(data, (uint256, uint256, uint256));
    IWorker02 worker = IWorker02(msg.sender);
    address baseToken = worker.baseToken();
    address farmingToken = worker.farmingToken();
    // 2. Approve router to do their stuffs
    farmingToken.safeApprove(address(router), uint256(-1));
    // 3. check farmingToken amount to liquidate more than equal farmingToken balance
    uint256 farmingTokenBalance = farmingToken.myBalance();
    require(
      farmingTokenBalance >= farmingTokenToLiquidate,
      "PancakeswapV2RestrictedSingleAssetStrategyPartialCloseWithdrawMinimizeTrading::execute:: insufficient farmingToken received from worker"
    );
    // 4. check toRepaidBaseTokenDebt less than equal debt
    require(
      toRepaidBaseTokenDebt <= debt,
      "PancakeswapV2RestrictedSingleAssetStrategyPartialCloseWithdrawMinimizeTrading::execute:: amount to repay debt is greater than debt"
    );
    uint256 farmingTokenToRepaidDebt = 0;
    if (toRepaidBaseTokenDebt > 0) {
      // 5. Swap form baseToken to repaid debt -> farmingToken
      uint256[] memory farmingTokenToRepaidDebts = router.getAmountsIn(toRepaidBaseTokenDebt, worker.getReversedPath());
      farmingTokenToRepaidDebt = farmingTokenToRepaidDebts[0];
      require(
        farmingTokenToLiquidate >= farmingTokenToRepaidDebts[0],
        "PancakeswapV2RestrictedSingleAssetStrategyPartialCloseWithdrawMinimizeTrading::execute:: not enough to pay back debt"
      );
      // 6. Swap from farming token -> base token according to worker's path
      router.swapTokensForExactTokens(
        toRepaidBaseTokenDebt,
        farmingTokenBalance,
        worker.getReversedPath(),
        address(this),
        now
      );
    }
    uint256 farmingTokenBalanceToBeSentToTheUser = farmingTokenToLiquidate.sub(farmingTokenToRepaidDebt);
    // 7. Return baseToken back to the original caller in order to repay the debt
    baseToken.safeTransfer(msg.sender, baseToken.myBalance());
    // 8. Return the partial farmingTokens back to the user.
    require(
      farmingTokenBalanceToBeSentToTheUser >= minFarmingTokenAmount,
      "PancakeswapV2RestrictedSingleAssetStrategyPartialCloseWithdrawMinimizeTrading::execute:: insufficient farmingToken amount received"
    );
    if (farmingTokenBalanceToBeSentToTheUser > 0) {
      if (farmingToken == address(wbnb)) {
        SafeToken.safeTransfer(farmingToken, address(wNativeRelayer), farmingTokenBalanceToBeSentToTheUser);
        wNativeRelayer.withdraw(farmingTokenBalanceToBeSentToTheUser);
        SafeToken.safeTransferETH(user, farmingTokenBalanceToBeSentToTheUser);
      } else {
        SafeToken.safeTransfer(farmingToken, user, farmingTokenBalanceToBeSentToTheUser);
      }
    }
    // 9. Return farmingToken back to the original caller
    farmingToken.safeTransfer(msg.sender, farmingToken.myBalance());
    // 10. Reset approval for safety reason
    farmingToken.safeApprove(address(router), 0);
    emit PancakeswapV2RestrictedSingleAssetStrategyPartialCloseWithdrawMinimizeTradingEvent(
      baseToken,
      farmingToken,
      farmingTokenToLiquidate,
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