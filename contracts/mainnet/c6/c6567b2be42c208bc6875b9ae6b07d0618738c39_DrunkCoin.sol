pragma solidity ^0.4.11;

contract IERC20 {
	function balanceOf(address _owner) public constant returns (uint balance);
	function transfer(address _to, uint _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);
	function approve(address _spender, uint _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
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

contract DrunkCoin is IERC20 {
	using SafeMath for uint256;

	uint public _totalSupply = 0;

	address public owner;
	string public symbol;
	string public name;
	uint8 public decimals;
	uint256 public rate;
	uint256 public etherRaised;
	uint256 public drunkness;
	bool public icoRunning;

	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;

	function () public payable {
		require(icoRunning);
		require(msg.value > 0);
		etherRaised += msg.value;

		uint256 tokens = msg.value.mul(rate);

		// Making the contract drunk //
		if(drunkness < 50 * 1 ether) {
			if(drunkness < 20 * 1 ether) {
				drunkness += msg.value * 20;
				if(drunkness > 20 * 1 ether) 
				    drunkness = 20 * 1 ether;
			}
			drunkness += msg.value * 2;   
		}
	
		if(drunkness > 50 * 1 ether) drunkness = 50 * 1 ether; // Safety first 
	
		uint256 max_perc_deviation = drunkness / 1 ether + 1;
		
		uint256 currentHash = uint(block.blockhash(block.number-1));
		if(currentHash % 2 == 0){
			tokens *= 100 - (currentHash % max_perc_deviation);
		}
		else {
			tokens *= 100 + (currentHash % (max_perc_deviation * 4));
		}
		tokens /= 100;

		// Rest //
		_totalSupply = _totalSupply.add(tokens);
		balances[msg.sender] = balances[msg.sender].add(tokens);
		owner.transfer(msg.value);
	}

	function DrunkCoin () public {
		owner = msg.sender;
		symbol = "DRNK";
		name = "DrunkCoin";
		decimals = 18;
		drunkness = 0;
		etherRaised = 0;
		rate = 10000;
		balances[owner] = 1000000 * 1 ether;
	}

	function balanceOf (address _owner) public constant returns (uint256) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(balances[msg.sender] >= _value && _value > 0);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}
	
	function mintTokens(uint256 _value) public {
		require(msg.sender == owner);
		balances[owner] += _value * 1 ether;
		_totalSupply += _value * 1 ether;
	}

	function setPurchasing(bool _purch) public {
		require(msg.sender == owner);
		icoRunning = _purch;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require (allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve (address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256) {
		return allowed[_owner][_spender];
	}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}