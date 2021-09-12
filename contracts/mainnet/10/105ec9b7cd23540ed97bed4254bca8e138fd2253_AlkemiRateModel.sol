/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// File: ErrorReporter.sol

pragma solidity 0.4.24;

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
        INVALID_COMBINED_RISK_PARAMETERS,
        ZERO_ORACLE_ADDRESS,
        CONTRACT_PAUSED,
        KYC_ADMIN_CHECK_FAILED,
        KYC_ADMIN_ADD_OR_DELETE_ADMIN_CHECK_FAILED,
        KYC_CUSTOMER_VERIFICATION_CHECK_FAILED,
        LIQUIDATOR_CHECK_FAILED,
        LIQUIDATOR_ADD_OR_DELETE_ADMIN_CHECK_FAILED,
        SET_WETH_ADDRESS_ADMIN_CHECK_FAILED,
        WETH_ADDRESS_NOT_SET_ERROR,
        ETHER_AMOUNT_MISMATCH_ERROR
    }

    /**
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        BORROW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED,
        BORROW_ACCOUNT_SHORTFALL_PRESENT,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_AMOUNT_LIQUIDITY_SHORTFALL,
        BORROW_AMOUNT_VALUE_CALCULATION_FAILED,
        BORROW_CONTRACT_PAUSED,
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
        LIQUIDATE_CONTRACT_PAUSED,
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
        LIQUIDATE_FETCH_ASSET_PRICE_FAILED,
        LIQUIDATE_TRANSFER_IN_FAILED,
        LIQUIDATE_TRANSFER_IN_NOT_POSSIBLE,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_CONTRACT_PAUSED,
        REPAY_BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_BORROW_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_ASSET_PRICE_CHECK_ORACLE,
        SET_MARKET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_ORACLE_OWNER_CHECK,
        SET_ORIGINATION_FEE_OWNER_CHECK,
        SET_PAUSED_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RISK_PARAMETERS_OWNER_CHECK,
        SET_RISK_PARAMETERS_VALIDATION,
        SUPPLY_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        SUPPLY_CONTRACT_PAUSED,
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
        SUPPORT_MARKET_FETCH_PRICE_FAILED,
        SUPPORT_MARKET_OWNER_CHECK,
        SUPPORT_MARKET_PRICE_CHECK,
        SUSPEND_MARKET_OWNER_CHECK,
        WITHDRAW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED,
        WITHDRAW_ACCOUNT_SHORTFALL_PRESENT,
        WITHDRAW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        WITHDRAW_AMOUNT_LIQUIDITY_SHORTFALL,
        WITHDRAW_AMOUNT_VALUE_CALCULATION_FAILED,
        WITHDRAW_CAPACITY_CALCULATION_FAILED,
        WITHDRAW_CONTRACT_PAUSED,
        WITHDRAW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        WITHDRAW_NEW_BORROW_RATE_CALCULATION_FAILED,
        WITHDRAW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        WITHDRAW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        WITHDRAW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        WITHDRAW_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        WITHDRAW_TRANSFER_OUT_FAILED,
        WITHDRAW_TRANSFER_OUT_NOT_POSSIBLE,
        KYC_ADMIN_CHECK_FAILED,
        KYC_ADMIN_ADD_OR_DELETE_ADMIN_CHECK_FAILED,
        KYC_CUSTOMER_VERIFICATION_CHECK_FAILED,
        LIQUIDATOR_CHECK_FAILED,
        LIQUIDATOR_ADD_OR_DELETE_ADMIN_CHECK_FAILED,
        SET_WETH_ADDRESS_ADMIN_CHECK_FAILED,
        WETH_ADDRESS_NOT_SET_ERROR,
        SEND_ETHER_ADMIN_CHECK_FAILED,
        ETHER_AMOUNT_MISMATCH_ERROR
    }

    /**
     * @dev use this when reporting a known error from the Alkemi Earn Verified or a non-upgradeable collaborator
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
// File: CarefulMath.sol

// Cloned from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol -> Commit id: 24a0bc2
// and added custom functions related to Alkemi
pragma solidity 0.4.24;


/**
 * @title Careful Math
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
 */
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

// File: Exponential.sol

