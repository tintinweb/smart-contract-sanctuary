/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT 
contract Ownable {
    address public owner;
    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
pragma solidity >=0.4.0 <0.9.0;
contract PolysecPRO is Ownable{
	using SafeMath for uint256;
	using SafeBEP20 for IBEP20;

    IBEP20 public token;
	uint256 constant public INVEST_MIN_AMOUNT = 0.01 ether; // 1 cake
	uint256[] internal REFERRAL_PERCENTS = [50e2, 25e2, 20e2];
	uint256 constant public PROJECT_FEE = 60e2;
	uint256 constant public FUND_FEE = 60e2;
	uint256 constant public MARKETING_FEE = 30e2;
	uint256 constant public PERCENT_STEP = 2e2;
	uint256 constant public PERCENTS_DIVIDER = 1000e2;
	uint256 constant public DECREASE_DAY_STEP = 0.2 days; //0.25 days
    uint256 constant internal REF_STEP = 10; // 10 Refs level 
    uint256 constant internal TIME_STEP = 1 days; //1 days

	uint256 public totalStaked;
	uint256 public totalRefBonus;
	
	uint256 public startUNIX;
	address payable public marketingAddress;
    address payable public projectAddress;
    address payable public fundAddress;

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
		bool force;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 apft;
        uint256 aparticipation;
        uint256 wprofits;
	}
	
    mapping(uint256 => mapping(address => uint256)) internal auds;
    mapping(uint256 => address) internal at;
    mapping(uint256 => address) internal alt;
	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr,address payable fundAddr,address payable projectAddr,uint256 startDate, IBEP20 tokenAddr) {
        require(!isContract(fundAddr));
		require(startDate > 0);
		token = tokenAddr;
		marketingAddress = marketingAddr;
		fundAddress = fundAddr;
        projectAddress = projectAddr;
		startUNIX = startDate;

        plans.push(Plan(14, 80e2));
        plans.push(Plan(21, 60e2));
        plans.push(Plan(28, 50e2));
        plans.push(Plan(14, 80e2));

	}
    
    function FeePayout(uint256 amt) internal{
    uint256 mktFee = amt.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
    uint256 fundFee = amt.mul(FUND_FEE).div(PERCENTS_DIVIDER);
    uint256 prjFee = amt.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
    token.safeTransfer(marketingAddress, mktFee);
    token.safeTransfer(fundAddress, fundFee);
    token.safeTransfer(projectAddress, prjFee);
    emit FeePayed(msg.sender, mktFee.add(prjFee).add(fundFee));
    }
  

	function invest(address referrer, uint8 plan) public payable{
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");
        
        token.safeTransferFrom(msg.sender, address(this), msg.value);

		FeePayout(msg.value);

		User storage user = users[msg.sender];
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}else{
			    user.referrer = projectAddress;
			}
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					if (users[upline].referrer == address(0)){
			        users[upline].referrer = projectAddress;
			        }
					upline = users[upline].referrer;
				} else break;
			}
		}
		
		
		uint256 refsamount;
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				    refsamount = refsamount.add(amount);
			}
		}
			if (refsamount > 0){
    
            uint256 proFee = refsamount.div(2);
            uint256 funFee = refsamount.div(2);
            token.safeTransfer(projectAddress, proFee);
            token.safeTransfer(fundAddress, funFee);

			}
		}
		else{
		    uint256 refbk = 95;
			uint256 amount = msg.value.mul(refbk).div(PERCENTS_DIVIDER);
            uint256 prFee = amount.div(2);
            uint256 fuFee = amount.div(2);
            token.safeTransfer(projectAddress, prFee);
            token.safeTransfer(fundAddress, fuFee);
		}
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}
		
        (uint256 percent, uint256 profit, , uint256 finish) = getResult(plan, msg.value);
        user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish, true));
		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}
	
	function withdraw() public {
        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }
        require(totalAmount > 0, "User has no dividends");
        uint256 contractBalance = token.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        user.checkpoint = block.timestamp;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    user.deposits[i].force = false;
                } else if (block.timestamp > user.deposits[i].finish) {
                    user.deposits[i].force = false;
                }
            }
        }
        user.wprofits = (user.wprofits).add(totalAmount);
        token.safeTransfer(payable(msg.sender), totalAmount);
        
        emit Withdrawn(msg.sender, totalAmount);
    }

	function getContractBalance() public view returns (uint256) {
		return token.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
	    uint256 userRefRate = getUserRefRate(msg.sender);
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP)).add(userRefRate);
		} else {
			return plans[plan].percent;
		}
    }
	
	function getResult(uint8 plan, uint256 deposit) public view returns ( uint256 percent, uint256 profit, uint256 current, uint256 finish){
        percent = getPercent(plan);
        if (plan < 3) {
            profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        } else if (plan < 4) {
            for (uint256 i = 0; i < plans[plan].time; i++) {
                profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
            }
        }
        current = block.timestamp;
        finish = current.add(getDecreaseDays(plans[plan].time));
    }
	
	function getUserDividends(address userAddress) public view returns (uint256){
        User memory user = users[userAddress];

        uint256 totalAmount;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                    uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                    uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
                    if (from < to) {
                        uint256 planTime = plans[user.deposits[i].plan].time.mul(TIME_STEP);
                        uint256 redress = planTime.div(getDecreaseDays(plans[user.deposits[i].plan].time));
                        totalAmount = totalAmount.add(share.mul(to.sub(from)).mul(redress).div(TIME_STEP));
                    }
                } else if (block.timestamp > user.deposits[i].finish) {
                    totalAmount = totalAmount.add(user.deposits[i].profit);
                }
            }
        }
        return totalAmount;
    }
	
	function getDecreaseDays(uint256 planTime) public view returns (uint256) {
	    uint256 None = planTime.mul(TIME_STEP);
        if (block.timestamp > startUNIX){
        uint256 limitDays = TIME_STEP.mul(4);
        uint256 pastDays = block.timestamp.sub(startUNIX).div(TIME_STEP);
        uint256 decreaseDays = pastDays.mul(DECREASE_DAY_STEP);
        if (decreaseDays > limitDays){
        decreaseDays = limitDays;
        }
        uint256 minimumDays = planTime.mul(TIME_STEP).sub(decreaseDays);
        return minimumDays;  
      }
      else{
          return None;
      }
    }
    
    function getUserRefRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 refsbonus = user.levels[0];
        uint256 RMultiplier = (refsbonus.div(REF_STEP)).mul(100);
            return RMultiplier;
    }
    

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
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

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	
	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].wprofits;
	}
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, bool force){
        User memory user = users[userAddress];
        require(index < user.deposits.length, "Invalid index");

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
        force = user.deposits[index].force;
    }
    
    function setDeveloperAccount(address payable _newDeveloperAccount) public onlyOwner {
        require(_newDeveloperAccount != address(0));
        projectAddress = _newDeveloperAccount;
    }
    
    function setMarketingAccount(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAddress = _newMarketingAccount;
    }
    
    function setFundAccount(address payable _newFundAccount) public onlyOwner {
        require(_newFundAccount != address(0));
        fundAddress = _newFundAccount;
    }


	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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