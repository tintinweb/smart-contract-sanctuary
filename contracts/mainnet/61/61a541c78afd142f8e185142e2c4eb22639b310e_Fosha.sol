pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns(uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
    }
    
    function div(uint256 a, uint256 b) internal returns(uint256) {
		uint256 c = a / b;
		return c;
    }

    function sub(uint256 a, uint256 b) internal returns(uint256) {
		assert(b <= a);
		return a - b;
    }

    function add(uint256 a, uint256 b) internal returns(uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);
		return c;
    }
}

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Fosha is ERC20, Ownable {
   
    using SafeMath for uint256;
	
    string constant public symbol = "FOSHA";
    string constant public name = "Fosha";
    uint8 constant public decimals = 18;

	uint public totalSupply;
	uint public tokensForIco;
	uint256 public startTransferTime;
	uint256 public tokensSold;
	uint256 public start;
	uint256 public end;
	uint256 public tokenExchangeRate;
	uint256 public amountRaised;
    bool public crowdsaleClosed = false;
	
    address public fundWallet;
    address ethFundWallet;
	
	mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
	
	event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);

	function Fosha(uint256 _total, uint256 _icototal, uint256 _start, uint256 _end, uint256 _exchange) {
		totalSupply = _total * 1 ether;
		tokensForIco = _icototal * 1 ether;
		start = _start;
		end = _end;
		tokenExchangeRate = _exchange;
		ethFundWallet = msg.sender;
		fundWallet = msg.sender;
		balances[fundWallet] = totalSupply;
		startTransferTime = end;
    }

    function() payable {
		uint256 amount = msg.value;
		uint256 numTokens = amount.mul(tokenExchangeRate); 
		require(!crowdsaleClosed && now >= start && now <= end && tokensSold.add(numTokens) <= tokensForIco && amount <= 5 ether);
		ethFundWallet.transfer(amount);
		balances[fundWallet] = balances[fundWallet].sub(numTokens); 
		balances[msg.sender] = balances[msg.sender].add(numTokens);
		Transfer(fundWallet, msg.sender, numTokens);
		amountRaised = amountRaised.add(amount);
		tokensSold += numTokens;
		FundTransfer(msg.sender, amount, true, amountRaised);
    }

    function transfer(address _to, uint256 _value) returns(bool success) {
		require(now >= startTransferTime); 
		balances[msg.sender] = balances[msg.sender].sub(_value); 
		balances[_to] = balances[_to].add(_value); 
		Transfer(msg.sender, _to, _value); 
		return true;
    }
	
	function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
	
    function approve(address _spender, uint256 _value) returns(bool success) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
    }

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
		if (now < startTransferTime) {
		    require(_from == fundWallet);
		}
		var _allowance = allowed[_from][msg.sender];
		require(_value <= _allowance);
		balances[_from] = balances[_from].sub(_value); 
		balances[_to] = balances[_to].add(_value); 
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
    }

    function markCrowdsaleEnding() {
		require(now > end);
		crowdsaleClosed = true;
    }
}