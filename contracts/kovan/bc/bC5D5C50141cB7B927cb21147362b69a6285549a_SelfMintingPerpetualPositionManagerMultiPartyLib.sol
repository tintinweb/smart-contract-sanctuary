// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  IERC20Standard
} from '../../../../@jarvis-network/uma-core/contracts/common/interfaces/IERC20Standard.sol';
import {
  MintableBurnableIERC20
} from '../../common/interfaces/MintableBurnableIERC20.sol';
import {
  ISelfMintingController
} from '../../../core/interfaces/ISelfMintingController.sol';
import {SynthereumInterfaces} from '../../../core/Constants.sol';
import {
  OracleInterface
} from '../../../../@jarvis-network/uma-core/contracts/oracle/interfaces/OracleInterface.sol';
import {
  OracleInterfaces
} from '../../../../@jarvis-network/uma-core/contracts/oracle/implementation/Constants.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {SafeMath} from '../../../../@openzeppelin/contracts/math/SafeMath.sol';
import {
  SafeERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {FeePayerPartyLib} from '../../common/FeePayerPartyLib.sol';
import {FeePayerParty} from '../../common/FeePayerParty.sol';
import {
  SelfMintingPerpetualPositionManagerMultiParty
} from './SelfMintingPerpetualPositionManagerMultiParty.sol';

library SelfMintingPerpetualPositionManagerMultiPartyLib {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for SelfMintingPerpetualPositionManagerMultiParty.PositionData;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for FeePayerParty.FeePayerData;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for FixedPoint.Unsigned;
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
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount,
    uint256 feeAmount
  );
  event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  function depositTo(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
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

    checkDepositLimit(positionData, positionManagerData, feePayerData);

    emit Deposit(sponsor, collateralAmount.rawValue);

    feePayerData.collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      collateralAmount.rawValue
    );
  }

  function withdraw(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory feePercentage,
    FeePayerParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory feeAmount) {
    feeAmount = _checkAndCalculateDaoFee(
      globalPositionData,
      positionManagerData,
      numTokens,
      feePercentage,
      feePayerData
    );
    FixedPoint.Unsigned memory netCollateralAmount =
      collateralAmount.sub(feeAmount);
    require(
      (_checkCollateralization(
        globalPositionData,
        positionData
          .rawCollateral
          .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
          .add(netCollateralAmount),
        positionData.tokensOutstanding.add(numTokens),
        feePayerData
      ) ||
        _checkCollateralization(
          globalPositionData,
          netCollateralAmount,
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
      netCollateralAmount,
      feePayerData
    );

    positionData.tokensOutstanding = positionData.tokensOutstanding.add(
      numTokens
    );

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .add(numTokens);

    checkDepositLimit(positionData, positionManagerData, feePayerData);

    checkMintLimit(globalPositionData, positionManagerData);

    emit PositionCreated(
      msg.sender,
      collateralAmount.rawValue,
      numTokens.rawValue,
      feeAmount.rawValue
    );

    IERC20 collateralCurrency = feePayerData.collateralCurrency;

    collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      (collateralAmount).rawValue
    );

    collateralCurrency.safeTransfer(
      positionManagerData._getDaoFeeRecipient(),
      feeAmount.rawValue
    );

    positionManagerData.tokenCurrency.mint(msg.sender, numTokens.rawValue);
  }

  function redeeem(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory feePercentage,
    FeePayerParty.FeePayerData storage feePayerData,
    address sponsor
  )
    external
    returns (
      FixedPoint.Unsigned memory amountWithdrawn,
      FixedPoint.Unsigned memory feeAmount
    )
  {
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
    feeAmount = _checkAndCalculateDaoFee(
      globalPositionData,
      positionManagerData,
      numTokens,
      feePercentage,
      feePayerData
    );
    FixedPoint.Unsigned memory totAmountWithdrawn;
    if (positionData.tokensOutstanding.isEqual(numTokens)) {
      totAmountWithdrawn = positionData._deleteSponsorPosition(
        globalPositionData,
        feePayerData,
        sponsor
      );
    } else {
      totAmountWithdrawn = positionData._decrementCollateralBalances(
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

    amountWithdrawn = totAmountWithdrawn.sub(feeAmount);

    emit Redeem(
      msg.sender,
      amountWithdrawn.rawValue,
      numTokens.rawValue,
      feeAmount.rawValue
    );

    IERC20 collateralCurrency = feePayerData.collateralCurrency;

    {
      collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
      collateralCurrency.safeTransfer(
        positionManagerData._getDaoFeeRecipient(),
        feeAmount.rawValue
      );
      positionManagerData.tokenCurrency.safeTransferFrom(
        msg.sender,
        address(this),
        numTokens.rawValue
      );
      positionManagerData.tokenCurrency.burn(numTokens.rawValue);
    }
  }

  function repay(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory feePercentage,
    FeePayerParty.FeePayerData storage feePayerData
  ) external returns (FixedPoint.Unsigned memory feeAmount) {
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

    FixedPoint.Unsigned memory feeToWithdraw =
      _checkAndCalculateDaoFee(
        globalPositionData,
        positionManagerData,
        numTokens,
        feePercentage,
        feePayerData
      );

    positionData.tokensOutstanding = newTokenCount;

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(numTokens);

    feeAmount = positionData._decrementCollateralBalances(
      globalPositionData,
      feeToWithdraw,
      feePayerData
    );

    checkDepositLimit(positionData, positionManagerData, feePayerData);

    emit Repay(
      msg.sender,
      numTokens.rawValue,
      newTokenCount.rawValue,
      feeAmount.rawValue
    );

    feePayerData.collateralCurrency.safeTransfer(
      positionManagerData._getDaoFeeRecipient(),
      feeAmount.rawValue
    );

    positionManagerData.tokenCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      numTokens.rawValue
    );
    positionManagerData.tokenCurrency.burn(numTokens.rawValue);
  }

  function settleEmergencyShutdown(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
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

      SelfMintingPerpetualPositionManagerMultiParty(address(this))
        .deleteSponsorPosition(msg.sender);
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
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

  function calculateDaoFee(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory numTokens,
    FeePayerParty.FeePayerData storage feePayerData
  ) external view returns (FixedPoint.Unsigned memory) {
    return
      _calculateDaoFee(
        globalPositionData,
        numTokens,
        positionManagerData._getDaoFeePercentage(),
        feePayerData
      );
  }

  function daoFee(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData
  )
    external
    view
    returns (FixedPoint.Unsigned memory percentage, address recipient)
  {
    percentage = positionManagerData._getDaoFeePercentage();
    recipient = positionManagerData._getDaoFeeRecipient();
  }

  function capMintAmount(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData
  ) external view returns (FixedPoint.Unsigned memory capMint) {
    capMint = positionManagerData._getCapMintAmount();
  }

  function capDepositRatio(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData
  ) external view returns (FixedPoint.Unsigned memory capDeposit) {
    capDeposit = positionManagerData._getCapDepositRatio();
  }

  function _incrementCollateralBalances(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData
  ) internal {
    positionData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
    positionData.withdrawalRequestPassTimestamp = 0;
  }

  function _deleteSponsorPosition(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionToLiquidate,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
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

    SelfMintingPerpetualPositionManagerMultiParty(address(this))
      .deleteSponsorPosition(sponsor);

    emit EndedSponsorPosition(sponsor);

    return
      startingGlobalCollateral.sub(
        globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      );
  }

  function _checkPositionCollateralization(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
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
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
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

  function checkDepositLimit(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal view {
    require(
      _getCollateralizationRatio(
        positionData.rawCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        ),
        positionData
          .tokensOutstanding
      )
        .isLessThanOrEqual(positionManagerData._getCapDepositRatio()),
      'Position overcomes deposit limit'
    );
  }

  function checkMintLimit(
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData
  ) internal view {
    require(
      globalPositionData.totalTokensOutstanding.isLessThanOrEqual(
        positionManagerData._getCapMintAmount()
      ),
      'Total amount minted overcomes mint limit'
    );
  }

  function _checkAndCalculateDaoFee(
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory feePercentage,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal view returns (FixedPoint.Unsigned memory) {
    FixedPoint.Unsigned memory actualFeePercentage =
      positionManagerData._getDaoFeePercentage();
    require(
      actualFeePercentage.isLessThanOrEqual(feePercentage),
      'User fees are not enough for paying DAO'
    );
    return
      _calculateDaoFee(
        globalPositionData,
        numTokens,
        actualFeePercentage,
        feePayerData
      );
  }

  function _calculateDaoFee(
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory actualFeePercentage,
    FeePayerParty.FeePayerData storage feePayerData
  ) internal view returns (FixedPoint.Unsigned memory) {
    FixedPoint.Unsigned memory globalCollateralizationRatio =
      _getCollateralizationRatio(
        globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        ),
        globalPositionData.totalTokensOutstanding
      );
    return numTokens.mul(globalCollateralizationRatio).mul(actualFeePercentage);
  }

  function _getOracleEmergencyShutdownPrice(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
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
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
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

  function _getCapMintAmount(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory capMint) {
    capMint = FixedPoint.Unsigned(
      positionManagerData.getSelfMintingController().getCapMintAmount(
        address(this)
      )
    );
  }

  function _getCapDepositRatio(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory capDeposit) {
    capDeposit = FixedPoint.Unsigned(
      positionManagerData.getSelfMintingController().getCapDepositRatio(
        address(this)
      )
    );
  }

  function _getDaoFeePercentage(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory feePercentage) {
    feePercentage = FixedPoint.Unsigned(
      positionManagerData.getSelfMintingController().getDaoFeePercentage(
        address(this)
      )
    );
  }

  function _getDaoFeeRecipient(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData
  ) internal view returns (address recipient) {
    recipient = positionManagerData
      .getSelfMintingController()
      .getDaoFeeRecipient(address(this));
  }

  function getSelfMintingController(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData
  ) internal view returns (ISelfMintingController selfMintingController) {
    selfMintingController = ISelfMintingController(
      positionManagerData.synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.SelfMintingController
      )
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

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Standard is IERC20 {
  function decimals() external view returns (uint8);
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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISelfMintingController {
  struct DaoFee {
    uint256 feePercentage;
    address feeRecipient;
  }

  /**
   * @notice Allow to set capMintAmount on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param capMintAmounts Mint cap amounts for self-minting derivatives
   */
  function setCapMintAmount(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata capMintAmounts
  ) external;

  /**
   * @notice Allow to set capDepositRatio on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param capDepositRatios Deposit caps ratios for self-minting derivatives
   */
  function setCapDepositRatio(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata capDepositRatios
  ) external;

  /**
   * @notice Allow to set Dao fees on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param daoFees Dao fees for self-minting derivatives
   */
  function setDaoFee(
    address[] calldata selfMintingDerivatives,
    DaoFee[] calldata daoFees
  ) external;

  /**
   * @notice Allow to set Dao fee percentages on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param daoFeePercentages Dao fee percentages for self-minting derivatives
   */
  function setDaoFeePercentage(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata daoFeePercentages
  ) external;

  /**
   * @notice Allow to set Dao fee recipients on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param daoFeeRecipients Dao fee recipients for self-minting derivatives
   */
  function setDaoFeeRecipient(
    address[] calldata selfMintingDerivatives,
    address[] calldata daoFeeRecipients
  ) external;

  function getCapMintAmount(address selfMintingDerivative)
    external
    view
    returns (uint256 capMintAmount);

  function getCapDepositRatio(address selfMintingDerivative)
    external
    view
    returns (uint256 capDepositRatio);

  function getDaoFee(address selfMintingDerivative)
    external
    view
    returns (DaoFee memory daoFee);

  function getDaoFeePercentage(address selfMintingDerivative)
    external
    view
    returns (uint256 daoFeePercentage);

  function getDaoFeeRecipient(address selfMintingDerivative)
    external
    view
    returns (address recipient);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

abstract contract OracleInterface {
  function requestPrice(bytes32 identifier, uint256 time) public virtual;

  function hasPrice(bytes32 identifier, uint256 time)
    public
    view
    virtual
    returns (bool);

  function getPrice(bytes32 identifier, uint256 time)
    public
    view
    virtual
    returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

library OracleInterfaces {
  bytes32 public constant Oracle = 'Oracle';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant Store = 'Store';
  bytes32 public constant FinancialContractsAdmin = 'FinancialContractsAdmin';
  bytes32 public constant Registry = 'Registry';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant OptimisticOracle = 'OptimisticOracle';
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/math/SafeMath.sol';
import '../../../../../@openzeppelin/contracts/math/SignedSafeMath.sol';

library FixedPoint {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  uint256 private constant FP_SCALING_FACTOR = 10**18;

  struct Unsigned {
    uint256 rawValue;
  }

  function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
    return Unsigned(a.mul(FP_SCALING_FACTOR));
  }

  function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue == fromUnscaledUint(b).rawValue;
  }

  function isEqual(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue == b.rawValue;
  }

  function isGreaterThan(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue > b.rawValue;
  }

  function isGreaterThan(Unsigned memory a, uint256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue > fromUnscaledUint(b).rawValue;
  }

  function isGreaterThan(uint256 a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledUint(a).rawValue > b.rawValue;
  }

  function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue >= b.rawValue;
  }

  function isGreaterThanOrEqual(Unsigned memory a, uint256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue >= fromUnscaledUint(b).rawValue;
  }

  function isGreaterThanOrEqual(uint256 a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledUint(a).rawValue >= b.rawValue;
  }

  function isLessThan(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue < b.rawValue;
  }

  function isLessThan(Unsigned memory a, uint256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue < fromUnscaledUint(b).rawValue;
  }

  function isLessThan(uint256 a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledUint(a).rawValue < b.rawValue;
  }

  function isLessThanOrEqual(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue <= b.rawValue;
  }

  function isLessThanOrEqual(Unsigned memory a, uint256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue <= fromUnscaledUint(b).rawValue;
  }

  function isLessThanOrEqual(uint256 a, Unsigned memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledUint(a).rawValue <= b.rawValue;
  }

  function min(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return a.rawValue < b.rawValue ? a : b;
  }

  function max(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return a.rawValue > b.rawValue ? a : b;
  }

  function add(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.add(b.rawValue));
  }

  function add(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return add(a, fromUnscaledUint(b));
  }

  function sub(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.sub(b.rawValue));
  }

  function sub(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return sub(a, fromUnscaledUint(b));
  }

  function sub(uint256 a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return sub(fromUnscaledUint(a), b);
  }

  function mul(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
  }

  function mul(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.mul(b));
  }

  function mulCeil(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    uint256 mulRaw = a.rawValue.mul(b.rawValue);
    uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
    uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
    if (mod != 0) {
      return Unsigned(mulFloor.add(1));
    } else {
      return Unsigned(mulFloor);
    }
  }

  function mulCeil(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.mul(b));
  }

  function div(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
  }

  function div(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return Unsigned(a.rawValue.div(b));
  }

  function div(uint256 a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    return div(fromUnscaledUint(a), b);
  }

  function divCeil(Unsigned memory a, Unsigned memory b)
    internal
    pure
    returns (Unsigned memory)
  {
    uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
    uint256 divFloor = aScaled.div(b.rawValue);
    uint256 mod = aScaled.mod(b.rawValue);
    if (mod != 0) {
      return Unsigned(divFloor.add(1));
    } else {
      return Unsigned(divFloor);
    }
  }

  function divCeil(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory)
  {
    return divCeil(a, fromUnscaledUint(b));
  }

  function pow(Unsigned memory a, uint256 b)
    internal
    pure
    returns (Unsigned memory output)
  {
    output = fromUnscaledUint(1);
    for (uint256 i = 0; i < b; i = i.add(1)) {
      output = mul(output, a);
    }
  }

  int256 private constant SFP_SCALING_FACTOR = 10**18;

  struct Signed {
    int256 rawValue;
  }

  function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
    require(a.rawValue >= 0, 'Negative value provided');
    return Unsigned(uint256(a.rawValue));
  }

  function fromUnsigned(Unsigned memory a)
    internal
    pure
    returns (Signed memory)
  {
    require(a.rawValue <= uint256(type(int256).max), 'Unsigned too large');
    return Signed(int256(a.rawValue));
  }

  function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
    return Signed(a.mul(SFP_SCALING_FACTOR));
  }

  function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue == fromUnscaledInt(b).rawValue;
  }

  function isEqual(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue == b.rawValue;
  }

  function isGreaterThan(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue > b.rawValue;
  }

  function isGreaterThan(Signed memory a, int256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue > fromUnscaledInt(b).rawValue;
  }

  function isGreaterThan(int256 a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledInt(a).rawValue > b.rawValue;
  }

  function isGreaterThanOrEqual(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue >= b.rawValue;
  }

  function isGreaterThanOrEqual(Signed memory a, int256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue >= fromUnscaledInt(b).rawValue;
  }

  function isGreaterThanOrEqual(int256 a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledInt(a).rawValue >= b.rawValue;
  }

  function isLessThan(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue < b.rawValue;
  }

  function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue < fromUnscaledInt(b).rawValue;
  }

  function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue < b.rawValue;
  }

  function isLessThanOrEqual(Signed memory a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue <= b.rawValue;
  }

  function isLessThanOrEqual(Signed memory a, int256 b)
    internal
    pure
    returns (bool)
  {
    return a.rawValue <= fromUnscaledInt(b).rawValue;
  }

  function isLessThanOrEqual(int256 a, Signed memory b)
    internal
    pure
    returns (bool)
  {
    return fromUnscaledInt(a).rawValue <= b.rawValue;
  }

  function min(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return a.rawValue < b.rawValue ? a : b;
  }

  function max(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return a.rawValue > b.rawValue ? a : b;
  }

  function add(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.add(b.rawValue));
  }

  function add(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return add(a, fromUnscaledInt(b));
  }

  function sub(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.sub(b.rawValue));
  }

  function sub(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return sub(a, fromUnscaledInt(b));
  }

  function sub(int256 a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return sub(fromUnscaledInt(a), b);
  }

  function mul(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
  }

  function mul(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.mul(b));
  }

  function mulAwayFromZero(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    int256 mulRaw = a.rawValue.mul(b.rawValue);
    int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;

    int256 mod = mulRaw % SFP_SCALING_FACTOR;
    if (mod != 0) {
      bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
      int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
      return Signed(mulTowardsZero.add(valueToAdd));
    } else {
      return Signed(mulTowardsZero);
    }
  }

  function mulAwayFromZero(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.mul(b));
  }

  function div(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
  }

  function div(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return Signed(a.rawValue.div(b));
  }

  function div(int256 a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    return div(fromUnscaledInt(a), b);
  }

  function divAwayFromZero(Signed memory a, Signed memory b)
    internal
    pure
    returns (Signed memory)
  {
    int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
    int256 divTowardsZero = aScaled.div(b.rawValue);

    int256 mod = aScaled % b.rawValue;
    if (mod != 0) {
      bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
      int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
      return Signed(divTowardsZero.add(valueToAdd));
    } else {
      return Signed(divTowardsZero);
    }
  }

  function divAwayFromZero(Signed memory a, int256 b)
    internal
    pure
    returns (Signed memory)
  {
    return divAwayFromZero(a, fromUnscaledInt(b));
  }

  function pow(Signed memory a, uint256 b)
    internal
    pure
    returns (Signed memory output)
  {
    output = fromUnscaledInt(1);
    for (uint256 i = 0; i < b; i = i.add(1)) {
      output = mul(output, a);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import './IERC20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
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
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance =
      token.allowance(address(this), spender).sub(
        value,
        'SafeERC20: decreased allowance below zero'
      );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata =
      address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      require(
        abi.decode(returndata, (bool)),
        'SafeERC20: ERC20 operation did not succeed'
      );
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../../base/interfaces/IStandardERC20.sol';
import {
  MintableBurnableIERC20
} from '../../common/interfaces/MintableBurnableIERC20.sol';
import {
  IdentifierWhitelistInterface
} from '../../../../@jarvis-network/uma-core/contracts/oracle/interfaces/IdentifierWhitelistInterface.sol';
import {
  AddressWhitelist
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/AddressWhitelist.sol';
import {
  AdministrateeInterface
} from '../../../../@jarvis-network/uma-core/contracts/oracle/interfaces/AdministrateeInterface.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  ISelfMintingDerivativeDeployment
} from '../common/interfaces/ISelfMintingDerivativeDeployment.sol';
import {
  OracleInterface
} from '../../../../@jarvis-network/uma-core/contracts/oracle/interfaces/OracleInterface.sol';
import {
  OracleInterfaces
} from '../../../../@jarvis-network/uma-core/contracts/oracle/implementation/Constants.sol';
import {SynthereumInterfaces} from '../../../core/Constants.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {
  SafeERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  SelfMintingPerpetualPositionManagerMultiPartyLib
} from './SelfMintingPerpetualPositionManagerMultiPartyLib.sol';
import {FeePayerParty} from '../../common/FeePayerParty.sol';

contract SelfMintingPerpetualPositionManagerMultiParty is
  ISelfMintingDerivativeDeployment,
  FeePayerParty
{
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for PositionData;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for PositionManagerData;

  struct PositionManagerParams {
    uint256 withdrawalLiveness;
    address collateralAddress;
    address tokenAddress;
    address finderAddress;
    bytes32 priceFeedIdentifier;
    FixedPoint.Unsigned minSponsorTokens;
    address timerAddress;
    address excessTokenBeneficiary;
    uint8 version;
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
    uint8 version;
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
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount,
    uint256 feeAmount
  );
  event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

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

  constructor(PositionManagerParams memory _positionManagerData)
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
    positionManagerData.version = _positionManagerData.version;
  }

  function deposit(uint256 collateralAmount) external {
    depositTo(msg.sender, collateralAmount);
  }

  function withdraw(uint256 collateralAmount)
    external
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (uint256 amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    amountWithdrawn = positionData
      .withdraw(
      globalPositionData,
      FixedPoint.Unsigned(collateralAmount),
      feePayerData
    )
      .rawValue;
  }

  function requestWithdrawal(uint256 collateralAmount)
    external
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    nonReentrant()
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.requestWithdrawal(
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      actualTime,
      feePayerData
    );
  }

  function withdrawPassedRequest()
    external
    notEmergencyShutdown()
    fees()
    nonReentrant()
    returns (uint256 amountWithdrawn)
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    amountWithdrawn = positionData
      .withdrawPassedRequest(globalPositionData, actualTime, feePayerData)
      .rawValue;
  }

  function cancelWithdrawal() external notEmergencyShutdown() nonReentrant() {
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.cancelWithdrawal();
  }

  function create(
    uint256 collateralAmount,
    uint256 numTokens,
    uint256 feePercentage
  )
    external
    notEmergencyShutdown()
    fees()
    nonReentrant()
    returns (uint256 daoFeeAmount)
  {
    PositionData storage positionData = positions[msg.sender];
    daoFeeAmount = positionData
      .create(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens),
      FixedPoint.Unsigned(feePercentage),
      feePayerData
    )
      .rawValue;
  }

  function redeem(uint256 numTokens, uint256 feePercentage)
    external
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (uint256 amountWithdrawn, uint256 daoFeeAmount)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    (
      FixedPoint.Unsigned memory collateralAmount,
      FixedPoint.Unsigned memory feeAmount
    ) =
      positionData.redeeem(
        globalPositionData,
        positionManagerData,
        FixedPoint.Unsigned(numTokens),
        FixedPoint.Unsigned(feePercentage),
        feePayerData,
        msg.sender
      );

    amountWithdrawn = collateralAmount.rawValue;
    daoFeeAmount = feeAmount.rawValue;
  }

  function repay(uint256 numTokens, uint256 feePercentage)
    external
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (uint256 daoFeeAmount)
  {
    PositionData storage positionData = _getPositionData(msg.sender);
    daoFeeAmount = (
      positionData.repay(
        globalPositionData,
        positionManagerData,
        FixedPoint.Unsigned(numTokens),
        FixedPoint.Unsigned(feePercentage),
        feePayerData
      )
    )
      .rawValue;
  }

  function settleEmergencyShutdown()
    external
    isEmergencyShutdown()
    fees()
    nonReentrant()
    returns (uint256 amountWithdrawn)
  {
    PositionData storage positionData = positions[msg.sender];
    amountWithdrawn = positionData
      .settleEmergencyShutdown(
      globalPositionData,
      positionManagerData,
      feePayerData
    )
      .rawValue;
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
    returns (uint256 amount)
  {
    FixedPoint.Unsigned memory pfcAmount = _pfc();
    amount = positionManagerData
      .trimExcess(token, pfcAmount, feePayerData)
      .rawValue;
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
    return
      positions[sponsor].rawCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = positionManagerData.synthereumFinder;
  }

  function tokenCurrency() external view override returns (IERC20 synthToken) {
    synthToken = positionManagerData.tokenCurrency;
  }

  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(positionManagerData.tokenCurrency))
      .symbol();
  }

  function version() external view override returns (uint8 selfMintingversion) {
    selfMintingversion = positionManagerData.version;
  }

  function totalPositionCollateral()
    external
    view
    nonReentrantView()
    returns (uint256)
  {
    return
      globalPositionData
        .rawTotalPositionCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .rawValue;
  }

  function totalTokensOutstanding() external view returns (uint256) {
    return globalPositionData.totalTokensOutstanding.rawValue;
  }

  function emergencyShutdownPrice()
    external
    view
    isEmergencyShutdown()
    returns (uint256)
  {
    return positionManagerData.emergencyShutdownPrice.rawValue;
  }

  function calculateDaoFee(uint256 numTokens) external view returns (uint256) {
    return
      positionManagerData
        .calculateDaoFee(
        globalPositionData,
        FixedPoint.Unsigned(numTokens),
        feePayerData
      )
        .rawValue;
  }

  function daoFee()
    external
    view
    returns (uint256 feePercentage, address feeRecipient)
  {
    (FixedPoint.Unsigned memory percentage, address recipient) =
      positionManagerData.daoFee();
    feePercentage = percentage.rawValue;
    feeRecipient = recipient;
  }

  function capMintAmount() external view returns (uint256 capMint) {
    capMint = positionManagerData.capMintAmount().rawValue;
  }

  function capDepositRatio() external view returns (uint256 capDeposit) {
    capDeposit = positionManagerData.capDepositRatio().rawValue;
  }

  function depositTo(address sponsor, uint256 collateralAmount)
    public
    notEmergencyShutdown()
    noPendingWithdrawal(sponsor)
    fees()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(sponsor);

    positionData.depositTo(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      feePayerData,
      sponsor
    );
  }

  function collateralCurrency()
    public
    view
    override(ISelfMintingDerivativeDeployment, FeePayerParty)
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../../GSN/Context.sol';
import './IERC20.sol';
import '../../math/SafeMath.sol';

