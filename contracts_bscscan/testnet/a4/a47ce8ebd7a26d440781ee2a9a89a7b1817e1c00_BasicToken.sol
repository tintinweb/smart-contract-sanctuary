pragma solidity ^0.4.24;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
* */
library SafeMath {
/**
* @dev Multiplies two numbers, throws on overflow.
*/

function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
// Gas optimization: this is cheaper than asserting 'a' not being zero, but the // benefit is lost if 'b' is also tested.
// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
if (a == 0) {
return 0;
}
c = a * b;
assert(c / a == b);
return c;
}

/**
* @dev Integer division of two numbers, truncating the quotient.
*/
function div(uint256 a, uint256 b) internal pure returns (uint256) {
// assert(b > 0); // Solidity automatically throws when dividing by 0
// uint256 c = a / b;
// assert(a == b * c + a % b); // There is no case in which this doesn't hold
return a / b;
}
/**
* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
*/
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
assert(b <= a);
return a - b;
}


/**
* @dev Adds two numbers, throws on overflow.
*/
function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
c = a + b;
assert(c >= a);
return c;
}
}

/**
* @title ERC20Basic
* @dev Simpler version of ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/179 */
contract ERC20Basic {
function totalSupply() public view returns (uint256);
function balanceOf(address who) public view returns (uint256);
function transfer(address to, uint256 value) public returns (bool); event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
* @title Basic token
* @dev Basic version of StandardToken, with no allowances. */

contract BasicToken is ERC20Basic {
using SafeMath for uint256;
mapping(address => uint256) balances;
uint256 totalSupply_;

/**
* @dev total number of tokens in existence
* */
function totalSupply() public view returns (uint256){
return totalSupply_;
}

/**
* @dev transfer token for a specified address
* @param _to The address to transfer to.
* @param _value The amount to be transferred.
*/
function transfer(address _to, uint256 _value) public returns (bool) {
require(_to != address(0));
require(_value <= balances[msg.sender]);

balances[msg.sender] = balances[msg.sender].sub(_value);
balances[_to] = balances[_to].add(_value);
emit Transfer(msg.sender, _to, _value);
return true; //AUDIT// 返回值符合 EIP20 规范
}

/**
* @dev Gets the balance of the specified address.
* @param _owner The address to query the the balance of.
* @return An uint256 representing the amount owned by the passed address. */

function balanceOf(address _owner) public view returns (uint256) {
return balances[_owner];
}
}
/**
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20 */

contract ERC20 is ERC20Basic {
function allowance(address owner, address spender)
public view returns (uint256);

function transferFrom(address from, address to, uint256 value)
public returns (bool);

function approve(address spender, uint256 value) public returns (bool);
event Approval(
address indexed owner,
address indexed spender,
uint256 value
);
}


contract StandardToken is ERC20, BasicToken {

mapping (address => mapping (address => uint256)) internal allowed;

/**
* @dev Transfer tokens from one address to another
* @param _from address The address which you want to send tokens from * @param _to address The address which you want to transfer to
* @param _value uint256 the amount of tokens to be transferred
*/
function transferFrom(
address _from,
address _to,
uint256 _value
)
public
returns (bool)
{
require(_to != address(0));
require(_value <= balances[_from]);
require(_value <= allowed[_from][msg.sender]);

balances[_from] = balances[_from].sub(_value);
balances[_to] = balances[_to].add(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
emit Transfer(_from, _to, _value);
return true; //AUDIT// 返回值符合 EIP20 规范
}
/**
* @dev Approve the passed address to spend the specified amount of tokens on behalf of
msg.sender. *
* Beware that changing an allowance with this method brings the risk that someone may use both the old
* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
* race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729 * @param _spender The address which will spend the funds.
* @param _value The amount of tokens to be spent.
*/
function approve(address _spender, uint256 _value) public returns (bool) {
allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);
return true;
}

/**
* @dev Function to check the amount of tokens that an owner allowed to a spender.
* @param _owner address The address which owns the funds.
* @param _spender address The address which will spend the funds.
* @return A uint256 specifying the amount of tokens still available for the spender. */
function allowance(
address _owner,
address _spender
)
public
view
returns (uint256)
{
return allowed[_owner][_spender];
}

}

/* 父类:账户管理员 */
contract owned {
address public owner;

constructor() public {
owner = msg.sender;
}

modifier onlyOwner {
require(msg.sender == owner);
_;
}

function transferOwnership(address newOwner) onlyOwner public {
owner = newOwner;
}
}


contract BbtcToken is owned, StandardToken {
string public name = "波比特";
string public symbol = "BBTC";
uint8 public decimals = 18;

/* 构造函数 */
constructor() public {
//发行量:8400wan(小数位:18)
totalSupply_ = 84 * 100 * 10000 * 1000000000000000000;
balances[msg.sender] = totalSupply_;
}

}