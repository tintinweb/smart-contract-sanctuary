/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// File: @openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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

// File: contracts/utils/DecimalMath.sol



/// @dev Implements simple fixed point math add, sub, mul and div operations.
/// @author Alberto Cuesta Cañada
library DecimalMath {
    using SafeMathUpgradeable for uint256;

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.add(y);
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.sub(y);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(y).div(unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(unit(decimals)).div(y);
    }
}

// File: contracts/utils/Decimal.sol




library Decimal {
    using DecimalMath for uint256;
    using SafeMathUpgradeable for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal(x.d.mul(DecimalMath.unit(18)) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.add(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.sub(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.mul(y);
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.div(y);
        return t;
    }
}

// File: @openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol



/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: contracts/utils/SignedDecimalMath.sol



/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library SignedDecimalMath {
    using SignedSafeMathUpgradeable for int256;

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(int256 x, int256 y) internal pure returns (int256) {
        return x.add(y);
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(int256 x, int256 y) internal pure returns (int256) {
        return x.sub(y);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(int256 x, int256 y) internal pure returns (int256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return x.mul(y).div(unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(int256 x, int256 y) internal pure returns (int256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return x.mul(unit(decimals)).div(y);
    }
}

// File: contracts/utils/SignedDecimal.sol





library SignedDecimal {
    using SignedDecimalMath for int256;
    using SignedSafeMathUpgradeable for int256;

    struct signedDecimal {
        int256 d;
    }

    function zero() internal pure returns (signedDecimal memory) {
        return signedDecimal(0);
    }

    function toInt(signedDecimal memory x) internal pure returns (int256) {
        return x.d;
    }

    function isNegative(signedDecimal memory x) internal pure returns (bool) {
        if (x.d < 0) {
            return true;
        }
        return false;
    }

    function abs(signedDecimal memory x) internal pure returns (Decimal.decimal memory) {
        Decimal.decimal memory t;
        if (x.d < 0) {
            t.d = uint256(0 - x.d);
        } else {
            t.d = uint256(x.d);
        }
        return t;
    }

    /// @dev add two decimals
    function addD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.add(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.sub(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a signedDecimal by a int256
    function mulScalar(signedDecimal memory x, int256 y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.mul(y);
        return t;
    }

    /// @dev divide two decimals
    function divD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a signedDecimal by a int256
    function divScalar(signedDecimal memory x, int256 y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.div(y);
        return t;
    }
}

// File: contracts/utils/MixedDecimal.sol





/// @dev To handle a signedDecimal add/sub/mul/div a decimal and provide convert decimal to signedDecimal helper
library MixedDecimal {
    using SignedDecimal for SignedDecimal.signedDecimal;
    using SignedSafeMathUpgradeable for int256;

    uint256 private constant _INT256_MAX = 2**255 - 1;
    string private constant ERROR_NON_CONVERTIBLE = "MixedDecimal: uint value is bigger than _INT256_MAX";

    modifier convertible(Decimal.decimal memory x) {
        require(_INT256_MAX >= x.d, ERROR_NON_CONVERTIBLE);
        _;
    }

    function fromDecimal(Decimal.decimal memory x)
        internal
        pure
        convertible(x)
        returns (SignedDecimal.signedDecimal memory)
    {
        return SignedDecimal.signedDecimal(int256(x.d));
    }

    function toUint(SignedDecimal.signedDecimal memory x) internal pure returns (uint256) {
        return x.abs().d;
    }

    /// @dev add SignedDecimal.signedDecimal and Decimal.decimal, using SignedSafeMath directly
    function addD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d.add(int256(y.d));
        return t;
    }

    /// @dev subtract SignedDecimal.signedDecimal by Decimal.decimal, using SignedSafeMath directly
    function subD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d.sub(int256(y.d));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by Decimal.decimal
    function mulD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.mulD(fromDecimal(y));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by a uint256
    function mulScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.mulScalar(int256(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a Decimal.decimal
    function divD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.divD(fromDecimal(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a uint256
    function divScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.divScalar(int256(y));
        return t;
    }
}

// File: contracts/utils/BlockContext.sol


// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/types/ISakePerpVaultTypes.sol

pragma experimental ABIEncoderV2;

interface ISakePerpVaultTypes {
    /**
     * @notice pool types
     * @param HIGH high risk pool
     * @param LOW low risk pool
     */
    enum Risk {HIGH, LOW}
}

// File: contracts/types/IExchangeTypes.sol




interface IExchangeTypes {
    /**
     * @notice asset direction, used in getInputPrice, getOutputPrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {ADD_TO_AMM, REMOVE_FROM_AMM}

    struct LiquidityChangedSnapshot {
        SignedDecimal.signedDecimal cumulativeNotional;
        // the base/quote reserve of amm right before liquidity changed
        Decimal.decimal quoteAssetReserve;
        Decimal.decimal baseAssetReserve;
        // total position size owned by amm after last snapshot taken
        // `totalPositionSize` = currentBaseAssetReserve - lastLiquidityChangedHistoryItem.baseAssetReserve + prevTotalPositionSize
        SignedDecimal.signedDecimal totalPositionSize;
    }
}

// File: contracts/interface/IExchange.sol







interface IExchange is IExchangeTypes {
    function swapInput(
        Dir _dir,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit,
        bool _reverse
    ) external returns (Decimal.decimal memory);

    function swapOutput(
        Dir _dir,
        Decimal.decimal calldata _baseAssetAmount,
        Decimal.decimal calldata _quoteAssetAmountLimit,
        bool _skipFluctuationCheck
    ) external returns (Decimal.decimal memory);

    function migrateLiquidity(Decimal.decimal calldata _liquidityMultiplier, Decimal.decimal calldata _priceLimitRatio)
        external;

    function shutdown() external;

    function settleFunding(bool movingAmm)
        external
        returns (
            SignedDecimal.signedDecimal memory,
            SignedDecimal.signedDecimal memory,
            SignedDecimal.signedDecimal memory
        );

    function calcFee(Decimal.decimal calldata _quoteAssetAmount) external view returns (Decimal.decimal memory);

    function calcBaseAssetAfterLiquidityMigration(
        SignedDecimal.signedDecimal memory _baseAssetAmount,
        Decimal.decimal memory _fromQuoteReserve,
        Decimal.decimal memory _fromBaseReserve
    ) external view returns (SignedDecimal.signedDecimal memory);

    function getInputTwap(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputTwap(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPrice(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputPrice(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);

    function getSpotPrice() external view returns (Decimal.decimal memory);

    function getLiquidityHistoryLength() external view returns (uint256);

    // overridden by state variable
    function quoteAsset() external view returns (IERC20Upgradeable);

    function open() external view returns (bool);

    // can not be overridden by state variable due to type `Deciaml.decimal`
    function getSettlementPrice() external view returns (Decimal.decimal memory);

    function getCumulativeNotional() external view returns (SignedDecimal.signedDecimal memory);

    function getMaxHoldingBaseAsset() external view returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap() external view returns (Decimal.decimal memory);

    function getLiquidityChangedSnapshots(uint256 i) external view returns (LiquidityChangedSnapshot memory);

    function mint(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function burn(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function getMMUnrealizedPNL(Decimal.decimal memory _baseAssetReserve, Decimal.decimal memory _quoteAssetReserve)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function moveAMMPriceToOracle(uint256 _oraclePrice, bytes32 _priceFeedKey) external;

    function setPriceFeed(address _priceFeed) external;

    function getReserve() external view returns (Decimal.decimal memory, Decimal.decimal memory);

    function initMarginRatio() external view returns (Decimal.decimal memory);

    function maintenanceMarginRatio() external view returns (Decimal.decimal memory);

    function liquidationFeeRatio() external view returns (Decimal.decimal memory);

    function maxLiquidationFee() external view returns (Decimal.decimal memory);

    function spreadRatio() external view returns (Decimal.decimal memory);

    function priceFeedKey() external view returns (bytes32);

    function tradeLimitRatio() external view returns (uint256);

    function priceAdjustRatio() external view returns (uint256);

    function fluctuationLimitRatio() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function adjustTotalPosition(
        SignedDecimal.signedDecimal memory adjustedPosition,
        SignedDecimal.signedDecimal memory oldAdjustedPosition
    ) external;

    function getTotalPositionSize() external view returns (SignedDecimal.signedDecimal memory);

    function getExchangeState() external view returns (address);

    function getUnderlyingPrice() external view returns (Decimal.decimal memory);

    function isOverSpreadLimit() external view returns (bool);

    function getPositionSize()
        external
        view
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory);
}

// File: contracts/interface/IInsuranceFund.sol




interface IInsuranceFund {
    function withdraw(Decimal.decimal calldata _amount) external returns (Decimal.decimal memory badDebt);

    function setExchange(IExchange _exchange) external;

    function setBeneficiary(address _beneficiary) external;
}

// File: contracts/interface/ISystemSettings.sol





interface ISystemSettings {
    function insuranceFundFeeRatio() external view returns (Decimal.decimal memory);

    function lpWithdrawFeeRatio() external view returns (Decimal.decimal memory);

    function overnightFeeRatio() external view returns (Decimal.decimal memory);

    function overnightFeeLpShareRatio() external view returns (Decimal.decimal memory);

    function fundingFeeLpShareRatio() external view returns (Decimal.decimal memory);

    function overnightFeePeriod() external view returns (uint256);

    function isExistedExchange(IExchange _exchange) external view returns (bool);

    function getAllExchanges() external view returns (IExchange[] memory);

    function getInsuranceFund(IExchange _exchange) external view returns (IInsuranceFund);

    function setNextOvernightFeeTime(IExchange _exchange) external;

    function nextOvernightFeeTime(address _exchange) external view returns (uint256);

    function checkTransfer(address _from, address _to) external view returns (bool);
}

// File: contracts/interface/ISakePerpVault.sol






interface ISakePerpVault is ISakePerpVaultTypes {
    function withdraw(
        IExchange _exchange,
        address _receiver,
        Decimal.decimal memory _amount
    ) external;

    function realizeBadDebt(IExchange _exchange, Decimal.decimal memory _badDebt) external;

    function modifyLiquidity() external;

    function getMMLiquidity(address _exchange, Risk _risk) external view returns (SignedDecimal.signedDecimal memory);

    function getAllMMLiquidity(address _exchange)
        external
        view
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory);

    function getTotalMMLiquidity(address _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function getTotalMMAvailableLiquidity(address _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function getTotalLpUnrealizedPNL(IExchange _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function addCachedLiquidity(address _exchange, Decimal.decimal memory _DeltalpLiquidity) external;

    function requireMMNotBankrupt(address _exchange) external;

    function getMMCachedLiquidity(address _exchange, Risk _risk) external view returns (Decimal.decimal memory);

    function getTotalMMCachedLiquidity(address _exchange) external view returns (Decimal.decimal memory);

    function setRiskLiquidityWeight(address _exchange, uint256 _highWeight, uint256 _lowWeight) external;

    function setMaxLoss(
        address _exchange,
        Risk _risk,
        uint256 _max
    ) external;
}

// File: contracts/types/ISakePerpTypes.sol




interface ISakePerpTypes {
    //
    // Struct and Enum
    //
    enum Side {BUY, SELL}
    enum PnlCalcOption { SPOT_PRICE, TWAP, ORACLE }

    /// @notice This struct records personal position information
    /// @param size denominated in amm.baseAsset
    /// @param margin isolated margin
    /// @param openNotional the quoteAsset value of position when opening position. the cost of the position
    /// @param lastUpdatedCumulativePremiumFraction for calculating funding payment, record at the moment every time when trader open/reduce/close position
    /// @param lastUpdatedCumulativeOvernightFeeRate for calculating holding fee, record at the moment every time when trader open/reduce/close position
    /// @param liquidityHistoryIndex
    /// @param blockNumber the block number of the last position
    struct Position {
        SignedDecimal.signedDecimal size;
        Decimal.decimal margin;
        Decimal.decimal openNotional;
        SignedDecimal.signedDecimal lastUpdatedCumulativePremiumFraction;
        Decimal.decimal lastUpdatedCumulativeOvernightFeeRate;
        uint256 liquidityHistoryIndex;
        uint256 blockNumber;
    }
}

// File: contracts/interface/ISakePerp.sol






interface ISakePerp is ISakePerpTypes {
    function getMMLiquidity(address _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function getLatestCumulativePremiumFraction(IExchange _exchange)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function getLatestCumulativePremiumFractionWithPosition(
        IExchange _exchange,
        SignedDecimal.signedDecimal memory _position
    ) external view returns (SignedDecimal.signedDecimal memory);

    function getLatestCumulativeOvernightFeeRate(IExchange _exchange) external view returns (Decimal.decimal memory);

    function getPositionNotionalAndUnrealizedPnl(
        IExchange _exchange,
        address _trader,
        PnlCalcOption _pnlCalcOption
    ) external view returns (Decimal.decimal memory positionNotional, SignedDecimal.signedDecimal memory unrealizedPnl);

    function getPosition(IExchange _exchange, address _trader) external view returns (Position memory);

    function getUnadjustedPosition(IExchange _exchange, address _trader)
        external
        view
        returns (Position memory position);

    function getMarginRatio(IExchange _exchange, address _trader)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function payFunding(IExchange _exchange) external;
}

// File: contracts/interface/ISakePerpState.sol




interface ISakePerpState {
    struct TradingState {
        uint256 lastestLongTime;
        uint256 lastestShortTime;
    }

    struct RemainMarginInfo {
        Decimal.decimal remainMargin;
        Decimal.decimal badDebt;
        SignedDecimal.signedDecimal fundingPayment;
        Decimal.decimal overnightFee;
    }

    function checkWaitingPeriod(
        address _exchange,
        address _trader,
        ISakePerpTypes.Side _side
    ) external returns (bool);

    function updateOpenInterestNotional(IExchange _exchange, SignedDecimal.signedDecimal memory _amount) external;

    function getWhiteList() external view returns (address);

    function getPositionNotionalAndUnrealizedPnl(
        IExchange _exchange,
        ISakePerpTypes.Position memory _position,
        ISakePerpTypes.PnlCalcOption _pnlCalcOption
    ) external view returns (Decimal.decimal memory positionNotional, SignedDecimal.signedDecimal memory unrealizedPnl);

    function calcPositionAfterLiquidityMigration(
        IExchange _exchange,
        ISakePerpTypes.Position memory _position,
        uint256 _latestLiquidityIndex
    ) external view returns (ISakePerpTypes.Position memory);

    function calcPositionAfterLiquidityMigrationWithoutNew(
        IExchange _exchange,
        ISakePerpTypes.Position memory _position,
        uint256 _latestLiquidityIndex
    ) external returns (SignedDecimal.signedDecimal memory);

    function calcRemainMarginWithFundingPaymentAndOvernightFee(
        IExchange _exchange,
        ISakePerpTypes.Position memory _oldPosition,
        SignedDecimal.signedDecimal memory _marginDelta
    ) external view returns (RemainMarginInfo memory remainMarginInfo);
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol



/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol






/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol


// solhint-disable-next-line compiler-version


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: @openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol




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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol




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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// File: contracts/SakePerp.sol

















// note BaseRelayRecipient must come after OwnerPausableUpgradeSafe so its msg.sender takes precedence
// (yes, the ordering is reversed comparing to Python)
contract SakePerp is ISakePerp, OwnableUpgradeable, BlockContext {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    //
    // EVENTS
    //
    event MarginChanged(
        address indexed sender,
        address indexed exchange,
        int256 amount,
        int256 fundingPayment,
        uint256 overnightFee
    );
    event PositionAdjusted(
        address indexed exchange,
        address indexed trader,
        int256 newPositionSize,
        uint256 oldLiquidityIndex,
        uint256 newLiquidityIndex
    );
    event PositionSettled(address indexed exchange, address indexed trader, uint256 valueTransferred);
    event RestrictionModeEntered(address exchange, uint256 blockNumber);

    /// @notice This event is emitted when position change
    /// @param trader the address which execute this transaction
    /// @param exchange IExchange address
    /// @param margin margin
    /// @param positionNotional margin * leverage
    /// @param exchangedPositionSize position size, e.g. ETHUSDC or LINKUSDC
    /// @param fee transaction fee
    /// @param positionSizeAfter position size after this transaction, might be increased or decreased
    /// @param realizedPnl realized pnl after this position changed
    /// @param unrealizedPnlAfter unrealized pnl after this position changed
    /// @param badDebt position change amount cleared by insurance funds
    /// @param liquidationPenalty amount of remaining margin lost due to liquidation
    /// @param spotPrice quote asset reserve / base asset reserve
    /// @param fundingPayment funding payment (+: trader paid, -: trader received)
    /// @param overnightPayment overnight payment
    event PositionChanged(
        address indexed trader,
        address indexed exchange,
        uint256 margin,
        uint256 positionNotional,
        int256 exchangedPositionSize,
        uint256 fee,
        int256 positionSizeAfter,
        int256 realizedPnl,
        int256 unrealizedPnlAfter,
        uint256 badDebt,
        uint256 liquidationPenalty,
        uint256 spotPrice,
        int256 fundingPayment,
        uint256 overnightPayment
    );

    /// @notice This event is emitted when position liquidated
    /// @param trader the account address being liquidated
    /// @param exchange IExchange address
    /// @param positionNotional liquidated position value minus liquidationFee
    /// @param positionSize liquidated position size
    /// @param liquidationFee liquidation fee to the liquidator
    /// @param liquidator the address which execute this transaction
    /// @param badDebt liquidation fee amount cleared by insurance funds
    event PositionLiquidated(
        address indexed trader,
        address indexed exchange,
        uint256 positionNotional,
        uint256 positionSize,
        uint256 liquidationFee,
        address liquidator,
        uint256 badDebt
    );

    /// @notice This event is emitted when overnight fee payed
    /// @param exchange exchange address
    /// @param totalOpenNotional the total open notional
    /// @param overnightFee the total overinight fee this time
    /// @param rate current overnight feerate
    event OvernightFeePayed(address indexed exchange, uint256 totalOpenNotional, uint256 overnightFee, uint256 rate);

    /// @notice This struct is used for avoiding stack too deep error when passing too many var between functions
    struct PositionResp {
        Position position;
        // the quote asset amount trader will send if open position, will receive if close
        Decimal.decimal exchangedQuoteAssetAmount;
        // if realizedPnl + realizedFundingPayment + margin is negative, it's the abs value of it
        Decimal.decimal badDebt;
        // the base asset amount trader will receive if open position, will send if close
        SignedDecimal.signedDecimal exchangedPositionSize;
        // funding payment incurred during this position response
        SignedDecimal.signedDecimal fundingPayment;
        // overnight payment incurred during this position response
        Decimal.decimal overnightFee;
        // realizedPnl = unrealizedPnl * closedRatio
        SignedDecimal.signedDecimal realizedPnl;
        // positive = trader transfer margin to vault, negative = trader receive margin from vault
        // it's 0 when internalReducePosition, its addedMargin when internalIncreasePosition
        // it's min(0, oldPosition + realizedFundingPayment + realizedPnl) when internalClosePosition
        SignedDecimal.signedDecimal marginToVault;
        // unrealized pnl after open position
        SignedDecimal.signedDecimal unrealizedPnlAfter;
    }

    struct ExchangeMap {
        // issue #1471
        // last block when it turn restriction mode on.
        // In restriction mode, no one can do multi open/close/liquidate position in the same block.
        // If any underwater position being closed (having a bad debt and make insuranceFund loss),
        // or any liquidation happened,
        // restriction mode is ON in that block and OFF(default) in the next block.
        // This design is to prevent the attacker being benefited from the multiple action in one block
        // in extreme cases
        uint256 lastRestrictionBlock;
        SignedDecimal.signedDecimal[] cumulativePremiumFractions;
        Decimal.decimal[] cumulativeOvernightFeerates;
        mapping(address => Position) positionMap;
        Decimal.decimal totalOpenNotional;
        SignedDecimal.signedDecimal[] cumulativePremiumFractionsForLong;
        SignedDecimal.signedDecimal[] cumulativePremiumFractionsForShort;
    }

    //**********************************************************//
    //    Can not change the order of below state variables     //
    //**********************************************************//
    // key by exchange address
    mapping(address => ExchangeMap) internal exchangeMap;

    ISystemSettings public systemSettings;

    ISakePerpVault public sakePerpVault;
    ISakePerpState public sakePerpState;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private status;
    bool public paused;
    //**********************************************************//
    //    Can not change the order of above state variables     //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //
    // openzeppelin doesn't support struct input
    // https://github.com/OpenZeppelin/openzeppelin-sdk/issues/1523
    function initialize(
        address _systemsettings,
        address _sakePerpVault,
        address _sakePerpState
    ) public initializer {
        __Ownable_init();

        systemSettings = ISystemSettings(_systemsettings);
        sakePerpVault = ISakePerpVault(_sakePerpVault);
        sakePerpState = ISakePerpState(_sakePerpState);
        status = _NOT_ENTERED;
        paused = false;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        status = _NOT_ENTERED;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    //
    // External
    //
    /**
     * @dev set system settings
     */
    function setSystemSettings(ISystemSettings _systemSettings) external onlyOwner {
        systemSettings = _systemSettings;
    }

    /**
     * @notice add margin to increase margin ratio
     * @param _exchange IExchange address
     * @param _addedMargin added margin in 18 digits
     */
    function addMargin(IExchange _exchange, Decimal.decimal calldata _addedMargin)
        external
        whenNotPaused()
        nonReentrant()
    {
        // check condition
        requireExchange(_exchange, true);
        requireNonZeroInput(_addedMargin);

        // update margin part in personal position
        address trader = msg.sender;
        Position memory position = adjustPositionForLiquidityChanged(_exchange, trader);
        position.margin = position.margin.addD(_addedMargin);
        setPosition(_exchange, trader, position);

        // transfer token from trader
        IERC20Upgradeable(_exchange.quoteAsset()).safeTransferFrom(
            trader,
            address(sakePerpVault),
            _addedMargin.toUint()
        );

        emit MarginChanged(trader, address(_exchange), int256(_addedMargin.toUint()), 0, 0);
    }

    /**
     * @notice remove margin to decrease margin ratio
     * @param _exchange IExchange address
     * @param _removedMargin removed margin in 18 digits
     */
    function removeMargin(IExchange _exchange, Decimal.decimal calldata _removedMargin)
        external
        whenNotPaused()
        nonReentrant()
    {
        // check condition
        requireExchange(_exchange, true);
        requireNonZeroInput(_removedMargin);

        // update margin part in personal position
        address trader = msg.sender;
        Position memory position = adjustPositionForLiquidityChanged(_exchange, trader);

        // realize funding payment if there's no bad debt
        SignedDecimal.signedDecimal memory marginDelta = MixedDecimal.fromDecimal(_removedMargin).mulScalar(-1);
        ISakePerpState.RemainMarginInfo memory remainMarginInfo = sakePerpState
        .calcRemainMarginWithFundingPaymentAndOvernightFee(_exchange, position, marginDelta);
        require(remainMarginInfo.badDebt.toUint() == 0, "margin is not enough");

        position.margin = remainMarginInfo.remainMargin;
        position.lastUpdatedCumulativePremiumFraction = getLatestCumulativePremiumFractionWithPosition(
            _exchange,
            position.size
        );
        position.lastUpdatedCumulativeOvernightFeeRate = getLatestCumulativeOvernightFeeRate(_exchange);
        setPosition(_exchange, trader, position);

        // check margin ratio
        requireMoreMarginRatio(getMarginRatio(_exchange, trader), _exchange.initMarginRatio(), true);

        // transfer token back to trader
        withdraw(_exchange, trader, _removedMargin);

        emit MarginChanged(
            trader,
            address(_exchange),
            marginDelta.toInt(),
            remainMarginInfo.fundingPayment.toInt(),
            remainMarginInfo.overnightFee.toUint()
        );
    }

    /**
     * @notice settle all the positions when exchange is shutdown. The settlement price is according to IExchange.settlementPrice
     * @param _exchange IExchange address
     */
    function settlePosition(IExchange _exchange) external nonReentrant() {
        // check condition
        requireExchange(_exchange, false);

        address trader = msg.sender;
        Position memory pos = getPosition(_exchange, trader);
        requirePositionSize(pos.size);

        // update position
        clearPosition(_exchange, trader);

        // calculate settledValue
        // If Settlement Price = 0, everyone takes back her collateral.
        // else Returned Fund = Position Size * (Settlement Price - Open Price) + Collateral
        Decimal.decimal memory settlementPrice = _exchange.getSettlementPrice();
        Decimal.decimal memory settledValue;
        if (settlementPrice.toUint() == 0) {
            settledValue = pos.margin;
        } else {
            // returnedFund = positionSize * (settlementPrice - openPrice) + positionMargin
            // openPrice = positionOpenNotional / positionSize.abs()
            SignedDecimal.signedDecimal memory returnedFund = pos
            .size
            .mulD(MixedDecimal.fromDecimal(settlementPrice).subD(pos.openNotional.divD(pos.size.abs())))
            .addD(pos.margin);
            // if `returnedFund` is negative, trader can't get anything back
            if (returnedFund.toInt() > 0) {
                settledValue = returnedFund.abs();
            }
        }

        // transfer token based on settledValue. no insurance fund support
        if (settledValue.toUint() > 0) {
            withdraw(_exchange, trader, settledValue);
            //IERC20Upgradeable(_exchange.quoteAsset()).safeTransfer(trader, settledValue.toUint());
        }

        // emit event
        emit PositionSettled(address(_exchange), trader, settledValue.toUint());
    }

    // if increase position
    //   marginToVault = addMargin
    //   marginDiff = realizedFundingPayment + realizedPnl(0)
    //   pos.margin += marginToVault + marginDiff
    //   vault.margin += marginToVault + marginDiff
    //   required(enoughMarginRatio)
    // else if reduce position()
    //   marginToVault = 0
    //   marginDiff = realizedFundingPayment + realizedPnl
    //   pos.margin += marginToVault + marginDiff
    //   if pos.margin < 0, badDebt = abs(pos.margin), set pos.margin = 0
    //   vault.margin += marginToVault + marginDiff
    //   required(enoughMarginRatio)
    // else if close
    //   marginDiff = realizedFundingPayment + realizedPnl
    //   pos.margin += marginDiff
    //   if pos.margin < 0, badDebt = abs(pos.margin)
    //   marginToVault = -pos.margin
    //   set pos.margin = 0
    //   vault.margin += marginToVault + marginDiff
    // else if close and open a larger position in reverse side
    //   close()
    //   positionNotional -= exchangedQuoteAssetAmount
    //   newMargin = positionNotional / leverage
    //   internalIncreasePosition(newMargin, leverage)
    // else if liquidate
    //   close()
    //   pay liquidation fee to liquidator
    //   move the remain margin to insuranceFund

    /**
     * @notice open a position
     * @param _exchange exchange address
     * @param _side enum Side; BUY for long and SELL for short
     * @param _quoteAssetAmount quote asset amount in 18 digits. Can Not be 0
     * @param _leverage leverage  in 18 digits. Can Not be 0
     * @param _baseAssetAmountLimit minimum base asset amount expected to get to prevent from slippage.
     */
    function openPosition(
        IExchange _exchange,
        Side _side,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _leverage,
        Decimal.decimal calldata _baseAssetAmountLimit
    ) external whenNotPaused() nonReentrant() {
        requireExchange(_exchange, true);
        requireNonZeroInput(_quoteAssetAmount);
        requireNonZeroInput(_leverage);
        requireMoreMarginRatio(
            MixedDecimal.fromDecimal(Decimal.one()).divD(_leverage),
            _exchange.initMarginRatio(),
            true
        );
        requireNotRestrictionMode(_exchange);

        address trader = msg.sender;
        require(
            sakePerpState.checkWaitingPeriod(address(_exchange), trader, _side),
            "cannot open position during waiting period"
        );

        PositionResp memory positionResp;
        {
            // add scope for stack too deep error
            int256 oldPositionSize = adjustPositionForLiquidityChanged(_exchange, trader).size.toInt();
            bool isNewPosition = oldPositionSize == 0 ? true : false;
            if (!isNewPosition) {
                requireMoreMarginRatio(getMarginRatio(_exchange, trader), _exchange.maintenanceMarginRatio(), true);
            }

            // increase or decrease position depends on old position's side and size
            if (isNewPosition || (oldPositionSize > 0 ? Side.BUY : Side.SELL) == _side) {
                positionResp = internalIncreasePosition(
                    _exchange,
                    _side,
                    _quoteAssetAmount.mulD(_leverage),
                    _baseAssetAmountLimit,
                    _leverage
                );
            } else {
                positionResp = openReversePosition(
                    _exchange,
                    _side,
                    _quoteAssetAmount,
                    _leverage,
                    _baseAssetAmountLimit
                );
            }

            // update the position state
            setPosition(_exchange, trader, positionResp.position);

            // to prevent attacker to leverage the bad debt to withdraw extra token from  insurance fund
            if (positionResp.badDebt.toUint() > 0) {
                enterRestrictionMode(_exchange);
            }

            //ransfer the actual token between trader and vault
            IERC20Upgradeable quoteToken = _exchange.quoteAsset();
            if (positionResp.marginToVault.toInt() > 0) {
                quoteToken.safeTransferFrom(trader, address(sakePerpVault), positionResp.marginToVault.abs().toUint());
            } else if (positionResp.marginToVault.toInt() < 0) {
                withdraw(_exchange, trader, positionResp.marginToVault.abs());
            }

            //check MM
            sakePerpVault.requireMMNotBankrupt(address(_exchange));
        }

        // calculate fee and transfer token for fees
        //@audit - can optimize by changing amm.swapInput/swapOutput's return type to (exchangedAmount, quoteToll, quoteSpread, quoteReserve, baseReserve) (@wraecca)
        Decimal.decimal memory transferredFee = transferFee(trader, _exchange, positionResp.exchangedQuoteAssetAmount);

        // emit event
        uint256 spotPrice = _exchange.getSpotPrice().toUint();
        int256 fundingPayment = positionResp.fundingPayment.toInt(); // pre-fetch for stack too deep error
        uint256 overnightFee = positionResp.overnightFee.toUint();
        emit PositionChanged(
            trader,
            address(_exchange),
            positionResp.position.margin.toUint(),
            positionResp.exchangedQuoteAssetAmount.toUint(),
            positionResp.exchangedPositionSize.toInt(),
            transferredFee.toUint(),
            positionResp.position.size.toInt(),
            positionResp.realizedPnl.toInt(),
            positionResp.unrealizedPnlAfter.toInt(),
            positionResp.badDebt.toUint(),
            0,
            spotPrice,
            fundingPayment,
            overnightFee
        );
    }

    /**
     * @notice close all the positions
     * @param _exchange IExchange address
     */
    function closePosition(IExchange _exchange, Decimal.decimal calldata _quoteAssetAmountLimit)
        external
        whenNotPaused()
        nonReentrant()
    {
        // check conditions
        requireExchange(_exchange, true);
        requireNotRestrictionMode(_exchange);

        // update position
        address trader = msg.sender;
        Position memory position = adjustPositionForLiquidityChanged(_exchange, trader);
        Side _side = position.size.isNegative() ? Side.BUY : Side.SELL;
        require(
            sakePerpState.checkWaitingPeriod(address(_exchange), trader, _side),
            "cannot close position during waiting period"
        );

        PositionResp memory positionResp = internalClosePosition(_exchange, trader, _quoteAssetAmountLimit, true);

        {
            // add scope for stack too deep error
            // transfer the actual token from trader and vault
            if (positionResp.badDebt.toUint() > 0) {
                enterRestrictionMode(_exchange);
                realizeBadDebt(_exchange, positionResp.badDebt);
            }
            withdraw(_exchange, trader, positionResp.marginToVault.abs());
        }

        //check MM
        sakePerpVault.requireMMNotBankrupt(address(_exchange));

        // calculate fee and transfer token for fees
        Decimal.decimal memory transferredFee = transferFee(trader, _exchange, positionResp.exchangedQuoteAssetAmount);

        {
            // avoid stack too deep
            // prepare event
            uint256 spotPrice = _exchange.getSpotPrice().toUint();
            int256 fundingPayment = positionResp.fundingPayment.toInt();
            uint256 overnightFee = positionResp.overnightFee.toUint();
            emit PositionChanged(
                trader,
                address(_exchange),
                0, // margin
                positionResp.exchangedQuoteAssetAmount.toUint(),
                positionResp.exchangedPositionSize.toInt(),
                transferredFee.toUint(),
                positionResp.position.size.toInt(),
                positionResp.realizedPnl.toInt(),
                0, // unrealizedPnl
                positionResp.badDebt.toUint(),
                0,
                spotPrice,
                fundingPayment,
                overnightFee
            );
        }
    }

    /**
     * @notice liquidate trader's underwater position. Require trader's margin ratio less than maintenance margin ratio
     * @dev liquidator can NOT open any positions in the same block to prevent from price manipulation.
     * @param _exchange IExchange address
     * @param _trader trader address
     */
    function liquidate(IExchange _exchange, address _trader) external nonReentrant() {
        // check conditions
        requireExchange(_exchange, true);
        {
            SignedDecimal.signedDecimal memory marginRatio = getMarginRatio(_exchange, _trader);

            // including oracle-based margin ratio as reference price when amm is over spread limit
            if (_exchange.isOverSpreadLimit()) {
                SignedDecimal.signedDecimal memory marginRatioBasedOnOracle = getMarginRatioBasedOnOracle(
                    _exchange,
                    _trader
                );
                if (marginRatioBasedOnOracle.subD(marginRatio).toInt() > 0) {
                    marginRatio = marginRatioBasedOnOracle;
                }
            }
            requireMoreMarginRatio(marginRatio, _exchange.maintenanceMarginRatio(), false);
        }

        // update states
        adjustPositionForLiquidityChanged(_exchange, _trader);
        PositionResp memory positionResp = internalClosePosition(_exchange, _trader, Decimal.zero(), false);
        enterRestrictionMode(_exchange);

        {
            // avoid stack too deep
            // Amount pay to liquidator
            Decimal.decimal memory liquidationFee = positionResp.exchangedQuoteAssetAmount.mulD(
                _exchange.liquidationFeeRatio()
            );
            if (liquidationFee.cmp(_exchange.maxLiquidationFee()) > 0) {
                liquidationFee = _exchange.maxLiquidationFee();
            }

            // neither trader nor liquidator should pay anything for liquidating position
            // in here, -marginToVault means remainMargin

            Decimal.decimal memory remainMargin = positionResp.marginToVault.abs();
            // add scope for stack too deep error
            // if the remainMargin is not enough for liquidationFee, count it as bad debt
            // else, then the rest will be transferred to insuranceFund
            Decimal.decimal memory liquidationBadDebt;
            Decimal.decimal memory totalBadDebt = positionResp.badDebt;
            SignedDecimal.signedDecimal memory totalMarginToVault = positionResp.marginToVault;
            if (liquidationFee.toUint() > remainMargin.toUint()) {
                liquidationBadDebt = liquidationFee.subD(remainMargin);
                totalBadDebt = totalBadDebt.addD(liquidationBadDebt);
            } else {
                totalMarginToVault = totalMarginToVault.addD(liquidationFee);
            }

            // transfer the actual token between trader and vault
            if (totalBadDebt.toUint() > 0) {
                realizeBadDebt(_exchange, totalBadDebt);
            }
            if (totalMarginToVault.toInt() < 0) {
                transferToInsuranceFund(_exchange, totalMarginToVault.abs());
            }
            withdraw(_exchange, msg.sender, liquidationFee);

            emit PositionLiquidated(
                _trader,
                address(_exchange),
                positionResp.exchangedQuoteAssetAmount.toUint(),
                positionResp.exchangedPositionSize.toUint(),
                liquidationFee.toUint(),
                msg.sender,
                liquidationBadDebt.toUint()
            );
        }

        {
            emit PositionChanged(
                _trader,
                address(_exchange),
                0,
                positionResp.exchangedQuoteAssetAmount.toUint(),
                positionResp.exchangedPositionSize.toInt(),
                0,
                0,
                positionResp.realizedPnl.toInt(),
                0,
                positionResp.badDebt.toUint(),
                positionResp.marginToVault.abs().toUint(),
                _exchange.getSpotPrice().toUint(),
                positionResp.fundingPayment.toInt(),
                positionResp.overnightFee.toUint()
            );
        }
    }

    /**
     * @notice if funding rate is positive, traders with long position pay traders with short position and vice versa.
     * @param _exchange IExchange address
     */
    function payFunding(IExchange _exchange) external override {
        requireExchange(_exchange, true);
        bool movingAmm = false;
        if (msg.sender == address(_exchange)) movingAmm = true;

        (
            SignedDecimal.signedDecimal memory longPremiumFraction,
            SignedDecimal.signedDecimal memory shortPremiumFraction,
            SignedDecimal.signedDecimal memory ammFundingPaymentLoss
        ) = _exchange.settleFunding(movingAmm);
        if (ammFundingPaymentLoss.toInt() > 0) {
            handleFundingFeeAndOvernightFee(_exchange, ammFundingPaymentLoss.abs(), Decimal.zero());
        }

        exchangeMap[address(_exchange)].cumulativePremiumFractionsForLong.push(
            longPremiumFraction.addD(getLatestCumulativePremiumFractionWithSide(_exchange, Side.BUY))
        );
        exchangeMap[address(_exchange)].cumulativePremiumFractionsForShort.push(
            shortPremiumFraction.addD(getLatestCumulativePremiumFractionWithSide(_exchange, Side.SELL))
        );
    }

    /**
     * @notice if overnight fee rate is positive, traders with long position pay traders with short position and vice versa.
     * @param _exchange IExchange address
     */
    function payOvernightFee(IExchange _exchange) external {
        requireExchange(_exchange, true);
        systemSettings.setNextOvernightFeeTime(_exchange);

        Decimal.decimal memory overnightFeeRate = systemSettings.overnightFeeRatio();
        exchangeMap[address(_exchange)].cumulativeOvernightFeerates.push(
            overnightFeeRate.addD(getLatestCumulativeOvernightFeeRate(_exchange))
        );

        Decimal.decimal memory totalOpenNotional = exchangeMap[address(_exchange)].totalOpenNotional;
        Decimal.decimal memory exchageOvernightPayment = overnightFeeRate.mulD(totalOpenNotional);

        if (exchageOvernightPayment.toUint() > 0) {
            handleFundingFeeAndOvernightFee(
                _exchange,
                exchageOvernightPayment,
                systemSettings.overnightFeeLpShareRatio()
            );
        }

        emit OvernightFeePayed(
            address(_exchange),
            totalOpenNotional.toUint(),
            exchageOvernightPayment.toUint(),
            overnightFeeRate.toUint()
        );
    }

    /**
     * @notice adjust msg.sender's position when liquidity migration happened
     * @param _exchange Exchange address
     */
    function adjustPosition(IExchange _exchange) external {
        adjustPositionForLiquidityChanged(_exchange, msg.sender);
    }

    //
    // VIEW FUNCTIONS
    //
    /**
     * @notice get margin ratio, marginRatio = (margin + funding payments + unrealized Pnl) / openNotional
     * use spot and twap price to calculate unrealized Pnl, final unrealized Pnl depends on which one is higher
     * @param _exchange IExchange address
     * @param _trader trader address
     * @return margin ratio in 18 digits
     */
    function getMarginRatio(IExchange _exchange, address _trader)
        public
        view
        override
        returns (SignedDecimal.signedDecimal memory)
    {
        Position memory position = getPosition(_exchange, _trader);
        requirePositionSize(position.size);
        requireNonZeroInput(position.openNotional);

        (Decimal.decimal memory spotPositionNotional, SignedDecimal.signedDecimal memory spotPricePnl) = (
            getPositionNotionalAndUnrealizedPnl(_exchange, _trader, PnlCalcOption.SPOT_PRICE)
        );
        (Decimal.decimal memory twapPositionNotional, SignedDecimal.signedDecimal memory twapPricePnl) = (
            getPositionNotionalAndUnrealizedPnl(_exchange, _trader, PnlCalcOption.TWAP)
        );
        (SignedDecimal.signedDecimal memory unrealizedPnl, Decimal.decimal memory positionNotional) = spotPricePnl
        .toInt() > twapPricePnl.toInt()
            ? (spotPricePnl, spotPositionNotional)
            : (twapPricePnl, twapPositionNotional);

        return _getMarginRatio(_exchange, position, unrealizedPnl, positionNotional);
    }

    function getMarginRatioBasedOnOracle(IExchange _exchange, address _trader)
        public
        view
        returns (SignedDecimal.signedDecimal memory)
    {
        Position memory position = getPosition(_exchange, _trader);
        requirePositionSize(position.size);
        (Decimal.decimal memory oraclePositionNotional, SignedDecimal.signedDecimal memory oraclePricePnl) = (
            getPositionNotionalAndUnrealizedPnl(_exchange, _trader, PnlCalcOption.ORACLE)
        );
        return _getMarginRatio(_exchange, position, oraclePricePnl, oraclePositionNotional);
    }

    function _getMarginRatio(
        IExchange _exchange,
        Position memory _position,
        SignedDecimal.signedDecimal memory _unrealizedPnl,
        Decimal.decimal memory _positionNotional
    ) internal view returns (SignedDecimal.signedDecimal memory) {
        ISakePerpState.RemainMarginInfo memory remainMarginInfo = sakePerpState
        .calcRemainMarginWithFundingPaymentAndOvernightFee(_exchange, _position, _unrealizedPnl);
        return
            MixedDecimal.fromDecimal(remainMarginInfo.remainMargin).subD(remainMarginInfo.badDebt).divD(
                _positionNotional
            );
    }

    /**
     * @notice get personal position information, and adjust size if migration is necessary
     * @param _exchange IExchange address
     * @param _trader trader address
     * @return struct Position
     */
    function getPosition(IExchange _exchange, address _trader) public view override returns (Position memory) {
        Position memory pos = getUnadjustedPosition(_exchange, _trader);
        uint256 latestLiquidityIndex = _exchange.getLiquidityHistoryLength().sub(1);
        if (pos.liquidityHistoryIndex == latestLiquidityIndex) {
            return pos;
        }

        return sakePerpState.calcPositionAfterLiquidityMigration(_exchange, pos, latestLiquidityIndex);
    }

    /**
     * @notice get position notional and unrealized Pnl without fee expense and funding payment
     * @param _exchange IExchange address
     * @param _trader trader address
     * @param _pnlCalcOption enum PnlCalcOption, SPOT_PRICE for spot price and TWAP for twap price
     * @return positionNotional position notional
     * @return unrealizedPnl unrealized Pnl
     */
    function getPositionNotionalAndUnrealizedPnl(
        IExchange _exchange,
        address _trader,
        PnlCalcOption _pnlCalcOption
    )
        public
        view
        override
        returns (Decimal.decimal memory positionNotional, SignedDecimal.signedDecimal memory unrealizedPnl)
    {
        Position memory position = getPosition(_exchange, _trader);
        return sakePerpState.getPositionNotionalAndUnrealizedPnl(_exchange, position, _pnlCalcOption);
    }

    /**
     * @notice get latest cumulative premium fraction.
     * @param _exchange IExchange address
     * @return latest cumulative premium fraction in 18 digits
     */
    function getLatestCumulativePremiumFraction(IExchange _exchange)
        public
        view
        override
        returns (SignedDecimal.signedDecimal memory)
    {
        uint256 len = exchangeMap[address(_exchange)].cumulativePremiumFractions.length;
        if (len > 0) {
            return exchangeMap[address(_exchange)].cumulativePremiumFractions[len - 1];
        }
    }

    /**
     * @notice get latest cumulative premium fraction with specified side.
     * @param _exchange IExchange address
     * @param _side position side
     * @return latest cumulative premium fraction in 18 digits
     */
    function getLatestCumulativePremiumFractionWithSide(IExchange _exchange, Side _side)
        public
        view
        returns (SignedDecimal.signedDecimal memory)
    {
        if (_side == Side.BUY) {
            uint256 len = exchangeMap[address(_exchange)].cumulativePremiumFractionsForLong.length;
            if (len > 0) {
                return exchangeMap[address(_exchange)].cumulativePremiumFractionsForLong[len - 1];
            }
        } else {
            uint256 len = exchangeMap[address(_exchange)].cumulativePremiumFractionsForShort.length;
            if (len > 0) {
                return exchangeMap[address(_exchange)].cumulativePremiumFractionsForShort[len - 1];
            }
        }
    }

    /**
     * @notice get latest cumulative premium fraction with specified side.
     * @param _exchange IExchange address
     * @param _position position size
     * @return latest cumulative premium fraction in 18 digits
     */
    function getLatestCumulativePremiumFractionWithPosition(IExchange _exchange, SignedDecimal.signedDecimal memory _position)
        public
        view
        override
        returns (SignedDecimal.signedDecimal memory)
    {
        if (_position.toInt() > 0) {
            return getLatestCumulativePremiumFractionWithSide(_exchange, Side.BUY);
        } else {
            return getLatestCumulativePremiumFractionWithSide(_exchange, Side.SELL);
        }
    }

    /**
     * @notice get latest cumulative overnight feerate.
     * @param _exchange IExchange address
     * @return latest cumulative overnight feerate in 18 digits
     */
    function getLatestCumulativeOvernightFeeRate(IExchange _exchange)
        public
        view
        override
        returns (Decimal.decimal memory)
    {
        uint256 len = exchangeMap[address(_exchange)].cumulativeOvernightFeerates.length;
        if (len > 0) {
            return exchangeMap[address(_exchange)].cumulativeOvernightFeerates[len - 1];
        }
    }

    /**
     * @notice get MM liquidity.
     * @param _exchange IExchange address
     * @return MM liquidity in 18 digits
     *
     */
    function getMMLiquidity(address _exchange) public view override returns (SignedDecimal.signedDecimal memory) {
        return sakePerpVault.getTotalMMLiquidity(_exchange);
    }

    //
    // INTERNAL FUNCTIONS
    //

    function enterRestrictionMode(IExchange _exchange) internal {
        uint256 blockNumber = _blockNumber();
        exchangeMap[address(_exchange)].lastRestrictionBlock = blockNumber;
        emit RestrictionModeEntered(address(_exchange), blockNumber);
    }

    function setPosition(
        IExchange _exchange,
        address _trader,
        Position memory _position
    ) internal {
        Position storage positionStorage = exchangeMap[address(_exchange)].positionMap[_trader];
        exchangeMap[address(_exchange)].totalOpenNotional = exchangeMap[address(_exchange)].totalOpenNotional.subD(
            positionStorage.openNotional
        );
        positionStorage.size = _position.size;
        positionStorage.margin = _position.margin;
        positionStorage.openNotional = _position.openNotional;
        positionStorage.lastUpdatedCumulativePremiumFraction = _position.lastUpdatedCumulativePremiumFraction;
        positionStorage.lastUpdatedCumulativeOvernightFeeRate = _position.lastUpdatedCumulativeOvernightFeeRate;
        positionStorage.blockNumber = _position.blockNumber;
        positionStorage.liquidityHistoryIndex = _position.liquidityHistoryIndex;
        exchangeMap[address(_exchange)].totalOpenNotional = exchangeMap[address(_exchange)].totalOpenNotional.addD(
            positionStorage.openNotional
        );
    }

    function clearPosition(IExchange _exchange, address _trader) internal {
        Position memory position = exchangeMap[address(_exchange)].positionMap[_trader];
        exchangeMap[address(_exchange)].totalOpenNotional = exchangeMap[address(_exchange)].totalOpenNotional.subD(
            position.openNotional
        );

        // keep the record in order to retain the last updated block number
        exchangeMap[address(_exchange)].positionMap[_trader] = Position({
            size: SignedDecimal.zero(),
            margin: Decimal.zero(),
            openNotional: Decimal.zero(),
            lastUpdatedCumulativePremiumFraction: SignedDecimal.zero(),
            lastUpdatedCumulativeOvernightFeeRate: Decimal.zero(),
            blockNumber: _blockNumber(),
            liquidityHistoryIndex: 0
        });
    }

    // only called from openPosition and closeAndOpenReversePosition. caller need to ensure there's enough marginRatio
    function internalIncreasePosition(
        IExchange _exchange,
        Side _side,
        Decimal.decimal memory _openNotional,
        Decimal.decimal memory _minPositionSize,
        Decimal.decimal memory _leverage
    ) internal returns (PositionResp memory positionResp) {
        address trader = msg.sender;
        Position memory oldPosition = getUnadjustedPosition(_exchange, trader);
        positionResp.exchangedPositionSize = swapInput(_exchange, _side, _openNotional, _minPositionSize, false);
        SignedDecimal.signedDecimal memory newSize = oldPosition.size.addD(positionResp.exchangedPositionSize);
        // if size is 0 (means a new position), set the latest liquidity index
        uint256 liquidityHistoryIndex = oldPosition.liquidityHistoryIndex;
        if (oldPosition.size.toInt() == 0) {
            liquidityHistoryIndex = _exchange.getLiquidityHistoryLength().sub(1);
        }

        sakePerpState.updateOpenInterestNotional(_exchange, MixedDecimal.fromDecimal(_openNotional));
        // if the trader is not in the whitelist, check max position size
        if (trader != sakePerpState.getWhiteList()) {
            Decimal.decimal memory maxHoldingBaseAsset = _exchange.getMaxHoldingBaseAsset();
            if (maxHoldingBaseAsset.toUint() > 0) {
                // total position size should be less than `positionUpperBound`
                require(newSize.abs().cmp(maxHoldingBaseAsset) <= 0, "hit position size upper bound");
            }
        }

        Position memory position;
        {
            //avoid stakc too deep
            SignedDecimal.signedDecimal memory increaseMarginRequirement = MixedDecimal.fromDecimal(
                _openNotional.divD(_leverage)
            );

            ISakePerpState.RemainMarginInfo memory remainMarginInfo = sakePerpState
            .calcRemainMarginWithFundingPaymentAndOvernightFee(_exchange, oldPosition, increaseMarginRequirement);

            positionResp.marginToVault = increaseMarginRequirement;
            positionResp.fundingPayment = remainMarginInfo.fundingPayment;
            positionResp.overnightFee = remainMarginInfo.overnightFee;

            position.margin = remainMarginInfo.remainMargin;
        }

        {
            //avoid stack too deep
            (, SignedDecimal.signedDecimal memory unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(
                _exchange,
                trader,
                PnlCalcOption.SPOT_PRICE
            );
            positionResp.unrealizedPnlAfter = unrealizedPnl;
        }

        // update positionResp
        positionResp.exchangedQuoteAssetAmount = _openNotional;
        position.size = newSize;
        position.openNotional = oldPosition.openNotional.addD(positionResp.exchangedQuoteAssetAmount);
        position.liquidityHistoryIndex = liquidityHistoryIndex;
        position.lastUpdatedCumulativePremiumFraction = getLatestCumulativePremiumFractionWithPosition(
            _exchange,
            position.size
        );
        position.lastUpdatedCumulativeOvernightFeeRate = getLatestCumulativeOvernightFeeRate(_exchange);
        position.blockNumber = _blockNumber();
        positionResp.position = position;
    }

    function openReversePosition(
        IExchange _exchange,
        Side _side,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit
    ) internal returns (PositionResp memory) {
        Decimal.decimal memory openNotional = _quoteAssetAmount.mulD(_leverage);
        (
            Decimal.decimal memory oldPositionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        ) = getPositionNotionalAndUnrealizedPnl(_exchange, msg.sender, PnlCalcOption.SPOT_PRICE);
        PositionResp memory positionResp;

        // reduce position if old position is larger
        if (oldPositionNotional.toUint() > openNotional.toUint()) {
            sakePerpState.updateOpenInterestNotional(_exchange, MixedDecimal.fromDecimal(openNotional).mulScalar(-1));
            Position memory oldPosition = getUnadjustedPosition(_exchange, msg.sender);
            positionResp.exchangedPositionSize = swapInput(_exchange, _side, openNotional, _baseAssetAmountLimit, true);

            // realizedPnl = unrealizedPnl * closedRatio
            // closedRatio = positionResp.exchangedPositionSiz / oldPosition.size
            if (oldPosition.size.toInt() != 0) {
                positionResp.realizedPnl = unrealizedPnl.mulD(positionResp.exchangedPositionSize.abs()).divD(
                    oldPosition.size.abs()
                );
            }

            //
            {
                //avoid stack too deep
                ISakePerpState.RemainMarginInfo memory remainMarginInfo = sakePerpState
                .calcRemainMarginWithFundingPaymentAndOvernightFee(_exchange, oldPosition, positionResp.realizedPnl);

                positionResp.badDebt = remainMarginInfo.badDebt;
                positionResp.fundingPayment = remainMarginInfo.fundingPayment;
                positionResp.overnightFee = remainMarginInfo.overnightFee;
                positionResp.exchangedQuoteAssetAmount = openNotional;

                //stack too deep, temp use oldPosition
                oldPosition.margin = remainMarginInfo.remainMargin;
                //position.margin = remainMargin;
            }

            // positionResp.unrealizedPnlAfter = unrealizedPnl - realizedPnl
            positionResp.unrealizedPnlAfter = unrealizedPnl.subD(positionResp.realizedPnl);

            // calculate openNotional (it's different depends on long or short side)
            // long: unrealizedPnl = positionNotional - openNotional => openNotional = positionNotional - unrealizedPnl
            // short: unrealizedPnl = openNotional - positionNotional => openNotional = positionNotional + unrealizedPnl
            // positionNotional = oldPositionNotional - exchangedQuoteAssetAmount
            SignedDecimal.signedDecimal memory remainOpenNotional = oldPosition.size.toInt() > 0
                ? MixedDecimal.fromDecimal(oldPositionNotional).subD(positionResp.exchangedQuoteAssetAmount).subD(
                    positionResp.unrealizedPnlAfter
                )
                : positionResp.unrealizedPnlAfter.addD(oldPositionNotional).subD(
                    positionResp.exchangedQuoteAssetAmount
                );
            require(remainOpenNotional.toInt() > 0, "value of openNotional <= 0");

            {
                Position memory position;
                position.margin = oldPosition.margin;
                position.size = oldPosition.size.addD(positionResp.exchangedPositionSize);
                position.openNotional = remainOpenNotional.abs();
                position.liquidityHistoryIndex = oldPosition.liquidityHistoryIndex;
                position.lastUpdatedCumulativePremiumFraction = getLatestCumulativePremiumFractionWithPosition(
                    _exchange,
                    position.size
                );
                position.lastUpdatedCumulativeOvernightFeeRate = getLatestCumulativeOvernightFeeRate(_exchange);
                position.blockNumber = _blockNumber();
                positionResp.position = position;
            }

            return positionResp;
        }

        return closeAndOpenReversePosition(_exchange, _side, _quoteAssetAmount, _leverage, _baseAssetAmountLimit);
    }

    function closeAndOpenReversePosition(
        IExchange _exchange,
        Side _side,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit
    ) internal returns (PositionResp memory positionResp) {
        // new position size is larger than or equal to the old position size
        // so either close or close then open a larger position
        PositionResp memory closePositionResp = internalClosePosition(_exchange, msg.sender, Decimal.zero(), true);
        // the old position is underwater. trader should close a position first
        require(closePositionResp.badDebt.toUint() == 0, "reduce an underwater position");

        // update open notional after closing position
        Decimal.decimal memory openNotional = _quoteAssetAmount.mulD(_leverage).subD(
            closePositionResp.exchangedQuoteAssetAmount
        );

        // if remain exchangedQuoteAssetAmount is too small (eg. 1wei) then the required margin might be 0
        // then the clearingHouse will stop opening position
        if (openNotional.divD(_leverage).toUint() == 0) {
            positionResp = closePositionResp;
        } else {
            Decimal.decimal memory updatedBaseAssetAmountLimit;
            if (_baseAssetAmountLimit.toUint() > closePositionResp.exchangedPositionSize.toUint()) {
                updatedBaseAssetAmountLimit = _baseAssetAmountLimit.subD(closePositionResp.exchangedPositionSize.abs());
            }

            PositionResp memory increasePositionResp = internalIncreasePosition(
                _exchange,
                _side,
                openNotional,
                updatedBaseAssetAmountLimit,
                _leverage
            );
            positionResp = PositionResp({
                position: increasePositionResp.position,
                exchangedQuoteAssetAmount: closePositionResp.exchangedQuoteAssetAmount.addD(
                    increasePositionResp.exchangedQuoteAssetAmount
                ),
                badDebt: closePositionResp.badDebt.addD(increasePositionResp.badDebt),
                fundingPayment: closePositionResp.fundingPayment.addD(increasePositionResp.fundingPayment),
                overnightFee: closePositionResp.overnightFee.addD(increasePositionResp.overnightFee),
                exchangedPositionSize: closePositionResp.exchangedPositionSize.addD(
                    increasePositionResp.exchangedPositionSize
                ),
                realizedPnl: closePositionResp.realizedPnl.addD(increasePositionResp.realizedPnl),
                unrealizedPnlAfter: SignedDecimal.zero(),
                marginToVault: closePositionResp.marginToVault.addD(increasePositionResp.marginToVault)
            });
        }
        return positionResp;
    }

    function internalClosePosition(
        IExchange _exchange,
        address _trader,
        Decimal.decimal memory _quoteAssetAmountLimit,
        bool _skipFluctuationCheck
    ) private returns (PositionResp memory positionResp) {
        // check conditions
        Position memory oldPosition = getUnadjustedPosition(_exchange, _trader);
        SignedDecimal.signedDecimal memory oldPositionSize = oldPosition.size;
        requirePositionSize(oldPositionSize);

        (, SignedDecimal.signedDecimal memory unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(
            _exchange,
            _trader,
            PnlCalcOption.SPOT_PRICE
        );

        ISakePerpState.RemainMarginInfo memory remainMarginInfo = sakePerpState
        .calcRemainMarginWithFundingPaymentAndOvernightFee(_exchange, oldPosition, unrealizedPnl);

        positionResp.exchangedPositionSize = oldPositionSize.mulScalar(-1);
        positionResp.realizedPnl = unrealizedPnl;
        positionResp.badDebt = remainMarginInfo.badDebt;
        positionResp.fundingPayment = remainMarginInfo.fundingPayment;
        positionResp.overnightFee = remainMarginInfo.overnightFee;
        positionResp.marginToVault = MixedDecimal.fromDecimal(remainMarginInfo.remainMargin).mulScalar(-1);
        positionResp.exchangedQuoteAssetAmount = _exchange.swapOutput(
            oldPositionSize.toInt() > 0 ? IExchangeTypes.Dir.ADD_TO_AMM : IExchangeTypes.Dir.REMOVE_FROM_AMM,
            oldPositionSize.abs(),
            _quoteAssetAmountLimit,
            _skipFluctuationCheck
        );

        // bankrupt position's bad debt will be also consider as a part of the open interest
        sakePerpState.updateOpenInterestNotional(
            _exchange,
            unrealizedPnl.addD(remainMarginInfo.badDebt).addD(oldPosition.openNotional).mulScalar(-1)
        );
        clearPosition(_exchange, _trader);
    }

    function swapInput(
        IExchange _exchange,
        Side _side,
        Decimal.decimal memory _inputAmount,
        Decimal.decimal memory _minOutputAmount,
        bool _reverse
    ) internal returns (SignedDecimal.signedDecimal memory) {
        IExchangeTypes.Dir dir = (_side == Side.BUY)
            ? IExchangeTypes.Dir.ADD_TO_AMM
            : IExchangeTypes.Dir.REMOVE_FROM_AMM;
        SignedDecimal.signedDecimal memory outputAmount = MixedDecimal.fromDecimal(
            _exchange.swapInput(dir, _inputAmount, _minOutputAmount, _reverse)
        );
        if (IExchangeTypes.Dir.REMOVE_FROM_AMM == dir) {
            return outputAmount.mulScalar(-1);
        }
        return outputAmount;
    }

    function transferFee(
        address _from,
        IExchange _exchange,
        Decimal.decimal memory _positionNotional
    ) internal returns (Decimal.decimal memory) {
        Decimal.decimal memory fee = _exchange.calcFee(_positionNotional);
        if (fee.toUint() > 0) {
            address insuranceFundAddress = address(systemSettings.getInsuranceFund(_exchange));
            require(insuranceFundAddress != address(0), "Invalid InsuranceFund");
            Decimal.decimal memory insuranceFundFee = fee.mulD(systemSettings.insuranceFundFeeRatio());
            IERC20Upgradeable(_exchange.quoteAsset()).safeTransferFrom(
                _from,
                address(insuranceFundAddress),
                insuranceFundFee.toUint()
            );
            Decimal.decimal memory lpFee = fee.subD(insuranceFundFee);
            IERC20Upgradeable(_exchange.quoteAsset()).safeTransferFrom(_from, address(sakePerpVault), lpFee.toUint());
            sakePerpVault.addCachedLiquidity(address(_exchange), lpFee);
            return fee;
        }

        return Decimal.zero();
    }

    function withdraw(
        IExchange _exchange,
        address _receiver,
        Decimal.decimal memory _amount
    ) internal {
        return sakePerpVault.withdraw(_exchange, _receiver, _amount);
    }

    function realizeBadDebt(IExchange _exchange, Decimal.decimal memory _badDebt) internal {
        return sakePerpVault.realizeBadDebt(_exchange, _badDebt);
    }

    function transferToInsuranceFund(IExchange _exchange, Decimal.decimal memory _amount) internal {
        IInsuranceFund insuranceFund = systemSettings.getInsuranceFund(_exchange);
        sakePerpVault.withdraw(_exchange, address(insuranceFund), _amount);
    }

    function handleFundingFeeAndOvernightFee(
        IExchange _exchange,
        Decimal.decimal memory _fee,
        Decimal.decimal memory _insuranceFundRatio
    ) internal {
        address insuranceFundAddress = address(systemSettings.getInsuranceFund(_exchange));
        require(insuranceFundAddress != address(0), "Invalid InsuranceFund");
        Decimal.decimal memory insuranceFundFee = _fee.mulD(_insuranceFundRatio);
        sakePerpVault.withdraw(_exchange, insuranceFundAddress, insuranceFundFee);
        Decimal.decimal memory vaultFee = _fee.subD(insuranceFundFee);
        sakePerpVault.addCachedLiquidity(address(_exchange), vaultFee);
    }

    //
    // INTERNAL VIEW FUNCTIONS
    //

    function adjustPositionForLiquidityChanged(IExchange _exchange, address _trader)
        internal
        returns (Position memory)
    {
        Position memory unadjustedPosition = getUnadjustedPosition(_exchange, _trader);
        if (unadjustedPosition.size.toInt() == 0) {
            return unadjustedPosition;
        }
        uint256 latestLiquidityIndex = _exchange.getLiquidityHistoryLength().sub(1);
        if (unadjustedPosition.liquidityHistoryIndex == latestLiquidityIndex) {
            return unadjustedPosition;
        }

        Position memory adjustedPosition = sakePerpState.calcPositionAfterLiquidityMigration(
            _exchange,
            unadjustedPosition,
            latestLiquidityIndex
        );
        SignedDecimal.signedDecimal memory oldAdjustedPosition = sakePerpState
        .calcPositionAfterLiquidityMigrationWithoutNew(_exchange, unadjustedPosition, latestLiquidityIndex);
        _exchange.adjustTotalPosition(adjustedPosition.size, oldAdjustedPosition);

        setPosition(_exchange, _trader, adjustedPosition);
        emit PositionAdjusted(
            address(_exchange),
            _trader,
            adjustedPosition.size.toInt(),
            unadjustedPosition.liquidityHistoryIndex,
            adjustedPosition.liquidityHistoryIndex
        );
        return adjustedPosition;
    }

    function getUnadjustedPosition(IExchange _exchange, address _trader)
        public
        view
        override
        returns (Position memory position)
    {
        position = exchangeMap[address(_exchange)].positionMap[_trader];
    }

    //
    // REQUIRE FUNCTIONS
    //
    function requireExchange(IExchange _exchange, bool _open) private view {
        require(systemSettings.isExistedExchange(_exchange), "exchange not found");
        require(_open == _exchange.open(), _open ? "exchange was closed" : "exchange is open");
    }

    function requireNonZeroInput(Decimal.decimal memory _decimal) private pure {
        require(_decimal.toUint() != 0, "input is 0");
    }

    function requirePositionSize(SignedDecimal.signedDecimal memory _size) private pure {
        require(_size.toInt() != 0, "positionSize is 0");
    }

    function requireNotRestrictionMode(IExchange _exchange) private view {
        uint256 currentBlock = _blockNumber();
        if (currentBlock == exchangeMap[address(_exchange)].lastRestrictionBlock) {
            require(
                getUnadjustedPosition(_exchange, msg.sender).blockNumber != currentBlock,
                "only one action allowed"
            );
        }
    }

    function requireMoreMarginRatio(
        SignedDecimal.signedDecimal memory _marginRatio,
        Decimal.decimal memory _baseMarginRatio,
        bool _largerThanOrEqualTo
    ) private pure {
        int256 remainingMarginRatio = _marginRatio.subD(_baseMarginRatio).toInt();
        require(
            _largerThanOrEqualTo ? remainingMarginRatio >= 0 : remainingMarginRatio < 0,
            "Margin ratio not meet criteria"
        );
    }

    //
    // Set System Open Flag
    //
    function pause(bool _pause) public onlyOwner {
        paused = _pause;
    }

    function setInitialFundingRate(IExchange _exchange) public onlyOwner {
        SignedDecimal.signedDecimal memory premium = getLatestCumulativePremiumFraction(_exchange);
        exchangeMap[address(_exchange)].cumulativePremiumFractionsForLong.push(premium);
        exchangeMap[address(_exchange)].cumulativePremiumFractionsForShort.push(premium);
    }
}