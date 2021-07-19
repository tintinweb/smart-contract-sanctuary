//SourceUnit: ITRC20.sol

pragma solidity  >=0.5.0 <0.7.0;
interface ITRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool success);
    function burnFrom(address _from, uint256 _value) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value); 
}


//SourceUnit: JstKing.sol

pragma solidity ^0.5.10;

import "./ITRC20.sol";
import "./SafeMath.sol";

contract JstKing{
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100*10**uint256(18);
	uint256[] public REFERRAL_PERCENTS = [30, 20, 10];
	uint256 constant public ADMIN_FEE = 100;
	uint256 constant public ZONE_POOL_PERCENT = 60;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalStaked;

	struct Plan {
	    uint256 time;
	    uint256 percent;
	}

	Plan[] internal plans;

	struct Deposit {
        	uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalAirdropWithdrawn;
		uint256 familyNum; 
		uint256 familyDeposit;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public commissionWallet; //10%
	address payable public zonePoolWallet;   //6%
	address payable public retailReferWallet;//6%
	ITRC20 jst;
	ITRC20 jkc;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event AirdropWithdrawn(address indexed user, uint256 amount);

	constructor(address payable adminWallet, address payable zoneWallet, address payable retailWallet, address JSTAddress, address JKCTokenAddress, uint256 startDate) public {
		require(!isContract(adminWallet));
		require(!isContract(zoneWallet));
		require(startDate > 0);
		commissionWallet = adminWallet;
		zonePoolWallet = zoneWallet;
		retailReferWallet = retailWallet;
		startUNIX = startDate;

		plans.push(Plan(14, 80));
		plans.push(Plan(21, 65));
		plans.push(Plan(28, 50));
		plans.push(Plan(14, 80));
		plans.push(Plan(21, 65));
		plans.push(Plan(28, 50));

		jkc = ITRC20(JKCTokenAddress);
		jst = ITRC20(JSTAddress);
	}

	function invest(address referrer, uint256 deposit_amount, uint8 plan) public payable {
		require(deposit_amount >= INVEST_MIN_AMOUNT);
        	require(plan < 6, "Invalid plan");

		//deposit JST to contract address
		jst.transferFrom(msg.sender, address(this), deposit_amount);

		uint256 fee = deposit_amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER);
		jst.transfer(commissionWallet, fee);
		emit FeePayed(msg.sender, fee);

		uint256 zonePoolAmount  = deposit_amount.mul(ZONE_POOL_PERCENT).div(PERCENTS_DIVIDER);
		jst.transfer(zonePoolWallet, zonePoolAmount);

		if(referrer == retailReferWallet)
		{
			jst.transfer(retailReferWallet, zonePoolAmount);
		}

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 30; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					users[upline].familyNum = users[upline].familyNum.add(1);
					users[upline].familyDeposit = users[upline].familyDeposit.add(deposit_amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 30; i++) {
				if (upline != address(0)) {
					uint256 amount = deposit_amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					if(amount > 0)
					{
						users[upline].bonus = users[upline].bonus.add(amount);
						users[upline].totalBonus = users[upline].totalBonus.add(amount);
						emit RefBonus(upline, msg.sender, i, amount);
					}
					users[upline].familyNum = users[upline].familyNum.add(1);
					users[upline].familyDeposit = users[upline].familyDeposit.add(deposit_amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			user.totalAirdropWithdrawn = 0;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, deposit_amount);
		user.deposits.push(Deposit(plan, percent, deposit_amount, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(deposit_amount);
		users[msg.sender].familyNum = users[msg.sender].familyNum.add(1);
		users[msg.sender].familyDeposit = users[msg.sender].familyDeposit.add(deposit_amount);
		emit NewDeposit(msg.sender, plan, percent, deposit_amount, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = jst.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}


		jst.transfer(msg.sender, totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

		uint256 totalAirdrop = getUserAvailableAirdrops(msg.sender);
		uint256 contractJKCBalance = jkc.balanceOf(address(this));
		if (contractJKCBalance < totalAirdrop) {
			totalAirdrop = contractJKCBalance;
		}
		user.totalAirdropWithdrawn = user.totalAirdropWithdrawn.add(totalAirdrop);

		user.checkpoint = block.timestamp;

		jkc.transfer(msg.sender, totalAirdrop);

		emit AirdropWithdrawn(msg.sender, totalAirdrop);

	}

	function getContractBalance() public view returns (uint256) {
		return jst.balanceOf(address(this));
	}

	function getZoneRewardPoolBalance() public view returns (uint256) {
		return jst.balanceOf(zonePoolWallet);
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);

		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 3) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
				}
			}
		}

		return totalAmount;
	}

	function getUserAvailableAirdrops(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 3) {
					uint256 share = user.deposits[i].amount.div(100).div(100); //1% per day
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				} else {
					uint256 share = user.deposits[i].amount.div(50).div(100); //1% per day
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				}
			}
		}

		return totalAmount;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDepositCount(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}
	function getUserFamilyInfo(address userAddress) public view returns(uint256 totalNum, uint256 totalDeposit) {
		totalNum = users[userAddress].familyNum;
		totalDeposit = users[userAddress].familyDeposit;
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
	function getUserTotalAirdrops(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			if(users[userAddress].deposits[i].plan < 3)
				amount = amount.add(users[userAddress].deposits[i].amount.div(100));
			else
				amount = amount.add(users[userAddress].deposits[i].amount.div(50));
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity  >=0.5.0 <0.7.0;
library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

  /**
   * @dev gives square root of given x.
   */
  function sqrt(uint256 x)
  internal
  pure
  returns(uint256 y) {
    uint256 z = ((add(x, 1)) / 2);
    y = x;
    while (z < y) {
      y = z;
      z = ((add((x / z), z)) / 2);
    }
  }

  /**
   * @dev gives square. multiplies x by x
   */
  function sq(uint256 x)
  internal
  pure
  returns(uint256) {
    return (mul(x, x));
  }

  /**
   * @dev x to the power of y
   */
  function pwr(uint256 x, uint256 y)
  internal
  pure
  returns(uint256) {
    if (x == 0)
      return (0);
    else if (y == 0)
      return (1);
    else {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z, x);
      return (z);
    }
  }
}