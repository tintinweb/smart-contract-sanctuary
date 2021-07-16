//SourceUnit: GrabTron.sol

/*
 *  
 *   GRABTRON
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Basic interest rate: +1% every 24 hours (+0.0416% hourly)
 *   - Personal hold-bonus: +0.1% for every 24 hours without withdraw
 *   - Contract total amount bonus: +0.1% upto for every 250,000 TRX on platform address balance
 * 
 *   - Minimal deposit: 100 TRX, no maximal limit
 *   - Total income: 220% (deposit included)
 *   - Earnings every moment, withdraw any time
 * 
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 5-level referral commission: 5% - 2% - 1% - 0.5 - 0.5%
 *   
 *   [INVESTMENT CONTRIBUTIONS IF REACH 250K TRX DAILY]
 *   
 *   Top 3 contribution commission: 1.5% - 1% - 0.5%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 78% Platform main balance, participants payouts
 *	 - 9% Affiliate program bonuses
 *	 - 3% Daily top bonus
 *   - 8.5% Advertising and promotion expenses
 *   - 1.5% Support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 */

pragma solidity ^0.5.10;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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

contract GrabTron {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
	uint256 constant public BASE_PERCENT = 10;
	uint256[] public REFERRAL_PERCENTS = [50, 20, 10, 5, 5];
	uint256 constant public MARKETING_FEE = 85;
	uint256 constant public PROJECT_FEE = 15;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint constant public MAX_CONTRACT_PERCENT = 220;
	uint256 constant public CONTRACT_BALANCE_STEP = 250000 trx;  // If reach 250k TRX, contract ROI will increase by 0.1% everyday
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public projectAddress;

	uint256 public daily_balance;
    uint256[] public daily_top_bonuses=[15, 10, 5];     
    uint256 public daily_top_last_draw = block.timestamp;
    uint256 public daily_top_cycle;
	uint256 constant public QUALIFY_TOP_BONUS = 250000 trx;

    mapping(uint256 => mapping(address => uint256)) public daily_users_refs_deposits_sum;
    mapping(uint8 => address) public daily_top;

	uint public contractPercent;

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
		uint256 topsponsorbonus;
		uint256 totalWithdrawn;
		uint24[5] refs;
	}

	mapping (address => User) public users;
	mapping(address => mapping(uint256=>address)) public downline;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event DailytopPayout(address indexed user, uint256 Amount);

	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		contractPercent = getContractBalanceRate();
	}

	function invest(address referrer) public payable {
		require(!isContract(msg.sender) && msg.sender == tx.origin);
		require(msg.value >= INVEST_MIN_AMOUNT);
	
		User storage user = users[msg.sender];



		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		uint msgValue = msg.value;
		if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < 5; i++) {
                if (upline != address(0)) {

                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                    if (amount > 0) {
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                        emit RefBonus(upline, msg.sender, i, amount);
                    }

                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

			downline[referrer][users[referrer].refs[0] - 1]= msg.sender;

        }

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		

		if(daily_top_last_draw + 1 days < block.timestamp) {
            _drawTop();
        }

		_dailyDeposits(msg.sender, msg.value);

		if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {

		User storage user = users[msg.sender];


		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(22).div(10)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(22).div(10)) {     // Deposited Amount × 22 ÷ 10    // = Deposited Amount × 2.2
					dividends = (user.deposits[i].amount.mul(22).div(10)).sub(user.deposits[i].withdrawn);     // Deposited Amount × 2.2 Times Return
				}                                                                                              // Total Return = 220%

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);    // changing of storage data after withdrawal
				totalAmount = totalAmount.add(dividends);

			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		uint256 topSponsorBonus = getUserTopSponsorBonus(msg.sender);
		if (topSponsorBonus > 0) {
			totalAmount = totalAmount.add(topSponsorBonus);
			user.topsponsorbonus = 0;
		}

		

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount);

		user.totalWithdrawn = user.totalWithdrawn.add(totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function _dailyDeposits(address _addr, uint256 _amount) private {

		daily_balance += _amount;
        address upline = users[_addr].referrer;

        if(upline == address(0)) return;
        
        daily_users_refs_deposits_sum[daily_top_cycle][upline] += _amount;

		if(daily_users_refs_deposits_sum[daily_top_cycle][upline] >= QUALIFY_TOP_BONUS){
			
			for(uint8 i = 0; i < daily_top_bonuses.length; i++) {
				if(daily_top[i] == upline) break;

				if(daily_top[i] == address(0)) {
					daily_top[i] = upline;
					break;
				}

				if(daily_users_refs_deposits_sum[daily_top_cycle][upline] > daily_users_refs_deposits_sum[daily_top_cycle][daily_top[i]]) {
					for(uint8 j = i + 1; j < daily_top_bonuses.length; j++) {
						if(daily_top[j] == upline) {
							for(uint8 k = j; k <= daily_top_bonuses.length; k++) {
								daily_top[k] = daily_top[k + 1];
							}
							break;
						}
					}

					for(uint8 j = uint8(daily_top_bonuses.length - 1); j > i; j--) {
						daily_top[j] = daily_top[j - 1];
					}

					daily_top[i] = upline;

					break;
				}
			}
		}
    }

	function _drawTop() private {

        daily_top_last_draw = block.timestamp;
        daily_top_cycle++;

       	uint256 draw_amount = daily_balance;
		

			for(uint8 i = 0; i < daily_top_bonuses.length; i++) {
				if(daily_top[i] == address(0)) break;

				uint256 win = draw_amount * daily_top_bonuses[i] / PERCENTS_DIVIDER;

				users[daily_top[i]].topsponsorbonus += win;
				daily_balance = 0;

				emit DailytopPayout(daily_top[i], win);
			}
		
        
		daily_balance = 0;
        for(uint8 i = 0; i < daily_top_bonuses.length; i++) {
            daily_top[i] = address(0);
        }
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _daily_top_last_draw, uint256 _daily_balance, uint _contractPercent) {
        return (totalUsers, totalInvested, totalWithdrawn, daily_top_last_draw, daily_balance, contractPercent);
    }

	function getContractBalanceRate() internal view returns (uint) {
        uint contractBalance = address(this).balance;
        uint contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP));

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }

	function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(22).div(10)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(22).div(10)) {
					dividends = (user.deposits[i].amount.mul(22).div(10)).sub(user.deposits[i].withdrawn);
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

	function getUserInfo(address userAddress) public view returns(address _referrer, uint256 _bonus, uint256 _topsponsorbonus, uint256 _totalWithdrawn) {
		return (users[userAddress].referrer, users[userAddress].bonus, users[userAddress].topsponsorbonus, users[userAddress].totalWithdrawn);
	}
	
	function getUserDownlineInfo(address userAddress) public view returns(uint256 _level1, uint256 _level2, uint256 _level3, uint256 _level4, uint256 _level5) {
		return (users[userAddress].refs[0], users[userAddress].refs[1], users[userAddress].refs[2], users[userAddress].refs[3], users[userAddress].refs[4]);
	}

	

	 

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserTopSponsorBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].topsponsorbonus;
	}

	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress)).add(getUserTopSponsorBonus(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(22).div(10)) {
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

	function dailyTopInfo() view external returns(address[3] memory addrs, uint256[3] memory deps) {
        for(uint8 i = 0; i < daily_top_bonuses.length; i++) {
            if(daily_top[i] == address(0)) break;

            addrs[i] = daily_top[i];
            deps[i] = daily_users_refs_deposits_sum[daily_top_cycle][daily_top[i]];
        }
    }
}