// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

struct Payout {
	address beneficiary;
	uint96 amount;
}

contract Gamber {
	
	uint256 public fee;
	address public collector;
	address public owner;
	uint192 public rate; // in 0.01%
	uint256 public lowerBound;
	uint256 public upperBound;	
	uint128 public first;
  uint128 public last;
	mapping(uint128 => Payout) public payouts;
	uint256 public balance;

	constructor() {
		owner = msg.sender;
		collector = msg.sender;
		lowerBound =   30000000000000000;
		upperBound = 1000000000000000000;
		rate = 2000;
	}

	modifier onlyOwner() {
		require(owner == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	function setCollector(address newCollector) public onlyOwner {
		require(newCollector != address(0), "New collector is the zero address");
		collector = newCollector;
	}

	event RateChanged(uint192 rate);

	function setRate(uint192 newRate) public onlyOwner {
		require(newRate > 0, "Rate should be positive");
		rate = newRate;
		emit RateChanged(rate);
	}

	event BoundsUpdated(uint256 lower, uint256 upper);

	function setBounds(uint192 newLowerBound, uint192 newUpperBound) public onlyOwner {
		require(newUpperBound > newLowerBound, "Upper bound should be greater than lower bound");
		upperBound = newUpperBound;
		lowerBound = newLowerBound;

		emit BoundsUpdated(lowerBound, upperBound);
	}

	function setUpperBound(uint192 newUpperBound) public onlyOwner {
		require(newUpperBound > lowerBound, "Upper bound should be greater than lower bound");
		upperBound = newUpperBound;

		emit BoundsUpdated(lowerBound, upperBound);
	}

	function setLowerBound(uint192 newLowerBound) public onlyOwner {
		require(newLowerBound < upperBound, "Lower bound should be less than upper bound");
		lowerBound = newLowerBound;

		emit BoundsUpdated(lowerBound, upperBound);
	}

	event Collected(uint256 amount);

	function collect() public onlyOwner {
		require(fee > 0, "Nothing to collect");
		payable(collector).transfer(fee);
		emit Collected(fee);
		fee = 0;
	}

	event Accepted(address sender, uint256 amount);

	function accept(address sender, uint256 amount) internal {
		fee += amount/10;
		balance += amount - amount/10;
		if(amount >= lowerBound) {
			if(amount > upperBound) amount = upperBound;
			emit Accepted(sender, amount);
			amount += amount*rate/10000;
			payouts[last++] = Payout(sender, uint96(amount));
		}
	}

	event Paid(address beneficiary, uint96 amount);

	function pay(address beneficiary, uint96 amount) internal {
		payable(beneficiary).transfer(amount);
		balance -= amount;
		emit Paid(beneficiary, amount);
	}

	receive() external payable {
		accept(msg.sender, msg.value);		
		while(balance > payouts[first].amount && payouts[first].beneficiary != address(0)) {
			pay(payouts[first].beneficiary, payouts[first].amount);
			delete payouts[first++];
		}
	}
}