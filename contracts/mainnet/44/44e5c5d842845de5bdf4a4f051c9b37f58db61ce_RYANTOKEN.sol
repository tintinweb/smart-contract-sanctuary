pragma solidity ^0.4.18;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract RYANTOKEN is ERC20,Ownable{
	using SafeMath for uint256;
	string public constant name="瑞安币";
	string public symbol="RYAN";
	string public constant version = "1.0";
	uint256 public constant decimals = 18;
	uint256 public totalSupply;
	uint256 public constant MAX_SUPPLY=300000000*10**decimals;
  mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

	event GetETH(address indexed _from, uint256 _value);

	function RYANTOKEN() public {
		totalSupply=MAX_SUPPLY;
		balances[msg.sender] = MAX_SUPPLY;
		Transfer(0x0, msg.sender, MAX_SUPPLY);
	}

	function () payable external
	{
		GetETH(msg.sender,msg.value);
	}

	function etherProceeds() external
		onlyOwner
	{
		if(!msg.sender.send(this.balance)) revert();
	}

  	function transfer(address _to, uint256 _value) public  returns (bool)
 	{
		require(_to != address(0));
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint256 balance) 
  	{
		return balances[_owner];
  	}

  	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
  	{
		require(_to != address(0));
		uint256 _allowance = allowed[_from][msg.sender];

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
  	}

  	function approve(address _spender, uint256 _value) public returns (bool) 
  	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
  	}

  	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) 
  	{
		return allowed[_owner][_spender];
  	}
}