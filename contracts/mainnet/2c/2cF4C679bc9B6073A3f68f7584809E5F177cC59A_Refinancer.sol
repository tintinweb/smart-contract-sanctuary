// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.7;

interface IERC20Like {

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function balanceOf(address account_) external view returns (uint256 balance_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}

interface ILenderLike {

    function poolDelegate() external view returns (address poolDelegate_);

}

interface IMapleGlobalsLike {

    function governor() external view returns (address governor_);

    function investorFee() external view returns (uint256 investorFee_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function protocolPaused() external view returns (bool paused_);

    function treasuryFee() external view returns (uint256 treasuryFee_);

}

interface IMapleLoanFactoryLike {

    function mapleGlobals() external view returns (address mapleGlobals_);

}

/// @title Small Library to standardize erc20 token interactions.
library ERC20Helper {

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function transfer(address token_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transfer.selector, to_, amount_));
    }

    function transferFrom(address token_, address from_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transferFrom.selector, from_, to_, amount_));
    }

    function approve(address token_, address spender_, uint256 amount_) internal returns (bool success_) {
        // If setting approval to zero fails, return false.
        if (!_call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, uint256(0)))) return false;

        // If `amount_` is zero, return true as the previous step already did this.
        if (amount_ == uint256(0)) return true;

        // Return the result of setting the approval to `amount_`.
        return _call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, amount_));
    }

    function _call(address token_, bytes memory data_) private returns (bool success_) {
        if (token_.code.length == uint256(0)) return false;

        bytes memory returnData;
        ( success_, returnData ) = token_.call(data_);

        return success_ && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }

}

/// @title Refinancer uses storage from Maple Loan.
interface IRefinancer {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   A new value for collateralRequired has been set.
     *  @param collateralRequired_ The new value for collateralRequired.
     */
    event CollateralRequiredSet(uint256 collateralRequired_);

    /**
     *  @dev   A new value for earlyFeeRate has been set.
     *  @param earlyFeeRate_ The new value for earlyFeeRate.
     */
    event EarlyFeeRateSet(uint256 earlyFeeRate_);

    /**
     *  @dev   A new value for endingPrincipal has been set.
     *  @param endingPrincipal_ The new value for endingPrincipal.
     */
    event EndingPrincipalSet(uint256 endingPrincipal_);

    /**
     *  @dev   A new value for gracePeriod has been set.
     *  @param gracePeriod_ The new value for gracePeriod.
     */
    event GracePeriodSet(uint256 gracePeriod_);

    /**
     *  @dev   A new value for interestRate has been set.
     *  @param interestRate_ The new value for interestRate.
     */
    event InterestRateSet(uint256 interestRate_);

    /**
     *  @dev   A new value for lateFeeRate has been set.
     *  @param lateFeeRate_ The new value for lateFeeRate.
     */
    event LateFeeRateSet(uint256 lateFeeRate_);

    /**
     *  @dev   A new value for lateInterestPremium has been set.
     *  @param lateInterestPremium_ The new value for lateInterestPremium.
     */
    event LateInterestPremiumSet(uint256 lateInterestPremium_);

    /**
     *  @dev   A new value for paymentInterval has been set.
     *  @param paymentInterval_ The new value for paymentInterval.
     */
    event PaymentIntervalSet(uint256 paymentInterval_);

    /**
     *  @dev   A new value for paymentsRemaining has been set.
     *  @param paymentsRemaining_ The new value for paymentsRemaining.
     */
    event PaymentsRemainingSet(uint256 paymentsRemaining_);

    /**
     *  @dev   The value of the principal has been decreased.
     *  @param decreasedBy_ The amount of which the value was decreased by.
     */
    event PrincipalDecreased(uint256 decreasedBy_);

    /**
     *  @dev   The value of the principal has been increased.
     *  @param increasedBy_ The amount of which the value was increased by.
     */
    event PrincipalIncreased(uint256 increasedBy_);

    /*****************/
    /*** Functions ***/
    /*****************/

    /**
     *  @dev   Function to decrease the principal during a refinance.
     *  @param amount_ The amount of which the value will decrease by.
     */
    function decreasePrincipal(uint256 amount_) external;

