// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseParaSwapSellAdapter} from './BaseParaSwapSellAdapter.sol';
import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {IERC20} from './IERC20.sol';

/**
 * @title ParaSwapLiquiditySwapAdapter
 * @notice Adapter to swap liquidity using ParaSwap.
 * @author Jason Raymond Bell
 */
contract ParaSwapLiquiditySwapAdapter is BaseParaSwapSellAdapter {
  constructor(
    ILendingPoolAddressesProvider addressesProvider
  ) public BaseParaSwapSellAdapter(addressesProvider) {}

  /**
   * @dev Swaps the received reserve amount from the flash loan into the asset specified in the params.
   * The received funds from the swap are then deposited into the protocol on behalf of the user.
   * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset and repay the flash loan.
   * @param assets Address of the underlying asset to be swapped from
   * @param amounts Amount of the flash loan i.e. maximum amount to swap
   * @param premiums Fee of the flash loan
   * @param initiator Account that initiated the flash loan
   * @param params Additional variadic field to include extra params. Expected parameters:
   *   address assetToSwapTo Address of the underlying asset to be swapped to and deposited
   *   uint256 minAmountToReceive Min amount to be received from the swap
   *   uint256 swapAllBalanceOffset Set to offset of fromAmount in Augustus calldata if wanting to swap all balance, otherwise 0
   *   bytes swapCalldata Calldata for ParaSwap's AugustusSwapper contract
   *   address augustus Address of ParaSwap's AugustusSwapper contract
   *   PermitSignature permitParams Struct containing the permit signatures, set to all zeroes if not used
   */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override returns (bool) {
    require(msg.sender == address(LENDING_POOL), 'CALLER_MUST_BE_LENDING_POOL');
    require(assets.length == 1, 'FLASHLOAN_MULTIPLE_ASSETS_NOT_SUPPORTED');

    uint256 flashLoanAmount = amounts[0];
    uint256 premium = premiums[0];
    address initiatorLocal = initiator;
    address assetToSwapFrom = assets[0];
    (
      address assetToSwapTo,
      uint256 minAmountToReceive,
      uint256 swapAllBalanceOffset,
      bytes memory swapCalldata,
      address augustus,
      PermitSignature memory permitParams
    ) = abi.decode(params, (address, uint256, uint256, bytes, address, PermitSignature));

    _swapLiquidity(
      swapAllBalanceOffset,
      swapCalldata,
      augustus,
      permitParams,
      flashLoanAmount,
      premium,
      initiatorLocal,
      assetToSwapFrom,
      assetToSwapTo,
      minAmountToReceive
    );

    return true;
  }

  /**
   * @dev Swaps an amount of an asset to another and deposits the new asset amount on behalf of the user without using a flash loan.
   * This method can be used when the temporary transfer of the collateral asset to this contract does not affect the user position.
   * The user should give this contract allowance to pull the ATokens in order to withdraw the underlying asset and perform the swap.
   * @param assetToSwapFrom Address of the underlying asset to be swapped from
   * @param assetToSwapTo Address of the underlying asset to be swapped to and deposited
   * @param amountToSwap Amount to be swapped, or maximum amount when swapping all balance
   * @param minAmountToReceive Minimum amount to be received from the swap
   * @param swapAllBalanceOffset Set to offset of fromAmount in Augustus calldata if wanting to swap all balance, otherwise 0
   * @param swapCalldata Calldata for ParaSwap's AugustusSwapper contract
   * @param augustus Address of ParaSwap's AugustusSwapper contract
   * @param permitParams Struct containing the permit signatures, set to all zeroes if not used
   */
  function swapAndDeposit(
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    uint256 minAmountToReceive,
    uint256 swapAllBalanceOffset,
    bytes calldata swapCalldata,
    address augustus,
    PermitSignature calldata permitParams
  ) external {
    address aToken = _getReserveData(assetToSwapFrom).aTokenAddress;

    if (swapAllBalanceOffset != 0) {
      uint256 balance = IERC20(aToken).balanceOf(msg.sender);
      require(balance <= amountToSwap, 'INSUFFICIENT_AMOUNT_TO_SWAP');
      amountToSwap = balance;
    }

    _pullAToken(
      assetToSwapFrom,
      aToken,
      msg.sender,
      amountToSwap,
      permitParams
    );

    uint256 amountReceived = _sellOnParaSwap(
      swapAllBalanceOffset,
      swapCalldata,
      augustus,
      assetToSwapFrom,
      assetToSwapTo,
      amountToSwap,
      minAmountToReceive
    );

    IERC20(assetToSwapTo).safeApprove(address(LENDING_POOL), 0);
    IERC20(assetToSwapTo).safeApprove(address(LENDING_POOL), amountReceived);
    LENDING_POOL.deposit(assetToSwapTo, amountReceived, msg.sender, 0);
  }

  /**
   * @dev Swaps an amount of an asset to another and deposits the funds on behalf of the initiator.
   * @param swapAllBalanceOffset Set to offset of fromAmount in Augustus calldata if wanting to swap all balance, otherwise 0
   * @param swapCalldata Calldata for ParaSwap's AugustusSwapper contract
   * @param augustus Address of ParaSwap's AugustusSwapper contract
   * @param permitParams Struct containing the permit signatures, set to all zeroes if not used
   * @param flashLoanAmount Amount of the flash loan i.e. maximum amount to swap
   * @param premium Fee of the flash loan
   * @param initiator Account that initiated the flash loan
   * @param assetToSwapFrom Address of the underyling asset to be swapped from
   * @param assetToSwapTo Address of the underlying asset to be swapped to and deposited
   * @param minAmountToReceive Min amount to be received from the swap
   */
  function _swapLiquidity (
    uint256 swapAllBalanceOffset,
    bytes memory swapCalldata,
    address augustus,
    PermitSignature memory permitParams,
    uint256 flashLoanAmount,
    uint256 premium,
    address initiator,
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 minAmountToReceive
  ) internal {
    address aToken = _getReserveData(assetToSwapFrom).aTokenAddress;
    uint256 amountToSwap = flashLoanAmount;

    uint256 balance = IERC20(aToken).balanceOf(initiator);
    if (swapAllBalanceOffset != 0) {
      uint256 balanceToSwap = balance.sub(premium);
      require(balanceToSwap <= amountToSwap, 'INSUFFICIENT_AMOUNT_TO_SWAP');
      amountToSwap = balanceToSwap;
    } else {
      require(balance >= amountToSwap.add(premium), 'INSUFFICIENT_ATOKEN_BALANCE');
    }

    uint256 amountReceived = _sellOnParaSwap(
      swapAllBalanceOffset,
      swapCalldata,
      augustus,
      assetToSwapFrom,
      assetToSwapTo,
      amountToSwap,
      minAmountToReceive
    );

    IERC20(assetToSwapTo).safeApprove(address(LENDING_POOL), 0);
    IERC20(assetToSwapTo).safeApprove(address(LENDING_POOL), amountReceived);
    LENDING_POOL.deposit(assetToSwapTo, amountReceived, initiator, 0);

    _pullAToken(
      assetToSwapFrom,
      aToken,
      initiator,
      amountToSwap.add(premium),
      permitParams
    );

    // Repay flash loan
    IERC20(assetToSwapFrom).safeApprove(address(LENDING_POOL), 0);
    IERC20(assetToSwapFrom).safeApprove(address(LENDING_POOL), flashLoanAmount.add(premium));
  }
}