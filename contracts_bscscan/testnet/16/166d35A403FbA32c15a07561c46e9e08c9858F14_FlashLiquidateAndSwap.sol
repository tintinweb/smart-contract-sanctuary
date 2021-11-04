pragma solidity ^0.5.16;

import "./PancakeInterfaces.sol";

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ComptrollerInterface {
    function markets(address) external view returns (bool, uint);
}

interface CErc20Interface  {
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
}

contract CTokenInterface {

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) public view returns (uint);
    function exchangeRateCurrent() public returns (uint);
    function exchangeRateStored() public view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() public returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
}

interface PriceOracleInterface {

    function getUnderlyingPrice(CTokenInterface cToken) external view returns (uint);
}

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

contract Operable is Ownable {

    event OperatorChanged(address indexed newAddress);

    address public operator;

    /**
     * @dev throws if called by any account other than the operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Operable: caller is not the operator");
        _;
    }

    /**
     * @dev update the operator role
     */
    function updateOperator(address _newOperator) external onlyOwner {
        require(
            _newOperator != address(0),
            "Operable: new operator is the zero address"
        );
        operator = _newOperator;
        emit OperatorChanged(operator);
    }
}

contract FlashLiquidateInterface  {

    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY,
        APPROVE_ERROR,
        LIQUIDATE_ERROR,
        REDEEM_ERROR
    }

    /*** User Interface ***/

    function liquidate(address borrower) external returns (uint);


    /*** Admin Functions ***/

    function setOracleAddr(address _newOracleAddr) external;
}

