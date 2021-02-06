/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity 0.5.10;

contract ETHREV {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 0.02 ether;
	uint256 constant public BASE_PERCENT = 15;
	uint256[] public REFERRAL_PERCENTS = [50, 30, 10];
	uint256 constant public OWNER_FEE = 50;
	uint256 constant public DISTR_PERCENT = 20;
	uint256 constant public ROI_PERCENT = 2000;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 100 ether;
	uint256 constant public TIME_STEP = 1 days;

	uint256 internal _totalBank;
    uint256 internal _profitPerShare;
    uint256 internal _magnitude = 1e18;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public owner;
	address public defaultReferrer;
	uint256 internal _bonusCount;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256[4] totalBonuses;
		uint256 withdrawnBonuses;
		uint256 refBackPercent;
		uint256 payoutsTo;
		uint256 bonusCount;
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event RefBack(address indexed referrer, address indexed referral, uint256 amount);

	constructor(address payable ownerAddr, address defaultRefAddr) public {
		require(!_isContract(ownerAddr) && !_isContract(defaultRefAddr));
		owner = ownerAddr;
		defaultReferrer = defaultRefAddr;
	}

	function() external payable {
		if (msg.value > 0) {
			invest(_bytesToAddress(bytes(msg.data)));
		} else {
			withdraw();
		}
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		owner.transfer(msg.value.mul(OWNER_FEE).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
			if (!isActive(referrer)) {
				referrer = defaultReferrer;
			}
            user.referrer = referrer;
			address upline = referrer;
            for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
        }

		address upline = user.referrer;
		for (uint256 i = 0; i < 3; i++) {
			if (upline != address(0)) {
				uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				if (i == 0) {
					if (users[upline].refBackPercent > 0) {
						uint256 refback = amount.mul(users[upline].refBackPercent).div(PERCENTS_DIVIDER);
						user.totalBonuses[3] = user.totalBonuses[3].add(refback);
						amount = amount.sub(refback);
						emit RefBack(upline, msg.sender, refback);
					}
				}
				users[upline].totalBonuses[i] = users[upline].totalBonuses[i].add(amount);
				emit RefBonus(upline, msg.sender, i, amount);
				upline = users[upline].referrer;
			} else break;
		}

		uint256 deposit = msg.value.mul(900).div(PERCENTS_DIVIDER);
		uint256 dividends = msg.value.mul(DISTR_PERCENT).div(PERCENTS_DIVIDER);

		if (_totalBank > 0) {
            _profitPerShare = _profitPerShare.add(dividends.mul(_magnitude).div(_totalBank));
            user.payoutsTo = user.payoutsTo.add(_profitPerShare.mul(deposit));
        } else {
            _profitPerShare = _profitPerShare.add(dividends.mul(_magnitude).div(deposit));
        }

		_totalBank = _totalBank.add(deposit);

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(deposit, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

		uint256 balance = address(this).balance;

		// 0.5% to everyone every 100 ETH on balance
		if (balance.div(CONTRACT_BALANCE_STEP) > _bonusCount) {
			_bonusCount = balance.div(CONTRACT_BALANCE_STEP);
			_profitPerShare = _profitPerShare.add((balance.mul(5).div(PERCENTS_DIVIDER)).mul(_magnitude).div(_totalBank));
		}

	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		uint256 paidIdx;
		uint256 paidAmount;

		uint256 distributionShare = getDistributionShare(msg.sender);
		if (distributionShare > 0) {
			totalAmount = totalAmount.add(distributionShare);
			user.payoutsTo = user.payoutsTo.add(distributionShare.mul(_magnitude));
		}

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ROI_PERCENT).div(PERCENTS_DIVIDER)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) >= user.deposits[i].amount.mul(ROI_PERCENT).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);

					paidAmount++;
					if (paidIdx == 0) {
						paidIdx = i;
					}
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); // changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.withdrawnBonuses = user.withdrawnBonuses.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		if (paidIdx != 0) {
			for (uint256 i = 0; i < paidAmount; i++) {
				_totalBank = _totalBank.sub(user.deposits[paidIdx + i].amount);
			}
		}

		// 2% to everyone
		_profitPerShare = _profitPerShare.add((totalAmount.mul(DISTR_PERCENT).div(PERCENTS_DIVIDER)).mul(_magnitude).div(_totalBank));

		(owner.send(totalAmount.mul(OWNER_FEE).div(PERCENTS_DIVIDER)));

		totalAmount = totalAmount.mul(900).div(PERCENTS_DIVIDER);

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

    function setRefBackPercent(uint256 newPercent) public {
		require(newPercent <= PERCENTS_DIVIDER);
		User storage user = users[msg.sender];
		user.refBackPercent = newPercent;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

    function getUserHoldBonus(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		if (isActive(userAddress)) {
			uint256 holdBonus = (now.sub(user.checkpoint)).div(TIME_STEP);
			return holdBonus;
		} else {
			return 0;
		}
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		return BASE_PERCENT.add(getUserHoldBonus(userAddress));
	}

	function getDistributionShare(address account) public view returns(uint256) {
		if (getUserTotalActiveDeposits(msg.sender) > 0) {
			return (_profitPerShare.mul(getUserTotalActiveDeposits(msg.sender)).sub(users[account].payoutsTo)).div(_magnitude);
		}
    }

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ROI_PERCENT).div(PERCENTS_DIVIDER)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(ROI_PERCENT).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(ROI_PERCENT).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				// no update of withdrawn because that is view function

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

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return getUserTotalRefBonus(userAddress).sub(getUserReferralWithdraw(userAddress));
	}

	function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawnBonuses;
	}

	function getUserTotalRefBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonuses[0].add(users[userAddress].totalBonuses[1]).add(users[userAddress].totalBonuses[2]);
	}

	function getUserTotalBonusEarnings(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].totalBonuses[0], users[userAddress].totalBonuses[1], users[userAddress].totalBonuses[2]);
	}

	function getUserTotalRefBack(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonuses[3];
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress)).add(getDistributionShare(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(ROI_PERCENT).div(PERCENTS_DIVIDER)) {
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

	function getUserTotalActiveDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ROI_PERCENT).div(PERCENTS_DIVIDER)) {
				amount = amount.add(user.deposits[i].amount);
			}
		}

		return amount;
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

		uint256 amount = getUserReferralWithdraw(userAddress);

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
	}

	function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	function _bytesToAddress(bytes memory _source) internal pure returns(address parsedReferer) {
        assembly {
            parsedReferer := mload(add(_source,0x14))
        }
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