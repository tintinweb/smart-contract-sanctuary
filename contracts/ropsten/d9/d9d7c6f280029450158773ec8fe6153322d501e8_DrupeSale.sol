pragma solidity ^0.4.24;

library SafeMath {
	function mul(uint a, uint b) internal pure returns (uint c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		require(c / a == b);
		return c;
	}

	function div(uint a, uint b) internal pure returns (uint c) {
		return a / b;
	}
}

contract ERC20Interface {
	function transfer(address to, uint tokens) public returns (bool success);
}

contract DrupeSaleRef {
	address _referrer;
	DrupeSale _sale;

	constructor(address referrer, DrupeSale sale) public {
		require(referrer != address(0));
		require(sale != address(0));
		_referrer = referrer;
		_sale = sale;
	}

	function() public payable {
		require(msg.value > 0);
		_sale.buyUsingRefBonus.value(msg.value)(msg.sender, _referrer);
	}
}

contract DrupeSale {
	using SafeMath for uint;
	struct Fraction { uint numerator; uint denominator; }

	address _owner;
	address _newOwner;
	bool _open;
	address _payout;
	ERC20Interface _drupe;
	uint _tokensPerEther;
	Fraction _refBonus;
	mapping(address => DrupeSaleRef) _refs;

	constructor() public {
		_owner = msg.sender;
		_newOwner = address(0);
		_open = false;
		_refBonus = Fraction(0, 1);
	}

	function _ensureRef(address referrer) internal {
		if (_refs[referrer] == address(0)) {
			_refs[referrer] = new DrupeSaleRef(referrer, this);
		}
	}

	function open(address payout, address drupe, uint tokensPerEther) public {
		require(msg.sender == _owner);
		require(payout != address(0));
		require(drupe != address(0));
		require(tokensPerEther > 0);

		_open = true;
		_payout = payout;
		_drupe = ERC20Interface(drupe);
		_tokensPerEther = tokensPerEther;
		_refBonus = Fraction(0, 1);
	}

	function setRefBonus(uint numerator, uint denominator) public {
		require(msg.sender == _owner);
		_refBonus = Fraction(numerator, denominator);
	}

	function close() public {
		require(msg.sender == _owner);
		_open = false;
	}

	function isOpen() public view returns (bool) {
		return _open;
	}

	function hasRefBonus() public view returns (bool) {
		return _refBonus.numerator > 0;
	}

	function getRefBonus() public view returns (uint numerator, uint denominator) {
		numerator = _refBonus.numerator;
		denominator = _refBonus.denominator;
	}

	function getRef(address referrer) public view returns (address) {
		return _refs[referrer];
	}

	function getOwner() public view returns (address) {
		return _owner;
	}

	function getNewOwner() public view returns (address) {
		return _newOwner;
	}

	function() public payable {
		require(_open);
		require(msg.value > 0);
		uint tokens = _tokensPerEther.mul(msg.value);
		_payout.transfer(msg.value);
		_drupe.transfer(msg.sender, tokens);
		_ensureRef(msg.sender);
	}

	function buyUsingRefBonus(address sender, address referrer) public payable {
		require(_open);
		require(msg.value > 0);
		require(sender != address(0));
		require(referrer != address(0));
		require(sender != referrer);
		uint tokens = _tokensPerEther.mul(msg.value);
		uint refTokens = tokens.mul(_refBonus.numerator).div(_refBonus.denominator);
		_payout.transfer(msg.value);
		_drupe.transfer(sender, tokens);
		if (refTokens > 0) {
			_drupe.transfer(referrer, refTokens);
		}
		_ensureRef(sender);
	}

	function transferOwnership(address newOwner) public {
		require(msg.sender == _owner);
		_newOwner = newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == _newOwner);
		_owner = _newOwner;
		_newOwner = address(0);
	}

	function payout(address drupe, address to, uint tokens) public {
		require(msg.sender == _owner);
		require(drupe != address(0));
		require(to != address(0));
		ERC20Interface(drupe).transfer(to, tokens);
	}
}