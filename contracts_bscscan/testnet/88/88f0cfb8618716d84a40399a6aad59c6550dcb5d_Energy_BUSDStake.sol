/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Energy{
  function balanceOf() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Exchange{
  function getPrice() external view returns (uint256);
}

interface MasterRef{
  function getUserInfo(address user) external returns(uint256,uint256,uint256,bool);
  function addRefLevel(uint256 i, address user) external;
  function addRefBonus(uint256 i, address user , uint256 amount) external;
  function getReferralStats(address pool, address user) external returns(uint256 [] memory,uint256 [] memory, uint256, uint256);
  function addRefWithdrawn(address user , uint256 amount) external;
  function addMedal(uint256 i, address user) external;
  function setFirstPlan(address user) external;
  function getUserPlanCnt(address user) external returns(uint256);
  function setAchievement(uint256 index, uint8 value, address user) external;
}

interface IPSV2Router01 {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


contract Energy_BUSDStake {
	using SafeMath for uint256;

  	address public tokenAddr;
  	IBEP20 public token;
  	Energy public energy;
  	Exchange public exchange;
  	MasterRef public masterRef;

	uint256[] public STAKE_MIN_AMOUNT = [50 ether, 100 ether, 1000 ether];
	uint256[] public STAKE_MAX_AMOUNT = [1000 ether, 5000 ether, 20000 ether];
	uint256[] public REFERRAL_PERCENTS = [250, 150, 50, 30, 20];
	uint256[] public REFERRAL_LEVELS = [1,3,5];
	uint256[] public MEDAL_PERCENTS = [30, 50, 70];
	uint256 constant public PROJECT_FEE = 450;
	uint256 constant public DEV_FEE = 50;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	// uint256 constant public TIME_STEP = 1 days;
	uint256 constant public TIME_STEP = 3600;
	uint256 constant public TURBO_PERCENT = 200;
	uint256 constant public TOTAL_DEPOSITS = 100;

	uint256 public totalStaked;
	uint256 public totalDeposits;
	uint256 public totalUsers;
	uint256 public totalTurbos;
	
	struct Plan {
		uint256 time;
		uint256 percent;
	}

  	Plan[] internal plans;

	struct Turbo {
		uint256 price;
		uint256 start;
		uint256 finish;
	}

	struct Deposit {
		uint256 id;
		uint8   plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 withdrawn;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[]	deposits;
		uint256     checkpoint;
		address     referrer;
		bool    	status;
	}

	mapping (address => User) public users;
  	mapping (uint256 => Turbo[]) public turbos;

	uint256 public startUNIX;
	address payable public projectWallet;
	address payable public devWallet;
	address public masterChef;

	//testnet
	address constant public _psRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
	//mainnet
	// address constant public _psRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
	IPSV2Router01    public _psRouter;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event WithdrawnRef(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address tokenAddress, address energyAddress, address exchangeAddress, address masterRefAddress, address masterChefAddress, address payable projectAddress, address payable devAddress, uint256 startDate) {
		require(!isContract(projectAddress),"unvalid project address");
		require(!isContract(devAddress),"unvalid dev address");
		require(energyAddress != address(0),"unvalid energy address");
		require(tokenAddress != address(0),"unvalid token address");
		require(exchangeAddress != address(0),"unvalid exchange address");
		require(masterRefAddress != address(0),"unvalid MasterRef address");
		require(masterChefAddress != address(0),"unvalid MasterChef address");
		require(startDate > 0);
		projectWallet = projectAddress;
		devWallet = devAddress;
		startUNIX = startDate;

		tokenAddr = tokenAddress;
		token = IBEP20(tokenAddress);
		energy = Energy(energyAddress);
		exchange = Exchange(exchangeAddress);
		masterRef = MasterRef(masterRefAddress);
		masterChef = masterChefAddress;

		_psRouter = IPSV2Router01(_psRouterAddress);

		plans.push(Plan(10, 1200));
		plans.push(Plan(20, 720));
		plans.push(Plan(30, 583));
	}

	function stake(address referrer, uint8 plan, uint256 amount) public payable {
		require(block.timestamp > startUNIX," the pool is not active yet ");
		
    	require(plan < 3, "Invalid plan");
		require(amount >= STAKE_MIN_AMOUNT[plan]," the amount is less than the minimum ");
		require(amount <= STAKE_MAX_AMOUNT[plan]," the amount is greater than the maxmimum ");
		require(amount <= token.balanceOf(msg.sender), "insufficient amount");
		
		User storage user = users[msg.sender];
    
		require(user.deposits.length < TOTAL_DEPOSITS ,"the maximum deposit number reached");
		require(!user.status," only one deposit can be active at the same time in each plan ");
		user.status = true;

		uint256[3] memory medals;
		(medals[0],medals[1],medals[2],) = masterRef.getUserInfo(msg.sender);

		if(plan == 1)
			require(medals[0] > 0," first, you need to pass plan 1 and earn a medal M1 ");

		if(plan == 2)
			require(medals[1] > 0," first, you need to pass plan 2 and earn a medal M2 ");

		token.transferFrom(msg.sender, address(this), amount);

		if (user.referrer == address(0)) {
			if (referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					masterRef.addRefLevel(i,upline);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					uint256 amountR = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					masterRef.addRefBonus(i,upline,amountR);
					emit RefBonus(upline, upline, i, amountR);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
      		totalUsers += 1;
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
			masterRef.setFirstPlan(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, amount, medals);
    	totalDeposits += 1;
		user.deposits.push(Deposit(totalDeposits, plan, percent, amount, profit, 0, block.timestamp, finish));

		totalStaked = totalStaked.add(amount);
		emit NewDeposit(msg.sender, plan, percent, amount, profit, block.timestamp, finish);


		
		//achievements
		uint256 userPlanCnt = masterRef.getUserPlanCnt(msg.sender);
		if(userPlanCnt == 0){
			if(_getBnBAmount(amount) >= (exchange.getPrice().mul(10))){
				masterRef.setAchievement(0, 1, msg.sender);
			}
			else{
				masterRef.setAchievement(0, 3, msg.sender);
			}
		}
		else if(userPlanCnt == 1){
			if(_getBnBAmount(amount) >= (exchange.getPrice().mul(50))){
				masterRef.setAchievement(1, 1, msg.sender);
			}
			else{
				masterRef.setAchievement(1, 3, msg.sender);
			}
		}
		else if(userPlanCnt == 2){
			if(_getBnBAmount(amount) >= (exchange.getPrice().mul(100))){
				masterRef.setAchievement(2, 1, msg.sender);
			}
			else{
				masterRef.setAchievement(2, 3, msg.sender);
			}
		}
	}

	function runTurbo(uint256 depositId) public {
		require(depositId <= totalDeposits, " Invalid Deposiot ID ");

		User storage user = users[msg.sender];
		uint256 id = 0;
		bool valid = false;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if(user.deposits[i].id == depositId){
				id = i;
				valid=true;
			}
		}
		require(valid == true, "deposit id does not belong to the caller user");
		require( block.timestamp < user.deposits[id].finish, "expired deposit");

		Turbo[] storage turbo = turbos[depositId];
		if(turbo.length > 0){
			require( block.timestamp >  turbo[turbo.length-1].finish, "only one turbo allowed at the same time");
		}

		uint256 turboPrice = getTurboPrice(user.deposits[id].amount);
		require(turboPrice > 0, "invalid energy price");
		//transfer turbo energy to Energy Staking Pool
		energy.transferFrom(msg.sender, masterChef, turboPrice);

		totalTurbos++;
		turbos[depositId].push(Turbo(turboPrice,block.timestamp, block.timestamp.add(TIME_STEP)));

	}

	function getTurboPrice(uint256 amount) public view returns (uint256){

		uint256 bnbAmount = _getBnBAmount(amount);

		uint256 lastPrice = exchange.getPrice();
		if(lastPrice > 0){
			return (
				(bnbAmount.mul(10**18).mul(TURBO_PERCENT).div(PERCENTS_DIVIDER)).div(lastPrice).div(2)
			);
		}
		else{
			return 0;
		}

	}

	function _getBnBAmount(uint256 tokenAmount) private view returns(uint256) {
        address[] memory path = new address[](2);

        path[0] = tokenAddr;
        path[1] = _psRouter.WETH();

        uint[] memory amounts = _psRouter.getAmountsOut(tokenAmount, path);

        return amounts[1];
    }

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = updateUserDividends(msg.sender);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		
		uint256 feeP = totalAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		token.transfer(projectWallet, feeP);
		uint256 feeD = totalAmount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		token.transfer(devWallet, feeD);
		emit FeePayed(msg.sender, feeP.add(feeD));

		totalAmount = totalAmount.sub(feeP.add(feeD));
		token.transfer(msg.sender, totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function withdrawRef() public {
		(,,,uint256 totalAmount) = masterRef.getReferralStats(address(this),msg.sender);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		masterRef.addRefWithdrawn(msg.sender,totalAmount);
		token.transfer(msg.sender, totalAmount);
		emit WithdrawnRef(msg.sender, totalAmount);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan, uint256[3] memory medals) public view returns (uint256) {
		uint256 percent = plans[plan].percent;
		for (uint256 i = 0; i < 3; i++) {
			if(medals[i] > 0){
				percent = percent.add(MEDAL_PERCENTS[i]);
			}
		}

		return percent;
  	}

	function getResult(uint8 plan, uint256 deposit, uint256[3] memory medals) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		if (plan < 3) {
			percent = getPercent(plan,medals);
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
			finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
		uint256 turboDividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				uint256 share = user.deposits[i].profit.div(plans[user.deposits[i].plan].time);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
				turboDividends = getTruboDividends(user.deposits[i].id, from, to, user.deposits[i].amount);
				if(turboDividends > 0){
					totalAmount = totalAmount.add(turboDividends);
				}
			}
		}

		return totalAmount;
	}

	function updateUserDividends(address userAddress) internal returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
		uint256 turboDividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				uint256 share = user.deposits[i].profit.div(plans[user.deposits[i].plan].time);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
				turboDividends = getTruboDividends(user.deposits[i].id, from, to, user.deposits[i].amount);
				if(turboDividends > 0){
					totalAmount = totalAmount.add(turboDividends);
				}
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(totalAmount);

				if(user.deposits[i].finish < block.timestamp ){
					user.status = false;
					masterRef.addMedal(user.deposits[i].plan, msg.sender);
					masterRef.setAchievement(5, 1, msg.sender);
				}
			}
		}

		return totalAmount;
	}

	function getTruboDividends(uint256 depositId, uint256 dFrom, uint256 dTo, uint256 amount) internal view returns (uint256) {
		Turbo[] storage turbo = turbos[depositId];

		uint256 totalTurboDividends;

		for (uint256 i = 0; i < turbo.length; i++) {
			if ( (turbo[i].start >= dFrom && turbo[i].start < dTo) ||
				 (turbo[i].finish > dFrom && turbo[i].finish <= dTo) ||
				 (turbo[i].start <= dFrom && turbo[i].finish >= dTo)
			 ) {
				uint256 share = amount.mul(TURBO_PERCENT).div(PERCENTS_DIVIDER);
				uint256 from = turbo[i].start > dFrom ? turbo[i].start : dFrom;
				uint256 to = turbo[i].finish < dTo ? turbo[i].finish : dTo;
				if (from < to) {
					totalTurboDividends = totalTurboDividends.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalTurboDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserDividends(userAddress);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].withdrawn);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256 id, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 withdrawn, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		id = user.deposits[index].id;
		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		withdrawn = user.deposits[index].withdrawn;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function getLastUserDepositInfo(address userAddress) public view returns(uint256 id, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 withdrawn, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];
		uint256 index = user.deposits.length.sub(1);

		id = user.deposits[index].id;
		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		withdrawn = user.deposits[index].withdrawn;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function getTurboStatus(uint256 depositId) public view returns(bool) {
	    Turbo[] memory turbo = turbos[depositId];
		if(turbo.length > 0){
			if( block.timestamp <=  turbo[turbo.length-1].finish && block.timestamp >=  turbo[turbo.length-1].start){
				return true;
			}
			else{
				return false;
			}
		}
		else{
			return false;
		}
	}

	

	function getTurboLength(uint256 depositId) public view returns(uint256) {
	    Turbo[] memory turbo = turbos[depositId];
		return turbo.length;
	}

	function getUserStatus(address userAddress) public view returns(bool) {
	    User storage user = users[userAddress];
		return (user.status);
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
  	}

	
	  
  	function setMasterchef(address payable masterchefAddr) public {
		require(msg.sender == projectWallet, "only owner");
		if(masterchefAddr != address(0)){
			masterChef = masterchefAddr;
		}
  	}

	  	  
  	function setExchange(address exchangeAddress) public {
		require(msg.sender == projectWallet, "only owner");
		if(exchangeAddress != address(0)){
			exchange = Exchange(exchangeAddress);
		}
  	}
}

/* © 2021 by S&S8712943. All rights reserved. */