/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin\contracts\access\Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: contracts\interfaces\WarpVaultSCI.sol

pragma solidity ^0.6.0;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title WarpVaultSCI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The WarpVaultSCI contract an abstract contract the WarpControl contract uses to interface
    with a WarpVaultSC contract.
**/

abstract contract WarpVaultSCI {
    uint256 public totalReserves;

    function borrowBalanceCurrent(address account)
        public
        virtual
        returns (uint256);

    function borrowBalancePrior(address account)
        public
        virtual
        view
        returns (uint256);

    function exchangeRateCurrent() public virtual returns (uint256);

    function _borrow(uint256 _borrowAmount, address _borrower) external virtual;

    function _repayLiquidatedLoan(
        address _borrower,
        address _liquidator,
        uint256 _amount
    ) public virtual;

    function setNewInterestModel(address _newModel) public virtual;

    function getSCDecimals() public virtual view returns (uint8);

    function getSCAddress() public virtual view returns (address);

    function updateWarpControl(address _warpControl) public virtual;

    function updateTeam(address _warpTeam) public virtual;

    function viewAccountBalance(address _account)
        public
        virtual
        view
        returns (uint256);
}

// File: contracts\interfaces\WarpVaultLPI.sol

pragma solidity ^0.6.0;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title WarpVaultLPI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The WarpVaultLPI contract an abstract contract the WarpControl contract uses to interface
    with a WarpVaultLP contract.
**/

abstract contract WarpVaultLPI {
    function getAssetAdd() public virtual view returns (address);

    function collateralOfAccount(address _account)
        public
        virtual
        view
        returns (uint256);

    function _liquidateAccount(address _account, address _liquidator)
        public
        virtual;

    function updateWarpControl(address _warpControl) public virtual;
}

// File: contracts\interfaces\WarpVaultLPFactoryI.sol

pragma solidity ^0.6.0;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title WarpVaultLPFactoryI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The WarpVaultLPFactory contract is designed to produce individual WarpVaultLP contracts
**/

abstract contract WarpVaultLPFactoryI {
    function createWarpVaultLP(
        uint256 _timelock,
        address _lp
    ) public virtual returns (address);
}

// File: contracts\interfaces\WarpVaultSCFactoryI.sol

pragma solidity ^0.6.0;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title WarpVaultSCFactoryI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The WarpVaultSCFactoryI contract is used by the Warp Control contract to interface with the WarpVaultSCFactory contract
**/

abstract contract WarpVaultSCFactoryI {
    function createNewWarpVaultSC(
        address _InterestRate,
        address _StableCoin,
        address _warpTeam,
        uint256 _initialExchangeRate,
        uint256 _timelock,
        uint256 _reserveFactorMantissa
    ) public virtual returns (address);
}

// File: contracts\interfaces\SwapLPOracleI.sol

pragma solidity ^0.6.0;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title SwapLPOracleI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The SwapLPOracleI contract an abstract contract the Warp platform uses to interface
    With the SwapOracle to retrieve token prices.
**/

abstract contract SwapLPOracleI {
    function addChainlinkETHOracle(
                                   address oracle, address token
    ) public virtual;

    function OneUSDC() public virtual view returns (uint256);
    function OneWETH() public virtual view returns (uint256);

    function getUnderlyingPrice(address _MMI) public virtual returns (uint256);

    function getPriceOfToken(address _token, uint256 _amount)
        public
        virtual
        returns (uint256);

    function transferOwnership(address _newOwner) public virtual;

    function _calculatePriceOfLP(
        uint256 supply,
        uint256 value0,
        uint256 value1,
        uint256 reserve0,
        uint256 reserve1
    ) public virtual pure returns (uint256);
}

// File: @openzeppelin\contracts\math\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: contracts\compound\BaseJumpRateModelV2.sol

pragma solidity ^0.6.0;


/**
 * @title Logic for Compound's JumpRateModel Contract V2.
 * @author Compound (modified by Dharma Labs, refactored by Arr00)
 * @notice Version 2 modifies Version 1 by enabling updateable parameters.
 */
