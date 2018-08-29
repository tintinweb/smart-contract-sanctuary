pragma solidity ^0.4.24;

// THE LAST SMART CONTRACT HAD SOME SECURITY HOLES
// THIS IS THE SECOND SMART CONTRACT
// OLD CONTRACT CAN BE SEEN AT https://etherscan.io/address/0xdd8f1fc3f9eb03e151abb5afcc42644e28a1e797
// DATA IS IMPORTED FROM THE LAST CONTRACT
// BIG SHOUTOUT TO CASTILLO NETWORK FOR FINDING THE SECURITY HOLE AND PERFORMING AN AUDIT ON THE LAST CONTRACT
// https://github.com/EthereumCommonwealth/Auditing

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

// Create Ad on DappVolume
// Advertiser can choose 1 hour, 12 hours, 24 hours, or 1 week
// half of the money gets sent back to last advertiser
//
// An investor can earn 10% of the ad revenue
// Investors can get bought out by new investors
// when an invester is bought out, they get 120% of their investment back

contract DappVolumeAd {

	// import safemath
	using SafeMath for uint256;

	// set variables
	uint256 public dappId;
	uint256 public purchaseTimestamp;
	uint256 public purchaseSeconds;
	uint256 public investmentMin;
	uint256 public adPriceHour;
	uint256 public adPriceHalfDay;
	uint256 public adPriceDay;
	uint256 public adPriceWeek;
	uint256 public adPriceMultiple;
	address public contractOwner;
	address public lastOwner;
	address public theInvestor;

	// only contract owner
	modifier onlyContractOwner {
		require(msg.sender == contractOwner);
		_;
	}

	// set constructor
	constructor() public {
		investmentMin = 4096000000000000000;
		adPriceHour = 5000000000000000;
		adPriceHalfDay = 50000000000000000;
		adPriceDay = 100000000000000000;
		adPriceWeek = 500000000000000000;
		adPriceMultiple = 2;
		contractOwner = msg.sender;
		theInvestor = 0x1C26d2dFDACe03F0F6D0AaCa233D00728b9e58da;
		lastOwner = contractOwner;
	}

	// withdraw funds to contract creator
	function withdraw() public onlyContractOwner {
		contractOwner.transfer(address(this).balance);
	}

	// set ad price multiple incase we want to up the price in the future
	function setAdPriceMultiple(uint256 amount) public onlyContractOwner {
		adPriceMultiple = amount;
	}

	// update and set ad
	function updateAd(uint256 id) public payable {
		// set minimum amount and make sure ad hasnt expired
		require(msg.value >= adPriceMultiple.mul(adPriceHour));
		require(block.timestamp > purchaseTimestamp.add(purchaseSeconds));
		require(id > 0);

		// send 10% to the investor
		theInvestor.send(msg.value.div(10));
		// send 50% of the money to the last person
		lastOwner.send(msg.value.div(2));

		// set ad time limit in seconds
		if (msg.value >= adPriceMultiple.mul(adPriceWeek)) {
			purchaseSeconds = 604800; // 1 week
		} else if (msg.value >= adPriceMultiple.mul(adPriceDay)) {
			purchaseSeconds = 86400; // 1 day
		} else if (msg.value >= adPriceMultiple.mul(adPriceHalfDay)) {
			purchaseSeconds = 43200; // 12 hours
		} else {
			purchaseSeconds = 3600; // 1 hour
		}

		// set dapp id
		dappId = id;
		// set new timestamp
		purchaseTimestamp = block.timestamp;
		// set last owner
		lastOwner = msg.sender;
	}

	// update the investor
	function updateInvestor() public payable {
		require(msg.value >= investmentMin);
		// send 60% to last investor (120% of original purchase)
		theInvestor.send(msg.value.div(100).mul(60));
		// double the price to become the investor
		investmentMin = investmentMin.mul(2);
		// set new investor
		theInvestor = msg.sender;
	}

	// get timestamp when ad ends
	function getPurchaseTimestampEnds() public view returns (uint _getPurchaseTimestampAdEnds) {
		return purchaseTimestamp.add(purchaseSeconds);
	}

	// get contract balance
	function getBalance() public view returns(uint256){
		return address(this).balance;
	}

}