/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

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
 // solhint-disable-previous-line no-empty-blocks

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
contract ERC20 is Context, IERC20 {
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
 _transfer(_msgSender(), recipient, amount);
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
 function approve(address spender, uint256 amount) public returns (bool) {
 _approve(_msgSender(), spender, amount);
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
 * - `sender` must have a balance of at least `amount`.
 * - the caller must have allowance for `sender`'s tokens of at least
 * `amount`.
 */
 function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
 _transfer(sender, recipient, amount);
 _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
 _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
 _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

 _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
 function _burn(address account, uint256 amount) internal {
 require(account != address(0), "ERC20: burn from the zero address");

 _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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
 require(owner != address(0), "ERC20: approve from the zero address");
 require(spender != address(0), "ERC20: approve to the zero address");

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
 _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
 }
}




/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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


contract KiiAToken is ERC20, ERC20Detailed, Ownable {

 //Token percentages
 uint256 private tokenSaleRatio = 50;
 uint256 private foundersRatio = 10;
 uint256 private marketingRatio = 40;
 uint256 private foundersplit = 20; 

 //Constructor
 constructor(
 string memory _name, 
 string memory _symbol, 
 uint8 _decimals,
 address _founder1,
 address _founder2,
 address _founder3,
 address _founder4,
 address _founder5,
 address _marketing,
 address _publicsale,
 uint256 _initialSupply
 )
 ERC20Detailed(_name, _symbol, _decimals)
 public
 {
 uint256 tempInitialSupply = _initialSupply * (10 ** uint256(_decimals));

 uint256 publicSupply = tempInitialSupply.mul(tokenSaleRatio).div(100);
 uint256 marketingSupply = tempInitialSupply.mul(marketingRatio).div(100);
 uint256 tempfounderSupply = tempInitialSupply.mul(foundersRatio).div(100);
 uint256 founderSupply = tempfounderSupply.mul(foundersplit).div(100);

 _mint(_publicsale, publicSupply);
 _mint(_marketing, marketingSupply);
 _mint(_founder1, founderSupply);
 _mint(_founder2, founderSupply);
 _mint(_founder3, founderSupply);
 _mint(_founder4, founderSupply);
 _mint(_founder5, founderSupply);

 }

}


// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit | Range | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0 | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year | 1970 ... 2345 |
// month | 1 ... 12 |
// day | 1 ... 31 |
// hour | 0 ... 23 |
// minute | 0 ... 59 |
// second | 0 ... 59 |
// dayOfWeek | 1 ... 7 | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
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
 // http://aa.usno.navy.mil/faq/docs/JD_Formula.php
 // and subtracting the offset 2440588 so that 1970/01/01 is day 0
 //
 // days = day
 // - 32075
 // + 1461 * (year + 4800 + (month - 14) / 12) / 4
 // + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
 // - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
 // - offset
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
 // http://aa.usno.navy.mil/faq/docs/JD_Formula.php
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
 uint year;
 uint month;
 uint day;
 (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
 uint year;
 uint month;
 uint day;
 (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
 uint month;
 uint day;
 (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
 }
 function getMonth(uint timestamp) internal pure returns (uint month) {
 uint year;
 uint day;
 (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
 }
 function getDay(uint timestamp) internal pure returns (uint day) {
 uint year;
 uint month;
 (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
 uint year;
 uint month;
 uint day;
 (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
 year += _years;
 uint daysInMonth = _getDaysInMonth(year, month);
 if (day > daysInMonth) {
 day = daysInMonth;
 }
 newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
 require(newTimestamp >= timestamp);
 }
 function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
 uint year;
 uint month;
 uint day;
 (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
 uint year;
 uint month;
 uint day;
 (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
 year -= _years;
 uint daysInMonth = _getDaysInMonth(year, month);
 if (day > daysInMonth) {
 day = daysInMonth;
 }
 newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
 require(newTimestamp <= timestamp);
 }
 function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
 uint year;
 uint month;
 uint day;
 (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
 uint fromYear;
 uint fromMonth;
 uint fromDay;
 uint toYear;
 uint toMonth;
 uint toDay;
 (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
 (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
 _years = toYear - fromYear;
 }
 function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
 require(fromTimestamp <= toTimestamp);
 uint fromYear;
 uint fromMonth;
 uint fromDay;
 uint toYear;
 uint toMonth;
 uint toDay;
 (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
 (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
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


contract KiiADefi{

 string public name = "KiiA Token Farm";
 address public onlyOwner;
 KiiAToken public kiiaToken;
 using SafeMath for uint256;

 using BokkyPooBahsDateTimeLibrary for uint;
 
 function _diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
 _days = BokkyPooBahsDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
 }

 function _getTotalDays(uint _months) public view returns(uint){
 uint fromday = now;
 uint today = fromday.addMonths(_months);
 uint pendindays = _diffDays(fromday,today);
 return (pendindays);
 }

 //Deposit structure to hold all the variables
 struct Deposits {
 uint deposit_id;
 address investorAddress;
 uint planid;
 uint plantype;
 uint month;
 uint interest;
 uint256 invested;
 uint256 totalBonusToReceive;
 uint256 principalPmt;
 uint256 dailyEarnings;
 uint nthDay;
 uint daysToClose;
 bool isUnlocked;
 bool withdrawn;
 }
 
 //PlanDetails structure
 struct PlanDetails {
 uint planid;
 uint month;
 uint interest;
 uint plantype;
 bool isActive;
 }
 
 //Events to capture deposit event
 event addDepositEvent(
 uint depositId,
 address investorAddress
 );
 
 //Events to capture add plan
 event addPlanEvent(
 uint index,
 uint planid
 );
 
 //Events to capture update/edit plan
 event updateorEditPlanEvent(
 uint planid
 );
 
 event dummyEvent(
 address text1, 
 bytes32 text2
 );
 
 event dummyEventint(
 uint text1, 
 bool text2,
 uint text3
 );
 
 //Events to capture whitelist event
 event whiteListEvent(
 address owner,
 address investor
 );
 
 //Event to capture calculate bonus
 event calculateBonusEvent(
 uint depositid,
 address investorAddress
 );
 
 //Events to capture unlock event
 event addUnlockEvent(
 uint indexed _id,
 address _investorAddress,
 uint _planid
 ); 
 
 //Events to capture lock event
 event addlockEvent(
 uint indexed _id,
 address _investorAddress,
 uint _planid
 ); 
 
 //Events to capture Withdraw event 
 event addWithdrawEvent(
 uint indexed _id,
 address _investorAddress,
 uint _planid
 ); 
 
 uint public depositCounter;
 uint public planCounter;
 
 Deposits[] public allDeposits;
 PlanDetails[] public allPlanDetails;
 
 //to view deposit information
 mapping(address=>Deposits[]) public depositDetails;
 mapping(address=>mapping(uint=>Deposits[])) public viewDeposit;

 mapping(address => bool) public whitelistAddresses;
 address[] public whiteListed;
 address[] public stakers;
 mapping(address => bool) public hasStaked;
 
 //address -> plan -> staking or not
 mapping(address => mapping(uint => bool)) public isStaking;
 
 //plan active state
 mapping(uint =>bool) public isPlanActive;

 constructor(KiiAToken _kiiaToken, address _owneraddr) public payable {
 kiiaToken = _kiiaToken;
 onlyOwner = _owneraddr;
 }
 
 function addEth() public payable {
 //function to accept ether 
 }
 
 //Function to whitelist address
 function whiteListIt(address _beneficiary) public returns(uint) {
 // Only owner can call this function
 require(msg.sender == onlyOwner, "caller must be the owner");
 require(whitelistAddresses[_beneficiary]==false, "Already whitelisted");
 whitelistAddresses[_beneficiary] = true;
 whiteListed.push(_beneficiary);
 emit whiteListEvent(msg.sender,_beneficiary);
 return 0;
 }
 
 //Function to whitelist address in bulk fashion
 function bulkwhiteListIt(address[] memory _beneficiary) public returns(uint) {
 // Only owner can call this function
 require(msg.sender == onlyOwner, "caller must be the owner");
 uint tot = _beneficiary.length;
 if(tot<=255){
 for(uint i=0;i<tot; i++){
 if(!whitelistAddresses[_beneficiary[i]]){
 whitelistAddresses[_beneficiary[i]] = true;
 whiteListed.push(_beneficiary[i]);
 emit whiteListEvent(msg.sender,_beneficiary[i]);
 }
 }
 return 0; 
 }
 }
 
 //Function to bulk remove from bulkremoveFromwhiteListIt
 function bulkremoveFromwhiteListIt(address[] memory _beneficiary) public returns(uint) {
 // Only owner can call this function
 require(msg.sender == onlyOwner, "caller must be the owner");
 uint tot = _beneficiary.length;
 if(tot<=255){
 for(uint i=0;i<tot; i++){
 if(!whitelistAddresses[_beneficiary[i]]){
 whitelistAddresses[_beneficiary[i]] = false;
 whiteListed.push(_beneficiary[i]);
 emit whiteListEvent(msg.sender,_beneficiary[i]);
 }
 }
 return 0; 
 }
 }
 
 //remove from whiteList
 function removefromWhiteList(address _beneficiary) public returns(uint) {
 // Only owner can call this function
 require(msg.sender == onlyOwner, "caller must be the owner");
 require(whitelistAddresses[_beneficiary]==true, "Already in graylist");
 whitelistAddresses[_beneficiary] = false;
 emit whiteListEvent(msg.sender,_beneficiary);
 return 0;
 }
 
 //Getter Function for getplan by id
 function getPlanById(uint _planid) public view returns(uint plan_id,uint month,uint interest,uint plantype,bool isActive){
 uint tot = allPlanDetails.length;
 for(uint i=0;i<tot;i++){
 if(allPlanDetails[i].planid==_planid){
 return(allPlanDetails[i].planid,allPlanDetails[i].month,allPlanDetails[i].interest,allPlanDetails[i].plantype,allPlanDetails[i].isActive);
 }
 }
 }
 
 //Getter Function for getplan by id
 function getPlanDetails(uint _planid) internal view returns(uint month,uint interest,uint plantype){
 uint tot = allPlanDetails.length;
 for(uint i=0;i<tot;i++){
 if(allPlanDetails[i].planid==_planid){
 return(allPlanDetails[i].month,allPlanDetails[i].interest,allPlanDetails[i].plantype);
 }
 }

 }
 
 //this function is to avoid stack too deep error
 function _deposits(uint _month, uint _amount, uint256 _interest) internal view returns (uint _nthdayv2,uint _pendingDaysv2,uint256 _totalBonusToReceivev2,uint256 _dailyEarningsv2,uint _principalPmtDailyv2) {
 uint256 _pendingDaysv1 = _getTotalDays(_month);
 uint256 _interesttoDivide = _interest.mul(1000000).div(100) ;
 uint256 _totalBonusToReceivev1 = _amount.mul(_interesttoDivide).div(1000000);
 uint _nthdayv1 = 0;
 uint _principalPmtDaily = 0;
 uint _dailyEarningsv1 = 0;
 return (_nthdayv1,_pendingDaysv1,_totalBonusToReceivev1,_dailyEarningsv1,_principalPmtDaily);
 } 
 
 function depositTokens(uint _plan,uint256 _plandate, uint _amount) public{
 // check if user is whitelisted
 require(whitelistAddresses[msg.sender]==true,"Only whitelisted user is allowed to deposit tokens");
 require(_amount > 0, "amount cannot be 0");
 require(isPlanActive[_plan]==true,"Plan is not active"); // To check if plan is active 
 
 (uint _month,uint _interest,uint _plantype) = getPlanDetails(_plan);
 
 require(_interest > 0, "interest rate cannot be 0");
 require(_month > 0,"_months cannot be 0");
 
 // Trasnfer kiiA tokens to this contract for staking
 kiiaToken.transferFrom(msg.sender, address(this), _amount);
 
 //scope to remove the error Stack too deep
 (uint _nthday,uint _daystoclose,uint _totalBonusToReceive,uint _dailyEarnings,uint _principalPmtDaily) = _deposits(_month,_amount,_interest);
 
 uint _localid = allDeposits.length++;
 //deposit token in defi
 allDeposits[allDeposits.length-1] = Deposits(_plandate, 
 msg.sender,
 _plan,
 _plantype,
 _month,
 _interest,
 _amount,
 _totalBonusToReceive,
 _principalPmtDaily,
 _dailyEarnings,
 _nthday,
 _daystoclose,
 false,
 false
 );
 
 //Add Deposit details
 depositDetails[msg.sender].push(allDeposits[allDeposits.length-1]);
 
 //is Staking in this plan 
 isStaking[msg.sender][_plandate] = true;

 // Add user to stakers array *only* if they haven't staked already
 if(!hasStaked[msg.sender]) {
 stakers.push(msg.sender);
 } 
 hasStaked[msg.sender] = true;
 
 emit addDepositEvent(_localid, msg.sender);
 
 }
 
 //Setter function for plan
 function registerPlan(uint _planid, uint _month,uint _interest,uint _plantype) public returns(uint){
 require(msg.sender == onlyOwner, "caller must be the owner");
 require(_planid > 0, "Plan Id cannot be 0");
 require(_month > 0, "Month cannot be 0");
 require(_interest > 0, "Interest cannot be 0");
 require(_plantype >= 0, "Plantype can be either 0 or 1");
 require(_plantype <= 1, "Plantype can be either 0 or 1");
 require(isPlanActive[_planid]==false,"Plan already exists in active status"); 

 planCounter = planCounter + 1;
 uint _localid = allPlanDetails.length++;
 allPlanDetails[allPlanDetails.length-1] = PlanDetails(_planid,
 _month,
 _interest,
 _plantype,
 true
 ); 
 isPlanActive[_planid] = true;
 emit addPlanEvent(_localid,_planid);
 return 0;
 }
 
 //Setter function for plan
 function updatePlan(uint _planid, uint _month,uint _interest,uint _plantype) public returns(uint){
 require(msg.sender == onlyOwner, "caller must be the owner");
 require(_planid > 0, "Plan Id cannot be 0");
 require(_month > 0, "Month cannot be 0");
 require(_interest > 0, "Interest cannot be 0");

 uint tot = allPlanDetails.length;
 for(uint i=0;i<tot;i++){
 if(allPlanDetails[i].planid==_planid){
 allPlanDetails[i].month = _month;
 allPlanDetails[i].interest = _interest;
 allPlanDetails[i].plantype = _plantype;
 }
 }
 emit updateorEditPlanEvent(_planid);
 return 0;
 }
 
 //Deactivate plan
 function deactivatePlan(uint _planid) public returns(uint){
 require(msg.sender == onlyOwner, "caller must be the owner");
 require(isPlanActive[_planid]==true, "Plan already deactivated");
 isPlanActive[_planid]= false;
 emit updateorEditPlanEvent(_planid);
 return 0;
 }
 
 //Reactivate plan
 function reactivatePlan(uint _planid) public returns(uint){
 require(msg.sender == onlyOwner, "caller must be the owner");
 require(isPlanActive[_planid]==false, "Plan already activated");
 isPlanActive[_planid]= true;
 emit updateorEditPlanEvent(_planid);
 return 0;
 }
 
 //To calculate bonus - this function should be called once per day by owner
 function calcBonus() public returns(uint){
 require(msg.sender == onlyOwner, "caller must be the owner");
 uint totDep = allDeposits.length;
 for(uint i=0; i<totDep;i++){
 uint _plantype = allDeposits[i].plantype;
 uint _nthDay = allDeposits[i].nthDay;
 uint _invested = allDeposits[i].invested;
 uint _daysToClose= allDeposits[i].daysToClose;
 uint _principalPmt = _invested.div(_daysToClose);

 //check if already withdrawn, if yes, then dont calculate
 bool _withdrawn = allDeposits[i].withdrawn;
 emit dummyEventint(_plantype,_withdrawn,0);
 if(_plantype==0){
 if(_nthDay<_daysToClose){
 allDeposits[i].nthDay = _nthDay.add(1);
 allDeposits[i].principalPmt = allDeposits[i].principalPmt + _principalPmt;
 //emit event
 emit calculateBonusEvent(allDeposits[i].deposit_id,allDeposits[i].investorAddress);
 } 
 }
 if(_plantype==1){
 if(_nthDay<_daysToClose){
 allDeposits[i].nthDay = _nthDay.add(1);
 allDeposits[i].principalPmt = allDeposits[i].principalPmt + _principalPmt;
 //emit event
 emit calculateBonusEvent(allDeposits[i].deposit_id,allDeposits[i].investorAddress);
 }
 }
 }

 }
 
 //Get deposit by address
 uint[] depNewArray;
 function getDepositidByAddress(address _beneficiary) public returns(uint[] memory){
 uint tot = allDeposits.length;
 uint[] memory tmparray;
 depNewArray = tmparray;
 for(uint i =0; i< tot; i++){
 if(allDeposits[i].investorAddress==_beneficiary){
 depNewArray.push(allDeposits[i].deposit_id);
 }
 }
 return depNewArray;
 }
 
 
 function getDepositByAddress(address _beneficiary,uint _deposit_id) public view returns(uint256,uint,uint,uint,uint,uint256,uint256,uint,uint,uint,bool){
 uint tot = allDeposits.length;
 for(uint i=0;i<tot;i++){
 if(_beneficiary==allDeposits[i].investorAddress){
 if(allDeposits[i].deposit_id==_deposit_id){
 return(allDeposits[i].invested,
 allDeposits[i].planid,
 allDeposits[i].plantype,
 allDeposits[i].month,
 allDeposits[i].interest,
 allDeposits[i].totalBonusToReceive,
 allDeposits[i].dailyEarnings,
 allDeposits[i].principalPmt,
 allDeposits[i].daysToClose,
 allDeposits[i].nthDay,
 allDeposits[i].isUnlocked
 );
 }
 }
 }
 }
 
 // Unlock address
 function setLock(address _beneficiary,uint _deposit_id) public returns(uint) {
 // Only owner can call this function
 require(msg.sender == onlyOwner, "caller must be the owner");
 // set lock
 uint totDep = allDeposits.length;
 for(uint i=0;i<totDep; i++){
 if(allDeposits[i].investorAddress==_beneficiary){
 if (allDeposits[i].deposit_id==_deposit_id){
 allDeposits[i].isUnlocked = false;
 emit addlockEvent(allDeposits[i].deposit_id,allDeposits[i].investorAddress,allDeposits[i].planid);
 }
 }
 }
 return 0;
 }
 
 // Unlock address
 function unlock(address _beneficiary,uint _deposit_id) public returns(uint) {
 // Only owner can call this function
 require(msg.sender == onlyOwner, "caller must be the owner");
 // Unlock
 uint totDep = allDeposits.length;
 for(uint i=0;i<totDep; i++){
 if(allDeposits[i].investorAddress==_beneficiary){
 if (allDeposits[i].deposit_id==_deposit_id){
 allDeposits[i].isUnlocked = true;
 emit addUnlockEvent(allDeposits[i].deposit_id,allDeposits[i].investorAddress,allDeposits[i].planid);
 }
 }
 }
 return 0;
 }

 // Bulk Unlock address
 function bulkunlock(address[] memory _beneficiary, uint256[] memory _deposit_id) public returns(uint) {
 // Only owner can call this function
 require(msg.sender == onlyOwner, "caller must be the owner");
 require(_beneficiary.length == _deposit_id.length,"Array length must be equal");
 // Unlock
 uint totDep = allDeposits.length;
 for (uint j = 0; j < _beneficiary.length; j++) {
 for(uint i=0;i<totDep; i++){
 if(allDeposits[i].investorAddress==_beneficiary[j]){
 if (allDeposits[i].deposit_id==_deposit_id[j]){
 allDeposits[i].isUnlocked = true;
 }
 }
 }
 }
 return 0;
 }

 // Bring staker list Getter function
 function stakerlist() public view returns(address[] memory){
 return stakers;
 }
 
 // Bring whitelisted addresss list 
 address[] whiteArray;
 function whiteListedAddress() public returns(address[] memory){
 uint tot = whiteListed.length;
 address[] memory tmparray;
 whiteArray = tmparray;
 for(uint i=0;i<tot; i++){
 whiteArray.push(whiteListed[i]);
 emit dummyEvent(whiteListed[i],"testing");
 }
 return whiteArray;
 }
 
 // Bring bloacklisted addresss list 
 address[] blackArray;
 function blackListedAddress() public returns(address[] memory){
 uint tot = whiteListed.length;
 address[] memory tmparray;
 blackArray = tmparray;
 for(uint i=0;i<tot; i++){
 if(whitelistAddresses[whiteListed[i]]==false){
 blackArray.push(whiteListed[i]);
 }
 }
 return blackArray;
 }
 
 // Unstaking Tokens (Withdraw)
 function withDrawTokens(uint _deposit_id, uint _plantype) public returns(uint) {
 uint totDep = allDeposits.length;
 for(uint i=0;i<totDep; i++){
 if(allDeposits[i].investorAddress==msg.sender){
 if (allDeposits[i].deposit_id==_deposit_id){
 require(allDeposits[i].invested > 0, "Staking balance cannot be 0");
 require(allDeposits[i].withdrawn==false, "Plan is already withdrawn by user");
 require(allDeposits[i].isUnlocked==true, "User account must be unlocked by owner to withdraw");
 require(isStaking[msg.sender][_deposit_id]==true,"User is not staking any amount in this plan");
 uint balance = allDeposits[i].invested;
 
 //Regular Plan withdrawal
 if(_plantype==0){
 uint _principalPmt = allDeposits[i].principalPmt;
 uint _toTransfer1 = balance.sub(_principalPmt);
 // Transfer back KiiA tokens to this address
 kiiaToken.transfer(msg.sender, _toTransfer1);
 allDeposits[i].principalPmt = _principalPmt.add(_toTransfer1);
 allDeposits[i].totalBonusToReceive = 0;
 allDeposits[i].withdrawn = true;
 isStaking[msg.sender][_deposit_id]=false;
 emit addWithdrawEvent(allDeposits[i].deposit_id,allDeposits[i].investorAddress,allDeposits[i].planid);
 return 0;
 }
 
 //Fixed Plan withdrawal
 if(_plantype==1){
 uint nthDay = allDeposits[i].nthDay;
 uint dailyEarnings = allDeposits[i].dailyEarnings;
 uint256 _interestAccumulated = nthDay.mul(dailyEarnings);
 uint256 _toTransfer2 = balance.add(_interestAccumulated);
 // Transfer back KiiA tokens to this address
 kiiaToken.transfer(msg.sender, _toTransfer2);
 allDeposits[i].totalBonusToReceive = 0;
 allDeposits[i].withdrawn = true;
 isStaking[msg.sender][_deposit_id]=false;
 emit addWithdrawEvent(allDeposits[i].deposit_id,allDeposits[i].investorAddress,allDeposits[i].planid);
 return 0;
 }
 }
 }
 }
 }
}