/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity 0.8.2;

//safemath implementation

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {		
		uint256 c = a + b;
		require(c >= a); 
  		return c;
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);	
		uint256 c = a - b;		
		return c;
	}
}

contract Ronzocoin {
	using SafeMath for uint256;	

	string public constant name = "Ronzocoin";
	string public constant symbol = "RNZ";
	uint8 public constant decimals = 18;
	uint256 public _totalSupply = 42_000_000e18;
	
	address public owner;

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	mapping(address => uint256) public balances;
	mapping(address => mapping (address => uint256)) public allowed;


//give total token supply to contract owner

	constructor() public {
		owner = msg.sender;
   		balances[msg.sender] = _totalSupply;
	}


//get total token supply regardless of token owner

	function totalSupply() public view returns (uint256) {
  		return _totalSupply;
	}


//get token balance of a token owner

	function balanceOf(address _owner) public view returns (uint256 balance) {
  		return balances[_owner];
	}


//transfer tokens from sender to receiver

	function transfer(address _to, uint256 _value) public returns (bool success) {
  		require(_value <= balances[msg.sender]);
  		
		balances[msg.sender] = balances[msg.sender].sub(_value);
  		balances[_to] = balances[_to].add(_value);
  		emit Transfer(msg.sender, _to, _value);
  		return true;
	}


//approve marketplace for tokens withdrawal

	function approve(address _spender, uint256 _value) public returns (bool success) {
  		allowed[msg.sender][_spender] = _value;
  		emit Approval(msg.sender, _spender, _value);
  		return true;
	}


//get number of tokens approved for withdrawal

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
  		return allowed[_owner][_spender];
	}


//transfer approved tokens from sender to receiver through marketplace

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
 		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);
		
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}
}