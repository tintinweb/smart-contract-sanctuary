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
	uint public totalSupply;

	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);

	function balanceOf(address who) public view returns (uint);
  	function transfer(address to, uint value) public returns (bool);
  	function allowance(address owner, address spender) public view returns (uint);
  	function transferFrom(address from, address to, uint value) public returns (bool);
  	function approve(address spender, uint value) public returns (bool);
}

contract CampaignContract {
	using SafeMath for uint256;
	
	address internal owner;
	
	//Limits are recorded as USD in ether units (1 ether = 1 USD) [this is units not actual price]
	uint256 public minUSD;
	uint256 public maxUSD;
	uint256 public maxContribution;
	uint256 public minContribution;

	struct KYCObject {
		bytes32 phone;
		bytes32 name;
		bytes32 occupation;
		bytes32 addressOne;
		bytes32 addressTwo;
	}
	
	mapping (address => KYCObject) internal contributionKYC;

	mapping (address => uint256) internal amountAttempted;
	mapping (address => uint256) internal amountContributed;

	uint256 public amountRaised; //Value strictly increases and tracks total raised.
	uint256 public amountRemaining; //Value represents amount that can be withdrawn.

	event OwnerChanged(address indexed from, address indexed to);
	event LimitsChanged(uint256 indexed newMin, uint256 indexed newMax, uint256 indexed price);

	event KYCSubmitted(address indexed who, bytes32 phone, bytes32 name, bytes32 occupation, bytes32 addrOne, bytes32 addrTwo);

	event ContributionReceived(address indexed from, uint256 amount);
	event ContributionWithdrawn(address indexed from, uint256 amount);

	event KYCReset(address indexed by, address indexed who);
	event ContributionIncrease(uint256 indexed time, uint256 amount);
	event ContributionAccepted(address indexed from, uint256 amount, uint256 total);
	event ContributionReturned(address indexed from, uint256 amount);
	
	event EtherWithdrawn(address indexed by, uint256 amount, uint256 remaining);

	function CampaignContract() public {
		owner = msg.sender;
		
		minUSD = 1 ether;
		maxUSD = 950 ether;
		minContribution = .1 ether;
		maxContribution = 1 ether;

		amountRaised = 0 ether;
		amountRemaining = 0 ether;

	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	function changeOwner(address addr) external onlyOwner {
		require(addr != address(0));
		owner = addr;
	
		emit OwnerChanged(msg.sender, addr);
	}
	
	function changeLimits(uint256 price) external onlyOwner {
		uint256 adjPrice = price.div(10**9);
		uint256 adjMin = minUSD.mul(10**9);
		uint256 adjMax = maxUSD.mul(10**9);
	
		maxContribution = adjMax.div(adjPrice);
		minContribution = adjMin.div(adjPrice);
	
		emit LimitsChanged(minContribution, maxContribution, price);
	}

	modifier hasKYCInfo(address addr) {
		require(contributionKYC[addr].phone != "");
		require(contributionKYC[addr].name != "");
		_;
	}
	
	function verifyKYC(bytes32 phone, bytes32 name, bytes32 occupation, bytes32 addrOne, bytes32 addrTwo) external {
		require(contributionKYC[msg.sender].phone == "");
		require(contributionKYC[msg.sender].name == "");
		require(phone != "");
		require(name != "");
		require(occupation != "");
		require(addrOne != "");
		require(addrTwo != "");
	
		contributionKYC[msg.sender].phone = phone;
		contributionKYC[msg.sender].name = name;
		contributionKYC[msg.sender].occupation = occupation;
		contributionKYC[msg.sender].addressOne = addrOne;
		contributionKYC[msg.sender].addressTwo = addrTwo;
	
		emit KYCSubmitted(msg.sender, phone, name, occupation, addrOne, addrTwo);
	}
	
	function getPhone(address addr) external view returns (bytes32 result) {
		return contributionKYC[addr].phone;
	}
	
	function getName(address addr) external view returns (bytes32 result) {
		return contributionKYC[addr].name;
	}
	
	function getOccupation(address addr) external view returns (bytes32 result) {
		return contributionKYC[addr].occupation;
	}
	
	function getAddressOne(address addr) external view returns (bytes32 result) {
		return contributionKYC[addr].addressOne;
	}
	
	function getAddressTwo(address addr) external view returns (bytes32 result) {
		return contributionKYC[addr].addressTwo;
	}

	function contribute() external hasKYCInfo(msg.sender) payable {
		//Make sure they&#39;re not attempting to submit more than max.
		uint256 finalAttempted = amountAttempted[msg.sender].add(msg.value);
		require(finalAttempted <= maxContribution);
	
		//Make sure the attempt added with the already submitted amount isn&#39;t more than max.
		uint256 finalAmount = amountContributed[msg.sender].add(finalAttempted);
		require(finalAmount >= minContribution);
		require(finalAmount <= maxContribution);
	
		amountAttempted[msg.sender] = finalAttempted;
		emit ContributionReceived(msg.sender, msg.value);
	}
	
	function withdrawContribution() external hasKYCInfo(msg.sender) {
		require(amountAttempted[msg.sender] > 0);
		uint256 amount = amountAttempted[msg.sender];
		amountAttempted[msg.sender] = 0;
	
		msg.sender.transfer(amount);
		emit ContributionWithdrawn(msg.sender, amount);
	}
	
	function getAmountAttempted(address addr) external view returns (uint256 amount) {
		return amountAttempted[addr];
	}
	
	function getAmountContributed(address addr) external view returns (uint256 amount) {
		return amountContributed[addr];
	}
	
	function getPotentialAmount(address addr) external view returns (uint256 amount) {
		return amountAttempted[addr].add(amountContributed[addr]);
	}

	function resetKYC(address addr) external onlyOwner hasKYCInfo(addr) {
		//Cant reset KYC for someone who you&#39;ve accepted from already.
		require(amountContributed[addr] == 0);
	
		//Someone having their KYC reset must have withdrawn their attempts.
		require(amountAttempted[addr] == 0);
	
		contributionKYC[addr].phone = "";
		contributionKYC[addr].name = "";
		contributionKYC[addr].occupation = "";
		contributionKYC[addr].addressOne = "";
		contributionKYC[addr].addressTwo = "";
	
		emit KYCReset(msg.sender, addr);
	}
	
	function acceptContribution(address addr) external onlyOwner hasKYCInfo(addr) {
		require(amountAttempted[addr] >= minContribution);
		require(amountContributed[addr].add(amountAttempted[addr]) <= maxContribution);
	
		uint256 amount = amountAttempted[addr];
		amountAttempted[addr] = 0;
		amountContributed[addr] = amountContributed[addr].add(amount);
		amountRaised = amountRaised.add(amount);
		amountRemaining = amountRemaining.add(amount);
	
		emit ContributionIncrease(now, amountRaised);
		emit ContributionAccepted(addr, amount, amountContributed[addr]);
	}
	
	function rejectContribution(address addr) external onlyOwner {
		require(amountAttempted[addr] > 0);
	
		uint256 amount = amountAttempted[addr];
		amountAttempted[addr] = 0;
	
		addr.transfer(amount);
		emit ContributionReturned(addr, amount);
	}
	
	function withdrawToWallet(uint256 amount) external onlyOwner {
		require(amount <= amountRemaining);
	
		amountRemaining = amountRemaining.sub(amount);
		msg.sender.transfer(amount);
		emit EtherWithdrawn(msg.sender, amount, amountRemaining);
	}
	
	function retrieveAssets(address which) external onlyOwner {
		ERC20Base token = ERC20Base(which);
		uint256 amount = token.balanceOf(address(this));
		require(token.transfer(msg.sender, amount));
	}
	
	function killContract() external onlyOwner {
		selfdestruct(msg.sender);
	}

}