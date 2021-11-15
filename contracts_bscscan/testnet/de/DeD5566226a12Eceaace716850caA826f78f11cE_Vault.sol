/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Vault {
    using SafeMath for uint256;

    address internal owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Call not allowed."); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function getRewardsEarned(address staker) public view returns (uint256) {
        return stakersRewards[staker] + (balance[staker] * rewardsPerSAFUPerBlock * (block.number - lastUpdate[staker])) / 1e9;
    }

    function getLastUpdate(address staker) public view returns (uint256) {
        return lastUpdate[staker];
    }

    function getStakerBalance(address staker) public view returns (uint256) {
        return balance[staker];
    }

	//IBEP20 SAFU = IBEP20(0x890cc7d14948478c98A6CD7F511E1f7f7f99F397); //Main Net
	IBEP20 SAFU = IBEP20(0xFaD74bF823Be5a09a0a269CdE4c59C1073FDA6c1); //Test Net

    uint256 public maximumLocked = 2000 * 1e9;
	uint256 public totalLocked;
    uint256 public rewardsPerSAFUPerBlock;

 	mapping (address => uint256) stakersRewards;
	mapping (address => uint256) lastUpdate;
	mapping (address => uint256) balance;

	address[] stakers;
    mapping (address => uint256) stakerIndexes;

    constructor() {
        owner = msg.sender;
    }

    function stake(uint256 amount) public {
		require(amount > 0 && totalLocked + amount <= maximumLocked, "The maximum amount of SAFUs has been staked in this pool.");
		SAFU.transferFrom(msg.sender, address(this), amount);

		totalLocked += amount;


		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;

		if (balance[msg.sender] > 0) {
			stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerSAFUPerBlock * (block.number - _lastUpdate)) / 1e9;
		} else {
			addStaker(msg.sender);
		}

		balance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
		require(amount > 0 && amount <= balance[msg.sender], "You cannot withdraw more than what you have!");
		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;
		stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerSAFUPerBlock * (block.number - _lastUpdate)) / 1e9;
		balance[msg.sender] -= amount;

		if (balance[msg.sender] == 0) {
			removeStaker(msg.sender);
		}

		SAFU.transfer(msg.sender, amount);
    }

    function claim() public {
		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;
		stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerSAFUPerBlock * (block.number - _lastUpdate)) / 1e9;
		require(stakersRewards[msg.sender] > 0, "No rewards to claim!");
		uint256 rewards = stakersRewards[msg.sender];
		stakersRewards[msg.sender] = 0;
		SAFU.transfer(msg.sender, rewards);
    }
    
	function modifyRewards(uint256 amount) public onlyOwner {

		for (uint256 i = 0; i < stakers.length; i++) {
			uint256 _lastUpdate = lastUpdate[stakers[i]];
			lastUpdate[stakers[i]] = block.number;
			stakersRewards[stakers[i]] += (balance[stakers[i]] * rewardsPerSAFUPerBlock * (block.number - _lastUpdate)) / 1e9;
		}

		rewardsPerSAFUPerBlock = amount;

	}

	function addStaker(address staker) internal {
        stakerIndexes[staker] = stakers.length;
        stakers.push(staker);
    }

    function removeStaker(address staker) internal {
        stakers[stakerIndexes[staker]] = stakers[stakers.length-1];
        stakerIndexes[stakers[stakers.length-1]] = stakerIndexes[staker];
        stakers.pop();
    }

}