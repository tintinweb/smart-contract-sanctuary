//SourceUnit: TronForce.sol

pragma solidity 0.5.4;

contract TronForce {
    
    modifier onlyOwner {
        require(msg.sender == owner, "Access denied");
        _;
    }
    
	using SafeMath for uint256;
	using SafeMath for uint64;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256 constant public MIN_WITHDRAW = 50 trx;
	uint256[] public REFERRAL_PERCENTS = [50, 40, 30, 20, 10];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint constant public MAX_PROFIT = 3000;//300%
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public WITHDRAW_INTERVAL = 5 days;
	uint256 constant public RATE = 30; //3%

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;

	address payable public marketingAddress;
    address payable public devAddress;
    address payable public communityWallet;
    address payable public adminWallet;
    address payable public refundAddress;
    address public owner;

	struct Deposit {
		uint64 amount;
		uint64 start;
		bool reinvest;
	}

	struct User {
	    uint64 totalWithdrawn;
		uint64 checkpoint;
		address payable referrer;
		uint32 downlines;
		Deposit[] deposits;
	}

	mapping (address => User) internal users;

	event Newbie(address indexed user, address referrer);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	
	function() external payable {}
	
	constructor(
	    address payable marketingAddr, 
	    address payable communityAddr, 
	    address payable adminAddr, 
	    address payable devAddr) public {
            require(!isContract(marketingAddr) &&
            !isContract(communityAddr) &&
            !isContract(adminAddr) &&
            !isContract(devAddr));
        
        marketingAddress = marketingAddr;
        communityWallet = communityAddr;
        adminWallet = adminAddr;
        devAddress = devAddr;
        owner = msg.sender;
        
        users[msg.sender].deposits.push(Deposit(1 trx, uint64(block.timestamp), false));
	}

	function invest(address payable _ref) public payable {
	    
		require(msg.value >= INVEST_MIN_AMOUNT);
		require(refundAddress != address(0));

		payAdminOnDep(msg.value);
		
		User storage user = users[msg.sender];

		if (user.referrer == address(0)){
		    require(users[_ref].deposits.length > 0 && _ref != msg.sender, 'Invalid referrer');
			user.referrer = _ref;
			users[_ref].downlines++;
		}

		if (user.referrer != address(0)) {
			address payable upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					upline.transfer(amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = uint32(block.timestamp);
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender, _ref);
		}

		user.deposits.push(Deposit(uint64(msg.value), uint32(block.timestamp), false));
		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {
		
		User storage user = users[msg.sender];
		require(block.timestamp > users[msg.sender].checkpoint + WITHDRAW_INTERVAL, "Ops!");

		uint totalDeposit = getUserTotalDeposits(msg.sender);
		uint dividends = getUserDividends(msg.sender);
		require(dividends >= MIN_WITHDRAW);
		if(dividends.add(user.totalWithdrawn) > totalDeposit.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)){
		    dividends = totalDeposit.mul(MAX_PROFIT).div(PERCENTS_DIVIDER).sub(user.totalWithdrawn);
		}
		
		uint256 contractBalance = address(this).balance;
		if (contractBalance < dividends) {
			dividends = contractBalance;
		}
		user.deposits.push(Deposit(uint64(dividends.mul(40).div(100)), uint64(now), true));
		refundAddress.transfer(dividends.div(10));
		dividends = dividends.div(2);

		user.checkpoint = uint32(block.timestamp);
		user.totalWithdrawn = uint64(user.totalWithdrawn.add(dividends));
		totalWithdrawn = totalWithdrawn.add(dividends);
		
		msg.sender.transfer(dividends);
		
		emit Withdrawn(msg.sender, dividends);

	}

	function reinvest() public {
	    
		User storage user = users[msg.sender];
		require(block.timestamp > users[msg.sender].checkpoint + WITHDRAW_INTERVAL, "Ops!");

		uint dividends = getUserDividends(msg.sender);
		uint totalDeposit = getUserTotalDeposits(msg.sender);
		require(dividends >= MIN_WITHDRAW);
		if(dividends.add(user.totalWithdrawn) > totalDeposit.mul(MAX_PROFIT).div(PERCENTS_DIVIDER)){
		    dividends = totalDeposit.mul(MAX_PROFIT).div(PERCENTS_DIVIDER).sub(user.totalWithdrawn);
		}
		user.deposits.push(Deposit(uint64(dividends.mul(90).div(100)), uint32(now), true));
		user.checkpoint = uint32(block.timestamp);
		
		refundAddress.transfer(dividends.div(10));
		payAdminOnReinvest(dividends);
		
	}
    
    function payAdminOnDep(uint _amount) private {
        marketingAddress.transfer(_amount*5/100);
        communityWallet.transfer(_amount*3/100);
        devAddress.transfer(_amount*4/100);
        adminWallet.transfer(_amount*2/100);
    }
    
    function payAdminOnReinvest(uint _amount) private {
        marketingAddress.transfer(_amount*6/100);
        communityWallet.transfer(_amount*2/100);
        devAddress.transfer(_amount*3/100);
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
	    
		User storage user = users[userAddress];
		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
            
            Deposit storage dep = user.deposits[i];
			uint checkpoint = dep.start > user.checkpoint ? dep.start : user.checkpoint; 

			dividends = dep.amount.mul(RATE).div(PERCENTS_DIVIDER)
				.mul(block.timestamp.sub(checkpoint))
				.div(TIME_STEP);
				
			totalDividends = totalDividends.add(dividends);
		}

		return totalDividends;
		
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    if(!user.deposits[i].reinvest){
    		    amount = amount.add(user.deposits[i].amount);
		    }
		}

		return amount;
	}
	
	function getUserDepositsWithReinvests(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		return user.totalWithdrawn;
	}
    
    function setRefundAddress(address payable _addr) public onlyOwner{
        require(isContract(_addr), "Only contract");
        refundAddress = _addr;
    }

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, bool) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].start, user.deposits[index].reinvest);
	}
	
    function getUserData(address _addr) external view returns ( uint[] memory data ){
        
        User memory u = users[_addr];
        uint[] memory d = new uint[](17);
        d[0] = u.checkpoint;
        d[1] = 0;
        d[2] = u.downlines;
        d[3] = getUserDividends(_addr);
        d[4] = getUserDepositsWithReinvests(_addr);
        d[5] = getUserTotalDeposits(_addr);
        d[6] = getUserTotalWithdrawn(_addr);
        d[7] = 0;
        d[8] = totalInvested;
        d[9] = totalWithdrawn;
        d[10] = 0;
        d[11] = totalUsers;
        d[12] = getContractBalance();
        d[13] = 0;
        d[14] = 0;
        d[15] = 0;
        d[16] = 0;
        
        return d;
        
    }
    
    function getUserDeposits(address _addr) external view returns ( uint[] memory deposits, uint[] memory dates ){
        
        User memory u = users[_addr];
        deposits = new uint[](u.deposits.length);
        dates = new uint[](u.deposits.length);
        
        for (uint256 i = 0; i < u.deposits.length; i++) {
			deposits[i] = u.deposits[i].amount;
			dates[i] = u.deposits[i].start;
		}
        
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