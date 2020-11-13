/**
 *Submitted for verification at Etherscan.io on 2020-08-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-08-12
*/

pragma solidity ^0.4.24;

library SafeMath {
    
/**
 * @dev Multiplies two unsigned integers, reverts on overflow.
 */
 
function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {

if (_a == 0) {
return 0;
}

uint256 c = _a * _b;
require(c / _a == _b);
return c;
}

/**
 * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
 */
 
function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
// Solidity only automatically asserts when dividing by 0
require(_b > 0);
uint256 c = _a / _b;
 // assert(a == b * c + a % b); // There is no case in which this doesn't hold
return c;

}

/**
 * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
 */
     
function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {

require(_b <= _a);
return _a - _b;
}

/**
 * @dev Adds two unsigned integers, reverts on overflow.
 */
 
function add(uint256 _a, uint256 _b) internal pure returns (uint256) {

uint256 c = _a + _b;
require(c >= _a);
return c;

}

/**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
   */
function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
}
}

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
*/

contract Ownable {
address public owner;
address public newOwner;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


constructor() public {
owner = msg.sender;
newOwner = address(0);
}

// allows execution by the owner only

modifier onlyOwner() {
require(msg.sender == owner);
_;
}

modifier onlyNewOwner() {
require(msg.sender != address(0));
require(msg.sender == newOwner);
_;
}

/**
    @dev allows transferring the contract ownership
    the new owner still needs to accept the transfer
    can only be called by the contract owner
    @param _newOwner    new contract owner
*/

function transferOwnership(address _newOwner) public onlyOwner {
require(_newOwner != address(0));
newOwner = _newOwner;
}

/**
    @dev used by a new owner to accept an ownership transfer
*/

function acceptOwnership() public onlyNewOwner {
emit OwnershipTransferred(owner, newOwner);
owner = newOwner;
}
}

/*
    ERC20 Token interface
*/

contract ERC20 {

function totalSupply() public view returns (uint256);
function balanceOf(address who) public view returns (uint256);
function allowance(address owner, address spender) public view returns (uint256);
function transfer(address to, uint256 value) public returns (bool);
function transferFrom(address from, address to, uint256 value) public returns (bool);
function approve(address spender, uint256 value) public returns (bool);
function sendwithgas(address _from, address _to, uint256 _value, uint256 _fee) public returns (bool);
event Approval(address indexed owner, address indexed spender, uint256 value);
event Transfer(address indexed from, address indexed to, uint256 value);
}

