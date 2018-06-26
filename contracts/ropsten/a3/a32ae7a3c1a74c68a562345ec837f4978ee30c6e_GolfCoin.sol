pragma solidity ^0.4.18;

interface IERC20 {
	function totalSupply() constant returns (uint totalSupply);
	function balanceOf(address _owner) constant returns (uint balance);
	function transfer(address _to, uint _value) returns (bool success);
	function transferFrom(address _from, address _to, uint _value) returns (bool success);
	function approve(address _spender, uint _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}



contract GolfCoin is IERC20{
	using SafeMath for uint256;

	uint256 private _totalSupply = 0;

	bool public purchasingAllowed = true;

	string public constant symbol = &quot;GOLF&quot;;
	string public constant name = &quot;GolfCoin&quot;;
	uint256 public constant decimals = 18;

	uint256 private CREATOR_TOKEN = 31000000 * 10**decimals;
	uint256 private CREATOR_TOKEN_END = 4650000 * 10**decimals;
	uint256 private constant RATE = 10000;

	address private owner;

	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;

	struct Buyer{
	    address to;
	    uint256 value;
	}

	Buyer[] buyers;

	modifier onlyOwner {
	    require(msg.sender == owner);
	    _;
	}

	function() payable{
		require(purchasingAllowed);
		createTokens();
	}

	function GolfCoin(){
		owner = msg.sender;
		balances[msg.sender] = CREATOR_TOKEN;
		_totalSupply = CREATOR_TOKEN;
	}

	function createTokens() payable{
	    bool bSend = true;
		require(msg.value >= 0);
		uint256 tokens = msg.value.mul(10 ** decimals);
		tokens = tokens.mul(RATE);
		tokens = tokens.div(10 ** 18);

		uint256 sum2 = balances[owner].sub(tokens);
		require(sum2 >= CREATOR_TOKEN_END);
		//uint256 sum = _totalSupply.add(tokens);
		_totalSupply = sum2;
		owner.transfer(msg.value);
		balances[msg.sender] = balances[msg.sender].add(tokens);
		balances[owner] = balances[owner].sub(tokens);
		Transfer(msg.sender, owner, msg.value);
	}

	function totalSupply() constant returns (uint totalSupply){
		return _totalSupply;
	}

	function balanceOf(address _owner) constant returns (uint balance){
		return balances[_owner];
	}

	function enablePurchasing() onlyOwner {
		purchasingAllowed = true;
	}

	function disablePurchasing() onlyOwner {
		purchasingAllowed = false;
	}

	function transfer(address _to, uint256 _value) returns (bool success){
		require(balances[msg.sender] >= _value	&& balances[_to] + _value > balances[_to]);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
		require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value	&& balances[_to] + _value > balances[_to]);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) returns (bool success){
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint remaining){
		return allowed[_owner][_spender];
	}

	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);

}