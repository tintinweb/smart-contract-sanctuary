// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Uniswap Adapter
import {BaseUniswapAdapter} from '@aave/protocol-v2/contracts/adapters/BaseUniswapAdapter.sol';

// Interfaces
import {
  ILendingPoolAddressesProvider
} from '@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '@aave/protocol-v2/contracts/interfaces/ILendingPool.sol';
import {IUniswapV2Router02} from '@aave/protocol-v2/contracts/interfaces/IUniswapV2Router02.sol';
import {IERC20} from '@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {
  SafeERC20
} from '@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol';

/**
 * @title FlashLiquidationAdapter
 * @notice Flash Liquidation that uses Uniswap V2 Adapter to swap released collateral during Aave V2 liquidations.
 * @dev You can check latest source at Aave Protocol V2 repository: https://github.com/aave/protocol-v2/blob/master/contracts/adapters/FlashLiquidationAdapter.sol
 * @author Aave
 **/
contract FlashLiquidationAdapter is BaseUniswapAdapter {
  using SafeERC20 for IERC20;

  struct LiquidationParams {
    address collateralAsset;
    address borrowedAsset;
    address user;
    uint256 debtToCover;
    bool useEthPath;
  }

  struct LiquidationCallLocalVars {
    uint256 initFlashBorrowedBalance;
    uint256 diffFlashBorrowedBalance;
    uint256 initCollateralBalance;
    uint256 diffCollateralBalance;
    uint256 flashLoanDebt;
    uint256 soldAmount;
    uint256 remainingTokens;
    uint256 borrowedAssetLeftovers;
  }

  constructor(
    ILendingPoolAddressesProvider addressesProvider,
    IUniswapV2Router02 uniswapRouter,
    address wethAddress
  ) public BaseUniswapAdapter(addressesProvider, uniswapRouter, wethAddress) {}

  /**
   * @dev Liquidate a non-healthy position collateral-wise, with a Health Factor below 1, using Flash Loan and Uniswap to repay flash loan premium.
   * - The caller (liquidator) with a flash loan covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk minus the flash loan premium.
   * @param assets Address of asset to be swapped
   * @param amounts Amount of the asset to be swapped
   * @param premiums Fee of the flash loan
   * @param initiator Address of the caller
   * @param params Additional variadic field to include extra params. Expected parameters:
   *   address collateralAsset The collateral asset to release and will be exchanged to pay the flash loan premium
   *   address borrowedAsset The asset that must be covered
   *   address user The user address with a Health Factor below 1
   *   uint256 debtToCover The amount of debt to cover
   *   bool useEthPath Use WETH as connector path between the collateralAsset and borrowedAsset at Uniswap
   */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override returns (bool) {
    require(msg.sender == address(LENDING_POOL), 'CALLER_MUST_BE_LENDING_POOL');

    LiquidationParams memory decodedParams = _decodeParams(params);

    require(assets.length == 1 && assets[0] == decodedParams.borrowedAsset, 'INCONSISTENT_PARAMS');

    _liquidateAndSwap(
      decodedParams.collateralAsset,
      decodedParams.borrowedAsset,
      decodedParams.user,
      decodedParams.debtToCover,
      decodedParams.useEthPath,
      amounts[0],
      premiums[0],
      initiator
    );

    return true;
  }

  /**
   * @dev
   * @param collateralAsset The collateral asset to release and will be exchanged to pay the flash loan premium
   * @param borrowedAsset The asset that must be covered
   * @param user The user address with a Health Factor below 1
   * @param debtToCover The amount of debt to coverage, can be max(-1) to liquidate all possible debt
   * @param useEthPath true if the swap needs to occur using ETH in the routing, false otherwise
   * @param flashBorrowedAmount Amount of asset requested at the flash loan to liquidate the user position
   * @param premium Fee of the requested flash loan
   * @param initiator Address of the caller
   */
  function _liquidateAndSwap(
    address collateralAsset,
    address borrowedAsset,
    address user,
    uint256 debtToCover,
    bool useEthPath,
    uint256 flashBorrowedAmount,
    uint256 premium,
    address initiator
  ) internal {
    LiquidationCallLocalVars memory vars;
    vars.initCollateralBalance = IERC20(collateralAsset).balanceOf(address(this));
    if (collateralAsset != borrowedAsset) {
      vars.initFlashBorrowedBalance = IERC20(borrowedAsset).balanceOf(address(this));

      // Track leftover balance to rescue funds in case of external transfers into this contract
      vars.borrowedAssetLeftovers = vars.initFlashBorrowedBalance.sub(flashBorrowedAmount);
    }
    vars.flashLoanDebt = flashBorrowedAmount.add(premium);

    // Approve LendingPool to use debt token for liquidation
    IERC20(borrowedAsset).safeApprove(address(LENDING_POOL), 0);
    IERC20(borrowedAsset).safeApprove(address(LENDING_POOL), debtToCover);

    // Liquidate the user position and release the underlying collateral
    LENDING_POOL.liquidationCall(collateralAsset, borrowedAsset, user, debtToCover, false);

    // Discover the liquidated tokens
    uint256 collateralBalanceAfter = IERC20(collateralAsset).balanceOf(address(this));

    // Track only collateral released, not current asset balance of the contract
    vars.diffCollateralBalance = collateralBalanceAfter.sub(vars.initCollateralBalance);

    if (collateralAsset != borrowedAsset) {
      // Discover flash loan balance after the liquidation
      uint256 flashBorrowedAssetAfter = IERC20(borrowedAsset).balanceOf(address(this));

      // Use only flash loan borrowed assets, not current asset balance of the contract
      vars.diffFlashBorrowedBalance = flashBorrowedAssetAfter.sub(vars.borrowedAssetLeftovers);

      // Swap released collateral into the debt asset, to repay the flash loan
      vars.soldAmount = _swapTokensForExactTokens(
        collateralAsset,
        borrowedAsset,
        vars.diffCollateralBalance,
        vars.flashLoanDebt.sub(vars.diffFlashBorrowedBalance),
        useEthPath
      );
      vars.remainingTokens = vars.diffCollateralBalance.sub(vars.soldAmount);
    } else {
      vars.remainingTokens = vars.diffCollateralBalance.sub(premium);
    }

    // Allow repay of flash loan
    IERC20(borrowedAsset).safeApprove(address(LENDING_POOL), 0);
    IERC20(borrowedAsset).safeApprove(address(LENDING_POOL), vars.flashLoanDebt);

    // Transfer remaining tokens to initiator
    if (vars.remainingTokens > 0) {
      IERC20(collateralAsset).safeTransfer(initiator, vars.remainingTokens);
    }
  }

  /**
   * @dev Decodes the information encoded in the flash loan params
   * @param params Additional variadic field to include extra params. Expected parameters:
   *   address collateralAsset The collateral asset to claim
   *   address borrowedAsset The asset that must be covered and will be exchanged to pay the flash loan premium
   *   address user The user address with a Health Factor below 1
   *   uint256 debtToCover The amount of debt to cover
   *   bool useEthPath Use WETH as connector path between the collateralAsset and borrowedAsset at Uniswap
   * @return LiquidationParams struct containing decoded params
   */
  function _decodeParams(bytes memory params) internal pure returns (LiquidationParams memory) {
    (
      address collateralAsset,
      address borrowedAsset,
      address user,
      uint256 debtToCover,
      bool useEthPath
    ) = abi.decode(params, (address, address, address, uint256, bool));

    return LiquidationParams(collateralAsset, borrowedAsset, user, debtToCover, useEthPath);
  }

  function requestFlashLoan(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    bytes calldata params
  ) external {
    // Request a Flash Loan to Lending Pool
    ILendingPool(LENDING_POOL).flashLoan(
      address(this),
      assets,
      amounts,
      modes,
      address(this),
      params,
      0
    );

    LiquidationParams memory decodedParams = _decodeParams(params);

    // Transfer the remaining collateral to the msg.sender
    uint256 allBalance = IERC20(decodedParams.collateralAsset).balanceOf(address(this));
    IERC20(decodedParams.collateralAsset).safeTransfer(msg.sender, allBalance);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {PercentageMath} from '../protocol/libraries/math/PercentageMath.sol';
import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {SafeERC20} from '../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {IERC20WithPermit} from '../interfaces/IERC20WithPermit.sol';
import {FlashLoanReceiverBase} from '../flashloan/base/FlashLoanReceiverBase.sol';
import {IBaseUniswapAdapter} from './interfaces/IBaseUniswapAdapter.sol';

/**
 * @title BaseUniswapAdapter
 * @notice Implements the logic for performing assets swaps in Uniswap V2
 * @author Aave
 **/
abstract contract BaseUniswapAdapter is FlashLoanReceiverBase, IBaseUniswapAdapter, Ownable {
  using SafeMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;

  // Max slippage percent allowed
  uint256 public constant override MAX_SLIPPAGE_PERCENT = 3000; // 30%
  // FLash Loan fee set in lending pool
  uint256 public constant override FLASHLOAN_PREMIUM_TOTAL = 9;
  // USD oracle asset address
  address public constant override USD_ADDRESS = 0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96;

  address public immutable override WETH_ADDRESS;
  IPriceOracleGetter public immutable override ORACLE;
  IUniswapV2Router02 public immutable override UNISWAP_ROUTER;

  constructor(
    ILendingPoolAddressesProvider addressesProvider,
    IUniswapV2Router02 uniswapRouter,
    address wethAddress
  ) public FlashLoanReceiverBase(addressesProvider) {
    ORACLE = IPriceOracleGetter(addressesProvider.getPriceOracle());
    UNISWAP_ROUTER = uniswapRouter;
    WETH_ADDRESS = wethAddress;
  }

  /**
   * @dev Given an input asset amount, returns the maximum output amount of the other asset and the prices
   * @param amountIn Amount of reserveIn
   * @param reserveIn Address of the asset to be swap from
   * @param reserveOut Address of the asset to be swap to
   * @return uint256 Amount out of the reserveOut
   * @return uint256 The price of out amount denominated in the reserveIn currency (18 decimals)
   * @return uint256 In amount of reserveIn value denominated in USD (8 decimals)
   * @return uint256 Out amount of reserveOut value denominated in USD (8 decimals)
   */
  function getAmountsOut(
    uint256 amountIn,
    address reserveIn,
    address reserveOut
  )
    external
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      address[] memory
    )
  {
    AmountCalc memory results = _getAmountsOutData(reserveIn, reserveOut, amountIn);

    return (
      results.calculatedAmount,
      results.relativePrice,
      results.amountInUsd,
      results.amountOutUsd,
      results.path
    );
  }

  /**
   * @dev Returns the minimum input asset amount required to buy the given output asset amount and the prices
   * @param amountOut Amount of reserveOut
   * @param reserveIn Address of the asset to be swap from
   * @param reserveOut Address of the asset to be swap to
   * @return uint256 Amount in of the reserveIn
   * @return uint256 The price of in amount denominated in the reserveOut currency (18 decimals)
   * @return uint256 In amount of reserveIn value denominated in USD (8 decimals)
   * @return uint256 Out amount of reserveOut value denominated in USD (8 decimals)
   */
  function getAmountsIn(
    uint256 amountOut,
    address reserveIn,
    address reserveOut
  )
    external
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      address[] memory
    )
  {
    AmountCalc memory results = _getAmountsInData(reserveIn, reserveOut, amountOut);

    return (
      results.calculatedAmount,
      results.relativePrice,
      results.amountInUsd,
      results.amountOutUsd,
      results.path
    );
  }

  /**
   * @dev Swaps an exact `amountToSwap` of an asset to another
   * @param assetToSwapFrom Origin asset
   * @param assetToSwapTo Destination asset
   * @param amountToSwap Exact amount of `assetToSwapFrom` to be swapped
   * @param minAmountOut the min amount of `assetToSwapTo` to be received from the swap
   * @return the amount received from the swap
   */
  function _swapExactTokensForTokens(
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    uint256 minAmountOut,
    bool useEthPath
  ) internal returns (uint256) {
    uint256 fromAssetDecimals = _getDecimals(assetToSwapFrom);
    uint256 toAssetDecimals = _getDecimals(assetToSwapTo);

    uint256 fromAssetPrice = _getPrice(assetToSwapFrom);
    uint256 toAssetPrice = _getPrice(assetToSwapTo);

    uint256 expectedMinAmountOut =
      amountToSwap
        .mul(fromAssetPrice.mul(10**toAssetDecimals))
        .div(toAssetPrice.mul(10**fromAssetDecimals))
        .percentMul(PercentageMath.PERCENTAGE_FACTOR.sub(MAX_SLIPPAGE_PERCENT));

    require(expectedMinAmountOut < minAmountOut, 'minAmountOut exceed max slippage');

    // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    IERC20(assetToSwapFrom).safeApprove(address(UNISWAP_ROUTER), 0);
    IERC20(assetToSwapFrom).safeApprove(address(UNISWAP_ROUTER), amountToSwap);

    address[] memory path;
    if (useEthPath) {
      path = new address[](3);
      path[0] = assetToSwapFrom;
      path[1] = WETH_ADDRESS;
      path[2] = assetToSwapTo;
    } else {
      path = new address[](2);
      path[0] = assetToSwapFrom;
      path[1] = assetToSwapTo;
    }
    uint256[] memory amounts =
      UNISWAP_ROUTER.swapExactTokensForTokens(
        amountToSwap,
        minAmountOut,
        path,
        address(this),
        block.timestamp
      );

    emit Swapped(assetToSwapFrom, assetToSwapTo, amounts[0], amounts[amounts.length - 1]);

    return amounts[amounts.length - 1];
  }

  /**
   * @dev Receive an exact amount `amountToReceive` of `assetToSwapTo` tokens for as few `assetToSwapFrom` tokens as
   * possible.
   * @param assetToSwapFrom Origin asset
   * @param assetToSwapTo Destination asset
   * @param maxAmountToSwap Max amount of `assetToSwapFrom` allowed to be swapped
   * @param amountToReceive Exact amount of `assetToSwapTo` to receive
   * @return the amount swapped
   */
  function _swapTokensForExactTokens(
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 maxAmountToSwap,
    uint256 amountToReceive,
    bool useEthPath
  ) internal returns (uint256) {
    uint256 fromAssetDecimals = _getDecimals(assetToSwapFrom);
    uint256 toAssetDecimals = _getDecimals(assetToSwapTo);

    uint256 fromAssetPrice = _getPrice(assetToSwapFrom);
    uint256 toAssetPrice = _getPrice(assetToSwapTo);

    uint256 expectedMaxAmountToSwap =
      amountToReceive
        .mul(toAssetPrice.mul(10**fromAssetDecimals))
        .div(fromAssetPrice.mul(10**toAssetDecimals))
        .percentMul(PercentageMath.PERCENTAGE_FACTOR.add(MAX_SLIPPAGE_PERCENT));

    require(maxAmountToSwap < expectedMaxAmountToSwap, 'maxAmountToSwap exceed max slippage');

    // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    IERC20(assetToSwapFrom).safeApprove(address(UNISWAP_ROUTER), 0);
    IERC20(assetToSwapFrom).safeApprove(address(UNISWAP_ROUTER), maxAmountToSwap);

    address[] memory path;
    if (useEthPath) {
      path = new address[](3);
      path[0] = assetToSwapFrom;
      path[1] = WETH_ADDRESS;
      path[2] = assetToSwapTo;
    } else {
      path = new address[](2);
      path[0] = assetToSwapFrom;
      path[1] = assetToSwapTo;
    }

    uint256[] memory amounts =
      UNISWAP_ROUTER.swapTokensForExactTokens(
        amountToReceive,
        maxAmountToSwap,
        path,
        address(this),
        block.timestamp
      );

    emit Swapped(assetToSwapFrom, assetToSwapTo, amounts[0], amounts[amounts.length - 1]);

    return amounts[0];
  }

  /**
   * @dev Get the price of the asset from the oracle denominated in eth
   * @param asset address
   * @return eth price for the asset
   */
  function _getPrice(address asset) internal view returns (uint256) {
    return ORACLE.getAssetPrice(asset);
  }

  /**
   * @dev Get the decimals of an asset
   * @return number of decimals of the asset
   */
  function _getDecimals(address asset) internal view returns (uint256) {
    return IERC20Detailed(asset).decimals();
  }

  /**
   * @dev Get the aToken associated to the asset
   * @return address of the aToken
   */
  function _getReserveData(address asset) internal view returns (DataTypes.ReserveData memory) {
    return LENDING_POOL.getReserveData(asset);
  }

  /**
   * @dev Pull the ATokens from the user
   * @param reserve address of the asset
   * @param reserveAToken address of the aToken of the reserve
   * @param user address
   * @param amount of tokens to be transferred to the contract
   * @param permitSignature struct containing the permit signature
   */
  function _pullAToken(
    address reserve,
    address reserveAToken,
    address user,
    uint256 amount,
    PermitSignature memory permitSignature
  ) internal {
    if (_usePermit(permitSignature)) {
      IERC20WithPermit(reserveAToken).permit(
        user,
        address(this),
        permitSignature.amount,
        permitSignature.deadline,
        permitSignature.v,
        permitSignature.r,
        permitSignature.s
      );
    }

    // transfer from user to adapter
    IERC20(reserveAToken).safeTransferFrom(user, address(this), amount);

    // withdraw reserve
    LENDING_POOL.withdraw(reserve, amount, address(this));
  }

  /**
   * @dev Tells if the permit method should be called by inspecting if there is a valid signature.
   * If signature params are set to 0, then permit won't be called.
   * @param signature struct containing the permit signature
   * @return whether or not permit should be called
   */
  function _usePermit(PermitSignature memory signature) internal pure returns (bool) {
    return
      !(uint256(signature.deadline) == uint256(signature.v) && uint256(signature.deadline) == 0);
  }

  /**
   * @dev Calculates the value denominated in USD
   * @param reserve Address of the reserve
   * @param amount Amount of the reserve
   * @param decimals Decimals of the reserve
   * @return whether or not permit should be called
   */
  function _calcUsdValue(
    address reserve,
    uint256 amount,
    uint256 decimals
  ) internal view returns (uint256) {
    uint256 ethUsdPrice = _getPrice(USD_ADDRESS);
    uint256 reservePrice = _getPrice(reserve);

    return amount.mul(reservePrice).div(10**decimals).mul(ethUsdPrice).div(10**18);
  }

  /**
   * @dev Given an input asset amount, returns the maximum output amount of the other asset
   * @param reserveIn Address of the asset to be swap from
   * @param reserveOut Address of the asset to be swap to
   * @param amountIn Amount of reserveIn
   * @return Struct containing the following information:
   *   uint256 Amount out of the reserveOut
   *   uint256 The price of out amount denominated in the reserveIn currency (18 decimals)
   *   uint256 In amount of reserveIn value denominated in USD (8 decimals)
   *   uint256 Out amount of reserveOut value denominated in USD (8 decimals)
   */
  function _getAmountsOutData(
    address reserveIn,
    address reserveOut,
    uint256 amountIn
  ) internal view returns (AmountCalc memory) {
    // Subtract flash loan fee
    uint256 finalAmountIn = amountIn.sub(amountIn.mul(FLASHLOAN_PREMIUM_TOTAL).div(10000));

    if (reserveIn == reserveOut) {
      uint256 reserveDecimals = _getDecimals(reserveIn);
      address[] memory path = new address[](1);
      path[0] = reserveIn;

      return
        AmountCalc(
          finalAmountIn,
          finalAmountIn.mul(10**18).div(amountIn),
          _calcUsdValue(reserveIn, amountIn, reserveDecimals),
          _calcUsdValue(reserveIn, finalAmountIn, reserveDecimals),
          path
        );
    }

    address[] memory simplePath = new address[](2);
    simplePath[0] = reserveIn;
    simplePath[1] = reserveOut;

    uint256[] memory amountsWithoutWeth;
    uint256[] memory amountsWithWeth;

    address[] memory pathWithWeth = new address[](3);
    if (reserveIn != WETH_ADDRESS && reserveOut != WETH_ADDRESS) {
      pathWithWeth[0] = reserveIn;
      pathWithWeth[1] = WETH_ADDRESS;
      pathWithWeth[2] = reserveOut;

      try UNISWAP_ROUTER.getAmountsOut(finalAmountIn, pathWithWeth) returns (
        uint256[] memory resultsWithWeth
      ) {
        amountsWithWeth = resultsWithWeth;
      } catch {
        amountsWithWeth = new uint256[](3);
      }
    } else {
      amountsWithWeth = new uint256[](3);
    }

    uint256 bestAmountOut;
    try UNISWAP_ROUTER.getAmountsOut(finalAmountIn, simplePath) returns (
      uint256[] memory resultAmounts
    ) {
      amountsWithoutWeth = resultAmounts;

      bestAmountOut = (amountsWithWeth[2] > amountsWithoutWeth[1])
        ? amountsWithWeth[2]
        : amountsWithoutWeth[1];
    } catch {
      amountsWithoutWeth = new uint256[](2);
      bestAmountOut = amountsWithWeth[2];
    }

    uint256 reserveInDecimals = _getDecimals(reserveIn);
    uint256 reserveOutDecimals = _getDecimals(reserveOut);

    uint256 outPerInPrice =
      finalAmountIn.mul(10**18).mul(10**reserveOutDecimals).div(
        bestAmountOut.mul(10**reserveInDecimals)
      );

    return
      AmountCalc(
        bestAmountOut,
        outPerInPrice,
        _calcUsdValue(reserveIn, amountIn, reserveInDecimals),
        _calcUsdValue(reserveOut, bestAmountOut, reserveOutDecimals),
        (bestAmountOut == 0) ? new address[](2) : (bestAmountOut == amountsWithoutWeth[1])
          ? simplePath
          : pathWithWeth
      );
  }

  /**
   * @dev Returns the minimum input asset amount required to buy the given output asset amount
   * @param reserveIn Address of the asset to be swap from
   * @param reserveOut Address of the asset to be swap to
   * @param amountOut Amount of reserveOut
   * @return Struct containing the following information:
   *   uint256 Amount in of the reserveIn
   *   uint256 The price of in amount denominated in the reserveOut currency (18 decimals)
   *   uint256 In amount of reserveIn value denominated in USD (8 decimals)
   *   uint256 Out amount of reserveOut value denominated in USD (8 decimals)
   */
  function _getAmountsInData(
    address reserveIn,
    address reserveOut,
    uint256 amountOut
  ) internal view returns (AmountCalc memory) {
    if (reserveIn == reserveOut) {
      // Add flash loan fee
      uint256 amountIn = amountOut.add(amountOut.mul(FLASHLOAN_PREMIUM_TOTAL).div(10000));
      uint256 reserveDecimals = _getDecimals(reserveIn);
      address[] memory path = new address[](1);
      path[0] = reserveIn;
      
      return
        AmountCalc(
          amountIn,
          amountOut.mul(10**18).div(amountIn),
          _calcUsdValue(reserveIn, amountIn, reserveDecimals),
          _calcUsdValue(reserveIn, amountOut, reserveDecimals),
          path
        );
    }

    (uint256[] memory amounts, address[] memory path) =
      _getAmountsInAndPath(reserveIn, reserveOut, amountOut);

    // Add flash loan fee
    uint256 finalAmountIn = amounts[0].add(amounts[0].mul(FLASHLOAN_PREMIUM_TOTAL).div(10000));

    uint256 reserveInDecimals = _getDecimals(reserveIn);
    uint256 reserveOutDecimals = _getDecimals(reserveOut);

    uint256 inPerOutPrice =
      amountOut.mul(10**18).mul(10**reserveInDecimals).div(
        finalAmountIn.mul(10**reserveOutDecimals)
      );

    return
      AmountCalc(
        finalAmountIn,
        inPerOutPrice,
        _calcUsdValue(reserveIn, finalAmountIn, reserveInDecimals),
        _calcUsdValue(reserveOut, amountOut, reserveOutDecimals),
        path
      );
  }

  /**
   * @dev Calculates the input asset amount required to buy the given output asset amount
   * @param reserveIn Address of the asset to be swap from
   * @param reserveOut Address of the asset to be swap to
   * @param amountOut Amount of reserveOut
   * @return uint256[] amounts Array containing the amountIn and amountOut for a swap
   */
  function _getAmountsInAndPath(
    address reserveIn,
    address reserveOut,
    uint256 amountOut
  ) internal view returns (uint256[] memory, address[] memory) {
    address[] memory simplePath = new address[](2);
    simplePath[0] = reserveIn;
    simplePath[1] = reserveOut;

    uint256[] memory amountsWithoutWeth;
    uint256[] memory amountsWithWeth;
    address[] memory pathWithWeth = new address[](3);

    if (reserveIn != WETH_ADDRESS && reserveOut != WETH_ADDRESS) {
      pathWithWeth[0] = reserveIn;
      pathWithWeth[1] = WETH_ADDRESS;
      pathWithWeth[2] = reserveOut;

      try UNISWAP_ROUTER.getAmountsIn(amountOut, pathWithWeth) returns (
        uint256[] memory resultsWithWeth
      ) {
        amountsWithWeth = resultsWithWeth;
      } catch {
        amountsWithWeth = new uint256[](3);
      }
    } else {
      amountsWithWeth = new uint256[](3);
    }

    try UNISWAP_ROUTER.getAmountsIn(amountOut, simplePath) returns (
      uint256[] memory resultAmounts
    ) {
      amountsWithoutWeth = resultAmounts;

      return
        (amountsWithWeth[0] < amountsWithoutWeth[0] && amountsWithWeth[0] != 0)
          ? (amountsWithWeth, pathWithWeth)
          : (amountsWithoutWeth, simplePath);
    } catch {
      return (amountsWithWeth, pathWithWeth);
    }
  }

  /**
   * @dev Calculates the input asset amount required to buy the given output asset amount
   * @param reserveIn Address of the asset to be swap from
   * @param reserveOut Address of the asset to be swap to
   * @param amountOut Amount of reserveOut
   * @return uint256[] amounts Array containing the amountIn and amountOut for a swap
   */
  function _getAmountsIn(
    address reserveIn,
    address reserveOut,
    uint256 amountOut,
    bool useEthPath
  ) internal view returns (uint256[] memory) {
    address[] memory path;

    if (useEthPath) {
      path = new address[](3);
      path[0] = reserveIn;
      path[1] = WETH_ADDRESS;
      path[2] = reserveOut;
    } else {
      path = new address[](2);
      path[0] = reserveIn;
      path[1] = reserveOut;
    }

    return UNISWAP_ROUTER.getAmountsIn(amountOut, path);
  }

  /**
   * @dev Emergency rescue for token stucked on this contract, as failsafe mechanism
   * - Funds should never remain in this contract more time than during transactions
   * - Only callable by the owner
   **/
  function rescueTokens(IERC20 token) external onlyOwner {
    token.transfer(owner(), token.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IUniswapV2Router02 {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint256[] memory amounts);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {SafeMath} from './SafeMath.sol';
import {Address} from './Address.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {Errors} from '../helpers/Errors.sol';

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/

interface IPriceOracleGetter {
  /**
   * @dev returns the asset price in ETH
   * @param asset the address of the asset
   * @return the ETH price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';

interface IERC20WithPermit is IERC20 {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {IFlashLoanReceiver} from '../interfaces/IFlashLoanReceiver.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ILendingPool public immutable override LENDING_POOL;

  constructor(ILendingPoolAddressesProvider provider) public {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ILendingPool(provider.getLendingPool());
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IPriceOracleGetter} from '../../interfaces/IPriceOracleGetter.sol';
import {IUniswapV2Router02} from '../../interfaces/IUniswapV2Router02.sol';

interface IBaseUniswapAdapter {
  event Swapped(address fromAsset, address toAsset, uint256 fromAmount, uint256 receivedAmount);

  struct PermitSignature {
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct AmountCalc {
    uint256 calculatedAmount;
    uint256 relativePrice;
    uint256 amountInUsd;
    uint256 amountOutUsd;
    address[] path;
  }

  function WETH_ADDRESS() external returns (address);

  function MAX_SLIPPAGE_PERCENT() external returns (uint256);

  function FLASHLOAN_PREMIUM_TOTAL() external returns (uint256);

  function USD_ADDRESS() external returns (address);

  function ORACLE() external returns (IPriceOracleGetter);

  function UNISWAP_ROUTER() external returns (IUniswapV2Router02);

  /**
   * @dev Given an input asset amount, returns the maximum output amount of the other asset and the prices
   * @param amountIn Amount of reserveIn
   * @param reserveIn Address of the asset to be swap from
   * @param reserveOut Address of the asset to be swap to
   * @return uint256 Amount out of the reserveOut
   * @return uint256 The price of out amount denominated in the reserveIn currency (18 decimals)
   * @return uint256 In amount of reserveIn value denominated in USD (8 decimals)
   * @return uint256 Out amount of reserveOut value denominated in USD (8 decimals)
   * @return address[] The exchange path
   */
  function getAmountsOut(
    uint256 amountIn,
    address reserveIn,
    address reserveOut
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      address[] memory
    );

  /**
   * @dev Returns the minimum input asset amount required to buy the given output asset amount and the prices
   * @param amountOut Amount of reserveOut
   * @param reserveIn Address of the asset to be swap from
   * @param reserveOut Address of the asset to be swap to
   * @return uint256 Amount in of the reserveIn
   * @return uint256 The price of in amount denominated in the reserveOut currency (18 decimals)
   * @return uint256 In amount of reserveIn value denominated in USD (8 decimals)
   * @return uint256 Out amount of reserveOut value denominated in USD (8 decimals)
   * @return address[] The exchange path
   */
  function getAmountsIn(
    uint256 amountOut,
    address reserveIn,
    address reserveOut
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      address[] memory
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // 'The caller must be the pool admin'
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small

  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // 'The current liquidity is not enough'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // 'User cannot withdraw more than the available balance'
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // 'Transfer cannot be allowed.'
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // 'Borrowing is not enabled'
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // 'Invalid interest rate mode selected'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // 'The requested amount is greater than the max loan size in stable rate mode
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // 'To repay on behalf of an user an explicit amount to repay is needed'
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // 'User does not have a stable rate loan in progress on this reserve'
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // 'User does not have a variable rate loan in progress on this reserve'
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // 'The underlying balance needs to be greater than 0'
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // 'User deposit is already being used as collateral'
  string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = '21'; // 'User does not have any stable rate loan for this reserve'
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // 'Interest rate rebalance conditions were not met'
  string public constant LP_LIQUIDATION_CALL_FAILED = '23'; // 'Liquidation call failed'
  string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = '24'; // 'There is not enough liquidity available to borrow'
  string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = '25'; // 'The requested amount is too small for a FlashLoan.'
  string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // 'The actual balance of the protocol is inconsistent'
  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = '28';
  string public constant CT_CALLER_MUST_BE_LENDING_POOL = '29'; // 'The caller of this function must be a lending pool'
  string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // 'User cannot give allowance to himself'
  string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // 'Transferred amount needs to be greater than zero'
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // 'Reserve has already been initialized'
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = '35'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = '36'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = '37'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '38'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '39'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_CONFIGURATION = '75'; // 'Invalid risk parameters for the reserve'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = '76'; // 'The caller must be the emergency admin'
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // 'Provider is not registered'
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // 'Health factor is not below the threshold'
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // 'The collateral chosen cannot be liquidated'
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // 'User did not borrow the specified currency'
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // "There isn't enough liquidity available to liquidate"
  string public constant LPCM_NO_ERRORS = '46'; // 'No errors'
  string public constant LP_INVALID_FLASHLOAN_MODE = '47'; //Invalid flashloan mode selected
  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant LP_FAILED_REPAY_WITH_COLLATERAL = '57';
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant LP_FAILED_COLLATERAL_SWAP = '60';
  string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = '61';
  string public constant LP_REENTRANCY_NOT_ALLOWED = '62';
  string public constant LP_CALLER_MUST_BE_AN_ATOKEN = '63';
  string public constant LP_IS_PAUSED = '64'; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string public constant RC_INVALID_LTV = '67';
  string public constant RC_INVALID_LIQ_THRESHOLD = '68';
  string public constant RC_INVALID_LIQ_BONUS = '69';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string public constant LP_INCONSISTENT_PARAMS_LENGTH = '74';
  string public constant UL_INVALID_INDEX = '77';
  string public constant LP_NOT_CONTRACT = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';

  enum CollateralManagerErrors {
    NO_ERROR,
    NO_COLLATERAL_AVAILABLE,
    COLLATERAL_CANNOT_BE_LIQUIDATED,
    CURRRENCY_NOT_BORROWED,
    HEALTH_FACTOR_ABOVE_THRESHOLD,
    NOT_ENOUGH_LIQUIDITY,
    NO_ACTIVE_RESERVE,
    HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
    INVALID_EQUAL_ASSETS_TO_SWAP,
    FROZEN_RESERVE
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal virtual view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal virtual view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

  function LENDING_POOL() external view returns (ILendingPool);
}

