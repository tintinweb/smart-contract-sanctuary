/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";
import "../events/LoanOpeningsEvents.sol";
import "../events/LoanMaintenanceEvents.sol";
import "../mixins/VaultController.sol";
import "../mixins/InterestUser.sol";
import "../mixins/LiquidationHelper.sol";
import "../swaps/SwapsUser.sol";


contract LoanMaintenance is LoanOpeningsEvents, LoanMaintenanceEvents, VaultController, InterestUser, SwapsUser, LiquidationHelper {

    struct LoanReturnData {
        bytes32 loanId;
        address loanToken;
        address collateralToken;
        uint256 principal;
        uint256 collateral;
        uint256 interestOwedPerDay;
        uint256 interestDepositRemaining;
        uint256 startRate; // collateralToLoanRate
        uint256 startMargin;
        uint256 maintenanceMargin;
        uint256 currentMargin;
        uint256 maxLoanTerm;
        uint256 endTimestamp;
        uint256 maxLiquidatable;
        uint256 maxSeizable;
    }

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.depositCollateral.selector, target);
        _setTarget(this.withdrawCollateral.selector, target);
        _setTarget(this.withdrawAccruedInterest.selector, target);
        _setTarget(this.extendLoanDuration.selector, target);
        _setTarget(this.reduceLoanDuration.selector, target);
        _setTarget(this.getLenderInterestData.selector, target);
        _setTarget(this.getLoanInterestData.selector, target);
        _setTarget(this.getUserLoans.selector, target);
        _setTarget(this.getLoan.selector, target);
        _setTarget(this.getActiveLoans.selector, target);
    }

    function depositCollateral(
        bytes32 loanId,
        uint256 depositAmount) // must match msg.value if ether is sent
        external
        payable
        nonReentrant
    {
        require(depositAmount != 0, "depositAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(msg.value == 0 || loanParamsLocal.collateralToken == address(wbaseToken), "wrong asset sent");

        loanLocal.collateral = loanLocal.collateral
            .add(depositAmount);

        if (msg.value == 0) {
            vaultDeposit(
                loanParamsLocal.collateralToken,
                msg.sender,
                depositAmount
            );
        } else {
            require(msg.value == depositAmount, "ether deposit mismatch");
            vaultEtherDeposit(
                msg.sender,
                msg.value
            );
        }
        
        emit DepositCollateral(loanId, depositAmount);
    }

    function withdrawCollateral(
        bytes32 loanId,
        address receiver, //Notice
        uint256 withdrawAmount)
        external
        nonReentrant
        returns (uint256 actualWithdrawAmount)
    {
        require(withdrawAmount != 0, "withdrawAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(
            msg.sender == loanLocal.borrower ||
            delegatedManagers[loanLocal.id][msg.sender],
            "unauthorized"
        );

        uint256 maxDrawdown = IPriceFeeds(priceFeeds).getMaxDrawdown(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral,
            loanParamsLocal.maintenanceMargin
        );

        if (withdrawAmount > maxDrawdown) {
            actualWithdrawAmount = maxDrawdown;
        } else {
            actualWithdrawAmount = withdrawAmount;
        }

        loanLocal.collateral = loanLocal.collateral
            .sub(actualWithdrawAmount);

        if (loanParamsLocal.collateralToken == address(wbaseToken)) {
            vaultEtherWithdraw(
                receiver,
                actualWithdrawAmount
            );
        } else {
            vaultWithdraw(
                loanParamsLocal.collateralToken,
                receiver,
                actualWithdrawAmount
            );
        }
    }

    function withdrawAccruedInterest(
        address loanToken)
        external
    {
        // pay outstanding interest to lender
        _payInterest(
            msg.sender, // lender
            loanToken
        );
    }

    function extendLoanDuration(
        bytes32 loanId,
        uint256 depositAmount,
        bool useCollateral,
        bytes calldata /*loanDataBytes*/) // for future use
        external
        payable
        nonReentrant
        returns (uint256 secondsExtended)
    {
        require(depositAmount != 0, "depositAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(
            !useCollateral ||
            msg.sender == loanLocal.borrower ||
            delegatedManagers[loanLocal.id][msg.sender],
            "unauthorized"
        );
        require(loanParamsLocal.maxLoanTerm == 0, "indefinite-term only");
        require(msg.value == 0 || (!useCollateral && loanParamsLocal.loanToken == address(wbaseToken)), "wrong asset sent");

        // pay outstanding interest to lender
        _payInterest(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];

        _settleFeeRewardForInterestExpense(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            block.timestamp
        );

        // Handle back interest: calculates interest owned since the loan endtime passed but the loan remained open
        uint256 backInterestOwed;
        if (block.timestamp > loanLocal.endTimestamp) {
            backInterestOwed = block.timestamp
                .sub(loanLocal.endTimestamp);
            backInterestOwed = backInterestOwed
                .mul(loanInterestLocal.owedPerDay);
            backInterestOwed = backInterestOwed
                .div(86400);

            require(depositAmount > backInterestOwed, "deposit cannot cover back interest");
        }

        // deposit interest
        if (useCollateral) {
            _doCollateralSwap(
                loanLocal,
                loanParamsLocal,
                depositAmount
            );
        } else {
            if (msg.value == 0) {
                vaultDeposit(
                    loanParamsLocal.loanToken,
                    msg.sender,
                    depositAmount
                );
            } else {
                require(msg.value == depositAmount, "ether deposit mismatch");
                vaultEtherDeposit(
                    msg.sender,
                    msg.value
                );
            }
        }

        if (backInterestOwed != 0) {
            depositAmount = depositAmount
                .sub(backInterestOwed);

            // pay out backInterestOwed
            _payInterestTransfer(
                loanLocal.lender,
                loanParamsLocal.loanToken,
                backInterestOwed
            );
        }

        secondsExtended = depositAmount
            .mul(86400)
            .div(loanInterestLocal.owedPerDay);

        loanLocal.endTimestamp = loanLocal.endTimestamp
            .add(secondsExtended);

        require (loanLocal.endTimestamp > block.timestamp, "loan too short");

        uint256 maxDuration = loanLocal.endTimestamp
            .sub(block.timestamp);

        // loan term has to at least be greater than one hour
        require(maxDuration > 3600, "loan too short");

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .add(depositAmount);

        lenderInterest[loanLocal.lender][loanParamsLocal.loanToken].owedTotal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken].owedTotal
            .add(depositAmount);
    }

    function reduceLoanDuration(
        bytes32 loanId,
        address receiver, //Notice
        uint256 withdrawAmount)
        external
        nonReentrant
        returns (uint256 secondsReduced)
    {
        require(withdrawAmount != 0, "withdrawAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(
            msg.sender == loanLocal.borrower ||
            delegatedManagers[loanLocal.id][msg.sender],
            "unauthorized"
        );
        require(loanParamsLocal.maxLoanTerm == 0, "indefinite-term only");
        require(loanLocal.endTimestamp > block.timestamp, "loan term has ended");

        // pay outstanding interest to lender
        _payInterest(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];

        _settleFeeRewardForInterestExpense(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            block.timestamp
        );

        uint256 interestDepositRemaining = loanLocal.endTimestamp
            .sub(block.timestamp)
            .mul(loanInterestLocal.owedPerDay)
            .div(86400);
        require(withdrawAmount < interestDepositRemaining, "withdraw amount too high");

        // withdraw interest
        if (loanParamsLocal.loanToken == address(wbaseToken)) {
            vaultEtherWithdraw(
                receiver,
                withdrawAmount
            );
        } else {
            vaultWithdraw(
                loanParamsLocal.loanToken,
                receiver,
                withdrawAmount
            );
        }

        secondsReduced = withdrawAmount
            .mul(86400)
            .div(loanInterestLocal.owedPerDay);

        require (loanLocal.endTimestamp > secondsReduced, "loan too short");

        loanLocal.endTimestamp = loanLocal.endTimestamp
            .sub(secondsReduced);

        require (loanLocal.endTimestamp > block.timestamp, "loan too short");

        uint256 maxDuration = loanLocal.endTimestamp
            .sub(block.timestamp);

        // loan term has to at least be greater than one hour
        require(maxDuration > 3600, "loan too short");

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .sub(withdrawAmount);

        lenderInterest[loanLocal.lender][loanParamsLocal.loanToken].owedTotal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken].owedTotal
            .sub(withdrawAmount);
    }

    /// @dev Gets current lender interest data totals for all loans with a specific oracle and interest token
    /// @param lender The lender address
    /// @param loanToken The loan token address
    /// @return interestPaid The total amount of interest that has been paid to a lender so far
    /// @return interestPaidDate The date of the last interest pay out, or 0 if no interest has been withdrawn yet
    /// @return interestOwedPerDay The amount of interest the lender is earning per day
    /// @return interestUnPaid The total amount of interest the lender is owned and not yet withdrawn
    /// @return interestFeePercent The fee retained by the protocol before interest is paid to the lender
    /// @return principalTotal The total amount of outstading principal the lender has loaned
    function getLenderInterestData(
        address lender,
        address loanToken)
        external
        view
        returns (
            uint256 interestPaid,
            uint256 interestPaidDate,
            uint256 interestOwedPerDay,
            uint256 interestUnPaid,
            uint256 interestFeePercent,
            uint256 principalTotal)
    {
        LenderInterest memory lenderInterestLocal = lenderInterest[lender][loanToken];

        interestUnPaid = block.timestamp.sub(lenderInterestLocal.updatedTimestamp).mul(lenderInterestLocal.owedPerDay).div(86400);
        if (interestUnPaid > lenderInterestLocal.owedTotal)
            interestUnPaid = lenderInterestLocal.owedTotal;

        return (
            lenderInterestLocal.paidTotal,
            lenderInterestLocal.paidTotal != 0 ? lenderInterestLocal.updatedTimestamp : 0,
            lenderInterestLocal.owedPerDay,
            lenderInterestLocal.updatedTimestamp != 0 ? interestUnPaid : 0,
            lendingFeePercent,
            lenderInterestLocal.principalTotal
        );
    }

    /// @dev Gets current interest data for a loan
    /// @param loanId A unique id representing the loan
    /// @return loanToken The loan token that interest is paid in
    /// @return interestOwedPerDay The amount of interest the borrower is paying per day
    /// @return interestDepositTotal The total amount of interest the borrower has deposited
    /// @return interestDepositRemaining The amount of deposited interest that is not yet owed to a lender
    function getLoanInterestData(
        bytes32 loanId)
        external
        view
        returns (
            address loanToken,
            uint256 interestOwedPerDay,
            uint256 interestDepositTotal,
            uint256 interestDepositRemaining)
    {
        loanToken = loanParams[loans[loanId].loanParamsId].loanToken;
        interestOwedPerDay = loanInterest[loanId].owedPerDay;
        interestDepositTotal = loanInterest[loanId].depositTotal;

        uint256 endTimestamp = loans[loanId].endTimestamp;
        uint256 interestTime = block.timestamp > endTimestamp ?
            endTimestamp :
            block.timestamp;
        interestDepositRemaining = endTimestamp > interestTime ?
            endTimestamp
                .sub(interestTime)
                .mul(interestOwedPerDay)
                .div(86400) :
                0;
    }

    // Only returns data for loans that are active
    // loanType 0: all loans
    // loanType 1: margin trade loans
    // loanType 2: non-margin trade loans
    // only active loans are returned
    function getUserLoans(
        address user,
        uint256 start,
        uint256 count,
        uint256 loanType,
        bool isLender,
        bool unsafeOnly)
        external
        view
        returns (LoanReturnData[] memory loansData)
    {
        EnumerableBytes32Set.Bytes32Set storage set = isLender ?
            lenderLoanSets[user] :
            borrowerLoanSets[user];

        uint256 end = count.min256(set.values.length);
        if (end == 0 || start >= end) {
            return loansData;
        }

        loansData = new LoanReturnData[](count);
        uint256 itemCount;
        for (uint256 i = end-start; i > 0; i--) {
            if (itemCount == count) {
                break;
            }
            LoanReturnData memory loanData = _getLoan(
                set.get(i+start-1), // loanId
                loanType,
                unsafeOnly
            );
            if (loanData.loanId == 0)
                continue;

            loansData[itemCount] = loanData;
            itemCount++;
        }

        if (itemCount < count) {
            assembly {
                mstore(loansData, itemCount)
            }
        }
    }

    function getLoan(
        bytes32 loanId)
        external
        view
        returns (LoanReturnData memory loanData)
    {
        return _getLoan(
            loanId,
            0, // loanType
            false // unsafeOnly
        );
    }

    function getActiveLoans(
        uint256 start,
        uint256 count,
        bool unsafeOnly)
        external
        view
        returns (LoanReturnData[] memory loansData)
    {
        uint256 end = count.min256(activeLoansSet.values.length);
        if (end == 0 || start >= end) {
            return loansData;
        }

        loansData = new LoanReturnData[](count);
        uint256 itemCount;
        for (uint256 i = end-start; i > 0; i--) {
            if (itemCount == count) {
                break;
            }
            LoanReturnData memory loanData = _getLoan(
                activeLoansSet.get(i+start-1), // loanId
                0, // loanType
                unsafeOnly
            );
            if (loanData.loanId == 0)
                continue;

            loansData[itemCount] = loanData;
            itemCount++;
        }

        if (itemCount < count) {
            assembly {
                mstore(loansData, itemCount)
            }
        }
    }

    function _getLoan(
        bytes32 loanId,
        uint256 loanType,
        bool unsafeOnly)
        internal
        view
        returns (LoanReturnData memory loanData)
    {
        Loan memory loanLocal = loans[loanId];
        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        if (loanType != 0) {
            if (!(
                (loanType == 1 && loanParamsLocal.maxLoanTerm != 0) ||
                (loanType == 2 && loanParamsLocal.maxLoanTerm == 0)
            )) {
                return loanData;
            }
        }

        LoanInterest memory loanInterestLocal = loanInterest[loanId];

        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );

        uint256 maxLiquidatable;
        uint256 maxSeizable;
        if (currentMargin <= loanParamsLocal.maintenanceMargin) {
            (maxLiquidatable, maxSeizable,) = _getLiquidationAmounts(
                loanLocal.principal,
                loanLocal.collateral,
                currentMargin,
                loanParamsLocal.maintenanceMargin,
                collateralToLoanRate
            );
        } else if (unsafeOnly) {
            return loanData;
        }

        return LoanReturnData({
            loanId: loanId,
            loanToken: loanParamsLocal.loanToken,
            collateralToken: loanParamsLocal.collateralToken,
            principal: loanLocal.principal,
            collateral: loanLocal.collateral,
            interestOwedPerDay: loanInterestLocal.owedPerDay,
            interestDepositRemaining: loanLocal.endTimestamp >= block.timestamp ? loanLocal.endTimestamp.sub(block.timestamp).mul(loanInterestLocal.owedPerDay).div(86400) : 0,
            startRate: loanLocal.startRate,
            startMargin: loanLocal.startMargin,
            maintenanceMargin: loanParamsLocal.maintenanceMargin,
            currentMargin: currentMargin,
            maxLoanTerm: loanParamsLocal.maxLoanTerm,
            endTimestamp: loanLocal.endTimestamp,
            maxLiquidatable: maxLiquidatable,
            maxSeizable: maxSeizable
        });
    }

    function _doCollateralSwap(
        Loan storage loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 depositAmount)
        internal
    {
        // reverts in _loanSwap if amountNeeded can't be bought
        (,uint256 sourceTokenAmountUsed,) = _loanSwap(
            loanLocal.id,
            loanParamsLocal.collateralToken,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            loanLocal.collateral, // minSourceTokenAmount
            0, // maxSourceTokenAmount (0 means minSourceTokenAmount)
            depositAmount, // requiredDestTokenAmount (partial spend of loanLocal.collateral to fill this amount)
            true, // bypassFee
            "" // loanDataBytes
        );
        loanLocal.collateral = loanLocal.collateral
            .sub(sourceTokenAmountUsed);

        // ensure the loan is still healthy
        (uint256 currentMargin,) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            currentMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


import "./Objects.sol";
import "../mixins/EnumerableBytes32Set.sol";
import "../openzeppelin/v2/utils/ReentrancyGuard.sol";
import "../openzeppelin/v2/ownership/Ownable.sol";
import "../openzeppelin/v2/math/SafeMath.sol";
import "../openzeppelin/v2/access/Roles.sol";
import "../interfaces/IWbaseERC20.sol";



contract State is Objects, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;
    using Roles for Roles.Role;

    address public priceFeeds;                                                          // handles asset reference price lookups
    address public swapsImpl;                                                           // handles asset swaps using dex liquidity
    address public thaifiSwapContractRegistryAddress;                                       // contract registry address of the thaifi swap network

    mapping (bytes4 => address) public logicTargets;                                    // implementations of protocol functions

    mapping (bytes32 => Loan) public loans;                                             // loanId => Loan
    mapping (bytes32 => LoanParams) public loanParams;                                  // loanParamsId => LoanParams

    mapping (address => mapping (bytes32 => Order)) public lenderOrders;                // lender => orderParamsId => Order
    mapping (address => mapping (bytes32 => Order)) public borrowerOrders;              // borrower => orderParamsId => Order

    mapping (bytes32 => mapping (address => bool)) public delegatedManagers;            // loanId => delegated => approved

    // Interest
    mapping (address => mapping (address => LenderInterest)) public lenderInterest;     // lender => loanToken => LenderInterest object
    mapping (bytes32 => LoanInterest) public loanInterest;                              // loanId => LoanInterest object

    // Internals
    EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;                           // implementations set
    EnumerableBytes32Set.Bytes32Set internal activeLoansSet;                            // active loans set

    mapping (address => EnumerableBytes32Set.Bytes32Set) internal lenderLoanSets;       // lender loans set
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal borrowerLoanSets;     // borrow loans set
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal userLoanParamSets;    // user loan params set

    address public feesController;                                                      // address controlling fee withdrawals

    uint256 public lendingFeePercent = 10**19; // 10% fee                               // fee taken from lender interest payments
    mapping (address => uint256) public lendingFeeTokensHeld;                           // total interest fees received and not withdrawn per asset
    mapping (address => uint256) public lendingFeeTokensPaid;                           // total interest fees withdraw per asset (lifetime fees = lendingFeeTokensHeld + lendingFeeTokensPaid)

    uint256 public tradingFeePercent = 15 * 10**16; // 0.15% fee                        // fee paid for each trade
    mapping (address => uint256) public tradingFeeTokensHeld;                           // total trading fees received and not withdrawn per asset
    mapping (address => uint256) public tradingFeeTokensPaid;                           // total trading fees withdraw per asset (lifetime fees = tradingFeeTokensHeld + tradingFeeTokensPaid)

    uint256 public borrowingFeePercent = 9 * 10**16; // 0.09% fee                       // origination fee paid for each loan
    mapping (address => uint256) public borrowingFeeTokensHeld;                         // total borrowing fees received and not withdrawn per asset
    mapping (address => uint256) public borrowingFeeTokensPaid;                         // total borrowing fees withdraw per asset (lifetime fees = borrowingFeeTokensHeld + borrowingFeeTokensPaid)

    uint256 public protocolTokenHeld;                                                   // current protocol token deposit balance
    uint256 public protocolTokenPaid;                                                   // lifetime total payout of protocol token

    uint256 public affiliateFeePercent = 30 * 10**18; // 30% fee share                  // fee share for affiliate program

    uint256 public liquidationIncentivePercent = 15 * 10**18; // 5% collateral discount  // discount on collateral for liquidators

    mapping (address => address) public loanPoolToUnderlying;                            // loanPool => underlying
    mapping (address => address) public underlyingToLoanPool;                            // underlying => loanPool
    EnumerableBytes32Set.Bytes32Set internal loanPoolsSet;                               // loan pools set

    mapping (address => bool) public supportedTokens;                                    // supported tokens for swaps

    uint256 public maxDisagreement = 5 * 10**18;                                         // % disagreement between swap rate and reference rate

    uint256 public sourceBuffer = 10000;                                                 // used as buffer for swap source amount estimations

    uint256 public maxSwapSize = 50 ether;                                               // maximum support swap size in BTC

    mapping(address => uint256) public borrowerNonce;                                    // nonce per borrower. used for loan id creation.

    uint256 public rolloverBaseReward = 16800000000000;                                  // Rollover transaction costs around 0.0000168 rBTC, it is denominated in wBASE
    uint256 public rolloverFlexFeePercent = 0.1 ether;                                   // 0.1%

    IWbaseERC20 public wbaseToken;
    address public protocolTokenAddress;

    uint256 public feeRebatePercent = 50 * 10**18; // 50% fee rebate                     // potocolToken reward to user, it is worth % of trading/borrowing fee

    Roles.Role internal _liquidators;

    mapping (address => address) public loanToRouter;
    mapping (address => address) public loanToTokenPair;


    function _setTarget(
        bytes4 sig,
        address target)
        internal
    {
        logicTargets[sig] = target;

        if (target != address(0)) {
            logicTargetsSet.addBytes32(bytes32(sig));
        } else {
            logicTargetsSet.removeBytes32(bytes32(sig));
        }
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanOpeningsEvents {

    // topic0: 0x7bd8cbb7ba34b33004f3deda0fd36c92fc0360acbd97843360037b467a538f90
    event Borrow(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 newCollateral,
        uint256 interestRate,
        uint256 interestDuration,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    // topic0: 0xf640c1cfe1a912a0b0152b5a542e5c2403142eed75b06cde526cee54b1580e5c
    event Trade(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address collateralToken,
        address loanToken,
        uint256 positionSize,
        uint256 borrowedAmount,
        uint256 interestRate,
        uint256 settlementDate,
        uint256 entryPrice, // one unit of collateralToken, denominated in loanToken
        uint256 entryLeverage,
        uint256 currentLeverage
    );

    // topic0: 0x0eef4f90457a741c97d76fcf13fa231fefdcc7649bdb3cb49157c37111c98433
    event DelegatedManagerSet(
        bytes32 indexed loanId,
        address indexed delegator,
        address indexed delegated,
        bool isActive
    );
}

pragma solidity 0.5.17;

contract LoanMaintenanceEvents {
    
    event DepositCollateral(
        bytes32 loanId,
        uint256 depositAmount
    );
    
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/v2/token/ERC20/SafeERC20.sol";
import "../core/State.sol";


contract VaultController is State {
    using SafeERC20 for IERC20;

    event VaultDeposit(
        address indexed asset,
        address indexed from,
        uint256 amount
    );
    event VaultWithdraw(
        address indexed asset,
        address indexed to,
        uint256 amount
    );

    function vaultEtherDeposit(
        address from,
        uint256 value)
        internal
    {
        IWbaseERC20 _wbaseToken = wbaseToken;
        _wbaseToken.deposit.value(value)();

        emit VaultDeposit(
            address(_wbaseToken),
            from,
            value
        );
    }

    function vaultEtherWithdraw(
        address to, //notice
        uint256 value)
        internal
    {
        if (value != 0) {
            IWbaseERC20 _wbaseToken = wbaseToken;
            uint256 balance = address(this).balance;
            if (value > balance) {
                _wbaseToken.withdraw(value - balance);
            }
            Address.sendValue(to, value);

            emit VaultWithdraw(
                address(_wbaseToken),
                to,
                value
            );
        }
    }

    function vaultDeposit(
        address token,
        address from,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).safeTransferFrom(
                from,
                address(this),
                value
            );

            emit VaultDeposit(
                token,
                from,
                value
            );
        }
    }

    function vaultWithdraw(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).safeTransfer(
                to,
                value
            );

            emit VaultWithdraw(
                token,
                to,
                value
            );
        }
    }

    function vaultTransfer(
        address token,
        address from,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            if (from == address(this)) {
                IERC20(token).safeTransfer(
                    to,
                    value
                );
            } else {
                IERC20(token).safeTransferFrom(
                    from,
                    to,
                    value
                );
            }
        }
    }

    function vaultApprove(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0 && IERC20(token).allowance(address(this), to) != 0) {
            IERC20(token).safeApprove(to, 0);
        }
        IERC20(token).safeApprove(to, value);
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/v2/token/ERC20/SafeERC20.sol";
import "../core/State.sol";
import "../mixins/VaultController.sol";
import "./FeesHelper.sol";


