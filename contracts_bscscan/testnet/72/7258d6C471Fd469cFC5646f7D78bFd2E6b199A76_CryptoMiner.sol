/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity ^0.5.4;

contract CryptoMiner {
    using SafeMath for uint64;
	using SafeMath for uint256;
	
	uint256 constant public FIX_PERCENT = 30;
    uint256 constant public MAX_DAILY_WITHDRAWAL = 10 ether;
    uint256 constant public MAX_DAILY_Ref_WITHDRAWAL = 4 ether;
	uint256 constant public INVEST_MIN_AMOUNT = 0.025 ether;
	uint256[5] public REFERRAL_PERCENTS = [80, 40, 10, 10, 20];
	uint256[5] public REINVEST_REFERRAL_PERCENTS = [8, 4, 1, 1, 2];
	uint256 constant public MARKETING_FEE = 20;
	uint256 constant public SUPPORTING_FEE = 240; //For external cashflow funding for mining, crypto & forex trading, project research & devt for expansion and sustainability
	uint256 constant public ADMIN_FEE = 30;
	uint256 constant public DEV_FEE = 50;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public LAUNCH_TIME;

	uint256 public totalUsers;
	uint256 public totalInvested;

	address payable public marketingAddress;
	address payable public supportAddress;
	address payable public adminAddress;
	address payable public devAddress;
	


	struct Deposit {
		uint64 amount;
		uint64 withdrawn;
		uint32 checkpoint;
		uint64 reInvested;
	}

	struct User {
		Deposit[] deposits;
		uint64 totalInvested;
		uint64 totalWithdrawn;
		uint64 totalRefBonus;
		address referrer;
		uint64 bonus;
		uint64 lastWithdrawn;
		uint32 checkpoint;
		uint64[5] refCounts;
	}

	mapping (address => User) internal users;

	event NewUser(address user);
	event NewDeposit(address indexed user, uint256 amount, uint256 withDonation);
	event SystemReinvest(address user, uint256 amount);
	event Withdrawn(address indexed user, uint256 dividends, uint256 amount, uint256 reInvested);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	
	modifier beforeStarted() {
        require(block.timestamp >= LAUNCH_TIME, "!beforeStarted");
        _;
    }

	constructor(address payable marketingAddr, address payable supportAddr, address payable adminAddr, address payable devAddr) public {
	    require(!isContract(marketingAddr) && 
    		!isContract(supportAddr)&&
    		!isContract(adminAddr) &&
    		!isContract(devAddr));
		marketingAddress = marketingAddr;
		supportAddress = supportAddr;
		adminAddress = adminAddr;
		devAddress = devAddr;
		LAUNCH_TIME = 1634119200;
	}
	
	function payUplines(uint _amount) private {
        address upline = users[msg.sender].referrer;
		for (uint i = 0; i < 5; i++) {
			if (upline != address(0)) {
				uint amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
				upline = users[upline].referrer;
			} else break;
		}
    }
    
	function payUplinesReInvest(uint _amount) private {
        address upline = users[msg.sender].referrer;
    	for (uint i = 0; i < 5; i++) {
    		if (upline != address(0)) {
    			uint amount = _amount.mul(REINVEST_REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
    			users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
    			upline = users[upline].referrer;
    		} else break;
    	}
    }
    
    function countUplines() private {
        address upline = users[msg.sender].referrer;
		for (uint i = 0; i < 5; i++) {
			if (upline != address(0)) {
				users[upline].refCounts[i] = uint64(uint(users[upline].refCounts[i]).add(1));
				upline = users[upline].referrer;
			} else break;
		}
    }
    function transferFee(uint _amount) private{
        uint fee = _amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) adminAddress.transfer(fee);
        fee = _amount.mul(MARKETING_FEE-10).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) marketingAddress.transfer(fee);
        fee = _amount.mul(SUPPORTING_FEE).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) supportAddress.transfer(fee);
        fee = _amount.mul(DEV_FEE+5).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
    }
    function pauseWithdrawal() public view returns(bool){
        uint8 hour = uint8((block.timestamp / 60 / 60) % 24);
        if(hour >= 0 && hour <= 3){
            return true;
        }
        else{
            return false;
        }
    }
    function getMyDividends() public view returns(uint){
        
        uint256 dividends;
        
		for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
		    if(users[msg.sender].deposits[i].withdrawn < users[msg.sender].deposits[i].amount.mul(5).div(2)){
		        uint dividend = users[msg.sender].deposits[i].amount.add(users[msg.sender].deposits[i].reInvested).mul(FIX_PERCENT)
					.mul(block.timestamp.sub(users[msg.sender].deposits[i].checkpoint))
					.div(PERCENTS_DIVIDER)
					.div(TIME_STEP);
    			dividends = dividends.add(dividend);
		    }
		}
		return dividends > users[msg.sender].totalInvested*5/2 ? users[msg.sender].totalInvested*5/2 : dividends;
    }
    function getUserBalance(address _user) public view returns(uint){
        
        uint256 amount;
        
		for (uint256 i = 0; i < users[_user].deposits.length; i++) {
		    if(users[_user].deposits[i].withdrawn < users[_user].deposits[i].amount.mul(5).div(2)){
		        amount += users[_user].deposits[i].amount.add(users[_user].deposits[i].reInvested);
		    }
		}
		return amount;
    }
    function getFreshDeposits(address _user) public view returns(uint){
        
        uint256 amount;
        
		for (uint256 i = 0; i < users[_user].deposits.length; i++) {
		    if(users[_user].deposits[i].withdrawn == 0 && users[_user].deposits[i].reInvested == 0){
		        amount += (users[_user].deposits[i].amount.mul(10).div(9));
		    }
		}
		return amount;
    }

	function invest(address referrer) public payable beforeStarted() {
	    require(!isContract(msg.sender) && msg.sender == tx.origin);
		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		supportAddress.transfer(msg.value.mul(SUPPORTING_FEE).div(PERCENTS_DIVIDER));
		adminAddress.transfer(msg.value.mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
		devAddress.transfer(msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER));
		
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && user.deposits.length == 0 && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {
		    payUplines(msg.value);
		}

		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
			user.checkpoint = uint32(block.timestamp);
			countUplines();
			emit NewUser(msg.sender);
		}
        
        uint amount = msg.value.mul(9).div(10);
		user.deposits.push(Deposit(uint64(amount), 0, uint32(block.timestamp), 0));
		user.totalInvested = uint64(user.totalInvested.add(msg.value));
		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, msg.value, amount);

	}

	function withdraw(uint _plan) public beforeStarted() {
		User storage user = users[msg.sender];
        require(block.timestamp > user.checkpoint + TIME_STEP , "Only once a day");
		require(!pauseWithdrawal(), "Withdrawal paused between 1-4 am utc");
        require(user.deposits.length > 0, "Not registered");
        if(_plan > 2) {
            _plan = 2;
        }
                
        uint invested = getFreshDeposits(msg.sender);
		if(_plan != 2 && user.lastWithdrawn > 0.1 ether){
		    require( invested >= user.lastWithdrawn.div(4), "Make a deposit to be able to withdraw");
		}
		
		uint dividends;
		uint reInvests; 
		uint toBePaid;
		uint reInvested;
		uint totalDividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    
		    if(user.deposits[i].withdrawn < user.deposits[i].amount.mul(5).div(2)){
		        Deposit storage dep = user.deposits[i];
    			uint dividend = uint(dep.amount)
        			.add(dep.reInvested)
        			.mul(FIX_PERCENT)
    				.mul(block.timestamp.sub(dep.checkpoint))
    				.div(PERCENTS_DIVIDER)
    				.div(TIME_STEP);
    				
    			if(dividend > dep.amount.add(dep.reInvested).mul(5).div(2)){
    			    dividend = dep.amount.add(dep.reInvested).mul(5).div(2);
    			}
    			
    			totalDividends += dividend;
						
				if(_plan == 0){
				    reInvested = dividend.div(2);
				    toBePaid = dividend.div(4);
				}else if(_plan == 1){
				    reInvested = 0;
				    toBePaid = dividend.div(2);
				}else{
				    reInvested = dividend.mul(3).div(4);
				    toBePaid = 0;
				}
				
				if(dep.withdrawn.add(toBePaid) > dep.amount.mul(5).div(2)){
				    toBePaid = dep.amount.mul(5).div(2).sub(dep.withdrawn);
				    reInvested = 0;
				}
			
        		if(dividends.add(toBePaid) >= MAX_DAILY_WITHDRAWAL){
        		    if(reInvested>0){
        		        reInvested = reInvested.add(dividends.add(toBePaid).sub(MAX_DAILY_WITHDRAWAL));
        		    }
        		    toBePaid = MAX_DAILY_WITHDRAWAL.sub(dividends);
        		}
        		
                dividends = dividends.add(toBePaid);
				reInvests = reInvests.add(reInvested);

        		dep.withdrawn = uint64(dep.withdrawn.add(toBePaid));
        		dep.reInvested = uint64(dep.reInvested.add(reInvested));
        		dep.checkpoint = uint32(block.timestamp);
		    }
		}
		
		if(dividends > 0){
		    require(totalDividends >= 0.025 ether, "Min withdrawal is 0.025 bnb");
		}
		
		if(reInvests>0){
		    payUplinesReInvest(reInvests);
		}
		
        user.checkpoint = uint32(block.timestamp);
        if(dividends>0){
            user.lastWithdrawn = uint64(dividends);
        }
		user.totalWithdrawn = uint64(uint(user.totalWithdrawn).add(dividends));

		emit Withdrawn(msg.sender, totalDividends, dividends, reInvests);
		
		if (address(this).balance < dividends) {
			dividends = address(this).balance;
		}

		msg.sender.transfer(dividends);
		transferFee(dividends);
	}
	
	function withdrawRefBonus() external {
		
	    require(!pauseWithdrawal(), "Withdrawal paused between 1-4 am utc");
	    User storage user = users[msg.sender];
	    require(block.timestamp > user.checkpoint + TIME_STEP*2 , "Only once per two days");
	    
	    uint paid = user.bonus > MAX_DAILY_Ref_WITHDRAWAL ? MAX_DAILY_Ref_WITHDRAWAL : user.bonus;
	    
	    user.bonus = uint64(user.bonus.sub(paid));
	    user.checkpoint = uint32(block.timestamp);
	    user.totalRefBonus = uint64(user.totalRefBonus.add(paid));
        
		msg.sender.transfer(paid);
		transferFee(paid);
	}

    function getStatsView() public view returns
        (uint256 statsTotalUsers,
        uint256 statsTotalInvested,
        uint256 statsContractBalance,
        uint256 statsUserTotalInvested,
        uint256 statsUserTotalReInvested,
        uint256 statsUserNewDeposits,
        uint256 statsUserTotalWithdrawn,
        uint256 statsUserLastWithdrawn,
        uint256 statsUserRefBonus,
        uint256 statsUserRefBonusWithdrawn,
        uint256 statsUserDividends,
        uint32 statsUserCheckpoint,
        address statsUserReferrer,
        uint64[5] memory statsUserRefCounts)
    {
            return 
                (totalUsers,
                totalInvested,
                address(this).balance,
                users[msg.sender].totalInvested,
                getUserBalance(msg.sender),
                getFreshDeposits(msg.sender),
                users[msg.sender].totalWithdrawn,
                users[msg.sender].lastWithdrawn,
                users[msg.sender].bonus,
                users[msg.sender].totalRefBonus,
                getMyDividends(),
                users[msg.sender].checkpoint,
                users[msg.sender].referrer,
                users[msg.sender].refCounts);
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