    /**
     *  @dev   Function to increase the principal during a refinance.
     *  @param amount_ The amount of which the value will increase by.
     */
    function increasePrincipal(uint256 amount_) external;

    /**
     *  @dev   Function to set the collateralRequired during a refinance.
     *  @param collateralRequired_ The new value for collateralRequired.
     */
    function setCollateralRequired(uint256 collateralRequired_) external;

    /**
     *  @dev   Function to set the earlyFeeRate during a refinance.
     *  @param earlyFeeRate_ The new value for earlyFeeRate.
     */
    function setEarlyFeeRate(uint256 earlyFeeRate_) external;

    /**
     *  @dev   Function to set the endingPrincipal during a refinance.
     *  @param endingPrincipal_ The new value for endingPrincipal.
     */
    function setEndingPrincipal(uint256 endingPrincipal_) external;

    /**
     *  @dev   Function to set the gracePeriod during a refinance.
     *  @param gracePeriod_ The new value for gracePeriod.
     */
    function setGracePeriod(uint256 gracePeriod_) external;

    /**
     *  @dev   Function to set the interestRate during a refinance.
     *  @param interestRate_ The new value for interestRate.
     */
    function setInterestRate(uint256 interestRate_) external;

    /**
     *  @dev   Function to set the lateFeeRate during a refinance.
     *  @param lateFeeRate_ The new value for lateFeeRate.
     */
    function setLateFeeRate(uint256 lateFeeRate_) external;

    /**
     *  @dev   Function to set the lateInterestPremium during a refinance.
     *  @param lateInterestPremium_ The new value for lateInterestPremium.
     */
    function setLateInterestPremium(uint256 lateInterestPremium_) external;

    /**
     *  @dev   Function to set the paymentInterval during a refinance.
     *  @param paymentInterval_ The new value for paymentInterval.
     */
    function setPaymentInterval(uint256 paymentInterval_) external;

    /**
     *  @dev   Function to set the paymentsRemaining during a refinance.
     *  @param paymentsRemaining_ The new value for paymentsRemaining.
     */
    function setPaymentsRemaining(uint256 paymentsRemaining_) external;

}

abstract contract SlotManipulatable {

    function _getReferenceTypeSlot(bytes32 slot_, bytes32 key_) internal pure returns (bytes32 value_) {
        return keccak256(abi.encodePacked(key_, slot_));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

/// @title An implementation that is to be proxied, will need ProxiedInternals.
abstract contract ProxiedInternals is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.factory') - 1`.
    bytes32 private constant FACTORY_SLOT = bytes32(0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1);

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    /// @dev Delegatecalls to a migrator contract to manipulate storage during an initialization or migration.
    function _migrate(address migrator_, bytes calldata arguments_) internal virtual returns (bool success_) {
        uint256 size;

        assembly {
            size := extcodesize(migrator_)
        }

        if (size == uint256(0)) return false;

        ( success_, ) = migrator_.delegatecall(arguments_);
    }

    /// @dev Sets the factory address in storage.
    function _setFactory(address factory_) internal virtual returns (bool success_) {
        _setSlotValue(FACTORY_SLOT, bytes32(uint256(uint160(factory_))));
        return true;
    }

    /// @dev Sets the implementation address in storage.
    function _setImplementation(address implementation_) internal virtual returns (bool success_) {
        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation_))));
        return true;
    }

    /// @dev Returns the factory address.
    function _factory() internal view virtual returns (address factory_) {
        return address(uint160(uint256(_getSlotValue(FACTORY_SLOT))));
    }

    /// @dev Returns the implementation address.
    function _implementation() internal view virtual returns (address implementation_) {
        return address(uint160(uint256(_getSlotValue(IMPLEMENTATION_SLOT))));
    }

}

/// @title A Maple implementation that is to be proxied, will need MapleProxiedInternals.
abstract contract MapleProxiedInternals is ProxiedInternals {}

