/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-20
*/

// File: contracts\ErrorReporter.sol

pragma solidity ^0.5.16;

contract ErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        REJECTION,
        MATH_ERROR,
        NOT_FRESH,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED,
        INSUFFICIENT_COLLATERAL
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ADMIN_CHECK,
        PARTICIPANT_CHECK,
        ACCRUE_INTEREST_FAILED,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_REJECTION,
        BORROW_INSUFFICIENT_COLLATERAL,
        MINT_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        COLLATERALIZE_REJECTION,
        REDEEM_COLLATERAL_ACCUMULATED_BORROW_CALCULATION_FAILED,
        REDEEM_COLLATERAL_NEW_ACCOUNT_COLLATERAL_CALCULATION_FAILED,
        REDEEM_COLLATERAL_INSUFFICIENT_COLLATERAL,
        LIQUIDATE_BORROW_REJECTION,
        LIQUIDATE_BORROW_COLLATERAL_RATE_CALCULATION_FAILED,
        LIQUIDATE_BORROW_NOT_SATISFIED,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        SET_LIQUIDATE_FACTOR_BOUNDS_CHECK,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

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
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

// File: contracts\EIP20Interface.sol

pragma solidity ^0.5.8;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// File: contracts\EIP20NonStandardInterface.sol

pragma solidity ^0.5.8;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// File: contracts\CarefulMath.sol

// File: contracts/CarefulMath.sol

pragma solidity ^0.5.8;

/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// File: contracts\Exponential.sol

pragma solidity ^0.5.16;


/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

// File: contracts\InterestRateModel.sol

pragma solidity ^0.5.16;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amnount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amnount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

// File: contracts\DFL.sol

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


