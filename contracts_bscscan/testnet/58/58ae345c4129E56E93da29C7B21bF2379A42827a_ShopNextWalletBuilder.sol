// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import  "./IBEP20.sol";
import "../util/Pausable.sol";
import "../util/SafeMath.sol";

contract BEP20 is Context, IBEP20, Pausable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override virtual whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external whenNotPaused override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
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
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused override virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external whenNotPaused returns (bool) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard. Does not include
 * the optional functions; to access them see {BEP20Detailed}.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



library Constant {
    string constant SHOPNEXTWALLETYPETEAMADVISOR = "TEAMADVISOR";
    string constant SHOPNEXTWALLETYPECOMPANY = "COMPANY";
    string constant SHOPNEXTWALLETYPEMARKETING = "MARKETING";
    string constant SHOPNEXTWALLETYPECOMMUNITY = "COMMUNITY";
    string constant SHOPNEXTWALLETYPESALE = "SALE";
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DateTime {
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
        public
        pure
        returns (uint8)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp)
        internal
        pure
        returns (_DateTime memory dt)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint256 timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public pure returns (uint256 timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }

    function diffMonth(uint256 currentDate, uint256 checkDate) public pure returns(uint256 monthDiff){
        _DateTime memory currentDateTime = parseTimestamp(currentDate);
        _DateTime memory checkDateTime = parseTimestamp(checkDate);
        monthDiff = (currentDateTime.year * 12 + currentDateTime.month) - (checkDateTime.year * 12 + checkDateTime.month);
        return monthDiff;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Context.sol";

contract MultiOwner is Ownable {

    address private _secondaryOwner;

    bool private _isSecondaryPromoting;

    event PromoteSecondaryOwner(address indexed primaryOwner, address indexed secondaryOwner);
    event UnpromoteSecondaryOwner(address indexed primaryOwner, address indexed secondaryOwner);
    event ChangeSecondaryOwner (address newSecondaryOwner);

    constructor() Ownable() {
    }

    modifier IsOwner() {
       if (!_isSecondaryPromoting)  {
           require(owner() == _msgSender());
       }
       if (_isSecondaryPromoting) {
           require(_secondaryOwner == _msgSender());
       }
        _;
    }

    modifier IsMultiOwner() {
        require (owner() == _msgSender() || _secondaryOwner == _msgSender());
        _;
    }

    function getSecondaryOwner() public view returns(address){
        return _secondaryOwner;
    }

    function isPromotingSecondaryOwner() public view returns(bool) {
        return _isSecondaryPromoting;
    }

    function secondaryPromote() IsMultiOwner external returns (bool) {
        _isSecondaryPromoting = true;
        emit PromoteSecondaryOwner(owner(), _secondaryOwner);
        return true;
    }

    function secondaryUnpromote() IsMultiOwner external returns (bool) {
        _isSecondaryPromoting = false;
        emit PromoteSecondaryOwner(owner(), _secondaryOwner);
        return true;
    }


    function changeSecondaryOwner(address _newSecondaryOwner) IsMultiOwner external returns(bool) {
        require(_newSecondaryOwner != address(0));
        require(owner() != _newSecondaryOwner);
        _secondaryOwner = _newSecondaryOwner;
        emit ChangeSecondaryOwner(_secondaryOwner);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
 */abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool private paused = false;


  /**
  * @dev modifier to allow actions only when the contract IS paused
  */
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

  /**
  * @dev modifier to allow actions only when the contract IS NOT paused
  */
  modifier whenPaused {
    require (paused) ;
    _;
  }

  /**
  * @dev called by the owner to pause, triggers stopped state
  */
  function pause() onlyOwner external whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
  * @dev called by the owner to unpause, returns to normal state
  */
  function unpause() onlyOwner external whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract ReleaseTokenInfo {

    uint256 _releasedTime;
    uint256 _releasedTokenSize;
    

    constructor(uint256 releasedTime, uint256 releasedTokenSize) {
        _releasedTime = releasedTime;
        _releasedTokenSize = releasedTokenSize;
    }

    function getReleasedTime() view public returns(uint256){
        return _releasedTime;
    }

    function getReleasedTokenTotal() view public returns (uint256) {
        return _releasedTokenSize;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../util/ReleaseTokenInfo.sol";

interface IShopNextWallet {
    event Received(address from, uint256 amount);
    event WalletTransfer(address to, uint256 amount);
    event WalletTransferToken(
        address tokenContract,
        address to,
        uint256 amount
    );

    event InitializeToken(
        address from,
        address to,
        address tokenContract,
        uint256 amount
    );
    event WalletMultiSendToken(uint256 total, address tokenAddress);

    function releasingToken(address tokenAddress, uint256 amount)
        external;

    function info()
        external
        returns (
            address,
            address,
            uint256,
            uint256,
            string memory
        ); // creator , owner, createdTime, currentBalance

    function transferToken(
        address tokenContract,
        address to,
        uint256 amount
    ) external payable returns (bool);

    function multiSendToken(
        address tokenAddress,
        address[] memory receivers,
        uint256[] memory amounts
    ) external payable returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../util/MultiOwner.sol";
import "../wallet/IShopNextWallet.sol";
import "../util/ReleaseTokenInfo.sol";
import "../token/BEP20.sol";

contract ShopNextWallet is MultiOwner, IShopNextWallet {
    
    address private _creator;
    uint256 private _initalizedWalletDate;
    ReleaseTokenInfo[] private _releasedTokenHistory;
    uint256 _latestReleasedTokenTime;
    string _walletName;
    constructor(string memory walletName, address currentOwner) MultiOwner() {
        _creator = msg.sender;
        _walletName = walletName;
        _initalizedWalletDate = block.timestamp;
        transferOwnership(currentOwner);
    }

    // keep all the ether sent to this address
    fallback() external payable {}

    receive() external payable {
        // custom function code
        emit Received(msg.sender, msg.value);
    }

    function info()
        external
        view
        override
        returns (
            address,
            address,
            uint256,
            uint256,
            string memory
        )
    {
        return (_creator, owner(), _initalizedWalletDate, address(this).balance, _walletName);
    }

    function transferToken(
        address tokenContract,
        address to,
        uint256 amount
    ) external payable override IsOwner returns (bool) {
        require(to != address(0), "ShopNextWallet: not transfer to 0 address");
        require(amount > 0, "ShopNextWallet: amount is equal to 0");
        require(tokenContract != address(0), "ShopNextWallet: ERC");
        BEP20 token = BEP20(tokenContract);
        //now send all the token balance
        // uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(to, amount);
        emit WalletTransferToken(tokenContract, msg.sender, amount);
        return true;
    }

    function multiSendToken(
        address tokenContract,
        address[] memory receivers,
        uint256[] memory amounts
    ) external payable override IsOwner returns (bool) {
        require( msg.sender == owner());
        uint256 total = 0;
        require(receivers.length <= 200);
        require(amounts.length <= 200);
        require(receivers.length ==amounts.length);
         BEP20 token = BEP20(tokenContract);
        uint8 i = 0;
        for (i; i < receivers.length; i++) {
            token.transferFrom(address(this), receivers[i], amounts[i]);
            total += amounts[i];
        }
        // setTxCount(msg.sender, txCount(msg.sender).add(1));
        emit WalletMultiSendToken(total, tokenContract);
        return true;
    } 

    function releasingToken(address tokenAddress, uint256 amount) IsOwner external view override{
        require(tokenAddress != address(0));
        require(amount != 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../util/MultiOwner.sol";
import "./ShopNextWallet.sol";
import "../util/Constant.sol";
import "../token/BEP20.sol";
import "../util/DateTime.sol";
import "../util/SafeMath.sol";
import "../util/ReleaseTokenInfo.sol";

contract ShopNextWalletBuilder is MultiOwner {
    using SafeMath for uint256;

    mapping(string => uint256) _initializedTokenSize;
    mapping(string => uint256) _totalTokenSize;
    mapping(string => ReleaseTokenInfo[]) _releaseTokenHistory;
    mapping(string => address) _walletByType;
    mapping(string => uint256) _walletCreationDateTime;
    mapping(string => uint256) _releasedTokenSize;
    mapping(address => address[]) wallets;
    address _tokenAddress;
    DateTime dateTime;

    constructor(address tokenAddress) MultiOwner() {
        require(
            tokenAddress != address(0),
            "ShopNextWalletBuilder: must have token address"
        );
        _tokenAddress = tokenAddress;

        transferOwnership(msg.sender);
        initializedTokenSize();
        totalTokenSize();
        dateTime = new DateTime();
    }

    function getWallets(address _user) public view returns (address[] memory) {
        return wallets[_user];
    }

    function getTokenAddress() public view returns (address) {
        return _tokenAddress;
    }

    function initializedTokenSize() internal {
        _initializedTokenSize[Constant.SHOPNEXTWALLETYPETEAMADVISOR] = 0;
        _initializedTokenSize[Constant.SHOPNEXTWALLETYPECOMPANY] = 0;
        _initializedTokenSize[Constant.SHOPNEXTWALLETYPEMARKETING] = 0;
        _initializedTokenSize[Constant.SHOPNEXTWALLETYPECOMMUNITY] = 0;
        _initializedTokenSize[Constant.SHOPNEXTWALLETYPESALE] =
            48000000 *
            (10**18);
    }

    function totalTokenSize() internal {
        _totalTokenSize[Constant.SHOPNEXTWALLETYPETEAMADVISOR] = uint256(
            200000000 * (10**18)
        );
        _totalTokenSize[Constant.SHOPNEXTWALLETYPECOMPANY] = uint256(
            200000000 * (10**18)
        );
        _totalTokenSize[Constant.SHOPNEXTWALLETYPEMARKETING] = uint256(
            150000000 * (10**18)
        );
        _totalTokenSize[Constant.SHOPNEXTWALLETYPECOMMUNITY] = uint256(
            240000000 * (10**18)
        );
        _totalTokenSize[Constant.SHOPNEXTWALLETYPESALE] = uint256(
            210000000 * (10**18)
        );
    }

    function getReleasedTokenSizeByWalletType(string memory walletType)
        public
        view
        returns (uint256)
    {
        return _releasedTokenSize[walletType];
    }

    function getInitializedTokenSizeByWalletType(string memory walletType)
        public
        view
        returns (uint256)
    {
        return _initializedTokenSize[walletType];
    }

    function getTokenSizeByWalletType(string memory walletType)
        public
        view
        returns (uint256)
    {
        return _totalTokenSize[walletType];
    }

    function getReleasedTokenHistory(string memory walletType)
        public
        view
        returns (ReleaseTokenInfo[] memory)
    {
        return _releaseTokenHistory[walletType];
    }

    function getWalletAddressByWalletType(string memory walletType)
        public
        view
        returns (address)
    {
        return _walletByType[walletType];
    }

    function newShopNextWallets() public payable IsOwner returns (bool) {
        // DateTime._DateTime memory creationDateTime = DateTime.parseTimestamp(block.timestamp);
        // SHOPNEXTWALLETYPETEAMADVISOR
        address teamAdvisorWallet = createWallet(
            Constant.SHOPNEXTWALLETYPETEAMADVISOR
        );
        require(teamAdvisorWallet != address(0));

        // Constant.SHOPNEXTWALLETYPECOMPANY
        address companyWallet = createWallet(Constant.SHOPNEXTWALLETYPECOMPANY);
        require(companyWallet != address(0));

        // Constant.SHOPNEXTWALLETYPEMARKETING
        address marketingWallet = createWallet(
            Constant.SHOPNEXTWALLETYPEMARKETING
        );
        require(marketingWallet != address(0));

        // Constant.SHOPNEXTWALLETYPECOMPANY
        address communityWallet = createWallet(
            Constant.SHOPNEXTWALLETYPECOMMUNITY
        );
        require(communityWallet != address(0));

        // Constant.SHOPNEXTWALLETYPESALE
        address saleWallet = createWallet(Constant.SHOPNEXTWALLETYPESALE);
        require(saleWallet != address(0));
        return true;
    }

    function createWallet(string memory walletType)
        internal
        returns (address wallet)
    {
        // create new wallet
        ShopNextWallet shopNextWallet = new ShopNextWallet(walletType, owner());
        wallet = address(shopNextWallet);
        _walletByType[walletType] = wallet;
        address factoryAddress = address(this);
        BEP20 token = BEP20(_tokenAddress);
        token.increaseAllowance(
            factoryAddress,
            _initializedTokenSize[walletType]
        );
        token.transferFrom(
            factoryAddress,
            wallet,
            _initializedTokenSize[walletType]
        );
        _releasedTokenSize[walletType] = _initializedTokenSize[walletType];
        wallets[owner()].push(wallet);
        _walletCreationDateTime[walletType] = block.timestamp;
        emit Created(wallet, msg.sender, owner(), block.timestamp, msg.value);
    }

    function releaseTokenForWallet() public payable IsOwner returns (bool) {
        // daily trigger
        // DateTime creationDateTime = DateTime.parseTimestamp(block.timestamp);
        uint256 releasingTotalAmount = 0;
        uint256 currentTimestamp = block.timestamp;
        releasingTotalAmount += releaseTokenForTeamAdvisorWallet(
            currentTimestamp
        );

        releasingTotalAmount += releaseTokenForSaleWallet(currentTimestamp);
        releasingTotalAmount += releaseTokenForCommunityWallet(
            currentTimestamp
        );
        releasingTotalAmount += releaseTokenForCompanyWallet(currentTimestamp);
        releasingTotalAmount += releaseTokenForMarketingWallet(
            currentTimestamp
        );
        require(releasingTotalAmount > 0 );

        emit ReleaseTokenForWallets(_tokenAddress, releasingTotalAmount);
        return true;
    }

    function releaseTokenForWalletCustomTime(uint256 currentTimestamp)
        public
        payable
        IsOwner
        returns (bool)
    {
        // daily trigger
        // DateTime creationDateTime = DateTime.parseTimestamp(block.timestamp);
        uint256 releasingTotalAmount = 0;
        releasingTotalAmount += releaseTokenForTeamAdvisorWallet(
            currentTimestamp
        );

        releasingTotalAmount += releaseTokenForSaleWallet(currentTimestamp);
        releasingTotalAmount += releaseTokenForCommunityWallet(
            currentTimestamp
        );
        releasingTotalAmount += releaseTokenForCompanyWallet(currentTimestamp);
        releasingTotalAmount += releaseTokenForMarketingWallet(
            currentTimestamp
        );

        emit ReleaseTokenForWallets(_tokenAddress, releasingTotalAmount);
        return true;
    }

    function releaseTokenForTeamAdvisorWallet(uint256 currentTimestamp)
        internal
        returns (uint256 releasingAmount)
    {
        // at 6th month from creation date -> release 3,333,333 tokens and stop this rule at end of 11th month
        // at 12th month -> release 5,000,000 tokens per month and end till token of this wallet is done or meet deadline by end of 47th month
        uint256 diffMonth = getDiffMonth(
            Constant.SHOPNEXTWALLETYPETEAMADVISOR,
            currentTimestamp
        );

        if (
            !checkReleaseTime(
                Constant.SHOPNEXTWALLETYPETEAMADVISOR,
                currentTimestamp
            )
        ) {
            return 0;
        }

        if (diffMonth >= 6 && diffMonth <= 11) {
            releasingAmount = 3333333 * (10**18);
        }

        if (diffMonth >= 12 && diffMonth <= 47) {
            releasingAmount = 5000000 * (10**18);
        }

        if (releasingAmount == 0) {
            return 0;
        }

        if (
            !giveFundToWallet(
                Constant.SHOPNEXTWALLETYPETEAMADVISOR,
                releasingAmount,
                currentTimestamp
            )
        ) {
            return 0;
        }
    }

    function releaseTokenForSaleWallet(uint256 currentTimestamp)
        internal
        returns (uint256 releasingAmount)
    {
        // from 1st month from creation date => release 15,950,000 tokens and stop this rule at end of 9th month
        // at 10th month=> release 6,150,000 tokens and end till token of this wallet is done
        uint256 diffMonth = getDiffMonth(
            Constant.SHOPNEXTWALLETYPESALE,
            currentTimestamp
        );

        if (
            !checkReleaseTime(Constant.SHOPNEXTWALLETYPESALE, currentTimestamp)
        ) {
            return 0;
        }
        if (diffMonth >= 1 && diffMonth <= 9) {
            releasingAmount = 15950000 * (10**18);
        }

        if (diffMonth >= 10) {
            releasingAmount = 6150000 * (10**18);
        }
        if (releasingAmount == 0) {
            return 0;
        }
        if (
            !giveFundToWallet(
                Constant.SHOPNEXTWALLETYPESALE,
                releasingAmount,
                currentTimestamp
            )
        ) {
            return 0;
        }
    }

    function releaseTokenForCommunityWallet(uint256 currentTimestamp)
        internal
        returns (uint256 releasingAmount)
    {
        // at 1st month from creation date => release 5,000,000 tokens and till token of this wallet is done
        uint256 diffMonth = getDiffMonth(
            Constant.SHOPNEXTWALLETYPECOMMUNITY,
            currentTimestamp
        );

        if (
            !checkReleaseTime(
                Constant.SHOPNEXTWALLETYPECOMMUNITY,
                currentTimestamp
            )
        ) {
            return 0;
        }

        if (diffMonth >= 1) {
            releasingAmount = 5000000 * (10**18);
        }
        if (releasingAmount == 0) {
            return 0;
        }

        if (
            !giveFundToWallet(
                Constant.SHOPNEXTWALLETYPECOMMUNITY,
                releasingAmount,
                currentTimestamp
            )
        ) {
            return 0;
        }
    }

    function releaseTokenForCompanyWallet(uint256 currentTimestamp)
        internal
        returns (uint256 releasingAmount)
    {
        // skipping for 1 year from creation date
        // at 13th month, release 200,000,000/36 each month and end till token of this wallet is done   or meet deadline by end of 47th month

        uint256 diffMonth = getDiffMonth(
            Constant.SHOPNEXTWALLETYPECOMPANY,
            currentTimestamp
        );

        if (
            !checkReleaseTime(
                Constant.SHOPNEXTWALLETYPECOMPANY,
                currentTimestamp
            )
        ) {
            return 0;
        }
        if (diffMonth >= 13 && diffMonth <= 47) {
            releasingAmount = 5555555 * (10**18);
        }

        if (releasingAmount == 0) {
            return 0;
        }

        if (
            !giveFundToWallet(
                Constant.SHOPNEXTWALLETYPECOMPANY,
                releasingAmount,
                currentTimestamp
            )
        ) {
            return 0;
        }
    }

    function releaseTokenForMarketingWallet(uint256 currentTimestamp)
        internal
        returns (uint256 releasingAmount)
    {
        // at 1st month from creation date => release 3,125,000 tokens and till token of this wallet is done

        uint256 diffMonth = getDiffMonth(
            Constant.SHOPNEXTWALLETYPEMARKETING,
            currentTimestamp
        );

        if (
            !checkReleaseTime(
                Constant.SHOPNEXTWALLETYPEMARKETING,
                currentTimestamp
            )
        ) {
            return 0;
        }

        if (diffMonth >= 1) {
            releasingAmount = 3125000 * (10**18);
        }
        if (releasingAmount == 0) {
            return 0;
        }

        if (
            !giveFundToWallet(
                Constant.SHOPNEXTWALLETYPEMARKETING,
                releasingAmount,
                currentTimestamp
            )
        ) {
            return 0;
        }
    }

    function giveFundToWallet(
        string memory walletType,
        uint256 releasingAmount,
        uint256 currentTimestamp
    ) internal returns (bool) {
        if (
            _totalTokenSize[walletType] <
            _releasedTokenSize[walletType].add(releasingAmount)
        ) {
            return false;
        }
        BEP20 bep20 = BEP20(_tokenAddress);
        _releasedTokenSize[walletType] = _releasedTokenSize[walletType].add(
            releasingAmount
        );

        address factoryAddress = address(this);
        address walletAddress = _walletByType[walletType];
        bep20.increaseAllowance(factoryAddress, releasingAmount);
        bep20.transferFrom(factoryAddress, walletAddress, releasingAmount);

        ReleaseTokenInfo info = new ReleaseTokenInfo(
            currentTimestamp,
            releasingAmount
        );
        _releaseTokenHistory[walletType].push(info);
        return true;
    }

    function getDiffMonth(string memory walletType, uint256 currentTimestamp)
        internal
        view
        returns (uint256)
    {
        return (
            dateTime.diffMonth(
                currentTimestamp,
                _walletCreationDateTime[walletType]
            )
        );
    }

    function checkReleaseTime(
        string memory walletType,
        uint256 currentTimestamp
    ) internal view returns (bool) {
        (uint256 month, uint256 year) = (
            dateTime.getMonth(currentTimestamp),
            dateTime.getYear(currentTimestamp)
        );

        uint8 i = 0;
        for (i; i < _releaseTokenHistory[walletType].length; i++) {
            (uint256 checkMonth, uint256 checkYear) = (
                dateTime.getMonth(
                    _releaseTokenHistory[walletType][i].getReleasedTime()
                ),
                dateTime.getYear(
                    _releaseTokenHistory[walletType][i].getReleasedTime()
                )
            );
            if (checkMonth == month && checkYear == year) {
                return false;
            }
        }
        return true;
    }

    // Prevents accidental sending of BNB to the factory
    fallback() external payable {
        // revert();
    }

    receive() external payable {
        // custom function code
    }

    event Created(
        address wallet,
        address from,
        address to,
        uint256 createdAt,
        uint256 amount
    );

    event ReleaseTokenForWallets(address tokenAddress, uint256 totalAmount);
}

