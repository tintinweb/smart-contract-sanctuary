pragma solidity ^0.8.0;


import "../common/variables.sol";
import "./events.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Internals is Variables, Events {
    using SafeMath for uint;

    uint internal constant secondsInYear = 31536000;
    uint internal constant _kink = 8000;
    uint internal constant _kinkTwo = 9500;
    // to calculate supply rate after deducting fee. 9000 = 90% of interest should go to user. Hence, 10% goes to protocol.
    uint internal constant _supplyAfterFee = 9000; // 9000 = 9000 BPS = 90%


    // y is rate & x is utilization from 0 to 1. 0.05 * 1e4 = 5% with 4 decimals
    // Formula: y = (0.0375x + 0.01) * 1e18 / secondsInYear.
    // At x = 0 (0%), y = 0.01 (1%); x = 0.8 (80%), y = 0.04 (4%)
    function rateCal(uint utilization_) internal pure returns (uint rate_) {
        rate_ = uint(1189117199).mul(utilization_).div(10000).add(317097919);
    }

    // y is rate & x is utilization from 0 to 1. 0.2 * 1e4 = 20% with 4 decimals
    // Will come into play at kink. 
    // Formula: y = (1.066x - 0.8133) * 1e18 / secondsInYear.
    // At x = 0.8 (80%), y = 0.04 (4%); x = 0.95 (95%), y = 0.2 (20%)
    function jumpRateCal(uint utilization_) internal pure returns (uint rate_) {
        rate_ = uint(33834348046).mul(utilization_).div(10000).sub(25789573820);
    }

    // y is rate & x is utilization from 0 to 1. 0.8 * 1e4 = 80% with 4 decimals
    // Will come into play at kinkTwo.
    // Formula: y = (16x - 15) * 1e18 / secondsInYear.
    // At x = 0.95 (95%), y = 0.2 (20%); x = 1 (100%), y = 1 (100%)
    function jumpRateTwoCal(uint utilization_) internal pure returns (uint rate_) {
        rate_ = uint(507356671740).mul(utilization_).div(10000).sub(475646879756);
    }

    /**
    * @dev Calculates new supply & borrow rate from utilization
    * @param utilization_ totalBorrow / totalSupply. 1e18 = 100% utilization
    * @return supplyRate_ supply rate for that particular token
    * @return borrowRate_ borrow rate for that particular token
    */
    function calRateFromUtilization(uint utilization_) internal pure returns (uint supplyRate_, uint borrowRate_) {
        uint rate_;
        if (utilization_ < _kink) {
            rate_ = rateCal(utilization_);
        } else if (utilization_ < _kinkTwo) {
            rate_ = jumpRateCal(utilization_);
        } else {
            rate_ = jumpRateTwoCal(utilization_);
        }
        supplyRate_ = rate_.mul(_supplyAfterFee).mul(utilization_).div(10000).div(10000);
        borrowRate_ = rate_;
    }

    // /**
    // * @dev Updates interest for a particular protocol. msg.sender is protocol
    // * @param token_ address of token for which interest needs to be updated.
    // * @return newSupplyExchangePrice new supply exchange price
    // * @return newBorrowExchangePrice new borrow exchange price
    // * @return totalSupply_ overall system total supply after adding interest
    // * @return totalBorrow_ overall system total borrow after adding interest
    // * @return totalProtocolSupply_ protocol's total supply after adding interest
    // * @return totalProtocolBorrow_ protocol's total borrow after adding interest
    // */
    function updateInterest(
        address token_
    ) public view returns (
        uint newSupplyExchangePrice,
        uint newBorrowExchangePrice
    ) {
        // TODO: consider initializing exchange price whenever a new token is deposited for the first time.
        Rates memory curRate_ = _rate[token_];
        if (curRate_.lastUpdateTime == 0) {
            newSupplyExchangePrice = initialExchangePrice;
            newBorrowExchangePrice = initialExchangePrice;
        } else {
            (uint supplyRate_, uint borrowRate_) = calRateFromUtilization(curRate_.utilization);
            uint timePassed_ = block.timestamp - curRate_.lastUpdateTime;
            uint lastSupplyExchangePrice_ = curRate_.lastSupplyExchangePrice;
            uint lastBorrowExchangePrice_ = curRate_.lastBorrowExchangePrice;
            newSupplyExchangePrice = lastSupplyExchangePrice_.add(
                lastSupplyExchangePrice_.mul(supplyRate_).mul(timePassed_).div(1e18)
                );
            newBorrowExchangePrice = lastBorrowExchangePrice_.add(
                lastBorrowExchangePrice_.mul(borrowRate_).mul(timePassed_).div(1e18)
                );
        }
    }

    struct liquidityVariables {
        uint totalSupply;
        uint totalBorrow;
        uint totalProtocolSupply;
        uint totalProtocolBorrow;
    }

    /**
    * @dev Updates core storage variables. 
    * _rawSupply, _rawBorrow, _protocolRawSupply, _protocolRawBorrow, _rate.
    * msg.sender is protocol.
    * @param token_ token to update
    * @param supplyAmount supply amount (+ve deposit, -ve withdrawing)
    * @param borrowAmount borrow amount (+ve borrow, -ve payback)
    * @return newSupplyRate_ new supply rate of overall system and that protocol.
    * @return newBorrowRate_ new borrow rate of overall system and that protocol.
    * @return newSupplyExchangePrice_ new borrow rate of overall system and that protocol.
    * @return newBorrowExchangePrice_ new borrow rate of overall system and that protocol.
    */
    function updateStorage(
        address token_,
        int supplyAmount,
        int borrowAmount
    ) internal returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    ) {
        // require(totalSupply_ > totalBorrow_, "borrow-exceeds-supply");
        (newSupplyExchangePrice_, newBorrowExchangePrice_) = updateInterest(token_);
        liquidityVariables memory v_;
        if (supplyAmount > 0) {
            uint newRawSupply_ = uint(supplyAmount).mul(1e18).div(newSupplyExchangePrice_);
            _rawSupply[token_] += newRawSupply_;
            // TODO: Verify if this works
            v_.totalProtocolSupply = (_protocolRawSupply[msg.sender][token_] += newRawSupply_);
            v_.totalProtocolSupply = v_.totalProtocolSupply.mul(newSupplyExchangePrice_).div(1e18);
            require(_protocolSupplyLimits[msg.sender][token_] > v_.totalProtocolSupply, "supply-limit-exceeded");
        } else if (supplyAmount < 0) {
            uint newRawSupply_ = uint(-supplyAmount).mul(1e18).div(newSupplyExchangePrice_);
            _rawSupply[token_] -= newRawSupply_;
            // TODO: Verify if this works
            v_.totalProtocolSupply = (_protocolRawSupply[msg.sender][token_] -= newRawSupply_);
            v_.totalProtocolSupply = v_.totalProtocolSupply.mul(newSupplyExchangePrice_).div(1e18);
        }
        if (borrowAmount > 0) {
            uint newRawBorrow_ = uint(borrowAmount).mul(1e18).div(newBorrowExchangePrice_);
            _rawBorrow[token_] += newRawBorrow_;
            // TODO: Verify if this works
            v_.totalProtocolBorrow = (_protocolRawBorrow[msg.sender][token_] += newRawBorrow_);
            v_.totalProtocolBorrow = v_.totalProtocolBorrow.mul(newBorrowExchangePrice_).div(1e18);
            require(_protocolBorrowLimits[msg.sender][token_] > v_.totalProtocolBorrow, "borrow-limit-exceeded");
        } else if (borrowAmount < 0) {
            uint newRawBorrow_ = uint(-borrowAmount).mul(1e18).div(newBorrowExchangePrice_);
            _rawBorrow[token_] -= newRawBorrow_;
            // TODO: Verify if this works
            v_.totalProtocolBorrow = (_protocolRawBorrow[msg.sender][token_] -= newRawBorrow_);
            v_.totalProtocolBorrow = v_.totalProtocolBorrow.mul(newBorrowExchangePrice_).div(1e18);
        }
        v_.totalSupply = _rawSupply[token_].mul(newSupplyExchangePrice_).div(1e18);
        v_.totalBorrow = _rawBorrow[token_].mul(newBorrowExchangePrice_).div(1e18);
        uint utilization_ = v_.totalBorrow.mul(10000).div(v_.totalSupply);
        // TODO: do we need this?
        (newSupplyRate_, newBorrowRate_) = calRateFromUtilization(utilization_);
        _rate[token_] = Rates(uint96(newSupplyExchangePrice_), uint96(newBorrowExchangePrice_), uint48(block.timestamp), uint16(utilization_));
        emit updateStorageLog(
            v_.totalSupply,
            v_.totalBorrow,
            v_.totalProtocolSupply,
            v_.totalProtocolBorrow,
            token_,
            msg.sender,
            newSupplyRate_,
            newBorrowRate_
        );
    }

    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

}

