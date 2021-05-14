// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  MintableBurnableIERC20
} from '../common/interfaces/MintableBurnableIERC20.sol';
import {
  IERC20Standard
} from '../../../@jarvis-network/uma-core/contracts/common/interfaces/IERC20Standard.sol';
import {
  OracleInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/OracleInterface.sol';
import {
  OracleInterfaces
} from '../../../@jarvis-network/uma-core/contracts/oracle/implementation/Constants.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {FeePayerPartyLib} from '../common/FeePayerPartyLib.sol';
import {
  PerpetualPositionManagerPoolParty
} from './PerpetualPositionManagerPoolParty.sol';
import {FeePayerParty} from '../common/FeePayerParty.sol';

library PerpetualPositionManagerPoolPartyLib {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using PerpetualPositionManagerPoolPartyLib for PerpetualPositionManagerPoolParty.PositionData;
  using PerpetualPositionManagerPoolPartyLib for PerpetualPositionManagerPoolParty.PositionManagerData;
  using PerpetualPositionManagerPoolPartyLib for FeePayerParty.FeePayerData;
  using PerpetualPositionManagerPoolPartyLib for FixedPoint.Unsigned;
  using FeePayerPartyLib for FixedPoint.Unsigned;

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event RequestWithdrawal(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalExecuted(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalCanceled(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );
  event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  function depositTo(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerParty.FeePayerData storage feePayerData,
    address sponsor
  ) external {
    require(collateralAmount.isGreaterThan(0), 'Invalid collateral amount');

    positionData._incrementCollateralBalances(
      globalPositionData,
      collateralAmount,
      feePayerData
    );

    emit Deposit(sponsor, collateralAmount.rawValue);

    feePayerData.collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      collateralAmount.rawValue
    );
  }

  function withdraw(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    require(collateralAmount.isGreaterThan(0), 'Invalid collateral amount');

    amountWithdrawn = _decrementCollateralBalancesCheckGCR(
      positionData,
      globalPositionData,
      collateralAmount,
      feePayerData
    );

    emit Withdrawal(msg.sender, amountWithdrawn.rawValue);

    feePayerData.collateralCurrency.safeTransfer(
      msg.sender,
      amountWithdrawn.rawValue
    );
  }

  function requestWithdrawal(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    uint256 actualTime,
    FeePayerParty.FeePayerData storage feePayerData
  ) external {
    require(
      collateralAmount.isGreaterThan(0) &&
        collateralAmount.isLessThanOrEqual(
          positionData.rawCollateral.getFeeAdjustedCollateral(
            feePayerData.cumulativeFeeMultiplier
          )
        ),
      'Invalid collateral amount'
    );

    positionData.withdrawalRequestPassTimestamp = actualTime.add(
      positionManagerData.withdrawalLiveness
    );
    positionData.withdrawalRequestAmount = collateralAmount;

    emit RequestWithdrawal(msg.sender, collateralAmount.rawValue);
  }

  function withdrawPassedRequest(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    uint256 actualTime,
    FeePayerParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    require(
      positionData.withdrawalRequestPassTimestamp != 0 &&
        positionData.withdrawalRequestPassTimestamp <= actualTime,
      'Invalid withdraw request'
    );

    FixedPoint.Unsigned memory amountToWithdraw =
      positionData.withdrawalRequestAmount;
    if (
      positionData.withdrawalRequestAmount.isGreaterThan(
        positionData.rawCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      )
    ) {
      amountToWithdraw = positionData.rawCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
    }

    amountWithdrawn = positionData._decrementCollateralBalances(
      globalPositionData,
      amountToWithdraw,
      feePayerData
    );

    positionData._resetWithdrawalRequest();

    feePayerData.collateralCurrency.safeTransfer(
      msg.sender,
      amountWithdrawn.rawValue
    );

    emit RequestWithdrawalExecuted(msg.sender, amountWithdrawn.rawValue);
  }

  function cancelWithdrawal(
    PerpetualPositionManagerPoolParty.PositionData storage positionData
  ) external {
    require(
      positionData.withdrawalRequestPassTimestamp != 0,
      'No pending withdrawal'
    );

    emit RequestWithdrawalCanceled(
      msg.sender,
      positionData.withdrawalRequestAmount.rawValue
    );

    _resetWithdrawalRequest(positionData);
  }

  function create(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens,
    FeePayerParty.FeePayerData storage feePayerData
  ) external {
    require(
      (_checkCollateralization(
        globalPositionData,
        positionData
          .rawCollateral
          .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
          .add(collateralAmount),
        positionData.tokensOutstanding.add(numTokens),
        feePayerData
      ) ||
        _checkCollateralization(
          globalPositionData,
          collateralAmount,
          numTokens,
          feePayerData
        )),
      'Insufficient collateral'
    );

    require(
      positionData.withdrawalRequestPassTimestamp == 0,
      'Pending withdrawal'
    );
    if (positionData.tokensOutstanding.isEqual(0)) {
      require(
        numTokens.isGreaterThanOrEqual(positionManagerData.minSponsorTokens),
        'Below minimum sponsor position'
      );
      emit NewSponsor(msg.sender);
    }

    _incrementCollateralBalances(
      positionData,
      globalPositionData,
      collateralAmount,
      feePayerData
    );

    positionData.tokensOutstanding = positionData.tokensOutstanding.add(
      numTokens
    );

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .add(numTokens);

    emit PositionCreated(
      msg.sender,
      collateralAmount.rawValue,
      numTokens.rawValue
    );

    feePayerData.collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      collateralAmount.rawValue
    );
    require(
      positionManagerData.tokenCurrency.mint(msg.sender, numTokens.rawValue),
      'Minting synthetic tokens failed'
    );
  }

  function redeeem(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory numTokens,
    FeePayerParty.FeePayerData storage feePayerData,
    address sponsor
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    require(
      numTokens.isLessThanOrEqual(positionData.tokensOutstanding),
      'Invalid token amount'
    );

    FixedPoint.Unsigned memory fractionRedeemed =
      numTokens.div(positionData.tokensOutstanding);
    FixedPoint.Unsigned memory collateralRedeemed =
      fractionRedeemed.mul(
        positionData.rawCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      );

    if (positionData.tokensOutstanding.isEqual(numTokens)) {
      amountWithdrawn = positionData._deleteSponsorPosition(
        globalPositionData,
        feePayerData,
        sponsor
      );
    } else {
      amountWithdrawn = positionData._decrementCollateralBalances(
        globalPositionData,
        collateralRedeemed,
        feePayerData
      );

      FixedPoint.Unsigned memory newTokenCount =
        positionData.tokensOutstanding.sub(numTokens);
      require(
        newTokenCount.isGreaterThanOrEqual(
          positionManagerData.minSponsorTokens
        ),
        'Below minimum sponsor position'
      );
      positionData.tokensOutstanding = newTokenCount;

      globalPositionData.totalTokensOutstanding = globalPositionData
        .totalTokensOutstanding
        .sub(numTokens);
    }

    emit Redeem(msg.sender, amountWithdrawn.rawValue, numTokens.rawValue);

    feePayerData.collateralCurrency.safeTransfer(
      msg.sender,
      amountWithdrawn.rawValue
    );
    positionManagerData.tokenCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      numTokens.rawValue
    );
    positionManagerData.tokenCurrency.burn(numTokens.rawValue);
  }

  function repay(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory numTokens
  ) external {
    require(
      numTokens.isLessThanOrEqual(positionData.tokensOutstanding),
      'Invalid token amount'
    );

    FixedPoint.Unsigned memory newTokenCount =
      positionData.tokensOutstanding.sub(numTokens);
    require(
      newTokenCount.isGreaterThanOrEqual(positionManagerData.minSponsorTokens),
      'Below minimum sponsor position'
    );
    positionData.tokensOutstanding = newTokenCount;

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(numTokens);

    emit Repay(msg.sender, numTokens.rawValue, newTokenCount.rawValue);

    positionManagerData.tokenCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      numTokens.rawValue
    );
    positionManagerData.tokenCurrency.burn(numTokens.rawValue);
  }

  function settleEmergencyShutdown(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FeePayerParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    if (
      positionManagerData.emergencyShutdownPrice.isEqual(
        FixedPoint.fromUnscaledUint(0)
      )
    ) {
      FixedPoint.Unsigned memory oraclePrice =
        positionManagerData._getOracleEmergencyShutdownPrice(feePayerData);
      positionManagerData.emergencyShutdownPrice = oraclePrice
        ._decimalsScalingFactor(feePayerData);
    }

    FixedPoint.Unsigned memory tokensToRedeem =
      FixedPoint.Unsigned(
        positionManagerData.tokenCurrency.balanceOf(msg.sender)
      );

    FixedPoint.Unsigned memory totalRedeemableCollateral =
      tokensToRedeem.mul(positionManagerData.emergencyShutdownPrice);

    if (
      positionData
        .rawCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .isGreaterThan(0)
    ) {
      FixedPoint.Unsigned memory tokenDebtValueInCollateral =
        positionData.tokensOutstanding.mul(
          positionManagerData.emergencyShutdownPrice
        );
      FixedPoint.Unsigned memory positionCollateral =
        positionData.rawCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        );

      FixedPoint.Unsigned memory positionRedeemableCollateral =
        tokenDebtValueInCollateral.isLessThan(positionCollateral)
          ? positionCollateral.sub(tokenDebtValueInCollateral)
          : FixedPoint.Unsigned(0);

      totalRedeemableCollateral = totalRedeemableCollateral.add(
        positionRedeemableCollateral
      );

      PerpetualPositionManagerPoolParty(address(this)).deleteSponsorPosition(
        msg.sender
      );
      emit EndedSponsorPosition(msg.sender);
    }

    FixedPoint.Unsigned memory payout =
      FixedPoint.min(
        globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        ),
        totalRedeemableCollateral
      );

    amountWithdrawn = globalPositionData
      .rawTotalPositionCollateral
      .removeCollateral(payout, feePayerData.cumulativeFeeMultiplier);
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(tokensToRedeem);

    emit SettleEmergencyShutdown(
      msg.sender,
      amountWithdrawn.rawValue,
      tokensToRedeem.rawValue
    );

    feePayerData.collateralCurrency.safeTransfer(
      msg.sender,
      amountWithdrawn.rawValue
    );
    positionManagerData.tokenCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      tokensToRedeem.rawValue
    );
    positionManagerData.tokenCurrency.burn(tokensToRedeem.rawValue);
  }

  function trimExcess(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    IERC20 token,
    FixedPoint.Unsigned memory pfcAmount,
    FeePayerParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory amount) {
    FixedPoint.Unsigned memory balance =
      FixedPoint.Unsigned(token.balanceOf(address(this)));
    if (address(token) == address(feePayerData.collateralCurrency)) {
      amount = balance.sub(pfcAmount);
    } else {
      amount = balance;
    }
    token.safeTransfer(
      positionManagerData.excessTokenBeneficiary,
      amount.rawValue
    );
  }

  function requestOraclePrice(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    uint256 requestedTime,
    FeePayerParty.FeePayerData storage feePayerData
  ) external {
    feePayerData._getOracle().requestPrice(
      positionManagerData.priceIdentifier,
      requestedTime
    );
  }

  function reduceSponsorPosition(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory tokensToRemove,
    FixedPoint.Unsigned memory collateralToRemove,
    FixedPoint.Unsigned memory withdrawalAmountToRemove,
    FeePayerParty.FeePayerData storage feePayerData,
    address sponsor
  ) external {
    if (
      tokensToRemove.isEqual(positionData.tokensOutstanding) &&
      positionData
        .rawCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .isEqual(collateralToRemove)
    ) {
      positionData._deleteSponsorPosition(
        globalPositionData,
        feePayerData,
        sponsor
      );
      return;
    }

    positionData._decrementCollateralBalances(
      globalPositionData,
      collateralToRemove,
      feePayerData
    );

    positionData.tokensOutstanding = positionData.tokensOutstanding.sub(
      tokensToRemove
    );
    require(
      positionData.tokensOutstanding.isGreaterThanOrEqual(
        positionManagerData.minSponsorTokens
      ),
      'Below minimum sponsor position'
    );

    positionData.withdrawalRequestAmount = positionData
      .withdrawalRequestAmount
      .sub(withdrawalAmountToRemove);

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(tokensToRemove);
  }

  function getOraclePrice(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    uint256 requestedTime,
    FeePayerParty.FeePayerData storage feePayerData
  ) external view returns (FixedPoint.Unsigned memory price) {
    return _getOraclePrice(positionManagerData, requestedTime, feePayerData);
  }

  function decimalsScalingFactor(
    FixedPoint.Unsigned memory oraclePrice,
    FeePayerParty.FeePayerData storage feePayerData
  ) external view returns (FixedPoint.Unsigned memory scaledPrice) {
    return _decimalsScalingFactor(oraclePrice, feePayerData);
  }

  function _incrementCollateralBalances(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerParty.FeePayerData memory feePayerData
  ) internal returns (FixedPoint.Unsigned memory) {
    positionData.rawCollateral.addCollateral(
      collateralAmount,
      feePayerData.cumulativeFeeMultiplier
    );
    return
      globalPositionData.rawTotalPositionCollateral.addCollateral(
        collateralAmount,
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function _decrementCollateralBalances(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal returns (FixedPoint.Unsigned memory) {
    positionData.rawCollateral.removeCollateral(
      collateralAmount,
      feePayerData.cumulativeFeeMultiplier
    );
    return
      globalPositionData.rawTotalPositionCollateral.removeCollateral(
        collateralAmount,
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function _decrementCollateralBalancesCheckGCR(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal returns (FixedPoint.Unsigned memory) {
    positionData.rawCollateral.removeCollateral(
      collateralAmount,
      feePayerData.cumulativeFeeMultiplier
    );
    require(
      _checkPositionCollateralization(
        positionData,
        globalPositionData,
        feePayerData
      ),
      'CR below GCR'
    );
    return
      globalPositionData.rawTotalPositionCollateral.removeCollateral(
        collateralAmount,
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function _resetWithdrawalRequest(
    PerpetualPositionManagerPoolParty.PositionData storage positionData
  ) internal {
    positionData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
    positionData.withdrawalRequestPassTimestamp = 0;
  }

  function _deleteSponsorPosition(
    PerpetualPositionManagerPoolParty.PositionData storage positionToLiquidate,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FeePayerParty.FeePayerData storage feePayerData,
    address sponsor
  ) internal returns (FixedPoint.Unsigned memory) {
    FixedPoint.Unsigned memory startingGlobalCollateral =
      globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );

    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(positionToLiquidate.rawCollateral);
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(positionToLiquidate.tokensOutstanding);

    PerpetualPositionManagerPoolParty(address(this)).deleteSponsorPosition(
      sponsor
    );

    emit EndedSponsorPosition(sponsor);

    return
      startingGlobalCollateral.sub(
        globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      );
  }

  function _checkPositionCollateralization(
    PerpetualPositionManagerPoolParty.PositionData storage positionData,
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal view returns (bool) {
    return
      _checkCollateralization(
        globalPositionData,
        positionData.rawCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        ),
        positionData.tokensOutstanding,
        feePayerData
      );
  }

  function _checkCollateralization(
    PerpetualPositionManagerPoolParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory numTokens,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal view returns (bool) {
    FixedPoint.Unsigned memory global =
      _getCollateralizationRatio(
        globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        ),
        globalPositionData.totalTokensOutstanding
      );
    FixedPoint.Unsigned memory thisChange =
      _getCollateralizationRatio(collateral, numTokens);
    return !global.isGreaterThan(thisChange);
  }

  function _getOracleEmergencyShutdownPrice(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal view returns (FixedPoint.Unsigned memory) {
    return
      positionManagerData._getOraclePrice(
        positionManagerData.emergencyShutdownTimestamp,
        feePayerData
      );
  }

  function _getOraclePrice(
    PerpetualPositionManagerPoolParty.PositionManagerData
      storage positionManagerData,
    uint256 requestedTime,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal view returns (FixedPoint.Unsigned memory price) {
    OracleInterface oracle = feePayerData._getOracle();
    require(
      oracle.hasPrice(positionManagerData.priceIdentifier, requestedTime),
      'Unresolved oracle price'
    );
    int256 oraclePrice =
      oracle.getPrice(positionManagerData.priceIdentifier, requestedTime);

    if (oraclePrice < 0) {
      oraclePrice = 0;
    }
    return FixedPoint.Unsigned(uint256(oraclePrice));
  }

  function _getOracle(FeePayerParty.FeePayerData storage feePayerData)
    internal
    view
    returns (OracleInterface)
  {
    return
      OracleInterface(
        feePayerData.finder.getImplementationAddress(OracleInterfaces.Oracle)
      );
  }

  function _decimalsScalingFactor(
    FixedPoint.Unsigned memory oraclePrice,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal view returns (FixedPoint.Unsigned memory scaledPrice) {
    uint8 collateralDecimalsNumber =
      IERC20Standard(address(feePayerData.collateralCurrency)).decimals();
    scaledPrice = oraclePrice.div(
      (10**(uint256(18)).sub(collateralDecimalsNumber))
    );
  }

  function _getCollateralizationRatio(
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory numTokens
  ) internal pure returns (FixedPoint.Unsigned memory ratio) {
    return
      numTokens.isLessThanOrEqual(0)
        ? FixedPoint.fromUnscaledUint(0)
        : collateral.div(numTokens);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import {ERC20} from '../../../../@openzeppelin/contracts/token/ERC20/ERC20.sol';

abstract contract MintableBurnableIERC20 is ERC20 {
  function burn(uint256 value) external virtual;

  function mint(address to, uint256 value) external virtual returns (bool);

  function addMinter(address account) external virtual;

  function addBurner(address account) external virtual;

  function addAdmin(address account) external virtual;

  function addAdminAndMinterAndBurner(address account) external virtual;

  function renounceMinter() external virtual;

  function renounceBurner() external virtual;

  function renounceAdmin() external virtual;

  function renounceAdminAndMinterAndBurner() external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 interface that includes the decimals read only method.
 */
interface IERC20Standard is IERC20 {
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5,05`
     * (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei. This is the value
     * {ERC20} uses, unless {_setupDecimals} is called.
     *
     * NOTE: This information is only used for _display_ purposes: it in no way affects any of the arithmetic
     * of the contract, including {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     */
    function requestPrice(bytes32 identifier, uint256 time) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(bytes32 identifier, uint256 time) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(bytes32 identifier, uint256 time) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../../../../../@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../../@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  StoreInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/StoreInterface.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {FeePayerParty} from './FeePayerParty.sol';

library FeePayerPartyLib {
  using FixedPoint for FixedPoint.Unsigned;
  using FeePayerPartyLib for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;

  event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
  event FinalFeesPaid(uint256 indexed amount);

  function payRegularFees(
    FeePayerParty.FeePayerData storage feePayerData,
    StoreInterface store,
    uint256 time,
    FixedPoint.Unsigned memory collateralPool
  ) external returns (FixedPoint.Unsigned memory totalPaid) {
    if (collateralPool.isEqual(0)) {
      feePayerData.lastPaymentTime = time;
      return totalPaid;
    }

    if (feePayerData.lastPaymentTime == time) {
      return totalPaid;
    }

    FixedPoint.Unsigned memory regularFee;
    FixedPoint.Unsigned memory latePenalty;

    (regularFee, latePenalty) = store.computeRegularFee(
      feePayerData.lastPaymentTime,
      time,
      collateralPool
    );
    feePayerData.lastPaymentTime = time;

    totalPaid = regularFee.add(latePenalty);
    if (totalPaid.isEqual(0)) {
      return totalPaid;
    }

    if (totalPaid.isGreaterThan(collateralPool)) {
      FixedPoint.Unsigned memory deficit = totalPaid.sub(collateralPool);
      FixedPoint.Unsigned memory latePenaltyReduction =
        FixedPoint.min(latePenalty, deficit);
      latePenalty = latePenalty.sub(latePenaltyReduction);
      deficit = deficit.sub(latePenaltyReduction);
      regularFee = regularFee.sub(FixedPoint.min(regularFee, deficit));
      totalPaid = collateralPool;
    }

    emit RegularFeesPaid(regularFee.rawValue, latePenalty.rawValue);

    feePayerData.cumulativeFeeMultiplier._adjustCumulativeFeeMultiplier(
      totalPaid,
      collateralPool
    );

    if (regularFee.isGreaterThan(0)) {
      feePayerData.collateralCurrency.safeIncreaseAllowance(
        address(store),
        regularFee.rawValue
      );
      store.payOracleFeesErc20(
        address(feePayerData.collateralCurrency),
        regularFee
      );
    }

    if (latePenalty.isGreaterThan(0)) {
      feePayerData.collateralCurrency.safeTransfer(
        msg.sender,
        latePenalty.rawValue
      );
    }
    return totalPaid;
  }

  function payFinalFees(
    FeePayerParty.FeePayerData storage feePayerData,
    StoreInterface store,
    address payer,
    FixedPoint.Unsigned memory amount
  ) external {
    if (amount.isEqual(0)) {
      return;
    }

    feePayerData.collateralCurrency.safeTransferFrom(
      payer,
      address(this),
      amount.rawValue
    );

    emit FinalFeesPaid(amount.rawValue);

    feePayerData.collateralCurrency.safeIncreaseAllowance(
      address(store),
      amount.rawValue
    );
    store.payOracleFeesErc20(address(feePayerData.collateralCurrency), amount);
  }

  function getFeeAdjustedCollateral(
    FixedPoint.Unsigned memory rawCollateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external pure returns (FixedPoint.Unsigned memory collateral) {
    return rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier);
  }

  function removeCollateral(
    FixedPoint.Unsigned storage rawCollateral,
    FixedPoint.Unsigned memory collateralToRemove,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external returns (FixedPoint.Unsigned memory removedCollateral) {
    FixedPoint.Unsigned memory initialBalance =
      rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier);
    FixedPoint.Unsigned memory adjustedCollateral =
      collateralToRemove._convertToRawCollateral(cumulativeFeeMultiplier);
    rawCollateral.rawValue = rawCollateral.sub(adjustedCollateral).rawValue;
    removedCollateral = initialBalance.sub(
      rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier)
    );
  }

  function addCollateral(
    FixedPoint.Unsigned storage rawCollateral,
    FixedPoint.Unsigned memory collateralToAdd,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external returns (FixedPoint.Unsigned memory addedCollateral) {
    FixedPoint.Unsigned memory initialBalance =
      rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier);
    FixedPoint.Unsigned memory adjustedCollateral =
      collateralToAdd._convertToRawCollateral(cumulativeFeeMultiplier);
    rawCollateral.rawValue = rawCollateral.add(adjustedCollateral).rawValue;
    addedCollateral = rawCollateral
      ._getFeeAdjustedCollateral(cumulativeFeeMultiplier)
      .sub(initialBalance);
  }

  function convertToRawCollateral(
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external pure returns (FixedPoint.Unsigned memory rawCollateral) {
    return collateral._convertToRawCollateral(cumulativeFeeMultiplier);
  }

  function _adjustCumulativeFeeMultiplier(
    FixedPoint.Unsigned storage cumulativeFeeMultiplier,
    FixedPoint.Unsigned memory amount,
    FixedPoint.Unsigned memory currentPfc
  ) internal {
    FixedPoint.Unsigned memory effectiveFee = amount.divCeil(currentPfc);
    cumulativeFeeMultiplier.rawValue = cumulativeFeeMultiplier
      .mul(FixedPoint.fromUnscaledUint(1).sub(effectiveFee))
      .rawValue;
  }

  function _getFeeAdjustedCollateral(
    FixedPoint.Unsigned memory rawCollateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) internal pure returns (FixedPoint.Unsigned memory collateral) {
    return rawCollateral.mul(cumulativeFeeMultiplier);
  }

  function _convertToRawCollateral(
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) internal pure returns (FixedPoint.Unsigned memory rawCollateral) {
    return collateral.div(cumulativeFeeMultiplier);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  MintableBurnableIERC20
} from '../common/interfaces/MintableBurnableIERC20.sol';
import {
  OracleInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/OracleInterface.sol';
import {
  IdentifierWhitelistInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/IdentifierWhitelistInterface.sol';
import {
  AdministrateeInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/AdministrateeInterface.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  IDerivativeDeployment
} from '../common/interfaces/IDerivativeDeployment.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  OracleInterfaces
} from '../../../@jarvis-network/uma-core/contracts/oracle/implementation/Constants.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {
  PerpetualPositionManagerPoolPartyLib
} from './PerpetualPositionManagerPoolPartyLib.sol';
import {
  AccessControl
} from '../../../@openzeppelin/contracts/access/AccessControl.sol';
import {
  AddressWhitelist
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/AddressWhitelist.sol';
import {FeePayerParty} from '../common/FeePayerParty.sol';

contract PerpetualPositionManagerPoolParty is
  IDerivativeDeployment,
  AccessControl,
  FeePayerParty
{
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using PerpetualPositionManagerPoolPartyLib for PositionData;
  using PerpetualPositionManagerPoolPartyLib for PositionManagerData;

  bytes32 public constant POOL_ROLE = keccak256('Pool');

  struct Roles {
    address[] admins;
    address[] pools;
  }

  struct PositionManagerParams {
    uint256 withdrawalLiveness;
    address collateralAddress;
    address tokenAddress;
    address finderAddress;
    bytes32 priceFeedIdentifier;
    FixedPoint.Unsigned minSponsorTokens;
    address timerAddress;
    address excessTokenBeneficiary;
    ISynthereumFinder synthereumFinder;
  }

  struct PositionData {
    FixedPoint.Unsigned tokensOutstanding;
    uint256 withdrawalRequestPassTimestamp;
    FixedPoint.Unsigned withdrawalRequestAmount;
    FixedPoint.Unsigned rawCollateral;
  }

  struct GlobalPositionData {
    FixedPoint.Unsigned totalTokensOutstanding;
    FixedPoint.Unsigned rawTotalPositionCollateral;
  }

  struct PositionManagerData {
    ISynthereumFinder synthereumFinder;
    MintableBurnableIERC20 tokenCurrency;
    bytes32 priceIdentifier;
    uint256 withdrawalLiveness;
    FixedPoint.Unsigned minSponsorTokens;
    FixedPoint.Unsigned emergencyShutdownPrice;
    uint256 emergencyShutdownTimestamp;
    address excessTokenBeneficiary;
  }

  mapping(address => PositionData) public positions;

  GlobalPositionData public globalPositionData;

  PositionManagerData public positionManagerData;

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event RequestWithdrawal(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalExecuted(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalCanceled(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );
  event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  modifier onlyPool() {
    require(hasRole(POOL_ROLE, msg.sender), 'Sender must be a pool');
    _;
  }

  modifier onlyCollateralizedPosition(address sponsor) {
    _onlyCollateralizedPosition(sponsor);
    _;
  }

  modifier notEmergencyShutdown() {
    _notEmergencyShutdown();
    _;
  }

  modifier isEmergencyShutdown() {
    _isEmergencyShutdown();
    _;
  }

  modifier noPendingWithdrawal(address sponsor) {
    _positionHasNoPendingWithdrawal(sponsor);
    _;
  }

  constructor(
    PositionManagerParams memory _positionManagerData,
    Roles memory _roles
  )
    public
    FeePayerParty(
      _positionManagerData.collateralAddress,
      _positionManagerData.finderAddress,
      _positionManagerData.timerAddress
    )
    nonReentrant()
  {
    require(
      _getIdentifierWhitelist().isIdentifierSupported(
        _positionManagerData.priceFeedIdentifier
      ),
      'Unsupported price identifier'
    );
    require(
      _getCollateralWhitelist().isOnWhitelist(
        _positionManagerData.collateralAddress
      ),
      'Collateral not whitelisted'
    );
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(POOL_ROLE, DEFAULT_ADMIN_ROLE);
    for (uint256 j = 0; j < _roles.admins.length; j++) {
      _setupRole(DEFAULT_ADMIN_ROLE, _roles.admins[j]);
    }
    for (uint256 j = 0; j < _roles.pools.length; j++) {
      _setupRole(POOL_ROLE, _roles.pools[j]);
    }
    positionManagerData.synthereumFinder = _positionManagerData
      .synthereumFinder;
    positionManagerData.withdrawalLiveness = _positionManagerData
      .withdrawalLiveness;
    positionManagerData.tokenCurrency = MintableBurnableIERC20(
      _positionManagerData.tokenAddress
    );
    positionManagerData.minSponsorTokens = _positionManagerData
      .minSponsorTokens;
    positionManagerData.priceIdentifier = _positionManagerData
      .priceFeedIdentifier;
    positionManagerData.excessTokenBeneficiary = _positionManagerData
      .excessTokenBeneficiary;
  }

  function deposit(FixedPoint.Unsigned memory collateralAmount) external {
    depositTo(msg.sender, collateralAmount);
  }

  function withdraw(FixedPoint.Unsigned memory collateralAmount)
    external
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    amountWithdrawn = positionData.withdraw(
      globalPositionData,
      collateralAmount,
      feePayerData
    );
  }

  function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
    external
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    nonReentrant()
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.requestWithdrawal(
      positionManagerData,
      collateralAmount,
      actualTime,
      feePayerData
    );
  }

  function withdrawPassedRequest()
    external
    onlyPool()
    notEmergencyShutdown()
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    amountWithdrawn = positionData.withdrawPassedRequest(
      globalPositionData,
      actualTime,
      feePayerData
    );
  }

  function cancelWithdrawal()
    external
    onlyPool()
    notEmergencyShutdown()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.cancelWithdrawal();
  }

  function create(
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external onlyPool() notEmergencyShutdown() fees() nonReentrant() {
    PositionData storage positionData = positions[msg.sender];

    positionData.create(
      globalPositionData,
      positionManagerData,
      collateralAmount,
      numTokens,
      feePayerData
    );
  }

  function redeem(FixedPoint.Unsigned memory numTokens)
    external
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    amountWithdrawn = positionData.redeeem(
      globalPositionData,
      positionManagerData,
      numTokens,
      feePayerData,
      msg.sender
    );
  }

  function repay(FixedPoint.Unsigned memory numTokens)
    external
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.repay(globalPositionData, positionManagerData, numTokens);
  }

  function settleEmergencyShutdown()
    external
    onlyPool()
    isEmergencyShutdown()
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    PositionData storage positionData = positions[msg.sender];
    amountWithdrawn = positionData.settleEmergencyShutdown(
      globalPositionData,
      positionManagerData,
      feePayerData
    );
  }

  function emergencyShutdown()
    external
    override
    notEmergencyShutdown()
    nonReentrant()
  {
    require(
      msg.sender ==
        positionManagerData.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.Manager
        ) ||
        msg.sender == _getFinancialContractsAdminAddress(),
      'Caller must be a Synthereum manager or the UMA governor'
    );
    positionManagerData.emergencyShutdownTimestamp = getCurrentTime();
    positionManagerData.requestOraclePrice(
      positionManagerData.emergencyShutdownTimestamp,
      feePayerData
    );
    emit EmergencyShutdown(
      msg.sender,
      positionManagerData.emergencyShutdownTimestamp
    );
  }

  function remargin() external override {
    return;
  }

  function trimExcess(IERC20 token)
    external
    nonReentrant()
    returns (FixedPoint.Unsigned memory amount)
  {
    FixedPoint.Unsigned memory pfcAmount = _pfc();
    amount = positionManagerData.trimExcess(token, pfcAmount, feePayerData);
  }

  function deleteSponsorPosition(address sponsor) external onlyThisContract {
    delete positions[sponsor];
  }

  function getCollateral(address sponsor)
    external
    view
    nonReentrantView()
    returns (FixedPoint.Unsigned memory collateralAmount)
  {
    collateralAmount = positions[sponsor]
      .rawCollateral
      .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier);
  }

  function synthereumFinder() external view returns (ISynthereumFinder finder) {
    finder = positionManagerData.synthereumFinder;
  }

  function tokenCurrency() external view override returns (IERC20 token) {
    token = positionManagerData.tokenCurrency;
  }

  function totalPositionCollateral()
    external
    view
    nonReentrantView()
    returns (FixedPoint.Unsigned memory totalCollateral)
  {
    totalCollateral = globalPositionData
      .rawTotalPositionCollateral
      .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier);
  }

  function emergencyShutdownPrice()
    external
    view
    isEmergencyShutdown()
    returns (FixedPoint.Unsigned memory)
  {
    return positionManagerData.emergencyShutdownPrice;
  }

  function getAdminMembers() external view override returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(DEFAULT_ADMIN_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  function getPoolMembers() external view override returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(POOL_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(POOL_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  function depositTo(
    address sponsor,
    FixedPoint.Unsigned memory collateralAmount
  )
    public
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(sponsor)
    fees()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(sponsor);

    positionData.depositTo(
      globalPositionData,
      collateralAmount,
      feePayerData,
      sponsor
    );
  }

  function collateralCurrency()
    public
    view
    override(IDerivativeDeployment, FeePayerParty)
    returns (IERC20 collateral)
  {
    collateral = FeePayerParty.collateralCurrency();
  }

  function _pfc()
    internal
    view
    virtual
    override
    returns (FixedPoint.Unsigned memory)
  {
    return
      globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function _getPositionData(address sponsor)
    internal
    view
    onlyCollateralizedPosition(sponsor)
    returns (PositionData storage)
  {
    return positions[sponsor];
  }

  function _getIdentifierWhitelist()
    internal
    view
    returns (IdentifierWhitelistInterface)
  {
    return
      IdentifierWhitelistInterface(
        feePayerData.finder.getImplementationAddress(
          OracleInterfaces.IdentifierWhitelist
        )
      );
  }

  function _getCollateralWhitelist() internal view returns (AddressWhitelist) {
    return
      AddressWhitelist(
        feePayerData.finder.getImplementationAddress(
          OracleInterfaces.CollateralWhitelist
        )
      );
  }

  function _onlyCollateralizedPosition(address sponsor) internal view {
    require(
      positions[sponsor]
        .rawCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .isGreaterThan(0),
      'Position has no collateral'
    );
  }

  function _notEmergencyShutdown() internal view {
    require(
      positionManagerData.emergencyShutdownTimestamp == 0,
      'Contract emergency shutdown'
    );
  }

  function _isEmergencyShutdown() internal view {
    require(
      positionManagerData.emergencyShutdownTimestamp != 0,
      'Contract not emergency shutdown'
    );
  }

  function _positionHasNoPendingWithdrawal(address sponsor) internal view {
    require(
      _getPositionData(sponsor).withdrawalRequestPassTimestamp == 0,
      'Pending withdrawal'
    );
  }

  function _getFinancialContractsAdminAddress()
    internal
    view
    returns (address)
  {
    return
      feePayerData.finder.getImplementationAddress(
        OracleInterfaces.FinancialContractsAdmin
      );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  AdministrateeInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/AdministrateeInterface.sol';
import {
  StoreInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/StoreInterface.sol';
import {
  FinderInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/FinderInterface.sol';
import {
  OracleInterfaces
} from '../../../@jarvis-network/uma-core/contracts/oracle/implementation/Constants.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {FeePayerPartyLib} from './FeePayerPartyLib.sol';
import {
  Testable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Testable.sol';
import {
  Lockable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

abstract contract FeePayerParty is AdministrateeInterface, Testable, Lockable {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FeePayerPartyLib for FixedPoint.Unsigned;
  using FeePayerPartyLib for FeePayerData;
  using SafeERC20 for IERC20;

  struct FeePayerData {
    IERC20 collateralCurrency;
    FinderInterface finder;
    uint256 lastPaymentTime;
    FixedPoint.Unsigned cumulativeFeeMultiplier;
  }

  FeePayerData public feePayerData;

  event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
  event FinalFeesPaid(uint256 indexed amount);

  modifier fees {
    payRegularFees();
    _;
  }
  modifier onlyThisContract {
    require(msg.sender == address(this), 'Caller is not this contract');
    _;
  }

  constructor(
    address _collateralAddress,
    address _finderAddress,
    address _timerAddress
  ) public Testable(_timerAddress) {
    feePayerData.collateralCurrency = IERC20(_collateralAddress);
    feePayerData.finder = FinderInterface(_finderAddress);
    feePayerData.lastPaymentTime = getCurrentTime();
    feePayerData.cumulativeFeeMultiplier = FixedPoint.fromUnscaledUint(1);
  }

  function payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    external
    onlyThisContract
  {
    _payFinalFees(payer, amount);
  }

  function collateralCurrency()
    public
    view
    virtual
    nonReentrantView()
    returns (IERC20)
  {
    return feePayerData.collateralCurrency;
  }

  function payRegularFees()
    public
    nonReentrant()
    returns (FixedPoint.Unsigned memory totalPaid)
  {
    StoreInterface store = _getStore();
    uint256 time = getCurrentTime();
    FixedPoint.Unsigned memory collateralPool = _pfc();
    totalPaid = feePayerData.payRegularFees(store, time, collateralPool);
    return totalPaid;
  }

  function pfc()
    public
    view
    override
    nonReentrantView()
    returns (FixedPoint.Unsigned memory)
  {
    return _pfc();
  }

  function _payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    internal
  {
    StoreInterface store = _getStore();
    feePayerData.payFinalFees(store, payer, amount);
  }

  function _pfc() internal view virtual returns (FixedPoint.Unsigned memory);

  function _getStore() internal view returns (StoreInterface) {
    return
      StoreInterface(
        feePayerData.finder.getImplementationAddress(OracleInterfaces.Store)
      );
  }

  function _computeFinalFees()
    internal
    view
    returns (FixedPoint.Unsigned memory finalFees)
  {
    StoreInterface store = _getStore();
    return store.computeFinalFee(address(feePayerData.collateralCurrency));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that allows financial contracts to pay oracle fees for their use of the system.
 */
interface StoreInterface {
    /**
     * @notice Pays Oracle fees in ETH to the store.
     * @dev To be used by contracts whose margin currency is ETH.
     */
    function payOracleFees() external payable;

    /**
     * @notice Pays oracle fees in the margin currency, erc20Address, to the store.
     * @dev To be used if the margin currency is an ERC20 token rather than ETH.
     * @param erc20Address address of the ERC20 token used to pay the fee.
     * @param amount number of tokens to transfer. An approval for at least this amount must exist.
     */
    function payOracleFeesErc20(address erc20Address, FixedPoint.Unsigned calldata amount) external;

    /**
     * @notice Computes the regular oracle fees that a contract should pay for a period.
     * @param startTime defines the beginning time from which the fee is paid.
     * @param endTime end time until which the fee is paid.
     * @param pfc "profit from corruption", or the maximum amount of margin currency that a
     * token sponsor could extract from the contract through corrupting the price feed in their favor.
     * @return regularFee amount owed for the duration from start to end time for the given pfc.
     * @return latePenalty for paying the fee after the deadline.
     */
    function computeRegularFee(
        uint256 startTime,
        uint256 endTime,
        FixedPoint.Unsigned calldata pfc
    ) external view returns (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty);

    /**
     * @notice Computes the final oracle fees that a contract should pay at settlement.
     * @param currency token used to pay the final fee.
     * @return finalFee amount due.
     */
    function computeFinalFee(address currency) external view returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that all financial contracts expose to the admin.
 */
interface AdministrateeInterface {
    /**
     * @notice Initiates the shutdown process, in case of an emergency.
     */
    function emergencyShutdown() external;

    /**
     * @notice A core contract method called independently or as a part of other financial contract transactions.
     * @dev It pays fees and moves money between margin accounts to make sure they reflect the NAV of the contract.
     */
    function remargin() external;

    /**
     * @notice Gets the current profit from corruption for this contract in terms of the collateral currency.
     * @dev This is equivalent to the collateral pool available from which to pay fees. Therefore, derived contracts are
     * expected to implement this so that pay-fee methods can correctly compute the owed fees as a % of PfC.
     * @return pfc value for equal to the current profit from corruption denominated in collateral currency.
     */
    function pfc() external view returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run on the test network, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) internal {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return now; // solhint-disable-line not-rely-on-time
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being re-entered.
    // Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() public {
        currentTime = now; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStandardERC20 is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface ISynthereumFinder {
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDerivativeDeployment {
  function collateralCurrency() external view returns (IERC20 collateral);

  function tokenCurrency() external view returns (IERC20 syntheticCurrency);

  function getAdminMembers() external view returns (address[] memory);

  function getPoolMembers() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant SelfMintingController = 'SelfMintingController';
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../../../../../@openzeppelin/contracts/access/Ownable.sol";
import "./Lockable.sol";

/**
 * @title A contract to track a whitelist of addresses.
 */
contract AddressWhitelist is Ownable, Lockable {
    enum Status { None, In, Out }
    mapping(address => Status) public whitelist;

    address[] public whitelistIndices;

    event AddedToWhitelist(address indexed addedAddress);
    event RemovedFromWhitelist(address indexed removedAddress);

    /**
     * @notice Adds an address to the whitelist.
     * @param newElement the new address to add.
     */
    function addToWhitelist(address newElement) external nonReentrant() onlyOwner {
        // Ignore if address is already included
        if (whitelist[newElement] == Status.In) {
            return;
        }

        // Only append new addresses to the array, never a duplicate
        if (whitelist[newElement] == Status.None) {
            whitelistIndices.push(newElement);
        }

        whitelist[newElement] = Status.In;

        emit AddedToWhitelist(newElement);
    }

    /**
     * @notice Removes an address from the whitelist.
     * @param elementToRemove the existing address to remove.
     */
    function removeFromWhitelist(address elementToRemove) external nonReentrant() onlyOwner {
        if (whitelist[elementToRemove] != Status.Out) {
            whitelist[elementToRemove] = Status.Out;
            emit RemovedFromWhitelist(elementToRemove);
        }
    }

    /**
     * @notice Checks whether an address is on the whitelist.
     * @param elementToCheck the address to check.
     * @return True if `elementToCheck` is on the whitelist, or False.
     */
    function isOnWhitelist(address elementToCheck) external view nonReentrantView() returns (bool) {
        return whitelist[elementToCheck] == Status.In;
    }

    /**
     * @notice Gets all addresses that are currently included in the whitelist.
     * @dev Note: This method skips over, but still iterates through addresses. It is possible for this call to run out
     * of gas if a large number of addresses have been removed. To reduce the likelihood of this unlikely scenario, we
     * can modify the implementation so that when addresses are removed, the last addresses in the array is moved to
     * the empty index.
     * @return activeWhitelist the list of addresses on the whitelist.
     */
    function getWhitelist() external view nonReentrantView() returns (address[] memory activeWhitelist) {
        // Determine size of whitelist first
        uint256 activeCount = 0;
        for (uint256 i = 0; i < whitelistIndices.length; i++) {
            if (whitelist[whitelistIndices[i]] == Status.In) {
                activeCount++;
            }
        }

        // Populate whitelist
        activeWhitelist = new address[](activeCount);
        activeCount = 0;
        for (uint256 i = 0; i < whitelistIndices.length; i++) {
            address addr = whitelistIndices[i];
            if (whitelist[addr] == Status.In) {
                activeWhitelist[activeCount] = addr;
                activeCount++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {
    "deploy/contracts/derivative/common/FeePayerPartyLib.sol": {
      "FeePayerPartyLib": "0x5b4c09b6eef425db4c25e3506a253a9bc2a11f13"
    }
  }
}