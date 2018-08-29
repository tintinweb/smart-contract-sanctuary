pragma solidity ^0.4.24;

// THE LAST SMART CONTRACT HAD SOME SECURITY HOLES
// THIS IS THE SECOND SMART CONTRACT FOR THE LIKE FEATURE
// OLD CONTRACT CAN BE SEEN AT https://etherscan.io/address/0x6acd16200a2a046bf207d1b263202ec1a75a7d51
// DATA IS IMPORTED FROM THE LAST CONTRACT
// BIG SHOUTOUT TO CASTILLO NETWORK FOR FINDING THE SECURITY HOLE AND PERFORMING AN AUDIT ON THE LAST CONTRACT
// https://github.com/EthereumCommonwealth/Auditing

// Old contract data
contract dappVolumeHearts {
	// map dapp ids with heart totals
	mapping(uint256 => uint256) public totals;
	// get total hearts by id
	function getTotalHeartsByDappId(uint256 dapp_id) public view returns(uint256) {
		return totals[dapp_id];
	}
}

// Allows users to "heart" (like) a DAPP by dapp id
// 1 Like = XXXXX eth will be set on front end of site
// 50% of each transaction gets sent to the last liker

contract DappVolumeHearts {

	dappVolumeHearts firstContract;

	using SafeMath for uint256;

	// set contract owner
	address public contractOwner;
	// set last address transacted
	address public lastAddress;
	// set first contracts address
	address constant public firstContractAddress = 0x6ACD16200a2a046bf207D1B263202ec1A75a7D51;
	// map dapp ids with heart totals ( does not count first contract )
	mapping(uint256 => uint256) public totals;

	// only contract owner
	modifier onlyContractOwner {
		require(msg.sender == contractOwner);
		_;
	}

	// set constructor
	constructor() public {
		contractOwner = msg.sender;
		lastAddress = msg.sender;
		firstContract = dappVolumeHearts(firstContractAddress);
	}


	// withdraw funds to contract creator
	function withdraw() public onlyContractOwner {
		contractOwner.transfer(address(this).balance);
	}

	// update heart count
	function update(uint256 dapp_id) public payable {
		require(msg.value >= 2000000000000000);
		require(dapp_id > 0);
		totals[dapp_id] = totals[dapp_id].add(msg.value);
		// send 50% of the money to the last person
		lastAddress.send(msg.value.div(2));
		lastAddress = msg.sender;
	}

	// get total hearts by id with legacy contract totaled in
	function getTotalHeartsByDappId(uint256 dapp_id) public view returns(uint256) {
		return totals[dapp_id].add(firstContract.getTotalHeartsByDappId(dapp_id));
	}

	// get contract balance
	function getBalance() public view returns(uint256){
		return address(this).balance;
	}

}

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