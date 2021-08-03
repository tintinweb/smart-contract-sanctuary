pragma solidity 0.5.10;

contract bnbsaving {
	using SafeMath for uint256;

    uint256 private constant MIN_DEP = 0.05 ether;
    uint256 private constant MAX_DEP = 100 ether;
    uint256 private constant MIN_WITHDRAW = 0.05 ether;
	uint256 private constant REFERENCE_RATE_P0 = 100;
	uint256 private constant REFERENCE_RATE_P1 = 100;
	uint256 private constant MAX_INC_P1 = 150;
	uint256 private constant PRJ1_FEE = 15;
	uint256 private constant PRJ2_FEE = 15;
	uint256 private constant PRJ3_FEE = 10;
	uint256 private constant PRJ4_FEE = 10;
	uint256 private constant PRJ5_FEE = 10;
	uint256 private constant MARKETING_FEE = 50;
	uint256 private constant DEV_FEE = 30;
	uint256 private constant PERCENT_STEP = 5;
	uint256 private constant COMMUNITY_FUND = 100;
	uint256 private constant PERCENTS_DIVIDER = 1000;
	uint256 private constant TIME_STEP = 8 hours;
	uint256 private constant TIME_STEP2 = 1 days;
	uint256 private constant INSURANCE_DURATION = 60;

    uint256 public  totalUsers;
    uint256 public  totalInvestments;
    uint256 public  totalWithdraws;
    uint256 public  totalReferral;
    uint256 public  totalCommunityFund;
    uint256 public  totalInsurance;
	uint256 public  launchDate;

    address payable public prjAcc1;
    address payable public prjAcc2;
    address payable public prjAcc3;
    address payable public prjAcc4;
    address payable public prjAcc5;
    address payable public marketingAccount;
	address payable public developerAccount;

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
        bool terminate;
        bool active;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 refCnt;
		uint256 totalBonus;
		uint256 totalInvest;
		uint256 totalWithdraw;
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event TerminateDeposit(address indexed user,  uint256 amount);

    constructor(address payable marketingAddr, address payable developerAddr, address payable prjAddr1, address payable prjAddr2, address payable prjAddr3, address payable prjAddr4, address payable prjAddr5, uint256 startDate) public {
        require(marketingAddr != address(0) && developerAddr != address(0) && prjAddr1 != address(0) && prjAddr2 != address(0) && prjAddr3 != address(0) && prjAddr4 != address(0) && prjAddr5 != address(0));
		require(startDate >= 0);
        developerAccount = developerAddr;
        marketingAccount = marketingAddr;
        prjAcc1 = prjAddr1;
        prjAcc2 = prjAddr2;
        prjAcc3 = prjAddr3;
        prjAcc4 = prjAddr4;
        prjAcc5 = prjAddr5;
		if(startDate>0){
			launchDate = startDate;
		}
		else{
			launchDate = block.timestamp;
		}

        plans.push(Plan(30, 40));
        plans.push(Plan(30, 30));
	}

	function projectFee() private {
        prjAcc1.transfer(msg.value.mul(PRJ1_FEE).div(PERCENTS_DIVIDER));
        prjAcc2.transfer(msg.value.mul(PRJ2_FEE).div(PERCENTS_DIVIDER));
        prjAcc3.transfer(msg.value.mul(PRJ3_FEE).div(PERCENTS_DIVIDER));
        prjAcc4.transfer(msg.value.mul(PRJ4_FEE).div(PERCENTS_DIVIDER));
        prjAcc5.transfer(msg.value.mul(PRJ5_FEE).div(PERCENTS_DIVIDER));
        marketingAccount.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		developerAccount.transfer(msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER));
	}

	function invest(address referrer, uint8 plan) public payable {
		require(msg.value >= MIN_DEP, "Min Deposit Amount is 0.05 BNB");
        require(msg.value <= MAX_DEP, "Max Deposit Amount is 100  BNB");
        require(plan < 2, "Invalid plan");

		projectFee();

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			if (upline != address(0)) {
				users[upline].refCnt = users[upline].refCnt.add(1);
			} 
			
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			if (upline != address(0)) {
				uint256 amount = 0;
				if(plan==0){
					amount = msg.value.mul(REFERENCE_RATE_P0).div(PERCENTS_DIVIDER);
				}
				else if(plan==1){
					amount = msg.value.mul(REFERENCE_RATE_P1).div(PERCENTS_DIVIDER);
				}
				if(amount>0){
					address(uint160(upline)).transfer(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					totalReferral = totalReferral.add(amount);
					emit RefBonus(upline, msg.sender, amount);
				}
			}
			
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish, true ,true));

		user.totalInvest = user.totalInvest.add(msg.value);
		totalInvestments = totalInvestments.add(msg.value);
		totalInsurance = totalInsurance.add((msg.value).div(2));
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		//only once a day
		require(block.timestamp > user.checkpoint + TIME_STEP , "Only once per 8 hours");

		uint256 totalAmount = getUserDividends(msg.sender);
        require(totalAmount > MIN_WITHDRAW , "Min Withdraw is 0.05 BNB");

		uint256 insurance = 0;
		if(user.totalWithdraw < user.totalInvest.div(2)){
			insurance = (user.totalInvest.div(2)).sub(user.totalWithdraw);
			if(insurance > totalAmount)
			{
				insurance = totalAmount;
			}
			if(totalInsurance >= insurance)
			{
				totalInsurance = totalInsurance.sub(insurance);
			}
		}

		totalAmount = totalAmount.sub(insurance);
		uint256 contractBalance = getContractAvailableBalance();
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		totalAmount = totalAmount.add(insurance);

		if(getContractBalance()<totalAmount){
			totalAmount = getContractBalance();
		}

		if(totalAmount>0){

			for (uint256 i = 0; i < user.deposits.length; i++) {
				if(user.deposits[i].terminate == true && user.deposits[i].plan == 0 ){
					user.deposits[i].terminate = false;
				}
			}


			uint256 comFund = totalAmount.mul(COMMUNITY_FUND).div(PERCENTS_DIVIDER);
			totalCommunityFund = totalCommunityFund.add(comFund);
			totalAmount = totalAmount.sub(comFund);

			user.checkpoint = block.timestamp;
			msg.sender.transfer(totalAmount);
			user.totalWithdraw = user.totalWithdraw.add(totalAmount);
			totalWithdraws = totalWithdraws.add(totalAmount);

			emit Withdrawn(msg.sender, totalAmount);
		}
	}

	function terminateDeposit(uint256 _index) public {
		User storage user = users[msg.sender];
		require(user.deposits[_index].terminate == true,"deposit withdrawn");
        require(user.deposits[_index].finish > block.timestamp, "should be active");
        uint256 totalAmount = user.deposits[_index].amount.div(2);
		uint256 insurance = 0;
		if(user.totalWithdraw < user.totalInvest.div(2)){
			insurance = (user.totalInvest.div(2)).sub(user.totalWithdraw);
			if(insurance > totalAmount)
			{
				insurance = totalAmount;
			}
			if(totalInsurance >= insurance)
			{
				totalInsurance = totalInsurance.sub(insurance);
			}
		}
		
		totalAmount = totalAmount.sub(insurance);
		uint256 contractBalance = getContractAvailableBalance();
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		totalAmount = totalAmount.add(insurance);

		if(getContractBalance()<totalAmount){
			totalAmount = getContractBalance();
		}


		if(totalAmount>0){
			address(uint160(msg.sender)).transfer(totalAmount);
			user.totalWithdraw = user.totalWithdraw.add(totalAmount);
			user.deposits[_index].profit = totalAmount;
			user.deposits[_index].finish = block.timestamp;
			user.deposits[_index].active = false;
			emit TerminateDeposit(msg.sender,totalAmount);
		}
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractAvailableBalance() public view returns (uint256) {
		if(block.timestamp > launchDate){
			if((block.timestamp.sub(launchDate)).div(TIME_STEP) > INSURANCE_DURATION){
				return getContractBalance();
			}
			else{
				if(totalInsurance < address(this).balance){
					return (address(this).balance).sub(totalInsurance);
				}
				else{
					return 0;
				}
			}
		}
		else{
			if(totalInsurance < address(this).balance){
				return (address(this).balance).sub(totalInsurance);
			}
			else{
				return 0;
			}
		}
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > launchDate && plan == 1) {
			uint256 calPercent = PERCENT_STEP.mul(block.timestamp.sub(launchDate)).div(TIME_STEP2);
			calPercent = calPercent.mod(MAX_INC_P1);
			return plans[plan].percent.add(calPercent);
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);

		if (plan == 0) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan == 1) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP2));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish && user.deposits[i].active == true ) {
				if (user.deposits[i].plan == 0) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP2));
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
				}
			}
		}

		return totalAmount;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256) {
		return users[userAddress].refCnt;
	}

	function getUserTotalStats(address userAddress) public view returns(uint256,uint256,uint256,uint256,uint256) {
		return (
			users[userAddress].totalInvest,
			users[userAddress].totalWithdraw,
			users[userAddress].totalBonus,
			users[userAddress].refCnt,
			users[userAddress].checkpoint
		);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, bool terminate, bool active) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
		terminate = user.deposits[index].terminate;
		active = user.deposits[index].active;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
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
	
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}