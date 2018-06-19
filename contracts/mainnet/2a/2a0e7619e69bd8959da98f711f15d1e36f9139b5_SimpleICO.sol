pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);
        uint256 c = a / b;
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

contract ERC20Base {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	string public name;
	string public symbol;
	uint8 public decimals;

	function totalSupply() public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	function balanceOf(address who) public view returns (uint256);
	function allowance(address owner, address spender) public view returns (uint256);
}

contract SimpleICO {
	using SafeMath for uint256;
	
	address internal owner;
	uint256 public startTime;
	uint256 public endTime;
	
	//0 - Initial State
	//1 - Contribution State
	//2 - Final State
	uint256 public state;

	mapping (address => bool) internal contributionKYC;

	mapping (address => uint256) internal originalContributed;
	mapping (address => uint256) internal adjustedContributed;
	uint256 public amountRaised; //Value strictly increases and tracks total raised.
	uint256 public adjustedRaised;
	uint256 public currentRate;

	uint256 public amountRemaining; //Amount that can be withdrawn.
	uint256 public nextCheckpoint; //Next blocktime that funds can be released.
	uint256 public tenthTotal;

	event KYCApproved(address indexed who, address indexed admin);
	event KYCRemoved(address indexed who, address indexed admin);

	event RateDecreased(uint256 indexed when, uint256 newRate);
	event ContributionReceived(address indexed from, uint256 amount, uint256 soFar);

	event EtherReleased(uint256 time, uint256 amount);
	event EtherWithdrawn(address indexed by, uint256 amount, uint256 remaining);

	function SimpleICO() public {
		owner = msg.sender;
		startTime = 0;
		endTime = 0;
		state = 0;

		amountRaised = 0 ether;
		adjustedRaised = 0 ether;
		currentRate = 4;

		amountRemaining = 0 ether;
		nextCheckpoint = 0;
		tenthTotal = 0 ether;

	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier stillRunning() {
		require(state == 1);
		require(now <= endTime);
		_;
	}
	
	modifier canEnd() {
		require(state == 1);
		require(now > endTime || amountRaised >= 500 ether);
		_;
	}

	modifier allowKYC(address addr) {
		if (!contributionKYC[addr]) {
			uint256 total = originalContributed[msg.sender].add(msg.value);
			require(total < .1 ether);
		}
	
		_;
	}
	
	function isApproved(address addr) external view returns (bool) {
		return contributionKYC[addr];
	}
	
	function approveKYC(address addr) external onlyOwner {
		require(!contributionKYC[addr]);
		contributionKYC[addr] = true;
	
		emit KYCApproved(addr, msg.sender);
	}
	
	function removeKYC(address addr) external onlyOwner {
		require(contributionKYC[addr]);
		require(originalContributed[addr] < .1 ether);
		contributionKYC[addr] = false;
	
		emit KYCRemoved(addr, msg.sender);
	}

	function contribute() external allowKYC(msg.sender) stillRunning payable {
		uint256 total = originalContributed[msg.sender].add(msg.value);
		uint256 adjusted = msg.value.mul(currentRate);
		uint256 adjustedTotal = adjustedContributed[msg.sender].add(adjusted);
	
		originalContributed[msg.sender] = total;
		adjustedContributed[msg.sender] = adjustedTotal;
	
		amountRaised = amountRaised.add(msg.value);
		adjustedRaised = adjustedRaised.add(adjusted);
		emit ContributionReceived(msg.sender, msg.value, total);
	
		if (currentRate == 4 && now > (startTime.add(2 weeks))) {
			currentRate = 2;
			emit RateDecreased(now, currentRate);
		}
	}
	
	function getAmountContributed(address addr) external view returns (uint256 amount) {
		return originalContributed[addr];
	}
	
	function getAdjustedContribution(address addr) external view returns (uint256 amount) {
		return adjustedContributed[addr];
	}

	function startContribution() external onlyOwner {
		require(state == 0);
		state = 1;
		startTime = now;
		endTime = now + 4 weeks;
	}
	
	function endContribution() external canEnd onlyOwner { //Require state 1 is in canEnd
		tenthTotal = amountRaised.div(10);
		amountRemaining = tenthTotal.mul(5);
		nextCheckpoint = now + 1 weeks;
	
		state = 2;
		emit EtherReleased(now, tenthTotal.mul(5));
	}
	
	function withdrawToWallet(uint256 amount) external onlyOwner {
		require(state == 2);
		require(amount <= amountRemaining);
	
		if (now > nextCheckpoint) {
			amountRemaining = amountRemaining.add(tenthTotal);
			nextCheckpoint = now + 1 weeks;
	
			emit EtherReleased(now, tenthTotal);
		}
	
		amountRemaining = amountRemaining.sub(amount);
		msg.sender.transfer(amount);
		emit EtherWithdrawn(msg.sender, amount, amountRemaining);
	}
	
	function retrieveAssets(address which) external onlyOwner {
		require(which != address(this));
	
		ERC20Base token = ERC20Base(which);
		uint256 amount = token.balanceOf(address(this));
		require(token.transfer(msg.sender, amount));
	}

}