contract InterestUser is VaultController, FeesHelper {
    using SafeERC20 for IERC20;

    function _payInterest(
        address lender, // Notice
        address interestToken)
        internal
    {
        LenderInterest storage lenderInterestLocal = lenderInterest[lender][interestToken];

        uint256 interestOwedNow = 0;
        if (lenderInterestLocal.owedPerDay != 0 && lenderInterestLocal.updatedTimestamp != 0) {
            interestOwedNow = block.timestamp
                .sub(lenderInterestLocal.updatedTimestamp)
                .mul(lenderInterestLocal.owedPerDay)
                .div(86400);

            if (interestOwedNow > lenderInterestLocal.owedTotal)
	            interestOwedNow = lenderInterestLocal.owedTotal;

            if (interestOwedNow != 0) {
                lenderInterestLocal.paidTotal = lenderInterestLocal.paidTotal
                    .add(interestOwedNow);
                lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
                    .sub(interestOwedNow);

                _payInterestTransfer(
                    lender,
                    interestToken,
                    interestOwedNow
                );
            }
        }

        lenderInterestLocal.updatedTimestamp = block.timestamp;
    }

    function _payInterestTransfer(
        address lender, // Notice
        address interestToken,
        uint256 interestOwedNow)
        internal
    {
        uint256 lendingFee = interestOwedNow
            .mul(lendingFeePercent)
            .div(10**20);

        _payLendingFee(
            lender,
            interestToken,
            lendingFee
        );

        // transfers the interest to the lender, less the interest fee
        vaultWithdraw(
            interestToken,
            lender,
            interestOwedNow
                .sub(lendingFee)
        );
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";


contract LiquidationHelper is State {
    
    /**
     * computes how much needs to be liquidated in order to restore the desired margin (maintenance + 5%)
     * @param principal total borrowed amount (in loan tokens)
     * @param collateral the collateral (in collateral tokens)
     * @param currentMargin the current margin
     * @param maintenanceMargin the maintenance (minimum) margin
     * @param collateralToLoanRate the exchange rate from collateral to loan tokens
     * */
    function _getLiquidationAmounts(
        uint256 principal,
        uint256 collateral,
        uint256 currentMargin,
        uint256 maintenanceMargin,
        uint256 collateralToLoanRate)
        internal
        view
        returns (uint256 maxLiquidatable, uint256 maxSeizable, uint256 incentivePercent)
    {
        incentivePercent = liquidationIncentivePercent;
        if (currentMargin > maintenanceMargin || collateralToLoanRate == 0) {
            return (maxLiquidatable, maxSeizable, incentivePercent);
        } else if (currentMargin <= incentivePercent) {
            return (principal, collateral, currentMargin);
        }

        uint256 desiredMargin = maintenanceMargin
            .add(5 ether); // 5 percentage points above maintenance

        // maxLiquidatable = ((1 + desiredMargin)*principal - collateralToLoanRate*collateral) / (desiredMargin - 0.05)
        maxLiquidatable = desiredMargin
            .add(10**20)
            .mul(principal)
            .div(10**20);
        maxLiquidatable = maxLiquidatable
            .sub(
                collateral
                    .mul(collateralToLoanRate)
                    .div(10**18)
            );
        maxLiquidatable = maxLiquidatable
            .mul(10**20)
            .div(
                desiredMargin
                    .sub(incentivePercent)
            );
        if (maxLiquidatable > principal) {
            maxLiquidatable = principal;
        }

        // maxSeizable = maxLiquidatable * (1 + incentivePercent) / collateralToLoanRate
        maxSeizable = maxLiquidatable
            .mul(
                incentivePercent
                    .add(10**20)
            );
        maxSeizable = maxSeizable
            .div(collateralToLoanRate)
            .div(100);
        if (maxSeizable > collateral) {
            maxSeizable = collateral;
        }

        return (maxLiquidatable, maxSeizable, incentivePercent);
    }


    /**
     * computes how much needs to be liquidated in order to restore the desired margin (maintenance + 5%)
     * @param principal total borrowed amount (in loan tokens)
     * @param collateral the collateral (in collateral tokens)
     * @param currentMargin the current margin
     * @param maintenanceMargin the maintenance (minimum) margin
     * @param collateralToLoanRate the exchange rate from collateral to loan tokens
     * */
    function _getHealthyLiquidationAmounts(
        uint256 principal,
        uint256 collateral,
        uint256 currentMargin,
        uint256 maintenanceMargin,
        uint256 collateralToLoanRate)
        internal
        view
        returns (uint256 maxLiquidatable, uint256 maxSeizable, uint256 incentivePercent)
    {
        incentivePercent = liquidationIncentivePercent;

        if (collateralToLoanRate == 0) {
            return (maxLiquidatable, maxSeizable, incentivePercent);
        } else if (currentMargin <= incentivePercent) {
            return (principal, collateral, currentMargin);
        }

        return (principal, collateral, incentivePercent);
    }



}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../feeds/IPriceFeeds.sol";
import "../events/SwapsEvents.sol";
import "../mixins/FeesHelper.sol";
import "./ISwapsImpl.sol";


contract SwapsUser is State, SwapsEvents, FeesHelper {

    function _loanSwap(
        bytes32 loanId,
        address sourceToken,
        address destToken,
        address user,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bool bypassFee,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed, uint256 sourceToDestSwapRate)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            [
                sourceToken,
                destToken,
                address(this), // receiver
                address(this), // returnToSender
                user
            ],
            [
                minSourceTokenAmount,
                maxSourceTokenAmount,
                requiredDestTokenAmount
            ],
            loanId,
            bypassFee,
            loanDataBytes
        );

        // will revert if swap size too large
        _checkSwapSize(sourceToken, sourceTokenAmountUsed);

        // will revert if disagreement found
        sourceToDestSwapRate = IPriceFeeds(priceFeeds).checkPriceDisagreement(
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived,
            maxDisagreement
        );

        emit LoanSwap(
            loanId,
            sourceToken,
            destToken,
            user,
            sourceTokenAmountUsed,
            destTokenAmountReceived
        );
    }

    function _swapsCall(
        address[5] memory addrs,
        uint256[3] memory vals,
        bytes32 loanId,
        bool miscBool, // bypassFee
        bytes memory loanDataBytes)
        internal
        returns (uint256, uint256)
    {
        //addrs[0]: sourceToken
        //addrs[1]: destToken
        //addrs[2]: receiver
        //addrs[3]: returnToSender
        //addrs[4]: user
        //vals[0]:  minSourceTokenAmount
        //vals[1]:  maxSourceTokenAmount
        //vals[2]:  requiredDestTokenAmount

        require(vals[0] != 0 || vals[1] != 0, "min or max source token amount needs to be set");

        if (vals[1] == 0) {
            vals[1] = vals[0];
        }
        require(vals[0] <= vals[1], "sourceAmount larger than max");

        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        uint256 tradingFee;
        if (!miscBool) { // bypassFee
            if (vals[2] == 0) {
                // condition: vals[0] will always be used as sourceAmount

                tradingFee = _getTradingFee(vals[0]);
                if (tradingFee != 0) {
                    _payTradingFee(
                        addrs[4], // user
                        loanId,
                        addrs[0], // sourceToken
                        tradingFee
                    );

                    vals[0] = vals[0]
                        .sub(tradingFee);
                }
            } else {
                // condition: unknown sourceAmount will be used

                tradingFee = _getTradingFee(vals[2]);

                if (tradingFee != 0) {
                    vals[2] = vals[2]
                        .add(tradingFee);
                }
            }
        }
        
        require(loanDataBytes.length == 0, "invalid state");

        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall_internal(
            addrs,
            vals
        );


        if (vals[2] == 0) {
            // there's no minimum destTokenAmount, but all of vals[0] (minSourceTokenAmount) must be spent
            require(sourceTokenAmountUsed == vals[0], "swap too large to fill");

            if (tradingFee != 0) {
                sourceTokenAmountUsed = sourceTokenAmountUsed
                    .add(tradingFee);
            }
        } else {
            // there's a minimum destTokenAmount required, but sourceTokenAmountUsed won't be greater than vals[1] (maxSourceTokenAmount)
            require(sourceTokenAmountUsed <= vals[1], "swap fill too large");
            require(destTokenAmountReceived >= vals[2], "insufficient swap liquidity");

            if (tradingFee != 0) {
                _payTradingFee(
                    addrs[4], // user
                    loanId, // loanId,
                    addrs[1], // destToken
                    tradingFee
                );

                destTokenAmountReceived = destTokenAmountReceived
                    .sub(tradingFee);
            }
        }

        return (destTokenAmountReceived, sourceTokenAmountUsed);
    }

    function _swapsCall_internal(
        address[5] memory addrs,
        uint256[3] memory vals)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        bytes memory data = abi.encodeWithSelector(
            ISwapsImpl(swapsImpl).internalSwap.selector,
            addrs[0], // sourceToken
            addrs[1], // destToken
            addrs[2], // receiverAddress
            addrs[3], // returnToSenderAddress
            vals[0],  // minSourceTokenAmount
            vals[1],  // maxSourceTokenAmount
            vals[2]   // requiredDestTokenAmount
        );

        bool success;
        (success, data) = swapsImpl.delegatecall(data);
        require(success, "swap failed");

        assembly {
            destTokenAmountReceived := mload(add(data, 32))
            sourceTokenAmountUsed := mload(add(data, 64))
        }
    }

    function _swapsExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount)
        internal
        view
        returns (uint256 destTokenAmount)
    {

        destTokenAmount = ISwapsImpl(swapsImpl).internalExpectedRate(
            sourceToken,
            destToken,
            sourceTokenAmount,
            thaifiSwapContractRegistryAddress
        );
    }

    function _checkSwapSize(
        address tokenAddress,
        uint256 amount)
        internal
        view
    {
        uint256 _maxSwapSize = maxSwapSize;
        if (_maxSwapSize != 0) {
            uint256 amountInEth;
            if (tokenAddress == address(wbaseToken)) {
                amountInEth = amount;
            } else {
                amountInEth = IPriceFeeds(priceFeeds).amountInEth(tokenAddress, amount);
            }
            require(amountInEth <= _maxSwapSize, "swap too large");
        }
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./objects/LoanStruct.sol";
import "./objects/LoanParamsStruct.sol";
import "./objects/OrderStruct.sol";
import "./objects/LenderInterestStruct.sol";
import "./objects/LoanInterestStruct.sol";


contract Objects is
    LoanStruct,
    LoanParamsStruct,
    OrderStruct,
    LenderInterestStruct,
    LoanInterestStruct
{}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

/**
 * @dev Library for managing loan sets
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * Include with `using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;`.
 *
 */
library EnumerableBytes32Set {

    struct Bytes32Set {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) index;
        bytes32[] values;
    }

    /**
     * @dev Add an address value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return addBytes32(set, value);
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (!contains(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes an address value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return removeBytes32(set, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(Bytes32Set storage set, uint256 start, uint256 count)
        internal
        view
        returns (bytes32[] memory output)
    {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes32[](end-start);
        for (uint256 i; i < end-start; i++) {
            output[i] = set.values[i+start];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(Bytes32Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return set.values[index];
    }
}

pragma solidity >=0.5.0 <0.6.0;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

    /// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
    /// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
    uint256 internal constant REENTRANCY_GUARD_FREE = 1;

    /// @dev Constant for locked guard state
    uint256 internal constant REENTRANCY_GUARD_LOCKED = 2;

    /**
    * @dev We use a single lock for the whole contract.
    */
    uint256 internal reentrancyLock = REENTRANCY_GUARD_FREE;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * If you mark a function `nonReentrant`, you should also
    * mark it `external`. Calling one `nonReentrant` function from
    * another is not supported. Instead, you can implement a
    * `private` function doing the actual work, and an `external`
    * wrapper marked as `nonReentrant`.
    */
    modifier nonReentrant() {
        require(reentrancyLock == REENTRANCY_GUARD_FREE, "nonReentrant");
        reentrancyLock = REENTRANCY_GUARD_LOCKED;
        _;
        reentrancyLock = REENTRANCY_GUARD_FREE;
    }

}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    //Notice
    function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}

