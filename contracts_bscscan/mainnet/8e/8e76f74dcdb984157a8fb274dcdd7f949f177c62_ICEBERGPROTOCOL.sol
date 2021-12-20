/**
 *Submitted for verification at BscScan.com on 2021-12-20
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

contract ICEBERGPROTOCOL {
    using SafeMath for uint256;

    address internal owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Call not allowed."); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function getRewardsEarned(address Depositr) public view returns (uint256) {
        return DepositrsRewards[Depositr] + (balance[Depositr] * BurnPerICEBERGPerBlock * (block.number - lastUpdate[Depositr])) / 1e9;
    }

    function getLastUpdate(address Depositr) public view returns (uint256) {
        return lastUpdate[Depositr];
    }

    function getDepositrBalance(address Depositr) public view returns (uint256) {
        return balance[Depositr];
    }

	IBEP20 ICEBERG = IBEP20(0xAdb6b13c85D43D38604247C96958620Ae8e91615); //Main Net

    uint256 public maximumLocked = 100000000 * 1e18;
	uint256 public totalLocked;
    uint256 public BurnPerICEBERGPerBlock;

 	mapping (address => uint256) DepositrsRewards;
	mapping (address => uint256) lastUpdate;
	mapping (address => uint256) balance;

	address[] Depositrs;
    mapping (address => uint256) DepositrIndexes;

    constructor() {
        owner = msg.sender;
    }

    function Deposit(uint256 amount) public {
		require(amount > 0 && totalLocked + amount <= maximumLocked, "The maximum amount of ICEBERGs has been Depositd in this pool.");
		ICEBERG.transferFrom(msg.sender, address(this), amount);

		totalLocked += amount;

		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;

		if (balance[msg.sender] > 0) {
			DepositrsRewards[msg.sender] += (balance[msg.sender] * BurnPerICEBERGPerBlock * (block.number - _lastUpdate)) / 1e18;
		} else {
			addDepositr(msg.sender);
		}

		balance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
		require(amount > 0 && amount <= balance[msg.sender], "You cannot withdraw more than what you have!");
		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;
		DepositrsRewards[msg.sender] += (balance[msg.sender] * BurnPerICEBERGPerBlock * (block.number - _lastUpdate)) / 1e18;
		balance[msg.sender] -= amount;

		if (balance[msg.sender] == 0) {
			removeDepositr(msg.sender);
		}

		ICEBERG.transfer(msg.sender, amount);

        totalLocked -= amount;
    }

    function Burn() public {
		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;
		DepositrsRewards[msg.sender] += (balance[msg.sender] * BurnPerICEBERGPerBlock * (block.number - _lastUpdate)) / 1e18;
		require(DepositrsRewards[msg.sender] > 0, "No rewards to Burn!");
		uint256 rewards = DepositrsRewards[msg.sender];
		DepositrsRewards[msg.sender] = 0;
		ICEBERG.transfer(msg.sender, rewards);
    }
    
	function ModifiyToken(uint256 amount) public onlyOwner {

		for (uint256 i = 0; i < Depositrs.length; i++) {
			uint256 _lastUpdate = lastUpdate[Depositrs[i]];
			lastUpdate[Depositrs[i]] = block.number;
			DepositrsRewards[Depositrs[i]] += (balance[Depositrs[i]] * BurnPerICEBERGPerBlock * (block.number - _lastUpdate)) / 1e18;
		}

		BurnPerICEBERGPerBlock = amount;

	}

	function addDepositr(address Depositr) internal {
        DepositrIndexes[Depositr] = Depositrs.length;
        Depositrs.push(Depositr);
    }

    function removeDepositr(address Depositr) internal {
        Depositrs[DepositrIndexes[Depositr]] = Depositrs[Depositrs.length-1];
        DepositrIndexes[Depositrs[Depositrs.length-1]] = DepositrIndexes[Depositr];
        Depositrs.pop();
    }

}