contract ERC20 is Context, IERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name_, string memory symbol_) public {
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        'ERC20: transfer amount exceeds allowance'
      )
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(
      amount,
      'ERC20: transfer amount exceeds balance'
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(
      amount,
      'ERC20: burn amount exceeds balance'
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SignedSafeMath {
  int256 private constant _INT256_MIN = -2**255;

  function mul(int256 a, int256 b) internal pure returns (int256) {
    if (a == 0) {
      return 0;
    }

    require(
      !(a == -1 && b == _INT256_MIN),
      'SignedSafeMath: multiplication overflow'
    );

    int256 c = a * b;
    require(c / a == b, 'SignedSafeMath: multiplication overflow');

    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, 'SignedSafeMath: division by zero');
    require(
      !(b == -1 && a == _INT256_MIN),
      'SignedSafeMath: division overflow'
    );

    int256 c = a / b;

    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require(
      (b >= 0 && c <= a) || (b < 0 && c > a),
      'SignedSafeMath: subtraction overflow'
    );

    return c;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require(
      (b >= 0 && c >= a) || (b < 0 && c < a),
      'SignedSafeMath: addition overflow'
    );

    return c;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;

    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(
      success,
      'Address: unable to send value, recipient may have reverted'
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, 'Address: low-level call failed');
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        'Address: low-level call with value failed'
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      'Address: insufficient balance for call'
    );
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, 'Address: low-level static call failed');
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), 'Address: static call to non-contract');

    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../common/implementation/FixedPoint.sol';