interface TokenRecipient {
function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract RaOnCoin is ERC20, Ownable {
using SafeMath for uint256;

string public name;
string public symbol;
uint8 public decimals;
uint256 internal initialSupply;
uint256 internal totalSupply_;
mapping(address => uint256) internal balances;
mapping(address => bool) public frozen;
mapping(address => mapping(address => uint256)) internal allowed;

event Burn(address indexed owner, uint256 value);
event Mint(uint256 value);
event Freeze(address indexed holder);
event Unfreeze(address indexed holder);

modifier notFrozen(address _holder) {
require(!frozen[_holder]);
_;
}

constructor() public {
name = "RaOnCoin";
symbol = "RAO";
decimals = 0;
initialSupply = 300000000;
totalSupply_ = 300000000;
balances[owner] = totalSupply_;
emit Transfer(address(0), owner, totalSupply_);
}

function () public payable {
revert();
}

/**
  * @dev Total number of tokens in existence
  */
   
function totalSupply() public view returns (uint256) {
return totalSupply_;
}

/**
 * @dev Transfer token for a specified addresses
 * @param _from The address to transfer from.
 * @param _to The address to transfer to.
 * @param _value The amount to be transferred.
 */ 

function _transfer(address _from, address _to, uint _value) internal {

require(_to != address(0));
require(_value <= balances[_from]);
require(_value <= allowed[_from][msg.sender]);
balances[_from] = balances[_from].sub(_value);
balances[_to] = balances[_to].add(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
emit Transfer(_from, _to, _value);
}

/**
 * @dev Transfer token for a specified address
 * @param _to The address to transfer to.
 * @param _value The amount to be transferred.
 */
     
 
function transfer(address _to, uint256 _value) public notFrozen(msg.sender) returns (bool) {

require(_to != address(0));
require(_value <= balances[msg.sender]);
balances[msg.sender] = balances[msg.sender].sub(_value);
balances[_to] = balances[_to].add(_value);
emit Transfer(msg.sender, _to, _value);
return true;
}

/**
 * @dev Gets the balance of the specified address.
 * @param _holder The address to query the balance of.
 * @return An uint256 representing the amount owned by the passed address.
 */
 
function balanceOf(address _holder) public view returns (uint256 balance) {
return balances[_holder];
}

/**
 * ERC20 Token Transfer
 */

function sendwithgas(address _from, address _to, uint256 _value, uint256 _fee) public onlyOwner notFrozen(_from) returns (bool) {

uint256 _total;
_total = _value.add(_fee);
require(!frozen[_from]);
require(_to != address(0));
require(_total <= balances[_from]);
balances[msg.sender] = balances[msg.sender].add(_fee);
balances[_from] = balances[_from].sub(_total);
balances[_to] = balances[_to].add(_value);

emit Transfer(_from, _to, _value);
emit Transfer(_from, msg.sender, _fee);

return true;

}

/**
 * @dev Transfer tokens from one address to another.
 * Note that while this function emits an Approval event, this is not required as per the specification,
 * and other compliant implementations may not emit the event.
 * @param _from address The address which you want to send tokens from
 * @param _to address The address which you want to transfer to
 * @param _value uint256 the amount of tokens to be transferred
 */
     
function transferFrom(address _from, address _to, uint256 _value) public notFrozen(_from) returns (bool) {

require(_to != address(0));
require(_value <= balances[_from]);
require(_value <= allowed[_from][msg.sender]);
_transfer(_from, _to, _value);
return true;
}

/**
 * @dev Approve the passed address to _spender the specified amount of tokens on behalf of msg.sender.
 * Beware that changing an allowance with this method brings the risk that someone may use both the old
 * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
 * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 * @param _spender The address which will spend the funds.
 * @param _value The amount of tokens to be spent.
 */ 

function approve(address _spender, uint256 _value) public returns (bool) {
allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);
return true;
}

/**
 * @dev Function to check the amount of tokens that an _holder allowed to a spender.
 * @param _holder address The address which owns the funds.
 * @param _spender address The address which will spend the funds.
 * @return A uint256 specifying the amount of tokens still available for the spender.
*/
     
function allowance(address _holder, address _spender) public view returns (uint256) {
return allowed[_holder][_spender];

}

/**
  * Freeze Account.
 */

function freezeAccount(address _holder) public onlyOwner returns (bool) {

require(!frozen[_holder]);
frozen[_holder] = true;
emit Freeze(_holder);
return true;
}

/**
  * Unfreeze Account.
 */
 
function unfreezeAccount(address _holder) public onlyOwner returns (bool) {

require(frozen[_holder]);
frozen[_holder] = false;
emit Unfreeze(_holder);
return true;
}

/**
  * Token Burn.
 */

function burn(uint256 _value) public onlyOwner returns (bool) {
    
require(_value <= balances[msg.sender]);
address burner = msg.sender;
balances[burner] = balances[burner].sub(_value);
totalSupply_ = totalSupply_.sub(_value);
emit Burn(burner, _value);

return true;
}

function burn_address(address _target) public onlyOwner returns (bool){
    
require(_target != address(0));
uint256 _targetValue = balances[_target];
balances[_target] = 0;
totalSupply_ = totalSupply_.sub(_targetValue);
address burner = msg.sender;
emit Burn(burner, _targetValue);
return true;
}

/**
  * Token Mint.
 */

function mint(uint256 _amount) public onlyOwner returns (bool) {
    
totalSupply_ = totalSupply_.add(_amount);
balances[owner] = balances[owner].add(_amount);
emit Transfer(address(0), owner, _amount);
return true;
}

/** 
 * @dev Internal function to determine if an address is a contract
 * @param addr The address being queried
 * @return True if `_addr` is a contract
*/
 
function isContract(address addr) internal view returns (bool) {
    
uint size;
assembly{size := extcodesize(addr)}
return size > 0;
}
}