// forked from Compound/COMP

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract DFL is EIP20Interface, Ownable {
    /// @notice EIP-20 token name for this token
    string public constant name = "DeFIL";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "DFL";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint96 internal _totalSupply;

    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new DFL token
     */
    constructor() public {
        emit Transfer(address(0), address(this), 0);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     * @param account The address of the account holding the new funds
     * @param rawAmount The number of tokens that are minted
     */
    function mint(address account, uint rawAmount) public onlyOwner {
        require(account != address(0), "DFL:: mint: cannot mint to the zero address");
        uint96 amount = safe96(rawAmount, "DFL::mint: amount exceeds 96 bits");
        _totalSupply = add96(_totalSupply, amount, "DFL::mint: total supply exceeds");
        balances[account] = add96(balances[account], amount, "DFL::mint: mint amount exceeds balance");

        _moveDelegates(address(0), delegates[account], amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "DFL::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the total supply of tokens
     * @return The total supply of tokens
     */
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "DFL::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "DFL::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "DFL::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DFL::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "DFL::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "DFL::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "DFL::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "DFL::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "DFL::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "DFL::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "DFL::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "DFL::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "DFL::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "DFL::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// File: contracts\ReentrancyGuard.sol

pragma solidity ^0.5.16;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts\DeFIL.sol

pragma solidity ^0.5.16;

// Forked from Compound/CToken








contract DeFIL is ReentrancyGuard, EIP20Interface, Exponential, ErrorReporter {
    /**
     * @notice EIP-20 token name for this token
     */
    string public constant name = "Certificate of eFIL";
    /**
     * @notice EIP-20 token symbol for this token
     */
    string public constant symbol = "ceFIL";
    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public constant decimals = 18;
    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;
    /**
     * @notice Address of eFIL token
     */
    address public eFILAddress;
    /**
     * @notice Address of mFIL token
     */
    address public mFILAddress;
    /**
     * @notice The address who owns the reserves
     */
    address public reservesOwner;
    /**
     * @notice Administrator for this contract
     */
    address public admin;
    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;
    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;
    /**
     * @notice Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
     */
    uint internal constant initialExchangeRateMantissa = 0.002e18; // 1 eFIL = 500 ceFIL
    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;
    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;
    /**
     * @notice Accumulator of the total earned interest rate since the opening
     */
    uint public borrowIndex;
    /**
     * @notice Total amount of outstanding borrows of the underlying
     */
    uint public totalBorrows;
    /**
     * @notice Total amount of reserves of the underlying held
     */
    uint public totalReserves;
    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    // Is mint allowed.
    bool public mintAllowed;
    // Is borrow allowed.
    bool public borrowAllowed;
    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;
    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }
    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    // Total collaterals
    uint public totalCollaterals;
    // Mapping of account to outstanding collateral balances
    mapping (address => uint) internal accountCollaterals;
    // Multiplier used to decide when liquidate borrow is allowed
    uint public liquidateFactorMantissa;
    // No liquidateFactorMantissa may bellows this value
    uint internal constant liquidateFactorMinMantissa = 1e18; // 100%

    /*** For DFL ***/
    /**
     * @notice Address of DFL token
     */
    DFL public dflToken;
    // By using the special 'min speed=0.00017e18' and 'start speed=86.805721e18'
    // We will got 99999999.8568 DFLs in the end.
    // The havle period in block number
    uint internal constant halvePeriod = 576000; // 100 days
    // Minimum speed
    uint internal constant minSpeed = 0.00017e18; // 1e18 / 5760
    // Current speed (per block)
    uint public currentSpeed = 86.805721e18; // 500000e18 / 5760; // start with 500,000 per day
    // The block number when next havle will happens
    uint public nextHalveBlockNumber;

    // The address of uniswap incentive contract for receiving DFL
    address public uniswapAddress;
    // The address of miner league for receiving DFL
    address public minerLeagueAddress;
    // The address of operator for receiving DFL
    address public operatorAddress;
    // The address of technical support for receiving DFL
    address public technicalAddress;
    // The address for undistributed DFL
    address public undistributedAddress;

    // The percentage of DFL distributes to uniswap incentive
    uint public uniswapPercentage;
    // The percentage of DFL distributes to miner league
    uint public minerLeaguePercentage;
    // The percentage of DFL distributes to operator
    uint public operatorPercentage;
    // The percentage of DFL distributes to technical support, unupdatable
    uint internal constant technicalPercentage = 0.02e18; // 2%

    // The threshold above which the flywheel transfers DFL
    uint internal constant dflClaimThreshold = 0.1e18; // 0.1 DFL
    // Block number that DFL was last accrued at
    uint public dflAccrualBlockNumber;
    // The last updated index of DFL for suppliers
    uint public dflSupplyIndex;
    // The initial dfl supply index
    uint internal constant dflInitialSupplyIndex = 1e36;
    // The index for each supplier as of the last time they accrued DFL
    mapping(address => uint) public dflSupplierIndex;
    // The DFL accrued but not yet transferred to each user
    mapping(address => uint) public dflAccrued;

    /*** Events ***/
    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);
    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);
    /**
     * @notice Event emitted when mFIL are collateralized
     */
    event Collateralize(address collateralizer, uint collateralizeAmount);
    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);
    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);
    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);
    /**
     * @notice Event emitted when collaterals are redeemed
     */
    event RedeemCollateral(address redeemer, uint redeemAmount);
    /**
     * @notice Event emitted when a liquidate borrow is repaid
     */
    event LiquidateBorrow(address liquidator, address borrower, uint accountBorrows, uint accountCollaterals);

    /*** Admin Events ***/
    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);
    /**
     * @notice Event emitted when mintAllowed is changed
     */
    event MintAllowed(bool mintAllowed);
    /**
     * @notice Event emitted when borrowAllowed is changed
     */
    event BorrowAllowed(bool borrowAllowed);
    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);
    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);
    /**
     * @notice Event emitted when the liquidate factor is changed
     */
    event NewLiquidateFactor(uint oldLiquidateFactorMantissa, uint newLiquidateFactorMantissa);
    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);
    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);
    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);

    // Event emitted when reserves owner is changed
    event ReservesOwnerChanged(address oldAddress, address newAddress);
    // Event emitted when uniswap address is changed
    event UniswapAddressChanged(address oldAddress, address newAddress);
    // Event emitted when miner leagure address is changed
    event MinerLeagueAddressChanged(address oldAddress, address newAddress);
    // Event emitted when operator address is changed
    event OperatorAddressChanged(address oldAddress, address newAddress);
    // Event emitted when technical address is changed
    event TechnicalAddressChanged(address oldAddress, address newAddress);
    // Event emitted when undistributed address is changed
    event UndistributedAddressChanged(address oldAddress, address newAddress);
    // Event emitted when reserved is reduced
    event ReservesReduced(address toTho, uint amount);
    // Event emitted when DFL is accrued
    event AccrueDFL(uint uniswapPart, uint minerLeaguePart, uint operatorPart, uint technicalPart, uint supplyPart, uint dflSupplyIndex);
    // Emitted when DFL is distributed to a supplier
    event DistributedDFL(address supplier, uint supplierDelta);
    // Event emitted when DFL percentage is changed
    event PercentagesChanged(uint uniswapPercentage, uint minerLeaguePercentage, uint operatorPercentage);

    /**
     * @notice constructor
     */
    constructor(address interestRateModelAddress,
                address eFILAddress_,
                address mFILAddress_,
                address dflAddress_,
                address reservesOwner_,
                address uniswapAddress_,
                address minerLeagueAddress_,
                address operatorAddress_,
                address technicalAddress_,
                address undistributedAddress_) public {
        // set admin
        admin = msg.sender;

        // Initialize block number and borrow index
        accrualBlockNumber = getBlockNumber();
        borrowIndex = mantissaOne;

        // reserve 50%
        uint err = _setReserveFactorFresh(0.5e18);
        require(err == uint(Error.NO_ERROR), "setting reserve factor failed");

        // set liquidate factor to 200%
        err = _setLiquidateFactorFresh(2e18);
        require(err == uint(Error.NO_ERROR), "setting liquidate factor failed");

        // Set the interest rate model (depends on block number / borrow index)
        err = _setInterestRateModelFresh(InterestRateModel(interestRateModelAddress));
        require(err == uint(Error.NO_ERROR), "setting interest rate model failed");

        // uniswapPercentage = 0.25e18; // 25%
        // minerLeaguePercentage = 0.1e18; // 10%
        // operatorPercentage = 0.03e18; // 3%
        err = _setDFLPercentagesFresh(0.25e18, 0.1e18, 0.03e18);
        require(err == uint(Error.NO_ERROR), "setting DFL percentages failed");

        // allow mint/borrow
        mintAllowed = true;
        borrowAllowed = true;

        // token addresses & tokens
        eFILAddress = eFILAddress_;
        mFILAddress = mFILAddress_;
        dflToken = DFL(dflAddress_);
        // set owner of reserves
        reservesOwner = reservesOwner_;

        // DFL
        dflAccrualBlockNumber = getBlockNumber();
        dflSupplyIndex = dflInitialSupplyIndex;
        nextHalveBlockNumber = dflAccrualBlockNumber + halvePeriod;

        // DFL addresses
        uniswapAddress = uniswapAddress_;
        minerLeagueAddress = minerLeagueAddress_;
        operatorAddress = operatorAddress_;
        technicalAddress = technicalAddress_;
        undistributedAddress = undistributedAddress_;

        emit Transfer(address(0), address(this), 0);
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
        /* Do not allow self-transfers */
        if (src == dst || dst == address(0)) {
            return fail(Error.BAD_INPUT, FailureInfo.TRANSFER_NOT_ALLOWED);
        }

        // Keep the flywheel moving
        accrueDFL();
        distributeSupplierDFL(src, false);
        distributeSupplierDFL(dst, false);

        /* Get the allowance, infinite for the account owner */
        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = uint(-1);
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /* Do the calculations, checking for {under,over}flow */
        MathError mathErr;
        uint allowanceNew;
        uint srcTokensNew;
        uint dstTokensNew;

        (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ALLOWED);
        }

        (mathErr, srcTokensNew) = subUInt(accountTokens[src], tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ENOUGH);
        }

        (mathErr, dstTokensNew) = addUInt(accountTokens[dst], tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_TOO_MUCH);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != uint(-1)) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);
        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "cannot approve to the zero address");
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256) {
        return accountTokens[owner];
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint) {
        Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
        (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, accountTokens[owner]);
        require(mErr == MathError.NO_ERROR, "balance could not be calculated");
        return balance;
    }

    /**
     * @notice Get the collateral of the `account`
     * @param account The address of the account to query
     * @return The number of collaterals owned by `account`
     */
    function getCollateral(address account) external view returns (uint256) {
        return accountCollaterals[account];
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * @notice Returns the current per-block borrow interest rate
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
    }

    /**
     * @notice Returns the current per-block supply interest rate
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint) {
        return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return borrowBalanceStored(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view returns (uint) {
        (MathError err, uint result) = borrowBalanceStoredInternal(account);
        require(err == MathError.NO_ERROR, "borrowBalanceStored: borrowBalanceStoredInternal failed");
        return result;
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address account) internal view returns (MathError, uint) {
        /* Note: we do not assert that is up to date */
        MathError mathErr;
        uint principalTimesIndex;
        uint result;

        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * global.borrowIndex / borrower.borrowIndex
         */
        (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        return (MathError.NO_ERROR, result);
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return exchangeRateStored();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the ceFIL
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view returns (uint) {
        (MathError err, uint result) = exchangeRateStoredInternal();
        require(err == MathError.NO_ERROR, "exchangeRateStored: exchangeRateStoredInternal failed");
        return result;
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the ceFIL
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return (error code, calculated exchange rate scaled by 1e18)
     */
    function exchangeRateStoredInternal() internal view returns (MathError, uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return (MathError.NO_ERROR, initialExchangeRateMantissa);
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            uint totalCash = getCashPrior();
            uint cashPlusBorrowsMinusReserves;
            Exp memory exchangeRate;
            MathError mathErr;

            (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            return (MathError.NO_ERROR, exchangeRate.mantissa);
        }
    }

    /**
     * @notice Accrue interest then return the up-to-date collateral rate
     * @return Calculated collateral rate scaled by 1e18
     */
    function collateralRateCurrent(address borrower) external returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return collateralRateStored(borrower);
    }

    /**
     * @notice Calculates the collateral rate of borrower from stored states
     * @dev This function does not accrue interest before calculating the collateral rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function collateralRateStored(address borrower) public view returns (uint) {
        (MathError err, uint rate, ,) = collateralRateInternal(borrower);
        require(err == MathError.NO_ERROR, "collateralRateStored: collateralRateInternal failed");
        return rate;
    }

    function collateralRateInternal(address borrower) internal view returns (MathError, uint, uint, uint) {
        MathError mathErr;
        uint _accountBorrows;
        uint _accountCollaterals;
        Exp memory collateralRate;

        (mathErr, _accountBorrows) = borrowBalanceStoredInternal(borrower);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0, 0, 0);
        }

        _accountCollaterals = accountCollaterals[borrower];
        (mathErr, collateralRate) = getExp(_accountBorrows, _accountCollaterals);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0, 0, 0);
        }

        return (MathError.NO_ERROR, collateralRate.mantissa, _accountBorrows, _accountCollaterals);
    }

    // Accrue DFL then return the up-to-date accrued amount
    function accruedDFLCurrent(address supplier) external nonReentrant returns (uint) {
        accrueDFL();
        return accruedDFLStoredInternal(supplier);
    }

    // Accrue DFL then return the up-to-date accrued amount
    function accruedDFLStored(address supplier) public view returns (uint) {
        return accruedDFLStoredInternal(supplier);
    }

    // Return the accrued DFL of account based on stored data
    function accruedDFLStoredInternal(address supplier) internal view returns(uint) {
        Double memory supplyIndex = Double({mantissa: dflSupplyIndex});
        Double memory supplierIndex = Double({mantissa: dflSupplierIndex[supplier]});
        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = dflInitialSupplyIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierDelta = mul_(accountTokens[supplier], deltaIndex);
        uint supplierAccrued = add_(dflAccrued[supplier], supplierDelta);
        return supplierAccrued;
    }

    /**
     * @notice Get cash balance of this in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint) {
        return getCashPrior();
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() public returns (uint) {
        /* Remember the initial block number */
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return uint(Error.NO_ERROR);
        }

        /* Read the previous values out of storage */
        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);

        /* Calculate the number of blocks elapsed since the last accrual */
        (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
        require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: borrowRateMantissa}), blockDelta);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint(mathErr));
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        /* We emit an AccrueInterest event */
        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender supplies assets into and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return fail(Error(err), FailureInfo.ACCRUE_INTEREST_FAILED);
        }

        // Keep the flywheel moving
        accrueDFL();
        distributeSupplierDFL(msg.sender, false);

        // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        (err,) = mintFresh(msg.sender, mintAmount);
        return err;
    }

    struct MintLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint mintTokens;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint actualMintAmount;
    }

    /**
     * @notice User supplies assets into and receives cTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param minter The address of the account which is supplying the assets
     * @param mintAmount The amount of the underlying asset to supply
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
     */
    function mintFresh(address minter, uint mintAmount) internal returns (uint, uint) {
        if (!mintAllowed || accountCollaterals[minter] != 0) {
            return (fail(Error.REJECTION, FailureInfo.MINT_REJECTION), 0);
        }

        MintLocalVars memory vars;

        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.MINT_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr)), 0);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        vars.actualMintAmount = doTransferIn(eFILAddress, minter, mintAmount);

        /*
         * We get the current exchange rate and calculate the number of cTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */

        (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa: vars.exchangeRateMantissa}));
        require(vars.mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED");

        /*
         * We calculate the new total supply of cTokens and minter token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[minter] + mintTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");

        (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[minter], vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[minter] = vars.accountTokensNew;

        /* We emit a Mint event, and a Transfer event */
        emit Mint(minter, vars.actualMintAmount, vars.mintTokens);
        emit Transfer(address(this), minter, vars.mintTokens);

        return (uint(Error.NO_ERROR), vars.actualMintAmount);
    }

    /**
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param collateralizeAmount The amount of the underlying asset to collateralize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function collateralize(uint collateralizeAmount) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return fail(Error(err), FailureInfo.ACCRUE_INTEREST_FAILED);
        }

        // Keep the flywheel moving
        accrueDFL();

        (err,) = collateralizeFresh(msg.sender, collateralizeAmount);
        return err;
    }

    struct CollateralizeLocalVars {
        Error err;
        MathError mathErr;
        uint totalCollateralsNew;
        uint accountCollateralsNew;
        uint actualCollateralizeAmount;
    }

    /**
     * @param collateralizer The address of the account which is supplying the assets
     * @param collateralizeAmount The amount of the underlying asset to supply
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual collateralize amount.
     */
    function collateralizeFresh(address collateralizer, uint collateralizeAmount) internal returns (uint, uint) {
        if (accountTokens[collateralizer] != 0) {
            return (fail(Error.REJECTION, FailureInfo.COLLATERALIZE_REJECTION), 0);
        }

        CollateralizeLocalVars memory vars;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        vars.actualCollateralizeAmount = doTransferIn(mFILAddress, collateralizer, collateralizeAmount);

        (vars.mathErr, vars.totalCollateralsNew) = addUInt(totalCollaterals, vars.actualCollateralizeAmount);
        require(vars.mathErr == MathError.NO_ERROR, "COLLATERALIZE_NEW_TOTAL_COLLATERALS_CALCULATION_FAILED");

        (vars.mathErr, vars.accountCollateralsNew) = addUInt(accountCollaterals[collateralizer], vars.actualCollateralizeAmount);
        require(vars.mathErr == MathError.NO_ERROR, "COLLATERALIZE_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");

        /* We write previously calculated values into storage */
        totalCollaterals = vars.totalCollateralsNew;
        accountCollaterals[collateralizer] = vars.accountCollateralsNew;

        /* We emit a Collateralize event, and a Transfer event */
        emit Collateralize(collateralizer, vars.actualCollateralizeAmount);
        return (uint(Error.NO_ERROR), vars.actualCollateralizeAmount);
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
            return fail(Error(err), FailureInfo.ACCRUE_INTEREST_FAILED);
        }

        // Keep the flywheel moving
        accrueDFL();
        distributeSupplierDFL(msg.sender, false);

        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        return redeemFresh(msg.sender, redeemTokens, 0);
    }

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
            return fail(Error(err), FailureInfo.ACCRUE_INTEREST_FAILED);
        }
        // Keep the flywheel moving
        accrueDFL();
        distributeSupplierDFL(msg.sender, false);

        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        return redeemFresh(msg.sender, 0, redeemAmount);
    }

    struct RedeemLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint redeemTokens;
        uint redeemAmount;
        uint totalSupplyNew;
        uint accountTokensNew;
    }

    /**
     * @notice User redeems cTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemFresh(address redeemer, uint redeemTokensIn, uint redeemAmountIn) internal returns (uint) {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        RedeemLocalVars memory vars;

        /* exchangeRate = invoke Exchange Rate Stored() */
        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr));
        }

        /* If redeemTokensIn > 0: */
        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             *  redeemAmount = redeemTokensIn x exchangeRateCurrent
             */
            vars.redeemTokens = redeemTokensIn;

            (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), redeemTokensIn);
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint(vars.mathErr));
            }
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             *  redeemAmount = redeemAmountIn
             */

            (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint(vars.mathErr));
            }

            vars.redeemAmount = redeemAmountIn;
        }

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  totalSupplyNew = totalSupply - redeemTokens
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint(vars.mathErr));
        }

        (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        /* Fail gracefully if protocol has insufficient cash */
        if (getCashPrior() < vars.redeemAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        doTransferOut(eFILAddress, redeemer, vars.redeemAmount);

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[redeemer] = vars.accountTokensNew;

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), vars.redeemTokens);
        emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);
        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return fail(Error(err), FailureInfo.ACCRUE_INTEREST_FAILED);
        }
        // Keep the flywheel moving
        accrueDFL();

        // borrowFresh emits borrow-specific logs on errors, so we don't need to
        return borrowFresh(msg.sender, borrowAmount);
    }

    struct BorrowLocalVars {
        MathError mathErr;
        uint actualBorrowAmount;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
    }

    /**
      * @notice Users borrow assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrowFresh(address borrower, uint borrowAmount) internal returns (uint) {
        if (!borrowAllowed) {
            return fail(Error.REJECTION, FailureInfo.BORROW_REJECTION);
        }

        BorrowLocalVars memory vars;

        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        if (borrowAmount == uint(-1)) {
            vars.actualBorrowAmount = accountCollaterals[borrower] > vars.accountBorrows ? accountCollaterals[borrower] - vars.accountBorrows : 0;
        } else {
            vars.actualBorrowAmount = borrowAmount;
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        if (getCashPrior() < vars.actualBorrowAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_CASH_NOT_AVAILABLE);
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + actualBorrowAmount
         *  totalBorrowsNew = totalBorrows + actualBorrowAmount
         */
        (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, vars.actualBorrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        // Check collaterals
        if (accountCollaterals[borrower] < vars.accountBorrowsNew) {
            return fail(Error.INSUFFICIENT_COLLATERAL, FailureInfo.BORROW_INSUFFICIENT_COLLATERAL);
        }

        (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows, vars.actualBorrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        doTransferOut(eFILAddress, borrower, vars.actualBorrowAmount);

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a Borrow event */
        emit Borrow(borrower, vars.actualBorrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);
        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint repayAmount) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return fail(Error(err), FailureInfo.ACCRUE_INTEREST_FAILED);
        }
        // Keep the flywheel moving
        accrueDFL();

        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        (err,) = repayBorrowFresh(msg.sender, msg.sender, repayAmount);
        return err;
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return fail(Error(err), FailureInfo.ACCRUE_INTEREST_FAILED);
        }
        // Keep the flywheel moving
        accrueDFL();

        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        (err,) = repayBorrowFresh(msg.sender, borrower, repayAmount);
        return err;
    }

    struct RepayBorrowLocalVars {
        Error err;
        MathError mathErr;
        uint repayAmount;
        uint borrowerIndex;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
        uint actualRepayAmount;
    }

    /**
     * @notice Borrows are repaid by another user (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of undelrying tokens being returned
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint, uint) {
        RepayBorrowLocalVars memory vars;

        /* We remember the original borrowerIndex for verification purposes */
        vars.borrowerIndex = accountBorrows[borrower].interestIndex;

        /* We fetch the amount the borrower owes, with accumulated interest */
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /* If repayAmount == -1, repayAmount = accountBorrows */
        if (repayAmount == uint(-1)) {
            vars.repayAmount = vars.accountBorrows;
        } else {
            vars.repayAmount = repayAmount;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        vars.actualRepayAmount = doTransferIn(eFILAddress, payer, vars.repayAmount);

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.actualRepayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED");

        (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, vars.actualRepayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED");

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a RepayBorrow event */
        emit RepayBorrow(payer, borrower, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);
        return (uint(Error.NO_ERROR), vars.actualRepayAmount);
    }

    /**
     * redeem collaterals
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The number of collateral to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemCollateral(uint redeemAmount) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
            return fail(Error(err), FailureInfo.ACCRUE_INTEREST_FAILED);
        }
        // Keep the flywheel moving
        accrueDFL();

        // redeemCollateralFresh emits redeem-collaterals-specific logs on errors, so we don't need to
        return redeemCollateralFresh(msg.sender, redeemAmount);
    }

    struct RedeemCollateralLocalVars {
        Error err;
        MathError mathErr;
        uint redeemAmount;
        uint accountBorrows;
        uint accountCollateralsOld;
        uint accountCollateralsNew;
        uint totalCollateralsNew;
    }

    /**
     * redeem collaterals
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming
     * @param redeemAmount The number of collaterals to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemCollateralFresh(address redeemer, uint redeemAmount) internal returns (uint) {
        RedeemCollateralLocalVars memory vars;

        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(redeemer);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_COLLATERAL_ACCUMULATED_BORROW_CALCULATION_FAILED, uint(vars.mathErr));
        }

        vars.accountCollateralsOld = accountCollaterals[redeemer];
        if (redeemAmount == uint(-1)) {
            vars.redeemAmount = vars.accountCollateralsOld >= vars.accountBorrows ? vars.accountCollateralsOld - vars.accountBorrows : 0;
        } else {
            vars.redeemAmount = redeemAmount;
        }

        (vars.mathErr, vars.accountCollateralsNew) = subUInt(accountCollaterals[redeemer], vars.redeemAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_COLLATERAL_NEW_ACCOUNT_COLLATERAL_CALCULATION_FAILED, uint(vars.mathErr));
        }

        // Check collateral
        if (vars.accountCollateralsNew < vars.accountBorrows) {
            return fail(Error.INSUFFICIENT_COLLATERAL, FailureInfo.REDEEM_COLLATERAL_INSUFFICIENT_COLLATERAL);
        }

        (vars.mathErr, vars.totalCollateralsNew) = subUInt(totalCollaterals, vars.redeemAmount);
        require(vars.mathErr == MathError.NO_ERROR, "REDEEM_COLLATERALS_NEW_TOTAL_COLLATERALS_CALCULATION_FAILED");

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        doTransferOut(mFILAddress, redeemer, vars.redeemAmount);

        /* We write previously calculated values into storage */
        totalCollaterals = vars.totalCollateralsNew;
        accountCollaterals[redeemer] = vars.accountCollateralsNew;

        /* We emit a RedeemCollateral event */
        emit RedeemCollateral(redeemer, vars.redeemAmount);
        return uint(Error.NO_ERROR);
    }

    /**
     * liquidate borrow
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param borrower The borrower's address
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrow(address borrower) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        if (err != uint(Error.NO_ERROR)) {
            return fail(Error(err), FailureInfo.ACCRUE_INTEREST_FAILED);
        }
        // Keep the flywheel moving
        accrueDFL();

        return liquidateBorrowFresh(msg.sender, borrower);
    }

    struct LiquidateBorrowLocalVars {
        Error err;
        MathError mathErr;
        uint accountBorrows;
        uint accountCollaterals;
        uint collateralRate;
        uint totalBorrowsNew;
    }

    /**
     * liquidate borrow
     * @dev Assumes interest has already been accrued up to the current block
     * @param liquidator The liquidator's address
     * @param borrower The borrower's address
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrowFresh(address liquidator, address borrower) internal returns (uint) {
        // make things simple
        if (accountCollaterals[liquidator] != 0 || accountTokens[liquidator] != 0) {
            return fail(Error.REJECTION, FailureInfo.LIQUIDATE_BORROW_REJECTION);
        }

        LiquidateBorrowLocalVars memory vars;

        (vars.mathErr, vars.collateralRate, vars.accountBorrows, vars.accountCollaterals) = collateralRateInternal(borrower);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_BORROW_COLLATERAL_RATE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        if (vars.collateralRate < liquidateFactorMantissa) {
            return fail(Error.REJECTION, FailureInfo.LIQUIDATE_BORROW_NOT_SATISFIED);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        require(doTransferIn(eFILAddress, liquidator, vars.accountBorrows) == vars.accountBorrows, "LIQUIDATE_BORROW_TRANSFER_IN_FAILED");

        (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, vars.accountBorrows);
        require(vars.mathErr == MathError.NO_ERROR, "LIQUIDATE_BORROW_NEW_TOTAL_BORROWS_CALCULATION_FAILED");

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = 0;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        accountCollaterals[borrower] = 0;
        accountCollaterals[liquidator] = vars.accountCollaterals;

        /* We emit a RepayBorrow event */
        emit LiquidateBorrow(liquidator, borrower, vars.accountBorrows, vars.accountCollaterals);
        return uint(Error.NO_ERROR);
    }

    /*** DFL ***/

    // accrue DFL
    function accrueDFL() internal {
        uint startBlockNumber = dflAccrualBlockNumber;
        uint endBlockNumber = startBlockNumber;
        uint currentBlockNumber = getBlockNumber();
        while (endBlockNumber < currentBlockNumber) {
            if (currentSpeed < minSpeed) {
                break;
            }

            startBlockNumber = endBlockNumber;
            if (currentBlockNumber < nextHalveBlockNumber) {
                endBlockNumber = currentBlockNumber;
            } else {
                endBlockNumber = nextHalveBlockNumber;
            }

            distributeAndUpdateSupplyIndex(startBlockNumber, endBlockNumber);

            if (endBlockNumber == nextHalveBlockNumber) {
                nextHalveBlockNumber = nextHalveBlockNumber + halvePeriod;
                currentSpeed = currentSpeed / 2;
            }
        }
        // update dflAccrualBlockNumber
        dflAccrualBlockNumber = currentBlockNumber;
    }

    // Accrue DFL for suppliers by updating the supply index
    function distributeAndUpdateSupplyIndex(uint startBlockNumber, uint endBlockNumber) internal {
        uint deltaBlocks = sub_(endBlockNumber, startBlockNumber);
        if (deltaBlocks > 0) {
            uint deltaDFLs = mul_(deltaBlocks, currentSpeed);
            dflToken.mint(address(this), deltaDFLs);

            uint uniswapPart = div_(mul_(uniswapPercentage, deltaDFLs), mantissaOne);
            uint minerLeaguePart = div_(mul_(minerLeaguePercentage, deltaDFLs), mantissaOne);
            uint operatorPart = div_(mul_(operatorPercentage, deltaDFLs), mantissaOne);
            uint technicalPart = div_(mul_(technicalPercentage, deltaDFLs), mantissaOne);
            uint supplyPart = sub_(sub_(sub_(sub_(deltaDFLs, uniswapPart), minerLeaguePart), operatorPart), technicalPart);

            // accrue, not transfer directly
            dflAccrued[uniswapAddress] = add_(dflAccrued[uniswapAddress], uniswapPart);
            dflAccrued[minerLeagueAddress] = add_(dflAccrued[minerLeagueAddress], minerLeaguePart);
            dflAccrued[operatorAddress] = add_(dflAccrued[operatorAddress], operatorPart);
            dflAccrued[technicalAddress] = add_(dflAccrued[technicalAddress], technicalPart);

            if (totalSupply > 0) {
                Double memory ratio = fraction(supplyPart, totalSupply);
                Double memory index = add_(Double({mantissa: dflSupplyIndex}), ratio);
                dflSupplyIndex = index.mantissa;
            } else {
                dflAccrued[undistributedAddress] = add_(dflAccrued[undistributedAddress], supplyPart);
            }

            emit AccrueDFL(uniswapPart, minerLeaguePart, operatorPart, technicalPart, supplyPart, dflSupplyIndex);
        }
    }

    // Calculate DFL accrued by a supplier and possibly transfer it to them
    function distributeSupplierDFL(address supplier, bool distributeAll) internal {
        /* Verify accrued block number equals current block number */
        require(dflAccrualBlockNumber == getBlockNumber(), "FRESHNESS_CHECK");
        uint supplierAccrued = accruedDFLStoredInternal(supplier);

        dflAccrued[supplier] = transferDFL(supplier, supplierAccrued, distributeAll ? 0 : dflClaimThreshold);
        dflSupplierIndex[supplier] = dflSupplyIndex;
        emit DistributedDFL(supplier, supplierAccrued - dflAccrued[supplier]);
    }

    // Transfer DFL to the user, if they are above the threshold
    function transferDFL(address user, uint userAccrued, uint threshold) internal returns (uint) {
        if (userAccrued >= threshold && userAccrued > 0) {
            uint dflRemaining = dflToken.balanceOf(address(this));
            if (userAccrued <= dflRemaining) {
                dflToken.transfer(user, userAccrued);
                return 0;
            }
        }
        return userAccrued;
    }

    function claimDFL() public nonReentrant {
        accrueDFL();
        distributeSupplierDFL(msg.sender, true);
    }

    // Claim all DFL accrued by the suppliers
    function claimDFL(address[] memory holders) public nonReentrant {
        accrueDFL();
        for (uint i = 0; i < holders.length; i++) {
            distributeSupplierDFL(holders[i], true);
        }
    }

    // Reduce reserves, only by staking contract
    function claimReserves() public nonReentrant {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");

        uint cash = getCashPrior();
        uint actualAmount = cash > totalReserves ? totalReserves : cash;

        doTransferOut(eFILAddress, reservesOwner, actualAmount);
        totalReserves = sub_(totalReserves, actualAmount);

        emit ReservesReduced(reservesOwner, actualAmount);
    }

    /*** Admin Functions ***/

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address newPendingAdmin) external returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() external returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
      * @dev Change mintAllowed
      * @param mintAllowed_ New value.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setMintAllowed(bool mintAllowed_) external returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        if (mintAllowed != mintAllowed_) {
            mintAllowed = mintAllowed_;
            emit MintAllowed(mintAllowed_);
        }

        return uint(Error.NO_ERROR);
    }

    /**
      * @dev Change borrowAllowed
      * @param borrowAllowed_ New value.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setBorrowAllowed(bool borrowAllowed_) external returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        if (borrowAllowed != borrowAllowed_) {
            borrowAllowed = borrowAllowed_;
            emit BorrowAllowed(borrowAllowed_);
        }

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
      * @dev Admin function to accrue interest and set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactor(uint newReserveFactorMantissa) external nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reserve factor change failed.
            return fail(Error(error), FailureInfo.ACCRUE_INTEREST_FAILED);
        }
        // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    /**
      * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
      * @dev Admin function to set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactorFresh(uint newReserveFactorMantissa) internal returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        // Check newReserveFactor ≤ maxReserveFactor
        if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
            return fail(Error.BAD_INPUT, FailureInfo.SET_RESERVE_FACTOR_BOUNDS_CHECK);
        }

        uint oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;

        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice accrues interest and sets a new liquidate factor for the protocol using _setLiquidateFactorFresh
      * @dev Admin function to accrue interest and set a new liquidate factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setLiquidateFactor(uint newLiquidateFactorMantissa) external nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted liquidate factor change failed.
            return fail(Error(error), FailureInfo.ACCRUE_INTEREST_FAILED);
        }
        return _setLiquidateFactorFresh(newLiquidateFactorMantissa);
    }

    function _setLiquidateFactorFresh(uint newLiquidateFactorMantissa) internal returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        if (newLiquidateFactorMantissa < liquidateFactorMinMantissa) {
            return fail(Error.BAD_INPUT, FailureInfo.SET_LIQUIDATE_FACTOR_BOUNDS_CHECK);
        }

        uint oldLiquidateFactorMantissa = liquidateFactorMantissa;
        liquidateFactorMantissa = newLiquidateFactorMantissa;

        emit NewLiquidateFactor(oldLiquidateFactorMantissa, newLiquidateFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted change of interest rate model failed
            return fail(Error(error), FailureInfo.ACCRUE_INTEREST_FAILED);
        }
        // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint) {
        // Used to store old model for use in the event that is emitted on success
        InterestRateModel oldInterestRateModel;

        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        // Track the current interest rate model
        oldInterestRateModel = interestRateModel;

        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        // Set the interest rate model to newInterestRateModel
        interestRateModel = newInterestRateModel;

        // Emit NewInterestRateModel(oldInterestRateModel, newInterestRateModel)
        emit NewInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return uint(Error.NO_ERROR);
    }

    /**
      * @dev Change reservesOwner
      * @param newReservesOwner New value.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReservesOwner(address newReservesOwner) public returns (uint) {
        claimReserves();
        return _setReservesOwnerFresh(newReservesOwner);
    }

    function _setReservesOwnerFresh(address newReservesOwner) internal returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        address oldReservesOwner = reservesOwner;
        reservesOwner = newReservesOwner;

        emit ReservesOwnerChanged(oldReservesOwner, newReservesOwner);
        return uint(Error.NO_ERROR);
    }

    /**
      * @dev Change minerLeagueAddress
      * @param newMinerLeagueAddress New value.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setMinerLeagueAddress(address newMinerLeagueAddress) external nonReentrant returns (uint) {
        // accrue
        accrueDFL();
        return _setMinerLeagueAddressFresh(newMinerLeagueAddress);
    }

    function _setMinerLeagueAddressFresh(address newMinerLeagueAddress) internal returns (uint) {
        if (msg.sender != minerLeagueAddress) {
            return fail(Error.UNAUTHORIZED, FailureInfo.PARTICIPANT_CHECK);
        }

        // transfers accrued
        if (dflAccrued[minerLeagueAddress] != 0) {
            doTransferOut(address(dflToken), minerLeagueAddress, dflAccrued[minerLeagueAddress]);
            delete dflAccrued[minerLeagueAddress];
        }

        address oldMinerLeagueAddress = minerLeagueAddress;
        minerLeagueAddress = newMinerLeagueAddress;

        emit MinerLeagueAddressChanged(oldMinerLeagueAddress, newMinerLeagueAddress);
        return uint(Error.NO_ERROR);
    }

    /**
      * @dev Change operatorAddress
      * @param newOperatorAddress New value.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setOperatorAddress(address newOperatorAddress) external nonReentrant returns (uint) {
        // accrue
        accrueDFL();
        return _setOperatorAddressFresh(newOperatorAddress);
    }

    function _setOperatorAddressFresh(address newOperatorAddress) internal returns (uint) {
        if (msg.sender != operatorAddress) {
            return fail(Error.UNAUTHORIZED, FailureInfo.PARTICIPANT_CHECK);
        }

        // transfers accrued
        if (dflAccrued[operatorAddress] != 0) {
            doTransferOut(address(dflToken), operatorAddress, dflAccrued[operatorAddress]);
            delete dflAccrued[operatorAddress];
        }

        address oldOperatorAddress = operatorAddress;
        operatorAddress = newOperatorAddress;

        emit OperatorAddressChanged(oldOperatorAddress, newOperatorAddress);
        return uint(Error.NO_ERROR);
    }

    /**
      * @dev Change technicalAddress
      * @param newTechnicalAddress New value.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setTechnicalAddress(address newTechnicalAddress) external nonReentrant returns (uint) {
        // accrue
        accrueDFL();
        return _setTechnicalAddressFresh(newTechnicalAddress);
    }

    function _setTechnicalAddressFresh(address newTechnicalAddress) internal returns (uint) {
        if (msg.sender != technicalAddress) {
            return fail(Error.UNAUTHORIZED, FailureInfo.PARTICIPANT_CHECK);
        }

        // transfers accrued
        if (dflAccrued[technicalAddress] != 0) {
            doTransferOut(address(dflToken), technicalAddress, dflAccrued[technicalAddress]);
            delete dflAccrued[technicalAddress];
        }

        address oldTechnicalAddress = technicalAddress;
        technicalAddress = newTechnicalAddress;

        emit TechnicalAddressChanged(oldTechnicalAddress, newTechnicalAddress);
        return uint(Error.NO_ERROR);
    }

    /**
      * @dev Change uniswapAddress
      * @param newUniswapAddress New value.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setUniswapAddress(address newUniswapAddress) external nonReentrant returns (uint) {
        // accrue
        accrueDFL();
        return _setUniswapAddressFresh(newUniswapAddress);
    }

    function _setUniswapAddressFresh(address newUniswapAddress) internal returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        // transfers accrued
        if (dflAccrued[uniswapAddress] != 0) {
            doTransferOut(address(dflToken), uniswapAddress, dflAccrued[uniswapAddress]);
            delete dflAccrued[uniswapAddress];
        }

        address oldUniswapAddress = uniswapAddress;
        uniswapAddress = newUniswapAddress;

        emit UniswapAddressChanged(oldUniswapAddress, newUniswapAddress);
        return uint(Error.NO_ERROR);
    }

    /**
      * @dev Change undistributedAddress
      * @param newUndistributedAddress New value.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setUndistributedAddress(address newUndistributedAddress) external nonReentrant returns (uint) {
        // accrue
        accrueDFL();
        return _setUndistributedAddressFresh(newUndistributedAddress);
    }

    function _setUndistributedAddressFresh(address newUndistributedAddress) internal returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        // transfers accrued to old address
        if (dflAccrued[undistributedAddress] != 0) {
            doTransferOut(address(dflToken), undistributedAddress, dflAccrued[undistributedAddress]);
            delete dflAccrued[undistributedAddress];
        }

        address oldUndistributedAddress = undistributedAddress;
        undistributedAddress = newUndistributedAddress;

        emit UndistributedAddressChanged(oldUndistributedAddress, newUndistributedAddress);
        return uint(Error.NO_ERROR);
    }

    /**
      * @dev Change DFL percentages
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setDFLPercentages(uint uniswapPercentage_,
                                uint minerLeaguePercentage_,
                                uint operatorPercentage_) external nonReentrant returns (uint) {
        accrueDFL();
        return _setDFLPercentagesFresh(uniswapPercentage_, minerLeaguePercentage_, operatorPercentage_);
    }

    function _setDFLPercentagesFresh(uint uniswapPercentage_,
                                     uint minerLeaguePercentage_,
                                     uint operatorPercentage_) internal returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADMIN_CHECK);
        }

        uint sumPercentage = add_(add_(add_(uniswapPercentage_, minerLeaguePercentage_), operatorPercentage_), technicalPercentage);
        require(sumPercentage <= mantissaOne, "PERCENTAGE_EXCEEDS");

        uniswapPercentage = uniswapPercentage_;
        minerLeaguePercentage = minerLeaguePercentage_;
        operatorPercentage = operatorPercentage_;

        emit PercentagesChanged(uniswapPercentage_, minerLeaguePercentage_, operatorPercentage_);
        return uint(Error.NO_ERROR);
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view returns (uint) {
        EIP20Interface token = EIP20Interface(eFILAddress);
        return token.balanceOf(address(this));
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address underlying, address from, uint amount) internal returns (uint) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        uint balanceBefore = EIP20Interface(underlying).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = EIP20Interface(underlying).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address underlying, address to, uint amount) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}