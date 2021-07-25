/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-11
*/

/**
*Submitted for verification at BscScan.com on 2021-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
return msg.data;
}
}

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
function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
unchecked {
require(b <= a, errorMessage);
return a - b;
}
}

/**
* @dev Returns the integer division of two unsigned integers, reverting with custom message on
* division by zero. The result is rounded towards zero.
*
* Counterpart to Solidity's `%` operator. This function uses a `revert`
* opcode (which leaves remaining gas untouched) while Solidity uses an
* invalid opcode to revert (consuming all remaining gas).
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
function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
unchecked {
require(b > 0, errorMessage);
return a % b;
}
}
}

pragma solidity =0.8.0;

contract BSC20 is Context {

using SafeMath for uint256;

mapping (address => uint256) private _balances;
mapping (address => mapping (address => uint256)) private _allowances;

string private _name;
string private _symbol;
uint8 private _decimals;

uint256 _totalSupply;

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

constructor () {
_name = "BLANETTEST";
_symbol = "BLANETTEST"; 
_decimals = 18;

_mint(_msgSender(), 1000000000E18);
}

/**
* @dev Returns the name of the token.
*/
function name() public view returns (string memory) {
return _name;
}

/**
* @dev Returns the symbol of the token.
*/
function symbol() public view returns (string memory) {
return _symbol;
}

/**
* @dev Returns the decimals of the token.
*/
function decimals() public view returns (uint8) {
return _decimals;
}

/**
* @dev Returns the total supply of the token.
*/
function totalSupply() public view returns (uint256) {
return _totalSupply;
}

/**
* @dev Returns the token balance of specific address.
*/
function balanceOf(address account) public view returns (uint256) {
return _balances[account];
}

function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(_msgSender(), recipient, amount );

return true;
}

/**
* @dev Returns approved balance to be spent by another address
* by using transferFrom method
*/
function allowance(address owner, address spender) public view returns (uint256) {
return _allowances[owner][spender];
}

/**
* @dev Sets the token allowance to another spender
*/
function approve(address spender, uint256 amount) public returns (bool) {
_approve(_msgSender(), spender, amount);

return true;
}

/**
* @dev Allows to transfer tokens on senders behalf
* based on allowance approved for the executer
*/
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
_transfer(sender, recipient, amount);

return true;
}

/**
* @dev Moves tokens `amount` from `sender` to `recipient`.
*
* Emits a {Transfer} event.
* Requirements:
*
* - `sender` cannot be the zero address.
* - `recipient` cannot be the zero address.
* - `sender` must have a balance of at least `amount`.
*/
function _transfer(address sender, address recipient, uint256 amount) internal virtual {
require(sender != address(0x0));
require(recipient != address(0x0));

_balances[sender] = _balances[sender].sub(amount);
_balances[recipient] = _balances[recipient].add(amount);

emit Transfer(sender, recipient, amount);
}

/** @dev Creates `amount` tokens and assigns them to `account`, increasing
* the total supply.
*
* Emits a {Transfer} event with `from` set to the zero address.
* Requirements:
*
* - `to` cannot be the zero address.
*/
function _mint(address account, uint256 amount) internal virtual {
require(account != address(0x0));

_totalSupply = _totalSupply.add(amount);
_balances[account] = _balances[account].add(amount);

emit Transfer(address(0x0), account, amount);
}

/**
* @dev Allows to burn tokens if token sender
* wants to reduce totalSupply() of the token
*/
function burn(uint256 amount) external {
_burn(msg.sender, amount);
}

/**
* @dev Destroys `amount` tokens from `account`, reducing the
* total supply.
*
* Emits a {Transfer} event with `to` set to the zero address.
*
* Requirements:
*
* - `account` cannot be the zero address.
* - `account` must have at least `amount` tokens.
*/
function _burn(address account, uint256 amount) internal virtual {
require(account != address(0x0));

_balances[account] = _balances[account].sub(amount);
_totalSupply = _totalSupply.sub(amount);

emit Transfer(account, address(0x0), amount);
}

/**
* @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
* Emits an {Approval} event.
*
* Requirements:
*
* - `owner` cannot be the zero address.
* - `spender` cannot be the zero address.
*/
function _approve(address owner, address spender, uint256 amount) internal virtual {
require(owner != address(0x0));
require(spender != address(0x0));

_allowances[owner][spender] = amount;

emit Approval(owner, spender, amount);
}
}