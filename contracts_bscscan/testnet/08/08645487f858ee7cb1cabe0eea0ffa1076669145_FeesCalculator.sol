/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

// File: contracts\IFeesCalculator.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IFeesCalculator {

    function calculateFees(address lpToken, uint256 amount, uint256 unlockTime,
        uint8 paymentMode) external view returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee);

    function calculateIncreaseAmountFees(address lpToken, uint256 amount, uint256 unlockTime,
        uint8 paymentMode) external view returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee);

}

// File: @openzeppelin\contracts\math\SafeMath.sol

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts\FeesCalculator.sol
pragma solidity 0.7.6;




contract FeesCalculator is Ownable, IFeesCalculator {
    using SafeMath for uint256;

    uint256 public ethMin = 0.01 ether;
    uint256 public tokenMin = 4.5 ether;
    uint256 public ethMax = 23 ether;
    uint256 public tokenMax = 103.5 ether;
    uint256 public liquidityPercent = 30;

    uint8 public PAYMENT_MODE_BNB_LP_TOKEN = 0;
    uint8 public PAYMENT_MODE_CRX_LP_TOKEN = 1;
    uint8 public PAYMENT_MODE_BNB_MAX = 2;
    uint8 public PAYMENT_MODE_CRX_MAX = 3;

    event OnFeeChanged(
        uint256 ethMin,
        uint256 tokenMin,
        uint256 ethMax,
        uint256 tokenMax,
        uint256 liquidityPercent
    );

    /**
    * @notice Calculates lock fees based on input params
    * @param amount amount of tokens to lock
    * @param paymentMode    0 - pay fees in minBNB + LP token,
    *                       1 - pay fees in minCRX + LP token,
    *                       2 - pay fees fully in maxBNB,
    *                       3 - pay fees fully in maxCRX
    */
    function calculateFees(address /* lpToken */, uint256 amount, uint256 /* unlockTime */,
        uint8 paymentMode) external override view returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee)  {
        require (paymentMode <= 3, "INVALID PAYMENT METHOD");
        if (paymentMode == PAYMENT_MODE_BNB_LP_TOKEN) {
            return (ethMin, 0, liquidityPercent.mul(amount).div(1e4));
        }
        if (paymentMode == PAYMENT_MODE_CRX_LP_TOKEN) {
            return (0, tokenMin, liquidityPercent.mul(amount).div(1e4));
        }
        if (paymentMode == PAYMENT_MODE_BNB_MAX) {
            return (ethMax, 0, 0);
        }
        return (0, tokenMax, 0);
    }

    /**
    * @notice Calculates increase lock amount fees based on input params
    * @param amount amount of tokens to lock
    * @param paymentMode    0 - pay fees in minBNB + LP token,
    *                       1 - pay fees in minCRX + LP token,
    *                       2 - pay fees fully in maxBNB,
    *                       3 - pay fees fully in maxCRX
    */
    function calculateIncreaseAmountFees(address /* lpToken */, uint256 amount, uint256 /* unlockTime */,
        uint8 paymentMode) external override view returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee)  {
        require (paymentMode <= 3, "INVALID PAYMENT METHOD");
        if (paymentMode == PAYMENT_MODE_BNB_MAX) {
            return (ethMax, 0, 0);
        }
        if (paymentMode == PAYMENT_MODE_CRX_MAX) {
            return (0, tokenMax, 0);
        }
        return (0, 0, liquidityPercent.mul(amount).div(1e4));
    }

    function getFees() external view returns(uint256, uint256, uint256, uint256, uint256)  {
        return (ethMin, tokenMin, ethMax, tokenMax, liquidityPercent);
    }

    function setEthMin(uint256 _ethMin) external onlyOwner {
        ethMin = _ethMin;

        emit OnFeeChanged(ethMin, tokenMin, ethMax, tokenMax, liquidityPercent);
    }

    function setTokenMin(uint256 _tokenMin) external onlyOwner {
        tokenMin = _tokenMin;

        emit OnFeeChanged(ethMin, tokenMin, ethMax, tokenMax, liquidityPercent);
    }

    function setEthMax(uint256 _ethMax) external onlyOwner {
        ethMax = _ethMax;

        emit OnFeeChanged(ethMin, tokenMin, ethMax, tokenMax, liquidityPercent);
    }

    function setTokenMax(uint256 _tokenMax) external onlyOwner {
        tokenMax = _tokenMax;

        emit OnFeeChanged(ethMin, tokenMin, ethMax, tokenMax, liquidityPercent);
    }

    function setLiquidityPercent(uint256 _liquidityPercent) external onlyOwner {
        liquidityPercent = _liquidityPercent;

        emit OnFeeChanged(ethMin, tokenMin, ethMax, tokenMax, liquidityPercent);
    }

}