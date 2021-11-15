pragma solidity ^0.5.16;

contract ErrorReporter {
    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint256 error, uint256 info, uint256 detail);

    enum Error {
        NO_ERROR,
        OPAQUE_ERROR, // To be used when reporting errors from upgradeable contracts; the opaque code should be given as `detail` in the `Failure` event
        UNAUTHORIZED,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW,
        DIVISION_BY_ZERO,
        BAD_INPUT,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_TRANSFER_FAILED,
        MARKET_NOT_SUPPORTED,
        SUPPLY_RATE_CALCULATION_FAILED,
        BORROW_RATE_CALCULATION_FAILED,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_OUT_FAILED,
        INSUFFICIENT_LIQUIDITY,
        INSUFFICIENT_BALANCE,
        INVALID_COLLATERAL_RATIO,
        MISSING_ASSET_PRICE,
        EQUITY_INSUFFICIENT_BALANCE,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        ASSET_NOT_PRICED,
        INVALID_LIQUIDATION_DISCOUNT,
        INVALID_COMBINED_RISK_PARAMETERS
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        BORROW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED,
        BORROW_ACCOUNT_SHORTFALL_PRESENT,
        BORROW_AMOUNT_LIQUIDITY_SHORTFALL,
        BORROW_AMOUNT_VALUE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_SUPPORTED,
        BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        BORROW_NEW_BORROW_RATE_CALCULATION_FAILED,
        BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED,
        BORROW_ORIGINATION_FEE_CALCULATION_FAILED,
        BORROW_TRANSFER_OUT_FAILED,
        EQUITY_WITHDRAWAL_AMOUNT_VALIDATION,
        EQUITY_WITHDRAWAL_CALCULATE_EQUITY,
        EQUITY_WITHDRAWAL_MODEL_OWNER_CHECK,
        EQUITY_WITHDRAWAL_TRANSFER_OUT_FAILED,
        LIQUIDATE_ACCUMULATED_BORROW_BALANCE_CALCULATION_FAILED,
        LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET,
        LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET,
        LIQUIDATE_AMOUNT_SEIZE_CALCULATION_FAILED,
        LIQUIDATE_BORROW_DENOMINATED_COLLATERAL_CALCULATION_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_TOO_HIGH,
        LIQUIDATE_DISCOUNTED_REPAY_TO_EVEN_AMOUNT_CALCULATION_FAILED,
        LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET,
        LIQUIDATE_NEW_BORROW_RATE_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET,
        LIQUIDATE_NEW_SUPPLY_RATE_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_TOTAL_BORROW_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_TOTAL_CASH_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET,
        LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET,
        LIQUIDATE_TRANSFER_IN_FAILED,
        LIQUIDATE_TRANSFER_IN_NOT_POSSIBLE,
        REPAY_BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_BORROW_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_ADMIN_OWNER_CHECK,
        SET_ASSET_PRICE_CHECK_ORACLE,
        SET_MARKET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_ORACLE_OWNER_CHECK,
        SET_ORIGINATION_FEE_OWNER_CHECK,
        SET_RISK_PARAMETERS_OWNER_CHECK,
        SET_RISK_PARAMETERS_VALIDATION,
        SUPPLY_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        SUPPLY_MARKET_NOT_SUPPORTED,
        SUPPLY_NEW_BORROW_INDEX_CALCULATION_FAILED,
        SUPPLY_NEW_BORROW_RATE_CALCULATION_FAILED,
        SUPPLY_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        SUPPLY_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        SUPPLY_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        SUPPLY_NEW_TOTAL_CASH_CALCULATION_FAILED,
        SUPPLY_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        SUPPLY_TRANSFER_IN_FAILED,
        SUPPLY_TRANSFER_IN_NOT_POSSIBLE,
        SUPPORT_MARKET_OWNER_CHECK,
        SUPPORT_MARKET_PRICE_CHECK,
        SUSPEND_MARKET_OWNER_CHECK,
        WITHDRAW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED,
        WITHDRAW_ACCOUNT_SHORTFALL_PRESENT,
        WITHDRAW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        WITHDRAW_AMOUNT_LIQUIDITY_SHORTFALL,
        WITHDRAW_AMOUNT_VALUE_CALCULATION_FAILED,
        WITHDRAW_CAPACITY_CALCULATION_FAILED,
        WITHDRAW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        WITHDRAW_NEW_BORROW_RATE_CALCULATION_FAILED,
        WITHDRAW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        WITHDRAW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        WITHDRAW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        WITHDRAW_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        WITHDRAW_TRANSFER_OUT_FAILED,
        WITHDRAW_TRANSFER_OUT_NOT_POSSIBLE
    }

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), 0);

        return uint256(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(FailureInfo info, uint256 opaqueError) internal returns (uint256) {
        emit Failure(uint256(Error.OPAQUE_ERROR), uint256(info), opaqueError);

        return uint256(Error.OPAQUE_ERROR);
    }
}

