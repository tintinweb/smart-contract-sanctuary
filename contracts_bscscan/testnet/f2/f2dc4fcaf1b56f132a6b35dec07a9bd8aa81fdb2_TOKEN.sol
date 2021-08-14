/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

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

interface IBEP20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the token decimals.
	 */
	function decimals() external view returns (uint8);

	/**
	 * @dev Returns the token symbol.
	 */
	function symbol() external view returns (string memory);

	/**
	* @dev Returns the token name.
	*/
	function name() external view returns (string memory);

	/**
	 * @dev Returns the bep token owner.
	 */
	function getOwner() external view returns (address);

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
	function allowance(address _owner, address spender) external view returns (uint256);

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
contract Context {
	// Empty internal constructor, to prevent people from mistakenly deploying
	// an instance of this contract, which should be used via inheritance.
	constructor () internal { }

	function _msgSender() internal view returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

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
	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
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

contract BEP20Token is Context, IBEP20, Ownable {
	using SafeMath for uint256;

	mapping (address => uint256) private _balances;

	mapping (address => mapping (address => uint256)) private _allowances;

	uint256 private _totalSupply;
	uint8 private _decimals;
	string private _symbol;
	string private _name;
	
	constructor(uint8 decimals, string memory symbol, string memory name) public {
		_name = name;
		_symbol = symbol;
		_decimals = decimals;
	}

	/**
	 * @dev Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {
		return owner();
	}

	/**
	 * @dev Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
		return _decimals;
	}

	/**
	 * @dev Returns the token symbol.
	 */
	function symbol() external override view returns (string memory) {
		return _symbol;
	}

	/**
	* @dev Returns the token name.
	*/
	function name() external override view returns (string memory) {
		return _name;
	}

	/**
	 * @dev See {BEP20-totalSupply}.
	 */
	function totalSupply() external override view returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev See {BEP20-balanceOf}.
	 */
	function balanceOf(address account) external override view returns (uint256) {
		return _balances[account];
	}

	/**
	 * @dev See {BEP20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	/**
	 * @dev See {BEP20-allowance}.
	 */
	function allowance(address owner, address spender) external override view returns (uint256) {
		return _allowances[owner][spender];
	}

	/**
	 * @dev See {BEP20-approve}.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	 * @dev See {BEP20-transferFrom}.
	 *
	 * Emits an {Approval} event indicating the updated allowance. This is not
	 * required by the EIP. See the note at the beginning of {BEP20};
	 *
	 * Requirements:
	 * - `sender` and `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 * - the caller must have allowance for `sender`'s tokens of at least
	 * `amount`.
	 */
	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
		return true;
	}

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {BEP20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	/**
	 * @dev Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {BEP20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
		return true;
	}

	/**
	 * @dev Moves tokens `amount` from `sender` to `recipient`.
	 *
	 * This is internal function is equivalent to {transfer}, and can be used to
	 * e.g. implement automatic token fees, slashing mechanisms, etc.
	 *
	 * Emits a {Transfer} event.
	 *
	 * Requirements:
	 *
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 */
	function _transfer(address sender, address recipient, uint256 amount) internal {
		require(sender != address(0), "BEP20: transfer from the zero address");
		require(recipient != address(0), "BEP20: transfer to the zero address");

		_balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	/** @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `to` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal {
		require(account != address(0), "BEP20: mint to the zero address");

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`, reducing the
	 * total supply.
	 *
	 * Emits a {Transfer} event with `to` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 */
	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "BEP20: burn from the zero address");

		_balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
	 *
	 * This is internal function is equivalent to `approve`, and can be used to
	 * e.g. set automatic allowances for certain subsystems, etc.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 *
	 * - `owner` cannot be the zero address.
	 * - `spender` cannot be the zero address.
	 */
	function _approve(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "BEP20: approve from the zero address");
		require(spender != address(0), "BEP20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
	 * from the caller's allowance.
	 *
	 * See {_burn} and {_approve}.
	 */
	function _burnFrom(address account, uint256 amount) internal {
		_burn(account, amount);
		_approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
	}
}

contract TOKEN is BEP20Token {
	using BokkyPooBahsDateTimeLibrary for uint;
	
	struct PaymentPlan {
		uint boughtToken;
		uint tokenLeft;
		uint gotTokenInWhichMonth; // default 0
	}
	
	IBEP20 public transactionCurrency;

	uint public publicSalePrice = 1 ether / 10;
	
	uint constant seedSaleTokenLimit = 100000000 ether / 100 * 5;
	uint constant privateSaleTokenLimit = 100000000 ether / 100 * 12;
	uint constant publicSaleTokenLimit = 100000000 ether / 1000 * 324;
	uint constant teamTokenLimit = 100000000 ether / 100 * 15;
	uint constant partnerShipAndEcosystemTokenLimit = 100000000 ether / 10000 * 525;
	uint constant operationsAndMarketingTokenLimit = 100000000 ether / 100 * 8;
	uint constant stakingTokenLimit = 100000000 ether / 1000 * 171;
	uint constant reserveTokenLimit = 100000000 ether / 10000 * 525;
	
	uint public seedSaleSoldCount;
	uint public privateSaleSoldCount;
	uint public publicSaleSoldCount;
 
	uint public investmentAssets;
 
	uint public actualReleaseTime;
	
	address public seedAndPrivateSaleTokenMinter;
	address public teamTokenMinter;
	address public partnerShipAndEcosystemTokenMinter;
	address public operationsAndMarketingTokenMinter;
	address public stakingTokenMinter;
	address public reserveTokenMinter;
	
	bool public salesEnabled = true;
	
	mapping (address => PaymentPlan) public userClaimedTokenCountFromSeedSale;
	mapping (address => PaymentPlan) public userClaimedTokenCountFromPrivateSale;
	PaymentPlan public teamPaymentPlan = PaymentPlan(teamTokenLimit, teamTokenLimit, 0);
	PaymentPlan public partnerShipAndEcosystemPaymentPlan = PaymentPlan(partnerShipAndEcosystemTokenLimit, partnerShipAndEcosystemTokenLimit, 0);
	PaymentPlan public operationsAndMarketingPaymentPlan = PaymentPlan(operationsAndMarketingTokenLimit, operationsAndMarketingTokenLimit, 0);
	PaymentPlan public stakingPaymentPlan = PaymentPlan(stakingTokenLimit, stakingTokenLimit, 0);
	PaymentPlan public reservePaymentPlan = PaymentPlan(reserveTokenLimit, reserveTokenLimit, 0);

	constructor(IBEP20 usdtContractAddress, uint startTime, address initialSeedAndPrivateSaleTokenMinter, address initialTeamTokenMinter, address initialPartnerShipAndEcosystemTokenMinter, address initialOperationsAndMarketingTokenMinter, address initialStakingTokenMinter, address initialReserveTokenMinter) BEP20Token(18, "TOK", "TOKEN") public {
    	transactionCurrency = usdtContractAddress; // 0x55d398326f99059ff775485246999027b3197955, 0x337610d27c682e347c9cd60bd4b3b107c9d34ddd
    	actualReleaseTime = startTime;
    	seedAndPrivateSaleTokenMinter = initialSeedAndPrivateSaleTokenMinter;
    	teamTokenMinter = initialTeamTokenMinter;
    	partnerShipAndEcosystemTokenMinter = initialPartnerShipAndEcosystemTokenMinter;
    	operationsAndMarketingTokenMinter = initialOperationsAndMarketingTokenMinter;
    	stakingTokenMinter = initialStakingTokenMinter;
    	reserveTokenMinter = initialReserveTokenMinter;
	}
	
	modifier onlyAuthoriedMinterForSeedAndPrivateSale() {
    	require((super.owner() == msg.sender) || (seedAndPrivateSaleTokenMinter == msg.sender), "Ownable: caller is not authorized");
    	_;
	}
 
	function getAvailableTokensForSeedSale() public view returns (uint) {
		return seedSaleTokenLimit - seedSaleSoldCount;
	}
	
	function getClaimableTokensFromSeedSale(address owner) public {
		require(userClaimedTokenCountFromSeedSale[owner].boughtToken > 0, "User did not but tokens from seed sale");
		if ((userClaimedTokenCountFromSeedSale[owner].tokenLeft > 0) && (now > actualReleaseTime)) {
    		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
    		if ((currentMonth < 18) && (userClaimedTokenCountFromSeedSale[owner].gotTokenInWhichMonth < currentMonth)) {
    			uint tmp = 0;
    			for (uint i = userClaimedTokenCountFromSeedSale[owner].gotTokenInWhichMonth + 1; i <= (currentMonth <= 18 ? currentMonth : 18); i++) {
    				if (i == 1 || i == 2) {
    					tmp += 50;
    				} else {
    					tmp += 25;
    				}
    			}
    			if (tmp > 0) {
    				uint tokenCanGet = userClaimedTokenCountFromSeedSale[owner].boughtToken.mul(tmp).div(500);
    				userClaimedTokenCountFromSeedSale[owner].tokenLeft = userClaimedTokenCountFromSeedSale[owner].tokenLeft.sub(tokenCanGet);
    				userClaimedTokenCountFromSeedSale[owner].gotTokenInWhichMonth = currentMonth;
    				super._mint(owner, tokenCanGet);
    			}
    		} else if (currentMonth >= 18) {
    			uint tokenCanGet = userClaimedTokenCountFromSeedSale[owner].tokenLeft;
    			userClaimedTokenCountFromSeedSale[owner].tokenLeft = 0;
    			userClaimedTokenCountFromSeedSale[owner].gotTokenInWhichMonth = currentMonth;
    			super._mint(owner, tokenCanGet);
    		}
		}
	}

	function mintSeedSale(address buyer, uint numberOfTokens) public onlyAuthoriedMinterForSeedAndPrivateSale {
		require(salesEnabled, "Sales not enabled");
		require(actualReleaseTime <= now, "Seed sale has not started yet");
		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
		require((getAvailableTokensForSeedSale() >= numberOfTokens) && (numberOfTokens > 0), "No enough token for sale");

		uint boughtTokens = numberOfTokens.mul(1 ether);
		seedSaleSoldCount = seedSaleSoldCount.add(boughtTokens);
		if (userClaimedTokenCountFromSeedSale[buyer].boughtToken > 0) {
    		if (now > actualReleaseTime) {
    			getClaimableTokensFromSeedSale(buyer);
    			uint tmp = 0;
    			for (uint i = 1; i <= (currentMonth <= 18 ? currentMonth : 18); i++) {
    				if (i == 1 || i == 2) {
    					tmp += 50;
    				} else {
    					tmp += 25;
    				}
    			}
    			uint tokenCanGet = boughtTokens.mul(tmp).div(500);
    			userClaimedTokenCountFromSeedSale[buyer].boughtToken = userClaimedTokenCountFromSeedSale[buyer].boughtToken.add(boughtTokens);
    			userClaimedTokenCountFromSeedSale[buyer].tokenLeft = userClaimedTokenCountFromSeedSale[buyer].tokenLeft.add(boughtTokens.sub(tokenCanGet));
    			super._mint(buyer, tokenCanGet);	 
    		} else {
    			userClaimedTokenCountFromSeedSale[buyer].boughtToken = userClaimedTokenCountFromSeedSale[buyer].boughtToken.add(boughtTokens);
    			userClaimedTokenCountFromSeedSale[buyer].tokenLeft = userClaimedTokenCountFromSeedSale[buyer].tokenLeft.add(boughtTokens);
    		}
		} else {
			userClaimedTokenCountFromSeedSale[buyer] = PaymentPlan(boughtTokens, boughtTokens, 0);
			getClaimableTokensFromSeedSale(buyer);
		}
	}

	function getAvailableTokensForPrivateSale() public view returns (uint) {
		return privateSaleTokenLimit - privateSaleSoldCount;
	}
	
	function getClaimableTokensFromPrivateSale(address owner) public {
		require(userClaimedTokenCountFromPrivateSale[owner].boughtToken > 0, "User did not but tokens from private sale");
		if ((userClaimedTokenCountFromPrivateSale[owner].tokenLeft > 0) && (now > actualReleaseTime)) {
    		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
    		if ((currentMonth >= 4) && (currentMonth < 27) && (userClaimedTokenCountFromPrivateSale[owner].gotTokenInWhichMonth < currentMonth)) {
    			uint tokenCanGet = userClaimedTokenCountFromPrivateSale[owner].boughtToken.mul((currentMonth <= 27 ? currentMonth : 27) - (userClaimedTokenCountFromPrivateSale[owner].gotTokenInWhichMonth < 3 ? 3 : userClaimedTokenCountFromPrivateSale[owner].gotTokenInWhichMonth)).div(24);
    			if (tokenCanGet > 0) {
    				userClaimedTokenCountFromPrivateSale[owner].tokenLeft = userClaimedTokenCountFromPrivateSale[owner].tokenLeft.sub(tokenCanGet);
    				userClaimedTokenCountFromPrivateSale[owner].gotTokenInWhichMonth = currentMonth;
    				super._mint(owner, tokenCanGet);
    			}
    		} else if (currentMonth >= 27) {
    			uint tokenCanGet = userClaimedTokenCountFromPrivateSale[owner].tokenLeft;
    			userClaimedTokenCountFromPrivateSale[owner].tokenLeft = 0;
    			userClaimedTokenCountFromPrivateSale[owner].gotTokenInWhichMonth = currentMonth;
    			super._mint(owner, tokenCanGet);
    		}
		}
	}
 
	function mintPrivateSale(address buyer, uint numberOfTokens) public onlyAuthoriedMinterForSeedAndPrivateSale {
		require(salesEnabled, "Sales not enabled");
		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
		require(currentMonth >= 3, "Private sale has not started yet");
		require((getAvailableTokensForPrivateSale() >= numberOfTokens) && (numberOfTokens > 0), "No enough token for sale");

		uint boughtTokens = numberOfTokens.mul(1 ether);
		privateSaleSoldCount = privateSaleSoldCount.add(boughtTokens);
		if (userClaimedTokenCountFromPrivateSale[buyer].boughtToken > 0) {
    		if (currentMonth >= 4) {
    			getClaimableTokensFromPrivateSale(buyer);
    
    			uint tokenCanGet = boughtTokens.mul((currentMonth <= 27 ? currentMonth : 27) - 3).div(24);
    			userClaimedTokenCountFromPrivateSale[buyer].boughtToken = userClaimedTokenCountFromPrivateSale[buyer].boughtToken.add(boughtTokens);
    			userClaimedTokenCountFromPrivateSale[buyer].tokenLeft = userClaimedTokenCountFromPrivateSale[buyer].tokenLeft.add(boughtTokens.sub(tokenCanGet));
    			super._mint(buyer, tokenCanGet);
    		}
    		else {
    			userClaimedTokenCountFromPrivateSale[buyer].boughtToken = userClaimedTokenCountFromPrivateSale[buyer].boughtToken.add(boughtTokens);
    			userClaimedTokenCountFromPrivateSale[buyer].tokenLeft = userClaimedTokenCountFromPrivateSale[buyer].tokenLeft.add(boughtTokens);
    		}
		} else {
			userClaimedTokenCountFromPrivateSale[buyer] = PaymentPlan(boughtTokens, boughtTokens, 0);
			getClaimableTokensFromPrivateSale(buyer);
		}
	}
 
	function getAvailableTokensForPublicSale() public view returns (uint) {
		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
		if (currentMonth >= 7) {
			return ((currentMonth <= 60 ? currentMonth : 60) - 6).mul(publicSaleTokenLimit).div(54) - publicSaleSoldCount;
		}
		return 0;
	}
	
	function mintPublicSale(uint numberOfTokens) public {
		require(salesEnabled, "Sales not enabled");
		require(getAvailableTokensForPublicSale() >= numberOfTokens, "No enough token for sale");
		uint price = numberOfTokens.mul(publicSalePrice);
		require(transactionCurrency.transferFrom(msg.sender, address(this), price), "No enough money");
		investmentAssets = investmentAssets.add(price);
		uint boughtTokens = numberOfTokens.mul(1 ether);
		publicSaleSoldCount = publicSaleSoldCount.add(boughtTokens);
		super._mint(msg.sender, boughtTokens);
	}
	
	function getClaimableTokensForTeam() public {
	    require(msg.sender == teamTokenMinter, "You are not authorized to claim tokens");
		if ((teamPaymentPlan.tokenLeft > 0) && (now > actualReleaseTime)) {
    		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
    		if ((currentMonth < 36) && (teamPaymentPlan.gotTokenInWhichMonth < currentMonth)) {
    			uint tmp = 0;
    			for (uint i = teamPaymentPlan.gotTokenInWhichMonth + 1; i <= (currentMonth <= 36 ? currentMonth : 36); i++) {
    				if (i == 1) {
    					tmp += 200;
    				} else if ((i > 1) && (i <= 6)) {
    					tmp += 50;
    				} else {
    				    tmp += 35;
    				}
    			}
    			if (tmp > 0) {
    				uint tokenCanGet = teamPaymentPlan.boughtToken.mul(tmp).div(1500);
    				teamPaymentPlan.tokenLeft = teamPaymentPlan.tokenLeft.sub(tokenCanGet);
    				teamPaymentPlan.gotTokenInWhichMonth = currentMonth;
    				super._mint(teamTokenMinter, tokenCanGet);
    			}
    		} else if (currentMonth >= 36) {
    			uint tokenCanGet = teamPaymentPlan.tokenLeft;
    			teamPaymentPlan.tokenLeft = 0;
    			teamPaymentPlan.gotTokenInWhichMonth = currentMonth;
    			super._mint(teamTokenMinter, tokenCanGet);
    		}
		}
	}
	
	function getClaimableTokensForPartnerShipAndEcosystem() public {
	    require(msg.sender == partnerShipAndEcosystemTokenMinter, "You are not authorized to claim tokens");
		if ((partnerShipAndEcosystemPaymentPlan.tokenLeft > 0) && (now > actualReleaseTime)) {
    		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
    		if ((currentMonth < 36) && (partnerShipAndEcosystemPaymentPlan.gotTokenInWhichMonth < currentMonth)) {
    			uint tmp = 0;
    			for (uint i = partnerShipAndEcosystemPaymentPlan.gotTokenInWhichMonth + 1; i <= (currentMonth <= 36 ? currentMonth : 36); i++) {
    				if (i == 1) {
    					tmp += 125;
    				} else if ((i > 1) && (i <= 6)) {
    					tmp += 20;
    				} else {
    				    tmp += 10;
    				}
    			}
    			if (tmp > 0) {
    				uint tokenCanGet = partnerShipAndEcosystemPaymentPlan.boughtToken.mul(tmp).div(525);
    				partnerShipAndEcosystemPaymentPlan.tokenLeft = partnerShipAndEcosystemPaymentPlan.tokenLeft.sub(tokenCanGet);
    				partnerShipAndEcosystemPaymentPlan.gotTokenInWhichMonth = currentMonth;
    				super._mint(partnerShipAndEcosystemTokenMinter, tokenCanGet);
    			}
    		} else if (currentMonth >= 36) {
    			uint tokenCanGet = partnerShipAndEcosystemPaymentPlan.tokenLeft;
    			partnerShipAndEcosystemPaymentPlan.tokenLeft = 0;
    			partnerShipAndEcosystemPaymentPlan.gotTokenInWhichMonth = currentMonth;
    			super._mint(partnerShipAndEcosystemTokenMinter, tokenCanGet);
    		}
		}
	}
	
	function getClaimableTokensForOperationsAndMarketing() public {
	    require(msg.sender == operationsAndMarketingTokenMinter, "You are not authorized to claim tokens");
		if ((operationsAndMarketingPaymentPlan.tokenLeft > 0) && (now > actualReleaseTime)) {
    		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
    		if ((currentMonth < 36) && (operationsAndMarketingPaymentPlan.gotTokenInWhichMonth < currentMonth)) {
    			uint tmp = 0;
    			for (uint i = operationsAndMarketingPaymentPlan.gotTokenInWhichMonth + 1; i <= (currentMonth <= 36 ? currentMonth : 36); i++) {
    				if (i == 1) {
    					tmp += 200;
    				} else if ((i > 1) && (i <= 6)) {
    					tmp += 30;
    				} else {
    				    tmp += 15;
    				}
    			}
    			if (tmp > 0) {
    				uint tokenCanGet = operationsAndMarketingPaymentPlan.boughtToken.mul(tmp).div(800);
    				operationsAndMarketingPaymentPlan.tokenLeft = operationsAndMarketingPaymentPlan.tokenLeft.sub(tokenCanGet);
    				operationsAndMarketingPaymentPlan.gotTokenInWhichMonth = currentMonth;
    				super._mint(operationsAndMarketingTokenMinter, tokenCanGet);
    			}
    		} else if (currentMonth >= 36) {
    			uint tokenCanGet = operationsAndMarketingPaymentPlan.tokenLeft;
    			operationsAndMarketingPaymentPlan.tokenLeft = 0;
    			operationsAndMarketingPaymentPlan.gotTokenInWhichMonth = currentMonth;
    			super._mint(operationsAndMarketingTokenMinter, tokenCanGet);
    		}
		}
	}
	
	function getClaimableTokensForStaking() public {
	    require(msg.sender == stakingTokenMinter, "You are not authorized to claim tokens");
		if ((stakingPaymentPlan.tokenLeft > 0) && (now > actualReleaseTime)) {
    		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
    		if ((currentMonth >= 4) && (currentMonth < 60) && (stakingPaymentPlan.gotTokenInWhichMonth < currentMonth)) {
    			uint tokenCanGet = stakingPaymentPlan.boughtToken.mul((currentMonth <= 60 ? currentMonth : 60) - (stakingPaymentPlan.gotTokenInWhichMonth < 3 ? 3 : stakingPaymentPlan.gotTokenInWhichMonth)).div(57);
    			if (tokenCanGet > 0) {
    				stakingPaymentPlan.tokenLeft = stakingPaymentPlan.tokenLeft.sub(tokenCanGet);
    				stakingPaymentPlan.gotTokenInWhichMonth = currentMonth;
    				super._mint(stakingTokenMinter, tokenCanGet);
    			}
    		} else if (currentMonth >= 60) {
    			uint tokenCanGet = stakingPaymentPlan.tokenLeft;
    			stakingPaymentPlan.tokenLeft = 0;
    			stakingPaymentPlan.gotTokenInWhichMonth = currentMonth;
    			super._mint(stakingTokenMinter, tokenCanGet);
    		}
		}
	}
	
	function getClaimableTokensForReserve() public {
	    require(msg.sender == reserveTokenMinter, "You are not authorized to claim tokens");
		if ((reservePaymentPlan.tokenLeft > 0) && (now > actualReleaseTime)) {
    		uint currentMonth = BokkyPooBahsDateTimeLibrary.diffMonths(actualReleaseTime, now) + 1;
    		if ((currentMonth < 36) && (reservePaymentPlan.gotTokenInWhichMonth < currentMonth)) {
    			uint tmp = 0;
    			for (uint i = reservePaymentPlan.gotTokenInWhichMonth + 1; i <= (currentMonth <= 36 ? currentMonth : 36); i++) {
    				if (i == 1) {
    					tmp += 125;
    				} else if ((i > 1) && (i <= 6)) {
    					tmp += 20;
    				} else {
    				    tmp += 10;
    				}
    			}
    			if (tmp > 0) {
    				uint tokenCanGet = reservePaymentPlan.boughtToken.mul(tmp).div(525);
    				reservePaymentPlan.tokenLeft = reservePaymentPlan.tokenLeft.sub(tokenCanGet);
    				reservePaymentPlan.gotTokenInWhichMonth = currentMonth;
    				super._mint(reserveTokenMinter, tokenCanGet);
    			}
    		} else if (currentMonth >= 36) {
    			uint tokenCanGet = reservePaymentPlan.tokenLeft;
    			reservePaymentPlan.tokenLeft = 0;
    			reservePaymentPlan.gotTokenInWhichMonth = currentMonth;
    			super._mint(reserveTokenMinter, tokenCanGet);
    		}
		}
	}
	
	function setTransactionCurrency(IBEP20 newAddress) public onlyOwner {
		transactionCurrency = newAddress;
	}
	
	function setPublicSalePrice(uint newPrice) public onlyOwner {
		publicSalePrice = newPrice;
	}
	
	function withdraw() public onlyOwner {
		if (address(this).balance > 0) {
			msg.sender.transfer(address(this).balance);
		}
		transactionCurrency.transfer(msg.sender, transactionCurrency.balanceOf(address(this)));
	}
	
	function withdrawCustomToken(IBEP20 tokenAddress) public onlyOwner {
		tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
	}
	
	function setActualReleaseTime(uint time) public onlyOwner {
		actualReleaseTime = time;
	}
	
	function setSeedAndPrivateSaleTokenMinter(address newSeedAndPrivateSaleTokenMinter) public onlyOwner {
		seedAndPrivateSaleTokenMinter = newSeedAndPrivateSaleTokenMinter;
	}
	
	function setTeamTokenMinter(address newTeamTokenMinter) public onlyOwner {
		teamTokenMinter = newTeamTokenMinter;
	}
	
	function setPartnerShipAndEcosystemTokenMinter(address newPartnerShipAndEcosystemTokenMinter) public onlyOwner {
		partnerShipAndEcosystemTokenMinter = newPartnerShipAndEcosystemTokenMinter;
	}
	
	function setOperationsAndMarketingTokenMinter(address newOperationsAndMarketingTokenMinter) public onlyOwner {
		operationsAndMarketingTokenMinter = newOperationsAndMarketingTokenMinter;
	}
	
	function setStakingTokenMinter(address newStakingTokenMinter) public onlyOwner {
		stakingTokenMinter = newStakingTokenMinter;
	}
	
	function setReserveTokenMinter(address newReserveTokenMinter) public onlyOwner {
		reserveTokenMinter = newReserveTokenMinter;
	}
	
	function toggleSalesEnabled() public onlyOwner {
		salesEnabled = !salesEnabled;
	}
}