contract BaseJumpRateModelV2 {
    using SafeMath for uint256;

    event NewInterestParams(
        uint256 baseRatePerBlock,
        uint256 multiplierPerBlock,
        uint256 jumpMultiplierPerBlock,
        uint256 kink
    );

    /**
     * @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
     */
    address public owner;

    /**
     * @notice The approximate number of blocks per year that is assumed by the interest rate model
     */
    uint256 public constant blocksPerYear = 2102400;

    /**
     * @notice The multiplier of utilization rate that gives the slope of the interest rate
     */
    uint256 public multiplierPerBlock;

    /**
     * @notice The base interest rate which is the y-intercept when utilization rate is 0
     */
    uint256 public baseRatePerBlock;

    /**
     * @notice The multiplierPerBlock after hitting a specified utilization point
     */
    uint256 public jumpMultiplierPerBlock;

    /**
     * @notice The utilization point at which the jump multiplier is applied
     */
    uint256 public kink;

    /**
     * @notice Construct an interest rate model
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
     * @param kink_ The utilization point at which the jump multiplier is applied
     * @param owner_ The address of the owner, i.e. the Timelock contract (which has the ability to update parameters directly)
     */
    constructor(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_,
        address owner_
    ) internal {
        owner = owner_;

        updateJumpRateModelInternal(
            baseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            kink_
        );
    }

    /**
     * @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
     * @param kink_ The utilization point at which the jump multiplier is applied
     */
    function updateJumpRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    ) external {
        require(msg.sender == owner, "only the owner may call this function.");

        updateJumpRateModelInternal(
            baseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            kink_
        );
    }

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market (currently unused)
     * @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public pure returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    /**
     * @notice Calculates the current borrow rate per block, with the error code expected by the market
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getBorrowRateInternal(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) internal view returns (uint256) {
        uint256 util = utilizationRate(cash, borrows, reserves);

        if (util <= kink) {
            return util.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
        } else {
            uint256 normalRate =
                kink.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
            uint256 excessUtil = util.sub(kink);
            return
                excessUtil.mul(jumpMultiplierPerBlock).div(1e18).add(
                    normalRate
                );
        }
    }

    /**
     * @notice Calculates the current supply rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @param reserveFactorMantissa The current reserve factor for the market
     * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) public view returns (uint256) {
        uint256 oneMinusReserveFactor =
            uint256(1e18).sub(reserveFactorMantissa);
        uint256 borrowRate = getBorrowRateInternal(cash, borrows, reserves);
        uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return
            utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }

    /**
     * @notice Internal function to update the parameters of the interest rate model
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
     * @param kink_ The utilization point at which the jump multiplier is applied
     */
    function updateJumpRateModelInternal(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    ) internal {
        baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
        multiplierPerBlock = (multiplierPerYear.mul(1e18)).div(
            blocksPerYear.mul(kink_)
        );
        jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);
        kink = kink_;

        emit NewInterestParams(
            baseRatePerBlock,
            multiplierPerBlock,
            jumpMultiplierPerBlock,
            kink
        );
    }
}

// File: contracts\compound\JumpRateModelV2.sol

pragma solidity ^0.6.0;




/**
  * @title Compound's JumpRateModel Contract V2 for V2 cTokens
  * @author Arr00
  * @notice Supports only for V2 cTokens
  */
