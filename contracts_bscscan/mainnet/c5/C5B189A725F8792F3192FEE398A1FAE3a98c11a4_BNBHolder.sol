/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


interface RecommendPool {

    function allotBonus(address[3] calldata ranking, uint256 timePointer) external  returns (uint256);

    function withdraw(address payable ref,uint256 amount) external returns (uint256);

    function prizes(address contractAddress,address userAddress) external view returns(uint256);

    function availableBalance(address userAddress) external view returns(uint256);
}

library TransferHelper {

    function safeTransferBnb(address to, uint256 value) internal {
       (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper::safeTransferBnb: Bnb transfer failed');
    }

}


contract BNBHolder {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;
	uint256 constant public INVEST_MAX_AMOUNT = 100 ether;
	uint256 constant public REINVEST_MIN_AMOUNT = 0.01 ether;
	uint256[] public REFERRAL_PERCENTS = [50, 20, 10];
	uint256 constant public PROJECT_FEE = 80;
	uint256 constant public DEV_FEE = 20;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalStaked;
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
		uint256 withdrawn;
		uint256 checkpoint;
		uint256 available;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
	}

	mapping (address => User) public users;

	mapping(uint256 => mapping(address => uint256)) public performances;
    mapping(uint256 => address[3]) public performanceRank;

    mapping(address => uint256) public playerWithdrawAmount;

	uint256 public startUNIX;
	address payable public commissionWallet;
	address payable public devAddress;
	address payable public referr =  address(0x46ccE7dFa2100c3Dad828392036Ab3DCf8009d98);

	uint256 public timePointer;

	RecommendPool public recommendPool;

	uint256[3] public rankPercent = [75,45,30];

	// Hold bonus percent 0.02%
	uint256 public HOLD_BONUS_PERCENT = 2;
	uint256 public HOLD_BONUS_DIVIDER = 1000;
	uint256 public HOLD_BONUS_MAX_DAYS = 5;
	//

    // Pre Withdraw
    uint256 public PRE_WITHDRAW_COMMISSION = 20;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Reinvest(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event PreWithdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
    event Performances(uint256 indexed duration_,address referral_,uint256 amount_);



	constructor( address payable _recommendPoolAddress, uint256 startTime) public {

	    startUNIX = startTime;

		commissionWallet = address(0x46ccE7dFa2100c3Dad828392036Ab3DCf8009d98);
		devAddress = address(0x313D4EcE1e498DA7fF67cb4Ef272ce04110db5D0);


        plans.push(Plan(10, 120));
        plans.push(Plan(13, 107));
        plans.push(Plan(16, 113));
        plans.push(Plan(10, 195));
        plans.push(Plan(13, 210));
        plans.push(Plan(16, 185));

        recommendPool = RecommendPool(_recommendPoolAddress);

        // set default referr
    	User storage user = users[referr];
        (uint256 percent, uint256 profit, uint256 finish) = getResult(0, INVEST_MIN_AMOUNT);
        user.deposits.push(Deposit(0, percent, INVEST_MIN_AMOUNT, profit, block.timestamp, finish, 0, block.timestamp, 0));

	}

	modifier settleBonus(){
        settlePerformance();
        _;
    }


    function globalRankStatus() public view returns( bool){

        return timePointer<duration();
    }

    function settlePerformance() public {

        if(timePointer<duration()){
            address[3] memory rankingList = sortRanking(timePointer);
            recommendPool.allotBonus(rankingList,timePointer);
            timePointer = duration();
        }
    }




	function invest(address referrer, uint8 plan) public settleBonus payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
		require(msg.value <= INVEST_MAX_AMOUNT);
        require(plan < 6, "Invalid plan");
        require(block.timestamp >= startUNIX);

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 feeD_ = msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		devAddress.transfer(feeD_);
		emit FeePayed(msg.sender, fee);

		TransferHelper.safeTransferBnb(address(recommendPool),msg.value.mul(2).div(100));


		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {

			if(getUserTotalDeposits(referrer) >= INVEST_MIN_AMOUNT){
				if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
					user.referrer = referrer;
				}

				address upline = user.referrer;
				for (uint256 i = 0; i < 3; i++) {
					if (upline != address(0)) {
						users[upline].levels[i] = users[upline].levels[i].add(1);
						upline = users[upline].referrer;
					} else break;
				}



			}


		}

		if (user.referrer != address(0)) {

			_statistics(user.referrer,msg.value);

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish, 0, block.timestamp, 0));

		_updateRanking(user.referrer);

		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}

	function _statistics(address ref,uint256 amount) private{
        if(ref!=address(0)){

          //---------mainet-------------
            if(duration() > 6){
             //---------mainet-------------
                performances[duration()][ref] = performances[duration()][ref].add(amount);
                emit Performances(duration(),ref,amount);
             //---------mainet-------------
            }
             //---------mainet-------------

        }

    }

	function shootOut(address[3] memory rankingList,address userAddress) public view returns (uint256 sn,uint256 minPerformance){

        minPerformance = performances[duration()][rankingList[0]];
        for(uint8 i =0;i<3;i++){
            if(rankingList[i]==userAddress){
                return (3,0);
            }
            if(performances[duration()][rankingList[i]]<minPerformance){
                minPerformance = performances[duration()][rankingList[i]];
                sn = i;
            }
        }

        return (sn,minPerformance);
    }

    function _updateRanking(address userAddress) private {
        address[3] memory rankingList = performanceRank[duration()];


        (uint256 sn,uint256 minPerformance) = shootOut(rankingList,userAddress);
        if(sn!=3){
            if(minPerformance<performances[duration()][userAddress]){
                rankingList[sn] = userAddress;
            }
            performanceRank[duration()] = rankingList;
        }
    }



    function sortRanking(uint256 _duration) public view returns(address[3] memory ranking){
        ranking = performanceRank[_duration];

        address tmp;
        for(uint8 i = 1;i<3;i++){
            for(uint8 j = 0;j<3-i;j++){
                if(performances[_duration][ranking[j]]<performances[_duration][ranking[j+1]]){
                    tmp = ranking[j];
                    ranking[j] = ranking[j+1];
                    ranking[j+1] = tmp;
                }
            }
        }
        return ranking;
    }

    function userRanking(uint256 _duration) external view returns(address[3] memory addressList,uint256[3] memory performanceList,uint256[3] memory preEarn){

        addressList = sortRanking(_duration);
        uint256 credit = recommendPool.availableBalance(address(this));
        for(uint8 i = 0;i<3;i++){
            preEarn[i] = credit.mul(rankPercent[i]).div(1000);
            performanceList[i] = performances[_duration][addressList[i]];
        }

    }

    function getDaysInHold(uint256 lastWithdraw) public view returns (uint256) {
        uint256 time = (block.timestamp.sub(lastWithdraw)).div(TIME_STEP);

        if (time > HOLD_BONUS_MAX_DAYS)
            time = HOLD_BONUS_MAX_DAYS;

        return time;
    }

    function getUserHoldBonus(uint256 lastWithdraw, uint256 amount) public view returns (uint256 bonus) {
        uint256 time = getDaysInHold(lastWithdraw);
        return amount.mul(HOLD_BONUS_PERCENT).div(HOLD_BONUS_DIVIDER).mul(time);
    }

    function getUserDepositDividents(address userAddress, uint256 deposit) private view returns (uint256 profit) {
        User storage user = users[userAddress];

        require(deposit <= user.deposits.length);

        uint256 profitAmount = 0;

		if (user.deposits[deposit].checkpoint < user.deposits[deposit].finish) {
			if (user.deposits[deposit].plan < 3) {
				uint256 share = user.deposits[deposit].amount.mul(user.deposits[deposit].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[deposit].start > user.deposits[deposit].checkpoint ? user.deposits[deposit].start : user.deposits[deposit].checkpoint;
				uint256 to = user.deposits[deposit].finish < block.timestamp ? user.deposits[deposit].finish : block.timestamp;
				if (from < to) {
				    uint256 sum = share.mul(to.sub(from)).div(TIME_STEP);
					profitAmount = profitAmount.add(sum);
					profitAmount = profitAmount.add(getUserHoldBonus(user.deposits[deposit].checkpoint, user.deposits[deposit].amount));
				}
			} else if (block.timestamp > user.deposits[deposit].finish) {
			    // withdrawn > 0 == deposit pre withdrawed
			    if (user.deposits[deposit].withdrawn > 0) {
			        profitAmount = 0;
			    } else {
			        profitAmount = profitAmount.add(user.deposits[deposit].profit);
			    }
			}
		}

		return profitAmount;
    }

    function withdrawReferral() public {
        User storage user = users[msg.sender];

        uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
		}

		require(referralBonus > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < referralBonus) {
			referralBonus = contractBalance;
		}

		msg.sender.transfer(referralBonus);

		emit Withdrawn(msg.sender, referralBonus);
    }

	function withdraw(uint256 deposit) public {
		User storage user = users[msg.sender];

		require(deposit <= user.deposits.length);

		uint256 totalAmount = getUserDepositDividents(msg.sender, deposit);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.deposits[deposit].checkpoint = block.timestamp;
		user.deposits[deposit].withdrawn = user.deposits[deposit].withdrawn.add(totalAmount);

		msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function preWithdraw(uint256 deposit) public {
	    User storage user = users[msg.sender];
	    uint256 totalAmount = 0;

	    require(block.timestamp < user.deposits[deposit].finish);
	    require(user.deposits[deposit].withdrawn < user.deposits[deposit].amount);

		totalAmount = totalAmount.add(user.deposits[deposit].amount.mul(100 - PRE_WITHDRAW_COMMISSION).div(100));
		totalAmount = totalAmount.sub(user.deposits[deposit].withdrawn);
		user.deposits[deposit].finish = block.timestamp;
		user.deposits[deposit].available = 0;
		user.deposits[deposit].withdrawn = user.deposits[deposit].profit;
		msg.sender.transfer(totalAmount);

		emit PreWithdrawn(msg.sender, totalAmount);

	}

	function reinvest(uint8 plan, uint256 deposit) public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDepositDividents(msg.sender, deposit);

		require(totalAmount >= REINVEST_MIN_AMOUNT);
        require(plan < 6, "Invalid plan");

        uint256 fee = totalAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 feeD_ = totalAmount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		devAddress.transfer(feeD_);

		// +2% for reinvest
		totalAmount = totalAmount.add(totalAmount.mul(2).div(100));

		user.deposits[deposit].available = 0;
		user.deposits[deposit].withdrawn = user.deposits[deposit].withdrawn.add(totalAmount);

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, totalAmount);
		user.deposits.push(Deposit(plan, percent, totalAmount, profit, block.timestamp, finish, 0, block.timestamp, 0));

		totalStaked = totalStaked.add(totalAmount);
		emit Reinvest(msg.sender, plan, percent, totalAmount, profit, block.timestamp, finish);

	}

	function withdrawRecommend() external settleBonus returns(uint256){

        uint256 recommend = recommendPool.prizes(address(this),msg.sender);

        recommendPool.withdraw(msg.sender,recommend);

        return recommend;
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);
		profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 3) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.deposits[i].checkpoint ? user.deposits[i].start : user.deposits[i].checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
					    uint256 sum = share.mul(to.sub(from)).div(TIME_STEP);
						totalAmount = totalAmount.add(sum);
						totalAmount = totalAmount.add(getUserHoldBonus(user.deposits[i].checkpoint, user.deposits[i].amount));
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
				}
			}
		}

		return totalAmount;
	}

	function duration() public view returns(uint256){
        return duration(startUNIX);
    }

    function duration(uint256 startTime) public view returns(uint256){
        if(now<startTime){
            return 0;
        }else{

            //---------mainet-------------
            return now.sub(startTime).div(1 days);
            //---------mainet-------------

            //------------test--------------------
           // return now.sub(startTime).div(10 minutes);
            //------------test--------------------

        }
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

	function getUserDepositInfo(address userAddress, uint256 index) public view
	returns(
	        uint8 plan,
	        uint256 percent,
	        uint256 amount,
	        uint256 profit,
	        uint256 start,
	        uint256 finish,
	        uint256 withdrawn,
	        uint256 checkpoint,
	        uint256 available,
	        uint256 holdDays
	        ) {
	    User storage user = users[userAddress];
		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
		withdrawn = user.deposits[index].withdrawn;
		checkpoint = user.deposits[index].checkpoint;
		available = getUserDepositDividents(userAddress, index);
		holdDays = getDaysInHold(checkpoint);
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
}