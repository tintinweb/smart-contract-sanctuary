//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract ErrorReporter {
    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     */
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

    /**
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        BORROW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED,
        BORROW_ACCOUNT_SHORTFALL_PRESENT,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_AMOUNT_LIQUIDITY_SHORTFALL,
        BORROW_AMOUNT_VALUE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_SUPPORTED,
        BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        BORROW_NEW_BORROW_RATE_CALCULATION_FAILED,
        BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
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
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_BORROW_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
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
    function failOpaque(FailureInfo info, uint256 opaqueError)
        internal
        returns (uint256)
    {
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

    /**
     * @dev Add two numbers together, overflow will lead to revert.
     */
    function srcAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    /**
     * @dev Integer subtraction of two numbers, overflow will lead to revert.
     */
    function srcSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    /**
     * @dev Multiplies two numbers, overflow will lead to revert.
     */
    function srcMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function srcDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "ds-math-div-overflow");
        z = x / y;
    }

    /**
     * @dev x to the power of y power(base, exponent)
     */
    function pow(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        } else if (exponent == 1) {
            return base;
        } else if (base == 0 && exponent != 0) {
            return 0;
        } else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++) z = srcMul(z, base);
            return z;
        }
    }
}

contract Exponential is CarefulMath {
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
    function getExp(uint256 num, uint256 denom)
        internal
        pure
        returns (Error, Exp memory)
    {
        (Error err0, uint256 scaledNumerator) = mul(num, expScale);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        (Error err1, uint256 rational) = div(scaledNumerator, denom);
        if (err1 != Error.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        return (Error.NO_ERROR, Exp({ mantissa: rational }));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b)
        internal
        pure
        returns (Error, Exp memory)
    {
        (Error error, uint256 result) = add(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b)
        internal
        pure
        returns (Error, Exp memory)
    {
        (Error error, uint256 result) = sub(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint256 scalar)
        internal
        pure
        returns (Error, Exp memory)
    {
        (Error err0, uint256 scaledMantissa) = mul(a.mantissa, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        return (Error.NO_ERROR, Exp({ mantissa: scaledMantissa }));
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint256 scalar)
        internal
        pure
        returns (Error, Exp memory)
    {
        (Error err0, uint256 descaledMantissa) = div(a.mantissa, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        return (Error.NO_ERROR, Exp({ mantissa: descaledMantissa }));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint256 scalar, Exp memory divisor)
        internal
        pure
        returns (Error, Exp memory)
    {
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
            return (err0, Exp({ mantissa: 0 }));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b)
        internal
        pure
        returns (Error, Exp memory)
    {
        (Error err0, uint256 doubleScaledProduct) = mul(a.mantissa, b.mantissa);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (Error err1, uint256 doubleScaledProductWithHalfScale) =
            add(halfExpScale, doubleScaledProduct);
        if (err1 != Error.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        (Error err2, uint256 product) =
            div(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is Error.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == Error.NO_ERROR);

        return (Error.NO_ERROR, Exp({ mantissa: product }));
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b)
        internal
        pure
        returns (Error, Exp memory)
    {
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
    function lessThanExp(Exp memory left, Exp memory right)
        internal
        pure
        returns (bool)
    {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right)
        internal
        pure
        returns (bool)
    {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if first Exp is greater than second Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right)
        internal
        pure
        returns (bool)
    {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }
}

interface ExchangeRateModel {
    function scale() external view returns (uint256);

    function token() external view returns (address);

    function getExchangeRate() external view returns (uint256);

    function getMaxSwingRate(uint256 interval) external view returns (uint256);

    function getFixedInterestRate(uint256 interval)
        external
        view
        returns (uint256);

    function getFixedExchangeRate(uint256 interval)
        external
        view
        returns (uint256);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface IAggregator {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface IStatusOracle {

    function getAssetPriceStatus(address _asset) external view returns (bool);
}

contract PriceOracle is Exponential {
    // Flag for whether or not contract is paused.
    bool public paused;

    // Approximately 1 hour: 60 seconds/minute * 60 minutes/hour * 1 block/15 seconds.
    uint256 public constant numBlocksPerPeriod = 240;

    uint256 public constant maxSwingMantissa = (5 * 10**15); // 0.005

    uint256 public constant MINIMUM_SWING = 10**15;
    uint256 public constant MAXIMUM_SWING = 10**17;

    uint256 public constant SECONDS_PER_WEEK = 604800;

    /**
     * @dev An administrator who can set the pending anchor value for assets.
     *      Set in the constructor.
     */
    address public anchorAdmin;

    /**
     * @dev Pending anchor administrator for this contract.
     */
    address public pendingAnchorAdmin;

    /**
     * @dev Address of the price poster.
     *      Set in the constructor.
     */
    address public poster;

    /**
     * @dev The maximum allowed percentage difference between a new price and the anchor's price
     *      Set only in the constructor
     */
    Exp public maxSwing;

    /**
     * @dev The maximum allowed percentage difference for all assets between a new price and the anchor's price
     */
    mapping(address => Exp) public maxSwings;

    /**
     * @dev Mapping of asset addresses to exchange rate information.
     *      Dynamic changes in asset prices based on exchange rates.
     * map: assetAddress -> ExchangeRateInfo
     */
    struct ExchangeRateInfo {
        address exchangeRateModel; // Address of exchange rate model contract
        uint256 exchangeRate; // Exchange rate between token and wrapped token
        uint256 maxSwingRate; // Maximum changing ratio of the exchange rate
        uint256 maxSwingDuration; // Duration of maximum changing ratio of the exchange rate
    }
    mapping(address => ExchangeRateInfo) public exchangeRates;

    /**
     * @dev Mapping of asset addresses to asset addresses. Stable coin can share a price.
     *
     * map: assetAddress -> Reader
     */
    struct Reader {
        address asset; // Asset to read price
        int256 decimalsDifference; // Standard decimal is 18, so this is equal to the decimal of `asset` - 18.
    }
    mapping(address => Reader) public readers;

    /**
     * @dev Mapping of asset addresses and their corresponding price in terms of Eth-Wei
     *      which is simply equal to AssetWeiPrice * 10e18. For instance, if OMG token was
     *      worth 5x Eth then the price for OMG would be 5*10e18 or Exp({mantissa: 5000000000000000000}).
     * map: assetAddress -> Exp
     */
    mapping(address => Exp) public _assetPrices;
    
    /**
     * @dev Mapping of asset addresses to aggregator.
     */
    mapping(address => IAggregator) public aggregator;

    /**
     * @dev Mapping of asset addresses to statusOracle.
     */
    mapping(address => IStatusOracle) public statusOracle;

    constructor(address _poster, uint256 _maxSwing) public {
        anchorAdmin = msg.sender;
        poster = _poster;
        _setMaxSwing(_maxSwing);
    }

    /**
     * @notice Do not pay into PriceOracle.
     */
    receive() external payable {
        revert();
    }

    enum OracleError { NO_ERROR, UNAUTHORIZED, FAILED_TO_SET_PRICE }

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
        SET_PRICES_PARAM_VALIDATION,
        SET_PRICE_IS_READER_ASSET,
        ADMIN_CONFIG
    }

    /**
     * @dev `msgSender` is msg.sender; `error` corresponds to enum OracleError;
     *      `info` corresponds to enum OracleFailureInfo, and `detail` is an arbitrary
     *      contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     */
    event OracleFailure(
        address msgSender,
        address asset,
        uint256 error,
        uint256 info,
        uint256 detail
    );

    /**
     * @dev Use this when reporting a known error from the price oracle or a non-upgradeable collaborator
     *      Using Oracle in name because we already inherit a `fail` function from ErrorReporter.sol
     *      via Exponential.sol
     */
    function failOracle(
        address _asset,
        OracleError _err,
        OracleFailureInfo _info
    ) internal returns (uint256) {
        emit OracleFailure(msg.sender, _asset, uint256(_err), uint256(_info), 0);

        return uint256(_err);
    }

    /**
     * @dev Use this to report an error when set asset price.
     *      Give the `error` corresponds to enum Error as `_details`.
     */
    function failOracleWithDetails(
        address _asset,
        OracleError _err,
        OracleFailureInfo _info,
        uint256 _details
    ) internal returns (uint256) {
        emit OracleFailure(
            msg.sender,
            _asset,
            uint256(_err),
            uint256(_info),
            _details
        );

        return uint256(_err);
    }

    struct Anchor {
        // Floor(block.number / numBlocksPerPeriod) + 1
        uint256 period;
        // Price in ETH, scaled by 10**18
        uint256 priceMantissa;
    }

    /**
     * @dev Anchors by asset.
     */
    mapping(address => Anchor) public anchors;

    /**
     * @dev Pending anchor prices by asset.
     */
    mapping(address => uint256) public pendingAnchors;

    /**
     * @dev Emitted when a pending anchor is set.
     * @param asset Asset for which to set a pending anchor.
     * @param oldScaledPrice If an unused pending anchor was present, its value; otherwise 0.
     * @param newScaledPrice The new scaled pending anchor price.
     */
    event NewPendingAnchor(
        address anchorAdmin,
        address asset,
        uint256 oldScaledPrice,
        uint256 newScaledPrice
    );

    /**
     * @notice Provides ability to override the anchor price for an asset.
     * @dev Admin function to set the anchor price for an asset.
     * @param _asset Asset for which to override the anchor price.
     * @param _newScaledPrice New anchor price.
     * @return uint 0=success, otherwise a failure (see enum OracleError for details).
     */
    function _setPendingAnchor(address _asset, uint256 _newScaledPrice)
        external
        returns (uint256)
    {
        // Check caller = anchorAdmin.
        // Note: Deliberately not allowing admin. They can just change anchorAdmin if desired.
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    _asset,
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.SET_PENDING_ANCHOR_PERMISSION_CHECK
                );
        }

        uint256 _oldScaledPrice = pendingAnchors[_asset];
        pendingAnchors[_asset] = _newScaledPrice;

        emit NewPendingAnchor(
            msg.sender,
            _asset,
            _oldScaledPrice,
            _newScaledPrice
        );

        return uint256(OracleError.NO_ERROR);
    }

    /**
     * @dev Emitted for all exchangeRates changes.
     */
    event SetExchangeRate(
        address asset,
        address exchangeRateModel,
        uint256 exchangeRate,
        uint256 maxSwingRate,
        uint256 maxSwingDuration
    );
    event SetMaxSwingRate(
        address asset,
        uint256 oldMaxSwingRate,
        uint256 newMaxSwingRate,
        uint256 maxSwingDuration
    );

    /**
     * @dev Emitted for all readers changes.
     */
    event ReaderPosted(
        address asset,
        address oldReader,
        address newReader,
        int256 decimalsDifference
    );

    /**
     * @dev Emitted for max swing changes.
     */
    event SetMaxSwing(uint256 maxSwing);

    /**
     * @dev Emitted for max swing changes.
     */
    event SetMaxSwingForAsset(address asset, uint256 maxSwing);

    /**
     * @dev Emitted for max swing changes.
     */
    event SetAssetAggregator(address asset, address aggregator);

    /**
     * @dev Emitted for statusOracle changes.
     */
    event SetAssetStatusOracle(address asset, IStatusOracle statusOracle);

    /**
     * @dev Emitted for all price changes.
     */
    event PricePosted(
        address asset,
        uint256 previousPriceMantissa,
        uint256 requestedPriceMantissa,
        uint256 newPriceMantissa
    );

    /**
     * @dev Emitted if this contract successfully posts a capped-to-max price.
     */
    event CappedPricePosted(
        address asset,
        uint256 requestedPriceMantissa,
        uint256 anchorPriceMantissa,
        uint256 cappedPriceMantissa
    );

    /**
     * @dev Emitted when admin either pauses or resumes the contract; `newState` is the resulting state.
     */
    event SetPaused(bool newState);

    /**
     * @dev Emitted when `pendingAnchorAdmin` is changed.
     */
    event NewPendingAnchorAdmin(
        address oldPendingAnchorAdmin,
        address newPendingAnchorAdmin
    );

    /**
     * @dev Emitted when `pendingAnchorAdmin` is accepted, which means anchor admin is updated.
     */
    event NewAnchorAdmin(address oldAnchorAdmin, address newAnchorAdmin);

    /**
     * @dev Emitted when `poster` is changed.
     */
    event NewPoster(address oldPoster, address newPoster);

    /**
     * @notice Set `paused` to the specified state.
     * @dev Admin function to pause or resume the contract.
     * @param _requestedState Value to assign to `paused`.
     * @return uint 0=success, otherwise a failure.
     */
    function _setPaused(bool _requestedState) external returns (uint256) {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.SET_PAUSED_OWNER_CHECK
                );
        }

        paused = _requestedState;
        emit SetPaused(_requestedState);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Begins to transfer the right of anchor admin.
     *         The `_newPendingAnchorAdmin` must call `_acceptAnchorAdmin` to finalize the transfer.
     * @dev Admin function to change the anchor admin.
     *      The `_newPendingAnchorAdmin` must call `_acceptAnchorAdmin` to finalize the transfer.
     * @param _newPendingAnchorAdmin New pending anchor admin.
     * @return uint 0=success, otherwise a failure.
     */
    function _setPendingAnchorAdmin(address _newPendingAnchorAdmin)
        external
        returns (uint256)
    {
        // Check caller = anchorAdmin.
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.SET_PENDING_ANCHOR_ADMIN_OWNER_CHECK
                );
        }

        // Save current value, if any, for inclusion in log.
        address _oldPendingAnchorAdmin = pendingAnchorAdmin;
        // Store pendingAdmin = newPendingAdmin.
        pendingAnchorAdmin = _newPendingAnchorAdmin;

        emit NewPendingAnchorAdmin(
            _oldPendingAnchorAdmin,
            _newPendingAnchorAdmin
        );

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of anchor admin rights. `msg.sender` must be `pendingAnchorAdmin`.
     * @dev Admin function for pending anchor admin to accept role and update anchor admin`
     * @return uint 0=success, otherwise a failure`
     */
    function _acceptAnchorAdmin() external returns (uint256) {
        // Check caller = pendingAnchorAdmin.
        // `msg.sender` can't be zero.
        if (msg.sender != pendingAnchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo
                        .ACCEPT_ANCHOR_ADMIN_PENDING_ANCHOR_ADMIN_CHECK
                );
        }

        // Save current value for inclusion in log.
        address _oldAnchorAdmin = anchorAdmin;
        // Store admin = pendingAnchorAdmin.
        anchorAdmin = pendingAnchorAdmin;
        // Clear the pending value.
        pendingAnchorAdmin = address(0);

        emit NewAnchorAdmin(_oldAnchorAdmin, msg.sender);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set new poster.
     * @dev Admin function to change of poster.
     * @param _newPoster New poster.
     * @return uint 0=success, otherwise a failure.
     *
     * TODO: Should we add a second arg to verify, like a checksum of `newAnchorAdmin` address?
     */
    function _setPoster(address _newPoster) external returns (uint256) {
        assert(poster != _newPoster);
        // Check caller = anchorAdmin.
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        // Save current value, if any, for inclusion in log.
        address _oldPoster = poster;
        // Store poster = newPoster.
        poster = _newPoster;

        emit NewPoster(_oldPoster, _newPoster);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set new exchange rate model.
     * @dev Function to set exchangeRateModel for an asset.
     * @param _asset Asset to set the new `_exchangeRateModel`.
     * @param _exchangeRateModel New `_exchangeRateModel` cnotract address,
     *                          if the `_exchangeRateModel` is address(0), revert to cancle.
     * @param _maxSwingDuration A value greater than zero and less than the seconds of a week.
     * @return uint 0=success, otherwise a failure (see enum OracleError for details).
     */
    function setExchangeRate(
        address _asset,
        address _exchangeRateModel,
        uint256 _maxSwingDuration
    ) external returns (uint256) {
        // Check caller = anchorAdmin.
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    _asset,
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        require(
            _exchangeRateModel != address(0),
            "setExchangeRate: exchangeRateModel cannot be a zero address."
        );
        require(
            _maxSwingDuration > 0 && _maxSwingDuration <= SECONDS_PER_WEEK,
            "setExchangeRate: maxSwingDuration cannot be zero, less than 604800 (seconds per week)."
        );

        uint256 _currentExchangeRate =
            ExchangeRateModel(_exchangeRateModel).getExchangeRate();
        require(
            _currentExchangeRate > 0,
            "setExchangeRate: currentExchangeRate not zero."
        );

        uint256 _maxSwingRate =
            ExchangeRateModel(_exchangeRateModel).getMaxSwingRate(
                _maxSwingDuration
            );
        require(
            _maxSwingRate > 0 &&
                _maxSwingRate <=
                ExchangeRateModel(_exchangeRateModel).getMaxSwingRate(
                    SECONDS_PER_WEEK
                ),
            "setExchangeRate: maxSwingRate cannot be zero, less than 604800 (seconds per week)."
        );

        exchangeRates[_asset].exchangeRateModel = _exchangeRateModel;
        exchangeRates[_asset].exchangeRate = _currentExchangeRate;
        exchangeRates[_asset].maxSwingRate = _maxSwingRate;
        exchangeRates[_asset].maxSwingDuration = _maxSwingDuration;

        emit SetExchangeRate(
            _asset,
            _exchangeRateModel,
            _currentExchangeRate,
            _maxSwingRate,
            _maxSwingDuration
        );
        return uint256(OracleError.NO_ERROR);
    }

    /**
     * @notice Set the asset’s `exchangeRateModel` to disabled.
     * @dev Admin function to disable of exchangeRateModel.
     * @param _asset Asset for which to disable the `exchangeRateModel`.
     * @return uint 0=success, otherwise a failure.
     */
    function _disableExchangeRate(address _asset)
        public
        returns (uint256)
    {
        // Check caller = anchorAdmin.
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    _asset,
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        exchangeRates[_asset].exchangeRateModel = address(0);
        exchangeRates[_asset].exchangeRate = 0;
        exchangeRates[_asset].maxSwingRate = 0;
        exchangeRates[_asset].maxSwingDuration = 0;

        emit SetExchangeRate(
            _asset,
            address(0),
            0,
            0,
            0
        );
        return uint256(OracleError.NO_ERROR);
    }

    /**
     * @notice Set a new `maxSwingRate`.
     * @dev Function to set exchange rate `maxSwingRate` for an asset.
     * @param _asset Asset for which to set the exchange rate `maxSwingRate`.
     * @param _maxSwingDuration Interval time.
     * @return uint 0=success, otherwise a failure (see enum OracleError for details)
     */
    function setMaxSwingRate(address _asset, uint256 _maxSwingDuration)
        external
        returns (uint256)
    {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    _asset,
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        require(
            _maxSwingDuration > 0 && _maxSwingDuration <= SECONDS_PER_WEEK,
            "setMaxSwingRate: maxSwingDuration cannot be zero, less than 604800 (seconds per week)."
        );

        ExchangeRateModel _exchangeRateModel =
            ExchangeRateModel(exchangeRates[_asset].exchangeRateModel);
        uint256 _newMaxSwingRate =
            _exchangeRateModel.getMaxSwingRate(_maxSwingDuration);
        uint256 _oldMaxSwingRate = exchangeRates[_asset].maxSwingRate;
        require(
            _oldMaxSwingRate != _newMaxSwingRate,
            "setMaxSwingRate: the same max swing rate."
        );
        require(
            _newMaxSwingRate > 0 &&
                _newMaxSwingRate <=
                _exchangeRateModel.getMaxSwingRate(SECONDS_PER_WEEK),
            "setMaxSwingRate: maxSwingRate cannot be zero, less than 31536000 (seconds per week)."
        );

        exchangeRates[_asset].maxSwingRate = _newMaxSwingRate;
        exchangeRates[_asset].maxSwingDuration = _maxSwingDuration;

        emit SetMaxSwingRate(
            _asset,
            _oldMaxSwingRate,
            _newMaxSwingRate,
            _maxSwingDuration
        );
        return uint256(OracleError.NO_ERROR);
    }

    /**
     * @notice Entry point for updating prices.
     * @dev Set reader for an asset.
     * @param _asset Asset for which to set the reader.
     * @param _readAsset Reader address, if the reader is address(0), cancel the reader.
     * @return uint 0=success, otherwise a failure (see enum OracleError for details).
     */
    function setReaders(address _asset, address _readAsset)
        external
        returns (uint256)
    {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    _asset,
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        address _oldReadAsset = readers[_asset].asset;
        // require(_readAsset != _oldReadAsset, "setReaders: Old and new values cannot be the same.");
        require(
            _readAsset != _asset,
            "setReaders: asset and readAsset cannot be the same."
        );

        readers[_asset].asset = _readAsset;
        if (_readAsset == address(0)) readers[_asset].decimalsDifference = 0;
        else
            readers[_asset].decimalsDifference = int256(
                IERC20(_asset).decimals() - IERC20(_readAsset).decimals()
            );

        emit ReaderPosted(
            _asset,
            _oldReadAsset,
            _readAsset,
            readers[_asset].decimalsDifference
        );
        return uint256(OracleError.NO_ERROR);
    }

    /**
     * @notice Set `maxSwing` to the specified value.
     * @dev Admin function to change of max swing.
     * @param _maxSwing Value to assign to `maxSwing`.
     * @return uint 0=success, otherwise a failure.
     */
    function _setMaxSwing(uint256 _maxSwing) public returns (uint256) {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        uint256 _oldMaxSwing = maxSwing.mantissa;
        require(
            _maxSwing != _oldMaxSwing,
            "_setMaxSwing: Old and new values cannot be the same."
        );

        require(
            _maxSwing >= MINIMUM_SWING && _maxSwing <= MAXIMUM_SWING,
            "_setMaxSwing: 0.1% <= _maxSwing <= 10%."
        );
        maxSwing = Exp({ mantissa: _maxSwing });
        emit SetMaxSwing(_maxSwing);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Set `maxSwing` for asset to the specified value.
     * @dev Admin function to change of max swing.
     * @param _asset Asset for which to set the `maxSwing`.
     * @param _maxSwing Value to assign to `maxSwing`.
     * @return uint 0=success, otherwise a failure.
     */
    function _setMaxSwingForAsset(address _asset, uint256 _maxSwing)
        public
        returns (uint256)
    {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        uint256 _oldMaxSwing = maxSwings[_asset].mantissa;
        require(
            _maxSwing != _oldMaxSwing,
            "_setMaxSwingForAsset: Old and new values cannot be the same."
        );
        require(
            _maxSwing >= MINIMUM_SWING && _maxSwing <= MAXIMUM_SWING,
            "_setMaxSwingForAsset: 0.1% <= _maxSwing <= 10%."
        );
        maxSwings[_asset] = Exp({ mantissa: _maxSwing });
        emit SetMaxSwingForAsset(_asset, _maxSwing);

        return uint256(Error.NO_ERROR);
    }

    function _setMaxSwingForAssetBatch(
        address[] calldata _assets,
        uint256[] calldata _maxSwings
    ) external {
        require(
            _assets.length == _maxSwings.length,
            "_setMaxSwingForAssetBatch: assets & maxSwings must match the current length."
        );
        for (uint256 i = 0; i < _assets.length; i++)
            _setMaxSwingForAsset(_assets[i], _maxSwings[i]);
    }

    /**
     * @notice Set `aggregator` for asset to the specified address.
     * @dev Admin function to change of aggregator.
     * @param _asset Asset for which to set the `aggregator`.
     * @param _aggregator Address to assign to `aggregator`.
     * @return uint 0=success, otherwise a failure.
     */
    function _setAssetAggregator(address _asset, IAggregator _aggregator)
        public
        returns (uint256)
    {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        require(
            _aggregator.decimals() > 0,
            "_setAssetAggregator: This is not the aggregator contract!"
        );

        IAggregator _oldAssetAggregator = aggregator[_asset];
        require(
            _aggregator != _oldAssetAggregator,
            "_setAssetAggregator: Old and new address cannot be the same."
        );
        
        aggregator[_asset] = IAggregator(_aggregator);
        emit SetAssetAggregator(_asset, address(_aggregator));

        return uint256(Error.NO_ERROR);
    }

    function _setAssetAggregatorBatch(
        address[] calldata _assets,
        IAggregator[] calldata _aggregators
    ) external {
        require(
            _assets.length == _aggregators.length,
            "_setAssetAggregatorBatch: assets & aggregators must match the current length."
        );
        for (uint256 i = 0; i < _assets.length; i++)
            _setAssetAggregator(_assets[i], _aggregators[i]);
    }

    /**
     * @notice Set the asset’s `aggregator` to disabled.
     * @dev Admin function to disable of aggregator.
     * @param _asset Asset for which to disable the `aggregator`.
     * @return uint 0=success, otherwise a failure.
     */
    function _disableAssetAggregator(address _asset)
        public
        returns (uint256)
    {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        require(
            _getReaderPrice(_asset) > 0,
            "_disableAssetAggregator: The price of local assets cannot be 0!"
        );
        
        aggregator[_asset] = IAggregator(address(0));
        emit SetAssetAggregator(_asset, address(0));

        return uint256(Error.NO_ERROR);
    }

    function _disableAssetAggregatorBatch(address[] calldata _assets) external {
        for (uint256 i = 0; i < _assets.length; i++)
            _disableAssetAggregator(_assets[i]);
    }

    /**
     * @notice Set `statusOracle` for asset to the specified address.
     * @dev Admin function to change of statusOracle.
     * @param _asset Asset for which to set the `statusOracle`.
     * @param _statusOracle Address to assign to `statusOracle`.
     * @return uint 0=success, otherwise a failure.SetAssetStatusOracle
     */
    function _setAssetStatusOracle(address _asset, IStatusOracle _statusOracle)
        public
        returns (uint256)
    {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }

        _statusOracle.getAssetPriceStatus(_asset);
        
        statusOracle[_asset] = _statusOracle;
        emit SetAssetStatusOracle(_asset, _statusOracle);

        return uint256(Error.NO_ERROR);
    }

    function _setAssetStatusOracleBatch(
        address[] calldata _assets,
        IStatusOracle[] calldata _statusOracles
    ) external {
        require(
            _assets.length == _statusOracles.length,
            "_setAssetStatusOracleBatch: assets & _statusOracles must match the current length."
        );
        for (uint256 i = 0; i < _assets.length; i++)
            _setAssetStatusOracle(_assets[i], _statusOracles[i]);
    }

    /**
     * @notice Set the `statusOracle` to disabled.
     * @dev Admin function to disable of statusOracle.
     * @return uint 0=success, otherwise a failure.
     */
    function _disableAssetStatusOracle(address _asset)
        public
        returns (uint256)
    {
        // Check caller = anchorAdmin
        if (msg.sender != anchorAdmin) {
            return
                failOracle(
                    address(0),
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.ADMIN_CONFIG
                );
        }
        statusOracle[_asset] = IStatusOracle(0);
        
        emit SetAssetStatusOracle(_asset, IStatusOracle(0));

        return uint256(Error.NO_ERROR);
    }

    function _disableAssetStatusOracleBatch(address[] calldata _assets) external {
        for (uint256 i = 0; i < _assets.length; i++)
            _disableAssetStatusOracle(_assets[i]);
    }

    /**
     * @notice Asset prices are provided by chain link or other aggregator.
     * @dev Get price of `asset` from aggregator.
     * @param _asset Asset for which to get the price.
     * @return Uint mantissa of asset price (scaled by 1e18) or zero if unset or under unexpected case.
     */
    function _getAssetAggregatorPrice(address _asset) internal view returns (uint256) {
        IAggregator _assetAggregator = aggregator[_asset];
        if (address(_assetAggregator) == address(0))
            return 0;

        int256 _aggregatorPrice = _assetAggregator.latestAnswer();
        if (_aggregatorPrice <= 0)
            return 0;

        return srcMul(
            uint256(_aggregatorPrice), 
            10 ** (srcSub(36, srcAdd(uint256(IERC20(_asset).decimals()), uint256(_assetAggregator.decimals()))))
        );
    }

    function getAssetAggregatorPrice(address _asset) external view returns (uint256) {
        return _getAssetAggregatorPrice(_asset);
    }

    /**
     * @notice Asset prices are provided by aggregator or a reader.
     * @dev Get price of `asset`.
     * @param _asset Asset for which to get the price.
     * @return Uint mantissa of asset price (scaled by 1e18) or zero if unset or under unexpected case.
     */
    function _getAssetPrice(address _asset) internal view returns (uint256) {
        uint256 _assetPrice = _getAssetAggregatorPrice(_asset);
        if (_assetPrice == 0)
            return _getReaderPrice(_asset);
        
        return _assetPrice;
    }

    function getAssetPrice(address _asset) external view returns (uint256) {
        return _getAssetPrice(_asset);
    }

    /**
     * @notice This is a basic function to read price, although this is a public function,
     *         It is not recommended, the recommended function is `assetPrices(asset)`.
     *         If `asset` does not has a reader to reader price, then read price from original
     *         structure `_assetPrices`;
     *         If `asset` has a reader to read price, first gets the price of reader, then
     *         `readerPrice * 10 ** |(18-assetDecimals)|`
     * @dev Get price of `asset`.
     * @param _asset Asset for which to get the price.
     * @return Uint mantissa of asset price (scaled by 1e18) or zero if unset.
     */
    function _getReaderPrice(address _asset) internal view returns (uint256) {
        Reader storage _reader = readers[_asset];
        if (_reader.asset == address(0)) return _assetPrices[_asset].mantissa;

        uint256 readerPrice = _assetPrices[_reader.asset].mantissa;

        if (_reader.decimalsDifference < 0)
            return
                srcMul(
                    readerPrice,
                    pow(10, uint256(0 - _reader.decimalsDifference))
                );

        return srcDiv(readerPrice, pow(10, uint256(_reader.decimalsDifference)));
    }

    function getReaderPrice(address _asset) external view returns (uint256) {
        return _getReaderPrice(_asset);
    }

    /**
     * @notice Retrieves price of an asset.
     * @dev Get price for an asset.
     * @param _asset Asset for which to get the price.
     * @return Uint mantissa of asset price (scaled by 1e18) or zero if unset or contract paused.
     */
    function assetPrices(address _asset) internal view returns (uint256) {
        // Note: zero is treated by the xSwap as an invalid
        //       price and will cease operations with that asset
        //       when zero.
        //
        // We get the price as:
        //
        //  1. If the contract is paused, return 0.
        //  2. If the asset has an exchange rate model, the asset price is calculated based on the exchange rate.
        //  3. Return price in `_assetPrices`, which may be zero.

        if (paused) {
            return 0;
        } else {
            uint256 _assetPrice = _getAssetPrice(_asset);
            ExchangeRateInfo storage _exchangeRateInfo = exchangeRates[_asset];
            if (_exchangeRateInfo.exchangeRateModel != address(0)) {
                uint256 _scale =
                    ExchangeRateModel(_exchangeRateInfo.exchangeRateModel)
                        .scale();
                uint256 _currentExchangeRate =
                    ExchangeRateModel(_exchangeRateInfo.exchangeRateModel)
                        .getExchangeRate();
                uint256 _currentChangeRate;
                Error _err;
                (_err, _currentChangeRate) = mul(_currentExchangeRate, _scale);
                if (_err != Error.NO_ERROR) return 0;

                _currentChangeRate =
                    _currentChangeRate /
                    _exchangeRateInfo.exchangeRate;
                // require(_currentExchangeRate >= _exchangeRateInfo.exchangeRate && _currentChangeRate <= _exchangeRateInfo.maxSwingRate, "assetPrices: Abnormal exchange rate.");
                if (
                    _currentExchangeRate < _exchangeRateInfo.exchangeRate ||
                    _currentChangeRate > _exchangeRateInfo.maxSwingRate
                ) return 0;

                uint256 _price;
                (_err, _price) = mul(_assetPrice, _currentExchangeRate);
                if (_err != Error.NO_ERROR) return 0;

                return _price / _scale;
            } else {
                return _assetPrice;
            }
        }
    }

    /**
     * @notice Retrieves price of an asset.
     * @dev Get price for an asset.
     * @param _asset Asset for which to get the price.
     * @return Uint mantissa of asset price (scaled by 1e18) or zero if unset or contract paused.
     */
    function getUnderlyingPrice(address _asset) external view returns (uint256) {
        return assetPrices(_asset);
    }

    /**
     * @notice The asset price status is provided by statusOracle.
     * @dev Get price status of `asset` from statusOracle.
     * @param _asset Asset for which to get the price status.
     * @return The asset price status is Boolean, the price status model is not set to true.true: available, false: unavailable.
     */
    function _getAssetPriceStatus(address _asset) internal view returns (bool) {

        IStatusOracle _statusOracle = statusOracle[_asset];
        if (_statusOracle == IStatusOracle(0))
            return true;

        return _statusOracle.getAssetPriceStatus(_asset);
    }

    function getAssetPriceStatus(address _asset) external view returns (bool) {
        return _getAssetPriceStatus(_asset);
    }

    /**
     * @notice Retrieve asset price and status.
     * @dev Get the price and status of the asset.
     * @param _asset The asset whose price and status are to be obtained.
     * @return Asset price and status.
     */
    function getUnderlyingPriceAndStatus(address _asset) external view returns (uint256, bool) {
        uint256 _assetPrice = assetPrices(_asset);
        return (_assetPrice, _getAssetPriceStatus(_asset));
    }

    /**
     * @dev Get exchange rate info of an asset in the time of `interval`.
     * @param _asset Asset for which to get the exchange rate info.
     * @param _interval Time to get accmulator interest rate.
     * @return Asset price, exchange rate model address, the token that is using this exchange rate model,
     *         exchange rate model contract address,
     *         the token that is using this exchange rate model,
     *         scale between token and wrapped token,
     *         exchange rate between token and wrapped token,
     *         After the time of `_interval`, get the accmulator interest rate.
     */
    function getExchangeRateInfo(address _asset, uint256 _interval)
        external
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        if (exchangeRates[_asset].exchangeRateModel == address(0))
            return (_getReaderPrice(_asset), address(0), address(0), 0, 0, 0);

        return (
            _getReaderPrice(_asset),
            exchangeRates[_asset].exchangeRateModel,
            ExchangeRateModel(exchangeRates[_asset].exchangeRateModel).token(),
            ExchangeRateModel(exchangeRates[_asset].exchangeRateModel).scale(),
            ExchangeRateModel(exchangeRates[_asset].exchangeRateModel)
                .getExchangeRate(),
            ExchangeRateModel(exchangeRates[_asset].exchangeRateModel)
                .getFixedInterestRate(_interval)
        );
    }

    struct SetPriceLocalVars {
        Exp price;
        Exp swing;
        Exp maxSwing;
        Exp anchorPrice;
        uint256 anchorPeriod;
        uint256 currentPeriod;
        bool priceCapped;
        uint256 cappingAnchorPriceMantissa;
        uint256 pendingAnchorMantissa;
    }

    /**
     * @notice Entry point for updating prices.
     *         1) If admin has set a `readerPrice` for this asset, then poster can not use this function.
     *         2) Standard stablecoin has 18 deicmals, and its price should be 1e18,
     *            so when the poster set a new price for a token,
     *            `requestedPriceMantissa` = actualPrice * 10 ** (18-tokenDecimals),
     *            actualPrice is scaled by 10**18.
     * @dev Set price for an asset.
     * @param _asset Asset for which to set the price.
     * @param _requestedPriceMantissa Requested new price, scaled by 10**18.
     * @return Uint 0=success, otherwise a failure (see enum OracleError for details).
     */
    function setPrice(address _asset, uint256 _requestedPriceMantissa)
        external
        returns (uint256)
    {
        // Fail when msg.sender is not poster
        if (msg.sender != poster) {
            return
                failOracle(
                    _asset,
                    OracleError.UNAUTHORIZED,
                    OracleFailureInfo.SET_PRICE_PERMISSION_CHECK
                );
        }

        return setPriceInternal(_asset, _requestedPriceMantissa);
    }

    function setPriceInternal(address _asset, uint256 _requestedPriceMantissa)
        internal
        returns (uint256)
    {
        // re-used for intermediate errors
        Error _err;
        SetPriceLocalVars memory _localVars;
        // We add 1 for currentPeriod so that it can never be zero and there's no ambiguity about an unset value.
        // (It can be a problem in tests with low block numbers.)
        _localVars.currentPeriod = (block.number / numBlocksPerPeriod) + 1;
        _localVars.pendingAnchorMantissa = pendingAnchors[_asset];
        _localVars.price = Exp({ mantissa: _requestedPriceMantissa });

        if (exchangeRates[_asset].exchangeRateModel != address(0)) {
            uint256 _currentExchangeRate =
                ExchangeRateModel(exchangeRates[_asset].exchangeRateModel)
                    .getExchangeRate();
            uint256 _scale =
                ExchangeRateModel(exchangeRates[_asset].exchangeRateModel)
                    .scale();
            uint256 _currentChangeRate;
            (_err, _currentChangeRate) = mul(_currentExchangeRate, _scale);
            assert(_err == Error.NO_ERROR);

            _currentChangeRate =
                _currentChangeRate /
                exchangeRates[_asset].exchangeRate;
            require(
                _currentExchangeRate >= exchangeRates[_asset].exchangeRate &&
                    _currentChangeRate <= exchangeRates[_asset].maxSwingRate,
                "setPriceInternal: Abnormal exchange rate."
            );
            exchangeRates[_asset].exchangeRate = _currentExchangeRate;
        }

        if (readers[_asset].asset != address(0)) {
            return
                failOracle(
                    _asset,
                    OracleError.FAILED_TO_SET_PRICE,
                    OracleFailureInfo.SET_PRICE_IS_READER_ASSET
                );
        }

        _localVars.maxSwing = maxSwings[_asset].mantissa == 0
            ? maxSwing
            : maxSwings[_asset];
        if (_localVars.pendingAnchorMantissa != 0) {
            // let's explicitly set to 0 rather than relying on default of declaration
            _localVars.anchorPeriod = 0;
            _localVars.anchorPrice = Exp({
                mantissa: _localVars.pendingAnchorMantissa
            });

            // Verify movement is within max swing of pending anchor (currently: 10%)
            (_err, _localVars.swing) = calculateSwing(
                _localVars.anchorPrice,
                _localVars.price
            );
            if (_err != Error.NO_ERROR) {
                return
                    failOracleWithDetails(
                        _asset,
                        OracleError.FAILED_TO_SET_PRICE,
                        OracleFailureInfo.SET_PRICE_CALCULATE_SWING,
                        uint256(_err)
                    );
            }

            // Fail when swing > maxSwing
            // if (greaterThanExp(_localVars.swing, maxSwing)) {
            if (greaterThanExp(_localVars.swing, _localVars.maxSwing)) {
                return
                    failOracleWithDetails(
                        _asset,
                        OracleError.FAILED_TO_SET_PRICE,
                        OracleFailureInfo.SET_PRICE_MAX_SWING_CHECK,
                        _localVars.swing.mantissa
                    );
            }
        } else {
            _localVars.anchorPeriod = anchors[_asset].period;
            _localVars.anchorPrice = Exp({
                mantissa: anchors[_asset].priceMantissa
            });

            if (_localVars.anchorPeriod != 0) {
                // (_err, _localVars.priceCapped, _localVars.price) = capToMax(_localVars.anchorPrice, _localVars.price);
                (_err, _localVars.priceCapped, _localVars.price) = capToMax(
                    _localVars.anchorPrice,
                    _localVars.price,
                    _localVars.maxSwing
                );
                if (_err != Error.NO_ERROR) {
                    return
                        failOracleWithDetails(
                            _asset,
                            OracleError.FAILED_TO_SET_PRICE,
                            OracleFailureInfo.SET_PRICE_CAP_TO_MAX,
                            uint256(_err)
                        );
                }
                if (_localVars.priceCapped) {
                    // save for use in log
                    _localVars.cappingAnchorPriceMantissa = _localVars
                        .anchorPrice
                        .mantissa;
                }
            } else {
                // Setting first price. Accept as is (already assigned above from _requestedPriceMantissa) and use as anchor
                _localVars.anchorPrice = Exp({
                    mantissa: _requestedPriceMantissa
                });
            }
        }

        // Fail if anchorPrice or price is zero.
        // zero anchor represents an unexpected situation likely due to a problem in this contract
        // zero price is more likely as the result of bad input from the caller of this function
        if (isZeroExp(_localVars.anchorPrice)) {
            // If we get here price could also be zero, but it does not seem worthwhile to distinguish the 3rd case
            return
                failOracle(
                    _asset,
                    OracleError.FAILED_TO_SET_PRICE,
                    OracleFailureInfo
                        .SET_PRICE_NO_ANCHOR_PRICE_OR_INITIAL_PRICE_ZERO
                );
        }

        if (isZeroExp(_localVars.price)) {
            return
                failOracle(
                    _asset,
                    OracleError.FAILED_TO_SET_PRICE,
                    OracleFailureInfo.SET_PRICE_ZERO_PRICE
                );
        }

        // BEGIN SIDE EFFECTS

        // Set pendingAnchor = Nothing
        // Pending anchor is only used once.
        if (pendingAnchors[_asset] != 0) {
            pendingAnchors[_asset] = 0;
        }

        // If currentPeriod > anchorPeriod:
        //  Set anchors[_asset] = (currentPeriod, price)
        //  The new anchor is if we're in a new period or we had a pending anchor, then we become the new anchor
        if (_localVars.currentPeriod > _localVars.anchorPeriod) {
            anchors[_asset] = Anchor({
                period: _localVars.currentPeriod,
                priceMantissa: _localVars.price.mantissa
            });
        }

        uint256 _previousPrice = _assetPrices[_asset].mantissa;

        setPriceStorageInternal(_asset, _localVars.price.mantissa);

        emit PricePosted(
            _asset,
            _previousPrice,
            _requestedPriceMantissa,
            _localVars.price.mantissa
        );

        if (_localVars.priceCapped) {
            // We have set a capped price. Log it so we can detect the situation and investigate.
            emit CappedPricePosted(
                _asset,
                _requestedPriceMantissa,
                _localVars.cappingAnchorPriceMantissa,
                _localVars.price.mantissa
            );
        }

        return uint256(OracleError.NO_ERROR);
    }

    // As a function to allow harness overrides
    function setPriceStorageInternal(address _asset, uint256 _priceMantissa)
        internal
    {
        _assetPrices[_asset] = Exp({ mantissa: _priceMantissa });
    }

    // abs(price - anchorPrice) / anchorPrice
    function calculateSwing(Exp memory _anchorPrice, Exp memory _price)
        internal
        pure
        returns (Error, Exp memory)
    {
        Exp memory numerator;
        Error err;

        if (greaterThanExp(_anchorPrice, _price)) {
            (err, numerator) = subExp(_anchorPrice, _price);
            // can't underflow
            assert(err == Error.NO_ERROR);
        } else {
            (err, numerator) = subExp(_price, _anchorPrice);
            // Given greaterThan check above, _price >= _anchorPrice so can't underflow.
            assert(err == Error.NO_ERROR);
        }

        return divExp(numerator, _anchorPrice);
    }

    // Base on the current anchor price, get the final valid price.
    function capToMax(
        Exp memory _anchorPrice,
        Exp memory _price,
        Exp memory _maxSwing
    )
        internal
        pure
        returns (
            Error,
            bool,
            Exp memory
        )
    {
        Exp memory one = Exp({ mantissa: mantissaOne });
        Exp memory onePlusMaxSwing;
        Exp memory oneMinusMaxSwing;
        Exp memory max;
        Exp memory min;
        // re-used for intermediate errors
        Error err;

        (err, onePlusMaxSwing) = addExp(one, _maxSwing);
        if (err != Error.NO_ERROR) {
            return (err, false, Exp({ mantissa: 0 }));
        }

        // max = _anchorPrice * (1 + _maxSwing)
        (err, max) = mulExp(_anchorPrice, onePlusMaxSwing);
        if (err != Error.NO_ERROR) {
            return (err, false, Exp({ mantissa: 0 }));
        }

        // If _price > _anchorPrice * (1 + _maxSwing)
        // Set _price = _anchorPrice * (1 + _maxSwing)
        if (greaterThanExp(_price, max)) {
            return (Error.NO_ERROR, true, max);
        }

        (err, oneMinusMaxSwing) = subExp(one, _maxSwing);
        if (err != Error.NO_ERROR) {
            return (err, false, Exp({ mantissa: 0 }));
        }

        // min = _anchorPrice * (1 - _maxSwing)
        (err, min) = mulExp(_anchorPrice, oneMinusMaxSwing);
        // We can't overflow here or we would have already overflowed above when calculating `max`
        assert(err == Error.NO_ERROR);

        // If  _price < _anchorPrice * (1 - _maxSwing)
        // Set _price = _anchorPrice * (1 - _maxSwing)
        if (lessThanExp(_price, min)) {
            return (Error.NO_ERROR, true, min);
        }

        return (Error.NO_ERROR, false, _price);
    }

    /**
     * @notice Entry point for updating multiple prices.
     * @dev Set prices for a variable number of assets.
     * @param _assets A list of up to assets for which to set a price.
     *        Notice: 0 < _assets.length == _requestedPriceMantissas.length
     * @param _requestedPriceMantissas Requested new prices for the assets, scaled by 10**18.
     *        Notice: 0 < _assets.length == _requestedPriceMantissas.length
     * @return Uint values in same order as inputs.
     *         For each: 0=success, otherwise a failure (see enum OracleError for details)
     */
    function setPrices(
        address[] memory _assets,
        uint256[] memory _requestedPriceMantissas
    ) external returns (uint256[] memory) {
        uint256 numAssets = _assets.length;
        uint256 numPrices = _requestedPriceMantissas.length;
        uint256[] memory result;

        // Fail when msg.sender is not poster
        if (msg.sender != poster) {
            result = new uint256[](1);
            result[0] = failOracle(
                address(0),
                OracleError.UNAUTHORIZED,
                OracleFailureInfo.SET_PRICE_PERMISSION_CHECK
            );
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
            result[i] = setPriceInternal(_assets[i], _requestedPriceMantissas[i]);
        }

        return result;
    }
}

