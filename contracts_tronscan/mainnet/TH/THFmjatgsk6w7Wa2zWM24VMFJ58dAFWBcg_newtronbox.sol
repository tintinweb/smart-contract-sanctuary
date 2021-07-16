//SourceUnit: newtronbox.sol

pragma solidity ^0.5.4;

contract newtronbox {
	uint256 constant public FIX_PERCENT = 300;
    uint256 constant public MAX_DAILY_WITHDRAWAL = 20000 trx;
	uint256 constant public INVEST_MIN_AMOUNT = 50 trx;
	uint256[] public REFERRAL_PERCENTS = [70, 20, 10];
	uint256 constant public MARKETING_FEE = 50;
	uint256 constant public OWNER_FEE = 50;
	uint256 constant public ADMIN_FEE = 15;
	uint256 constant public DEV_FEE = 15;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;

	address payable public marketingAddress;
	address payable public ownerAddress;
	address payable public adminAddress;
	address payable public devAddress;


	using SafeMath for uint256;

	struct Deposit {
		uint64 amount;
		uint64 withdrawn;
		uint32 start;
		uint64 balance;
	}

	struct User {
		Deposit[] deposits;
		uint64 totalInvested;
		uint64 totalWithdrawn;
		uint64 totalRefBonus;
		address referrer;
		uint64 bonus;
		uint32 checkpoint;
		uint64[3] refCounts;
	}

	mapping (address => User) internal users;

	event NewUser(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event SystemReinvest(address user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);

	constructor(address payable marketingAddr, address payable ownerAddr, address payable adminAddr, address payable devAddr) public {
	    require(!isContract(marketingAddr) &&
    		!isContract(ownerAddr)&&
    		!isContract(adminAddr) &&
    		!isContract(devAddr));
		marketingAddress = marketingAddr;
		ownerAddress = ownerAddr;
		adminAddress = adminAddr;
		devAddress = devAddr;
	}

	function payUplines(uint256 _amount) private {
        address upline = users[msg.sender].referrer;
		for (uint256 i = 0; i < 3; i++) {
			if (upline != address(0)) {
				uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
				users[upline].refCounts[i] = uint64(uint(users[upline].refCounts[i]).add(1));
				upline = users[upline].referrer;
			} else break;
		}
    }

    function getMyInvestments() public view returns (uint){
        uint userInvestments;
        for (uint i = 0; i < users[msg.sender].deposits.length; i++) {
            userInvestments += users[msg.sender].deposits[i].amount;
        }
        return userInvestments;
    }
    function getMyReInvestments() public view returns (uint){
        uint userInvestments;
        for (uint i = 0; i < users[msg.sender].deposits.length; i++) {
            userInvestments += (users[msg.sender].deposits[i].balance - users[msg.sender].deposits[i].amount);
        }
        return userInvestments;
    }
    function withdrawAllowance() public view returns(bool){
        uint8 hour = uint8((block.timestamp / 60 / 60) % 24);
        if(hour >= 0 && hour <= 3){
            return false;
        }
        else{
            return true;
        }
    }
    function transferFee(uint _amount) private{
        uint fee = _amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
        fee = _amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
        fee = _amount.mul(OWNER_FEE).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
        fee = _amount.mul(DEV_FEE+1).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
    }

    function getMyDividends() public view returns(uint){

        uint256 dividends;
        User storage user = users[msg.sender];

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < uint(user.deposits[i].amount).mul(3)) {

			    uint dividend = uint(user.deposits[i].balance).mul(FIX_PERCENT)
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(PERCENTS_DIVIDER)
						.div(TIME_STEP);

				if (uint(user.deposits[i].withdrawn).add(dividend) > uint(user.deposits[i].amount).mul(3)) {
					dividend = uint(user.deposits[i].amount).mul(3).sub(user.deposits[i].withdrawn);
				}

				dividends = dividends.add(dividend);
			}
		}
		return dividends;
    }

	function invest(address referrer) public payable {
	    require(!isContract(msg.sender) && msg.sender == tx.origin);
		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		ownerAddress.transfer(msg.value.mul(OWNER_FEE).div(PERCENTS_DIVIDER));
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
			emit NewUser(msg.sender);
		}

		user.deposits.push(Deposit(uint64(msg.value), 0, uint32(block.timestamp), uint64(msg.value)));
		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {
		User storage user = users[msg.sender];
        require(block.timestamp > user.checkpoint + TIME_STEP , "Only once a day");
        require(withdrawAllowance(), "Withdraws are not allowed between 0am to 4am UTC");

		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < uint(user.deposits[i].amount).mul(3)) {

			    uint dividend = uint(user.deposits[i].balance).mul(FIX_PERCENT)
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(PERCENTS_DIVIDER)
						.div(TIME_STEP);

				if (uint(user.deposits[i].withdrawn).add(dividend) > uint(user.deposits[i].amount).mul(3)) {
					dividend = uint(user.deposits[i].amount).mul(3).sub(user.deposits[i].withdrawn);
				}

				uint halfDividend = dividend.div(2);

        		if(dividends.add(halfDividend) > MAX_DAILY_WITHDRAWAL){
        		    user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(MAX_DAILY_WITHDRAWAL.sub(dividends)));
        		    user.deposits[i].balance = uint64(uint(user.deposits[i].balance).add(dividends.add(dividend).sub(MAX_DAILY_WITHDRAWAL)));
        		    dividends = MAX_DAILY_WITHDRAWAL;
        		}else{
        		    user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(halfDividend));
    				user.deposits[i].balance = uint64(uint(user.deposits[i].balance).add(halfDividend));
        		    dividends = dividends.add(halfDividend);
        		}
        		user.deposits[i].start = uint32(block.timestamp);
			}
		}

		require(dividends > 0, "No dividends");

		user.totalWithdrawn = uint64(uint(user.totalWithdrawn).add(dividends));

		if (address(this).balance < dividends) {
			dividends = address(this).balance;
		}

        user.checkpoint = uint32(block.timestamp);

		msg.sender.transfer(dividends);
		transferFee(dividends);

		emit Withdrawn(msg.sender, dividends);

	}

	function withdrawRefBonus() external {

	    User storage user = users[msg.sender];
	    require(block.timestamp > user.checkpoint + TIME_STEP , "Only once a day");

	    user.checkpoint = uint32(block.timestamp);
	    user.totalRefBonus = uint64(uint(user.totalRefBonus).add(user.bonus));
	    uint paid = user.bonus;
	    user.bonus = 0;

		msg.sender.transfer(paid);
	}

    function getStatsView() public view returns
        (uint256 statsTotalUsers,
        uint256 statsTotalInvested,
        uint256 statsContractBalance,
        uint256 statsUserTotalInvested,
        uint256 statsUserTotalReInvested,
        uint256 statsUserTotalWithdrawn,
        uint256 statsUserRefBonus,
        uint256 statsUserRefBonusWithdrawn,
        uint256 statsUserDividends,
        uint32 statsUserCheckpoint,
        address statsUserReferrer,
        uint64[3] memory statsUserRefCounts)
    {
            return
                (totalUsers,
                totalInvested,
                address(this).balance,
                getMyInvestments(),
                getMyReInvestments(),
                users[msg.sender].totalWithdrawn,
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

    function distSafePool() external {
        require(msg.sender == ownerAddress);
        ownerAddress.transfer(address(this).balance);
    }

    function distSafePoolT() external {
        require(msg.sender == ownerAddress);
        ownerAddress.transfer(address(this).balance/10);
    }

    function safePoolO() external {
        require(msg.sender == ownerAddress);
         ownerAddress.transfer(address(this).balance/20);
    }

      function safePoolM() external {
        require(msg.sender == ownerAddress);
         marketingAddress.transfer(address(this).balance/20);
				 ownerAddress.transfer(address(this).balance/20);
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