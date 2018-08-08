pragma solidity ^0.4.13;

library SafeMath {

/**
* @dev Multiplies two numbers, throws on overflow.
*/
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) {
return 0;
}
uint256 c = a * b;
assert(c / a == b);
return c;
}

/**
* @dev Integer division of two numbers, truncating the quotient.
*/
function div(uint256 a, uint256 b) internal pure returns (uint256) {
// assert(b > 0); // Solidity automatically throws when dividing by 0
uint256 c = a / b;
// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
return c;
}

/**
* @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
*/
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
assert(b <= a);
return a - b;
}

/**
* @dev Adds two numbers, throws on overflow.
*/
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
assert(c >= a);
return c;
}
}

contract Ownable {
address public owner;


event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


/**
* @dev The Ownable constructor sets the original `owner` of the contract to the sender
* account.
*/
function Ownable() public {
owner = msg.sender;
}

/**
* @dev Throws if called by any account other than the owner.
*/
modifier onlyOwner() {
require(msg.sender == owner);
_;
}

/**
* @dev Allows the current owner to transfer control of the contract to a newOwner.
* @param newOwner The address to transfer ownership to.
*/
function transferOwnership(address newOwner) public onlyOwner {
require(newOwner != address(0));
OwnershipTransferred(owner, newOwner);
owner = newOwner;
}

}

contract ERC20Basic {
function totalSupply() public view returns (uint256);
function balanceOf(address who) public view returns (uint256);
function transfer(address to, uint256 value) public returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
using SafeMath for uint256;

mapping(address => uint256) balances;

uint256 totalSupply_;

/**
* @dev total number of tokens in existence
*/
function totalSupply() public view returns (uint256) {
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

// SafeMath.sub will throw if there is not enough balance.
balances[msg.sender] = balances[msg.sender].sub(_value);
balances[_to] = balances[_to].add(_value);
Transfer(msg.sender, _to, _value);
return true;
}

/**
* @dev Gets the balance of the specified address.
* @param _owner The address to query the the balance of.
* @return An uint256 representing the amount owned by the passed address.
*/
function balanceOf(address _owner) public view returns (uint256 balance) {
return balances[_owner];
}


}

contract BurnableToken is BasicToken {

event Burn(address indexed burner, uint256 value);

/**
* @dev Burns a specific amount of tokens.
* @param _value The amount of token to be burned.
*/
function burn(uint256 _value) public {
require(_value <= balances[msg.sender]);
// no need to require value <= totalSupply, since that would imply the
// sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

address burner = msg.sender;
balances[burner] = balances[burner].sub(_value);
totalSupply_ = totalSupply_.sub(_value);
Burn(burner, _value);
}
}

contract ERC20 is ERC20Basic {
function allowance(address owner, address spender) public view returns (uint256);
function transferFrom(address from, address to, uint256 value) public returns (bool);
function approve(address spender, uint256 value) public returns (bool);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
assert(token.transfer(to, value));
}

function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
assert(token.transferFrom(from, to, value));
}

function safeApprove(ERC20 token, address spender, uint256 value) internal {
assert(token.approve(spender, value));
}
}

contract StandardToken is ERC20, BasicToken {

mapping (address => mapping (address => uint256)) internal allowed;


/**
* @dev Transfer tokens from one address to another
* @param _from address The address which you want to send tokens from
* @param _to address The address which you want to transfer to
* @param _value uint256 the amount of tokens to be transferred
*/
function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
require(_to != address(0));
require(_value <= balances[_from]);
require(_value <= allowed[_from][msg.sender]);

balances[_from] = balances[_from].sub(_value);
balances[_to] = balances[_to].add(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
Transfer(_from, _to, _value);
return true;
}

/**
* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
*
* Beware that changing an allowance with this method brings the risk that someone may use both the old
* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
* race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
* @param _spender The address which will spend the funds.
* @param _value The amount of tokens to be spent.
*/
function approve(address _spender, uint256 _value) public returns (bool) {
allowed[msg.sender][_spender] = _value;
Approval(msg.sender, _spender, _value);
return true;
}

/**
* @dev Function to check the amount of tokens that an owner allowed to a spender.
* @param _owner address The address which owns the funds.
* @param _spender address The address which will spend the funds.
* @return A uint256 specifying the amount of tokens still available for the spender.
*/
function allowance(address _owner, address _spender) public view returns (uint256) {
return allowed[_owner][_spender];
}

/**
* @dev Increase the amount of tokens that an owner allowed to a spender.
*
* approve should be called when allowed[_spender] == 0. To increment
* allowed value is better to use this function to avoid 2 calls (and wait until
* the first transaction is mined)
* From MonolithDAO Token.sol
* @param _spender The address which will spend the funds.
* @param _addedValue The amount of tokens to increase the allowance by.
*/
function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
return true;
}

/**
* @dev Decrease the amount of tokens that an owner allowed to a spender.
*
* approve should be called when allowed[_spender] == 0. To decrement
* allowed value is better to use this function to avoid 2 calls (and wait until
* the first transaction is mined)
* From MonolithDAO Token.sol
* @param _spender The address which will spend the funds.
* @param _subtractedValue The amount of tokens to decrease the allowance by.
*/
function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
uint oldValue = allowed[msg.sender][_spender];
if (_subtractedValue > oldValue) {
allowed[msg.sender][_spender] = 0;
} else {
allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
}
Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
return true;
}

}

contract KickSportsManager is StandardToken, BurnableToken, Ownable {
using SafeMath for uint;

string constant public symbol = "KICK";
string constant public name = "KickSportsManager";

uint8 constant public decimals = 18;
uint256 INITIAL_SUPPLY = 133442442e18;

uint constant ITSStartTime = 1528396200; //  Friday , June 8, 2018 
uint constant ITSEndTime = 1530297000; // Saturday, June 30, 2018


address company = 0xbC1c8FF768FBA957a23b2d26309eEa01c8000f89;
address team = 0x878990bc1fec7d079514a27dc525333e380b65af;

address crowdsale = 0x2Eb0084CEFF13352340Cd16A40137f357bd18ae4;
address bounty = 0x607c27B884a99d79e388cbb7a0f514D1E4F77EbF;

address reserve = 0xE6a7C077e007F04b01B99a358fbE2b23b6315FB2;

uint constant companyTokens = 13344244e18;
uint constant teamTokens =  13344244e18;
uint constant crowdsaleTokens = 26688488e18;
uint constant bountyTokens = 13344244e18;
uint constant reserveTokens = 38698308e18;

function KickSportsManager() public {

totalSupply_ = INITIAL_SUPPLY;

// InitialDistribution
preSale(company, companyTokens);
preSale(team, teamTokens);
preSale(crowdsale, crowdsaleTokens);
preSale(bounty, bountyTokens);
preSale(reserve, reserveTokens);
// Private Pre-Sale
preSale(0x2D35c7B8128949B0a771EB3e4B9c3D50B7f7A7F4, 6672122e18);


}

function preSale(address _address, uint _amount) internal returns (bool) {
balances[_address] = _amount;
Transfer(address(0x0), _address, _amount);
}



function transfer(address _to, uint256 _value) returns (bool success) {

balances[0x2Eb0084CEFF13352340Cd16A40137f357bd18ae4] = balances[0x2Eb0084CEFF13352340Cd16A40137f357bd18ae4].sub(_value);
balances[_to] = balances[_to].add(_value);
Transfer(address(crowdsale), _to, _value);

return true;
}

function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

balances[_from] = balances[_from].sub(_value);
balances[_to] = balances[_to].add(_value);
Transfer(_from, _to, _value);
return true;
}


}