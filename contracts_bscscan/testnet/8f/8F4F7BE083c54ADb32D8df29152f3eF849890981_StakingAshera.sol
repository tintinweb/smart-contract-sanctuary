/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: Unlicensed
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


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromPresale(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

contract StakingAshera{
    uint8 currentRound=1;
   
    uint256 round1Price= 50000;
    
    uint256 public totalWithdraw;
	uint256 public totalPartners;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		uint8 reinvest;
		uint256 preLaunchBonus;
		
	}
	uint256 constant public TIME_STEP = 1 days;
	struct WitthdrawHistory {
        
		uint256 amount;
		
		uint256 start;
		
	}
	struct User {
		Deposit[] deposits;
		
		WitthdrawHistory[] whistory;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256[5] leveldeposits;
	
		uint256[5] levelbonus;
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalWithdraw;
	}
	uint256 constant public PERCENTS_DIVIDER = 1000;
	mapping (address => User) internal users;

	uint256 public startUNIX;
   address tokenContract;
using SafeMath for uint256;
address owner;
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
     constructor(address _tokenContract,uint256 startDate)  {
       
         require(_tokenContract != address(this), "Can't let you take all native token");
          startUNIX = startDate;
       plans.push(Plan(2, 600));
        plans.push(Plan(3, 500));
        plans.push(Plan(5, 400));
        plans.push(Plan(10, 300));
        plans.push(Plan(20, 200));
        plans.push(Plan(50, 100));
          tokenContract = _tokenContract;
       
    }
    
    function deposit() public payable    {
        
        uint256 token=0;
     
            token=msg.value.mul(round1Price).div(1000000000);
        
        
        IERC20(tokenContract).transferFromPresale(address(this),msg.sender,token);
        
    }
     function stakeAshera(uint8 plan,uint256 amount) public payable    {
        
        uint256 token=0;
     
            token=amount;
        if(IERC20(tokenContract).balanceOf(msg.sender)<token){
            token=IERC20(tokenContract).balanceOf(msg.sender);
        }
        
         IERC20(tokenContract).transferFromPresale(msg.sender,address(this),token);
         	User storage user = users[msg.sender];
         	uint256 depositsValue=token;
         		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan,depositsValue);
         	user.deposits.push(Deposit(plan, percent, depositsValue, profit, block.timestamp, finish,0,0));
		

		emit NewDeposit(msg.sender, plan, percent, depositsValue, profit, block.timestamp, finish);
        
    }
    function stakeBNB(uint8 plan) public payable    {
        
        uint256 token=0;
     
            token=msg.value.mul(round1Price).div(1000000000);
        
        
        IERC20(tokenContract).transferFromPresale(address(this),msg.sender,token);
         IERC20(tokenContract).transferFromPresale(msg.sender,address(this),token);
         	User storage user = users[msg.sender];
         	uint256 depositsValue=token;
         		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan,depositsValue);
         	user.deposits.push(Deposit(plan, percent, depositsValue, profit, block.timestamp, finish,0,0));
		

		emit NewDeposit(msg.sender, plan, percent, depositsValue, profit, block.timestamp, finish);
        
    }
    	function getPercent(uint8 plan) public view returns (uint256) {
		
			return plans[plan].percent;
		
    }
    function getResult(uint8 plan, uint256 depositv) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);	
        profit = depositv.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}


	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
			
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				
			}
		}

		return totalAmount;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
	function getUserTotalWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].totalWithdraw;
	}
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory levels) {
		levels=users[userAddress].levels;
	}
	function getUserDownlineBonus(address userAddress) public view returns(uint256[5] memory levelbonus) {
	levelbonus=	users[userAddress].levelbonus;
	}
		function getUserDownlineDeposits(address userAddress) public view returns(uint256[5] memory leveldeposits) {
	leveldeposits= users[userAddress].leveldeposits;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	
	
	function getUserWithdrawHistory(address userAddress, uint256 index) public view returns(uint256 amount, uint256 start) {
	    User storage user = users[userAddress];

		amount = user.whistory[index].amount;
		start=user.whistory[index].start;
		
		
		
	}
	function getUserWithdrawSize(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];

		
		return user.whistory.length;
		
		
		
	}
	function getUserDepositeSize(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];

		
		return user.deposits.length;
		
		
		
	}
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, uint256 isreinvest,uint256 prebonus) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
		isreinvest = user.deposits[index].reinvest;
		prebonus = user.deposits[index].preLaunchBonus;

	}
    
}