pragma solidity ^0.5.17;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;

import "./IWbase.sol";
import "./IERC20.sol";



contract IWbaseERC20 is IWbase, IERC20 {}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanStruct {
    struct Loan {
        bytes32 id;                 // id of the loan
        bytes32 loanParamsId;       // the linked loan params id
        bytes32 pendingTradesId;    // the linked pending trades id
        bool active;                // if false, the loan has been fully closed
        uint256 principal;          // total borrowed amount outstanding
        uint256 collateral;         // total collateral escrowed for the loan
        uint256 startTimestamp;     // loan start time
        uint256 endTimestamp;       // for active loans, this is the expected loan end time, for in-active loans, is the actual (past) end time
        uint256 startMargin;        // initial margin when the loan opened
        uint256 startRate;          // reference rate when the loan opened for converting collateralToken to loanToken
        address borrower;           // borrower of this loan
        address lender;             // lender of this loan
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanParamsStruct {
    struct LoanParams {
        bytes32 id;                 // id of loan params object
        bool active;                // if false, this object has been disabled by the owner and can't be used for future loans
        address owner;              // owner of this object
        address loanToken;          // the token being loaned
        address collateralToken;    // the required collateral token
        uint256 minInitialMargin;   // the minimum allowed initial margin
        uint256 maintenanceMargin;  // an unhealthy loan when current margin is at or below this value
        uint256 maxLoanTerm;        // the maximum term for new loans (0 means there's no max term)
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract OrderStruct {
    struct Order {
        uint256 lockedAmount;           // escrowed amount waiting for a counterparty
        uint256 interestRate;           // interest rate defined by the creator of this order
        uint256 minLoanTerm;            // minimum loan term allowed
        uint256 maxLoanTerm;            // maximum loan term allowed
        uint256 createdTimestamp;       // timestamp when this order was created
        uint256 expirationTimestamp;    // timestamp when this order expires
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LenderInterestStruct {
    struct LenderInterest {
        uint256 principalTotal;     // total borrowed amount outstanding of asset
        uint256 owedPerDay;         // interest owed per day for all loans of asset
        uint256 owedTotal;          // total interest owed for all loans of asset (assuming they go to full term)
        uint256 paidTotal;          // total interest paid so far for asset
        uint256 updatedTimestamp;   // last update
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanInterestStruct {
    struct LoanInterest {
        uint256 owedPerDay;         // interest owed per day for loan
        uint256 depositTotal;       // total escrowed interest for loan
        uint256 updatedTimestamp;   // last update
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


interface IWbase {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


contract IERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../../../interfaces/IERC20.sol";


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
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */

    //Notice : payable added to fix
    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../openzeppelin/v2/token/ERC20/SafeERC20.sol";
import "../feeds/IPriceFeeds.sol";
import "../events/FeesEvents.sol";
import "../mixins/ProtocolTokenUser.sol";


contract FeesHelper is State, ProtocolTokenUser, FeesEvents {
    using SafeERC20 for IERC20;

    // calculate trading fee
    function _getTradingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(tradingFeePercent)
            .div(10**20);
    }

    // calculate loan origination fee
    function _getBorrowingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(borrowingFeePercent)
            .div(10**20);
    }
    
    /**
     * @dev settles the trading fee and pays the token reward to the user.
     * @param user the address to send the reward to
     * @param loanId the Id of the associated loan - used for logging only.
     * @param feeToken the address of the token in which the trading fee is paid
     * */
    function _payTradingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 tradingFee)
        internal
    {
        if (tradingFee != 0) {
            //increase the storage variable keeping track of the accumulated fees
            tradingFeeTokensHeld[feeToken] = tradingFeeTokensHeld[feeToken]
                .add(tradingFee);

            emit PayTradingFee(
                user,
                feeToken,
                loanId,
                tradingFee
            );
            
            //pay the token reward to the user
            _payFeeReward(
                user,
                loanId,
                feeToken,
                tradingFee
            );
        }
    }
    
    /**
     * @dev settles the borrowing fee and pays the token reward to the user.
     * @param user the address to send the reward to
     * @param loanId the Id of the associated loan - used for logging only.
     * @param feeToken the address of the token in which the borrowig fee is paid
     * @param borrowingFee the height of the fee
     * */
    function _payBorrowingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 borrowingFee)
        internal
    {
        if (borrowingFee != 0) {
            //increase the storage variable keeping track of the accumulated fees
            borrowingFeeTokensHeld[feeToken] = borrowingFeeTokensHeld[feeToken]
                .add(borrowingFee);

            emit PayBorrowingFee(
                user,
                feeToken,
                loanId,
                borrowingFee
            );
            //pay the token reward to the user
            _payFeeReward(
                user,
                loanId,
                feeToken,
                borrowingFee
            );
        }
    }

    /**
     * @dev settles the lending fee (based on the interest). Pays no token reward to the user.
     * @param user the address to send the reward to
     * @param feeToken the address of the token in which the lending fee is paid
     * @param lendingFee the height of the fee
     * */
    function _payLendingFee(
        address user, // Notice
        address feeToken,
        uint256 lendingFee)
        internal
    {
        if (lendingFee != 0) {
            //increase the storage variable keeping track of the accumulated fees
            lendingFeeTokensHeld[feeToken] = lendingFeeTokensHeld[feeToken]
                .add(lendingFee);

            emit PayLendingFee(
                user,
                feeToken,
                lendingFee
            );

             //// NOTE: Lenders do not receive a fee reward ////
        }
    }

    // settles and pays borrowers based on the fees generated by their interest payments
    function _settleFeeRewardForInterestExpense(
        LoanInterest storage loanInterestLocal,
        bytes32 loanId,
        address feeToken,
        address user,
        uint256 interestTime)
        internal
    {
        // this represents the fee generated by a borrower's interest payment
        uint256 interestExpenseFee = interestTime
            .sub(loanInterestLocal.updatedTimestamp)
            .mul(loanInterestLocal.owedPerDay)
            .div(86400)
            .mul(lendingFeePercent)
            .div(10**20);

        loanInterestLocal.updatedTimestamp = interestTime;

        if (interestExpenseFee != 0) {
            _payFeeReward(
                user,
                loanId,
                feeToken,
                interestExpenseFee
            );
        }
    }


    /**
     * @dev pays the potocolToken reward to user. The reward is worth 50% of the trading/borrowing fee.
     * @param user the address to send the reward to
     * @param loanId the Id of the associeated loan - used for logging only.
     * @param feeToken the address of the token in which the trading/borrowig fee was paid
     * @param feeAmount the height of the fee
     * */
    function _payFeeReward(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 feeAmount)
        internal
    {
        uint256 rewardAmount;
        address _priceFeeds = priceFeeds;
        //note: this should be refactored.
        //calculate the reward amount, querying the price feed
        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).queryReturn.selector,
                feeToken,
                protocolTokenAddress, // price rewards using BZRX price rather than vesting token price
                feeAmount
                .mul(feeRebatePercent)
                .div(10**20)  
            )
        );
        assembly {
            if eq(success, 1) {
                rewardAmount := mload(add(data, 32))
            }
        }

        if (rewardAmount != 0) {
            address rewardToken;
            (rewardToken, success) = _withdrawProtocolToken(
                user,
                rewardAmount
            );
            if (success) {
                protocolTokenPaid = protocolTokenPaid
                    .add(rewardAmount);

                emit EarnReward(
                    user,
                    rewardToken,
                    loanId,
                    rewardAmount
                );
            }
        }
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface IPriceFeeds {
    function queryRate(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function queryPrecision(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 precision);

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        external
        view
        returns (uint256 destAmount);

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        external
        view
        returns (uint256 sourceToDestSwapRate);

    function amountInEth(
        address Token,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);

    function getFastGasPrice(
        address payToken)
        external
        view
        returns (uint256);
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract FeesEvents {
    event PayLendingFee(
        address indexed payer,
        address indexed token,
        uint256 amount
    );

    event PayTradingFee(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event PayBorrowingFee(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event EarnReward(
        address indexed receiver,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../openzeppelin/v2/token/ERC20/SafeERC20.sol";


contract ProtocolTokenUser is State {
    using SafeERC20 for IERC20;

    function _withdrawProtocolToken(
        address receiver,
        uint256 amount)
        internal
        returns (address, bool)
    {
        uint256 withdrawAmount = amount;

        uint256 tokenBalance = protocolTokenHeld;
        if (withdrawAmount > tokenBalance) {
            withdrawAmount = tokenBalance;
        }
        if (withdrawAmount == 0) {
            return (protocolTokenAddress, false);
        }

        protocolTokenHeld = tokenBalance
            .sub(withdrawAmount);

        IERC20(protocolTokenAddress).safeTransfer(
            receiver,
            withdrawAmount
        );

        return (protocolTokenAddress, true);
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract SwapsEvents {
    event LoanSwap(
        bytes32 indexed loanId,
        address indexed sourceToken,
        address indexed destToken,
        address borrower,
        uint256 sourceAmount,
        uint256 destAmount
    );

    event ExternalSwap(
        address indexed user,
        address indexed sourceToken,
        address indexed destToken,
        uint256 sourceAmount,
        uint256 destAmount
    );
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface ISwapsImpl {
    function internalSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount)
        external
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed);

    function internalExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount,
        address optionalContractAddress)
        external
        view
        returns (uint256);
}