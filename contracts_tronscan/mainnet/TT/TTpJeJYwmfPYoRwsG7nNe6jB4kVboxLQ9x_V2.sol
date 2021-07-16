//SourceUnit: V2.sol

pragma solidity 0.5.10;

contract V2 {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256 constant public INVEST_MAX_AMOUNT = 50000 trx;
	uint256 constant public WITHDRAW_MIN_AMOUNT = 100 trx;
	uint256 constant public WITHDRAW_MAX_AMOUNT = 10000 trx;
	uint256 constant public BASE_MULTIPLE = 2;
	uint256 constant public BASE_PERCENT = 150;
	uint256 constant public DIRECT_BONUS_PERCENT = 1000;
	uint256 constant public WITHDRAW_FEE_PERCENT = 1300;
	uint256 constant public FEE_INVEST_PERCENT = 800;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 constant public INVEST_FEE_PERCENT = 500;
	uint256 constant public WITHDRAW_SERVICE_FEE = 500;
	uint256 constant public REFERRAL_PERCENT = 500;

	uint256 public totalUser;
	uint256 public totalInvested;
	uint256 public totalWithdrawFee;
	uint256 public totalInvestFee;
	uint256 public totalWithdrawn;
	uint256[2] public directProfit = [200 trx, 800 trx];
	uint256 public initBonusAmount = 100 trx;
	uint256 public initBonusLeft = 1000;

	address payable feeInvestRec;
	address payable feeWithdrawRec;
	address payable devAddr;
	address owner;

	struct UserInfo {
		address referrer;
		uint256 totalDeposit;
		uint256 remainProfit;
		uint256 bonusProfit;
		uint256 bonusDirect;
		uint256 totalBonusDirect;
		uint256 totalProfitRefer;
		uint256 totalWithdrawn;
		uint256 lastWithdraw;
		uint256 directInviteCount;
		uint256 totalReferCount;
		uint256 investCount;
		uint256 totalDirectProfit;
	}

	mapping (address => UserInfo) internal userInfo;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Reinvest(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event InvestFeePayed(address indexed user, uint256 totalAmount);
	event WithdrawFeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable _feeInvestRec, address payable _feeWithdrawRec, address payable _devAddr) public {
		feeInvestRec = _feeInvestRec;
		feeWithdrawRec = _feeWithdrawRec;
		devAddr = _devAddr;
		owner = msg.sender;
	}

	function invest(address _referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT && msg.value <= INVEST_MAX_AMOUNT, "amount err");
		// fee: 5%
		uint256 investFee = msg.value.mul(INVEST_FEE_PERCENT).div(PERCENTS_DIVIDER);
		feeInvestRec.transfer(investFee);
		emit InvestFeePayed(msg.sender, investFee);

		UserInfo storage user = userInfo[msg.sender];
		if (user.referrer == address(0) && userInfo[_referrer].totalDeposit > 0 && _referrer != msg.sender && userInfo[_referrer].referrer != msg.sender) {
			user.referrer = _referrer;
			userInfo[_referrer].directInviteCount = userInfo[_referrer].directInviteCount.add(1);
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					userInfo[upline].totalReferCount = userInfo[upline].totalReferCount.add(1);
					upline = userInfo[upline].referrer;
				} else break;
			}

		}

		// bal reinvest
		uint256 reinvestAmount = getUserDividends(msg.sender);
		if(user.bonusDirect > 0){
			reinvestAmount = reinvestAmount.add(user.bonusDirect.mul(BASE_MULTIPLE));
			user.bonusDirect = 0;
		}

		if(reinvestAmount > 0){
			user.remainProfit = user.remainProfit.add(reinvestAmount);
			_teamBonus(msg.sender, reinvestAmount);
			emit Reinvest(msg.sender, reinvestAmount);
		}
		user.lastWithdraw = block.timestamp;

		if (user.totalDeposit == 0) {
			totalUser = totalUser.add(1);
			if(initBonusLeft > 0){
				user.remainProfit = user.remainProfit.add(initBonusAmount);
				initBonusLeft = initBonusLeft.sub(1);
			}
			emit Newbie(msg.sender);
		}

		user.totalDeposit = user.totalDeposit.add(msg.value);
		user.remainProfit = user.remainProfit.add(msg.value.mul(BASE_MULTIPLE));
		// invest times
		user.investCount = user.investCount.add(1);
		totalInvested = totalInvested.add(msg.value);
		// direct bonus 
		_directBonus(msg.sender, msg.value);

		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw(uint256 _reinvest) public {
		UserInfo storage user = userInfo[msg.sender];
		uint256 bonusAmount;
		uint256 dividendsAmount;
		uint256 withdrawableAmount;

		if (user.bonusDirect > 0) {
			bonusAmount = user.bonusDirect;
			user.bonusDirect = 0;
		}

		dividendsAmount = getUserDividends(msg.sender);
		uint256 totalAmount = bonusAmount.add(dividendsAmount);

		if(_reinvest >= totalAmount){
			_reinvest = totalAmount;
		}else{
			withdrawableAmount = totalAmount.sub(_reinvest);
			if(withdrawableAmount > WITHDRAW_MAX_AMOUNT.add(bonusAmount)){
				withdrawableAmount = WITHDRAW_MAX_AMOUNT.add(bonusAmount);
				dividendsAmount = WITHDRAW_MAX_AMOUNT.add(_reinvest);
			}else if(withdrawableAmount < WITHDRAW_MIN_AMOUNT){
				withdrawableAmount = 0;
				_reinvest = totalAmount;
			}
		}

		user.remainProfit = user.remainProfit.add(_reinvest.mul(BASE_MULTIPLE)).sub(dividendsAmount);
		_teamBonus(msg.sender, _reinvest);
		emit Reinvest(msg.sender, _reinvest);

		if(withdrawableAmount > 0){
			require(user.lastWithdraw.add(TIME_STEP) < block.timestamp, "time too early");
			// sub fee
			uint256 withdrawFee = withdrawableAmount.mul(WITHDRAW_FEE_PERCENT).div(PERCENTS_DIVIDER);
			totalWithdrawFee = totalWithdrawFee.add(withdrawFee);
			uint256 feeInvest =  withdrawableAmount.mul(FEE_INVEST_PERCENT).div(PERCENTS_DIVIDER);
			totalInvestFee = totalInvestFee.add(feeInvest);
			// service fee
			uint256 serviceFee = withdrawableAmount.mul(WITHDRAW_SERVICE_FEE).div(PERCENTS_DIVIDER);
			feeWithdrawRec.transfer(serviceFee);
			emit WithdrawFeePayed(msg.sender, serviceFee);

			withdrawableAmount = withdrawableAmount.sub(withdrawFee);
			uint256 contractBalance = address(this).balance;
			if (contractBalance < withdrawableAmount) {
				withdrawableAmount = contractBalance;
			}
			msg.sender.transfer(withdrawableAmount);
			totalWithdrawn = totalWithdrawn.add(withdrawableAmount);
			user.totalWithdrawn = user.totalWithdrawn.add(withdrawableAmount);
			emit Withdrawn(msg.sender, withdrawableAmount);
		}

		user.lastWithdraw = block.timestamp;
	}

	function _directBonus(address _userAddr, uint256 _investAmount) internal {
		UserInfo storage user = userInfo[_userAddr];
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			uint256 bonusAmount = _investAmount.mul(DIRECT_BONUS_PERCENT).div(PERCENTS_DIVIDER);
			userInfo[upline].bonusDirect = userInfo[upline].bonusDirect.add(bonusAmount);
			userInfo[upline].totalBonusDirect = userInfo[upline].totalBonusDirect.add(bonusAmount);

			if(userInfo[upline].directInviteCount == 8 && userInfo[upline].totalDirectProfit == 0){
				userInfo[upline].remainProfit = userInfo[upline].remainProfit.add(directProfit[0]);
				userInfo[upline].bonusProfit = userInfo[upline].bonusProfit.add(directProfit[0]);
				userInfo[upline].totalDirectProfit = userInfo[upline].totalDirectProfit.add(directProfit[0]);
			}

			if(userInfo[upline].directInviteCount == 20  && userInfo[upline].totalDirectProfit == directProfit[0]){
				userInfo[upline].remainProfit = userInfo[upline].remainProfit.add(directProfit[1]);
				userInfo[upline].bonusProfit = userInfo[upline].bonusProfit.add(directProfit[1]);
				userInfo[upline].totalDirectProfit = userInfo[upline].totalDirectProfit.add(directProfit[1]);
			}
		}
	} 

	function _teamBonus(address _userAddr, uint256 _investAmount) internal {
		UserInfo storage user = userInfo[_userAddr];
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			// invest multiple amount
			uint256 bonus = _investAmount.mul(REFERRAL_PERCENT).div(PERCENTS_DIVIDER);
			UserInfo storage dev = userInfo[devAddr];
			dev.bonusDirect = dev.bonusDirect.add(bonus);
			
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					userInfo[upline].remainProfit = userInfo[upline].remainProfit.add(bonus);
					userInfo[upline].bonusProfit = userInfo[upline].bonusProfit.add(bonus);
					userInfo[upline].totalProfitRefer = userInfo[upline].totalProfitRefer.add(bonus);
					emit RefBonus(upline, _userAddr, i, bonus);
					upline = userInfo[upline].referrer;
				} else break;
			}
		}
	}

	function set(address payable _feeInvestRec, address payable _feeWithdrawRec, address payable _devAddr) public {
		require(msg.sender == owner, "permission denied");
		feeInvestRec = _feeInvestRec;
		feeWithdrawRec = _feeWithdrawRec;
		devAddr = _devAddr;
	}

	function transferOwnership(address _owner) public {
		require(msg.sender == owner, "permission denied");
		owner = _owner;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		UserInfo storage user = userInfo[userAddress];
		uint256 dayPassed = block.timestamp.sub(user.lastWithdraw).div(TIME_STEP);
		uint256 withdrawAmount = user.remainProfit.mul(dayPassed).mul(BASE_PERCENT).div(PERCENTS_DIVIDER);
		if(user.remainProfit <= withdrawAmount){
			withdrawAmount = user.remainProfit;
		}
		return withdrawAmount;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return userInfo[userAddress].bonusDirect.add(getUserDividends(userAddress));
	}

	function getContractInfo() public view returns(uint256[7] memory) {
		uint256[7] memory contractInfo;
		contractInfo[0] = address(this).balance;
		contractInfo[1] = totalUser;
		contractInfo[2] = totalInvested;
		contractInfo[3] = totalWithdrawFee;
		contractInfo[4] = totalInvestFee;
		contractInfo[5] = totalWithdrawn;
		contractInfo[6] = initBonusLeft;
		return contractInfo;
	}

	function getUserInfo(address userAddress) public view returns(address, uint256[11] memory) {
		UserInfo storage user = userInfo[userAddress];
		uint256[11] memory userInfoArr;
		userInfoArr[0] = user.totalDeposit;
		userInfoArr[1] = user.remainProfit;
		userInfoArr[2] = user.bonusProfit;
		userInfoArr[3] = user.bonusDirect;
		userInfoArr[4] = user.totalBonusDirect;
		userInfoArr[5] = user.totalProfitRefer;
		userInfoArr[6] = user.totalWithdrawn;
		userInfoArr[7] = user.lastWithdraw;
		userInfoArr[8] = user.directInviteCount;
		userInfoArr[9] = user.totalReferCount;
		userInfoArr[10] = user.investCount;
		return (user.referrer, userInfoArr);
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