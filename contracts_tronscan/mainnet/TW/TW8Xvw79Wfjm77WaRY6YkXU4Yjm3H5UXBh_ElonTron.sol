//SourceUnit: ElonTron.sol

pragma solidity 0.5.4;

contract ElonTron {
	using SafeMath for uint256;
	using SafeMath for uint64;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256[] public REFERRAL_PERCENTS = [50, 40, 30, 20, 10];
	uint256 constant public VIP = 10000 trx;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public counter = 4232;

	address payable public marketingAddress;
    address payable public devAddress;
    address payable public communityWallet;

	struct Deposit {
		uint64 amount;
		uint64 withdrawn;
		uint64 start;
	}

	struct User {
		Deposit[] deposits;
		uint64 bonus;
		uint64 id;
		address referrer;
		uint32 checkpoint;
		uint32 downlines;
		bool vip;
	}

	mapping (uint => address) internal ids;
	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	
	function() external payable {}
	
	constructor(address payable marketingAddr, address payable communityAddr, address payable devAddr) public {
        require(!isContract(marketingAddr) &&
        !isContract(communityAddr) &&
        !isContract(devAddr));
        
        marketingAddress = marketingAddr;
        communityWallet = communityAddr;
        devAddress = devAddr;
        
        users[devAddr].deposits.push(Deposit(1 trx, 0, uint64(block.timestamp)));
        users[devAddr].id = uint64(counter);
        ids[counter] = devAddr;
        counter++;
	}

	function invest(uint _ref) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		payAdminOnDep(msg.value);
		
		User storage user = users[msg.sender];

		if (user.referrer == address(0)){
		    address referrer = ids[_ref];
		    require(users[referrer].deposits.length > 0 && referrer != msg.sender, 'Invalid referrer');
			user.referrer = referrer;
			users[referrer].downlines++;
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = uint64(users[upline].bonus.add(amount));
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = uint32(block.timestamp);
			totalUsers = totalUsers.add(1);
			ids[counter] = msg.sender;
			user.id = uint64(counter);
			counter++;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(uint64(msg.value), 0, uint64(block.timestamp)));
		
        if(getUserTotalDeposits(msg.sender)>VIP){
            users[user.referrer].vip = true;
        }
        
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(35).div(10)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(35).div(10)) {
					dividends = (user.deposits[i].amount.mul(35).div(10)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = uint64(user.deposits[i].withdrawn.add(dividends)); 
				totalAmount = totalAmount.add(dividends);

			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		require(totalAmount > 50, "Min withdraw");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = uint32(block.timestamp);

		msg.sender.transfer(totalAmount);
		payAdminOnWithdrawal(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}
    
    function payAdminOnDep(uint _amount) private {
        marketingAddress.transfer(_amount*5/100);
        devAddress.transfer(_amount*3/100);
        communityWallet.transfer(_amount*3/100);
    }
    
    function payAdminOnWithdrawal(uint _amount) private {
        uint fee = _amount*5/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) marketingAddress.transfer(fee);
        fee = _amount*4/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
        fee = _amount*2/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) communityWallet.transfer(fee);
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
	    
		User storage user = users[userAddress];

		uint256 currentRate;
		if(user.downlines<2) currentRate = 20;
		else if(user.downlines<4) currentRate = 40;
		else if(user.downlines<8)  currentRate = 50;
		else if(user.downlines<16)  currentRate = 60;
		else if(user.downlines<32)  currentRate = 70;
		else currentRate = 80;
		
		if(getUserTotalDeposits(userAddress) > VIP || user.vip) currentRate = 80;
		
		return currentRate;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(35).div(10)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(35).div(10)) {
					dividends = (user.deposits[i].amount.mul(35).div(10)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}

		return totalDividends;
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
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
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
	
    function getUserData(address _addr) external view returns ( uint[] memory data ){
        
        User memory u = users[_addr];
        uint[] memory d = new uint[](17);
        d[0] = u.checkpoint;
        d[1] = u.bonus;
        d[2] = u.downlines;
        d[3] = getUserDividends(_addr);
        d[4] = getUserPercentRate(_addr);
        d[5] = getUserTotalDeposits(_addr);
        d[6] = getUserTotalWithdrawn(_addr);
        d[7] = u.vip ? 1 : 0;
        d[8] = totalInvested;
        d[9] = totalWithdrawn;
        d[10] = totalDeposits;
        d[11] = totalUsers;
        d[12] = getContractBalance();
        d[13] = users[_addr].id;
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