// Cloned from https://github.com/compound-finance/compound-money-market/blob/master/contracts/Exponential.sol -> Commit id: 241541a
pragma solidity 0.4.24;



contract Exponential is ErrorReporter, CarefulMath {
    // Per https://solidity.readthedocs.io/en/latest/contracts.html#constant-state-variables
    // the optimizer MAY replace the expression 10**18 with its calculated value.
    uint256 constant expScale = 10**18;

    uint256 constant halfExpScale = expScale / 2;

    struct Exp {
        uint256 mantissa;
    }

    uint256 constant mantissaOne = 10**18;
    // Though unused, the below variable cannot be deleted as it will hinder upgradeability
    // Will be cleared during the next compiler version upgrade
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
    function addExp(Exp memory a, Exp memory b)
        internal
        pure
        returns (Error, Exp memory)
    {
        (Error error, uint256 result) = add(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
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

        return (error, Exp({mantissa: result}));
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
            return (err0, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: scaledMantissa}));
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
            return (err0, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint256 scalar, Exp divisor)
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
            return (err0, Exp({mantissa: 0}));
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
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (Error err1, uint256 doubleScaledProductWithHalfScale) = add(
            halfExpScale,
            doubleScaledProduct
        );
        if (err1 != Error.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (Error err2, uint256 product) = div(
            doubleScaledProductWithHalfScale,
            expScale
        );
        // The only error `div` can return is Error.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == Error.NO_ERROR);

        return (Error.NO_ERROR, Exp({mantissa: product}));
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
        return exp.mantissa / expScale;
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
// File: AlkemiRateModel.sol

pragma solidity 0.4.24;


/**
 * @title  Earn Interest Rate Model
 * @author ShiftForex
 * @notice See Model here
 */

contract AlkemiRateModel is Exponential {
    // Assuming avg. block time of 13.3 seconds; can be updated using changeBlocksPerYear() by the admin
    uint256 public blocksPerYear = 2371128;

    address public owner;
    address public newOwner;

    string public contractName;

    uint8 private hundred = 100;

    modifier onlyOwner() {
        require(msg.sender == owner, "non-owner");
        _;
    }

    enum IRError {
        NO_ERROR,
        FAILED_TO_ADD_CASH_PLUS_BORROWS,
        FAILED_TO_GET_EXP,
        FAILED_TO_MUL_PRODUCT_TIMES_BORROW_RATE
    }

    event OwnerUpdate(address indexed owner, address indexed newOwner);

    event blocksPerYearUpdated(
        uint256 oldBlocksPerYear,
        uint256 newBlocksPerYear
    );

    Exp internal SpreadLow;
    Exp internal BreakPointLow;
    Exp internal ReserveLow;
    Exp internal ReserveMid;
    Exp internal SpreadMid;
    Exp internal BreakPointHigh;
    Exp internal ReserveHigh;
    Exp internal SpreadHigh;

    Exp internal MinRateActual;
    Exp internal HealthyMinURActual;
    Exp internal HealthyMinRateActual;
    Exp internal MaxRateActual;
    Exp internal HealthyMaxURActual;
    Exp internal HealthyMaxRateActual;

    constructor(
        string memory _contractName,
        uint256 MinRate,
        uint256 HealthyMinUR,
        uint256 HealthyMinRate,
        uint256 HealthyMaxUR,
        uint256 HealthyMaxRate,
        uint256 MaxRate
    ) public {
        // Remember to enter percentage times 100. ex., if it is 2.50%, enter 250
        // Checks for reasonable interest rate parameters
        require(MinRate < MaxRate, "Min Rate should be lesser than Max Rate");
        require(
            HealthyMinUR < HealthyMaxUR,
            "HealthyMinUR should be lesser than HealthyMaxUR"
        );
        require(
            HealthyMinRate < HealthyMaxRate,
            "HealthyMinRate should be lesser than HealthyMaxRate"
        );
        owner = msg.sender;
        changeRates(
            _contractName,
            MinRate,
            HealthyMinUR,
            HealthyMinRate,
            HealthyMaxUR,
            HealthyMaxRate,
            MaxRate
        );
    }

    function changeRates(
        string memory _contractName,
        uint256 MinRate,
        uint256 HealthyMinUR,
        uint256 HealthyMinRate,
        uint256 HealthyMaxUR,
        uint256 HealthyMaxRate,
        uint256 MaxRate
    ) public onlyOwner {
        // Remember to enter percentage times 100. ex., if it is 2.50%, enter 250 as solidity does not recognize floating point numbers
        // Checks for reasonable interest rate parameters
        require(MinRate < MaxRate, "Min Rate should be lesser than Max Rate");
        require(
            HealthyMinUR < HealthyMaxUR,
            "HealthyMinUR should be lesser than HealthyMaxUR"
        );
        require(
            HealthyMinRate < HealthyMaxRate,
            "HealthyMinRate should be lesser than HealthyMaxRate"
        );
        contractName = _contractName;
        Exp memory temp1;
        Exp memory temp2;
        Exp memory HundredMantissa;
        Error err;

        (err, HundredMantissa) = getExp(hundred, 1);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol

        // Rates are divided by 1e2 to scale down inputs to actual values
        // Inputs are expressed in percentage times 1e2, so we need to scale it down again by 1e2
        // Resulting values like MinRateActual etc., are represented in 1e20 scale
        // The return values for getSupplyRate() and getBorrowRate() functions are divided by 1e2 at the end to bring it down to 1e18 scale
        (err, MinRateActual) = getExp(MinRate, hundred);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, HealthyMinURActual) = getExp(HealthyMinUR, hundred);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, HealthyMinRateActual) = getExp(HealthyMinRate, hundred);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, MaxRateActual) = getExp(MaxRate, hundred);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, HealthyMaxURActual) = getExp(HealthyMaxUR, hundred);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, HealthyMaxRateActual) = getExp(HealthyMaxRate, hundred);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol

        SpreadLow = MinRateActual;
        BreakPointLow = HealthyMinURActual;
        BreakPointHigh = HealthyMaxURActual;

        // ReserveLow = (HealthyMinRate-SpreadLow)/BreakPointLow;
        (err, temp1) = subExp(HealthyMinRateActual, SpreadLow);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, ReserveLow) = divExp(temp1, BreakPointLow);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol

        // ReserveMid = (HealthyMaxRate-HealthyMinRate)/(HealthyMaxUR-HealthyMinUR);
        (err, temp1) = subExp(HealthyMaxRateActual, HealthyMinRateActual);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, temp2) = subExp(HealthyMaxURActual, HealthyMinURActual);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, ReserveMid) = divExp(temp1, temp2);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol

        // SpreadMid = HealthyMinRate - (ReserveMid * BreakPointLow);
        (err, temp1) = mulExp(ReserveMid, BreakPointLow);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, SpreadMid) = subExp(HealthyMinRateActual, temp1);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        require(
            SpreadMid.mantissa >= 0,
            "Spread Mid cannot be a negative number"
        );
        // ReserveHigh = (MaxRate - HealthyMaxRate) / (100 - HealthyMaxUR);
        (err, temp1) = subExp(MaxRateActual, HealthyMaxRateActual);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, temp2) = subExp(HundredMantissa, HealthyMaxURActual);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, ReserveHigh) = divExp(temp1, temp2);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol

        // SpreadHigh = (ReserveHigh * BreakPointHigh) - HealthyMaxRate;
        (err, temp2) = mulExp(ReserveHigh, BreakPointHigh);
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
        (err, SpreadHigh) = subExp(temp2, HealthyMaxRateActual);
        require(
            SpreadHigh.mantissa >= 0,
            "Spread High cannot be a negative number"
        );
        require(err == Error.NO_ERROR, "Integer Underflow / Overflow"); // To check for Integer overflow and underflow errors from Exponential.sol
    }

    function changeBlocksPerYear(uint256 _blocksPerYear) external onlyOwner {
        uint256 oldBlocksPerYear = blocksPerYear;
        blocksPerYear = _blocksPerYear;
        emit blocksPerYearUpdated(oldBlocksPerYear, _blocksPerYear);
    }

    function transferOwnership(address newOwner_) external onlyOwner {
        require(newOwner_ != owner, "TransferOwnership: the same owner.");
        newOwner = newOwner_;
    }

    function acceptOwnership() external {
        require(
            msg.sender == newOwner,
            "AcceptOwnership: only new owner do this."
        );
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

    /*
     * @dev Calculates the utilization rate (borrows / (cash + borrows)) as an Exp in 1e18 scale
     */
    function getUtilizationRate(uint256 cash, uint256 borrows)
        internal
        view
        returns (IRError, Exp memory)
    {
        if (borrows == 0) {
            // Utilization rate is zero when there's no borrows
            return (IRError.NO_ERROR, Exp({mantissa: 0}));
        }

        (Error err0, uint256 cashPlusBorrows) = add(cash, borrows);
        if (err0 != Error.NO_ERROR) {
            return (
                IRError.FAILED_TO_ADD_CASH_PLUS_BORROWS,
                Exp({mantissa: 0})
            );
        }

        (Error err1, Exp memory utilizationRate) = getExp(
            borrows,
            cashPlusBorrows
        );
        if (err1 != Error.NO_ERROR) {
            return (IRError.FAILED_TO_GET_EXP, Exp({mantissa: 0}));
        }
        (err1, utilizationRate) = mulScalar(utilizationRate, hundred);
        if (err1 != Error.NO_ERROR) {
            return (IRError.FAILED_TO_GET_EXP, Exp({mantissa: 0}));
        }

        return (IRError.NO_ERROR, utilizationRate);
    }

    /*
     * @dev Calculates the utilization and borrow rates for use by get{Supply,Borrow}Rate functions
     * Both Utilization Rate and Borrow Rate are returned in 1e18 scale
     */
    function getUtilizationAndAnnualBorrowRate(uint256 cash, uint256 borrows)
        internal
        view
        returns (
            IRError,
            Exp memory,
            Exp memory
        )
    {
        (IRError err0, Exp memory utilizationRate) = getUtilizationRate(
            cash,
            borrows
        );
        if (err0 != IRError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}), Exp({mantissa: 0}));
        }

        /**
         *  Borrow Rate
         *  0 < UR < 20% :      SpreadLow + UR * ReserveLow
         *  20% <= UR <= 80% :  SpreadMid + UR * ReserveMid
         *  80% < UR :          UR * ReserveHigh - SpreadHigh
         */

        Error err;

        uint256 annualBorrowRateScaled;
        Exp memory tempScaled;
        Exp memory tempScaled2;

        if (utilizationRate.mantissa < BreakPointLow.mantissa) {
            (err, tempScaled) = mulExp(utilizationRate, ReserveLow);
            require(err == Error.NO_ERROR);
            (err, tempScaled2) = addExp(tempScaled, SpreadLow);
            annualBorrowRateScaled = tempScaled2.mantissa;
            require(err == Error.NO_ERROR);
        } else if (utilizationRate.mantissa > BreakPointHigh.mantissa) {
            (err, tempScaled) = mulExp(utilizationRate, ReserveHigh);
            require(err == Error.NO_ERROR);
            // Integer Underflow is handled in sub() function under CarefulMath
            (err, tempScaled2) = subExp(tempScaled, SpreadHigh);
            annualBorrowRateScaled = tempScaled2.mantissa;
            require(err == Error.NO_ERROR);
        } else if (
            utilizationRate.mantissa >= BreakPointLow.mantissa &&
            utilizationRate.mantissa <= BreakPointHigh.mantissa
        ) {
            (err, tempScaled) = mulExp(utilizationRate, ReserveMid);
            require(err == Error.NO_ERROR);
            (err, tempScaled2) = addExp(tempScaled, SpreadMid);
            annualBorrowRateScaled = tempScaled2.mantissa;
            require(err == Error.NO_ERROR);
        }

        return (
            IRError.NO_ERROR,
            utilizationRate,
            Exp({mantissa: annualBorrowRateScaled})
        );
    }

    /**
     * @notice Gets the current supply interest rate based on the given asset, total cash and total borrows
     * @dev The return value should be scaled by 1e18, thus a return value of
     *      `(true, 1000000000000)` implies an interest rate of 0.000001 or 0.0001% *per block*.
     * @param _asset The asset to get the interest rate of
     * @param cash The total cash of the asset in the market
     * @param borrows The total borrows of the asset in the market
     * @return Success or failure and the supply interest rate per block scaled by 1e18
     */
    function getSupplyRate(
        address _asset,
        uint256 cash,
        uint256 borrows
    ) public view returns (uint256, uint256) {
        _asset; // pragma ignore unused argument
        (
            IRError err0,
            Exp memory utilizationRate0,
            Exp memory annualBorrowRate
        ) = getUtilizationAndAnnualBorrowRate(cash, borrows);
        if (err0 != IRError.NO_ERROR) {
            return (uint256(err0), 0);
        }

        /**
         *  Supply Rate
         *  = BorrowRate * utilizationRate * (1 - SpreadLow)
         */
        Exp memory temp1;
        Error err1;
        Exp memory oneMinusSpreadBasisPoints;
        (err1, temp1) = getExp(hundred, 1);
        require(err1 == Error.NO_ERROR);
        (err1, oneMinusSpreadBasisPoints) = subExp(temp1, SpreadLow);

        // mulScalar only overflows when product is greater than or equal to 2^256.
        // utilization rate's mantissa is a number between [0e18,1e18]. That means that
        // utilizationRate1 is a value between [0e18,8.5e21]. This is strictly less than 2^256.
        require(err1 == Error.NO_ERROR);

        // Next multiply this product times the borrow rate
        // Borrow rate should be divided by 1e2 to get product at 1e18 scale
        (err1, temp1) = mulExp(
            utilizationRate0,
            Exp({mantissa: annualBorrowRate.mantissa / hundred})
        );
        // If the product of the mantissas for mulExp are both less than 2^256,
        // then this operation will never fail.
        // We know that borrow rate is in the interval [0, 2.25e17] from above.
        // We know that utilizationRate1 is in the interval [0, 9e21] from directly above.
        // As such, the multiplication is in the interval of [0, 2.025e39]. This is strictly
        // less than 2^256 (which is about 10e77).
        require(err1 == Error.NO_ERROR);

        // oneMinusSpreadBasisPoints i.e.,(1 - SpreadLow) should be divided by 1e2 to get product at 1e18 scale
        (err1, temp1) = mulExp(
            temp1,
            Exp({mantissa: oneMinusSpreadBasisPoints.mantissa / hundred})
        );
        require(err1 == Error.NO_ERROR);

        // And then divide down by the spread's denominator (basis points divisor)
        // as well as by blocks per year.
        (Error err4, Exp memory supplyRate) = divScalar(temp1, blocksPerYear); // basis points * blocks per year
        // divScalar only fails when divisor is zero. This is clearly not the case.
        require(err4 == Error.NO_ERROR);

        // Note: supplyRate.mantissa is the rate scaled 1e20 ex., 23%
        // Note: we then divide by 1e2 to scale it down to the expected 1e18 scale, which matches the expected result ex., 0.2300
        return (uint256(IRError.NO_ERROR), supplyRate.mantissa / hundred);
    }

    /**
     * @notice Gets the current borrow interest rate based on the given asset, total cash and total borrows
     * @dev The return value should be scaled by 1e18, thus a return value of
     *      `(true, 1000000000000)` implies an interest rate of 0.000001 or 0.0001% *per block*.
     * @param asset The asset to get the interest rate of
     * @param cash The total cash of the asset in the market
     * @param borrows The total borrows of the asset in the market
     * @return Success or failure and the borrow interest rate per block scaled by 1e18
     */
    function getBorrowRate(
        address asset,
        uint256 cash,
        uint256 borrows
    ) public view returns (uint256, uint256) {
        asset; // pragma ignore unused argument

        (
            IRError err0,
            ,
            Exp memory annualBorrowRate
        ) = getUtilizationAndAnnualBorrowRate(cash, borrows);
        if (err0 != IRError.NO_ERROR) {
            return (uint256(err0), 0);
        }

        // And then divide down by blocks per year.
        (Error err1, Exp memory borrowRate) = divScalar(
            annualBorrowRate,
            blocksPerYear
        ); // basis points * blocks per year
        // divScalar only fails when divisor is zero. This is clearly not the case.
        require(err1 == Error.NO_ERROR);

        // Note: borrowRate.mantissa is the rate scaled 1e20 ex., 23%
        // Note: we then divide by 1e2 to scale it down to the expected 1e18 scale, which matches the expected result ex., 0.2300
        return (uint256(IRError.NO_ERROR), borrowRate.mantissa / hundred);
    }
}