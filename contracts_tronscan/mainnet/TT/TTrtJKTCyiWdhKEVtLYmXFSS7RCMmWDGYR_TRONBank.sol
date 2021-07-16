//SourceUnit: trxbank.sol



pragma solidity 0.5.10;

contract TRONBank {
	using SafeMath for uint256;
	

	
	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	
	uint256 constant public BASE_PERCENT = 10;
	uint256[5] public REFERRAL_PERCENTS = [50, 20, 5, 5, 5];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	

	
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	

	
	uint256 constant public TIME_STEP = 1 days;
	

	
	uint256 constant public TEN_TIME_STEP = 10 days;
	
	
	
	uint256 constant internal FEE = 5 trx;
	

	
	uint256 constant public DAILY_INVEST_RESTRICTIONS = 1 days;


	address payable  public  RATE_ADDR = address(0x41002FD4EE57B40037EB37F5B9CBD6F36E19B7F04E);
	
	address payable internal NODE_ADDRESS_1ST = address(0x4128AAEC950B0085E7BB240954465D55DCEAA9C574);
	address payable internal NODE_ADDRESS_2ND = address(0x41820D4D8396B279FA98E003820229E44B542CBA3C);
	address payable internal NODE_ADDRESS_3RD = address(0x41B64660B96796FBF8D942AFA4335A042F5E972D5C);
	address payable internal NODE_ADDRESS_4TH = address(0x4171E7880D27B19A58E6CA6415F9BA9A99FD04290E);
	address payable internal NODE_ADDRESS_5TH = address(0x419D74D48107FC7094BEA8A08E527AF86CBB58A00E);
	
	uint256 constant internal QUOTA = 1000000 trx;



	uint256 constant internal LIFT_LIMIT_THRESHOLD = 30000000 trx;


	
	uint256[5] public VIP_LEVEL = [10000 trx, 50000 trx, 100000 trx, 2000000 trx, 500000 trx];
	
	uint256[5] public VIP_LEVEL_PERCENT = [5, 10, 15, 20, 25];

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	
	uint256 public startTime;
	
	address payable  public owner;

	address payable public defaultReferral;


	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}
	


	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 referCount;
		uint256 referAmout;
		uint256 directReferralReward;
		uint256 teamRevenueReward; 
		uint256 teamNumber; 
		uint256[30] performance;

	}

	mapping (address => User) public users;
	
	mapping (address => uint256) public userWithdraw;
	
	mapping (address => uint256) public vipWithdraw;
	
	mapping(uint256 => uint256) public levelSeniority;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor() public {
		
		defaultReferral = address(0x415BE89C4E6A60FD32FC611878C92CDB18250FC537);

		levelSeniority[0] = 0;
		levelSeniority[1] = 5;
		levelSeniority[2] = 8;
		levelSeniority[3] = 12;
		levelSeniority[4] = 20;
		levelSeniority[5] = 30;
		
		
		startTime = block.timestamp;		
		owner =  msg.sender;
		
	}

	function invest(address  referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		NODE_ADDRESS_1ST.transfer(msg.value.mul(5).div(100));
		NODE_ADDRESS_2ND.transfer(msg.value.mul(5).div(100));
		NODE_ADDRESS_3RD.transfer(msg.value.mul(5).div(100));
		NODE_ADDRESS_4TH.transfer(msg.value.mul(5).div(100));
		NODE_ADDRESS_5TH.transfer(msg.value.mul(8).div(100));

		

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}
		address _referrer = user.referrer;
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 30; i++) {			
				if (upline != address(0)) {
					if(i<5){
						uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
						users[upline].bonus = users[upline].bonus.add(amount);							
						emit RefBonus(upline, msg.sender, i, amount);
					}
					users[upline].teamNumber = users[upline].teamNumber.add(1);
					users[upline].performance[i] = users[upline].performance[i].add(msg.value);
					upline = users[upline].referrer;
				}else{
					break;
				} 								
			}
		}
		
		users[_referrer].directReferralReward = users[_referrer].directReferralReward.add(msg.value.mul(REFERRAL_PERCENTS[0]).div(PERCENTS_DIVIDER));
		
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			users[_referrer].referCount  = users[_referrer].referCount.add(1);
			emit Newbie(msg.sender);
		}
		
		users[_referrer].referAmout = users[_referrer].referAmout.add(msg.value);

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		
		RATE_ADDR.transfer(FEE);

		totalInvested = totalInvested.add(msg.value);
		

		uint256 day = block.timestamp.sub(startTime).div(DAILY_INVEST_RESTRICTIONS).add(1);

		if(totalInvested <= LIFT_LIMIT_THRESHOLD ){
			require(day.mul(day.add(1)).mul(QUOTA).div(2) >= totalInvested,"Investment daily limit");
		}
			
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}
		
		
		uint256 _totalDeposit = getUserTotalDeposits(msg.sender);
		
		

		uint256 referralBonus = getUserReferralBonus(msg.sender);

		uint256 totalAmountRefer = 0;
		
		if (referralBonus > 0) {
		
		if(referralBonus.add(userWithdraw[msg.sender]) >= _totalDeposit.mul(2)){
			referralBonus = _totalDeposit.mul(2).sub(userWithdraw[msg.sender]);
		}
			
		
		address  _referrer = users[msg.sender].referrer;
		
		uint256 senior = 0;
		uint256 _referAmount = 0;
		for(uint256 i = 0;i < 30;i++){
			if(_referrer != address(0)){
				senior = getSeniority(_referrer);
				uint256 _referDeposit = getUserTotalDeposits(_referrer);
				if(_referDeposit.mul(2) <= userWithdraw[_referrer]){
					break;
				}
				if(levelSeniority[senior] > i && senior > 0){
				    _referAmount = referralBonus.mul(VIP_LEVEL_PERCENT[senior.sub(1)]).div(100);
						
					users[_referrer].bonus = users[_referrer].bonus.add(_referAmount);
					//if(_referDeposit.mul(2) <= userWithdraw[_referrer].add(users[_referrer].bonus)){	
					//	users[_referrer].bonus = _referDeposit.mul(2).sub(userWithdraw[_referrer]);
					//	break;
					//}
					users[_referrer].teamRevenueReward = users[_referrer].teamRevenueReward.add(_referAmount);
					totalAmountRefer = totalAmountRefer.add(_referAmount);
				}
				_referrer = users[_referrer].referrer;			
			}else break;
		}
		
		
		
		
		
		
		
		
		
		
		
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}
		
		uint256 compoundInterest = block.timestamp.sub(user.checkpoint).div(TEN_TIME_STEP);	
		
	
		
		totalAmount  = totalAmount.add(totalAmount.mul(compoundInterest).mul(5).div(100));

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		
		
		if(_totalDeposit.mul(2).sub(userWithdraw[msg.sender]) <= totalAmount){
			totalAmount = _totalDeposit.mul(2).sub(userWithdraw[msg.sender]);
		}
		
		
	
		
		
		msg.sender.transfer(totalAmount.sub(FEE));
		RATE_ADDR.transfer(FEE);
		
		userWithdraw[msg.sender] = userWithdraw[msg.sender].add(totalAmount);


		uint256 _vip = getSeniority(msg.sender);
		if(_vip > 0){
			vipWithdraw[msg.sender] = vipWithdraw[msg.sender].add(totalAmount);
		}
		
		

		
		totalWithdrawn = totalWithdrawn.add(totalAmount.add(totalAmountRefer));
		
		emit Withdrawn(msg.sender, totalAmount);

	}

	
	function getSeniority(address user) public view returns(uint256) {
		uint256 utd = getUserTotalDeposits(user);
		uint256 vip = 0;
		for(uint256 i = 0;i<VIP_LEVEL.length;i++){			
			if(utd < VIP_LEVEL[i]){
				return i;
			}else{
				vip = i.add(1);
			}
		}
		return vip;
	}
	


	function getUserDeposits(address userAddress )public view returns (uint256) {
	
		User memory user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if(user.deposits[i].amount.mul(2) != user.deposits[i].withdrawn ){
				amount = amount.add(user.deposits[i].amount);
			}			
		}
		return amount;
	}
	

	
	function getPerformance(address userAddress) public view returns (uint256) {
		uint256[30] memory _performance =  users[userAddress].performance;
		uint256 amount = 0;
		for(uint256 i= 0; i< _performance.length;i++){
			amount = amount.add(_performance[i]);
		}
		return amount;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		uint256 result = 0;
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP).mul(5);
		result =  BASE_PERCENT.add(contractBalancePercent);
		if(result >= 180){
			result = 180;
		}		 
		return result;
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		uint256 contractBalanceRate = getContractBalanceRate();
		return contractBalanceRate;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}
		}
		

		return totalDividends;
	}
	

	function getCompoundInterest(address userAddress) public view returns(uint256){
		uint256 _amount = getUserAvailable(userAddress);
		uint256 _rate = block.timestamp.sub(users[userAddress].checkpoint).div(TEN_TIME_STEP);
		return _amount.mul(_rate).mul(5).div(100);				
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		uint256 result = getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
		uint256 totalDeposits = getUserTotalDeposits(userAddress);
		
		if(result.add(userWithdraw[userAddress]) >= totalDeposits.mul(2)){
			result = totalDeposits.mul(2).sub(userWithdraw[userAddress]);
		}		
		return result;
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
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
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}