contract ProtocolModule is Internals {

    using SafeERC20 for IERC20;

    // checks if it's a protocol
    modifier isProtocolMod(address protocol_) {
        require(_isProtocol[protocol_], "not-a-protocol");
        _;
    }

    /**
    * @dev protocol supplying token to the liquidity contract.
    * @param token_ address of token.
    * @param amount_ amount of token.
    * @return newSupplyRate_ new supply rate of overall system and that protocol.
    * @return newBorrowRate_ new borrow rate of overall system and that protocol.
    */
    function supply(
        address token_,
        uint amount_
    ) public nonReentrant isProtocolMod(msg.sender) returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    ) {
        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
        (
            newSupplyRate_,
            newBorrowRate_,
            newSupplyExchangePrice_,
            newBorrowExchangePrice_
        ) = updateStorage(token_, int(amount_), 0);
        emit supplyLog(msg.sender, token_, amount_);
    }

    /**
    * @dev protocol withdrawing token from the liquidity contract.
    * @param token_ address of token.
    * @param amount_ amount of token.
    * @return newSupplyRate_ new supply rate of overall system and that protocol.
    * @return newBorrowRate_ new borrow rate of overall system and that protocol.
    */
    function withdraw(
        address token_,
        uint amount_
    ) public nonReentrant isProtocolMod(msg.sender) returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    ) {
        (
            newSupplyRate_,
            newBorrowRate_,
            newSupplyExchangePrice_,
            newBorrowExchangePrice_
        ) = updateStorage(token_, -int(amount_), 0);
        IERC20(token_).safeTransfer(msg.sender, amount_);
        emit withdrawLog(msg.sender, token_, amount_);
    }

    /**
    * @dev protocol borrowing token from the liquidity contract.
    * @param token_ address of token.
    * @param amount_ amount of token.
    * @return newSupplyRate_ new supply rate of overall system and that protocol.
    * @return newBorrowRate_ new borrow rate of overall system and that protocol.
    */
    function borrow(
        address token_,
        uint amount_
    ) public nonReentrant isProtocolMod(msg.sender) returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    ) {
        (
            newSupplyRate_,
            newBorrowRate_,
            newSupplyExchangePrice_,
            newBorrowExchangePrice_
        ) = updateStorage(token_, 0, int(amount_));
        IERC20(token_).safeTransfer(msg.sender, amount_);
        emit borrowLog(msg.sender, token_, amount_);
    }

    /**
    * @dev protocol paying back token to the liquidity contract.
    * @param token_ address of token.
    * @param amount_ amount of token.
    * @return newSupplyRate_ new supply rate of overall system and that protocol.
    * @return newBorrowRate_ new borrow rate of overall system and that protocol.
    */
    function payback(
        address token_,
        uint amount_
    ) public nonReentrant isProtocolMod(msg.sender) returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    ) {
        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
        (
            newSupplyRate_,
            newBorrowRate_,
            newSupplyExchangePrice_,
            newBorrowExchangePrice_
        ) = updateStorage(token_, 0, -int(amount_));
        emit paybackLog(msg.sender, token_, amount_);
    }

}

