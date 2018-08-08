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

contract Fosha {
    
    using SafeMath for uint256; 

    string constant public standard = "ERC20";
    string constant public symbol = "FOSHA";
    string constant public name = "Fosha";
    uint8 constant public decimals = 18;

    uint256 constant public initialSupply = 78000000 * 1 ether;
    uint256 constant public tokensForIco = 62400000 * 1 ether;

    uint256 public startTransferTime;
    uint256 public tokensSold;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 constant public start = 1524391200;
    uint256 constant public end = 1525132799;
    uint256 constant public tokenExchangeRate = 3000;
    uint256 public amountRaised;
    bool public crowdsaleClosed = false;
    address public fundWallet;
    address ethFundWallet;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);

    function Fosha(address _ethFundWallet) {
		ethFundWallet = _ethFundWallet;
		fundWallet = msg.sender;
		balanceOf[fundWallet] = initialSupply;
		startTransferTime = end;
    }

    function() payable {
		uint256 amount = msg.value;
		uint256 numTokens = amount.mul(tokenExchangeRate); 
		require(!crowdsaleClosed && now >= start && now <= end && tokensSold.add(numTokens) <= tokensForIco && amount <= 5);
		ethFundWallet.transfer(amount);
		balanceOf[fundWallet] = balanceOf[fundWallet].sub(numTokens); 
		balanceOf[msg.sender] = balanceOf[msg.sender].add(numTokens);
		Transfer(fundWallet, msg.sender, numTokens);
		amountRaised = amountRaised.add(amount);
		tokensSold += numTokens;
		FundTransfer(msg.sender, amount, true, amountRaised);
    }

    function transfer(address _to, uint256 _value) returns(bool success) {
		require(now >= startTransferTime); 
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); 
		balanceOf[_to] = balanceOf[_to].add(_value); 
		Transfer(msg.sender, _to, _value); 
		return true;
    }

    function approve(address _spender, uint256 _value) returns(bool success) {
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
		allowance[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
		if (now < startTransferTime) {
		    require(_from == fundWallet);
		}
		var _allowance = allowance[_from][msg.sender];
		require(_value <= _allowance);
		balanceOf[_from] = balanceOf[_from].sub(_value); 
		balanceOf[_to] = balanceOf[_to].add(_value); 
		allowance[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
    }

    function markCrowdsaleEnding() {
		require(now > end);
		crowdsaleClosed = true;
    }
}