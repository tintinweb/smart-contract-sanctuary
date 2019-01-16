pragma solidity ^0.4.24;

/**
 * @title Owned
 * @dev Contract that sets an owner, who can execute predefined functions, only accessible by him
 */
contract Owned {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != 0x0);
		owner = newOwner;
	}
}

/**
 * @title SafeMath
 * @dev Mathematical functions to check for overflows
 */
contract SafeMath {
	function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);

		return c;
	}
}

contract CURESSale is Owned, SafeMath {
	uint256 public maxGoal = 175000 * 1 ether;			// Hard Cap in Ethereum
	uint256 public minTransfer = 5 * 1 ether;			// Minimum amount in EHT that can be send
	uint256 public amountRaised = 0;					// The raised amount in ETH Wei
	mapping(address => uint256) public payments;		// How much ETH the user sent
	bool public isFinalized = false;					// Indicates if the Private Sale is finalized

	// Public event on the blockchain, to notify users when a Payment was made
	event PaymentMade(address indexed _to, uint256 _ammount);

	/**
	 * @dev The default function called when anyone sends funds (ETH) to the contract
	 */
	function() payable public {
		buyTokens();
	}

	function buyTokens() payable public returns (bool success) {
		// Check if finalized
		require(!isFinalized);

		uint256 amount = msg.value;

		// Check if the goal is reached
		require(safeAdd(amountRaised, amount) <= maxGoal);

		require(amount >= minTransfer);

		payments[msg.sender] = safeAdd(payments[msg.sender], amount);
		amountRaised = safeAdd(amountRaised, amount);

		owner.transfer(amount);

		emit PaymentMade(msg.sender, amount);
		return true;
	}

	/**
	 * @return The amount of ETH raised
	 */
	function raised() public view returns (uint256 amount) {
		return amountRaised / 1 ether;
	}

	// In case of any ETH left at the contract
	// Can be used only after the Sale is finalized
	function withdraw(uint256 _value) public onlyOwner {
		require(isFinalized);
		require(_value > 0);

		msg.sender.transfer(_value);
	}

	function changeMinTransfer(uint256 min) external onlyOwner {
		require(!isFinalized);

		require(min > 0);

		minTransfer = min;
	}

	// CURES finalizes the Sale
	function finalize() external onlyOwner {
		require(!isFinalized);

		// Finalize the Sale
		isFinalized = true;
	}
}