pragma solidity ^0.8.0;


contract Variables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    // Addresses have access to interact with the liquidity contract
    mapping (address => bool) internal _isProtocol;

    // Protocol => token => uint. Tokens limits for supply for a particular protocol. uint = limit of tokens.
    mapping (address => mapping(address => uint)) internal _protocolSupplyLimits;
    // Protocol => token => uint. Tokens limits for borrow for a particular protocol. uint = limit of tokens.
    mapping (address => mapping(address => uint)) internal _protocolBorrowLimits;

    uint public constant initialExchangePrice = 1e18;
    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    // total Supply of a token in raw. raw = totalSupply / supplyExchangePrice.
    mapping (address => uint) internal _rawSupply;
    // total Borrow of a token in raw. raw = totalBorrow / borrowExchangePrice.
    mapping (address => uint) internal _rawBorrow;
    // total Supply of a token in a protocol in raw. raw = totalProtocolSupply / supplyExchangePrice.
    mapping (address => mapping(address => uint)) internal _protocolRawSupply;
    // total Borrow of a token in a protocol in raw. raw = totalProtocolBorrow / borrowExchangePrice.
    mapping (address => mapping(address => uint)) internal _protocolRawBorrow;
    // token rates going on. Rates are calculated using _totalSupply, _totalBorrow, utilization at the time of last interaction.
    mapping(address => Rates) internal _rate;

}

pragma solidity ^0.8.0;


contract Events {

    event updateStorageLog(
        uint totalSupply_,
        uint totalBorrow_,
        uint totalProtocolSupply_,
        uint totalProtocolBorrow_,
        address token_,
        address protocol_,
        uint newSupplyRate_,
        uint newBorrowRate_
    );

    event supplyLog(address protocol_, address token_, uint amount_);

    event withdrawLog(address protocol_, address token_, uint amount_);

    event borrowLog(address protocol_, address token_, uint amount_);

    event paybackLog(address protocol_, address token_, uint amount_);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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