/// @title MapleLoanInternals defines the storage layout and internal logic of MapleLoan.
abstract contract MapleLoanInternals is MapleProxiedInternals {

    uint256 private constant SCALED_ONE = uint256(10 ** 18);

    // Roles
    address internal _borrower;         // The address of the borrower.
    address internal _lender;           // The address of the lender.
    address internal _pendingBorrower;  // The address of the pendingBorrower, the only address that can accept the borrower role.
    address internal _pendingLender;    // The address of the pendingLender, the only address that can accept the lender role.

    // Assets
    address internal _collateralAsset;  // The address of the asset used as collateral.
    address internal _fundsAsset;       // The address of the asset used as funds.

    // Loan Term Parameters
    uint256 internal _gracePeriod;      // The number of seconds a payment can be late.
    uint256 internal _paymentInterval;  // The number of seconds between payments.

    // Rates
    uint256 internal _interestRate;         // The annualized interest rate of the loan.
    uint256 internal _earlyFeeRate;         // The fee rate for prematurely closing loans.
    uint256 internal _lateFeeRate;          // The fee rate for late payments.
    uint256 internal _lateInterestPremium;  // The amount to increase the interest rate by for late payments.

    // Requested Amounts
    uint256 internal _collateralRequired;  // The collateral the borrower is expected to put up to draw down all _principalRequested.
    uint256 internal _principalRequested;  // The funds the borrowers wants to borrow.
    uint256 internal _endingPrincipal;     // The principal to remain at end of loan.

    // State
    uint256 internal _drawableFunds;       // The amount of funds that can be drawn down.
    uint256 internal _claimableFunds;      // The amount of funds that the lender can claim (principal repayments, interest, etc).
    uint256 internal _collateral;          // The amount of collateral, in collateral asset, that is currently posted.
    uint256 internal _nextPaymentDueDate;  // The timestamp of due date of next payment.
    uint256 internal _paymentsRemaining;   // The number of payments remaining.
    uint256 internal _principal;           // The amount of principal yet to be paid down.

    // Refinance
    bytes32 internal _refinanceCommitment;

    /**********************************/
    /*** Internal General Functions ***/
    /**********************************/

    /// @dev Clears all state variables to end a loan, but keep borrower and lender withdrawal functionality intact.
    function _clearLoanAccounting() internal {
        _gracePeriod     = uint256(0);
        _paymentInterval = uint256(0);

        _interestRate        = uint256(0);
        _earlyFeeRate        = uint256(0);
        _lateFeeRate         = uint256(0);
        _lateInterestPremium = uint256(0);

        _endingPrincipal = uint256(0);

        _nextPaymentDueDate = uint256(0);
        _paymentsRemaining  = uint256(0);
        _principal          = uint256(0);
    }

    /**
     *  @dev   Initializes the loan.
     *  @param borrower_    The address of the borrower.
     *  @param assets_      Array of asset addresses.
     *                          [0]: collateralAsset,
     *                          [1]: fundsAsset.
     *  @param termDetails_ Array of loan parameters:
     *                          [0]: gracePeriod,
     *                          [1]: paymentInterval,
     *                          [2]: payments,
     *  @param amounts_     Requested amounts:
     *                          [0]: collateralRequired,
     *                          [1]: principalRequested,
     *                          [2]: endingPrincipal.
     *  @param rates_       Fee parameters:
     *                          [0]: interestRate,
     *                          [1]: earlyFeeRate,
     *                          [2]: lateFeeRate,
     *                          [3]: lateInterestPremium.
     */
    function _initialize(
        address borrower_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_
    )
        internal
    {
        // Principal requested needs to be non-zero (see `_getCollateralRequiredFor` math).
        require(amounts_[1] > uint256(0), "MLI:I:INVALID_PRINCIPAL");

        // Ending principal needs to be less than or equal to principal requested.
        require(amounts_[2] <= amounts_[1], "MLI:I:INVALID_ENDING_PRINCIPAL");

        require((_borrower = borrower_) != address(0), "MLI:I:INVALID_BORROWER");

        _collateralAsset = assets_[0];
        _fundsAsset      = assets_[1];

        _gracePeriod       = termDetails_[0];
        _paymentInterval   = termDetails_[1];
        _paymentsRemaining = termDetails_[2];

        _collateralRequired = amounts_[0];
        _principalRequested = amounts_[1];
        _endingPrincipal    = amounts_[2];

        _interestRate        = rates_[0];
        _earlyFeeRate        = rates_[1];
        _lateFeeRate         = rates_[2];
        _lateInterestPremium = rates_[3];
    }

    /**************************************/
    /*** Internal Borrow-side Functions ***/
    /**************************************/

    /// @dev Prematurely ends a loan by making all remaining payments.
    function _closeLoan() internal returns (uint256 principal_, uint256 interest_) {
        require(block.timestamp <= _nextPaymentDueDate, "MLI:CL:PAYMENT_IS_LATE");

        ( principal_, interest_ ) = _getEarlyPaymentBreakdown();

        uint256 totalPaid = principal_ + interest_;

        // The drawable funds are increased by the extra funds in the contract, minus the total needed for payment.
        _drawableFunds = _drawableFunds + _getUnaccountedAmount(_fundsAsset) - totalPaid;

        _claimableFunds += totalPaid;

        _clearLoanAccounting();
    }

    /// @dev Sends `amount_` of `_drawableFunds` to `destination_`.
    function _drawdownFunds(uint256 amount_, address destination_) internal {
        _drawableFunds -= amount_;

        require(ERC20Helper.transfer(_fundsAsset, destination_, amount_), "MLI:DF:TRANSFER_FAILED");
        require(_isCollateralMaintained(),                                "MLI:DF:INSUFFICIENT_COLLATERAL");
    }

    /// @dev Makes a payment to progress the loan closer to maturity.
    function _makePayment() internal returns (uint256 principal_, uint256 interest_) {
        ( principal_, interest_ ) = _getNextPaymentBreakdown();

        uint256 totalPaid = principal_ + interest_;

        // The drawable funds are increased by the extra funds in the contract, minus the total needed for payment.
        // NOTE: This line will revert if not enough funds were added for the full payment amount.
        _drawableFunds = (_drawableFunds + _getUnaccountedAmount(_fundsAsset)) - totalPaid;

        _claimableFunds += totalPaid;

        uint256 paymentsRemaining = _paymentsRemaining;

        if (paymentsRemaining == uint256(1)) {
            _clearLoanAccounting();  // Assumes `_getNextPaymentBreakdown` returns a `principal_` that is `_principal`.
        } else {
            _nextPaymentDueDate += _paymentInterval;
            _principal          -= principal_;
            _paymentsRemaining   = paymentsRemaining - uint256(1);
        }
    }

    /// @dev Registers the delivery of an amount of collateral to be posted.
    function _postCollateral() internal returns (uint256 collateralPosted_) {
        _collateral += (collateralPosted_ = _getUnaccountedAmount(_collateralAsset));
    }

    /// @dev Sets refinance commitment given refinance operations.
    function _proposeNewTerms(address refinancer_, bytes[] calldata calls_) internal returns (bytes32 proposedRefinanceCommitment_) {
        // NOTE: There is no way to invalidate the `refinanceCommitment` (i.e. bytes32(0)) without explicitly setting it if `calls_.length` is 0.
        return _refinanceCommitment =
            calls_.length > uint256(0)
                ? _getRefinanceCommitment(refinancer_, calls_)
                : bytes32(0);
    }

    /// @dev Sends `amount_` of `_collateral` to `destination_`.
    function _removeCollateral(uint256 amount_, address destination_) internal {
        _collateral -= amount_;

        require(ERC20Helper.transfer(_collateralAsset, destination_, amount_), "MLI:RC:TRANSFER_FAILED");
        require(_isCollateralMaintained(),                                     "MLI:RC:INSUFFICIENT_COLLATERAL");
    }

    /// @dev Registers the delivery of an amount of funds to be returned as `_drawableFunds`.
    function _returnFunds() internal returns (uint256 fundsReturned_) {
        _drawableFunds += (fundsReturned_ = _getUnaccountedAmount(_fundsAsset));
    }

    /************************************/
    /*** Internal Lend-side Functions ***/
    /************************************/

    /// @dev Processes refinance operations.
    function _acceptNewTerms(address refinancer_, bytes[] calldata calls_) internal returns (bytes32 acceptedRefinanceCommitment_) {
        // NOTE: A zero refinancer address and/or empty calls array will never (probabilistically) match a refinance commitment in storage.
        require(_refinanceCommitment == (acceptedRefinanceCommitment_ = _getRefinanceCommitment(refinancer_, calls_)), "MLI:ANT:COMMITMENT_MISMATCH");

        require(refinancer_.code.length != uint256(0), "MLI:ANT:INVALID_REFINANCER");

        // Clear refinance commitment to prevent implications of re-acceptance of another call to `_acceptNewTerms`.
        _refinanceCommitment = bytes32(0);

        uint256 callCount = calls_.length;

        for (uint256 i; i < callCount; ++i) {
            ( bool success, ) = refinancer_.delegatecall(calls_[i]);
            require(success, "MLI:ANT:FAILED");
        }

        // Ensure that collateral is maintained after changes made.
        require(_isCollateralMaintained(), "MLI:ANT:INSUFFICIENT_COLLATERAL");
    }

    /// @dev Sends `amount_` of `_claimableFunds` to `destination_`.
    ///      If `amount_` is higher than `_claimableFunds` the transaction will underflow and revert.
    function _claimFunds(uint256 amount_, address destination_) internal {
        _claimableFunds -= amount_;

        require(ERC20Helper.transfer(_fundsAsset, destination_, amount_), "MLI:CF:TRANSFER_FAILED");
    }

    /// @dev Fund the loan and kick off the repayment requirements.
    function _fundLoan(address lender_) internal returns (uint256 fundsLent_) {
        uint256 paymentsRemaining = _paymentsRemaining;

        // Can only fund loan if there are payments remaining (as defined by the initialization) and no payment is due yet (as set by a funding).
        require((_nextPaymentDueDate == uint256(0)) && (paymentsRemaining != uint256(0)), "MLI:FL:LOAN_ACTIVE");

        uint256 paymentInterval = _paymentInterval;

        // NOTE: Don't need to check if lender_ is nonzero or valid, since it is done implicitly in calls to `lender_` below.
        _lender = lender_;

        _nextPaymentDueDate = block.timestamp + paymentInterval;

        // Amount funded and principal are as requested.
        fundsLent_ = _principal = _principalRequested;

        address fundsAsset = _fundsAsset;

        // Cannot under-fund loan, but over-funding results in additional funds left unaccounted for.
        require(_getUnaccountedAmount(fundsAsset) >= fundsLent_, "MLI:FL:WRONG_FUND_AMOUNT");

        IMapleGlobalsLike globals = IMapleGlobalsLike(IMapleLoanFactoryLike(_factory()).mapleGlobals());

        // Transfer the annualized treasury fee, if any, to the Maple treasury, and decrement drawable funds.
        uint256 treasuryFee = (fundsLent_ * globals.treasuryFee() * paymentInterval * paymentsRemaining) / uint256(365 days * 10_000);

        // Transfer delegate fee, if any, to the pool delegate, and decrement drawable funds.
        uint256 delegateFee = (fundsLent_ * globals.investorFee() * paymentInterval * paymentsRemaining) / uint256(365 days * 10_000);

        // Drawable funds is the amount funded, minus any fees.
        _drawableFunds = fundsLent_ - treasuryFee - delegateFee;

        require(
            treasuryFee == uint256(0) || ERC20Helper.transfer(fundsAsset, globals.mapleTreasury(), treasuryFee),
            "MLI:FL:T_TRANSFER_FAILED"
        );

        require(
            delegateFee == uint256(0) || ERC20Helper.transfer(fundsAsset, ILenderLike(lender_).poolDelegate(), delegateFee),
            "MLI:FL:PD_TRANSFER_FAILED"
        );
    }

    /// @dev Reset all state variables in order to release funds and collateral of a loan in default.
    function _repossess(address destination_) internal returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_) {
        uint256 nextPaymentDueDate = _nextPaymentDueDate;

        require(
            nextPaymentDueDate != uint256(0) && (block.timestamp > nextPaymentDueDate + _gracePeriod),
            "MLI:R:NOT_IN_DEFAULT"
        );

        _clearLoanAccounting();

        // Uniquely in `_repossess`, stop accounting for all funds so that they can be swept.
        _collateral     = uint256(0);
        _claimableFunds = uint256(0);
        _drawableFunds  = uint256(0);

        address collateralAsset = _collateralAsset;

        // Either there is no collateral to repossess, or the transfer of the collateral succeeds.
        require(
            (collateralRepossessed_ = _getUnaccountedAmount(collateralAsset)) == uint256(0) ||
            ERC20Helper.transfer(collateralAsset, destination_, collateralRepossessed_),
            "MLI:R:C_TRANSFER_FAILED"
        );

        address fundsAsset = _fundsAsset;

        // Either there are no funds to repossess, or the transfer of the funds succeeds.
        require(
            (fundsRepossessed_ = _getUnaccountedAmount(fundsAsset)) == uint256(0) ||
            ERC20Helper.transfer(fundsAsset, destination_, fundsRepossessed_),
            "MLI:R:F_TRANSFER_FAILED"
        );
    }

    /*******************************/
    /*** Internal View Functions ***/
    /*******************************/

    /// @dev Returns whether the amount of collateral posted is commensurate with the amount of drawn down (outstanding) principal.
    function _isCollateralMaintained() internal view returns (bool isMaintained_) {
        return _collateral >= _getCollateralRequiredFor(_principal, _drawableFunds, _principalRequested, _collateralRequired);
    }

    /// @dev Get principal and interest breakdown for paying off the entire loan early.
    function _getEarlyPaymentBreakdown() internal view returns (uint256 principal_, uint256 interest_) {
        interest_ = ((principal_ = _principal) * _earlyFeeRate) / SCALED_ONE;
    }

    /// @dev Get principal and interest breakdown for next standard payment.
    function _getNextPaymentBreakdown() internal view returns (uint256 principal_, uint256 interest_) {
        ( principal_, interest_ ) = _getPaymentBreakdown(
            block.timestamp,
            _nextPaymentDueDate,
            _paymentInterval,
            _principal,
            _endingPrincipal,
            _paymentsRemaining,
            _interestRate,
            _lateFeeRate,
            _lateInterestPremium
        );
    }

    /// @dev Returns the amount of an `asset_` that this contract owns, which is not currently accounted for by its state variables.
    function _getUnaccountedAmount(address asset_) internal view virtual returns (uint256 unaccountedAmount_) {
        return IERC20Like(asset_).balanceOf(address(this))
            - (asset_ == _collateralAsset ? _collateral : uint256(0))                   // `_collateral` is `_collateralAsset` accounted for.
            - (asset_ == _fundsAsset ? _claimableFunds + _drawableFunds : uint256(0));  // `_claimableFunds` and `_drawableFunds` are `_fundsAsset` accounted for.
    }

    /*******************************/
    /*** Internal Pure Functions ***/
    /*******************************/

    /// @dev Returns the total collateral to be posted for some drawn down (outstanding) principal and overall collateral ratio requirement.
    function _getCollateralRequiredFor(
        uint256 principal_,
        uint256 drawableFunds_,
        uint256 principalRequested_,
        uint256 collateralRequired_
    )
        internal pure returns (uint256 collateral_)
    {
        // Where (collateral / outstandingPrincipal) should be greater or equal to (collateralRequired / principalRequested).
        // NOTE: principalRequested_ cannot be 0, which is reasonable, since it means this was never a loan.
        return principal_ <= drawableFunds_ ? uint256(0) : (collateralRequired_ * (principal_ - drawableFunds_)) / principalRequested_;
    }

    /// @dev Returns principal and interest portions of a payment instalment, given generic, stateless loan parameters.
    function _getInstallment(uint256 principal_, uint256 endingPrincipal_, uint256 interestRate_, uint256 paymentInterval_, uint256 totalPayments_)
        internal pure virtual returns (uint256 principalAmount_, uint256 interestAmount_)
    {
        /*************************************************************************************************\
         *                             |                                                                 *
         * A = installment amount      |      /                         \     /           R           \  *
         * P = principal remaining     |     |  /                 \      |   | ----------------------- | *
         * R = interest rate           | A = | | P * ( 1 + R ) ^ N | - E | * |   /             \       | *
         * N = payments remaining      |     |  \                 /      |   |  | ( 1 + R ) ^ N | - 1  | *
         * E = ending principal target |      \                         /     \  \             /      /  *
         *                             |                                                                 *
         *                             |---------------------------------------------------------------- *
         *                                                                                               *
         * - Where R           is `periodicRate`                                                         *
         * - Where (1 + R) ^ N is `raisedRate`                                                           *
         * - Both of these rates are scaled by 1e18 (e.g., 12% => 0.12 * 10 ** 18)                       *
        \*************************************************************************************************/

        uint256 periodicRate = _getPeriodicInterestRate(interestRate_, paymentInterval_);
        uint256 raisedRate   = _scaledExponent(SCALED_ONE + periodicRate, totalPayments_, SCALED_ONE);

        // NOTE: If a lack of precision in `_scaledExponent` results in a `raisedRate` smaller than one, assume it to be one and simplify the equation.
        if (raisedRate <= SCALED_ONE) return ((principal_ - endingPrincipal_) / totalPayments_, uint256(0));

        uint256 total = ((((principal_ * raisedRate) / SCALED_ONE) - endingPrincipal_) * periodicRate) / (raisedRate - SCALED_ONE);

        interestAmount_  = _getInterest(principal_, interestRate_, paymentInterval_);
        principalAmount_ = total >= interestAmount_ ? total - interestAmount_ : uint256(0);
    }

    /// @dev Returns an amount by applying an annualized and scaled interest rate, to a principal, over an interval of time.
    function _getInterest(uint256 principal_, uint256 interestRate_, uint256 interval_) internal pure virtual returns (uint256 interest_) {
        return (principal_ * _getPeriodicInterestRate(interestRate_, interval_)) / SCALED_ONE;
    }

    /// @dev Returns total principal and interest portion of a number of payments, given generic, stateless loan parameters and loan state.
    function _getPaymentBreakdown(
        uint256 currentTime_,
        uint256 nextPaymentDueDate_,
        uint256 paymentInterval_,
        uint256 principal_,
        uint256 endingPrincipal_,
        uint256 paymentsRemaining_,
        uint256 interestRate_,
        uint256 lateFeeRate_,
        uint256 lateInterestPremium_
    )
        internal pure virtual
        returns (uint256 principalAmount_, uint256 interestAmount_)
    {
        ( principalAmount_, interestAmount_ ) = _getInstallment(
            principal_,
            endingPrincipal_,
            interestRate_,
            paymentInterval_,
            paymentsRemaining_
        );

        principalAmount_ = paymentsRemaining_ == uint256(1) ? principal_ : principalAmount_;

        if (currentTime_ > nextPaymentDueDate_) {
            uint256 daysLate = (((currentTime_ - nextPaymentDueDate_ - 1) / 1 days) + 1) * 1 days;

            interestAmount_ += _getInterest(principal_, interestRate_ + lateInterestPremium_, daysLate);
            interestAmount_ += (lateFeeRate_ * principal_) / SCALED_ONE;
        }
    }

    /// @dev Returns the interest rate over an interval, given an annualized interest rate.
    function _getPeriodicInterestRate(uint256 interestRate_, uint256 interval_) internal pure virtual returns (uint256 periodicInterestRate_) {
        return (interestRate_ * interval_) / uint256(365 days);
    }

    /// @dev Returns refinance commitment given refinance parameters.
    function _getRefinanceCommitment(address refinancer_, bytes[] calldata calls_) internal pure returns (bytes32 refinanceCommitment_) {
        return keccak256(abi.encode(refinancer_, calls_));
    }

    /**
     *  @dev Returns exponentiation of a scaled base value.
     *
     *       Walk through example:
     *       LINE  |  base_          |  exponent_  |  one_  |  result_
     *             |  3_00           |  18         |  1_00  |  0_00
     *        A    |  3_00           |  18         |  1_00  |  1_00
     *        B    |  3_00           |  9          |  1_00  |  1_00
     *        C    |  9_00           |  9          |  1_00  |  1_00
     *        D    |  9_00           |  9          |  1_00  |  9_00
     *        B    |  9_00           |  4          |  1_00  |  9_00
     *        C    |  81_00          |  4          |  1_00  |  9_00
     *        B    |  81_00          |  2          |  1_00  |  9_00
     *        C    |  6_561_00       |  2          |  1_00  |  9_00
     *        B    |  6_561_00       |  1          |  1_00  |  9_00
     *        C    |  43_046_721_00  |  1          |  1_00  |  9_00
     *        D    |  43_046_721_00  |  1          |  1_00  |  387_420_489_00
     *        B    |  43_046_721_00  |  0          |  1_00  |  387_420_489_00
     *
     * Another implementation of this algorithm can be found in Dapphub's DSMath contract:
     * https://github.com/dapphub/ds-math/blob/ce67c0fa9f8262ecd3d76b9e4c026cda6045e96c/src/math.sol#L77
     */
    function _scaledExponent(uint256 base_, uint256 exponent_, uint256 one_) internal pure returns (uint256 result_) {
        // If exponent_ is odd, set result_ to base_, else set to one_.
        result_ = exponent_ & uint256(1) != uint256(0) ? base_ : one_;          // A

        // Divide exponent_ by 2 (overwriting itself) and proceed if not zero.
        while ((exponent_ >>= uint256(1)) != uint256(0)) {                      // B
            base_ = (base_ * base_) / one_;                                     // C

            // If exponent_ is even, go back to top.
            if (exponent_ & uint256(1) == uint256(0)) continue;

            // If exponent_ is odd, multiply result_ is multiplied by base_.
            result_ = (result_ * base_) / one_;                                 // D
        }
    }

}

