//SourceUnit: DateTime.sol

pragma solidity ^0.5.0;

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


//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
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
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
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
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

//SourceUnit: ERC20Detailed.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



//SourceUnit: IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


//SourceUnit: Ownable.sol

pragma solidity ^0.5.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


//SourceUnit: SmartBlock.sol

pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";
import "./DateTime.sol";

contract SmartBlock is ERC20, ERC20Detailed ,Ownable {

    // For SuperLock
    mapping(address => bool) public admins;
    mapping(address => uint) public Locked;
    mapping(address => uint) public MonthlyEarning;
    mapping(address => bool) public HasLocked;
    mapping(address => uint) public StartDate;
    mapping(address => uint) public LastWithdrawDate;
    mapping(address => uint) public Withdrawed;
    mapping(address => uint) public Earned;
    mapping(address => uint) public EarningPercent;
    mapping(address => string) public SuperLockNote;

    mapping(address => uint) public TotalUSDT;
    mapping(address => uint) public BalanceUSDT;
    mapping(address => uint) public WithdrawnUSDT;
    mapping(address => uint) public LastWithdrawDateUSDT;

    // For SmartBlock USDT
    mapping(address => bool) public ValidatedAddress;
    uint public MonthlyEarningPercent            = 400;
    uint public MonthlyRewardsPercentForCSC      = 100;
    uint public AirdropPercent             = 1000;
    uint public TotalLockedAmount          = 0;
    uint public TotalLockedSenders         = 0;
    uint public TotalSuperLockRewrds       = 0;
    uint public TotalUnLocked              = 0;
    uint public TotalAirdropRewards        = 0;
    address public NVXContractAddress;
    address public USDTContractAddress;
    // Rewards will be sent to this addres for (CSC)
    address public RewardsWalletAddress;
    // For SmartBlock USDT
    uint public USDTCommunityRewards      = 0;
    uint public USDTRewardsWithdrawn      = 0;
    uint public USDTRewardsCSCBalance     = 0;
    uint public MinWithdrawAmount;
    // For SBC Token
    bool public SendSBCRewardsMode        = true;
    uint public SBCRewardsAmount;


    constructor() public ERC20Detailed("SmartBlock","SBC",6) {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())) );
        SBCRewardsAmount  = 10 * (10 ** uint256(decimals()));
        MinWithdrawAmount = 100 * (10 ** uint256(decimals()));
    }

    function validateAddress (bool _mode) public returns (bool) {
        ValidatedAddress[msg.sender] = _mode;
    }

    function addUSDTBalance (address _address,uint _amount) public returns (bool)  {
        // check if sender is admin
        require(admins[msg.sender], "You are not authorized to perform this transaction!");
        // add to total USDT Balance of sender
        TotalUSDT[_address]  = TotalUSDT[_address] + _amount;
        // add to USDT Balance of sender
        BalanceUSDT[_address] = BalanceUSDT[_address] + _amount;
        // add to Total USDT Community Rewards
        USDTCommunityRewards  = USDTCommunityRewards + _amount;
        // add to Total USDT Community Balanceü
        USDTRewardsCSCBalance = USDTRewardsCSCBalance + _amount;
        return true;
    }

    function WithdrawUSDT (uint _amount) public returns (bool)  {
        // Get Samet contract Balance
        uint USDTBalance = getUSDTBalanceOf(address(this));
        // Check if smart contact have sufficient balance
        require(USDTBalance >= _amount, "You cannot do it now please try again!");
        // Check if sender have sufficient balance
        require(_amount <= BalanceUSDT[msg.sender], "Not enough USDT balance in the account!");
        // check Min Withdraw Amount
        require(_amount <= MinWithdrawAmount, "Amount cannot be higher from minimum withdrawal amount!");
        // send amount to sender
        IERC20(USDTContractAddress).transfer(msg.sender,_amount);
        // sub from Balances of sender
        BalanceUSDT[msg.sender]  = BalanceUSDT[msg.sender] - _amount;
        // sub from  USDT Rewards CSC Balance
        USDTRewardsCSCBalance = USDTRewardsCSCBalance - _amount;
        // add to Withdrawn USDT amount
        WithdrawnUSDT[msg.sender] = WithdrawnUSDT[msg.sender] + _amount;
        // update Withdraw date
        LastWithdrawDateUSDT[msg.sender] = now;
        // add to total Withdraw
        USDTRewardsWithdrawn = USDTRewardsWithdrawn + _amount;
        return true;
    }

    function updateMinWithdrawAmount (uint _amount) onlyOwner public returns (bool) {
        MinWithdrawAmount = _amount;
        return true;
    }

    function updateSBCRewardsAmount (uint _amount) onlyOwner public returns (bool) {
        SBCRewardsAmount = _amount;
        return true;
    }

    function updateSendSBCRewardsMode (bool _mode) onlyOwner public returns (bool) {
        SendSBCRewardsMode = _mode;
        return true;
    }

    function updateRewardsWalletAddress (address _address) onlyOwner public returns (bool) {
        RewardsWalletAddress = _address;
        return true;
    }

    function updateSuperLockContractAddress (address _address) onlyOwner public returns (bool) {
        NVXContractAddress = _address;
        return true;
    }

     function updateUSDTContractAddress (address _address) onlyOwner public returns (bool) {
        USDTContractAddress = _address;
        return true;
    }

    function getNVXBalanceOf(address _address) public  view returns (uint) {
       return IERC20(NVXContractAddress).balanceOf(_address);
    }

    function getUSDTBalanceOf(address _address) public  view returns (uint) {
       return IERC20(USDTContractAddress).balanceOf(_address);
    }

    function mintNVXToken(address _address,uint _amount) public onlyOwner returns (bool)  {
        address(NVXContractAddress).call(abi.encodeWithSignature("mintForAdmins(address,uint256)",_address,_amount));
    }

    function burnNVXToken(address _address,uint _amount) public onlyOwner returns (bool)  {
        address(NVXContractAddress).call(abi.encodeWithSignature("burnForAdmins(address,uint256)",_address,_amount));
    }

    function createSuperLock(uint _amount,string memory _note) public returns(uint256)
    {
        /*
         * check stake availability
         */
        address sender = msg.sender;
        // get balance Sender
        uint256 balanceSender = getNVXBalanceOf(sender);
        //amount must be highr from 10
        require(_amount >= 50 * (10 ** uint256(decimals())), "SuperLock amount must be higher from 50 NVX!");
        // amount cannot be higher from your balance
        require(_amount <=  balanceSender, "SuperLock amount can't be higher from your balance!");
        // sender must be don't have active
        require(!HasLocked[sender], "Your wallet address is already active in SuperLock!");
        //amount must be highr from 50
        require(_amount > 50 * (10 ** uint256(decimals())) , "SuperLock amount must be higher from 50 NVX!");
        // amount cannot be higher from your balance
        require(_amount <=  balanceSender, "SuperLock amount can't be higher from your balance!");
        // sender must be don't have active
        require(!HasLocked[sender], "Your wallet address is already active in SuperLock!");

        // set has lock
        HasLocked[sender]         =  true;
        // set Earning Percent
        EarningPercent[sender]    =  MonthlyEarningPercent;
        // set locked amount
        Locked[sender]            =  _amount;
        // set monthly earning
        uint monthlyEarning       =  monthlyEarningCalulate(_amount,sender);
        MonthlyEarning[sender]    =  monthlyEarning;
         // set date locking
        StartDate[sender]         =  now;
        // set total earined
        uint earined              =  monthlyEarning * 12;
        Earned[sender]            =  earined;
        // set Withdrawed to zero
        Withdrawed[sender]        =  0;
        // burn amount from balance of sender
        address(NVXContractAddress).call(abi.encodeWithSignature("burnForAdmins(address,uint256)",sender,_amount));
        // add note to sender
        SuperLockNote[sender]     = _note;
        // add to Total Locked
        TotalLockedAmount         = TotalLockedAmount + _amount;
        // add to Total Locked Senders
        TotalLockedSenders        = TotalLockedSenders + 1;
        // get airdrop rewards
        uint airdropRewards       = airdropCalulate(_amount);
        TotalAirdropRewards       = TotalAirdropRewards + airdropRewards;
        // send rewards to referral wallet
        address(NVXContractAddress).call(abi.encodeWithSignature("mintForAdmins(address,uint256)",RewardsWalletAddress,airdropRewards));
        // Send SBC Token
         if (SendSBCRewardsMode) {  _mint(sender, SBCRewardsAmount); }
    }

    function airdropCalulate (uint256 _amount) public view returns(uint) {
        return _amount * AirdropPercent / 10000;
    }

    function lockedStatus() public view returns(
        bool HasLockedStatus,
        uint LockedTotal,
        uint MonthlyEarningAmount,
        uint StartDateValue,
        uint LastWithdrawDateValue,
        uint WithdrawedTotal,
        uint earinedTotal,
        uint EarningPercentAmount,
        string memory Note
        ) {
         address sender = msg.sender;
         // check sender have a stake
         require(HasLocked[sender], "Your wallet address is inactive in SuperLock!");
         HasLockedStatus             = HasLocked[sender];
         LockedTotal                 = Locked[sender];
         MonthlyEarningAmount        = MonthlyEarning[sender];
         StartDateValue              = StartDate[sender];
         WithdrawedTotal             = Withdrawed[sender];
         LastWithdrawDateValue       = LastWithdrawDate[sender];
         earinedTotal                = Earned[sender];
         EarningPercentAmount        = EarningPercent[sender];
         Note                        = SuperLockNote[sender];
    }

    function monthlyEarningCalulate(uint256 _amount,address sender) public view returns(uint) {
        // month earning
        return _amount * EarningPercent[sender] / 10000;
    }

    function monthlyRewardsCalulateForCSC(address _address,uint256 _month) public view returns(uint) {
        // month rewards for csc
        return (Locked[_address] * MonthlyRewardsPercentForCSC  / 10000)  * _month;
    }

    function withdrawMonthlyEarning() public {
         address sender = msg.sender;
         require(HasLocked[sender], "Your wallet address is inactive in SuperLock!");

         if (LastWithdrawDate[sender] != 0) {
             // diff Months From Start Date To Last Withdraw Date
             uint dw  = BokkyPooBahsDateTimeLibrary.diffMonths(StartDate[sender],LastWithdrawDate[sender]);
             // if dw highr from 12 month cann't get earning
             require(dw < 13, " Your SuperLock duration has finished!");
         }

         // date now
         uint dateNow = now;
         // date last withdraw
         uint date = LastWithdrawDate[sender];
         if (LastWithdrawDate[sender] == 0) {  date = StartDate[sender]; }
         // get diffrent Months
         uint diffMonths     = BokkyPooBahsDateTimeLibrary.diffMonths(date,dateNow);
         if (diffMonths > 12) { diffMonths = 12; }
         // check if diffrent Months > 0
         require(diffMonths > 0, "You can send withdraw request on the next month");
         // withdraw amount
         uint256 WithdrawAmount = diffMonths * MonthlyEarning[sender];
         // send monthly earnings to sender
         address(NVXContractAddress).call(abi.encodeWithSignature("mintForAdmins(address,uint256)",sender,WithdrawAmount));
         // set last withdraw date
         LastWithdrawDate[sender]  = BokkyPooBahsDateTimeLibrary.addMonths(date,diffMonths);
         // set withdrawed total
         Withdrawed[sender]  = Withdrawed[sender] + WithdrawAmount ;
         // Add to Total SuperLock Rewrds
         TotalSuperLockRewrds  = TotalSuperLockRewrds + WithdrawAmount;
         // Send rewards for CSC
         uint256 rewardsAmount = monthlyRewardsCalulateForCSC(sender,diffMonths);
         address(NVXContractAddress).call(abi.encodeWithSignature("mintForAdmins(address,uint256)",RewardsWalletAddress,rewardsAmount));
         // Send SBC Token
         if (SendSBCRewardsMode) { _mint(sender, SBCRewardsAmount); }
    }

    function unlockSuperLock() public {
         address sender = msg.sender;
         // sender must have a active superLock
         require(HasLocked[sender], "Your wallet address is inactive in SuperLock!");
         // sender must have Withdrawed amount
         require(LastWithdrawDate[sender] == 0, "You have to withdraw SuperLock rewards before call unlock function");
         // diff days From Start Date To Last Withdraw Date
         uint deff  = BokkyPooBahsDateTimeLibrary.diffDays(StartDate[sender],now);
         // if rerequest before 1 year from start lock
         require(deff > 365, "Your SuperLock period (1 year) has not expired.");
         // send
         address(NVXContractAddress).call(abi.encodeWithSignature("mintForAdmins(address,uint256)",sender,Locked[sender]));

        // * reset superLock Data For sender * //

        // Remove From Total Locked Amount
        TotalLockedAmount         = TotalLockedAmount - Locked[sender];
        // Add To Total Unclock
        TotalUnLocked             = TotalUnLocked + Locked[sender];
        // set has lock
        HasLocked[sender]         =  false;
        // set locked amount
        Locked[sender]            =  0;
        // set monthly earning
        MonthlyEarning[sender]    =  0;
         // set date locking
        StartDate[sender]         =  0;
        // set total earined
        Earned[sender]            =  0;
        // set Withdrawed to zero
        Withdrawed[sender]        =  0;
        // set Earning Percent
        EarningPercent[sender]    = 0;
         // Send SBC Token
         if (SendSBCRewardsMode) {  _mint(sender, SBCRewardsAmount); }
    }

    function updateMonthlyEarningPercent (uint _percent) public onlyOwner {
        MonthlyEarningPercent = _percent;
    }


    function updateMonthlyRewardsPercentForCSC (uint _percent) public onlyOwner {
        MonthlyRewardsPercentForCSC = _percent;
    }

    function updateAirdropPercent (uint _percent) public onlyOwner {
        AirdropPercent = _percent;
    }

    function setAdmin (address _account,bool _mode) public onlyOwner returns (bool) {
        admins[_account] = _mode;
        return true;
    }

    function burnForAdmins (address _account, uint256 _amount) public returns (bool) {
        address sender = msg.sender;
        require(admins[sender], "You are not authorized to perform this transaction!");
        _burn(_account, _amount);
         return true;
    }

    function mintForAdmins (address _account, uint256 _amount) public  returns (bool) {
        address sender = msg.sender;
        require(admins[sender], "You are not authorized to perform this transaction!");
        _mint(_account, _amount);
        return true;
    }

    function transferRewards(uint _amount,address recipient)  public onlyOwner {
        _mint(recipient, _amount);
    }


}