contract FlashLiquidateAndSwap is Exponential,FlashLiquidateInterface,Ownable,Operable {

    address public unitrollerAddr=0xF2fA277094fD84172738B16Dc470d620C4080c49;
    address public eFilAddr=0xb0e4857E0c8753849a0E527D2Da5e6A304699730;
    address public eUSDTAddr=0x301F357106131252e7FEB0EbC3C9fcd32eC575b8;
    address public constant filAddr=0xbfF22bB7f275715703E29fF60CD035203A79E61d;
    address public constant usdtAddr=0x922F531c9BDfbe3CE176FCBa91ACCdFE0D33b89e;
    address public oracleAddr=0xB5935145a91EA5330E03CE0F7B7c1Df4fb54715F;
    uint public flCloseFactor=0.6e18;
    uint public collateralFactorMantissa=0.6e18;

    /// @notice Logs the address of the sender and amounts paid to the contract
    event Paid(address indexed _from, uint _value);
    event Withdraw(address indexed sender, uint amount);
    event WithdrawToken(address indexed tokenAddr,address indexed sender, uint amount);
    event StartLiquidate(uint filAmount,uint filMulColAmount,uint usdtAmount,uint contractUsdtBalance,uint maxClose,uint userCanRedeemCount);
    event GetSupplyInfo(uint filCount,uint filBalance,uint filMulColBalance);
    event GetBorrowInfo(uint usdtCount,uint usdtBalance);

    IPancakeRouter02 private constant pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    uint256 MAX_INT = uint256(-1);

    constructor(address _newOperator) public {
        IERC20(filAddr).approve(address(pancakeRouter), MAX_INT);
        require(
            _newOperator != address(0),
            "FlashLiquidateAndSwap: new operator is the zero address"
        );
        operator = _newOperator;
        emit OperatorChanged(operator);
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details) Checks-Effects-Interaction
     */
    function liquidate(address borrower) public onlyOperator returns (uint) {
        uint err=_liquidateBorrowInternal(borrower);
        return err;
    }

    function _liquidateBorrowInternal(address borrower) internal onlyOperator returns (uint) {
        (uint err,uint filAmount,uint filMulColAmount,uint usdtAmount,uint contractUsdtBalance,uint maxClose)=_getAccountInfo(borrower);

        if (err != 0) {
            return err;
        }

        if (contractUsdtBalance>maxClose){

            //判断是否有坏账 判断抵押品最大可清算金额
            (MathError err1, uint mulMantissa) =mulUInt(filAmount,100);
            if (err1 != MathError.NO_ERROR) {
                return (uint(Error.MATH_ERROR));
            }
            (MathError err2, uint userCanRedeemCount) =divUInt(mulMantissa,108);
            if (err2 != MathError.NO_ERROR) {
                return (uint(Error.MATH_ERROR));
            }

            // fil 借款限额；usdt 债务；清算合约usdt余额；清算债务最大还款金额
            emit StartLiquidate(filAmount,filMulColAmount,usdtAmount,contractUsdtBalance,maxClose,userCanRedeemCount);
            if(userCanRedeemCount>usdtAmount){
                //不是坏账
                _liquidateBorrowFresh(borrower,maxClose);
            }else{
                //坏账
                _liquidateBorrowFresh(borrower,userCanRedeemCount);
            }
        }
        return uint(Error.NO_ERROR);
    }

    function _liquidateBorrowFresh(address borrower,uint maxClose) internal onlyOperator returns (uint) {
        //合约通过usdt代币合约授权给eUSDT合约指定金额
        bool isApprove=CTokenInterface(usdtAddr).approve(eUSDTAddr,maxClose);
        if (!isApprove) {
            return uint(Error.APPROVE_ERROR);
        }

        uint liquidateErr=CErc20Interface(eUSDTAddr).liquidateBorrow(borrower,maxClose,CTokenInterface(eFilAddr));
        if (liquidateErr!=0){
            return uint(Error.LIQUIDATE_ERROR);
        }

        // 获取合约中efil的数量
        uint efilTokens = CTokenInterface(eFilAddr).balanceOf(address(this));
        // 将efil赎回成fil
        uint redeemErr=_redeem(efilTokens);
        if (redeemErr!=0){
            return redeemErr;
        }
        _swap();

        return (uint(Error.NO_ERROR));
    }

    /**
     * @notice 获取账户相关信息
     * @param borrower The borrower of this cToken to be liquidated
     * @return (uint,uint,uint,uint) result code：错误码,filBalance fil数量x单价,filMulColBalance 可抵押价值,usdtBalance：usdt数量x价格,contractUsdtBalance：该合约中的usdt数量,maxClose：最大清算要花费的usdt数量
     */
    function _getAccountInfo(address borrower) internal returns (uint,uint,uint,uint,uint,uint) {

        //先获取存款信息
        (uint _getSupplyInfoErr,uint filCount,uint filBalance,uint filMulColBalance)=_getSupplyInfo(borrower);
        //再获取借款信息
        (uint _getBorrowInfoErr,uint usdtCount,uint usdtBalance)=_getBorrowInfo(borrower);

        MathError mErr;
        uint contractUsdtBalance;
        uint maxClose;

        //如果借款限额<债务，执行清算
        if (filMulColBalance<usdtBalance){
            (mErr, maxClose) = mulScalarTruncate(Exp({mantissa: flCloseFactor}), usdtCount);
            if (mErr != MathError.NO_ERROR) {
                return (uint(Error.MATH_ERROR), filBalance,filMulColBalance, usdtBalance, 0, 0);
            }

            //当前合约账户的usdt数量
            contractUsdtBalance = CTokenInterface(usdtAddr).balanceOf(address(this));
            //如果合约余额>最大清算还款金额，执行清算

        }

        return (uint(Error.NO_ERROR),filBalance,filMulColBalance,usdtBalance,contractUsdtBalance,maxClose);
    }

    /**
     * @notice 获取抵押物相关信息
     * @param borrower The borrower of this cToken to be liquidated
     * @return (uint,uint,uint,uint) result code;filCount;filBalance;filMulColBalance
     */
    function _getSupplyInfo(address borrower)  internal returns (uint,uint,uint,uint) {
        (uint usdtPrice,uint filPrice)=_getPriceInfo();

        //当前抵押品fil的数量
        uint filCount = CTokenInterface(eFilAddr).balanceOfUnderlying(borrower);

        MathError mErr;
        Exp memory filAmount;
        Exp memory filMulColAmount;

        (mErr,filAmount)=mulExp3(Exp({mantissa: filCount}),Exp({mantissa: filPrice}),Exp({mantissa: expScale}));
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0, 0, 0);
        }

        (mErr,filMulColAmount)=mulExp(Exp({mantissa: filAmount.mantissa}),Exp({mantissa: collateralFactorMantissa}));
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), filAmount.mantissa,0, 0);
        }
        emit GetSupplyInfo(filCount,filAmount.mantissa,filMulColAmount.mantissa);
        return (uint(Error.NO_ERROR),filCount,filAmount.mantissa,filMulColAmount.mantissa);
    }

    /**
     * @notice 获取债务相关信息：债务总额 usdt数量 usdt价值（数量x价格）
     * @param borrower The borrower of this cToken to be liquidated
     * @return (uint,uint,uint) result code;usdtBorrowCount;usdtBorrowBalance
     */
    function _getBorrowInfo(address borrower)  internal returns (uint,uint,uint) {

        MathError mErr;
        Exp memory usdtAmount;

        //当前价格
        (uint usdtPrice,uint filPrice)=_getPriceInfo();
        //当前借款usdt的数量
        uint usdtBorrowCount = CTokenInterface(eUSDTAddr).borrowBalanceCurrent(borrower);
        //usdt价值
        (mErr,usdtAmount)=mulExp3(Exp({mantissa: usdtBorrowCount}),Exp({mantissa: usdtPrice}),Exp({mantissa: expScale}));
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0, 0);
        }

        emit GetBorrowInfo(usdtBorrowCount,usdtAmount.mantissa);

        return (uint(Error.NO_ERROR), usdtBorrowCount,usdtAmount.mantissa);
    }

    function _getPriceInfo()  internal returns (uint,uint) {
        uint usdtPrice=PriceOracleInterface(oracleAddr).getUnderlyingPrice(CTokenInterface(eUSDTAddr));
        uint filPrice=PriceOracleInterface(oracleAddr).getUnderlyingPrice(CTokenInterface(eFilAddr));
        return (usdtPrice,filPrice);
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _redeem(uint redeemTokens) internal onlyOperator returns (uint) {
        uint err=CErc20Interface(eFilAddr).redeem(redeemTokens);
        if (err!=0){
            return uint(Error.REDEEM_ERROR);
        }
        //获取赎回后的fil数量
        uint filCount = CTokenInterface(filAddr).balanceOf(address(this));
        return uint(Error.NO_ERROR);
    }

    function _swap() internal onlyOperator {
        uint256 deadline = block.timestamp + 300;
        uint256 amountOutMinPancakeSwap = 1;

        _tradeOnPancake(IERC20(filAddr).balanceOf(address(this)), amountOutMinPancakeSwap, deadline);
    }

    function _tradeOnPancake(uint256 amountIn, uint256 amountOutMin, uint256 deadline) private onlyOperator {
        address recipient = address(this);

        pancakeRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            _getPathForPancakeSwap(),
            recipient,
            deadline
        );
    }

    function _getPathForPancakeSwap() private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = filAddr;
        path[1] = usdtAddr;

        return path;
    }

    function setOracleAddr(address _newOracleAddr) public onlyOwner {
        oracleAddr=_newOracleAddr;
    }

    function doTransferOut(address payable to, uint amount) onlyOwner external {
        require(address(this).balance > 0, "Value should not be zero");
        /* Send the Ether, with minimal gas and revert on failure */
        to.transfer(amount);
        emit Withdraw(to,amount);
    }

    function doTransferTokenOut(address tokenAddr,address payable to) onlyOwner external {
        IERC20 token = IERC20(tokenAddr);
        uint amount = token.balanceOf(address(this));
        require(amount > 0, "Value should not be zero");

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
        emit WithdrawToken(tokenAddr, to,amount);
    }

    // Fallback function is called when msg.data is not empty
    function() external payable{
        emit Paid(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

pragma solidity ^0.5.16;

interface IPancakeRouter02 {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}