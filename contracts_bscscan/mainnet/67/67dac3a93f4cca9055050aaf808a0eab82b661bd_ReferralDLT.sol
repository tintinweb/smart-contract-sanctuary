/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-22
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// File: contracts/libs/IVaultReferral.sol

pragma solidity 0.6.12;

interface IVaultReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record harvest click count.
     */
    function recordHarvestCount(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
    /**
     * @dev Claim Referral Rewards.
     */
    function claim(address user) external view returns (uint256);
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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

// File: @openzeppelin/contracts/math/SafeMath.sol

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
// File: contracts/libs/SafeBEP20.sol

pragma solidity ^0.6.0;

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// File: contracts/libs/IBEP20.sol

pragma solidity >=0.4.0;

interface IBEP20 {
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

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
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

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
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

// File: contracts/VaultReferral.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract ReferralDLT is IVaultReferral, Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    using SafeMath for uint8;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    mapping(address => bool) public operators;
    mapping(address => address) private referrers; // user address => referrer address
    mapping(address => uint256) private registerTime;
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))) private currentDayCount;
    EnumerableSet.AddressSet private referralRecord;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => address))) private currentDayWinner; // Recorded current day winner for highest referral
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private currentDayWinnerRewards; // Recorded current day winner for highest referral
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))) private currentDayHarvestCount;
    EnumerableMap.UintToAddressMap private harvestRecord;

    uint8[2] public winningNumbers;
    uint8[2] public nullTickets = [0,0];

    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => address)))) private currentDayHarvestWinner; // Recorded current day for random harvest winner
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))) private currentDayHarvestRewards; // Recorded current day for random harvest winner
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions
    mapping(address => uint256) public totalRewards; // referrer address => total reward in BNB
    mapping(address => uint256) public totalUNA; // referrer address => total reward in UNA

    mapping(address => uint256) public checkInRecords;
    mapping(address => uint256) public checkBalanceRecords;

    uint256 public poolBalance;
    uint256 public tokenBalance;
    uint256 public nextHarvestAvailable = block.timestamp;
    uint256 public harvestInterval = 1800;
    uint256 private referralPercent = 10;
    uint256 private harvestPercent = 50;
    uint256 private harvestSharePercent = 30;

    // Lucky Draw ticket count
    uint256 private checkInTicket = 1;
    uint256 private checkBalanceTicket = 5;
    uint256 private amateurTicket = 2;
    uint256 private intermediateTicket = 11;
    uint256 private expertTicket = 60;
    // Referral ticket count
    uint256 private amateurUNA = 1000 * 10**9;
    uint256 private intermediateUNA = 10000 * 10**9;
    uint256 private expertUNA = 50000 * 10**9;
    uint256 private amateurUplineTicket = 1;
    uint256 private intermediateUplineTicket = 3;
    uint256 private expertUplineTicket = 15;

    uint256 public minTokenHold = 1 * 10**9;
    uint256 public ratio = 70;
    uint256 private reservedRatio = 30;

    uint256 private levelGift = 1;
    uint8[5] private levelGiftRatio = [30,20,10,5,5];

    address public UNA = 0x7AA509D7761e35bf43B6AeB144480A19d0FEb851;
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IPancakeRouter02 public uniswapV2Router;
    address public uniswapV2Pair;

    event ReferralRecorded(address indexed user, address indexed referrer);
    event HarvestRecorded(address indexed user, uint256 harvestTime);
    event ReferralCommissionRecorded(address indexed referrer, uint256 commission);
    event RewardsRecorded(address indexed referrer, uint256 commission);
    event RewardsTokenRecorded(address indexed referrer, uint256 commission);
    event OperatorUpdated(address indexed operator, bool indexed status);

    constructor() public{
        operators[msg.sender] = true;
        transferOwnership(msg.sender);
    }

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    modifier onlyCommssion {
        require(totalRewards[msg.sender] > 0, "Commission is zero！");
        _;
    }

    modifier onlyToken {
        require(totalUNA[msg.sender] > 0, "Commission is zero！");
        _;
    }

    modifier onlyUser {
        require(msg.sender != address(0),'Invalid user address!');
        _;
    }

    modifier whenNotPaused {
        require(address(this).balance > 0,'Insufficient contract balance!');
        _;
    }

    modifier whenTokenNotPaused {
        require(IBEP20(UNA).balanceOf(address(this)) > 0,'Insufficient contract balance!');
        _;
    }
    
    modifier whenTokenAvail {
        require(IBEP20(UNA).balanceOf(msg.sender) > minTokenHold,'Insufficient UNA balance!');
        _;
    }

    receive() external payable {
        if(msg.value > 0){
            poolBalance = poolBalance.add(msg.value);
        }else{
            tokenBalance = IBEP20(UNA).balanceOf(address(this));
        }
    }
    /// @dev Tested for user daily check in
    function checkIn(address _user) public {
        /// @dev Check in daily to increase Lucky draw ticket +1
        require(BokkyPooBahsDateTimeLibrary.getDay(checkInRecords[_user]) < BokkyPooBahsDateTimeLibrary.getDay(block.timestamp),'No available for check in yet!');
        address _referrer;
        if(getReferrer(_user) == address(0)){
            _referrer = address(this);
        }else{
            _referrer = getReferrer(_user);
        }
        for(uint256 i = 0; i < checkInTicket; i++){
            getLuckyTicket(_user, _referrer);
        }
        checkInRecords[_user] = block.timestamp;
    }
    /// @dev Tested for user daily check balance for ticket claim
    function checkBalance(address _user) public {
        /// @dev Sync UNA balance daily to increase Lucky draw ticket +5
        require(BokkyPooBahsDateTimeLibrary.getDay(checkBalanceRecords[_user]) < BokkyPooBahsDateTimeLibrary.getDay(block.timestamp),'No available for ticket claim yet!');
        address _referrer;
        if(getReferrer(_user) == address(0)){
            _referrer = address(this);
        }else{
            _referrer = getReferrer(_user);
        }
        for(uint256 i = 0; i < checkBalanceTicket; i++){
            getLuckyTicket(_user, _referrer);
        }
        checkBalanceRecords[_user] = block.timestamp;
    }

    /// @dev Contribute UNA daily to increase Lucky draw ticket & referral ticket
    function contributeUNA(address _user, uint256 _amount) public {
        require(IBEP20(UNA).balanceOf(_user) >= _amount,'Insufficient balance!');
        IBEP20(UNA).safeTransferFrom(_user,address(this),_amount);
        address _referrer = getReferrer(_user);
        uint256 count = 0;
        if(_referrer != address(0)){
            multiLevelGift(_referrer, _amount,count);
        }
        updateTokenBalance(_amount.mul(reservedRatio).div(100));
        uint256 luckyCount = _amount == amateurUNA ? amateurTicket : _amount == intermediateUNA ? intermediateTicket : _amount >= expertUNA ? expertTicket : 0;
        uint256 referralCount = _amount == amateurUNA ? amateurUplineTicket : _amount == intermediateUNA ? intermediateUplineTicket : _amount >= expertUNA ? expertUplineTicket : 0;
        for(uint256 i = 0; i < luckyCount; i++){
            getLuckyTicket(_user, _referrer);
        }
        for(uint256 i = 0; i < referralCount; i++){
            getReferralTicket(_user, _referrer);
        }
    }
    /// @dev tested
    function multiLevelGift(address _referrer, uint256 _amount,uint256 _count) internal {
        if(_count <= levelGift){
            recordTokenRewards(_referrer,_amount.mul(_count == 0 && levelGift == 1 ? ratio : levelGiftRatio[_count]).div(100));
            _count += 1;
            if(getReferrer(_referrer) != address(0) && _count <= levelGift){
                multiLevelGift(getReferrer(_referrer),_amount,_count);
            }
        }
    }

    function getLuckyTicket(address _user, address _referrer) internal {
        require(_user != _referrer,'Referral address invalid');
        if(_referrer == address(0)){
            _referrer = address(this);
        }
        if (_user != address(0)
            && _referrer != address(0)
            && referrers[_user] == address(0)
            && referrers[_referrer]!= _user
        ) {
            referrers[_user] = _referrer;
            registerTime[_user] = block.timestamp;
            referralsCount[_referrer] += 1;
            if(registerTime[_referrer] == 0){
                registerTime[_referrer] = block.timestamp;
            }
            if(referralRecord.length() > 0){
                if(currentDayCount[_referrer][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] > currentDayCount[referralRecord.at(0)][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)]){
                    removeReferralEnumAddress();
                    referralRecord.add(_referrer);
                }
            }else{
                referralRecord.add(_referrer);
            }
            emit ReferralRecorded(_user, _referrer);
        }
        currentDayHarvestCount[_user][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] += 1;
        harvestRecord.set(harvestRecord.length()+1, _user);
    }

    function getReferralTicket(address _user, address _referrer) internal {
        require(_user != _referrer,'Referral address invalid');
        require(getReferrer(_user) == _referrer,'Upline address incorrect!');
        currentDayCount[_referrer][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] += 1;
        if(referralRecord.length() > 0){
            if(currentDayCount[_referrer][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] > currentDayCount[referralRecord.at(0)][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)]){
                removeReferralEnumAddress();
                referralRecord.add(_referrer);
            }
        }else{
            referralRecord.add(_referrer);
        }
    }

    function recordReferral(address _user, address _referrer) public override onlyOperator {
        require(_user != _referrer,'Referral address invalid');
        if (_user != address(0)
            && _referrer != address(0)
            && referrers[_user] == address(0)
            && referrers[_referrer] != _user
        ) {
            referrers[_user] = _referrer;
            registerTime[_user] = block.timestamp;
            referralsCount[_referrer] += 1;
            if(registerTime[_referrer] == 0){
                registerTime[_referrer] = block.timestamp;
            }
            if(referralRecord.length() > 0){
                if(currentDayCount[_referrer][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] > currentDayCount[referralRecord.at(0)][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)]){
                    removeReferralEnumAddress();
                    referralRecord.add(_referrer);
                }
            }else{
                referralRecord.add(_referrer);
            }
            emit ReferralRecorded(_user, _referrer);
        }else{
            require(referrers[_user] == address(0),'Referral record exists!');
        }
    }

    function recordHarvestCount(address _user, address _referrer) public override onlyOperator {
        require(_user != _referrer,'Referral address invalid');
        // require(block.timestamp >= nextHarvestAvailable,'Next harvest time not available yet!');
        if (_user != address(0)
            && _referrer != address(0)
            && referrers[_user] == address(0)
            && referrers[_referrer] != _user
        ) {
            recordReferral(_user,_referrer);
        }
        currentDayHarvestCount[_user][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] += 1;
        harvestRecord.set(harvestRecord.length()+1, _user);
        resetHarvestTime();
        emit HarvestRecorded(_user, block.timestamp);
    }

    function resetHarvestTime() internal {
        nextHarvestAvailable = nextHarvestAvailable.add(harvestInterval);
    }

    function drawNow() public onlyOperator{
        // uint256 yesterday = BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)- 1;
        require(currentDayWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] == address(0),'Already concluded highest referral winner!');
        require(currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][0] == address(0),'Already concluded first harvest winner!');
        require(currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][1] == address(0),'Already concluded second harvest winner!');
        uint256 referralCount = currentDayCount[referralRecord.at(0)][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)];
        uint256 commission = address(this).balance.mul(referralPercent).div(100);
        if(referralCount >= 1){
            currentDayWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] = referralRecord.at(0);
            currentDayWinnerRewards[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] = commission;
            recordBNBRewards(referralRecord.at(0),commission);
            removeReferralEnumAddress();
        }else{
            commission = 0;
            removeReferralEnumAddress();
        }
        if(harvestRecord.length() > 0){
            randomizedIndex(harvestRecord.length());
            uint256 harvestCommission = address(this).balance.mul(harvestPercent).div(1000);
            uint256 harvestShare = harvestCommission.mul(harvestSharePercent).div(100);
            currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][0] = readEnum(uint256(winningNumbers[0]));
            currentDayHarvestRewards[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][0] = harvestCommission;
            if(winningNumbers[1] != winningNumbers[0]){
                currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][1] = readEnum(uint256(winningNumbers[1]));
                currentDayHarvestRewards[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][1] = harvestCommission;
                recordBNBRewards(readEnum(uint256(winningNumbers[1])),harvestCommission);
                recordBNBRewards(getReferrer(readEnum(uint256(winningNumbers[1]))) == address(0) ? address(this) : getReferrer(readEnum(uint256(winningNumbers[1]))),harvestShare);
            }
            recordBNBRewards(readEnum(uint256(winningNumbers[0])),harvestCommission);
            recordBNBRewards(getReferrer(readEnum(uint256(winningNumbers[0]))) == address(0) ? address(this) : getReferrer(readEnum(uint256(winningNumbers[0]))),harvestShare);
            for(uint i = 1; i <= harvestRecord.length(); i++) {
                removeEnumAddress(i);
            }
            updatePoolBalance((harvestCommission.mul(2)).add(harvestShare.mul(2)));
        }
        updatePoolBalance(commission);
    }
    /// @dev To read current day or yesterday referral winner
    function readReferralWinner() public view returns (address){
        uint256 yesterday = BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)- 1;
        return currentDayWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] != address(0) ? currentDayWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)] : currentDayWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][yesterday];
    }
    /// @dev To read current day or yesterday harvest winner
    function readHarvestWinner() public view returns (address[] memory){
        address[] memory winners = new address[](2);
        uint256 yesterday = BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)- 1;
        winners[0] = currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][0] != address(0) ? currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][0] : currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][yesterday][0];
        winners[1] = currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][1] != address(0) ? currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][1] : currentDayHarvestWinner[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][yesterday][1];
        
        return winners;
    }
    /// @dev To randomly pick two winners
    function randomizedIndex(uint256 _externalRandomNumber) internal {
        winningNumbers = nullTickets;
        bytes32 _structHash;
        uint256 _randomNumber;
        uint8 _maxNumber = uint8(harvestRecord.length());
        bytes32 _blockhash = blockhash(block.number-1);
        uint256 _gasleft = gasleft();
        // 1
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                uint256(harvestRecord.length()),
                _gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[0]=uint8(_randomNumber);
        // 2
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                poolBalance,
                _gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[1]=uint8(_randomNumber);
    }
    /// @dev To read address from each harvest record
    function readEnum(uint256 key) internal view returns(address){
        return harvestRecord.get(key);
    }
    /// @dev To read harvest record length
    function readHarvestLength() public view returns(uint256){
        return harvestRecord.length();
    }
    /// @dev To remove harvest record after daily lucky draw
    function removeEnumAddress(uint256 key) internal returns(bool){
        return harvestRecord.remove(key);
    }
    /// @dev To read current highest address with highest referral ticket
    function readReferralEnum(uint256 key) public view returns(address){
        return referralRecord.at(key);
    }
    /// @dev To remove referral record daily after each draw
    function removeReferralEnumAddress() internal returns(bool){
        return referralRecord.remove(readReferralEnum(0));
    }
    /// @dev To record referral LP Commission
    function recordReferralCommission(address _referrer, uint256 _commission) public override onlyOperator {
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }
    /// @dev To record BNB rewards
    function recordBNBRewards(address _referrer, uint256 _commission) internal {
        if (_referrer != address(0) && _commission > 0) {
            totalRewards[_referrer] += _commission;
            emit RewardsRecorded(_referrer, _commission);
        }
    }
    /// @dev To record token rewards
    function recordTokenRewards(address _referrer, uint256 _commission) internal {
        if (_referrer != address(0) && _commission > 0) {
            totalUNA[_referrer] += _commission;
            emit RewardsTokenRecorded(_referrer, _commission);
        }
    }
    /// @dev To set minimum UNA token required
    function setMinTokenHold(uint256 _amount) public onlyOperator {
        minTokenHold = _amount * 10 ** 9;
    }
    /// @dev To set number of level, Maximum 5
    function setLevelGift(uint256 _levelgift) public onlyOperator {
        require(_levelgift <6,'Level overflow!');
        levelGift = _levelgift;
    }
    /// @dev To set each level of ratio
    function setLevelGiftRatio(uint8[] memory _levelgiftratio) public onlyOperator {
        for(uint8 i = 0; i < levelGiftRatio.length;i++){
            levelGiftRatio[i] = _levelgiftratio[i];
        }
    }
    function readRewardHistory(uint256 timenow) public view returns (uint256,uint256){
        return (currentDayWinnerRewards[BokkyPooBahsDateTimeLibrary.getYear(timenow)][BokkyPooBahsDateTimeLibrary.getMonth(timenow)][BokkyPooBahsDateTimeLibrary.getDay(timenow)],currentDayHarvestRewards[BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)][0]);
    }
    /// @dev Return countdown time left for next Check in tested
    function checkInCountdown(address _user) public view returns(uint256){
        uint256 yesterday = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(checkInRecords[_user]),BokkyPooBahsDateTimeLibrary.getMonth(checkInRecords[_user]),BokkyPooBahsDateTimeLibrary.getDay(checkInRecords[_user]));
        uint256 nextDay = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(checkInRecords[_user]),BokkyPooBahsDateTimeLibrary.getMonth(checkInRecords[_user]),BokkyPooBahsDateTimeLibrary.getDay(checkInRecords[_user]) + 1);
        return nextDay > yesterday && yesterday > 0 ? nextDay.sub(block.timestamp) : 0;
    }
    /// @dev Return countdown time left for next balance check in tested
    function checkInBalanceCountdown(address _user) public view returns(uint256){
        uint256 yesterday = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(checkBalanceRecords[_user]),BokkyPooBahsDateTimeLibrary.getMonth(checkBalanceRecords[_user]),BokkyPooBahsDateTimeLibrary.getDay(checkBalanceRecords[_user]));
        uint256 nextDay = BokkyPooBahsDateTimeLibrary.timestampFromDate(BokkyPooBahsDateTimeLibrary.getYear(checkBalanceRecords[_user]),BokkyPooBahsDateTimeLibrary.getMonth(checkBalanceRecords[_user]),BokkyPooBahsDateTimeLibrary.getDay(checkBalanceRecords[_user]) + 1);
        return nextDay > yesterday && yesterday > 0 ? nextDay.sub(block.timestamp) : 0;
    }
    /// @dev To set UNA token address in the token
    function setUNA(address _una) public onlyOperator {
        UNA = _una;
    }
    /// @dev Set BNB address of the current chain
    function setBNB(address _wbnb) public onlyOperator {
        WBNB = _wbnb;
    }
    /// @dev To set ratio 
    function setRatio(uint256 _ratio) public onlyOperator {
        ratio = _ratio;
    }
    /// @dev To set reserved ratio 
    function setReservedRatio(uint256 _reservedRatio) public onlyOperator {
        reservedRatio = _reservedRatio;
    }
    /// @dev To update BNB pool balance
    function updatePoolBalance(uint256 _poolBalance) public {
        poolBalance = poolBalance.sub(_poolBalance);
    }
    /// @dev To update token available balance
    function updateTokenBalance(uint256 _tokenBalance) public {
        tokenBalance = tokenBalance.add(_tokenBalance);
    }
    /// @dev To return the claimable amount of token by user from Vault
    function claim(address _user) public view override onlyUser returns (uint256) {
        require(totalRewards[_user] > 0,'No available commission to claim!');
        return totalRewards[_user];
    }
    /// @dev Get the referrer address that referred the user
    function getReferrer(address _user) public override view returns (address) {
        return referrers[_user];
    }
    /// @dev Get the register time of the user
    function getRegisterTime(address _user) public view returns (uint256) {
        return registerTime[_user];
    }
    /// @dev To get current day Referral Ticket Count
    function getReferralCountDaily(address _user) public view returns (uint256){
        return currentDayCount[_user][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)];
    }
    /// @dev To get current day Lucky Ticket Count
    function getHarvestCountDaily(address _user) public view returns (uint256){
        return currentDayHarvestCount[_user][BokkyPooBahsDateTimeLibrary.getYear(block.timestamp)][BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp)][BokkyPooBahsDateTimeLibrary.getDay(block.timestamp)];
    }
    /// @dev Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }
    /// @dev Owner can withdraw tokens that are sent here by mistake
    function depriveBEP20Token(IBEP20 _token, uint256 _amount, address _to) external onlyOperator {
        if(_token.balanceOf(address(this)) > 0){
            _token.safeTransfer(_to, _amount);
        }else{
           msg.sender.transfer(_amount);
        }
    }
    /// @dev For user to withdraw their referral and Lucky Draw rewards
    function withdrawBNBRewards() public payable onlyCommssion onlyUser whenNotPaused whenTokenAvail{
        msg.sender.transfer(totalRewards[msg.sender]);
        totalRewards[msg.sender] = 0;
    }

    /// @dev For user to withdraw their contribution token rewards
    function withdrawTokenRewards() public onlyToken onlyUser whenTokenNotPaused whenTokenAvail{
        IBEP20(UNA).approve(address(this), totalUNA[msg.sender]);
        IBEP20(UNA).transfer(msg.sender,totalUNA[msg.sender]);
        tokenBalance = tokenBalance.sub(totalUNA[msg.sender]);
        totalUNA[msg.sender] = 0;
    }
    /// @dev For Operator to swap additional token to BNB to increase the pool of contract
    function swapTokensForBNB(uint256 tokenAmount) public onlyOperator{
        require(IBEP20(UNA).balanceOf(address(this)) > 0 && tokenAmount > 0,'Insufficient Balance of Token!');
        address[] memory path = new address[](2);
        path[0] = address(UNA);
        path[1] = uniswapV2Router.WETH();

        IBEP20(UNA).approve(address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    /// @dev For Operator to initialize with router of UNA token
    function initialized(address _router) public onlyOperator{
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(_router);
        IPancakeFactory factory = IPancakeFactory(_uniswapV2Router.factory());
        address swapPair = factory.getPair(UNA,WBNB);
        uniswapV2Pair = swapPair;

        uniswapV2Router = _uniswapV2Router;
    }
    /// @dev For Operator to deposit BNB into contract for Lucky Draw
    function depositToContract() public payable onlyOperator{
        poolBalance = poolBalance.add(msg.value);
    }
    /// @dev Promotional function to airdrop ticket to particular address
    function airdropLuckyTicket(address _user,uint256 _ticket) public onlyOperator{
        address _referrer = getReferrer(_user);
        for(uint256 i=0 ; i<_ticket; i++) {
            getLuckyTicket(_user, _referrer);
        }
    }
    /// @dev Promotional function to airdrop referral ticket to particular address
    function airdropReferTicket(address _user,uint256 _ticket) public onlyOperator{
        address _referrer = getReferrer(_user);
        for(uint256 i=0 ;i<_ticket; i++){
            getReferralTicket(_user, _referrer);
        }
    }
}