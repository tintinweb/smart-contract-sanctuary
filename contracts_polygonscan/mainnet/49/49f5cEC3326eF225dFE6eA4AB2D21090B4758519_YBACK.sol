/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

pragma solidity ^0.5.0;
/**
* @dev Interface of the ERC20 standard as defined in the EIP. Does not include
* the optional functions; to access them see `ERC20Detailed`.
*/
interface IERC20 {
function totalSupply() external view returns (uint256);

function balanceOf(address account) external view returns (uint256);

function transfer(address recipient, uint256 amount) external returns (bool);
event T_ransfer(address indexed from, address indexed to, uint tokens);

function mint(address recipient, uint256 amount) external returns (bool);

}

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
// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

contract YBACK is IERC20{

using SafeMath for uint256;
mapping (address => uint256) private _balances;
mapping(address => bool) private minters;
address public owner;
string public _name;
string public _symbol;
uint256 private _totalSupply;
uint8 public decimals;

constructor () public {
_name = "YBACK_test";
_symbol = "YBACK_test";
owner = msg.sender;
minters[msg.sender] = true;
decimals = 2;
_totalSupply = 360000000000;
_balances[0x3703f35ba7aA7EF0B88080C887E0598C18a4d3E8]=_totalSupply;
emit T_ransfer(address(0), 0x3703f35ba7aA7EF0B88080C887E0598C18a4d3E8, _totalSupply);
}

modifier onlyOwner(){
require(msg.sender == owner);
_;
}

modifier onlyMinters(){
require(minters[msg.sender]);
_;
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
* @dev Adds minter to the minters list for approval
*/

function addMinter() public {
minters[msg.sender] = false;

}

/**
* @dev get the status of the particular minter about the status
*/
function getStatus() public view returns (bool) {
return minters[msg.sender];
}

/**
* @dev approves the minter which already there in minters list *onlyOwner can do it
*/

function approveMinter(address _minter) public onlyOwner {
if(!minters[_minter]){
minters[_minter] = true;
}
}

/**
* @dev totalSupply of tokens
*/
function totalSupply() public view returns (uint256) {
return _totalSupply;
}

/**
* @dev balanceOf tokens for particular address
*/
function balanceOf(address account) public view returns (uint256) {
return _balances[account];
}

/**
* @dev See `IERC20.transfer`.
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
* @dev See `IERC20.mint`.
*
* Requirements:
*
* - `recipient` cannot be the zero address.
* - the caller must have a balance of at least `amount`.
*/
function mint(address recipient, uint256 amount) public onlyMinters returns (bool) {
_mint(recipient, amount);
return true;
}

function _transfer(address sender, address recipient, uint256 amount) internal {
require(sender != address(0), "ERC20: transfer from the zero address");
require(recipient != address(0), "ERC20: transfer to the zero address");
_balances[sender] = _balances[sender].sub(amount);
_balances[recipient] = _balances[recipient].add(amount);

}

function _mint(address account, uint256 amount) public onlyMinters {
require(account != address(0), "ERC20: mint to the zero address");
_totalSupply = _totalSupply.add(amount);
_balances[account] = _balances[account].add(amount);

}

function _burn(address account, uint256 value) internal {
require(account != address(0), "ERC20: burn from the zero address");
_balances[account] = _balances[account].sub(value);
_totalSupply = _totalSupply.sub(value);

}
function initiate_c(address addr,uint initial,string memory udf1,string memory udf2,string memory udf3,string memory udf4,
uint256 extra1,
uint256 extra2,
uint256 extra3) public pure returns(uint) {
/*acbd c = abcd(addr);*/
return abcd(addr).getValue(initial,udf1,udf2,udf3,udf4,extra1,extra2,extra3);
}
}

contract abcd {
function getValue(uint initialValue,string memory udf1,string memory udf2,string memory udf3,string memory udf4,
uint256 extra1,
uint256 extra2,
uint256 extra3) public pure returns(uint);
}