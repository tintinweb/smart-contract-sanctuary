pragma solidity ^0.4.19;

/*	========================================================================================	*/
/*	http://remix.ethereum.org/#optimize=false&version=soljson-v0.4.19+commit.c4cbbb05.js 		*/
/*	This contract MUST be compiled with OPTIMIZATION=NO via Solidity v0.4.19+commit.c4cbbb05	*/
/*	Attempting to compile this contract with any earlier or later build of Solidity will		*/
/*	result in Warnings and/or Compilation Errors. Turning on optimization during compile		*/
/*	will prevent the contract code from being able to Publish and Verify properly. Thus, it		*/
/*	is imperative that this contract be compiled with optimization off using v0.4.19 of the		*/
/*	Solidity compiler, more specifically: v0.4.19+commit.f0d539ae.								*/
/*	========================================================================================	*/
/*	Token Name		:	Magnificent 50															*/
/*	Total Supply	:	168,000,000 Tokens														*/
/*	Contract Address:	0xa5a5aaff6bf97dee8d02d76c4a6221c9b408de0e								*/
/*	Ticker Symbol	:	Mag50																	*/
/*	Decimals		:	18																		*/
/*	Creator Address	:	0xa5a5aaff6bf97dee8d02d76c4a6221c9b408de0e								*/
/*	========================================================================================	*/

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
/*
	ERC20 interface
	see https://github.com/ethereum/EIPs/issues/20
*/

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/*
	SafeMath - the lowest gas library
	Math operations with safety checks that throw on error
*/

library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a * b; assert(a == 0 || c / a == b); return c;}
 
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
  function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b; return c;}
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a); return a - b;}
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b; assert(c >= a); return c;}
}
 
/*
	Basic token
	Basic version of StandardToken, with no allowances. 
*/

contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
 function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 
/*
	Gets the balance of the specified address.
	param _owner The address to query the the balance of. 
	return An uint256 representing the amount owned by the passed address.
*/

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
/*
	Implementation of the basic standard token.
	https://github.com/ethereum/EIPs/issues/20
*/

contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
/*
    Transfer tokens from one address to another
    param _from address The address which you want to send tokens from
    param _to address The address which you want to transfer to
    param _value uint256 the amout of tokens to be transfered
*/

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];
 
	// Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
	// require (_value <= _allowance);
 
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
 
/*
	Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	param _spender The address which will spend the funds.
	param _value The amount of Magnificent 50 tokens to be spent.
*/

  function approve(address _spender, uint256 _value) public returns (bool) {
 
	//  To change the approve amount you must first reduce the allowance
	//  of the adddress to zero by calling `approve(_spender, 0)` if it
	//  is not already 0 to mitigate the race condition described here:
	//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
 
/*
	Function to check the amount of tokens that an owner allowed to a spender.
	param _owner address The of the funds owner.
	param _spender address The address of the funds spender.
	return A uint256 Specify the amount of tokens still available to the spender.
*/
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}
 
/*
	The Ownable contract has an owner address, and provides basic authorization control
	functions, this simplifies the implementation of "user permissions".
*/

contract Ownable {
    
  address public owner;
 
 
/*
	Throws if called by any account other than the owner.
*/

  function Ownable() public {
    owner = 0xA900f6DD916a7B11B44E9a3b4baAD172dF014594;
  }
 

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
/*
	Allows the current owner to transfer control of the contract to a newOwner.
	param newOwner The address to transfer ownership to.
*/

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}
 

    
contract Mag50 is StandardToken, Ownable {
  string public constant name = "Magnificent 50";
  string public constant symbol = "Mag50";
  uint public constant decimals = 18;
  uint256 public initialSupply;
    
  function Mag50 () public { 
     totalSupply = 168000000 * 10 ** decimals;
      balances[0xA900f6DD916a7B11B44E9a3b4baAD172dF014594] = totalSupply;
      initialSupply = totalSupply; 
        Transfer(0, this, totalSupply);
        Transfer(this, 0xA900f6DD916a7B11B44E9a3b4baAD172dF014594, totalSupply);
  }
}