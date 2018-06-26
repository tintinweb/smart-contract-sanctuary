pragma solidity ^0.4.9;

contract ERC20 {
	string public name;
	string public symbol;
	uint8 public decimals = 8;

	uint public totalSupply;
	function balanceOf(address _owner) public constant returns (uint balance);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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

	/* function div(uint256 a, uint256 b) internal constant returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	} */

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

contract owned {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		owner = newOwner;
	}
}

contract BazistaToken is ERC20, owned {
	using SafeMath for uint256;

	string public name = &#39;Bazista Token&#39;;
	string public symbol = &#39;BZS&#39;;

	uint256 public totalSupply = 44000;

	address public icoWallet;
	uint256 public icoSupply = 33440;

	address public advisorsWallet;
	uint256 public advisorsSupply = 1320;

	address public teamWallet;
	uint256 public teamSupply = 6600;

	address public marketingWallet;
	uint256 public marketingSupply = 1760;

	address public bountyWallet;
	uint256 public bountySupply = 880;

	mapping(address => uint) balances;
	mapping (address => mapping (address => uint256)) allowed;

	modifier onlyPayloadSize(uint size) {
		require(msg.data.length >= (size + 4));
		_;
	}

	constructor () public {
		balances[this] = totalSupply;
	}


	function setWallets(address _advisorsWallet, address _teamWallet, address _marketingWallet, address _bountyWallet) public onlyOwner {
		advisorsWallet = _advisorsWallet;
		_transferFrom(this, advisorsWallet, advisorsSupply);

		teamWallet = _teamWallet;
		_transferFrom(this, teamWallet, teamSupply);

		marketingWallet = _marketingWallet;
		_transferFrom(this, marketingWallet, marketingSupply);

		bountyWallet = _bountyWallet;
		_transferFrom(this, bountyWallet, bountySupply);
	}


	function setICO(address _icoWallet) public onlyOwner {
		icoWallet = _icoWallet;
		_transferFrom(this, icoWallet, icoSupply);
	}

	function () public{
		revert();
	}

	function balanceOf(address _owner) public constant returns (uint balance) {
		return balances[_owner];
	}
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
		_transferFrom(msg.sender, _to, _value);
		return true;
	}
	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		_transferFrom(_from, _to, _value);
		return true;
	}
	function _transferFrom(address _from, address _to, uint256 _value) internal {
		require(_value > 0);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
}

















contract BazistaICO is owned {
	
	using SafeMath for uint256;

	BazistaToken public token;	

	uint256 public crowdsaleTokens = 32120000000000000;
	uint256 public presaleTokens = 1320000000000000;

	uint256 public wireLimit = 6688000000000000;
	uint256 public soldTokens = 0;

	uint256 public presaleStart = 1510822800;	//2017-11-16 12:00:00
	uint256 public presaleEnd = 1511254800;		//2017-11-21 12:00:00
	uint256 public saleStart = 1512378000;		//2017-12-04 12:00:00
	uint256 public saleEnd = 1514970000;		//2018-01-03 12:00:00

	uint256 public salePrice = 1100000000000;
	uint256 public minTokens = 4180000000000000; //3800*salePrice
	uint256 public maxWeis = 30300000000000000000000; //30300 eth

	mapping(address => uint) deposits;

	constructor() public 
	{
		owner = msg.sender;
		token = BazistaToken(owner);
	}

	function () public payable 
	{
		buy();
	}

	function getDeposits(address _owner) public constant returns (uint256 weis) 
	{
		return deposits[_owner];
	}		


	function percentFrom(uint256 from, uint8 percent) internal constant returns (uint256 val){
		val = from.mul(percent) / 100;
	}
	function calcTokens(uint256 _wei) internal constant returns (uint256 val){
		val = _wei.mul(salePrice) / (1 ether);
	}	
	

	


	function buy() public payable returns (uint256 tokens) {
		require((msg.value > 0) );

		tokens = calcTokens(msg.value);
		soldTokens = soldTokens.add(tokens);		

		require(token.transfer(msg.sender, tokens));		

		deposits[msg.sender]=deposits[msg.sender].add(msg.value);
	}

}