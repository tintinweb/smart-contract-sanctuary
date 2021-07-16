//SourceUnit: trxfox.sol

/*
 +-+-+-+-+-+-+
 |T|R|X|F|O|X|
 +-+-+-+-+-+-+
*/

pragma solidity ^0.5.4;

contract TrxFox {
    uint256 constant public MAX_DAILY_WITHDRAW = 5e4 trx;//TODO: uncomment
	uint256 constant public INVEST_MIN_AMOUNT = 50 trx;
	uint256 constant public FIX_PERCENT = 100;
	uint256 constant public DAILY_HOLD_PERCENT = 5;//TODO: uncomment
	uint256 constant public DAILY_HOLD_LIMIT = 500;
	uint16[] public REFERRAL_PERCENTS = [700, 300, 300, 100, 50, 50, 50, 50, 50, 50, 50, 50,25,25,25,25,25,25,25,25];
	uint256 constant public MARKETING_FEE = 250;
	uint256 constant public SUPPORTING_FEE = 250;
	uint256 constant public GLOBAL_PROMOTIONS = 300;
	uint256 constant public LEADERS_SHARE = 200;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1e6 trx;//TODO: uncomment
	uint256 constant public CONTRACT_BALANCE_PERCENT = 10;
	uint256 constant public CONTRACT_BONUS_LIMIT = 700;
	uint256 constant public TIME_STEP = 1 days;//TODO: uncomment
	uint256 constant public REFERRAL_BONUS_DAILY_PERCENT = 200;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public supportAddress;
	address payable public defaultReferrer;
	address payable public globalPromotions;
	address payable public leadersShare;
	
	using SafeMath for uint32;
	using SafeMath for uint256;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 lastWithdraw;
	}

	struct User {
		Deposit[] deposits;
		address referrer;
		uint referralBonus;
		uint passiveBonus;
		uint lastBonusWithdrawal;
		uint32[20] bonusLevels;
		uint lastWithdrawTime;
		uint withdrawnWithinADay;
		uint totalInvested;
		uint totalWithdrawn;
	}

	mapping (address => User) internal users;

	event NewUser(address indexed user);
	event NewDeposit(address indexed user, uint256 amount);
	event eWithdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(address payable marketingAddr, 
	    address payable supportAddr, 
	    address payable _globalPromotions, 
	    address payable _leadersShare, 
	    address payable defReferrer) public {
    		require(!isContract(marketingAddr) && 
    		!isContract(supportAddr)&& 
    		!isContract(defReferrer) &&
    		!isContract(_globalPromotions) &&
    		!isContract(_leadersShare));
    		marketingAddress = marketingAddr;
    		supportAddress = supportAddr;
    		defaultReferrer = defReferrer;
    		globalPromotions = _globalPromotions;
    		leadersShare = _leadersShare;
	}
	
	function payUplines(address _referer, uint256 _amount) private {
        address upline = users[_referer].referrer;
        if(upline != address(0) && users[upline].lastBonusWithdrawal == 0){
		    users[upline].lastBonusWithdrawal = block.timestamp;
		}
		for (uint i = 1; i < REFERRAL_PERCENTS.length; i++) {
			if (upline != address(0)) {
				uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER).div(2);
				users[upline].passiveBonus = users[upline].passiveBonus.add(amount);
				emit RefBonus(upline, msg.sender, i, amount);
				upline = users[upline].referrer;
			} else break;
		}
    }
    
    function updateUplines(address _user) private {
        address upline = users[_user].referrer;
		for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
			if (upline != address(0)) {
				users[upline].bonusLevels[i] = uint32(users[upline].bonusLevels[i].add(1));
				upline = users[upline].referrer;
			} else break;
		}
    }

	function invest(address referrer) external payable {
	    require(!isContract(msg.sender) && msg.sender == tx.origin);
		require(msg.value >= INVEST_MIN_AMOUNT,"Min invest limit");
		
		User storage user = users[msg.sender];
		if(user.deposits.length > 0){
		    require( msg.value > user.deposits[user.deposits.length-1].amount,"Last invest limit");
		}

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		supportAddress.transfer(msg.value.mul(SUPPORTING_FEE).div(PERCENTS_DIVIDER));
		globalPromotions.transfer(msg.value.mul(GLOBAL_PROMOTIONS).div(PERCENTS_DIVIDER));
		leadersShare.transfer(msg.value.mul(LEADERS_SHARE).div(PERCENTS_DIVIDER));
		
		if(msg.sender != defaultReferrer){
		    if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
    			user.referrer = referrer;
    		}else if(user.referrer == address(0)){
    		    user.referrer = defaultReferrer;
    		}
		}

        uint256 amount = msg.value.mul(REFERRAL_PERCENTS[0]).div(PERCENTS_DIVIDER);
		
		if(user.referrer != address(0)){
		    users[user.referrer].referralBonus = users[user.referrer].referralBonus.add(amount);
    		emit RefBonus(user.referrer, msg.sender, 0, amount);
		}

		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
			updateUplines(msg.sender);
			emit NewUser(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
        user.totalInvested = user.totalInvested.add(msg.value);
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

	}

	function withdrawDividends() external {
	    
	    User storage user = users[msg.sender];
	    uint maxWithdrawCap = user.totalInvested.mul(2).sub(user.totalWithdrawn);
	    uint dailyWithdrawCap = getDailyCap(msg.sender);
	    uint256 contractBalance = address(this).balance;
	    
	    require(maxWithdrawCap > 0 && dailyWithdrawCap > 0 && contractBalance > 0, "Unable to withdraw");
	    
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

            Deposit storage dep = user.deposits[i];
            uint256 depWithdrawCap = dep.amount.mul(2).sub(dep.withdrawn);
            
			if (depWithdrawCap > 0) {
			    
                uint dailyHoldPercent = (now.sub(dep.lastWithdraw)).mul(DAILY_HOLD_PERCENT).div(TIME_STEP);
                dailyHoldPercent = dailyHoldPercent > DAILY_HOLD_LIMIT ? DAILY_HOLD_LIMIT : dailyHoldPercent;
                uint totalBonusPercent = dailyHoldPercent.add(getContractBalanceRate());
                
                uint dividend = dep.amount
                    .mul(totalBonusPercent)
                    .mul(block.timestamp.sub(dep.lastWithdraw))
                    .div(TIME_STEP)
                    .div(PERCENTS_DIVIDER);
                    
				if(dividend > depWithdrawCap) dividend = depWithdrawCap;
				
				if(dividend > maxWithdrawCap) {
				    dividend = maxWithdrawCap;
				}
				
				if(dividend > dailyWithdrawCap){
				    dividend = dailyWithdrawCap;
				}
				
				if(dividend > contractBalance) dividend = contractBalance;
				
				dep.withdrawn = user.deposits[i].withdrawn.add(dividend);
				dep.lastWithdraw = block.timestamp;
				dividends = dividends.add(dividend);
				
				maxWithdrawCap = maxWithdrawCap.sub(dividend);
				dailyWithdrawCap = dailyWithdrawCap.sub(dividend);
				contractBalance = contractBalance.sub(dividend);
				
				if(maxWithdrawCap == 0 || dailyWithdrawCap == 0 || contractBalance == 0) break;
			}
		}

		require(dividends > 0, "No dividends");
		
		user.totalWithdrawn = user.totalWithdrawn.add(dividends);
		
		if(now.sub(user.lastWithdrawTime) > TIME_STEP){
		    user.lastWithdrawTime = block.timestamp;
		    user.withdrawnWithinADay = 0;
		}
		user.withdrawnWithinADay = user.withdrawnWithinADay.add(dividends);
		
		totalWithdrawn = totalWithdrawn.add(dividends);
		
		if(msg.sender != defaultReferrer){
		    payUplines(user.referrer,dividends);
		}

		msg.sender.transfer(dividends);

		emit eWithdrawn(msg.sender, dividends);

	}
	
	function withdrawBonus() external {
	    
	    User storage user = users[msg.sender];
	    
	    uint toBeWithdrawn = getUserWithdrawableBonus(msg.sender);
	    
	    require(toBeWithdrawn > 0, "No bonus");
	    
	    if(toBeWithdrawn>=user.referralBonus){
	        if(toBeWithdrawn.sub(user.referralBonus)>0){
	            user.passiveBonus = user.passiveBonus.sub(toBeWithdrawn.sub(user.referralBonus));
	            user.lastBonusWithdrawal = block.timestamp;
	        }
	        user.referralBonus = 0;
	    }
	    else{
	        user.referralBonus = user.referralBonus.sub(toBeWithdrawn);
	    }
        
	    if(now.sub(user.lastWithdrawTime) > TIME_STEP){
		    user.lastWithdrawTime = block.timestamp;
		    user.withdrawnWithinADay=0;
		}
	    user.withdrawnWithinADay = user.withdrawnWithinADay.add(toBeWithdrawn);
	    
        user.totalWithdrawn = user.totalWithdrawn.add(toBeWithdrawn);
        totalWithdrawn = totalWithdrawn.add(toBeWithdrawn);
        
		msg.sender.transfer(toBeWithdrawn);

		emit eWithdrawn(msg.sender, toBeWithdrawn);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.mul(CONTRACT_BALANCE_PERCENT).div(CONTRACT_BALANCE_STEP);
		return FIX_PERCENT.add(contractBalancePercent > CONTRACT_BONUS_LIMIT ? CONTRACT_BONUS_LIMIT : contractBalancePercent);
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
	    
		User storage user = users[userAddress];

		uint256 dividends;
		uint256 contractRatePercent = getContractBalanceRate();

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    Deposit storage dep = user.deposits[i];
            if(dep.withdrawn < dep.amount.mul(2)){
                
                uint dailyHoldPercent = (now.sub(dep.lastWithdraw)).mul(DAILY_HOLD_PERCENT).div(TIME_STEP);
                dailyHoldPercent = dailyHoldPercent > DAILY_HOLD_LIMIT ? DAILY_HOLD_LIMIT : dailyHoldPercent;
                uint totalBonusPercent = dailyHoldPercent.add(contractRatePercent);
                
                uint dividend = dep.amount.mul(totalBonusPercent)
                    .mul(block.timestamp.sub(dep.lastWithdraw)).div(TIME_STEP)
                    .div(PERCENTS_DIVIDER);
                    
                if(dividend.add(dep.withdrawn) > dep.amount.mul(2)){
                    dividend = dep.amount.mul(2).sub(dep.withdrawn);
                }
                dividends = dividends.add(dividend);
            }
		}

		return dividends;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	
	function getUserWithdrawableBonus(address _userAddress) public view returns(uint256){
	    
	    User storage user = users[_userAddress];
	    uint maxWithdrawCap = user.totalInvested.mul(2).sub(user.totalWithdrawn);
	    uint dailyWithdrawCap = getDailyCap(_userAddress);
	    
	    if(maxWithdrawCap == 0 || dailyWithdrawCap == 0 || address(this).balance == 0){
	        return 0;
	    }
	    
	    uint toBeWithdrawn = users[_userAddress].passiveBonus
	        .mul(REFERRAL_BONUS_DAILY_PERCENT.add(getContractBalanceRate()))
	        .mul(block.timestamp.sub(users[_userAddress].lastBonusWithdrawal))
	        .div(TIME_STEP)
	        .div(PERCENTS_DIVIDER);
	        
	    toBeWithdrawn =  toBeWithdrawn > users[_userAddress].passiveBonus ? users[_userAddress].passiveBonus : toBeWithdrawn;
	    toBeWithdrawn = toBeWithdrawn.add(user.referralBonus);
	    
	    if(toBeWithdrawn > dailyWithdrawCap){
	        toBeWithdrawn = dailyWithdrawCap;
	    }
	    
	    if(toBeWithdrawn > maxWithdrawCap){
	        toBeWithdrawn = maxWithdrawCap;
	    }
	    
	    if(toBeWithdrawn > address(this).balance){
	        toBeWithdrawn = address(this).balance;
	    }
	   
	    return toBeWithdrawn;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].lastWithdraw);
	}

    function getStatsView() public view returns
        (uint256 statsTotalInvested, 
        uint256 statsTotalWithdrawn, 
        uint256 statsTotalDeposits, 
        uint256 statsContractBalance, 
        uint256 statsUserTotalDeposits, 
        uint256 statsUserTotalInvested,
        uint256 statsUserTotalWithdrawn,
        uint256 statsUserRefBonus,
        uint256 statsUserDividends,
        uint256 statsUserLastInvestment,
        uint32[20] memory statsUserBonusLevels,
        uint256 statsLastWithdrawTime,
        uint256 statsWithdrawnWithinADay)
    {
            return 
                (totalInvested,
                totalWithdrawn,
                totalDeposits, 
                getContractBalance(),
                getUserAmountOfDeposits(msg.sender),
                users[msg.sender].totalInvested,
                users[msg.sender].totalWithdrawn,
                getUserWithdrawableBonus(msg.sender),
                getUserDividends(msg.sender),
                users[msg.sender].deposits.length > 0 ? users[msg.sender].deposits[users[msg.sender].deposits.length - 1].amount : 0,
                users[msg.sender].bonusLevels,
                users[msg.sender].lastWithdrawTime,
                users[msg.sender].withdrawnWithinADay);
    }
    
    function getDailyCap(address userAddress) public view returns(uint) {
        User storage user = users[userAddress];
		if(now.sub(user.lastWithdrawTime) > TIME_STEP){
		    return MAX_DAILY_WITHDRAW;
		}else{
		    return MAX_DAILY_WITHDRAW.sub(user.withdrawnWithinADay);
		}
	}
    
	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
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
        require(c >= a, "addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "division by zero");
        uint256 c = a / b;

        return c;
    }
}