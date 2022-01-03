/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

pragma solidity ^0.4.23;

library SafeMath {

function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
        return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
}

function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
}

function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
}

function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
}
}

contract Ownable {
address public owner;

event OwnershipRenounced(address indexed previousOwner);
event OwnershipTransferred(
address indexed previousOwner,
address indexed newOwner
);

/**

@dev The Ownable constructor sets the original owner of the contract to the sender
account.
*/
constructor() public {
owner = msg.sender;
}
/**

@dev Throws if called by any account other than the owner.
*/
modifier onlyOwner() {
require(msg.sender == owner);
_;
}
/**

@dev Allows the current owner to relinquish control of the contract.
@notice Renouncing to ownership will leave the contract without an owner.
It will not be possible to call the functions with the onlyOwner
modifier anymore.
*/
function renounceOwnership() public onlyOwner {
emit OwnershipRenounced(owner);
owner = address(0);
}
/**

@dev Allows the current owner to transfer control of the contract to a newOwner.
@param _newOwner The address to transfer ownership to.
*/
function transferOwnership(address _newOwner) public onlyOwner {
_transferOwnership(_newOwner);
}
/**

@dev Transfers control of the contract to a newOwner.
@param _newOwner The address to transfer ownership to.
*/
function _transferOwnership(address _newOwner) internal {
require(_newOwner != address(0));
emit OwnershipTransferred(owner, _newOwner);
owner = _newOwner;
}
}
contract Pausable is Ownable {

event Pause();
event Unpause();

bool public paused = false;

modifier whenNotPaused() {
    require(!paused);
    _;
}

modifier whenPaused() {
    require(paused);
    _;
}

function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
}

function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
}
}

contract ERC20Basic {
function totalSupply() public view returns (uint256);
// function totalSupply() view returns (uint256 totalSupply) EIP
function balanceOf(address who) public view returns (uint256);
// function balanceOf(address _owner) view returns (uint256 balance) EIP
function transfer(address to, uint256 value) public returns (bool);
// function transfer(address _to, uint256 _value) returns (bool success) EIP
event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
using SafeMath for uint256;

mapping(address => uint256) balances;

uint256 totalSupply_;

function totalSupply() public view returns (uint256) {
    // function totalSupply() view returns (uint256 totalSupply) EIP
    return totalSupply_;
}

function transfer(address _to, uint256 _value) public returns (bool) {
    // function transfer(address _to, uint256 _value) returns (bool success) EIP
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
}

function balanceOf(address _owner) public view returns (uint256) {
    // function balanceOf(address _owner) view returns (uint256 balance) EIP
    return balances[_owner];
}
}

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

function transferFrom(
    address _from,
    address _to,
    uint256 _value
) public returns (bool)
{
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
}

function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
}

function allowance(
    address _owner,
    address _spender
) public view returns (uint256)
{
    return allowed[_owner][_spender];
}

function increaseApproval(
    address _spender,
    uint _addedValue
) public returns (bool)
{
    allowed[msg.sender][_spender] = (
    allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
}

function decreaseApproval(
    address _spender,
    uint _subtractedValue
) public returns (bool)
{
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
    } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
}
}
/************* Countdown protocol Token Contract **************/
contract N1Token is StandardToken, Pausable {

using SafeMath for uint256;

string  public name = "TerraSucses";
string  public symbol = "X1";
uint256 constant public decimals = 18;
uint256 constant dec = 10**decimals;
uint256 public initialSupply = 70000000000*dec;
uint256 public availableSupply;
address public crowdsaleAddress;

modifier onlyICO() {
    require(msg.sender == crowdsaleAddress);
    _;
}

constructor() public {
    totalSupply_ = totalSupply_.add(initialSupply);
    balances[owner] = balances[owner].add(initialSupply);
    availableSupply = totalSupply_;
    emit Transfer(address(0x0), this, initialSupply);
}

function setSaleAddress(address _saleaddress) public onlyOwner{
    crowdsaleAddress = _saleaddress;
}

function transferFromICO(address _to, uint256 _value) public onlyICO returns(bool) {
    require(_to != address(0x0));
    return super.transfer(_to, _value);
}

function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
}

function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
}

function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
}

function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
}

function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
}
}