contract JumpRateModelV2 is  BaseJumpRateModelV2  {

	/**
     * @notice Calculates the current borrow rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external  view returns (uint) {
        return getBorrowRateInternal(cash, borrows, reserves);
    }

    constructor(uint baseRatePerYear, uint multiplierPerYear, uint jumpMultiplierPerYear, uint kink_, address owner_)
    	BaseJumpRateModelV2(baseRatePerYear,multiplierPerYear,jumpMultiplierPerYear,kink_,owner_) public {}
}

// File: contracts\compound\CarefulMath.sol

pragma solidity ^0.6.0;

/**
  * @title Careful Math
  * @author Compound

/blob/master/contracts/math/SafeMath.sol
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

// File: contracts\compound\Exponential.sol

pragma solidity ^0.6.0;


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

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts\WarpControl.sol

pragma solidity ^0.6.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";









////////////////////////////////////////////////////////////////////////////////////////////
/// @title WarpControl
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
WarpControl is designed to coordinate Warp Vaults
This contract uses the OpenZeppelin contract Library to inherit functions from
  Ownable.sol
**/

contract WarpControl is Ownable, Exponential {
    using SafeMath for uint256;

    SwapLPOracleI public oracle; //oracle contract 
    WarpVaultLPFactoryI public WVLPF;
    WarpVaultSCFactoryI public WVSCF;

    address public warpTeam;
    address public newWarpControl;
    uint256 public graceSpace;

    address[] public lpVaults;
    address[] public scVaults;

    mapping(address => address) public instanceLPTracker; //maps LP token address to the assets WarpVault
    mapping(address => address) public instanceSCTracker;
    mapping(address => address) public getAssetByVault;
    mapping(address => bool) public isVault;

    uint256 public borrowLimitPercentage = 66 ether;  // max percentage of collateral value allowed to borrow, with 18 decimals
    uint256 public liquidateLimitPercentage = 75 ether; // max percentage of collateral value before liquidation can occur
    uint256 public liquidationFee = 15 ether; // percentage of LP tokens to give to warp team upon liquidation

    event LogEvent2(uint256 lnum);
    event NewLPVault(address _newVault);
    event ImportedLPVault(address _vault);
    event NewSCVault(address _newVault, address _interestRateModel);
    event ImportedSCVault(address _vault);
    event NewBorrow(
        address _borrower,
        address _StableCoin,
        uint256 _amountBorrowed
    );
    event Liquidation(address _account, address liquidator);
    event NewInterestRateModelCreated(
      address _token,
      uint256 _baseRatePerYear,
      uint256 _multiplierPerYear,
      uint256 _jumpMultiplierPerYear,
      uint256 _optimal
    );

    /**
      @dev Throws if called by any account other than a warp vault
     */
    modifier onlyVault() {
        require(isVault[msg.sender] == true, "Only a vault may call this");
        _;
    }

    /**
    @notice the constructor function is fired during the contract deployment process. The constructor can only be fired once and
            is used to set up OracleFactory variables for the MoneyMarketFactory contract.
    @param _oracle is the address for the UniswapOracleFactorycontract
    @param _WVLPF is the address for the WarpVaultLPFactory used to produce LP Warp Vaults
    @param _WVSCF is the address for the WarpVaultSCFactory used to produce Stable Coin Warp Vaults
    @dev These factories are split into seperate contracts to avoid hitting the block gas limit
    **/
    constructor(
        address _oracle,
        address _WVLPF,
        address _WVSCF,
        address _warpTeam
    ) public {
        //instantiate the contracts
        oracle = SwapLPOracleI(_oracle);
        WVLPF = WarpVaultLPFactoryI(_WVLPF);
        WVSCF = WarpVaultSCFactoryI(_WVSCF);
        warpTeam = _warpTeam;
    }

    /**
    @notice viewNumLPVaults returns the number of lp vaults on the warp platform
    **/
    function viewNumLPVaults() external view returns (uint256) {
        return lpVaults.length;
    }

    /**
    @notice viewNumSCVaults returns the number of stablecoin vaults on the warp platform
    **/
    function viewNumSCVaults() external view returns (uint256) {
        return scVaults.length;
    }
     /**
    @notice createNewLPVault allows the contract owner to create a new WarpVaultLP contract for a specific LP token
    @param _timelock is a variable representing the number of seconds the timeWizard will prevent withdraws and borrows from a contracts(one week is 605800 seconds)
    @param _lp is the address for the LP token this Warp Vault will manage
    **/
    function createNewLPVault( 
        uint256 _timelock,
        address _lp
    ) public onlyOwner {
 
        require(instanceLPTracker[_lp] == address(0), "LP vault already exists");

        //create new Warp LP Vault
        address _WarpVault = WVLPF.createWarpVaultLP(_timelock, _lp);
        //track the warp vault lp instance by the address of the LP it represents
        instanceLPTracker[_lp] = _WarpVault;
        //add new LP Vault to the array of all LP vaults
        lpVaults.push(_WarpVault);
        //set Warp vault address as an approved vault
        isVault[_WarpVault] = true;
        //track vault to asset
        getAssetByVault[_WarpVault] = _lp;
        emit NewLPVault(_WarpVault);
    }

    function importLPVault(address _lpVault) public onlyOwner {
      require(isVault[_lpVault] == false);
        WarpVaultLPI _vault = WarpVaultLPI(_lpVault);
        address _lp = _vault.getAssetAdd();

        instanceLPTracker[_lp] = _lpVault;
        lpVaults.push(_lpVault);
        isVault[_lpVault] = true;
        getAssetByVault[_lpVault] = _lp;
        emit ImportedLPVault(_lpVault);
    }


    /**
    @notice createNewSCVault allows the contract owner to create a new WarpVaultLP contract for a specific LP token
    @param _timelock is a variable representing the number of seconds the timeWizard will prevent withdraws and borrows from a contracts(one week is 605800 seconds)
    @param _baseRatePerYear is the base rate per year(approx target base APR)
    @param _multiplierPerYear is the multiplier per year(rate of increase in interest w/ utilizastion)
    @param _jumpMultiplierPerYear is the Jump Multiplier Per Year(the multiplier per block after hitting a specific utilizastion point)
    @param _optimal is the this is the utilizastion point or "kink" at which the jump multiplier is applied
    @param _initialExchangeRate is the intitial exchange rate(the rate at which the initial exchange of asset/ART is set)
    @param _StableCoin is the address of the StableCoin this Warp Vault will manage
    **/
    function createNewSCVault(
        uint256 _timelock,
        uint256 _baseRatePerYear,
        uint256 _multiplierPerYear,
        uint256 _jumpMultiplierPerYear,
        uint256 _optimal,
        uint256 _initialExchangeRate,
        uint256 _reserveFactorMantissa,
        address _StableCoin
    ) public onlyOwner {
        //create the interest rate model for this stablecoin
        address IR = address(
            new JumpRateModelV2(
                _baseRatePerYear,
                _multiplierPerYear,
                _jumpMultiplierPerYear,
                _optimal,
                address(this)
            )
        );
        //create the SC Warp vault
        address _WarpVault = WVSCF.createNewWarpVaultSC(
            IR,
            _StableCoin,
            warpTeam,
            _initialExchangeRate,
            _timelock,
            _reserveFactorMantissa
        );
        //track the warp vault sc instance by the address of the stablecoin it represents
        instanceSCTracker[_StableCoin] = _WarpVault;
        //add new SC Vault to the array of all SC vaults
        scVaults.push(_WarpVault);
        //set Warp vault address as an approved vault
        isVault[_WarpVault] = true;
        //track vault to asset
        getAssetByVault[_WarpVault] = _StableCoin;
        emit NewSCVault(_WarpVault, IR);
    }

    function importSCVault(address _scVault) public onlyOwner {
      require(isVault[_scVault] == false);

        WarpVaultSCI _vault = WarpVaultSCI(_scVault);
        address _token = _vault.getSCAddress();

        // track token -> vault
        instanceSCTracker[_token] = _scVault;
        // vault list
        scVaults.push(_scVault);
        // register vault in mapping
        isVault[_scVault] = true;
        // track vault -> token
        getAssetByVault[_scVault] = _token;
        emit ImportedSCVault(_scVault);
    }

    function setBorrowThreshold(uint256 _borrowLimitPercentage) public onlyOwner {
        borrowLimitPercentage = _borrowLimitPercentage;
    }

    function setLiquidateThreshold(uint256 _liquidateimitPercentage) public onlyOwner{
        liquidateLimitPercentage = _liquidateimitPercentage;
    }

    function setLiquidationFee(uint256 _liquidationFee) public onlyOwner {
        liquidationFee = _liquidationFee;
    }

    /**
    @notice Figures out how much of a given LP token an account is allowed to withdraw
    @param account is the account being checked
    @param lpToken is the address of the lpToken the user wishes to withdraw
    @dev this function runs calculations to accrue interest for an up to date amount
     */
    function getMaxWithdrawAllowed(address account, address lpToken)
        public
        returns (uint256)
    {
        uint256 borrowedTotal = getTotalBorrowedValue(account);
        uint256 collateralValue = getTotalAvailableCollateralValue(account);
        uint256 requiredCollateral = calcCollateralRequired(borrowedTotal);
        if (collateralValue < requiredCollateral) {
            return 0;
        }
        uint256 leftoverCollateral = collateralValue.sub(requiredCollateral);
        uint256 lpValue = oracle.getUnderlyingPrice(lpToken);
        return leftoverCollateral.mul(1e18).div(lpValue);
    }


    /**
    @notice getTotalAvailableCollateralValue returns the total availible collaeral value for an account in USDC
    @param _account is the address whos collateral is being retreived
    @dev this function runs calculations to accrue interest for an up to date amount
    **/
    function getTotalAvailableCollateralValue(address _account)
        public
        returns (uint256)
    {
        //get the number of LP vaults the platform has
        uint256 numVaults = lpVaults.length;
        //initialize the totalCollateral variable to zero
        uint256 totalCollateral = 0;
        //loop through each lp wapr vault
        for (uint256 i = 0; i < numVaults; ++i) {
            //instantiate warp vault at that position
            WarpVaultLPI vault = WarpVaultLPI(lpVaults[i]);
            //retreive the address of its asset
            address asset = vault.getAssetAdd();
            //retrieve USD price of this asset
            uint256 assetPrice = oracle.getUnderlyingPrice(asset);

            uint256 accountCollateral = vault.collateralOfAccount(_account);
            //emit DebugValues(accountCollateral, assetPrice);

            //multiply the amount of collateral by the asset price and return it
            uint256 accountAssetsValue = accountCollateral.mul(assetPrice);
            //add value to total collateral
            totalCollateral = totalCollateral.add(accountAssetsValue);
        }
        //return total USDC value of all collateral
        return totalCollateral.div(1e18);
    }

    /**
    @notice getPriceOfCollateral returns the price of an lpToken
    @param lpToken is the address of the lp token
    @dev this function does not run calculations amd returns the previously calculated price
    **/
    function getPriceOfCollateral(address lpToken) public returns (uint256) {
        return oracle.getUnderlyingPrice(lpToken);
    }

    /**
    @notice viewPriceOfToken retrieves the price of a stablecoin
    @param token is the address of the stablecoin
    @param amount is the amount of stablecoin
    @dev this function does not run calculations amd returns the previously calculated price
    **/
    function getPriceOfToken(address token, uint256 amount)
        public
        returns (uint256)
    {
        return oracle.getPriceOfToken(token, amount);
    }

    /**
    @notice getTotalLentValue returns the total lent value for an account in USDC
    @param _account is the account whos lent value we are calculating
    **/
    function getTotalLentValue(address _account)
        public
        //view
        returns (uint256)
    {
        uint256 numSCVaults = scVaults.length;
        uint256 totalValue = 0;

        // Add up each stable coin vaults value
        for (uint256 i = 0; i < numSCVaults; ++i) {
            //instantiate each LP warp vault
            WarpVaultSCI WVSC = WarpVaultSCI(scVaults[i]);
            //retreive the amount user has borrowed from each stablecoin vault
            uint256 lentBalanceInStable = WVSC.viewAccountBalance(_account);
            if (lentBalanceInStable == 0) {
                continue;
            }
            uint256 usdcLentAmount = getPriceOfToken(
                WVSC.getSCAddress(),
                lentBalanceInStable
            );
            totalValue = totalValue.add(usdcLentAmount);
        }

        return totalValue;
    }

    /**
    @notice viewTotalBorrowedValue returns the total borrowed value for an account in USDC
    @param _account is the account whos borrowed value we are calculating
    @dev this function returns newly calculated values
    **/
    function getTotalBorrowedValue(address _account) public returns (uint256) {
        uint256 numSCVaults = scVaults.length;
        //initialize the totalBorrowedValue variable to zero
        uint256 totalBorrowedValue = 0;
        //loop through all stable coin vaults
        for (uint256 i = 0; i < numSCVaults; ++i) {
            //instantiate each LP warp vault
            WarpVaultSCI WVSC = WarpVaultSCI(scVaults[i]);
            //retreive the amount user has borrowed from each stablecoin vault
            uint256 borrowBalanceInStable = WVSC.borrowBalanceCurrent(_account);
            if (borrowBalanceInStable == 0) {
                continue;
            }
            uint256 usdcBorrowedAmount = getPriceOfToken(
                WVSC.getSCAddress(),
                borrowBalanceInStable
            );
            totalBorrowedValue = totalBorrowedValue.add(usdcBorrowedAmount);
        }
        //return total Borrowed Value
        return totalBorrowedValue;
    }

    function calcBorrowLimit(uint256 _collateralValue)
        public
        view
        returns (uint256)
    {
        return _collateralValue.mul(borrowLimitPercentage).div(100 ether);
    }

    function calcLiquidationLimit(uint256 _collateralValue)
        public
        view
        returns (uint256)
    {
        return _collateralValue.mul(liquidateLimitPercentage).div(100 ether);
    }

    /**
    @notice calcCollateralRequired returns the amount of collateral needed for an input borrow value
    liquidatteLimitPercentage
    @param _borrowAmount is the input borrow amount
    **/
    function calcCollateralRequired(uint256 _borrowAmount)
        public
        view
        returns (uint256)
    {
        return _borrowAmount.mul(100 ether).div(borrowLimitPercentage);
    }

    /**
    @notice getBorrowLimit returns the borrow limit for an account
    @param _account is the input account address
    @dev this calculation uses current values for calculations
    **/
    function getBorrowLimit(address _account) public returns (uint256) {
        uint256 availibleCollateralValue = getTotalAvailableCollateralValue(
            _account
        );

        return calcBorrowLimit(availibleCollateralValue);
    }

    function getLiquidationLimit(address _account) public returns (uint256) {
        uint256 availibleCollateralValue = getTotalAvailableCollateralValue(
            _account
        );

        return calcLiquidationLimit(availibleCollateralValue);
    }

    /**
    @notice borrowSC is the function an end user will call when they wish to borrow a stablecoin from the warp platform
    @param _StableCoin is the address of the stablecoin the user wishes to borrow
    @param _amount is the amount of that stablecoin the user wants to borrow
    **/
    function borrowSC(address _StableCoin, uint256 _amount) public {
        uint256 borrowedTotalInUSDC = getTotalBorrowedValue(msg.sender);
        uint256 borrowLimitInUSDC = getBorrowLimit(msg.sender);
        uint256 borrowAmountAllowedInUSDC = borrowLimitInUSDC.sub(
            borrowedTotalInUSDC
        );

        uint256 borrowAmountInUSDC = getPriceOfToken(_StableCoin, _amount);

        //require the amount being borrowed is less than or equal to the amount they are aloud to borrow
        require(
            borrowAmountAllowedInUSDC >= borrowAmountInUSDC,
            "Borrowing more than allowed"
        );

        //retreive stablecoin vault address being borrowed from and instantiate it
        WarpVaultSCI WV = WarpVaultSCI(instanceSCTracker[_StableCoin]);
        //call _borrow function on the stablecoin warp vault
        WV._borrow(_amount, msg.sender);
        emit NewBorrow(msg.sender, _StableCoin, _amount);
    }

    /**
    @notice liquidateAccount is used to liquidate a non-compliant loan after it has reached its 30 minute grace period
    @param _borrower is the address of the borrower whos loan is non-compliant
    **/
    function liquidateAccount(address _borrower) public {
        //require the liquidator is not also the borrower
        require(msg.sender != _borrower, "you cant liquidate yourself");
        //retreive the number of stablecoin vaults in the warp platform
        uint256 numSCVaults = scVaults.length;
        //retreive the number of LP vaults in the warp platform
        uint256 numLPVaults = lpVaults.length;
        // This is how much USDC worth of Stablecoin the user has borrowed
        uint256 borrowedAmount = 0;
        //initialize the stable coin balances array
        uint256[] memory scBalances = new uint256[](numSCVaults);
        // loop through and retreive the Borrowed Amount From All Vaults
        for (uint256 i = 0; i < numSCVaults; ++i) {
            //instantiate the vault at the current  position in the array
            WarpVaultSCI scVault = WarpVaultSCI(scVaults[i]);
            //retreive the borrowers borrow balance from this vault and add it to the scBalances array
            scBalances[i] = scVault.borrowBalanceCurrent(_borrower);
            uint256 borrowedAmountInUSDC = getPriceOfToken(
                getAssetByVault[address(scVault)],
                scBalances[i]
            );

            //add the borrowed amount to the total borrowed balance
            borrowedAmount = borrowedAmount.add(borrowedAmountInUSDC);
        }
        //retreve the USDC borrow limit for the borrower
        uint256 liquidationLimit = getLiquidationLimit(_borrower);
        
        //check if the borrow is less than the borrowed amount
        require(borrowedAmount > liquidationLimit, "Loan is still valid");

        // If it is Liquidate the account
        //loop through each SC vault so the  Liquidator can pay off Stable Coin loans
        for (uint256 i = 0; i < numSCVaults; ++i) {
            //instantiate the Warp SC Vault at the current position
            WarpVaultSCI scVault = WarpVaultSCI(scVaults[i]);
            //call repayLiquidatedLoan function to repay the loan
            scVault._repayLiquidatedLoan(
                _borrower,
                msg.sender,
                scBalances[i]
            );
        }
        //loop through each LP vault so the Liquidator gets the LP tokens the borrower had
        for (uint256 i = 0; i < numLPVaults; ++i) {
            //instantiate the Warp LP Vault at the current position
            WarpVaultLPI lpVault = WarpVaultLPI(lpVaults[i]);
            
            //call liquidateAccount function on that LP vault and transfer LP tokens to warp control
            lpVault._liquidateAccount(_borrower, address(this));

            IUniswapV2Pair lpToken = IUniswapV2Pair(lpVault.getAssetAdd());

            // transfer 15% of those tokens to the warp team
            lpToken.transfer(warpTeam, lpToken.balanceOf(address(this)) * liquidationFee / 100 ether);

            // transfer the remaining to liquidator
            lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
        }
        emit Liquidation(_borrower, msg.sender);
    }

    /**
    @notice updateInterestRateModel allows the warp team to update the interest rate model for a stablecoin
    @param _token is the address of the stablecoin whos vault is having its interest rate updated
    @param _baseRatePerYear is the base rate per year(approx target base APR)
    @param _multiplierPerYear is the multiplier per year(rate of increase in interest w/ utilizastion)
    @param _jumpMultiplierPerYear is the Jump Multiplier Per Year(the multiplier per block after hitting a specific utilizastion point)
    @param _optimal is the this is the utilizastion point or "kink" at which the jump multiplier is applied
    **/
    function updateInterestRateModel(
        address _token,
        uint256 _baseRatePerYear,
        uint256 _multiplierPerYear,
        uint256 _jumpMultiplierPerYear,
        uint256 _optimal
    ) public onlyOwner {
        address IR = address(
            new JumpRateModelV2(
                _baseRatePerYear,
                _multiplierPerYear,
                _jumpMultiplierPerYear,
                _optimal,
                address(this)
            )
        );
        address vault = instanceSCTracker[_token];
        WarpVaultSCI WV = WarpVaultSCI(vault);
        WV.setNewInterestModel(IR);
        emit NewInterestRateModelCreated(
          _token,
           _baseRatePerYear,
          _multiplierPerYear,
          _jumpMultiplierPerYear,
          _optimal
        );
    }

    /**
    @notice startUpgradeTimer starts a two day timer signaling that this contract will soon be updated to a new version
    @param _newWarpControl is the address of the new Warp control contract being upgraded to
    **/
    function startUpgradeTimer(address _newWarpControl) public onlyOwner {
        newWarpControl = _newWarpControl;
        graceSpace = now.add(172800);
    }

    /**
    @notice upgradeWarp is used to upgrade the Warp platform to use a new version of the WarpControl contract
    **/
    function upgradeWarp() public onlyOwner {
        require(now >= graceSpace, "you cant ugrade yet, less than two days");
        require(newWarpControl != address(0), "no new warp control set");

        oracle.transferOwnership(newWarpControl);

        uint256 numVaults = lpVaults.length;
        uint256 numSCVaults = scVaults.length;

        for (uint256 i = 0; i < numVaults; ++i) {
            WarpVaultLPI vault = WarpVaultLPI(lpVaults[i]);
            vault.updateWarpControl(newWarpControl);
        }

        for (uint256 i = 0; i < numSCVaults; ++i) {
            WarpVaultSCI vault = WarpVaultSCI(scVaults[i]);
            vault.updateWarpControl(newWarpControl);
        }
    }

    /**
    @notice transferWarpTeam allows the wapr team address to be changed by the owner account
    @param _newWarp is the address of the new warp team
    **/
    function transferWarpTeam(address _newWarp) public onlyOwner {
        uint256 numSCVaults = scVaults.length;
        warpTeam = _newWarp;
        for (uint256 i = 0; i < numSCVaults; ++i) {
            WarpVaultSCI WVSC = WarpVaultSCI(scVaults[i]);
            WVSC.updateTeam(_newWarp);
        }
    }
}