pragma solidity ^0.4.24;
contract PriceOracleInterface {

    /**
      * @notice Gets the price of a given asset
      * @dev fetches the price of a given asset
      * @param asset Asset to get the price of
      * @return the price scaled by 10**18, or zero if the price is not available
      */
    function assetPrices(address asset) public view returns (uint);
}
contract ErrorReporter {

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

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
        CONTRACT_PAUSED
    }

    /*
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
        WITHDRAW_TRANSFER_OUT_NOT_POSSIBLE
    }


    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }


    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(Error.OPAQUE_ERROR), uint(info), opaqueError);

        return uint(Error.OPAQUE_ERROR);
    }

}
contract InterestRateModel {

    /**
      * @notice Gets the current supply interest rate based on the given asset, total cash and total borrows
      * @dev The return value should be scaled by 1e18, thus a return value of
      *      `(true, 1000000000000)` implies an interest rate of 0.000001 or 0.0001% *per block*.
      * @param asset The asset to get the interest rate of
      * @param cash The total cash of the asset in the market
      * @param borrows The total borrows of the asset in the market
      * @return Success or failure and the supply interest rate per block scaled by 10e18
      */
    function getSupplyRate(address asset, uint cash, uint borrows) public view returns (uint, uint);

    /**
      * @notice Gets the current borrow interest rate based on the given asset, total cash and total borrows
      * @dev The return value should be scaled by 1e18, thus a return value of
      *      `(true, 1000000000000)` implies an interest rate of 0.000001 or 0.0001% *per block*.
      * @param asset The asset to get the interest rate of
      * @param cash The total cash of the asset in the market
      * @param borrows The total borrows of the asset in the market
      * @return Success or failure and the borrow interest rate per block scaled by 10e18
      */
    function getBorrowRate(address asset, uint cash, uint borrows) public view returns (uint, uint);
}
contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract EIP20NonStandardInterface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public;

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract CarefulMath is ErrorReporter {

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mul(uint a, uint b) internal pure returns (Error, uint) {
        if (a == 0) {
            return (Error.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (Error.INTEGER_OVERFLOW, 0);
        } else {
            return (Error.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint a, uint b) internal pure returns (Error, uint) {
        if (b == 0) {
            return (Error.DIVISION_BY_ZERO, 0);
        }

        return (Error.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (Error, uint) {
        if (b <= a) {
            return (Error.NO_ERROR, a - b);
        } else {
            return (Error.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function add(uint a, uint b) internal pure returns (Error, uint) {
        uint c = a + b;

        if (c >= a) {
            return (Error.NO_ERROR, c);
        } else {
            return (Error.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSub(uint a, uint b, uint c) internal pure returns (Error, uint) {
        (Error err0, uint sum) = add(a, b);

        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        return sub(sum, c);
    }
}
contract SafeToken is ErrorReporter {

    /**
      * @dev Checks whether or not there is sufficient allowance for this contract to move amount from `from` and
      *      whether or not `from` has a balance of at least `amount`. Does NOT do a transfer.
      */
    function checkTransferIn(address asset, address from, uint amount) internal view returns (Error) {

        EIP20Interface token = EIP20Interface(asset);

        if (token.allowance(from, address(this)) < amount) {
            return Error.TOKEN_INSUFFICIENT_ALLOWANCE;
        }

        if (token.balanceOf(from) < amount) {
            return Error.TOKEN_INSUFFICIENT_BALANCE;
        }

        return Error.NO_ERROR;
    }

    /**
      * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and returns an explanatory
      *      error code rather than reverting.  If caller has not called `checkTransferIn`, this may revert due to
      *      insufficient balance or insufficient allowance. If caller has called `checkTransferIn` prior to this call,
      *      and it returned Error.NO_ERROR, this should not revert in normal conditions.
      *
      *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
      *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
      */
    function doTransferIn(address asset, address from, uint amount) internal returns (Error) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(asset);

        bool result;

        token.transferFrom(from, address(this), amount);

        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    result := not(0)          // set result to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    result := mload(0)        // Set `result = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }

        if (!result) {
            return Error.TOKEN_TRANSFER_FAILED;
        }

        return Error.NO_ERROR;
    }

    /**
      * @dev Checks balance of this contract in asset
      */
    function getCash(address asset) internal view returns (uint) {
        EIP20Interface token = EIP20Interface(asset);

        return token.balanceOf(address(this));
    }

    /**
      * @dev Checks balance of `from` in `asset`
      */
    function getBalanceOf(address asset, address from) internal view returns (uint) {
        EIP20Interface token = EIP20Interface(asset);

        return token.balanceOf(from);
    }

    /**
      * @dev Similar to EIP20 transfer, except it handles a False result from `transfer` and returns an explanatory
      *      error code rather than reverting. If caller has not called checked protocol&#39;s balance, this may revert due to
      *      insufficient cash held in this contract. If caller has checked protocol&#39;s balance prior to this call, and verified
      *      it is >= amount, this should not revert in normal conditions.
      *
      *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
      *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
      */
    function doTransferOut(address asset, address to, uint amount) internal returns (Error) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(asset);

        bool result;

        token.transfer(to, amount);

        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    result := not(0)          // set result to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    result := mload(0)        // Set `result = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }

        if (!result) {
            return Error.TOKEN_TRANSFER_OUT_FAILED;
        }

        return Error.NO_ERROR;
    }
}
contract Exponential is ErrorReporter, CarefulMath {

    // TODO: We may wish to put the result of 10**18 here instead of the expression.
    // Per https://solidity.readthedocs.io/en/latest/contracts.html#constant-state-variables
    // the optimizer MAY replace the expression 10**18 with its calculated value.
    uint constant expScale = 10**18;

    // See TODO on expScale
    uint constant halfExpScale = expScale/2;

    struct Exp {
        uint mantissa;
    }

    uint constant mantissaOne = 10**18;
    uint constant mantissaOneTenth = 10**17;

    /**
    * @dev Creates an exponential from numerator and denominator values.
    *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
    *            or if `denom` is zero.
    */
    function getExp(uint num, uint denom) pure internal returns (Error, Exp memory) {
        (Error err0, uint scaledNumerator) = mul(num, expScale);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (Error err1, uint rational) = div(scaledNumerator, denom);
        if (err1 != Error.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
    * @dev Adds two exponentials, returning a new exponential.
    */
    function addExp(Exp memory a, Exp memory b) pure internal returns (Error, Exp memory) {
        (Error error, uint result) = add(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
    * @dev Subtracts two exponentials, returning a new exponential.
    */
    function subExp(Exp memory a, Exp memory b) pure internal returns (Error, Exp memory) {
        (Error error, uint result) = sub(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
    * @dev Multiply an Exp by a scalar, returning a new Exp.
    */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (Error, Exp memory) {
        (Error err0, uint scaledMantissa) = mul(a.mantissa, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
    * @dev Divide an Exp by a scalar, returning a new Exp.
    */
    function divScalar(Exp memory a, uint scalar) pure internal returns (Error, Exp memory) {
        (Error err0, uint descaledMantissa) = div(a.mantissa, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
    * @dev Divide a scalar by an Exp, returning a new Exp.
    */
    function divScalarByExp(uint scalar, Exp divisor) pure internal returns (Error, Exp memory) {
        /*
            We are doing this as:
            getExp(mul(expScale, scalar), divisor.mantissa)

            How it works:
            Exp = a / b;
            Scalar = s;
            `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (Error err0, uint numerator) = mul(expScale, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
    * @dev Multiplies two exponentials, returning a new exponential.
    */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (Error, Exp memory) {

        (Error err0, uint doubleScaledProduct) = mul(a.mantissa, b.mantissa);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (Error err1, uint doubleScaledProductWithHalfScale) = add(halfExpScale, doubleScaledProduct);
        if (err1 != Error.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (Error err2, uint product) = div(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is Error.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == Error.NO_ERROR);

        return (Error.NO_ERROR, Exp({mantissa: product}));
    }

    /**
      * @dev Divides two exponentials, returning a new exponential.
      *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
      *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
      */
    function divExp(Exp memory a, Exp memory b) pure internal returns (Error, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
      * @dev Truncates the given exp to a whole number value.
      *      For example, truncate(Exp{mantissa: 15 * (10**18)}) = 15
      */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we&#39;re performing a division that cannot fail
        return exp.mantissa / 10**18;
    }

    /**
      * @dev Checks if first Exp is less than second Exp.
      */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa; //TODO: Add some simple tests and this in another PR yo.
    }

    /**
      * @dev Checks if left Exp <= right Exp.
      */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
      * @dev returns true if Exp is exactly zero
      */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }
}
contract MoneyMarket is Exponential, SafeToken {

    uint constant initialInterestIndex = 10 ** 18;
    uint constant defaultOriginationFee = 0; // default is zero bps

    uint constant minimumCollateralRatioMantissa = 11 * (10 ** 17); // 1.1
    uint constant maximumLiquidationDiscountMantissa = (10 ** 17); // 0.1

    /**
      * @notice `MoneyMarket` is the core Compound MoneyMarket contract
      */
    constructor() public {
        admin = msg.sender;
        collateralRatio = Exp({mantissa: 2 * mantissaOne});
        originationFee = Exp({mantissa: defaultOriginationFee});
        liquidationDiscount = Exp({mantissa: 0});
        // oracle must be configured via _setOracle
    }

    /**
      * @notice Do not pay directly into MoneyMarket, please use `supply`.
      */
    function() payable public {
        revert();
    }

    /**
      * @dev pending Administrator for this contract.
      */
    address public pendingAdmin;

    /**
      * @dev Administrator for this contract. Initially set in constructor, but can
      *      be changed by the admin itself.
      */
    address public admin;

    /**
      * @dev Account allowed to set oracle prices for this contract. Initially set
      *      in constructor, but can be changed by the admin.
      */
    address public oracle;

    /**
      * @dev Container for customer balance information written to storage.
      *
      *      struct Balance {
      *        principal = customer total balance with accrued interest after applying the customer&#39;s most recent balance-changing action
      *        interestIndex = the total interestIndex as calculated after applying the customer&#39;s most recent balance-changing action
      *      }
      */
    struct Balance {
        uint principal;
        uint interestIndex;
    }

    /**
      * @dev 2-level map: customerAddress -> assetAddress -> balance for supplies
      */
    mapping(address => mapping(address => Balance)) public supplyBalances;


    /**
      * @dev 2-level map: customerAddress -> assetAddress -> balance for borrows
      */
    mapping(address => mapping(address => Balance)) public borrowBalances;


    /**
      * @dev Container for per-asset balance sheet and interest rate information written to storage, intended to be stored in a map where the asset address is the key
      *
      *      struct Market {
      *         isSupported = Whether this market is supported or not (not to be confused with the list of collateral assets)
      *         blockNumber = when the other values in this struct were calculated
      *         totalSupply = total amount of this asset supplied (in asset wei)
      *         supplyRateMantissa = the per-block interest rate for supplies of asset as of blockNumber, scaled by 10e18
      *         supplyIndex = the interest index for supplies of asset as of blockNumber; initialized in _supportMarket
      *         totalBorrows = total amount of this asset borrowed (in asset wei)
      *         borrowRateMantissa = the per-block interest rate for borrows of asset as of blockNumber, scaled by 10e18
      *         borrowIndex = the interest index for borrows of asset as of blockNumber; initialized in _supportMarket
      *     }
      */
    struct Market {
        bool isSupported;
        uint blockNumber;
        InterestRateModel interestRateModel;

        uint totalSupply;
        uint supplyRateMantissa;
        uint supplyIndex;

        uint totalBorrows;
        uint borrowRateMantissa;
        uint borrowIndex;
    }

    /**
      * @dev map: assetAddress -> Market
      */
    mapping(address => Market) public markets;

    /**
      * @dev list: collateralMarkets
      */
    address[] public collateralMarkets;

    /**
      * @dev The collateral ratio that borrows must maintain (e.g. 2 implies 2:1). This
      *      is initially set in the constructor, but can be changed by the admin.
      */
    Exp public collateralRatio;

    /**
      * @dev originationFee for new borrows.
      *
      */
    Exp public originationFee;

    /**
      * @dev liquidationDiscount for collateral when liquidating borrows
      *
      */
    Exp public liquidationDiscount;

    /**
      * @dev flag for whether or not contract is paused
      *
      */
    bool public paused;


    /**
      * @dev emitted when a supply is received
      *      Note: newBalance - amount - startingBalance = interest accumulated since last change
      */
    event SupplyReceived(address account, address asset, uint amount, uint startingBalance, uint newBalance);

    /**
      * @dev emitted when a supply is withdrawn
      *      Note: startingBalance - amount - startingBalance = interest accumulated since last change
      */
    event SupplyWithdrawn(address account, address asset, uint amount, uint startingBalance, uint newBalance);

    /**
      * @dev emitted when a new borrow is taken
      *      Note: newBalance - borrowAmountWithFee - startingBalance = interest accumulated since last change
      */
    event BorrowTaken(address account, address asset, uint amount, uint startingBalance, uint borrowAmountWithFee, uint newBalance);

    /**
      * @dev emitted when a borrow is repaid
      *      Note: newBalance - amount - startingBalance = interest accumulated since last change
      */
    event BorrowRepaid(address account, address asset, uint amount, uint startingBalance, uint newBalance);

    /**
      * @dev emitted when a borrow is liquidated
      *      targetAccount = user whose borrow was liquidated
      *      assetBorrow = asset borrowed
      *      borrowBalanceBefore = borrowBalance as most recently stored before the liquidation
      *      borrowBalanceAccumulated = borroBalanceBefore + accumulated interest as of immediately prior to the liquidation
      *      amountRepaid = amount of borrow repaid
      *      liquidator = account requesting the liquidation
      *      assetCollateral = asset taken from targetUser and given to liquidator in exchange for liquidated loan
      *      borrowBalanceAfter = new stored borrow balance (should equal borrowBalanceAccumulated - amountRepaid)
      *      collateralBalanceBefore = collateral balance as most recently stored before the liquidation
      *      collateralBalanceAccumulated = collateralBalanceBefore + accumulated interest as of immediately prior to the liquidation
      *      amountSeized = amount of collateral seized by liquidator
      *      collateralBalanceAfter = new stored collateral balance (should equal collateralBalanceAccumulated - amountSeized)
      */
    event BorrowLiquidated(address targetAccount,
        address assetBorrow,
        uint borrowBalanceBefore,
        uint borrowBalanceAccumulated,
        uint amountRepaid,
        uint borrowBalanceAfter,
        address liquidator,
        address assetCollateral,
        uint collateralBalanceBefore,
        uint collateralBalanceAccumulated,
        uint amountSeized,
        uint collateralBalanceAfter);

    /**
      * @dev emitted when pendingAdmin is changed
      */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
      * @dev emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
      * @dev newOracle - address of new oracle
      */
    event NewOracle(address oldOracle, address newOracle);

    /**
      * @dev emitted when new market is supported by admin
      */
    event SupportedMarket(address asset, address interestRateModel);

    /**
      * @dev emitted when risk parameters are changed by admin
      */
    event NewRiskParameters(uint oldCollateralRatioMantissa, uint newCollateralRatioMantissa, uint oldLiquidationDiscountMantissa, uint newLiquidationDiscountMantissa);

    /**
      * @dev emitted when origination fee is changed by admin
      */
    event NewOriginationFee(uint oldOriginationFeeMantissa, uint newOriginationFeeMantissa);

    /**
      * @dev emitted when market has new interest rate model set
      */
    event SetMarketInterestRateModel(address asset, address interestRateModel);

    /**
      * @dev emitted when admin withdraws equity
      * Note that `equityAvailableBefore` indicates equity before `amount` was removed.
      */
    event EquityWithdrawn(address asset, uint equityAvailableBefore, uint amount, address owner);

    /**
      * @dev emitted when a supported market is suspended by admin
      */
    event SuspendedMarket(address asset);

    /**
      * @dev emitted when admin either pauses or resumes the contract; newState is the resulting state
      */
    event SetPaused(bool newState);

    /**
      * @dev Simple function to calculate min between two numbers.
      */
    function min(uint a, uint b) pure internal returns (uint) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }

    /**
      * @dev Function to simply retrieve block number
      *      This exists mainly for inheriting test contracts to stub this result.
      */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
      * @dev Adds a given asset to the list of collateral markets. This operation is impossible to reverse.
      *      Note: this will not add the asset if it already exists.
      */
    function addCollateralMarket(address asset) internal {
        for (uint i = 0; i < collateralMarkets.length; i++) {
            if (collateralMarkets[i] == asset) {
                return;
            }
        }

        collateralMarkets.push(asset);
    }

    /**
      * @notice return the number of elements in `collateralMarkets`
      * @dev you can then externally call `collateralMarkets(uint)` to pull each market address
      * @return the length of `collateralMarkets`
      */
    function getCollateralMarketsLength() public view returns (uint) {
        return collateralMarkets.length;
    }

    /**
      * @dev Calculates a new supply index based on the prevailing interest rates applied over time
      *      This is defined as `we multiply the most recent supply index by (1 + blocks times rate)`
      */
    function calculateInterestIndex(uint startingInterestIndex, uint interestRateMantissa, uint blockStart, uint blockEnd) pure internal returns (Error, uint) {

        // Get the block delta
        (Error err0, uint blockDelta) = sub(blockEnd, blockStart);
        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        // Scale the interest rate times number of blocks
        // Note: Doing Exp construction inline to avoid `CompilerError: Stack too deep, try removing local variables.`
        (Error err1, Exp memory blocksTimesRate) = mulScalar(Exp({mantissa: interestRateMantissa}), blockDelta);
        if (err1 != Error.NO_ERROR) {
            return (err1, 0);
        }

        // Add one to that result (which is really Exp({mantissa: expScale}) which equals 1.0)
        (Error err2, Exp memory onePlusBlocksTimesRate) = addExp(blocksTimesRate, Exp({mantissa: mantissaOne}));
        if (err2 != Error.NO_ERROR) {
            return (err2, 0);
        }

        // Then scale that accumulated interest by the old interest index to get the new interest index
        (Error err3, Exp memory newInterestIndexExp) = mulScalar(onePlusBlocksTimesRate, startingInterestIndex);
        if (err3 != Error.NO_ERROR) {
            return (err3, 0);
        }

        // Finally, truncate the interest index. This works only if interest index starts large enough
        // that is can be accurately represented with a whole number.
        return (Error.NO_ERROR, truncate(newInterestIndexExp));
    }

    /**
      * @dev Calculates a new balance based on a previous balance and a pair of interest indices
      *      This is defined as: `The user&#39;s last balance checkpoint is multiplied by the currentSupplyIndex
      *      value and divided by the user&#39;s checkpoint index value`
      *
      *      TODO: Is there a way to handle this that is less likely to overflow?
      */
    function calculateBalance(uint startingBalance, uint interestIndexStart, uint interestIndexEnd) pure internal returns (Error, uint) {
        if (startingBalance == 0) {
            // We are accumulating interest on any previous balance; if there&#39;s no previous balance, then there is
            // nothing to accumulate.
            return (Error.NO_ERROR, 0);
        }
        (Error err0, uint balanceTimesIndex) = mul(startingBalance, interestIndexEnd);
        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        return div(balanceTimesIndex, interestIndexStart);
    }

    /**
      * @dev Gets the price for the amount specified of the given asset.
      */
    function getPriceForAssetAmount(address asset, uint assetAmount) internal view returns (Error, Exp memory)  {
        (Error err, Exp memory assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}));
        }

        if (isZeroExp(assetPrice)) {
            return (Error.MISSING_ASSET_PRICE, Exp({mantissa: 0}));
        }

        return mulScalar(assetPrice, assetAmount); // assetAmountWei * oraclePrice = assetValueInEth
    }

    /**
      * @dev Gets the price for the amount specified of the given asset multiplied by the current
      *      collateral ratio (i.e., assetAmountWei * collateralRatio * oraclePrice = totalValueInEth).
      *      We will group this as `(oraclePrice * collateralRatio) * assetAmountWei`
      */
    function getPriceForAssetAmountMulCollatRatio(address asset, uint assetAmount) internal view returns (Error, Exp memory)  {
        Error err;
        Exp memory assetPrice;
        Exp memory scaledPrice;
        (err, assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}));
        }

        if (isZeroExp(assetPrice)) {
            return (Error.MISSING_ASSET_PRICE, Exp({mantissa: 0}));
        }

        // Now, multiply the assetValue by the collateral ratio
        (err, scaledPrice) = mulExp(collateralRatio, assetPrice);
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}));
        }

        // Get the price for the given asset amount
        return mulScalar(scaledPrice, assetAmount);
    }

    /**
      * @dev Calculates the origination fee added to a given borrowAmount
      *      This is simply `(1 + originationFee) * borrowAmount`
      *
      *      TODO: Track at what magnitude this fee rounds down to zero?
      */
    function calculateBorrowAmountWithFee(uint borrowAmount) view internal returns (Error, uint) {
        // When origination fee is zero, the amount with fee is simply equal to the amount
        if (isZeroExp(originationFee)) {
            return (Error.NO_ERROR, borrowAmount);
        }

        (Error err0, Exp memory originationFeeFactor) = addExp(originationFee, Exp({mantissa: mantissaOne}));
        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        (Error err1, Exp memory borrowAmountWithFee) = mulScalar(originationFeeFactor, borrowAmount);
        if (err1 != Error.NO_ERROR) {
            return (err1, 0);
        }

        return (Error.NO_ERROR, truncate(borrowAmountWithFee));
    }

    /**
      * @dev fetches the price of asset from the PriceOracle and converts it to Exp
      * @param asset asset whose price should be fetched
      */
    function fetchAssetPrice(address asset) internal view returns (Error, Exp memory) {
        if (oracle == address(0)) {
            return (Error.ZERO_ORACLE_ADDRESS, Exp({mantissa: 0}));
        }

        PriceOracleInterface oracleInterface = PriceOracleInterface(oracle);
        uint priceMantissa = oracleInterface.assetPrices(asset);

        return (Error.NO_ERROR, Exp({mantissa: priceMantissa}));
    }

    /**
      * @notice Reads scaled price of specified asset from the price oracle
      * @dev Reads scaled price of specified asset from the price oracle.
      *      The plural name is to match a previous storage mapping that this function replaced.
      * @param asset Asset whose price should be retrieved
      * @return 0 on an error or missing price, the price scaled by 1e18 otherwise
      */
    function assetPrices(address asset) public view returns (uint) {
        (Error err, Exp memory result) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return 0;
        }
        return result.mantissa;
    }

    /**
      * @dev Gets the amount of the specified asset given the specified Eth value
      *      ethValue / oraclePrice = assetAmountWei
      *      If there&#39;s no oraclePrice, this returns (Error.DIVISION_BY_ZERO, 0)
      */
    function getAssetAmountForValue(address asset, Exp ethValue) internal view returns (Error, uint) {
        Error err;
        Exp memory assetPrice;
        Exp memory assetAmount;

        (err, assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, assetAmount) = divExp(ethValue, assetPrice);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(assetAmount));
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      *
      * TODO: Should we add a second arg to verify, like a checksum of `newAdmin` address?
      */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin = newPendingAdmin
        pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() public returns (uint) {
        // Check caller = pendingAdmin
        // msg.sender can&#39;t be zero
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current value for inclusion in log
        address oldAdmin = admin;
        // Store admin = pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = 0;

        emit NewAdmin(oldAdmin, msg.sender);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Set new oracle, who can set asset prices
      * @dev Admin function to change oracle
      * @param newOracle New oracle address
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setOracle(address newOracle) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_ORACLE_OWNER_CHECK);
        }

        // Verify contract at newOracle address supports assetPrices call.
        // This will revert if it doesn&#39;t.
        PriceOracleInterface oracleInterface = PriceOracleInterface(newOracle);
        oracleInterface.assetPrices(address(0));

        address oldOracle = oracle;

        // Store oracle = newOracle
        oracle = newOracle;

        emit NewOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice set `paused` to the specified state
      * @dev Admin function to pause or resume the market
      * @param requestedState value to assign to `paused`
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPaused(bool requestedState) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSED_OWNER_CHECK);
        }

        paused = requestedState;
        emit SetPaused(requestedState);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice returns the liquidity for given account.
      *         a positive result indicates ability to borrow, whereas
      *         a negative result indicates a shortfall which may be liquidated
      * @dev returns account liquidity in terms of eth-wei value, scaled by 1e18
      *      note: this includes interest trued up on all balances
      * @param account the account to examine
      * @return signed integer in terms of eth-wei (negative indicates a shortfall)
      */
    function getAccountLiquidity(address account) public view returns (int) {
        (Error err, Exp memory accountLiquidity, Exp memory accountShortfall) = calculateAccountLiquidity(account);
        require(err == Error.NO_ERROR);

        if (isZeroExp(accountLiquidity)) {
            return -1 * int(truncate(accountShortfall));
        } else {
            return int(truncate(accountLiquidity));
        }
    }

    /**
      * @notice return supply balance with any accumulated interest for `asset` belonging to `account`
      * @dev returns supply balance with any accumulated interest for `asset` belonging to `account`
      * @param account the account to examine
      * @param asset the market asset whose supply balance belonging to `account` should be checked
      * @return uint supply balance on success, throws on failed assertion otherwise
      */
    function getSupplyBalance(address account, address asset) view public returns (uint) {
        Error err;
        uint newSupplyIndex;
        uint userSupplyCurrent;

        Market storage market = markets[asset];
        Balance storage supplyBalance = supplyBalances[account][asset];

        // Calculate the newSupplyIndex, needed to calculate user&#39;s supplyCurrent
        (err, newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        require(err == Error.NO_ERROR);

        // Use newSupplyIndex and stored principal to calculate the accumulated balance
        (err, userSupplyCurrent) = calculateBalance(supplyBalance.principal, supplyBalance.interestIndex, newSupplyIndex);
        require(err == Error.NO_ERROR);

        return userSupplyCurrent;
    }

    /**
      * @notice return borrow balance with any accumulated interest for `asset` belonging to `account`
      * @dev returns borrow balance with any accumulated interest for `asset` belonging to `account`
      * @param account the account to examine
      * @param asset the market asset whose borrow balance belonging to `account` should be checked
      * @return uint borrow balance on success, throws on failed assertion otherwise
      */
    function getBorrowBalance(address account, address asset) view public returns (uint) {
        Error err;
        uint newBorrowIndex;
        uint userBorrowCurrent;

        Market storage market = markets[asset];
        Balance storage borrowBalance = borrowBalances[account][asset];

        // Calculate the newBorrowIndex, needed to calculate user&#39;s borrowCurrent
        (err, newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        require(err == Error.NO_ERROR);

        // Use newBorrowIndex and stored principal to calculate the accumulated balance
        (err, userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, newBorrowIndex);
        require(err == Error.NO_ERROR);

        return userBorrowCurrent;
    }


    /**
      * @notice Supports a given market (asset) for use with Compound
      * @dev Admin function to add support for a market
      * @param asset Asset to support; MUST already have a non-zero price set
      * @param interestRateModel InterestRateModel to use for the asset
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _supportMarket(address asset, InterestRateModel interestRateModel) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        (Error err, Exp memory assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPORT_MARKET_FETCH_PRICE_FAILED);
        }

        if (isZeroExp(assetPrice)) {
            return fail(Error.ASSET_NOT_PRICED, FailureInfo.SUPPORT_MARKET_PRICE_CHECK);
        }

        // Set the interest rate model to `modelAddress`
        markets[asset].interestRateModel = interestRateModel;

        // Append asset to collateralAssets if not set
        addCollateralMarket(asset);

        // Set market isSupported to true
        markets[asset].isSupported = true;

        // Default supply and borrow index to 1e18
        if (markets[asset].supplyIndex == 0) {
            markets[asset].supplyIndex = initialInterestIndex;
        }

        if (markets[asset].borrowIndex == 0) {
            markets[asset].borrowIndex = initialInterestIndex;
        }

        emit SupportedMarket(asset, interestRateModel);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Suspends a given *supported* market (asset) from use with Compound.
      *         Assets in this state do count for collateral, but users may only withdraw, payBorrow,
      *         and liquidate the asset. The liquidate function no longer checks collateralization.
      * @dev Admin function to suspend a market
      * @param asset Asset to suspend
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _suspendMarket(address asset) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUSPEND_MARKET_OWNER_CHECK);
        }

        // If the market is not configured at all, we don&#39;t want to add any configuration for it.
        // If we find !markets[asset].isSupported then either the market is not configured at all, or it
        // has already been marked as unsupported. We can just return without doing anything.
        // Caller is responsible for knowing the difference between not-configured and already unsupported.
        if (!markets[asset].isSupported) {
            return uint(Error.NO_ERROR);
        }

        // If we get here, we know market is configured and is supported, so set isSupported to false
        markets[asset].isSupported = false;

        emit SuspendedMarket(asset);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the risk parameters: collateral ratio and liquidation discount
      * @dev Owner function to set the risk parameters
      * @param collateralRatioMantissa rational collateral ratio, scaled by 1e18. The de-scaled value must be >= 1.1
      * @param liquidationDiscountMantissa rational liquidation discount, scaled by 1e18. The de-scaled value must be <= 0.1 and must be less than (descaled collateral ratio minus 1)
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setRiskParameters(uint collateralRatioMantissa, uint liquidationDiscountMantissa) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_RISK_PARAMETERS_OWNER_CHECK);
        }

        Exp memory newCollateralRatio = Exp({mantissa: collateralRatioMantissa});
        Exp memory newLiquidationDiscount = Exp({mantissa: liquidationDiscountMantissa});
        Exp memory minimumCollateralRatio = Exp({mantissa: minimumCollateralRatioMantissa});
        Exp memory maximumLiquidationDiscount = Exp({mantissa: maximumLiquidationDiscountMantissa});

        Error err;
        Exp memory newLiquidationDiscountPlusOne;

        // Make sure new collateral ratio value is not below minimum value
        if (lessThanExp(newCollateralRatio, minimumCollateralRatio)) {
            return fail(Error.INVALID_COLLATERAL_RATIO, FailureInfo.SET_RISK_PARAMETERS_VALIDATION);
        }

        // Make sure new liquidation discount does not exceed the maximum value, but reverse operands so we can use the
        // existing `lessThanExp` function rather than adding a `greaterThan` function to Exponential.
        if (lessThanExp(maximumLiquidationDiscount, newLiquidationDiscount)) {
            return fail(Error.INVALID_LIQUIDATION_DISCOUNT, FailureInfo.SET_RISK_PARAMETERS_VALIDATION);
        }

        // C = L+1 is not allowed because it would cause division by zero error in `calculateDiscountedRepayToEvenAmount`
        // C < L+1 is not allowed because it would cause integer underflow error in `calculateDiscountedRepayToEvenAmount`
        (err, newLiquidationDiscountPlusOne) = addExp(newLiquidationDiscount, Exp({mantissa: mantissaOne}));
        assert(err == Error.NO_ERROR); // We already validated that newLiquidationDiscount does not approach overflow size

        if (lessThanOrEqualExp(newCollateralRatio, newLiquidationDiscountPlusOne)) {
            return fail(Error.INVALID_COMBINED_RISK_PARAMETERS, FailureInfo.SET_RISK_PARAMETERS_VALIDATION);
        }

        // Save current values so we can emit them in log.
        Exp memory oldCollateralRatio = collateralRatio;
        Exp memory oldLiquidationDiscount = liquidationDiscount;

        // Store new values
        collateralRatio = newCollateralRatio;
        liquidationDiscount = newLiquidationDiscount;

        emit NewRiskParameters(oldCollateralRatio.mantissa, collateralRatioMantissa, oldLiquidationDiscount.mantissa, liquidationDiscountMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the origination fee (which is a multiplier on new borrows)
      * @dev Owner function to set the origination fee
      * @param originationFeeMantissa rational collateral ratio, scaled by 1e18. The de-scaled value must be >= 1.1
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setOriginationFee(uint originationFeeMantissa) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_ORIGINATION_FEE_OWNER_CHECK);
        }

        // Save current value so we can emit it in log.
        Exp memory oldOriginationFee = originationFee;

        originationFee = Exp({mantissa: originationFeeMantissa});

        emit NewOriginationFee(oldOriginationFee.mantissa, originationFeeMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the interest rate model for a given market
      * @dev Admin function to set interest rate model
      * @param asset Asset to support
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setMarketInterestRateModel(address asset, InterestRateModel interestRateModel) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MARKET_INTEREST_RATE_MODEL_OWNER_CHECK);
        }

        // Set the interest rate model to `modelAddress`
        markets[asset].interestRateModel = interestRateModel;

        emit SetMarketInterestRateModel(asset, interestRateModel);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice withdraws `amount` of `asset` from equity for asset, as long as `amount` <= equity. Equity= cash - (supply + borrows)
      * @dev withdraws `amount` of `asset` from equity  for asset, enforcing amount <= cash - (supply + borrows)
      * @param asset asset whose equity should be withdrawn
      * @param amount amount of equity to withdraw; must not exceed equity available
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _withdrawEquity(address asset, uint amount) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.EQUITY_WITHDRAWAL_MODEL_OWNER_CHECK);
        }

        // Check that amount is less than cash (from ERC-20 of self) plus borrows minus supply.
        uint cash = getCash(asset);
        (Error err0, uint equity) = addThenSub(cash, markets[asset].totalBorrows, markets[asset].totalSupply);
        if (err0 != Error.NO_ERROR) {
            return fail(err0, FailureInfo.EQUITY_WITHDRAWAL_CALCULATE_EQUITY);
        }

        if (amount > equity) {
            return fail(Error.EQUITY_INSUFFICIENT_BALANCE, FailureInfo.EQUITY_WITHDRAWAL_AMOUNT_VALIDATION);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        // We ERC-20 transfer the asset out of the protocol to the admin
        Error err2 = doTransferOut(asset, admin, amount);
        if (err2 != Error.NO_ERROR) {
            // This is safe since it&#39;s our first interaction and it didn&#39;t do anything if it failed
            return fail(err2, FailureInfo.EQUITY_WITHDRAWAL_TRANSFER_OUT_FAILED);
        }

        //event EquityWithdrawn(address asset, uint equityAvailableBefore, uint amount, address owner)
        emit EquityWithdrawn(asset, equity, amount, admin);

        return uint(Error.NO_ERROR); // success
    }

    /**
      * The `SupplyLocalVars` struct is used internally in the `supply` function.
      *
      * To avoid solidity limits on the number of local variables we:
      * 1. Use a struct to hold local computation localResults
      * 2. Re-use a single variable for Error returns. (This is required with 1 because variable binding to tuple localResults
      *    requires either both to be declared inline or both to be previously declared.
      * 3. Re-use a boolean error-like return variable.
      */
    struct SupplyLocalVars {
        uint startingBalance;
        uint newSupplyIndex;
        uint userSupplyCurrent;
        uint userSupplyUpdated;
        uint newTotalSupply;
        uint currentCash;
        uint updatedCash;
        uint newSupplyRateMantissa;
        uint newBorrowIndex;
        uint newBorrowRateMantissa;
    }


    /**
      * @notice supply `amount` of `asset` (which must be supported) to `msg.sender` in the protocol
      * @dev add amount of supported asset to msg.sender&#39;s account
      * @param asset The market asset to supply
      * @param amount The amount to supply
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function supply(address asset, uint amount) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.SUPPLY_CONTRACT_PAUSED);
        }

        Market storage market = markets[asset];
        Balance storage balance = supplyBalances[msg.sender][asset];

        SupplyLocalVars memory localResults; // Holds all our uint calculation results
        Error err; // Re-used for every function call that includes an Error in its return value(s).
        uint rateCalculationResultCode; // Used for 2 interest rate calculation calls

        // Fail if market not supported
        if (!market.isSupported) {
            return fail(Error.MARKET_NOT_SUPPORTED, FailureInfo.SUPPLY_MARKET_NOT_SUPPORTED);
        }

        // Fail gracefully if asset is not approved or has insufficient balance
        err = checkTransferIn(asset, msg.sender, amount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_TRANSFER_IN_NOT_POSSIBLE);
        }

        // We calculate the newSupplyIndex, user&#39;s supplyCurrent and supplyUpdated for the asset
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userSupplyCurrent) = calculateBalance(balance.principal, balance.interestIndex, localResults.newSupplyIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

        (err, localResults.userSupplyUpdated) = add(localResults.userSupplyCurrent, amount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

        // We calculate the protocol&#39;s totalSupply by subtracting the user&#39;s prior checkpointed balance, adding user&#39;s updated supply
        (err, localResults.newTotalSupply) = addThenSub(market.totalSupply, localResults.userSupplyUpdated, balance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_TOTAL_SUPPLY_CALCULATION_FAILED);
        }

        // We need to calculate what the updated cash will be after we transfer in from user
        localResults.currentCash = getCash(asset);

        (err, localResults.updatedCash) = add(localResults.currentCash, amount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_TOTAL_CASH_CALCULATION_FAILED);
        }

        // The utilization rate has changed! We calculate a new supply index and borrow index for the asset, and save it.
        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.SUPPLY_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        // We calculate the newBorrowIndex (we already had newSupplyIndex)
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.SUPPLY_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
        err = doTransferIn(asset, msg.sender, amount);
        if (err != Error.NO_ERROR) {
            // This is safe since it&#39;s our first interaction and it didn&#39;t do anything if it failed
            return fail(err, FailureInfo.SUPPLY_TRANSFER_IN_FAILED);
        }

        // Save market updates
        market.blockNumber = getBlockNumber();
        market.totalSupply =  localResults.newTotalSupply;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

        // Save user updates
        localResults.startingBalance = balance.principal; // save for use in `SupplyReceived` event
        balance.principal = localResults.userSupplyUpdated;
        balance.interestIndex = localResults.newSupplyIndex;

        emit SupplyReceived(msg.sender, asset, amount, localResults.startingBalance, localResults.userSupplyUpdated);

        return uint(Error.NO_ERROR); // success
    }

    struct WithdrawLocalVars {
        uint withdrawAmount;
        uint startingBalance;
        uint newSupplyIndex;
        uint userSupplyCurrent;
        uint userSupplyUpdated;
        uint newTotalSupply;
        uint currentCash;
        uint updatedCash;
        uint newSupplyRateMantissa;
        uint newBorrowIndex;
        uint newBorrowRateMantissa;

        Exp accountLiquidity;
        Exp accountShortfall;
        Exp ethValueOfWithdrawal;
        uint withdrawCapacity;
    }


    /**
      * @notice withdraw `amount` of `asset` from sender&#39;s account to sender&#39;s address
      * @dev withdraw `amount` of `asset` from msg.sender&#39;s account to msg.sender
      * @param asset The market asset to withdraw
      * @param requestedAmount The amount to withdraw (or -1 for max)
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function withdraw(address asset, uint requestedAmount) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.WITHDRAW_CONTRACT_PAUSED);
        }

        Market storage market = markets[asset];
        Balance storage supplyBalance = supplyBalances[msg.sender][asset];

        WithdrawLocalVars memory localResults; // Holds all our calculation results
        Error err; // Re-used for every function call that includes an Error in its return value(s).
        uint rateCalculationResultCode; // Used for 2 interest rate calculation calls

        // We calculate the user&#39;s accountLiquidity and accountShortfall.
        (err, localResults.accountLiquidity, localResults.accountShortfall) = calculateAccountLiquidity(msg.sender);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED);
        }

        // We calculate the newSupplyIndex, user&#39;s supplyCurrent and supplyUpdated for the asset
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userSupplyCurrent) = calculateBalance(supplyBalance.principal, supplyBalance.interestIndex, localResults.newSupplyIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

        // If the user specifies -1 amount to withdraw ("max"),  withdrawAmount => the lesser of withdrawCapacity and supplyCurrent
        if (requestedAmount == uint(-1)) {
            (err, localResults.withdrawCapacity) = getAssetAmountForValue(asset, localResults.accountLiquidity);
            if (err != Error.NO_ERROR) {
                return fail(err, FailureInfo.WITHDRAW_CAPACITY_CALCULATION_FAILED);
            }
            localResults.withdrawAmount = min(localResults.withdrawCapacity, localResults.userSupplyCurrent);
        } else {
            localResults.withdrawAmount = requestedAmount;
        }

        // From here on we should NOT use requestedAmount.

        // Fail gracefully if protocol has insufficient cash
        // If protocol has insufficient cash, the sub operation will underflow.
        localResults.currentCash = getCash(asset);
        (err, localResults.updatedCash) = sub(localResults.currentCash, localResults.withdrawAmount);
        if (err != Error.NO_ERROR) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.WITHDRAW_TRANSFER_OUT_NOT_POSSIBLE);
        }

        // We check that the amount is less than or equal to supplyCurrent
        // If amount is greater than supplyCurrent, this will fail with Error.INTEGER_UNDERFLOW
        (err, localResults.userSupplyUpdated) = sub(localResults.userSupplyCurrent, localResults.withdrawAmount);
        if (err != Error.NO_ERROR) {
            return fail(Error.INSUFFICIENT_BALANCE, FailureInfo.WITHDRAW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

        // Fail if customer already has a shortfall
        if (!isZeroExp(localResults.accountShortfall)) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.WITHDRAW_ACCOUNT_SHORTFALL_PRESENT);
        }

        // We want to know the user&#39;s withdrawCapacity, denominated in the asset
        // Customer&#39;s withdrawCapacity of asset is (accountLiquidity in Eth)/ (price of asset in Eth)
        // Equivalently, we calculate the eth value of the withdrawal amount and compare it directly to the accountLiquidity in Eth
        (err, localResults.ethValueOfWithdrawal) = getPriceForAssetAmount(asset, localResults.withdrawAmount); // amount * oraclePrice = ethValueOfWithdrawal
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_AMOUNT_VALUE_CALCULATION_FAILED);
        }

        // We check that the amount is less than withdrawCapacity (here), and less than or equal to supplyCurrent (below)
        if (lessThanExp(localResults.accountLiquidity, localResults.ethValueOfWithdrawal) ) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.WITHDRAW_AMOUNT_LIQUIDITY_SHORTFALL);
        }

        // We calculate the protocol&#39;s totalSupply by subtracting the user&#39;s prior checkpointed balance, adding user&#39;s updated supply.
        // Note that, even though the customer is withdrawing, if they&#39;ve accumulated a lot of interest since their last
        // action, the updated balance *could* be higher than the prior checkpointed balance.
        (err, localResults.newTotalSupply) = addThenSub(market.totalSupply, localResults.userSupplyUpdated, supplyBalance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_NEW_TOTAL_SUPPLY_CALCULATION_FAILED);
        }

        // The utilization rate has changed! We calculate a new supply index and borrow index for the asset, and save it.
        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.WITHDRAW_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        // We calculate the newBorrowIndex
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.WITHDRAW_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
        err = doTransferOut(asset, msg.sender, localResults.withdrawAmount);
        if (err != Error.NO_ERROR) {
            // This is safe since it&#39;s our first interaction and it didn&#39;t do anything if it failed
            return fail(err, FailureInfo.WITHDRAW_TRANSFER_OUT_FAILED);
        }

        // Save market updates
        market.blockNumber = getBlockNumber();
        market.totalSupply =  localResults.newTotalSupply;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

        // Save user updates
        localResults.startingBalance = supplyBalance.principal; // save for use in `SupplyWithdrawn` event
        supplyBalance.principal = localResults.userSupplyUpdated;
        supplyBalance.interestIndex = localResults.newSupplyIndex;

        emit SupplyWithdrawn(msg.sender, asset, localResults.withdrawAmount, localResults.startingBalance, localResults.userSupplyUpdated);

        return uint(Error.NO_ERROR); // success
    }

    struct AccountValueLocalVars {
        address assetAddress;
        uint collateralMarketsLength;

        uint newSupplyIndex;
        uint userSupplyCurrent;
        Exp supplyTotalValue;
        Exp sumSupplies;

        uint newBorrowIndex;
        uint userBorrowCurrent;
        Exp borrowTotalValue;
        Exp sumBorrows;
    }

    /**
      * @dev Gets the user&#39;s account liquidity and account shortfall balances. This includes
      *      any accumulated interest thus far but does NOT actually update anything in
      *      storage, it simply calculates the account liquidity and shortfall with liquidity being
      *      returned as the first Exp, ie (Error, accountLiquidity, accountShortfall).
      */
    function calculateAccountLiquidity(address userAddress) internal view returns (Error, Exp memory, Exp memory) {
        Error err;
        uint sumSupplyValuesMantissa;
        uint sumBorrowValuesMantissa;
        (err, sumSupplyValuesMantissa, sumBorrowValuesMantissa) = calculateAccountValuesInternal(userAddress);
        if (err != Error.NO_ERROR) {
            return(err, Exp({mantissa: 0}), Exp({mantissa: 0}));
        }

        Exp memory result;
        
        Exp memory sumSupplyValuesFinal = Exp({mantissa: sumSupplyValuesMantissa});
        Exp memory sumBorrowValuesFinal; // need to apply collateral ratio

        (err, sumBorrowValuesFinal) = mulExp(collateralRatio, Exp({mantissa: sumBorrowValuesMantissa}));
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}), Exp({mantissa: 0}));
        }

        // if sumSupplies < sumBorrows, then the user is under collateralized and has account shortfall.
        // else the user meets the collateral ratio and has account liquidity.
        if (lessThanExp(sumSupplyValuesFinal, sumBorrowValuesFinal)) {
            // accountShortfall = borrows - supplies
            (err, result) = subExp(sumBorrowValuesFinal, sumSupplyValuesFinal);
            assert(err == Error.NO_ERROR); // Note: we have checked that sumBorrows is greater than sumSupplies directly above, therefore `subExp` cannot fail.

            return (Error.NO_ERROR, Exp({mantissa: 0}), result);
        } else {
            // accountLiquidity = supplies - borrows
            (err, result) = subExp(sumSupplyValuesFinal, sumBorrowValuesFinal);
            assert(err == Error.NO_ERROR); // Note: we have checked that sumSupplies is greater than sumBorrows directly above, therefore `subExp` cannot fail.

            return (Error.NO_ERROR, result, Exp({mantissa: 0}));
        }
    }

    /**
      * @notice Gets the ETH values of the user&#39;s accumulated supply and borrow balances, scaled by 10e18.
      *         This includes any accumulated interest thus far but does NOT actually update anything in
      *         storage
      * @dev Gets ETH values of accumulated supply and borrow balances
      * @param userAddress account for which to sum values
      * @return (error code, sum ETH value of supplies scaled by 10e18, sum ETH value of borrows scaled by 10e18)
      * TODO: Possibly should add a Min(500, collateralMarkets.length) for extra safety
      * TODO: To help save gas we could think about using the current Market.interestIndex
      *       accumulate interest rather than calculating it
      */
    function calculateAccountValuesInternal(address userAddress) internal view returns (Error, uint, uint) {
        
        /** By definition, all collateralMarkets are those that contribute to the user&#39;s
          * liquidity and shortfall so we need only loop through those markets.
          * To handle avoiding intermediate negative results, we will sum all the user&#39;s
          * supply balances and borrow balances (with collateral ratio) separately and then
          * subtract the sums at the end.
          */

        AccountValueLocalVars memory localResults; // Re-used for all intermediate results
        localResults.sumSupplies = Exp({mantissa: 0});
        localResults.sumBorrows = Exp({mantissa: 0});
        Error err; // Re-used for all intermediate errors
        localResults.collateralMarketsLength = collateralMarkets.length;

        for (uint i = 0; i < localResults.collateralMarketsLength; i++) {
            localResults.assetAddress = collateralMarkets[i];
            Market storage currentMarket = markets[localResults.assetAddress];
            Balance storage supplyBalance = supplyBalances[userAddress][localResults.assetAddress];
            Balance storage borrowBalance = borrowBalances[userAddress][localResults.assetAddress];

            if (supplyBalance.principal > 0) {
                // We calculate the newSupplyIndex and user’s supplyCurrent (includes interest)
                (err, localResults.newSupplyIndex) = calculateInterestIndex(currentMarket.supplyIndex, currentMarket.supplyRateMantissa, currentMarket.blockNumber, getBlockNumber());
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                (err, localResults.userSupplyCurrent) = calculateBalance(supplyBalance.principal, supplyBalance.interestIndex, localResults.newSupplyIndex);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                // We have the user&#39;s supply balance with interest so let&#39;s multiply by the asset price to get the total value
                (err, localResults.supplyTotalValue) = getPriceForAssetAmount(localResults.assetAddress, localResults.userSupplyCurrent); // supplyCurrent * oraclePrice = supplyValueInEth
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                // Add this to our running sum of supplies
                (err, localResults.sumSupplies) = addExp(localResults.supplyTotalValue, localResults.sumSupplies);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }
            }

            if (borrowBalance.principal > 0) {
                // We perform a similar actions to get the user&#39;s borrow balance
                (err, localResults.newBorrowIndex) = calculateInterestIndex(currentMarket.borrowIndex, currentMarket.borrowRateMantissa, currentMarket.blockNumber, getBlockNumber());
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                (err, localResults.userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, localResults.newBorrowIndex);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                // In the case of borrow, we multiply the borrow value by the collateral ratio
                (err, localResults.borrowTotalValue) = getPriceForAssetAmount(localResults.assetAddress, localResults.userBorrowCurrent); // ( borrowCurrent* oraclePrice * collateralRatio) = borrowTotalValueInEth
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                // Add this to our running sum of borrows
                (err, localResults.sumBorrows) = addExp(localResults.borrowTotalValue, localResults.sumBorrows);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }
            }
        }
        
        return (Error.NO_ERROR, localResults.sumSupplies.mantissa, localResults.sumBorrows.mantissa);
    }

    /**
      * @notice Gets the ETH values of the user&#39;s accumulated supply and borrow balances, scaled by 10e18.
      *         This includes any accumulated interest thus far but does NOT actually update anything in
      *         storage
      * @dev Gets ETH values of accumulated supply and borrow balances
      * @param userAddress account for which to sum values
      * @return (uint 0=success; otherwise a failure (see ErrorReporter.sol for details),
      *          sum ETH value of supplies scaled by 10e18,
      *          sum ETH value of borrows scaled by 10e18)
      */
    function calculateAccountValues(address userAddress) public view returns (uint, uint, uint) {
        (Error err, uint supplyValue, uint borrowValue) = calculateAccountValuesInternal(userAddress);
        if (err != Error.NO_ERROR) {

            return (uint(err), 0, 0);
        }

        return (0, supplyValue, borrowValue);
    }

    struct PayBorrowLocalVars {
        uint newBorrowIndex;
        uint userBorrowCurrent;
        uint repayAmount;

        uint userBorrowUpdated;
        uint newTotalBorrows;
        uint currentCash;
        uint updatedCash;

        uint newSupplyIndex;
        uint newSupplyRateMantissa;
        uint newBorrowRateMantissa;

        uint startingBalance;
    }

    /**
      * @notice Users repay borrowed assets from their own address to the protocol.
      * @param asset The market asset to repay
      * @param amount The amount to repay (or -1 for max)
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function repayBorrow(address asset, uint amount) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.REPAY_BORROW_CONTRACT_PAUSED);
        }
        PayBorrowLocalVars memory localResults;
        Market storage market = markets[asset];
        Balance storage borrowBalance = borrowBalances[msg.sender][asset];
        Error err;
        uint rateCalculationResultCode;

        // We calculate the newBorrowIndex, user&#39;s borrowCurrent and borrowUpdated for the asset
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, localResults.newBorrowIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

        // If the user specifies -1 amount to repay (“max”), repayAmount =>
        // the lesser of the senders ERC-20 balance and borrowCurrent
        if (amount == uint(-1)) {
            localResults.repayAmount = min(getBalanceOf(asset, msg.sender), localResults.userBorrowCurrent);
        } else {
            localResults.repayAmount = amount;
        }

        // Subtract the `repayAmount` from the `userBorrowCurrent` to get `userBorrowUpdated`
        // Note: this checks that repayAmount is less than borrowCurrent
        (err, localResults.userBorrowUpdated) = sub(localResults.userBorrowCurrent, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

        // Fail gracefully if asset is not approved or has insufficient balance
        // Note: this checks that repayAmount is less than or equal to their ERC-20 balance
        err = checkTransferIn(asset, msg.sender, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE);
        }

        // We calculate the protocol&#39;s totalBorrow by subtracting the user&#39;s prior checkpointed balance, adding user&#39;s updated borrow
        // Note that, even though the customer is paying some of their borrow, if they&#39;ve accumulated a lot of interest since their last
        // action, the updated balance *could* be higher than the prior checkpointed balance.
        (err, localResults.newTotalBorrows) = addThenSub(market.totalBorrows, localResults.userBorrowUpdated, borrowBalance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED);
        }

        // We need to calculate what the updated cash will be after we transfer in from user
        localResults.currentCash = getCash(asset);

        (err, localResults.updatedCash) = add(localResults.currentCash, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED);
        }

        // The utilization rate has changed! We calculate a new supply index and borrow index for the asset, and save it.

        // We calculate the newSupplyIndex, but we have newBorrowIndex already
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.REPAY_BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.REPAY_BORROW_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
        err = doTransferIn(asset, msg.sender, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
            // This is safe since it&#39;s our first interaction and it didn&#39;t do anything if it failed
            return fail(err, FailureInfo.REPAY_BORROW_TRANSFER_IN_FAILED);
        }

        // Save market updates
        market.blockNumber = getBlockNumber();
        market.totalBorrows =  localResults.newTotalBorrows;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

        // Save user updates
        localResults.startingBalance = borrowBalance.principal; // save for use in `BorrowRepaid` event
        borrowBalance.principal = localResults.userBorrowUpdated;
        borrowBalance.interestIndex = localResults.newBorrowIndex;

        emit BorrowRepaid(msg.sender, asset, localResults.repayAmount, localResults.startingBalance, localResults.userBorrowUpdated);

        return uint(Error.NO_ERROR); // success
    }

    struct BorrowLocalVars {
        uint newBorrowIndex;
        uint userBorrowCurrent;
        uint borrowAmountWithFee;

        uint userBorrowUpdated;
        uint newTotalBorrows;
        uint currentCash;
        uint updatedCash;

        uint newSupplyIndex;
        uint newSupplyRateMantissa;
        uint newBorrowRateMantissa;

        uint startingBalance;

        Exp accountLiquidity;
        Exp accountShortfall;
        Exp ethValueOfBorrowAmountWithFee;
    }

    struct LiquidateLocalVars {
        // we need these addresses in the struct for use with `emitLiquidationEvent` to avoid `CompilerError: Stack too deep, try removing local variables.`
        address targetAccount;
        address assetBorrow;
        address liquidator;
        address assetCollateral;

        // borrow index and supply index are global to the asset, not specific to the user
        uint newBorrowIndex_UnderwaterAsset;
        uint newSupplyIndex_UnderwaterAsset;
        uint newBorrowIndex_CollateralAsset;
        uint newSupplyIndex_CollateralAsset;

        // the target borrow&#39;s full balance with accumulated interest
        uint currentBorrowBalance_TargetUnderwaterAsset;
        // currentBorrowBalance_TargetUnderwaterAsset minus whatever gets repaid as part of the liquidation
        uint updatedBorrowBalance_TargetUnderwaterAsset;

        uint newTotalBorrows_ProtocolUnderwaterAsset;

        uint startingBorrowBalance_TargetUnderwaterAsset;
        uint startingSupplyBalance_TargetCollateralAsset;
        uint startingSupplyBalance_LiquidatorCollateralAsset;

        uint currentSupplyBalance_TargetCollateralAsset;
        uint updatedSupplyBalance_TargetCollateralAsset;

        // If liquidator already has a balance of collateralAsset, we will accumulate
        // interest on it before transferring seized collateral from the borrower.
        uint currentSupplyBalance_LiquidatorCollateralAsset;
        // This will be the liquidator&#39;s accumulated balance of collateral asset before the liquidation (if any)
        // plus the amount seized from the borrower.
        uint updatedSupplyBalance_LiquidatorCollateralAsset;

        uint newTotalSupply_ProtocolCollateralAsset;
        uint currentCash_ProtocolUnderwaterAsset;
        uint updatedCash_ProtocolUnderwaterAsset;

        // cash does not change for collateral asset

        uint newSupplyRateMantissa_ProtocolUnderwaterAsset;
        uint newBorrowRateMantissa_ProtocolUnderwaterAsset;

        // Why no variables for the interest rates for the collateral asset?
        // We don&#39;t need to calculate new rates for the collateral asset since neither cash nor borrows change

        uint discountedRepayToEvenAmount;

        //[supplyCurrent / (1 + liquidationDiscount)] * (Oracle price for the collateral / Oracle price for the borrow) (discountedBorrowDenominatedCollateral)
        uint discountedBorrowDenominatedCollateral;

        uint maxCloseableBorrowAmount_TargetUnderwaterAsset;
        uint closeBorrowAmount_TargetUnderwaterAsset;
        uint seizeSupplyAmount_TargetCollateralAsset;

        Exp collateralPrice;
        Exp underwaterAssetPrice;
    }

    /**
      * @notice users repay all or some of an underwater borrow and receive collateral
      * @param targetAccount The account whose borrow should be liquidated
      * @param assetBorrow The market asset to repay
      * @param assetCollateral The borrower&#39;s market asset to receive in exchange
      * @param requestedAmountClose The amount to repay (or -1 for max)
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function liquidateBorrow(address targetAccount, address assetBorrow, address assetCollateral, uint requestedAmountClose) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.LIQUIDATE_CONTRACT_PAUSED);
        }
        LiquidateLocalVars memory localResults;
        // Copy these addresses into the struct for use with `emitLiquidationEvent`
        // We&#39;ll use localResults.liquidator inside this function for clarity vs using msg.sender.
        localResults.targetAccount = targetAccount;
        localResults.assetBorrow = assetBorrow;
        localResults.liquidator = msg.sender;
        localResults.assetCollateral = assetCollateral;

        Market storage borrowMarket = markets[assetBorrow];
        Market storage collateralMarket = markets[assetCollateral];
        Balance storage borrowBalance_TargeUnderwaterAsset = borrowBalances[targetAccount][assetBorrow];
        Balance storage supplyBalance_TargetCollateralAsset = supplyBalances[targetAccount][assetCollateral];

        // Liquidator might already hold some of the collateral asset
        Balance storage supplyBalance_LiquidatorCollateralAsset = supplyBalances[localResults.liquidator][assetCollateral];

        uint rateCalculationResultCode; // Used for multiple interest rate calculation calls
        Error err; // re-used for all intermediate errors

        (err, localResults.collateralPrice) = fetchAssetPrice(assetCollateral);
        if(err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_FETCH_ASSET_PRICE_FAILED);
        }

        (err, localResults.underwaterAssetPrice) = fetchAssetPrice(assetBorrow);
        // If the price oracle is not set, then we would have failed on the first call to fetchAssetPrice
        assert(err == Error.NO_ERROR);

        // We calculate newBorrowIndex_UnderwaterAsset and then use it to help calculate currentBorrowBalance_TargetUnderwaterAsset
        (err, localResults.newBorrowIndex_UnderwaterAsset) = calculateInterestIndex(borrowMarket.borrowIndex, borrowMarket.borrowRateMantissa, borrowMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_BORROWED_ASSET);
        }

        (err, localResults.currentBorrowBalance_TargetUnderwaterAsset) = calculateBalance(borrowBalance_TargeUnderwaterAsset.principal, borrowBalance_TargeUnderwaterAsset.interestIndex, localResults.newBorrowIndex_UnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_ACCUMULATED_BORROW_BALANCE_CALCULATION_FAILED);
        }

        // We calculate newSupplyIndex_CollateralAsset and then use it to help calculate currentSupplyBalance_TargetCollateralAsset
        (err, localResults.newSupplyIndex_CollateralAsset) = calculateInterestIndex(collateralMarket.supplyIndex, collateralMarket.supplyRateMantissa, collateralMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET);
        }

        (err, localResults.currentSupplyBalance_TargetCollateralAsset) = calculateBalance(supplyBalance_TargetCollateralAsset.principal, supplyBalance_TargetCollateralAsset.interestIndex, localResults.newSupplyIndex_CollateralAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET);
        }

        // Liquidator may or may not already have some collateral asset.
        // If they do, we need to accumulate interest on it before adding the seized collateral to it.
        // We re-use newSupplyIndex_CollateralAsset calculated above to help calculate currentSupplyBalance_LiquidatorCollateralAsset
        (err, localResults.currentSupplyBalance_LiquidatorCollateralAsset) = calculateBalance(supplyBalance_LiquidatorCollateralAsset.principal, supplyBalance_LiquidatorCollateralAsset.interestIndex, localResults.newSupplyIndex_CollateralAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET);
        }

        // We update the protocol&#39;s totalSupply for assetCollateral in 2 steps, first by adding target user&#39;s accumulated
        // interest and then by adding the liquidator&#39;s accumulated interest.

        // Step 1 of 2: We add the target user&#39;s supplyCurrent and subtract their checkpointedBalance
        // (which has the desired effect of adding accrued interest from the target user)
        (err, localResults.newTotalSupply_ProtocolCollateralAsset) = addThenSub(collateralMarket.totalSupply, localResults.currentSupplyBalance_TargetCollateralAsset, supplyBalance_TargetCollateralAsset.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET);
        }

        // Step 2 of 2: We add the liquidator&#39;s supplyCurrent of collateral asset and subtract their checkpointedBalance
        // (which has the desired effect of adding accrued interest from the calling user)
        (err, localResults.newTotalSupply_ProtocolCollateralAsset) = addThenSub(localResults.newTotalSupply_ProtocolCollateralAsset, localResults.currentSupplyBalance_LiquidatorCollateralAsset, supplyBalance_LiquidatorCollateralAsset.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET);
        }

        // We calculate maxCloseableBorrowAmount_TargetUnderwaterAsset, the amount of borrow that can be closed from the target user
        // This is equal to the lesser of
        // 1. borrowCurrent; (already calculated)
        // 2. ONLY IF MARKET SUPPORTED: discountedRepayToEvenAmount:
        // discountedRepayToEvenAmount=
        //      shortfall / [Oracle price for the borrow * (collateralRatio - liquidationDiscount - 1)]
        // 3. discountedBorrowDenominatedCollateral
        //      [supplyCurrent / (1 + liquidationDiscount)] * (Oracle price for the collateral / Oracle price for the borrow)

        // Here we calculate item 3. discountedBorrowDenominatedCollateral =
        // [supplyCurrent / (1 + liquidationDiscount)] * (Oracle price for the collateral / Oracle price for the borrow)
        (err, localResults.discountedBorrowDenominatedCollateral) =
        calculateDiscountedBorrowDenominatedCollateral(localResults.underwaterAssetPrice, localResults.collateralPrice, localResults.currentSupplyBalance_TargetCollateralAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_BORROW_DENOMINATED_COLLATERAL_CALCULATION_FAILED);
        }

        if (borrowMarket.isSupported) {
            // Market is supported, so we calculate item 2 from above.
            (err, localResults.discountedRepayToEvenAmount) =
            calculateDiscountedRepayToEvenAmount(targetAccount, localResults.underwaterAssetPrice);
            if (err != Error.NO_ERROR) {
                return fail(err, FailureInfo.LIQUIDATE_DISCOUNTED_REPAY_TO_EVEN_AMOUNT_CALCULATION_FAILED);
            }

            // We need to do a two-step min to select from all 3 values
            // min1&3 = min(item 1, item 3)
            localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset = min(localResults.currentBorrowBalance_TargetUnderwaterAsset, localResults.discountedBorrowDenominatedCollateral);

            // min1&3&2 = min(min1&3, 2)
            localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset = min(localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset, localResults.discountedRepayToEvenAmount);
        } else {
            // Market is not supported, so we don&#39;t need to calculate item 2.
            localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset = min(localResults.currentBorrowBalance_TargetUnderwaterAsset, localResults.discountedBorrowDenominatedCollateral);
        }

        // If liquidateBorrowAmount = -1, then closeBorrowAmount_TargetUnderwaterAsset = maxCloseableBorrowAmount_TargetUnderwaterAsset
        if (requestedAmountClose == uint(-1)) {
            localResults.closeBorrowAmount_TargetUnderwaterAsset = localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset;
        } else {
            localResults.closeBorrowAmount_TargetUnderwaterAsset = requestedAmountClose;
        }

        // From here on, no more use of `requestedAmountClose`

        // Verify closeBorrowAmount_TargetUnderwaterAsset <= maxCloseableBorrowAmount_TargetUnderwaterAsset
        if (localResults.closeBorrowAmount_TargetUnderwaterAsset > localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset) {
            return fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_TOO_HIGH);
        }

        // seizeSupplyAmount_TargetCollateralAsset = closeBorrowAmount_TargetUnderwaterAsset * priceBorrow/priceCollateral *(1+liquidationDiscount)
        (err, localResults.seizeSupplyAmount_TargetCollateralAsset) = calculateAmountSeize(localResults.underwaterAssetPrice, localResults.collateralPrice, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_AMOUNT_SEIZE_CALCULATION_FAILED);
        }

        // We are going to ERC-20 transfer closeBorrowAmount_TargetUnderwaterAsset of assetBorrow into Compound
        // Fail gracefully if asset is not approved or has insufficient balance
        err = checkTransferIn(assetBorrow, localResults.liquidator, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_TRANSFER_IN_NOT_POSSIBLE);
        }

        // We are going to repay the target user&#39;s borrow using the calling user&#39;s funds
        // We update the protocol&#39;s totalBorrow for assetBorrow, by subtracting the target user&#39;s prior checkpointed balance,
        // adding borrowCurrent, and subtracting closeBorrowAmount_TargetUnderwaterAsset.

        // Subtract the `closeBorrowAmount_TargetUnderwaterAsset` from the `currentBorrowBalance_TargetUnderwaterAsset` to get `updatedBorrowBalance_TargetUnderwaterAsset`
        (err, localResults.updatedBorrowBalance_TargetUnderwaterAsset) = sub(localResults.currentBorrowBalance_TargetUnderwaterAsset, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        // We have ensured above that localResults.closeBorrowAmount_TargetUnderwaterAsset <= localResults.currentBorrowBalance_TargetUnderwaterAsset, so the sub can&#39;t underflow
        assert(err == Error.NO_ERROR);

        // We calculate the protocol&#39;s totalBorrow for assetBorrow by subtracting the user&#39;s prior checkpointed balance, adding user&#39;s updated borrow
        // Note that, even though the liquidator is paying some of the borrow, if the borrow has accumulated a lot of interest since the last
        // action, the updated balance *could* be higher than the prior checkpointed balance.
        (err, localResults.newTotalBorrows_ProtocolUnderwaterAsset) = addThenSub(borrowMarket.totalBorrows, localResults.updatedBorrowBalance_TargetUnderwaterAsset, borrowBalance_TargeUnderwaterAsset.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_BORROW_CALCULATION_FAILED_BORROWED_ASSET);
        }

        // We need to calculate what the updated cash will be after we transfer in from liquidator
        localResults.currentCash_ProtocolUnderwaterAsset = getCash(assetBorrow);
        (err, localResults.updatedCash_ProtocolUnderwaterAsset) = add(localResults.currentCash_ProtocolUnderwaterAsset, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_CASH_CALCULATION_FAILED_BORROWED_ASSET);
        }

        // The utilization rate has changed! We calculate a new supply index, borrow index, supply rate, and borrow rate for assetBorrow
        // (Please note that we don&#39;t need to do the same thing for assetCollateral because neither cash nor borrows of assetCollateral happen in this process.)

        // We calculate the newSupplyIndex_UnderwaterAsset, but we already have newBorrowIndex_UnderwaterAsset so don&#39;t recalculate it.
        (err, localResults.newSupplyIndex_UnderwaterAsset) = calculateInterestIndex(borrowMarket.supplyIndex, borrowMarket.supplyRateMantissa, borrowMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_BORROWED_ASSET);
        }

        (rateCalculationResultCode, localResults.newSupplyRateMantissa_ProtocolUnderwaterAsset) = borrowMarket.interestRateModel.getSupplyRate(assetBorrow, localResults.updatedCash_ProtocolUnderwaterAsset, localResults.newTotalBorrows_ProtocolUnderwaterAsset);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.LIQUIDATE_NEW_SUPPLY_RATE_CALCULATION_FAILED_BORROWED_ASSET, rateCalculationResultCode);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa_ProtocolUnderwaterAsset) = borrowMarket.interestRateModel.getBorrowRate(assetBorrow, localResults.updatedCash_ProtocolUnderwaterAsset, localResults.newTotalBorrows_ProtocolUnderwaterAsset);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.LIQUIDATE_NEW_BORROW_RATE_CALCULATION_FAILED_BORROWED_ASSET, rateCalculationResultCode);
        }

        // Now we look at collateral. We calculated target user&#39;s accumulated supply balance and the supply index above.
        // Now we need to calculate the borrow index.
        // We don&#39;t need to calculate new rates for the collateral asset because we have not changed utilization:
        //  - accumulating interest on the target user&#39;s collateral does not change cash or borrows
        //  - transferring seized amount of collateral internally from the target user to the liquidator does not change cash or borrows.
        (err, localResults.newBorrowIndex_CollateralAsset) = calculateInterestIndex(collateralMarket.borrowIndex, collateralMarket.borrowRateMantissa, collateralMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET);
        }

        // We checkpoint the target user&#39;s assetCollateral supply balance, supplyCurrent - seizeSupplyAmount_TargetCollateralAsset at the updated index
        (err, localResults.updatedSupplyBalance_TargetCollateralAsset) = sub(localResults.currentSupplyBalance_TargetCollateralAsset, localResults.seizeSupplyAmount_TargetCollateralAsset);
        // The sub won&#39;t underflow because because seizeSupplyAmount_TargetCollateralAsset <= target user&#39;s collateral balance
        // maxCloseableBorrowAmount_TargetUnderwaterAsset is limited by the discounted borrow denominated collateral. That limits closeBorrowAmount_TargetUnderwaterAsset
        // which in turn limits seizeSupplyAmount_TargetCollateralAsset.
        assert (err == Error.NO_ERROR);

        // We checkpoint the liquidating user&#39;s assetCollateral supply balance, supplyCurrent + seizeSupplyAmount_TargetCollateralAsset at the updated index
        (err, localResults.updatedSupplyBalance_LiquidatorCollateralAsset) = add(localResults.currentSupplyBalance_LiquidatorCollateralAsset, localResults.seizeSupplyAmount_TargetCollateralAsset);
        // We can&#39;t overflow here because if this would overflow, then we would have already overflowed above and failed
        // with LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET
        assert (err == Error.NO_ERROR);

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
        err = doTransferIn(assetBorrow, localResults.liquidator, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            // This is safe since it&#39;s our first interaction and it didn&#39;t do anything if it failed
            return fail(err, FailureInfo.LIQUIDATE_TRANSFER_IN_FAILED);
        }

        // Save borrow market updates
        borrowMarket.blockNumber = getBlockNumber();
        borrowMarket.totalBorrows = localResults.newTotalBorrows_ProtocolUnderwaterAsset;
        // borrowMarket.totalSupply does not need to be updated
        borrowMarket.supplyRateMantissa = localResults.newSupplyRateMantissa_ProtocolUnderwaterAsset;
        borrowMarket.supplyIndex = localResults.newSupplyIndex_UnderwaterAsset;
        borrowMarket.borrowRateMantissa = localResults.newBorrowRateMantissa_ProtocolUnderwaterAsset;
        borrowMarket.borrowIndex = localResults.newBorrowIndex_UnderwaterAsset;

        // Save collateral market updates
        // We didn&#39;t calculate new rates for collateralMarket (because neither cash nor borrows changed), just new indexes and total supply.
        collateralMarket.blockNumber = getBlockNumber();
        collateralMarket.totalSupply = localResults.newTotalSupply_ProtocolCollateralAsset;
        collateralMarket.supplyIndex = localResults.newSupplyIndex_CollateralAsset;
        collateralMarket.borrowIndex = localResults.newBorrowIndex_CollateralAsset;

        // Save user updates

        localResults.startingBorrowBalance_TargetUnderwaterAsset = borrowBalance_TargeUnderwaterAsset.principal; // save for use in event
        borrowBalance_TargeUnderwaterAsset.principal = localResults.updatedBorrowBalance_TargetUnderwaterAsset;
        borrowBalance_TargeUnderwaterAsset.interestIndex = localResults.newBorrowIndex_UnderwaterAsset;

        localResults.startingSupplyBalance_TargetCollateralAsset = supplyBalance_TargetCollateralAsset.principal; // save for use in event
        supplyBalance_TargetCollateralAsset.principal = localResults.updatedSupplyBalance_TargetCollateralAsset;
        supplyBalance_TargetCollateralAsset.interestIndex = localResults.newSupplyIndex_CollateralAsset;

        localResults.startingSupplyBalance_LiquidatorCollateralAsset = supplyBalance_LiquidatorCollateralAsset.principal; // save for use in event
        supplyBalance_LiquidatorCollateralAsset.principal = localResults.updatedSupplyBalance_LiquidatorCollateralAsset;
        supplyBalance_LiquidatorCollateralAsset.interestIndex = localResults.newSupplyIndex_CollateralAsset;

        emitLiquidationEvent(localResults);

        return uint(Error.NO_ERROR); // success
    }

    /**
      * @dev this function exists to avoid error `CompilerError: Stack too deep, try removing local variables.` in `liquidateBorrow`
      */
    function emitLiquidationEvent(LiquidateLocalVars memory localResults) internal {
        // event BorrowLiquidated(address targetAccount, address assetBorrow, uint borrowBalanceBefore, uint borrowBalanceAccumulated, uint amountRepaid, uint borrowBalanceAfter,
        // address liquidator, address assetCollateral, uint collateralBalanceBefore, uint collateralBalanceAccumulated, uint amountSeized, uint collateralBalanceAfter);
        emit BorrowLiquidated(localResults.targetAccount,
            localResults.assetBorrow,
            localResults.startingBorrowBalance_TargetUnderwaterAsset,
            localResults.currentBorrowBalance_TargetUnderwaterAsset,
            localResults.closeBorrowAmount_TargetUnderwaterAsset,
            localResults.updatedBorrowBalance_TargetUnderwaterAsset,
            localResults.liquidator,
            localResults.assetCollateral,
            localResults.startingSupplyBalance_TargetCollateralAsset,
            localResults.currentSupplyBalance_TargetCollateralAsset,
            localResults.seizeSupplyAmount_TargetCollateralAsset,
            localResults.updatedSupplyBalance_TargetCollateralAsset);
    }

    /**
      * @dev This should ONLY be called if market is supported. It returns shortfall / [Oracle price for the borrow * (collateralRatio - liquidationDiscount - 1)]
      *      If the market isn&#39;t supported, we support liquidation of asset regardless of shortfall because we want borrows of the unsupported asset to be closed.
      *      Note that if collateralRatio = liquidationDiscount + 1, then the denominator will be zero and the function will fail with DIVISION_BY_ZERO.
      **/
    function calculateDiscountedRepayToEvenAmount(address targetAccount, Exp memory underwaterAssetPrice) internal view returns (Error, uint) {
        Error err;
        Exp memory _accountLiquidity; // unused return value from calculateAccountLiquidity
        Exp memory accountShortfall_TargetUser;
        Exp memory collateralRatioMinusLiquidationDiscount; // collateralRatio - liquidationDiscount
        Exp memory discountedCollateralRatioMinusOne; // collateralRatioMinusLiquidationDiscount - 1, aka collateralRatio - liquidationDiscount - 1
        Exp memory discountedPrice_UnderwaterAsset;
        Exp memory rawResult;

        // we calculate the target user&#39;s shortfall, denominated in Ether, that the user is below the collateral ratio
        (err, _accountLiquidity, accountShortfall_TargetUser) = calculateAccountLiquidity(targetAccount);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, collateralRatioMinusLiquidationDiscount) = subExp(collateralRatio, liquidationDiscount);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, discountedCollateralRatioMinusOne) = subExp(collateralRatioMinusLiquidationDiscount, Exp({mantissa: mantissaOne}));
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, discountedPrice_UnderwaterAsset) = mulExp(underwaterAssetPrice, discountedCollateralRatioMinusOne);
        // calculateAccountLiquidity multiplies underwaterAssetPrice by collateralRatio
        // discountedCollateralRatioMinusOne < collateralRatio
        // so if underwaterAssetPrice * collateralRatio did not overflow then
        // underwaterAssetPrice * discountedCollateralRatioMinusOne can&#39;t overflow either
        assert(err == Error.NO_ERROR);

        (err, rawResult) = divExp(accountShortfall_TargetUser, discountedPrice_UnderwaterAsset);
        // It&#39;s theoretically possible an asset could have such a low price that it truncates to zero when discounted.
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(rawResult));
    }

    /**
      * @dev discountedBorrowDenominatedCollateral = [supplyCurrent / (1 + liquidationDiscount)] * (Oracle price for the collateral / Oracle price for the borrow)
      */
    function calculateDiscountedBorrowDenominatedCollateral(Exp memory underwaterAssetPrice, Exp memory collateralPrice, uint supplyCurrent_TargetCollateralAsset) view internal returns (Error, uint) {
        // To avoid rounding issues, we re-order and group the operations so we do 1 division and only at the end
        // [supplyCurrent * (Oracle price for the collateral)] / [ (1 + liquidationDiscount) * (Oracle price for the borrow) ]
        Error err;
        Exp memory onePlusLiquidationDiscount; // (1 + liquidationDiscount)
        Exp memory supplyCurrentTimesOracleCollateral; // supplyCurrent * Oracle price for the collateral
        Exp memory onePlusLiquidationDiscountTimesOracleBorrow; // (1 + liquidationDiscount) * Oracle price for the borrow
        Exp memory rawResult;

        (err, onePlusLiquidationDiscount) = addExp(Exp({mantissa: mantissaOne}), liquidationDiscount);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, supplyCurrentTimesOracleCollateral) = mulScalar(collateralPrice, supplyCurrent_TargetCollateralAsset);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, onePlusLiquidationDiscountTimesOracleBorrow) = mulExp(onePlusLiquidationDiscount, underwaterAssetPrice);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, rawResult) = divExp(supplyCurrentTimesOracleCollateral, onePlusLiquidationDiscountTimesOracleBorrow);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(rawResult));
    }


    /**
      * @dev returns closeBorrowAmount_TargetUnderwaterAsset * (1+liquidationDiscount) * priceBorrow/priceCollateral
      **/
    function calculateAmountSeize(Exp memory underwaterAssetPrice, Exp memory collateralPrice, uint closeBorrowAmount_TargetUnderwaterAsset) internal view returns (Error, uint) {
        // To avoid rounding issues, we re-order and group the operations to move the division to the end, rather than just taking the ratio of the 2 prices:
        // underwaterAssetPrice * (1+liquidationDiscount) *closeBorrowAmount_TargetUnderwaterAsset) / collateralPrice

        // re-used for all intermediate errors
        Error err;

        // (1+liquidationDiscount)
        Exp memory liquidationMultiplier;

        // assetPrice-of-underwaterAsset * (1+liquidationDiscount)
        Exp memory priceUnderwaterAssetTimesLiquidationMultiplier;

        // priceUnderwaterAssetTimesLiquidationMultiplier * closeBorrowAmount_TargetUnderwaterAsset
        // or, expanded:
        // underwaterAssetPrice * (1+liquidationDiscount) * closeBorrowAmount_TargetUnderwaterAsset
        Exp memory finalNumerator;

        // finalNumerator / priceCollateral
        Exp memory rawResult;

        (err, liquidationMultiplier) = addExp(Exp({mantissa: mantissaOne}), liquidationDiscount);
        // liquidation discount will be enforced < 1, so 1 + liquidationDiscount can&#39;t overflow.
        assert(err == Error.NO_ERROR);

        (err, priceUnderwaterAssetTimesLiquidationMultiplier) = mulExp(underwaterAssetPrice, liquidationMultiplier);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, finalNumerator) = mulScalar(priceUnderwaterAssetTimesLiquidationMultiplier, closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, rawResult) = divExp(finalNumerator, collateralPrice);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(rawResult));
    }


    /**
      * @notice Users borrow assets from the protocol to their own address
      * @param asset The market asset to borrow
      * @param amount The amount to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(address asset, uint amount) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.BORROW_CONTRACT_PAUSED);
        }
        BorrowLocalVars memory localResults;
        Market storage market = markets[asset];
        Balance storage borrowBalance = borrowBalances[msg.sender][asset];

        Error err;
        uint rateCalculationResultCode;

        // Fail if market not supported
        if (!market.isSupported) {
            return fail(Error.MARKET_NOT_SUPPORTED, FailureInfo.BORROW_MARKET_NOT_SUPPORTED);
        }

        // We calculate the newBorrowIndex, user&#39;s borrowCurrent and borrowUpdated for the asset
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, localResults.newBorrowIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

        // Calculate origination fee.
        (err, localResults.borrowAmountWithFee) = calculateBorrowAmountWithFee(amount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_ORIGINATION_FEE_CALCULATION_FAILED);
        }

        // Add the `borrowAmountWithFee` to the `userBorrowCurrent` to get `userBorrowUpdated`
        (err, localResults.userBorrowUpdated) = add(localResults.userBorrowCurrent, localResults.borrowAmountWithFee);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

        // We calculate the protocol&#39;s totalBorrow by subtracting the user&#39;s prior checkpointed balance, adding user&#39;s updated borrow with fee
        (err, localResults.newTotalBorrows) = addThenSub(market.totalBorrows, localResults.userBorrowUpdated, borrowBalance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED);
        }

        // Check customer liquidity
        (err, localResults.accountLiquidity, localResults.accountShortfall) = calculateAccountLiquidity(msg.sender);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED);
        }

        // Fail if customer already has a shortfall
        if (!isZeroExp(localResults.accountShortfall)) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.BORROW_ACCOUNT_SHORTFALL_PRESENT);
        }

        // Would the customer have a shortfall after this borrow (including origination fee)?
        // We calculate the eth-equivalent value of (borrow amount + fee) of asset and fail if it exceeds accountLiquidity.
        // This implements: `[(collateralRatio*oraclea*borrowAmount)*(1+borrowFee)] > accountLiquidity`
        (err, localResults.ethValueOfBorrowAmountWithFee) = getPriceForAssetAmountMulCollatRatio(asset, localResults.borrowAmountWithFee);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_AMOUNT_VALUE_CALCULATION_FAILED);
        }
        if (lessThanExp(localResults.accountLiquidity, localResults.ethValueOfBorrowAmountWithFee)) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.BORROW_AMOUNT_LIQUIDITY_SHORTFALL);
        }

        // Fail gracefully if protocol has insufficient cash
        localResults.currentCash = getCash(asset);
        // We need to calculate what the updated cash will be after we transfer out to the user
        (err, localResults.updatedCash) = sub(localResults.currentCash, amount);
        if (err != Error.NO_ERROR) {
            // Note: we ignore error here and call this token insufficient cash
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED);
        }

        // The utilization rate has changed! We calculate a new supply index and borrow index for the asset, and save it.

        // We calculate the newSupplyIndex, but we have newBorrowIndex already
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.BORROW_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
        err = doTransferOut(asset, msg.sender, amount);
        if (err != Error.NO_ERROR) {
            // This is safe since it&#39;s our first interaction and it didn&#39;t do anything if it failed
            return fail(err, FailureInfo.BORROW_TRANSFER_OUT_FAILED);
        }

        // Save market updates
        market.blockNumber = getBlockNumber();
        market.totalBorrows =  localResults.newTotalBorrows;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

        // Save user updates
        localResults.startingBalance = borrowBalance.principal; // save for use in `BorrowTaken` event
        borrowBalance.principal = localResults.userBorrowUpdated;
        borrowBalance.interestIndex = localResults.newBorrowIndex;

        emit BorrowTaken(msg.sender, asset, amount, localResults.startingBalance, localResults.borrowAmountWithFee, localResults.userBorrowUpdated);

        return uint(Error.NO_ERROR); // success
    }
}