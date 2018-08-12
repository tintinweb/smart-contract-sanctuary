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

contract DrupeCoin {
	function transfer(address to, uint tokens) public returns (bool success);
	function balanceOf(address tokenOwner) public constant returns (uint balance);
}

// Contract that forwards token purchases to the main ico contract
// and references the referrer in order to sent a referral bonus:
contract DrupeICORef {
	address _referrer;
	DrupeICO _ico;

	constructor(address referrer, DrupeICO ico) public {
		_referrer = referrer;
		_ico = ico;
	}

	function() public payable {
		_ico.purchase.value(msg.value)(msg.sender, _referrer);
	}
}

// The main contract that holds all tokens for sale and accepts Ether:
contract DrupeICO {
	using SafeMath for uint;

	// Representation of a fraction: n(numerator)/d(denominator)
	struct Fraction { uint n; uint d; }

	// Representation of an ico phases:
	struct Presale {
		// Start timestamp in seconds since unix epoch:
		uint start;
		// Bonus that applies to token purchases during this phase:
		Fraction bonus;
	}
	struct Mainsale {
		// Start timestamp in seconds since unix epoch:
		uint start;
		// End timestamp in seconds since unix epoch:
		uint end;
	}

	// Event that is emitted for each referral contract creation:
	event Referrer(address indexed referrer, address indexed refContract);

	address _owner;
	address _newOwner;
	DrupeCoin _drupe;
	Fraction _basePrice; // in: ETH per DPC
	Fraction _refBonus;
	Presale _presale1;
	Presale _presale2;
	Mainsale _mainsale;

	constructor(
		address drupe,
		uint basePriceN, uint basePriceD,
		uint refBonusN, uint refBonusD,
		uint presale1Start, uint presale1BonusN, uint presale1BonusD,
		uint presale2Start, uint presale2BonusN, uint presale2BonusD,
		uint mainsaleStart, uint mainsaleEnd
	) public {
		require(drupe != address(0));
		require(basePriceN > 0 && basePriceD > 0);
		require(refBonusN > 0 && basePriceD > 0);
		require(presale1Start > now);
		require(presale1BonusN > 0 && presale1BonusD > 0);
		require(presale2Start > presale1Start);
		require(presale2BonusN > 0 && presale2BonusD > 0);
		require(mainsaleStart > presale2Start);
		require(mainsaleEnd > mainsaleStart);

		_owner = msg.sender;
		_newOwner = address(0);
		_drupe = DrupeCoin(drupe);
		_basePrice = Fraction({n: basePriceN, d: basePriceD});
		_refBonus = Fraction({n: refBonusN, d: refBonusD});
		_presale1 = Presale({
			start: presale1Start,
			bonus: Fraction({n: presale1BonusN, d: presale1BonusD})
		});
		_presale2 = Presale({
			start: presale2Start,
			bonus: Fraction({n: presale2BonusN, d: presale2BonusD})
		});
		_mainsale = Mainsale({
			start: mainsaleStart,
			end: mainsaleEnd
		});
	}

	// Modifier to ensure that a function is only called during the ico:
	modifier icoOnly() {
		require(now >= _presale1.start && now < _mainsale.end);
		_;
	}

	// Modifier to ensure that a function is only called by the owner:
	modifier ownerOnly() {
		require(msg.sender == _owner);
		_;
	}



	// Internal function for determining the current bonus:
	// (It is assumed that this function is only called during the ico)
	function _getBonus() internal view returns (Fraction memory bonus) {
		if (now < _presale2.start) {
			bonus = _presale1.bonus;
		} else if (now < _mainsale.start) {
			bonus = _presale2.bonus;
		} else {
			bonus = Fraction({n: 0, d: 1});
		}
	}



	// Exchange Ether for tokens:
	function() public payable icoOnly {
		Fraction memory bonus = _getBonus();

		// Calculate the raw amount of tokens:
		uint rawTokens = msg.value.mul(_basePrice.d).div(_basePrice.n);
		// Calculate the amount of tokens including bonus:
		uint tokens = rawTokens + rawTokens.mul(bonus.n).div(bonus.d);

		// Transfer tokens to the sender:
		_drupe.transfer(msg.sender, tokens);
		// (Sent Ether will remain on this contract)

		// Create referral contract for the sender:
		address refContract = new DrupeICORef(msg.sender, this);
		emit Referrer(msg.sender, refContract);
	}

	// Extended function for exchanging Ether for tokens.
	//  - aquired tokens will be send to the payout address.
	//  - ref bonus tokens will be send to the referrer.
	function purchase(address payout, address referrer) public payable icoOnly returns (uint tokens) {
		Fraction memory bonus = _getBonus();

		// Calculate the raw amount of tokens:
		uint rawTokens = msg.value.mul(_basePrice.d).div(_basePrice.n);
		// Calculate the amount of tokens including bonus:
		tokens = rawTokens + rawTokens.mul(bonus.n).div(bonus.d);
		// Calculate the amount of tokens for the referrer:
		uint refTokens = rawTokens.mul(_refBonus.n).div(_refBonus.d);

		// Transfer tokens to the payout address:
		_drupe.transfer(payout, tokens);
		// Transfer ref bonus tokens to the referrer:
		_drupe.transfer(referrer, refTokens);
		// (Sent Ether will remain on this contract)

		// Create referral contract for the sender:
		address refContract = new DrupeICORef(payout, this);
		emit Referrer(payout, refContract);
	}



	// Function that can be used to burn unsold tokens after the ico has ended:
	function burnUnsoldTokens() public ownerOnly {
		require(now >= _mainsale.end);
		uint unsoldTokens = _drupe.balanceOf(this);
		_drupe.transfer(address(0), unsoldTokens);
	}

	// Function that the owner can withdraw funds:
	function withdrawFunds(uint value) public ownerOnly {
		msg.sender.transfer(value);
	}



	function getOwner() public view returns (address) {
		return _owner;
	}

	function transferOwnership(address newOwner) public ownerOnly {
		_newOwner = newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == _newOwner);
		_owner = _newOwner;
		_newOwner = address(0);
	}



	function getDrupeCoin() public view returns (address) {
		return _drupe;
	}

	function getBasePrice() public view returns (uint n, uint d) {
		n = _basePrice.n;
		d = _basePrice.d;
	}

	function getRefBonus() public view returns (uint n, uint d) {
		n = _refBonus.n;
		d = _refBonus.d;
	}

	function getPresale1() public view returns (uint start, uint bonusN, uint bonusD) {
		start = _presale1.start;
		bonusN = _presale1.bonus.n;
		bonusD = _presale1.bonus.d;
	}

	function getPresale2() public view returns (uint start, uint bonusN, uint bonusD) {
		start = _presale2.start;
		bonusN = _presale2.bonus.n;
		bonusD = _presale2.bonus.d;
	}

	function getMainsale() public view returns (uint start, uint end) {
		start = _mainsale.start;
		end = _mainsale.end;
	}
}