//SourceUnit: XTron.sol

pragma solidity ^0.5.4;

contract  XTron{
    uint256 constant public MAX_DAILY_REF_WITHDRAWAL = 25000 trx;
	uint256 constant public INVEST_MIN_AMOUNT = 500 trx;
	uint256 constant public PREFERRED_FULFILLMENT = 50000 trx;
	uint256 constant public ENROLL_LEADERSHIP = 1000 trx;
	uint256 constant public MIN_PARTNERSHIP = 25000 trx;
	uint8[15] public REFERRAL_PERCENTS = [250, 150, 100, 50, 50, 50, 50, 30, 30, 30, 30, 30, 50, 50, 50];
	uint8[20] public LEADERSHIP_PERCENTS = [150, 100, 50, 50, 50, 50, 50, 50, 50, 100, 20, 20, 20, 20, 20, 50, 50, 50, 50, 50];
	uint256 constant public MARKETING_FEE = 50;
	uint256 constant public COMMUNITY_FEE = 25;
	uint256 constant public ADMIN_FEE = 40;
	uint256 constant public DEV_FEE = 30;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint public totalUsers;
	uint public totalInvested;
	uint public leadershipPool;
	uint public prelaunchTime;
	uint public launchTime;
	uint public daysCycle;
	uint public lastBalanceCheck;
	uint public lastDayInvestment;
	uint public inrollLeaderships;
	address[] public partnerships;
	address[] public holydayProgram;
	
	uint public top5;
    address public top5ad;
    uint public top4;
    address public top4ad;
    uint public top3;
    address public top3ad;
    uint public top2;
    address public top2ad;
    uint public top1;
    address public top1ad;
    
    uint public lasttop5;
    address public lasttop5ad;
    uint public lasttop4;
    address public lasttop4ad;
    uint public lasttop3;
    address public lasttop3ad;
    uint public lasttop2;
    address public lasttop2ad;
    uint public lasttop1;
    address public lasttop1ad;

	address payable public defaultAccount;
	address payable public marketingAddress;
	address payable public adminAddress;
	address payable public devAddress;
	address payable public communityWallet;
	
	using SafeMath for uint64;
	using SafeMath for uint256;

	struct User {
	    
	    uint64 activeContribution;
		uint64 totalInvested;
		uint64 totalWithdrawn;
		uint64 totalRefBonus;
		uint64 bonus;
		uint64 leadershipIncome;
		uint64 leadershipWithdrawn;
		uint64 leadershipDebit;
		uint64 downlineMaxDep;
		address referrer;
		uint32 checkpoint;
		uint32 countdown;
		uint8 VRR;//VARIABLE RATE OF RETURN
		bool participateLeadership;
		bool is25kFulfilled;
		uint64[] depositAmounts;
		uint32[] depositTimes;
		
	}

	mapping (address => User) internal users;

	event NewUser(address indexed user, address referrer, uint amount);
	event NewDeposit(address indexed user, uint256 amount, uint time, uint activeContribution, uint VRR);
	event Withdrawn(address indexed user, uint256 dividends, uint256 activeContribution, uint256 totalWithdrawn);
	event Reinvest(address indexed user, uint256 dividends, uint256 activeContribution, uint256 VRR);
	event RefWithdrawn(address indexed user, uint256 profit, uint256 currentBonus, uint256 activeContribution);
	event NewLeadershipDeposit(address indexed user, uint256 amount);
	event LeadershipWithdrawn(address indexed user, uint256 profit, uint256 activeContribution);
	event VRRZero(address indexed user);
    
	constructor(address payable defaultAccountAddr, address payable marketingAddr, address payable adminAddr, address payable communityAddr, address payable devAddr) public {
	    require(!isContract(marketingAddr) && 
    		!isContract(defaultAccountAddr) &&
    		!isContract(communityAddr) &&
    		!isContract(adminAddr) &&
    		!isContract(devAddr));
        defaultAccount = defaultAccountAddr;
		marketingAddress = marketingAddr;
		adminAddress = adminAddr;
		communityWallet = communityAddr;
		devAddress = devAddr;
		
        prelaunchTime = block.timestamp;
        launchTime = block.timestamp + 120 hours;
        
        users[defaultAccountAddr].checkpoint = uint32(block.timestamp);
        users[defaultAccountAddr].VRR = 8;
	}
	
	//////////////////////////////////////////////////////////
	//------------------private functions-------------------//
	
	function payUplines(uint _amount) private {
        address upline = users[msg.sender].referrer;
		for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
			if (upline != address(0)) {
				uint amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
				upline = users[upline].referrer;
			} else break;
		}
    }
    
    function payUplinesLeadership(uint _amount) private {
        address upline = users[msg.sender].referrer;
		for (uint i = 0; i < LEADERSHIP_PERCENTS.length; i++) {
			if (upline != address(0)) {
				if(users[upline].participateLeadership && users[upline].leadershipDebit == 0){
				    uint amount = _amount.mul(LEADERSHIP_PERCENTS[i]).div(PERCENTS_DIVIDER);
    				users[upline].leadershipIncome = uint64(uint(users[upline].leadershipIncome).add(amount));
    				upline = users[upline].referrer;
				}
			} else break;
		}
    }
    
    function countUplines() private {
//         address upline = users[msg.sender].referrer;
// 		for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
// 			if (upline != address(0)) {
// 				users[upline].refCounts[i] = uint64(uint(users[upline].refCounts[i]).add(1));
// 				upline = users[upline].referrer;
// 			} else break;
// 		}
    }
    
    function distributeDeposit(uint _amount) private{
        uint fee = _amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER);// 4% admin team
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) adminAddress.transfer(fee);
        fee = _amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);//5% marketing team
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) marketingAddress.transfer(fee);
        fee = _amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);//3% dev team
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
    }
    
    function updateDailyTops(uint _trx, address _sender) private{
        if (_trx > top1){
          
            top5 = top4;
            top5ad = top4ad;
            top4 = top3;
            top4ad = top3ad;
            top3 = top2;
            top3ad = top2ad;
            top2 = top1;
            top2ad = top1ad;
            top1 = _trx;
            top1ad =_sender;
              
        }else if (_trx > top2){
              
            top5 = top4;
            top5ad = top4ad;
            top4 = top3;
            top4ad = top3ad;
            top3 = top2;
            top3ad = top2ad;
            top2 = _trx;
            top2ad = _sender;
            
        }else if (_trx > top3){
            
            top5 = top4;
            top5ad = top4ad;
            top4 = top3;
            top4ad = top3ad;
            top3 = _trx;
            top3ad = _sender;
              
        }else if (_trx > top4){
              
            top5 = top4;
            top5ad = top4ad;
            top4 = _trx;
            top4ad= _sender;
              
        }else{
            
              top5 = _trx;
              top5ad = _sender;
              
        }
    }
    
	//---------------end of private functions---------------//
    //////////////////////////////////////////////////////////
    
    function pauseWithdrawal() public view returns(bool){
        
        uint8 hour = uint8((block.timestamp / 60 / 60) % 24);
        if((hour >= 0 && hour <= 5) || (hour >= 12 && hour <= 17)){
            return true;
        }
        else{
            return false;
        }
    }
    
    function isPreferredContributor(address _addr) public view returns(bool){
        return (users[_addr].is25kFulfilled && (users[_addr].totalInvested > users[_addr].downlineMaxDep));
    }
    
    function checkDayCycle() public{
            
        uint256 daysPassed = (block.timestamp - prelaunchTime) / TIME_STEP;
        if (daysPassed > daysCycle){
            
            daysCycle = daysPassed;
            lastDayInvestment = totalInvested - lastBalanceCheck;
            lastBalanceCheck = totalInvested;
            
            lasttop5 = top5;
            lasttop5ad = top5ad;
            lasttop4 = top4;
            lasttop4ad = top4ad;
            lasttop3 = top3;
            lasttop3ad = top3ad;
            lasttop2 = top2;
            lasttop2ad = top2ad;
            lasttop1 = top1;
            lasttop1ad = top1ad;
            
            top5 = 0;
            top4 = 0;
            top3 = 0;
            top2 = 0;
            top1 = 0;
            
        }
    }
    
	function invest(address referrer) external payable {
	    require(!isContract(msg.sender) && msg.sender == tx.origin);
		require(msg.value >= INVEST_MIN_AMOUNT && msg.value <= 1e7 trx);//Max deposit amount 10M trx
        
		User storage user = users[msg.sender];
		
		if (user.checkpoint == 0) {
		    require(referrer != address(0) && users[referrer].checkpoint > 0 && referrer != msg.sender, "Invalid referrer");
			user.referrer = referrer;
			totalUsers = totalUsers.add(1);
			user.checkpoint = uint32(block.timestamp);
			user.countdown = uint32(block.timestamp);
			user.VRR = 8;
			countUplines();
			emit NewUser(msg.sender, user.referrer, msg.value);
		}

		payUplines(msg.value * 10 / 100);
		
		checkDayCycle();
		
		uint64 amount = uint64(msg.value.mul(9).div(10));
		user.totalInvested += amount;
		user.activeContribution += amount;
		
		if(msg.value > PREFERRED_FULFILLMENT){
		    user.is25kFulfilled = true;
		}
		if(msg.value >= MIN_PARTNERSHIP){
		    partnerships.push(msg.sender);
		}
        if(user.totalInvested > users[user.referrer].downlineMaxDep){
            users[user.referrer].downlineMaxDep = user.totalInvested;
        }
        if(user.VRR < 8) {
		    if(user.VRR < 4 && isPreferredContributor(msg.sender)) user.VRR = 4;
		    else user.VRR++;
		}
		user.depositAmounts.push(uint64(msg.value));
		user.depositTimes.push(uint32(block.timestamp));
		
		totalInvested += msg.value;
		
		updateDailyTops(msg.value, msg.sender);
		
		distributeDeposit(msg.value);

		emit NewDeposit(msg.sender, msg.value, block.timestamp, user.activeContribution, user.VRR);

	}

	function withdraw() external {
	    
		require(!pauseWithdrawal(), "Withdrawal paused");//Withdrawal paused between 1-6 and 12-18 utc time
		
		User storage user = users[msg.sender];
		require(user.VRR > 0, "VRR is zero");
        require(block.timestamp > user.countdown + TIME_STEP , "Only once a day");
        
        uint dividend = getUserDividends(msg.sender) / 2;
        if(dividend == 0) return;
        
        if(user.totalWithdrawn + dividend > user.totalInvested * 2){
            dividend = (user.totalInvested * 2).sub(user.totalWithdrawn);
        }
        
        if(user.VRR > 2) {
            if(!isPreferredContributor(msg.sender)){
                user.VRR -= 2;
            }
        }
        else {
            user.VRR = 0;
            if(user.totalInvested * 10 / 9 >= 25000 trx){
                holydayProgram.push(msg.sender);
                emit VRRZero(msg.sender);
            }
        }
        
        user.totalWithdrawn += uint64(dividend);
        user.activeContribution = uint64(user.activeContribution.sub(dividend));
        user.checkpoint = uint32(block.timestamp);
        user.countdown = uint32(block.timestamp);
        
        payUplinesLeadership(dividend * 2 * 5 / 100);// 5% of dividend(already devided by 2) leadership program
        
		if (address(this).balance < dividend) {
			dividend = address(this).balance;
		}
		
		msg.sender.transfer(dividend);
		
		if((dividend * 2 * 30 / 100) <= address(this).balance){
		    communityWallet.transfer(dividend * 2 * 30 / 100);// 30% of dividend goes to community(dividend alreadt was half so have to multiply 2)
		}else{
		    communityWallet.transfer(address(this).balance);
		}
		
		emit Withdrawn(msg.sender, dividend, user.activeContribution, user.totalWithdrawn);
	}
	
	function reinvest() external {
	    
		//require(!pauseWithdrawal(), "Reinvestment paused");//Reinvestment paused between 1-6 and 12-18 utc time
		
		User storage user = users[msg.sender];
        require(block.timestamp > user.countdown + TIME_STEP , "Only once a day");
        
        uint dividend = getUserDividends(msg.sender) / 2;
        if(dividend == 0) return;
        
        if(user.VRR < 8) user.VRR += 1;
        user.activeContribution += uint64(dividend);
        user.checkpoint = uint32(block.timestamp);
        user.countdown = uint32(block.timestamp);
		
		emit Reinvest(msg.sender, dividend, user.activeContribution, user.VRR);
	}
	
	function withdrawRefBonus() external {
		
        require(!pauseWithdrawal(), "Withdrawal paused");
        User storage user = users[msg.sender];
        require(block.timestamp > user.countdown + TIME_STEP * 2 , "Once per two days");
        
        uint paid = user.bonus > MAX_DAILY_REF_WITHDRAWAL ? MAX_DAILY_REF_WITHDRAWAL : user.bonus;
        
        user.bonus = uint64(user.bonus.sub(paid));
        paid /= 2;
        user.activeContribution += uint64(paid * 9 / 10);
        user.countdown = uint32(block.timestamp);
        user.totalRefBonus = uint64(user.totalRefBonus.add(paid));
        
		msg.sender.transfer(paid);
		emit RefWithdrawn(msg.sender, paid, user.bonus, user.activeContribution);
	}
	
	function inrollLeadership() external payable {
        require(users[msg.sender].checkpoint > 0, "Not registered");
        require(users[msg.sender].participateLeadership == false, "Already activated");
		require(msg.value == ENROLL_LEADERSHIP, "Wrong amount");
        
		users[msg.sender].participateLeadership = true;
		users[msg.sender].countdown = uint32(block.timestamp);
		
		inrollLeaderships++;
        
		communityWallet.transfer(msg.value * 40 / 100);
		
		distributeDeposit(msg.value * 10 / 100);
		
		emit NewLeadershipDeposit(msg.sender, msg.value);
	}
	
	function depositLeadership() external payable {
		require(users[msg.sender].leadershipDebit > 0 && msg.value == users[msg.sender].leadershipDebit);
        
		User storage user = users[msg.sender];
		
		payUplines(msg.value * 10 / 100);
		
		checkDayCycle();
		
		uint64 amount = uint64(msg.value.mul(9).div(10));
		user.totalInvested += amount;
		user.activeContribution += amount;
		user.leadershipDebit = 0;
		user.depositAmounts.push(uint64(msg.value));
		user.depositTimes.push(uint32(block.timestamp));
		user.countdown = uint32(block.timestamp);
		
		totalInvested += msg.value;
		
		updateDailyTops(msg.value, msg.sender);
		
		distributeDeposit(msg.value);

		emit NewDeposit(msg.sender, msg.value, block.timestamp, user.activeContribution, user.VRR);

	}
	
	function withdrawLeadershipBonus() external {
		
        require(users[msg.sender].participateLeadership == true, "Not activated");
        require(users[msg.sender].leadershipDebit == 0, "Unable until deposit");
        require(!pauseWithdrawal(), "Withdrawal paused");
        
        User storage user = users[msg.sender];
        require(block.timestamp > user.countdown + TIME_STEP * 2 , "Once per two days");
        
        uint paid = user.leadershipIncome > MAX_DAILY_REF_WITHDRAWAL ? MAX_DAILY_REF_WITHDRAWAL : user.leadershipIncome;
        
        user.leadershipIncome = uint64(user.leadershipIncome.sub(paid));
        user.countdown = uint32(block.timestamp);
        user.leadershipWithdrawn += uint64(paid);
        user.leadershipDebit = uint64(paid / 2);
        
		msg.sender.transfer(paid);
		emit LeadershipWithdrawn(msg.sender, paid, user.activeContribution);
	}
    
    function getUserDividends(address _user) public view returns(uint){
        
        if(block.timestamp < launchTime) return 0;
        
        uint cp = users[_user].checkpoint > launchTime ? users[_user].checkpoint : launchTime;
        uint dividend = uint(users[_user].activeContribution)
        			.mul(users[_user].VRR)
                    .mul(block.timestamp.sub(cp))
                    .div(100)
                    .div(TIME_STEP);
        if(dividend > users[_user].activeContribution * 8 / 100){
            dividend = users[_user].activeContribution * 8 / 100;
        }
        
        return dividend;
    }
	
	function getUser1(address _addr) external view returns(uint dividends, uint64 activeContribution, uint64 userTotalInvested, uint64 totalWithdrawn, uint8 VRR, uint32 checkpoint, uint32 countdown, uint64[] memory depositAmounts, uint32[] memory depositTimes, uint64 totalRefBonus, uint64 bonus, address referrer){
	    User memory u = users[_addr];
	    return (
	        getUserDividends(_addr),
            u.activeContribution,
            u.totalInvested,
            u.totalWithdrawn,
            u.VRR,
            u.checkpoint,
            u.countdown,
            u.depositAmounts,
            u.depositTimes,
            u.totalRefBonus,
            u.bonus,
            u.referrer
            
	    );
	}
	
	function getUser2(address _addr) external view returns(uint256 statsTotalUsers, uint256 statsTotalInvested, uint256 statsContractBalance, uint256 statsInrolledLeadership, uint64 downlineMaxDep, uint64 leadershipIncome, uint64 leadershipWithdrawn, uint64 leadershipDebit, bool participateLeadership, bool is25kFulfilled){
        User memory u = users[_addr];
        
        return (
            totalUsers,
            totalInvested,
            address(this).balance,
            inrollLeaderships,
            u.downlineMaxDep,
            u.leadershipIncome,
            u.leadershipWithdrawn,
            u.leadershipDebit,
            u.participateLeadership,
            u.is25kFulfilled
	    );
	}
	
	function getTopInvestors() external view returns (address[] memory topAddress, uint[] memory topDeposits, address[] memory lastTopAddress, uint[] memory lastTopDeposits, address[] memory statsPartnerships, address[] memory statsHolydays){
	    address[] memory topAddr = new address[](5);
        uint[] memory topAmounts = new uint[](5);
        address[] memory lastTopAddr = new address[](5);
        uint[] memory lastTopAmounts = new uint[](5);

        topAddr[0]= top1ad;
        topAddr[1]= top2ad;
        topAddr[2]= top3ad;
        topAddr[3]= top4ad;
        topAddr[4]= top5ad;
        
        topAmounts[0] = top1;
        topAmounts[1] = top2;
        topAmounts[2] = top3;
        topAmounts[3] = top4;
        topAmounts[4] = top5;
        
        lastTopAddr[0]= lasttop1ad;
        lastTopAddr[1]= lasttop2ad;
        lastTopAddr[2]= lasttop3ad;
        lastTopAddr[3]= lasttop4ad;
        lastTopAddr[4]= lasttop5ad;
        
        lastTopAmounts[0] = lasttop1;
        lastTopAmounts[1] = lasttop2;
        lastTopAmounts[2] = lasttop3;
        lastTopAmounts[3] = lasttop4;
        lastTopAmounts[4] = lasttop5;
        
        return (
            topAddr,
            topAmounts,
            lastTopAddr,
            lastTopAmounts,
            partnerships,
            holydayProgram);
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