contract CarefulMath is ErrorReporter {
    /**
     * @dev Multiplies two numbers, returns an error on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (Error, uint256) {
        if (a == 0) {
            return (Error.NO_ERROR, 0);
        }

        uint256 c = a * b;

        if (c / a != b) {
            return (Error.INTEGER_OVERFLOW, 0);
        } else {
            return (Error.NO_ERROR, c);
        }
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (Error, uint256) {
        if (b == 0) {
            return (Error.DIVISION_BY_ZERO, 0);
        }

        return (Error.NO_ERROR, a / b);
    }

    /**
     * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (Error, uint256) {
        if (b <= a) {
            return (Error.NO_ERROR, a - b);
        } else {
            return (Error.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
     * @dev Adds two numbers, returns an error on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (Error, uint256) {
        uint256 c = a + b;

        if (c >= a) {
            return (Error.NO_ERROR, c);
        } else {
            return (Error.INTEGER_OVERFLOW, 0);
        }
    }

    /**
     * @dev add a and b and then subtract c
     */
    function addThenSub(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (Error, uint256) {
        (Error err0, uint256 sum) = add(a, b);

        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        return sub(sum, c);
    }
}

contract Exponential is ErrorReporter, CarefulMath {
    // TODO: We may wish to put the result of 10**18 here instead of the expression.
    // Per https://solidity.readthedocs.io/en/latest/contracts.html#constant-state-variables
    // the optimizer MAY replace the expression 10**18 with its calculated value.
    uint256 constant expScale = 10**18;

    // See TODO on expScale
    uint256 constant halfExpScale = expScale / 2;

    struct Exp {
        uint256 mantissa;
    }

    uint256 constant mantissaOne = 10**18;
    uint256 constant mantissaOneTenth = 10**17;

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint256 num, uint256 denom) internal pure returns (Error, Exp memory) {
        (Error err0, uint256 scaledNumerator) = mul(num, expScale);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (Error err1, uint256 rational) = div(scaledNumerator, denom);
        if (err1 != Error.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) internal pure returns (Error, Exp memory) {
        (Error error, uint256 result) = add(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) internal pure returns (Error, Exp memory) {
        (Error error, uint256 result) = sub(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint256 scalar) internal pure returns (Error, Exp memory) {
        (Error err0, uint256 scaledMantissa) = mul(a.mantissa, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint256 scalar) internal pure returns (Error, Exp memory) {
        (Error err0, uint256 descaledMantissa) = div(a.mantissa, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (Error, Exp memory) {
        /*
            We are doing this as:
            getExp(mul(expScale, scalar), divisor.mantissa)

            How it works:
            Exp = a / b;
            Scalar = s;
            `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (Error err0, uint256 numerator) = mul(expScale, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) internal pure returns (Error, Exp memory) {
        (Error err0, uint256 doubleScaledProduct) = mul(a.mantissa, b.mantissa);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (Error err1, uint256 doubleScaledProductWithHalfScale) = add(halfExpScale, doubleScaledProduct);
        if (err1 != Error.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (Error err2, uint256 product) = div(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is Error.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == Error.NO_ERROR);

        return (Error.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) internal pure returns (Error, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * (10**18)}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / 10**18;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa < right.mantissa; //TODO: Add some simple tests and this in another PR yo.
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if first Exp is greater than second Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }
}

contract PriceOracleV1 is Exponential {
    /**
     * @dev flag for whether or not contract is paused
     *
     */
    bool public paused;

    uint256 public constant numBlocksPerPeriod = 240; // approximately 1 hour: 60 seconds/minute * 60 minutes/hour * 1 block/15 seconds

    uint256 public constant maxSwingMantissa = (10**17); // 0.1

    /**
     * @dev Mapping of asset addresses and their corresponding price in terms of Eth-Wei
     *      which is simply equal to AssetWeiPrice * 10e18. For instance, if OMG token was
     *      worth 5x Eth then the price for OMG would be 5*10e18 or Exp({mantissa: 5000000000000000000}).
     * map: assetAddress -> Exp
     */
    mapping(address => Exp) public _assetPrices;

    constructor(address _poster) public {
        anchorAdmin = msg.sender;
        poster = _poster;
        maxSwing = Exp({mantissa: maxSwingMantissa});
    }

    /**
     * @notice Do not pay into PriceOracle
     */
    function() external payable {
        revert();
    }

    enum OracleError {
        NO_ERROR,
        UNAUTHORIZED,
        FAILED_TO_SET_PRICE
    }

    enum OracleFailureInfo {
        ACCEPT_ANCHOR_ADMIN_PENDING_ANCHOR_ADMIN_CHECK,
        SET_PAUSED_OWNER_CHECK,
        SET_PENDING_ANCHOR_ADMIN_OWNER_CHECK,
        SET_PENDING_ANCHOR_PERMISSION_CHECK,
        SET_PRICE_CALCULATE_SWING,
        SET_PRICE_CAP_TO_MAX,
        SET_PRICE_MAX_SWING_CHECK,
        SET_PRICE_NO_ANCHOR_PRICE_OR_INITIAL_PRICE_ZERO,
        SET_PRICE_PERMISSION_CHECK,
        SET_PRICE_ZERO_PRICE,
        SET_PRICES_PARAM_VALIDATION
    }

    /**
     * @dev `msgSender` is msg.sender; `error` corresponds to enum OracleError; `info` corresponds to enum OracleFailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event OracleFailure(address msgSender, address asset, uint256 error, uint256 info, uint256 detail);

    /**
     * @dev use this when reporting a known error from the price oracle or a non-upgradeable collaborator
     *      Using Oracle in name because we already inherit a `fail` function from ErrorReporter.sol via Exponential.sol
     */
    function failOracle(
        address asset,
        OracleError err,
        OracleFailureInfo info
    ) internal returns (uint256) {
        emit OracleFailure(msg.sender, asset, uint256(err), uint256(info), 0);

        return uint256(err);
    }

    /**
     * @dev Use this when reporting an error from the money market. Give the money market result as `details`
     */
    function failOracleWithDetails(
        address asset,
        OracleError err,
        OracleFailureInfo info,
        uint256 details
    ) internal returns (uint256) {
        emit OracleFailure(msg.sender, asset, uint256(err), uint256(info), details);

        return uint256(err);
    }

    /**
     * @dev An administrator who can set the pending anchor value for assets.
     *      Set in the constructor.
     */
    address public anchorAdmin;

    /**
     * @dev pending anchor administrator for this contract.
     */
    address public pendingAnchorAdmin;

    /**
     * @dev Address of the price poster.
     *      Set in the constructor.
     */
    address public poster;

    /**
     * @dev maxSwing the maximum allowed percentage difference between a new price and the anchor's price
     *      Set only in the constructor
     */
    Exp public maxSwing;

    struct Anchor {
        // floor(block.number / numBlocksPerPeriod) + 1
        uint256 period;
        // Price in ETH, scaled by 10**18
        uint256 priceMantissa;
    }

    /**
     * @dev anchors by asset
     */
    mapping(address => Anchor) public anchors;

    /**
     * @dev pending anchor prices by asset
     */
    mapping(address => uint256) public pendingAnchors;

    /**
     * @dev emitted when a pending anchor is set
     * @param asset Asset for which to set a pending anchor
     * @param oldScaledPrice if an unused pending anchor was present, its value; otherwise 0.
     * @param newScaledPrice the new scaled pending anchor price
     */
    event NewPendingAnchor(address anchorAdmin, address asset, uint256 oldScaledPrice, uint256 newScaledPrice);

    /**
     * @notice provides ability to override the anchor price for an asset
     * @dev Admin function to set the anchor price for an asset
     * @param asset Asset for which to override the anchor price
     * @param newScaledPrice New anchor price
     * @return uint 0=success, otherwise a failure (see enum OracleError for details)
     */
    function _setPendingAnchor(address asset, uint256 newScaledPrice) public returns (uint256) {
        // Check caller = anchorAdmin. Note: Deliberately not allowing admin. They can just change anchorAdmin if desired.
        if (msg.sender != anchorAdmin) {
            return failOracle(asset, OracleError.UNAUTHORIZED, OracleFailureInfo.SET_PENDING_ANCHOR_PERMISSION_CHECK);
        }

        uint256 oldScaledPrice = pendingAnchors[asset];
        pendingAnchors[asset] = newScaledPrice;

        emit NewPendingAnchor(msg.sender, asset, oldScaledPrice, newScaledPrice);

        return uint256(OracleError.NO_ERROR);
    }

    /**
     * @dev emitted for all price changes
     */
    event PricePosted(
        address asset,
        uint256 previousPriceMantissa,
        uint256 requestedPriceMantissa,
        uint256 newPriceMantissa
    );

    /**
     * @dev emitted if this contract successfully posts a capped-to-max price to the money market
     */
    event CappedPricePosted(
        address asset,
        uint256 requestedPriceMantissa,
        uint256 anchorPriceMantissa,
        uint256 cappedPriceMantissa
    );

    /**
     * @dev emitted when admin either pauses or resumes the contract; newState is the resulting state
     */
    event SetPaused(bool newState);

    /**
     * @dev emitted when pendingAnchorAdmin is changed
     */
    event NewPendingAnchorAdmin(address oldPendingAnchorAdmin, address newPendingAnchorAdmin);

    /**
     * @dev emitted when pendingAnchorAdmin is accepted, which means anchor admin is updated
     */
    event NewAnchorAdmin(address oldAnchorAdmin, address newAnchorAdmin);

    /**
     * @notice set `paused` to the specified state
     * @dev Admin function to pause or resume the market
     * @param requestedState value to assign to `paused`
     * @return uint 0=success, otherwise a failure
     */
    function _setPaused(bool requestedState) public returns (uint256) {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return failOracle(address(0), OracleError.UNAUTHORIZED, OracleFailureInfo.SET_PAUSED_OWNER_CHECK);
        }

        paused = requestedState;
        emit SetPaused(requestedState);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Begins transfer of anchor admin rights. The newPendingAnchorAdmin must call `_acceptAnchorAdmin` to finalize the transfer.
     * @dev Admin function to begin change of anchor admin. The newPendingAnchorAdmin must call `_acceptAnchorAdmin` to finalize the transfer.
     * @param newPendingAnchorAdmin New pending anchor admin.
     * @return uint 0=success, otherwise a failure
     *
     * TODO: Should we add a second arg to verify, like a checksum of `newAnchorAdmin` address?
     */
    function _setPendingAnchorAdmin(address newPendingAnchorAdmin) public returns (uint256) {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.SET_PENDING_ANCHOR_ADMIN_OWNER_CHECK
                );
        }

        // save current value, if any, for inclusion in log
        address oldPendingAnchorAdmin = pendingAnchorAdmin;
        // Store pendingAdmin = newPendingAdmin
        pendingAnchorAdmin = newPendingAnchorAdmin;

        emit NewPendingAnchorAdmin(oldPendingAnchorAdmin, newPendingAnchorAdmin);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of anchor admin rights. msg.sender must be pendingAnchorAdmin
     * @dev Admin function for pending anchor admin to accept role and update anchor admin
     * @return uint 0=success, otherwise a failure
     */
    function _acceptAnchorAdmin() public returns (uint256) {
        // Check caller = pendingAnchorAdmin
        // msg.sender can't be zero
        if (msg.sender != pendingAnchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ACCEPT_ANCHOR_ADMIN_PENDING_ANCHOR_ADMIN_CHECK
                );
        }

        // Save current value for inclusion in log
        address oldAnchorAdmin = anchorAdmin;
        // Store admin = pendingAnchorAdmin
        anchorAdmin = pendingAnchorAdmin;
        // Clear the pending value
        pendingAnchorAdmin = address(0);

        emit NewAnchorAdmin(oldAnchorAdmin, msg.sender);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice retrieves price of an asset
     * @dev function to get price for an asset
     * @param asset Asset for which to get the price
     * @return uint mantissa of asset price (scaled by 1e18) or zero if unset or contract paused
     */
    function assetPrices(address asset) public view returns (uint256) {
        // Note: zero is treated by the money market as an invalid
        //       price and will cease operations with that asset
        //       when zero.
        //
        // We get the price as:
        //
        //  1. If the contract is paused, return 0.
        //  2. Return price in `_assetPrices`, which may be zero.

        if (paused) {
            return 0;
        }
        return _assetPrices[asset].mantissa;
    }

    /**
     * @notice retrieves price of an asset
     * @dev function to get price for an asset
     * @param asset Asset for which to get the price
     * @return uint mantissa of asset price (scaled by 1e18) or zero if unset or contract paused
     */
    function getPrice(address asset) public view returns (uint256) {
        return assetPrices(asset);
    }

    struct SetPriceLocalVars {
        Exp price;
        Exp swing;
        Exp anchorPrice;
        uint256 anchorPeriod;
        uint256 currentPeriod;
        bool priceCapped;
        uint256 cappingAnchorPriceMantissa;
        uint256 pendingAnchorMantissa;
    }

    /**
     * @notice entry point for updating prices
     * @dev function to set price for an asset
     * @param asset Asset for which to set the price
     * @param requestedPriceMantissa requested new price, scaled by 10**18
     * @return uint 0=success, otherwise a failure (see enum OracleError for details)
     */
    function setPrice(address asset, uint256 requestedPriceMantissa) public returns (uint256) {
        // Fail when msg.sender is not poster
        if (msg.sender != poster) {
            return failOracle(asset, OracleError.UNAUTHORIZED, OracleFailureInfo.SET_PRICE_PERMISSION_CHECK);
        }

        return setPriceInternal(asset, requestedPriceMantissa);
    }

    function setPriceInternal(address asset, uint256 requestedPriceMantissa) internal returns (uint256) {
        // re-used for intermediate errors
        Error err;
        SetPriceLocalVars memory localVars;
        // We add 1 for currentPeriod so that it can never be zero and there's no ambiguity about an unset value.
        // (It can be a problem in tests with low block numbers.)
        localVars.currentPeriod = (block.number / numBlocksPerPeriod) + 1;
        localVars.pendingAnchorMantissa = pendingAnchors[asset];
        localVars.price = Exp({mantissa: requestedPriceMantissa});

        if (localVars.pendingAnchorMantissa != 0) {
            // let's explicitly set to 0 rather than relying on default of declaration
            localVars.anchorPeriod = 0;
            localVars.anchorPrice = Exp({mantissa: localVars.pendingAnchorMantissa});

            // Verify movement is within max swing of pending anchor (currently: 10%)
            (err, localVars.swing) = calculateSwing(localVars.anchorPrice, localVars.price);
            if (err != Error.NO_ERROR) {
                return
                    failOracleWithDetails(
                        asset,
                        OracleError.FAILED_TO_SET_PRICE,
                        OracleFailureInfo.SET_PRICE_CALCULATE_SWING,
                        uint256(err)
                    );
            }

            // Fail when swing > maxSwing
            if (greaterThanExp(localVars.swing, maxSwing)) {
                return
                    failOracleWithDetails(
                        asset,
                        OracleError.FAILED_TO_SET_PRICE,
                        OracleFailureInfo.SET_PRICE_MAX_SWING_CHECK,
                        localVars.swing.mantissa
                    );
            }
        } else {
            localVars.anchorPeriod = anchors[asset].period;
            localVars.anchorPrice = Exp({mantissa: anchors[asset].priceMantissa});

            if (localVars.anchorPeriod != 0) {
                (err, localVars.priceCapped, localVars.price) = capToMax(localVars.anchorPrice, localVars.price);
                if (err != Error.NO_ERROR) {
                    return
                        failOracleWithDetails(
                            asset,
                            OracleError.FAILED_TO_SET_PRICE,
                            OracleFailureInfo.SET_PRICE_CAP_TO_MAX,
                            uint256(err)
                        );
                }
                if (localVars.priceCapped) {
                    // save for use in log
                    localVars.cappingAnchorPriceMantissa = localVars.anchorPrice.mantissa;
                }
            } else {
                // Setting first price. Accept as is (already assigned above from requestedPriceMantissa) and use as anchor
                localVars.anchorPrice = Exp({mantissa: requestedPriceMantissa});
            }
        }

        // Fail if anchorPrice or price is zero.
        // zero anchor represents an unexpected situation likely due to a problem in this contract
        // zero price is more likely as the result of bad input from the caller of this function
        if (isZeroExp(localVars.anchorPrice)) {
            // If we get here price could also be zero, but it does not seem worthwhile to distinguish the 3rd case
            return
                failOracle(
                    asset,
                    OracleError.FAILED_TO_SET_PRICE,
                    OracleFailureInfo.SET_PRICE_NO_ANCHOR_PRICE_OR_INITIAL_PRICE_ZERO
                );
        }

        if (isZeroExp(localVars.price)) {
            return failOracle(asset, OracleError.FAILED_TO_SET_PRICE, OracleFailureInfo.SET_PRICE_ZERO_PRICE);
        }

        // BEGIN SIDE EFFECTS

        // Set pendingAnchor = Nothing
        // Pending anchor is only used once.
        if (pendingAnchors[asset] != 0) {
            pendingAnchors[asset] = 0;
        }

        // If currentPeriod > anchorPeriod:
        //  Set anchors[asset] = (currentPeriod, price)
        //  The new anchor is if we're in a new period or we had a pending anchor, then we become the new anchor
        if (localVars.currentPeriod > localVars.anchorPeriod) {
            anchors[asset] = Anchor({period: localVars.currentPeriod, priceMantissa: localVars.price.mantissa});
        }

        uint256 previousPrice = _assetPrices[asset].mantissa;

        setPriceStorageInternal(asset, localVars.price.mantissa);

        emit PricePosted(asset, previousPrice, requestedPriceMantissa, localVars.price.mantissa);

        if (localVars.priceCapped) {
            // We have set a capped price. Log it so we can detect the situation and investigate.
            emit CappedPricePosted(
                asset,
                requestedPriceMantissa,
                localVars.cappingAnchorPriceMantissa,
                localVars.price.mantissa
            );
        }

        return uint256(OracleError.NO_ERROR);
    }

    // As a function to allow harness overrides
    function setPriceStorageInternal(address asset, uint256 priceMantissa) internal {
        _assetPrices[asset] = Exp({mantissa: priceMantissa});
    }

    // abs(price - anchorPrice) / anchorPrice
    function calculateSwing(Exp memory anchorPrice, Exp memory price) internal pure returns (Error, Exp memory) {
        Exp memory numerator;
        Error err;

        if (greaterThanExp(anchorPrice, price)) {
            (err, numerator) = subExp(anchorPrice, price);
            // can't underflow
            assert(err == Error.NO_ERROR);
        } else {
            (err, numerator) = subExp(price, anchorPrice);
            // Given greaterThan check above, price >= anchorPrice so can't underflow.
            assert(err == Error.NO_ERROR);
        }

        return divExp(numerator, anchorPrice);
    }

    function capToMax(Exp memory anchorPrice, Exp memory price)
        internal
        view
        returns (
            Error,
            bool,
            Exp memory
        )
    {
        Exp memory one = Exp({mantissa: mantissaOne});
        Exp memory onePlusMaxSwing;
        Exp memory oneMinusMaxSwing;
        Exp memory max;
        Exp memory min;
        // re-used for intermediate errors
        Error err;

        (err, onePlusMaxSwing) = addExp(one, maxSwing);
        if (err != Error.NO_ERROR) {
            return (err, false, Exp({mantissa: 0}));
        }

        // max = anchorPrice * (1 + maxSwing)
        (err, max) = mulExp(anchorPrice, onePlusMaxSwing);
        if (err != Error.NO_ERROR) {
            return (err, false, Exp({mantissa: 0}));
        }

        // If price > anchorPrice * (1 + maxSwing)
        // Set price = anchorPrice * (1 + maxSwing)
        if (greaterThanExp(price, max)) {
            return (Error.NO_ERROR, true, max);
        }

        (err, oneMinusMaxSwing) = subExp(one, maxSwing);
        if (err != Error.NO_ERROR) {
            return (err, false, Exp({mantissa: 0}));
        }

        // min = anchorPrice * (1 - maxSwing)
        (err, min) = mulExp(anchorPrice, oneMinusMaxSwing);
        // We can't overflow here or we would have already overflowed above when calculating `max`
        assert(err == Error.NO_ERROR);

        // If  price < anchorPrice * (1 - maxSwing)
        // Set price = anchorPrice * (1 - maxSwing)
        if (lessThanExp(price, min)) {
            return (Error.NO_ERROR, true, min);
        }

        return (Error.NO_ERROR, false, price);
    }

    /**
     * @notice entry point for updating multiple prices
     * @dev function to set prices for a variable number of assets.
     * @param assets a list of up to assets for which to set a price. required: 0 < assets.length == requestedPriceMantissas.length
     * @param requestedPriceMantissas requested new prices for the assets, scaled by 10**18. required: 0 < assets.length == requestedPriceMantissas.length
     * @return uint values in same order as inputs. For each: 0=success, otherwise a failure (see enum OracleError for details)
     */
    function setPrices(address[] memory assets, uint256[] memory requestedPriceMantissas)
        public
        returns (uint256[] memory)
    {
        uint256 numAssets = assets.length;
        uint256 numPrices = requestedPriceMantissas.length;
        uint256[] memory result;

        // Fail when msg.sender is not poster
        if (msg.sender != poster) {
            result = new uint256[](1);
            result[0] = failOracle(address(0), OracleError.UNAUTHORIZED, OracleFailureInfo.SET_PRICE_PERMISSION_CHECK);
            return result;
        }

        if ((numAssets == 0) || (numPrices != numAssets)) {
            result = new uint256[](1);
            result[0] = failOracle(
                address(0),
                OracleError.FAILED_TO_SET_PRICE,
                OracleFailureInfo.SET_PRICES_PARAM_VALIDATION
            );
            return result;
        }

        result = new uint256[](numAssets);

        for (uint256 i = 0; i < numAssets; i++) {
            result[i] = setPriceInternal(assets[i], requestedPriceMantissas[i]);
        }

        return result;
    }
}