/// @title Refinancer uses storage from a MapleLoan defined by MapleLoanInternals.
contract Refinancer is IRefinancer, MapleLoanInternals {

    function decreasePrincipal(uint256 amount_) external override {
        require(_drawableFunds >= amount_, "R:DP:OUTSTANDING_TOO_LARGE");

        _principal          -= amount_;
        _principalRequested -= amount_;
        _drawableFunds      -= amount_;

        require(_principal >= _endingPrincipal, "R:DP:BELOW_ENDING_PRINCIPAL");

        emit PrincipalDecreased(amount_);
    }

    function increasePrincipal(uint256 amount_) external override {
        // Cannot under-fund the principal increase, but over-funding results in additional funds left unaccounted for.
        require(_getUnaccountedAmount(_fundsAsset) >= amount_, "R:IP:INSUFFICIENT_AMOUNT");

        _principal          += amount_;
        _principalRequested += amount_;
        _drawableFunds      += amount_;

        emit PrincipalIncreased(amount_);
    }

    function setCollateralRequired(uint256 collateralRequired_) external override {
        emit CollateralRequiredSet(_collateralRequired = collateralRequired_);
    }

    function setEarlyFeeRate(uint256 earlyFeeRate_) external override {
        emit EarlyFeeRateSet(_earlyFeeRate = earlyFeeRate_);
    }

    function setEndingPrincipal(uint256 endingPrincipal_) external override {
        require(endingPrincipal_ <= _principal, "R:DP:ABOVE_CURRENT_PRINCIPAL");
        emit EndingPrincipalSet(_endingPrincipal = endingPrincipal_);
    }

    function setGracePeriod(uint256 gracePeriod_) external override {
        emit GracePeriodSet(_gracePeriod = gracePeriod_);
    }

    function setInterestRate(uint256 interestRate_) external override {
        emit InterestRateSet(_interestRate = interestRate_);
    }

    function setLateFeeRate(uint256 lateFeeRate_) external override {
        emit LateFeeRateSet(_lateFeeRate = lateFeeRate_);
    }

    function setLateInterestPremium(uint256 lateInterestPremium_) external override {
        emit LateInterestPremiumSet(_lateInterestPremium = lateInterestPremium_);
    }

    function setPaymentInterval(uint256 paymentInterval_) external override {
        emit PaymentIntervalSet(_paymentInterval = paymentInterval_);
    }

    function setPaymentsRemaining(uint256 paymentsRemaining_) external override {
        emit PaymentsRemainingSet(_paymentsRemaining = paymentsRemaining_);
    }

}