interface StoreInterface {
  function payOracleFees() external payable;

  function payOracleFeesErc20(
    address erc20Address,
    FixedPoint.Unsigned calldata amount
  ) external;

  function computeRegularFee(
    uint256 startTime,
    uint256 endTime,
    FixedPoint.Unsigned calldata pfc
  )
    external
    view
    returns (
      FixedPoint.Unsigned memory regularFee,
      FixedPoint.Unsigned memory latePenalty
    );

  function computeFinalFee(address currency)
    external
    view
    returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../common/implementation/FixedPoint.sol';

interface AdministrateeInterface {
  function emergencyShutdown() external;

  function remargin() external;

  function pfc() external view returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

interface FinderInterface {
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
pragma solidity ^0.6.0;

import './Timer.sol';

abstract contract Testable {
  address public timerAddress;

  constructor(address _timerAddress) internal {
    timerAddress = _timerAddress;
  }

  modifier onlyIfTest {
    require(timerAddress != address(0x0));
    _;
  }

  function setCurrentTime(uint256 time) external onlyIfTest {
    Timer(timerAddress).setCurrentTime(time);
  }

  function getCurrentTime() public view returns (uint256) {
    if (timerAddress != address(0x0)) {
      return Timer(timerAddress).getCurrentTime();
    } else {
      return now;
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

contract Lockable {
  bool private _notEntered;

  constructor() internal {
    _notEntered = true;
  }

  modifier nonReentrant() {
    _preEntranceCheck();
    _preEntranceSet();
    _;
    _postEntranceReset();
  }

  modifier nonReentrantView() {
    _preEntranceCheck();
    _;
  }

  function _preEntranceCheck() internal view {
    require(_notEntered, 'ReentrancyGuard: reentrant call');
  }

  function _preEntranceSet() internal {
    _notEntered = false;
  }

  function _postEntranceReset() internal {
    _notEntered = true;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

contract Timer {
  uint256 private currentTime;

  constructor() public {
    currentTime = now;
  }

  function setCurrentTime(uint256 time) external {
    currentTime = time;
  }

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

interface IdentifierWhitelistInterface {
  function addSupportedIdentifier(bytes32 identifier) external;

  function removeSupportedIdentifier(bytes32 identifier) external;

  function isIdentifierSupported(bytes32 identifier)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/access/Ownable.sol';
import './Lockable.sol';

contract AddressWhitelist is Ownable, Lockable {
  enum Status {None, In, Out}
  mapping(address => Status) public whitelist;

  address[] public whitelistIndices;

  event AddedToWhitelist(address indexed addedAddress);
  event RemovedFromWhitelist(address indexed removedAddress);

  function addToWhitelist(address newElement)
    external
    nonReentrant()
    onlyOwner
  {
    if (whitelist[newElement] == Status.In) {
      return;
    }

    if (whitelist[newElement] == Status.None) {
      whitelistIndices.push(newElement);
    }

    whitelist[newElement] = Status.In;

    emit AddedToWhitelist(newElement);
  }

  function removeFromWhitelist(address elementToRemove)
    external
    nonReentrant()
    onlyOwner
  {
    if (whitelist[elementToRemove] != Status.Out) {
      whitelist[elementToRemove] = Status.Out;
      emit RemovedFromWhitelist(elementToRemove);
    }
  }

  function isOnWhitelist(address elementToCheck)
    external
    view
    nonReentrantView()
    returns (bool)
  {
    return whitelist[elementToCheck] == Status.In;
  }

  function getWhitelist()
    external
    view
    nonReentrantView()
    returns (address[] memory activeWhitelist)
  {
    uint256 activeCount = 0;
    for (uint256 i = 0; i < whitelistIndices.length; i++) {
      if (whitelist[whitelistIndices[i]] == Status.In) {
        activeCount++;
      }
    }

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
} from '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../../core/interfaces/IFinder.sol';

interface ISelfMintingDerivativeDeployment {
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  function collateralCurrency() external view returns (IERC20 collateral);

  function tokenCurrency() external view returns (IERC20 syntheticCurrency);

  function syntheticTokenSymbol() external view returns (string memory symbol);

  function version() external view returns (uint8 selfMintingversion);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../GSN/Context.sol';

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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
    "deploy/contracts/contracts/derivative/common/FeePayerPartyLib.sol": {
      "FeePayerPartyLib": "0x8c4af53cf5643305b580dca84c550c8a234902ae"
    }
  }
}