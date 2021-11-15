// SPDX-License-Identifier: WTFPL
pragma solidity >=0.6.0;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "../interfaces/IMasterShepherd.sol";
import "./VIPLevels.sol";

// import "hardhat/console.sol";

contract LamaVaults {
	using SafeMath for uint256;
	using SafeBEP20 for IBEP20;

	// Info of each user.
	struct UserInfo {
		uint256 amount; // How many LP tokens the user has provided.
		uint256 lamaRewardDebt; // Lama reward debt.
		uint256 extraRewardDebt; // Reward token reward debt.
		uint256 lastDepositTime; // keeps track of deposit time for potential penalty
	}

	// Info of each pool.
	struct PoolInfo {
		IBEP20 lpToken; // Address of LP token contract.
		IBEP20 rewardToken; // Address of the extra reward token contract.
		uint16 vipLevel; // required vip level
		uint256 lamaAllocPoint; // How many allocation points assigned to this pool (for LAMA reward)
		uint256 rewardAllocPoint; // How many allocation points assigned to this pool (for extra reward)
		uint256 lamaLastRewardBlock; // Last block number that Lama distribution occurs.
		uint256 rewardTokenLastRewardBlock; // Last block number that Reward Token distribution occurs.
		uint256 accLamaPerShare; // Accumulated Lamas per share, times 1e12.
		uint256 accRewardPerShare; // Accumulated Reward per share, times 1e12.
		uint256 totalDepositAmt; // Current total deposit amount in this pool
	}

	struct PoolFees {
		uint256 lockPeriod; // no unstake / no harvest period
		uint16 unstakeFeeBP; // Unstake fee in basis points
		uint16 harvestFeeBP; // Harvest fee in basis points
		uint256 unstakeFeeDuration; // Duration after which no withdrawal fees are applied
		uint256 harvestFeeDuration; // Duration after which no harvest fees are applied
	}

	uint256 public constant BASIS_POINTS = 1000;
	uint256 public MAX_LOCK_PERIOD = 7 days;
	uint256 public MAX_WITHDRAW_PERIOD = 60 days;

	// MasterShep V1 contract
	IMasterShepherd public msV1;
	// msV1 linked pool id
	uint256 public msV1pid;
	bool public msV1Linked;

	address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

	uint256 public bsc_seconds_per_block = 3;

	// The LAMA TOKEN
	IBEP20 public immutable lama;

	uint256 public lamaReceived;
	uint256 public lamaHarvested;

	address public adminAddress;
	address public feeAddress;
	// LAMA tokens rewarded per block
	uint256 _lamaPerBlock = 0.5 ether;

	// Reward tokens distribution rate.
	mapping(IBEP20 => uint256) public rewardTokenEmissionPerBlock;
	// Reward tokens balance
	mapping(IBEP20 => uint256) public rewardTokenBalance;
	// Reward tokens end block
	mapping(IBEP20 => uint256) public rewardTokenEndBlock;
	// List of reward tokens
	mapping(IBEP20 => bool) public isRewardToken;

	// LAMA VIP level contract
	IVIPLevels public vipLevels;

	bool public emergencyWithdrawFeesWaived = false;

	// Info of each pool.
	PoolInfo[] public poolInfo;
	PoolFees[] public poolFees;

	// Info of each user that stakes LP tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;

	// whitelisted contracts
	mapping(address => bool) public whitelist;
	// privileged access
	mapping(address => bool) public authorized;

	// to check if a pool with a given IBEP20 exists
	mapping(IBEP20 => bool) public tokenList;
	// Total allocation points for Lama. It's the sum of all allocation points in all pools
	uint256 public lamaTotalAllocPoint = 0;

	mapping(IBEP20 => uint256) public rewardTotalAllocPoint; // total allocation points per reward token

	// The block number when Wool mining starts
	uint256 public startBlock;

	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyBEP20Drain(address token, address recipient, uint256 amount);
	event RewardWithdraw(address indexed user, uint256 amount);

	constructor(
		IBEP20 _lama,
		IVIPLevels _vipLevels,
		address _feeAddress,
		uint256 _startBlock
	) public {
		lama = _lama;
		vipLevels = _vipLevels;
		startBlock = _startBlock;
		feeAddress = _feeAddress;
		adminAddress = msg.sender;
	}

	/**
	 * @notice Checks if the msg.sender is a contract or a proxy
	 */
	modifier notContract() {
		require(!_isContract(msg.sender) || whitelist[msg.sender], "contract not allowed");
		require(msg.sender == tx.origin, "proxy contract not allowed");
		_;
	}

	/**
	 * @notice Checks if address is a contract
	 * @dev It prevents contract from being targetted
	 */
	function _isContract(address addr) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(addr)
		}
		return size > 0;
	}

	modifier adminOnly() {
		require(msg.sender == adminAddress, "Unauthorized");
		_;
	}

	modifier minVipLevel(uint256 _pid) {
		PoolInfo storage pool = poolInfo[_pid];
		require(vipLevels.getVipLevel(msg.sender) >= pool.vipLevel || authorized[msg.sender], "Inadequate VIP level");
		_;
	}

	function poolLength() external view returns (uint256) {
		return poolInfo.length;
	}

	/**
	 * @notice Add a new lp to the pool
	 * @dev Can only be called by the owner
	 */
	function addPool(
		uint16 _vipLevel,
		IBEP20 _lpToken,
		IBEP20 _rewardToken,
		uint256 _lamaAllocPoint,
		uint256 _rewardAllocPoint,
		uint256 _lockPeriodInHours,
		uint16 _unstakeFeeBP,
		uint256 _unstakeFeeDurationInDays,
		uint16 _harvestFeeBP,
		uint256 _harvestFeeDurationInDays,
		bool _withUpdate
	) public adminOnly {
		require((_lockPeriodInHours * 1 hours) <= MAX_LOCK_PERIOD, "lock > MAX_LOCK_PERIOD");
		require((_unstakeFeeDurationInDays * 1 days) <= MAX_WITHDRAW_PERIOD, "unstake fee > MAX_WITHDRAW_PERIOD");
		require((_harvestFeeDurationInDays * 1 days) <= MAX_WITHDRAW_PERIOD, "harvest fee > MAX_WITHDRAW_PERIOD");
		if (_withUpdate) {
			massUpdatePools();
		}

		lamaTotalAllocPoint = lamaTotalAllocPoint.add(_lamaAllocPoint);
		rewardTotalAllocPoint[_rewardToken] = rewardTotalAllocPoint[_rewardToken].add(_rewardAllocPoint);
		tokenList[_lpToken] = true;
		isRewardToken[_rewardToken] = true;

		poolInfo.push(
			PoolInfo({
				lpToken: _lpToken,
				rewardToken: _rewardToken,
				lamaAllocPoint: _lamaAllocPoint,
				rewardAllocPoint: _rewardAllocPoint,
				lamaLastRewardBlock: block.number > startBlock ? block.number : startBlock,
				rewardTokenLastRewardBlock: block.number > startBlock ? block.number : startBlock,
				accLamaPerShare: 0,
				accRewardPerShare: 0,
				totalDepositAmt: 0,
				vipLevel: _vipLevel
			})
		);
		poolFees.push(
			PoolFees({
				lockPeriod: _lockPeriodInHours * 1 hours,
				unstakeFeeBP: _unstakeFeeBP,
				unstakeFeeDuration: _unstakeFeeDurationInDays * 1 days,
				harvestFeeBP: _harvestFeeBP,
				harvestFeeDuration: _harvestFeeDurationInDays * 1 days
			})
		);
	}

	function setPool(
		uint256 _pid,
		uint16 _vipLevel,
		uint256 _lamaAllocPoint,
		uint256 _rewardAllocPoint,
		uint256 _lockPeriodInHours,
		uint16 _unstakeFeeBP,
		uint256 _unstakeFeeDurationInDays,
		uint16 _harvestFeeBP,
		uint256 _harvestFeeDurationInDays,
		bool _withUpdate
	) public adminOnly {
		require((_lockPeriodInHours * 1 hours) <= MAX_LOCK_PERIOD, "lock > MAX_LOCK_PERIOD");
		require((_unstakeFeeDurationInDays * 1 days) <= MAX_WITHDRAW_PERIOD, "unstake fee > MAX_WITHDRAW_PERIOD");
		require((_harvestFeeDurationInDays * 1 days) <= MAX_WITHDRAW_PERIOD, "harvest fee > MAX_WITHDRAW_PERIOD");
		if (_withUpdate) {
			massUpdatePools();
		}
		PoolInfo storage pool = poolInfo[_pid];
		lamaTotalAllocPoint = lamaTotalAllocPoint.sub(pool.lamaAllocPoint).add(_lamaAllocPoint);
		rewardTotalAllocPoint[pool.rewardToken] = rewardTotalAllocPoint[pool.rewardToken]
			.sub(pool.rewardAllocPoint)
			.add(_rewardAllocPoint);

		pool.vipLevel = _vipLevel;
		pool.lamaAllocPoint = _lamaAllocPoint;
		pool.rewardAllocPoint = _rewardAllocPoint;

		poolFees[_pid].lockPeriod = _lockPeriodInHours * 1 hours;
		poolFees[_pid].unstakeFeeBP = _unstakeFeeBP;
		poolFees[_pid].unstakeFeeDuration = _unstakeFeeDurationInDays * 1 days;
		poolFees[_pid].harvestFeeBP = _harvestFeeBP;
		poolFees[_pid].harvestFeeDuration = _harvestFeeDurationInDays * 1 days;
	}

	// Return reward multiplier over the given _from to _to block.
	function getMultiplier(
		uint256 _from,
		uint256 _to,
		uint256 _endBlock
	) public pure returns (uint256) {
		if (_endBlock == 0 || _to <= _endBlock) {
			return _to.sub(_from);
		}
		if (_from >= _endBlock) {
			return 0;
		}
		return _endBlock.sub(_from);
	}

	function lamaPerBlock() public view returns (uint256) {
		return msV1Linked ? _lamaPerBlock : 0;
	}

	function pendingRewards(uint256 _pid, address _user)
		external
		view
		returns (uint256 pendingLamas, uint256 pendingRewardTokens)
	{
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];
		uint256 accLamaPerShare = pool.accLamaPerShare;
		uint256 accRewardPerShare = pool.accRewardPerShare;
		uint256 lpTotal = pool.totalDepositAmt;

		if (lpTotal != 0) {
			uint256 rewardTokenTotalAllocPoint = rewardTotalAllocPoint[pool.rewardToken];
			uint256 multiplier;
			uint256 reward;
			if (block.number > pool.lamaLastRewardBlock && lamaTotalAllocPoint != 0) {
				multiplier = getMultiplier(pool.lamaLastRewardBlock, block.number, 0);
				reward = multiplier.mul(lamaPerBlock()).mul(pool.lamaAllocPoint).div(lamaTotalAllocPoint);
				accLamaPerShare = accLamaPerShare.add(reward.mul(1e12).div(lpTotal));
			}
			if (block.number > pool.rewardTokenLastRewardBlock && rewardTokenTotalAllocPoint != 0) {
				multiplier = getMultiplier(
					pool.rewardTokenLastRewardBlock,
					block.number,
					rewardTokenEndBlock[pool.rewardToken]
				);

				reward = multiplier.mul(rewardTokenEmissionPerBlock[pool.rewardToken]).mul(pool.rewardAllocPoint).div(
					rewardTokenTotalAllocPoint
				);
				accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(lpTotal));
			}
		}

		pendingLamas = user.amount.mul(accLamaPerShare).div(1e12).sub(user.lamaRewardDebt);
		pendingRewardTokens = user.amount.mul(accRewardPerShare).div(1e12).sub(user.extraRewardDebt);
	}

	// Update reward variables for all pools
	function massUpdatePools() public {
		uint256 length = poolInfo.length;
		for (uint256 pid = 0; pid < length; ++pid) {
			updatePool(pid);
		}
	}

	function refillReward(
		IBEP20 _rewardToken,
		uint256 _amount,
		uint256 _rewardDurationInDays
	) external {
		require(msg.sender == adminAddress || authorized[msg.sender], "Unauthorized");
		require(isRewardToken[_rewardToken], "Not a reward token");
		require(_amount > 0, "Amount must be > 0");
		_rewardToken.transferFrom(msg.sender, address(this), _amount);

		rewardTokenBalance[_rewardToken] = rewardTokenBalance[_rewardToken].add(_amount);
		massUpdatePools();

		uint256 previousEndBlock = rewardTokenEndBlock[_rewardToken];
		// if already ended
		if (block.number > previousEndBlock) {
			previousEndBlock = block.number;
		}
		uint256 estimatedDurationInBlocks = (_rewardDurationInDays * 1 days).div(bsc_seconds_per_block);
		rewardTokenEndBlock[_rewardToken] = previousEndBlock.add(estimatedDurationInBlocks);

		rewardTokenEmissionPerBlock[_rewardToken] = rewardTokenBalance[_rewardToken].div(
			rewardTokenEndBlock[_rewardToken].sub(block.number)
		);
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool(uint256 _pid) public {
		PoolInfo storage pool = poolInfo[_pid];
		uint256 lpTotal = pool.totalDepositAmt;
		uint256 multiplier;
		uint256 reward;

		if (block.number > pool.lamaLastRewardBlock) {
			if (lpTotal == 0 || pool.lamaAllocPoint == 0) {
				pool.lamaLastRewardBlock = block.number;
			} else {
				multiplier = getMultiplier(pool.lamaLastRewardBlock, block.number, 0);
				reward = multiplier.mul(lamaPerBlock()).mul(pool.lamaAllocPoint).div(lamaTotalAllocPoint);

				pool.accLamaPerShare = pool.accLamaPerShare.add(reward.mul(1e12).div(lpTotal));
				pool.lamaLastRewardBlock = block.number;

				// withdraw all pending rewards from MasterShepherdV1
				uint256 lamaInitialBal = lama.balanceOf(address(this));
				msV1.withdraw(msV1pid, 0);
				lamaReceived = lamaReceived.add(lama.balanceOf(address(this)).sub(lamaInitialBal));
			}
		}
		if (block.number > pool.rewardTokenLastRewardBlock) {
			if (lpTotal == 0 || pool.rewardAllocPoint == 0) {
				pool.rewardTokenLastRewardBlock = block.number;
			} else {
				multiplier = getMultiplier(
					pool.rewardTokenLastRewardBlock,
					block.number,
					rewardTokenEndBlock[pool.rewardToken]
				);
				reward = multiplier.mul(rewardTokenEmissionPerBlock[pool.rewardToken]).mul(pool.rewardAllocPoint).div(
					rewardTotalAllocPoint[pool.rewardToken]
				);

				pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(lpTotal));
				pool.rewardTokenLastRewardBlock = block.number;
			}
		}
	}

	/**
	 * @notice Deposit LP tokens into the Vault
	 */
	function deposit(uint256 _pid, uint256 _amount) public notContract minVipLevel(_pid) {
		require(_amount > 0, "Insufficient amount");

		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		updatePool(_pid);

		pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
		pool.totalDepositAmt = pool.totalDepositAmt.add(_amount);

		user.amount = user.amount.add(_amount);
		user.lamaRewardDebt = user.amount.mul(pool.accLamaPerShare).div(1e12);
		user.extraRewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
		user.lastDepositTime = block.timestamp;

		emit Deposit(msg.sender, _pid, _amount);
	}

	/**
	 * @notice Withdraw LP tokens from the Vault
	 */
	function withdraw(uint256 _pid, uint256 _amount) public notContract minVipLevel(_pid) {
		require(_amount > 0, "Invalid amount");
		PoolInfo storage pool = poolInfo[_pid];
		PoolFees storage pfees = poolFees[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		require(block.timestamp > user.lastDepositTime.add(pfees.lockPeriod), "Withdrawal lock period");
		require(user.amount >= _amount, "withdraw: not good");
		updatePool(_pid);

		user.amount = user.amount.sub(_amount);
		user.lamaRewardDebt = user.amount.mul(pool.accLamaPerShare).div(1e12);
		user.extraRewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
		pool.totalDepositAmt = pool.totalDepositAmt.sub(_amount);

		uint256 taxedAmount = _getFees(
			_amount,
			pfees.unstakeFeeBP,
			pfees.unstakeFeeDuration,
			pfees.lockPeriod,
			user.lastDepositTime
		);
		safeIBep20Transfer(pool.lpToken, feeAddress, taxedAmount);
		safeIBep20Transfer(pool.lpToken, msg.sender, _amount.sub(taxedAmount));

		emit Withdraw(msg.sender, _pid, _amount);
	}

	function harvest(uint256 _pid) public notContract minVipLevel(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		PoolFees storage pfees = poolFees[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		require(block.timestamp > user.lastDepositTime.add(pfees.lockPeriod), "Harvest lock period");
		updatePool(_pid);

		uint256 pendingLamaAmount = user.amount.mul(pool.accLamaPerShare).div(1e12).sub(user.lamaRewardDebt);
		uint256 pendingRewardAmount = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.extraRewardDebt);
		uint256 taxedAmount;
		if (pendingLamaAmount > 0) {
			taxedAmount = _getFees(
				pendingLamaAmount,
				pfees.harvestFeeBP,
				pfees.harvestFeeDuration,
				pfees.lockPeriod,
				user.lastDepositTime
			);
			safeIBep20Transfer(lama, BURN_ADDRESS, taxedAmount);
			safeIBep20Transfer(lama, msg.sender, pendingLamaAmount.sub(taxedAmount));
			lamaHarvested = lamaHarvested.add(pendingLamaAmount);
		}
		if (pendingRewardAmount > 0) {
			taxedAmount = _getFees(
				pendingRewardAmount,
				pfees.harvestFeeBP,
				pfees.harvestFeeDuration,
				pfees.lockPeriod,
				user.lastDepositTime
			);
			safeIBep20Transfer(pool.rewardToken, feeAddress, taxedAmount);
			safeIBep20Transfer(pool.rewardToken, msg.sender, pendingRewardAmount.sub(taxedAmount));
			rewardTokenBalance[pool.rewardToken] = rewardTokenBalance[pool.rewardToken].sub(pendingRewardAmount);
		}
		user.lamaRewardDebt = user.amount.mul(pool.accLamaPerShare).div(1e12);
		user.extraRewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
	}

	function _getFees(
		uint256 amount,
		uint256 maxFee,
		uint256 maxDuration,
		uint256 lockPeriod,
		uint256 lastDepositTime
	) internal view returns (uint256) {
		maxFee = maxFee.mul(1e12);
		uint256 timeElapsed = block.timestamp.sub(lastDepositTime);
		timeElapsed = timeElapsed < lockPeriod ? 0 : timeElapsed.sub(lockPeriod);
		if (timeElapsed > maxDuration) return 0;
		uint256 feePerTimeUnit = maxFee.div(maxDuration);
		uint256 waivedFees = feePerTimeUnit.mul(timeElapsed);
		uint256 feesBP = maxFee.sub(waivedFees);
		if (feesBP == 0) return 0;
		return amount.mul(feesBP).div(1e12 * BASIS_POINTS);
	}

	/**
	 * @notice Withdraw without caring about rewards. Early unstaking fees still apply, unless emergencyWithdrawFeesWaived is set to true. EMERGENCY ONLY.
	 */
	function emergencyWithdraw(uint256 _pid) external {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		uint256 taxedAmount = 0;
		uint256 amount = user.amount;
		user.amount = 0;
		user.lamaRewardDebt = 0;
		user.extraRewardDebt = 0;
		pool.totalDepositAmt = pool.totalDepositAmt.sub(amount);

		if (!emergencyWithdrawFeesWaived) {
			PoolFees storage pfees = poolFees[_pid];
			taxedAmount = _getFees(
				amount,
				pfees.unstakeFeeBP,
				pfees.unstakeFeeDuration,
				pfees.lockPeriod,
				user.lastDepositTime
			);
			safeIBep20Transfer(pool.lpToken, feeAddress, taxedAmount);
		}

		safeIBep20Transfer(pool.lpToken, msg.sender, amount.sub(taxedAmount));
		emit EmergencyWithdraw(msg.sender, _pid, amount);
	}

	function setAdminAddress(address _adminAddress) public adminOnly {
		adminAddress = _adminAddress;
	}

	function setFeeAddress(address _feeAddress) public adminOnly {
		feeAddress = _feeAddress;
	}

	/**
	 * @notice  Safe token transfer function, just in case if rounding error causes contract not to have enough tokens.
	 */
	function safeIBep20Transfer(
		IBEP20 _token,
		address _to,
		uint256 _amount
	) internal {
		if (_amount == 0) return;
		uint256 balance = _token.balanceOf(address(this));
		if (_amount > balance) {
			_token.transfer(_to, balance);
		} else {
			_token.transfer(_to, _amount);
		}
	}

	function updateLamaEmissionRate(uint256 _newLamaPerBlock) external adminOnly {
		massUpdatePools();
		_lamaPerBlock = _newLamaPerBlock;
	}

	function setStartBlock(uint256 _newStartBlock) external adminOnly {
		require(startBlock == 0 || block.number < startBlock, "already started");
		require(_newStartBlock > block.number, "invalid start block");
		startBlock = _newStartBlock;
		uint256 length = poolInfo.length;
		for (uint256 pid = 0; pid < length; ++pid) {
			poolInfo[pid].lamaLastRewardBlock = startBlock;
			poolInfo[pid].rewardTokenLastRewardBlock = startBlock;
		}
	}

	function linkToMSv1(
		IMasterShepherd _msv1,
		IBEP20 _proxyToken,
		uint256 _v1Pid
	) external adminOnly {
		msV1 = _msv1;
		uint256 amount = 1 ether;
		_proxyToken.approve(address(msV1), amount);
		msV1.deposit(_v1Pid, amount);
		msV1pid = _v1Pid;
		msV1Linked = true;
	}

	function unlinkFromMSv1() external adminOnly {
		msV1.withdraw(msV1pid, 1 ether);
		msV1Linked = false;
		msV1 = IMasterShepherd(address(0));
	}

	function updateBscSecondsPerBlock(uint256 _seconds) external adminOnly {
		bsc_seconds_per_block = _seconds;
	}

	/**
	 * @notice Enable emergency withdraws without paying unstaking fees
	 * @dev Only callable by the contract owner. For emergency only
	 */
	function toggleWaiveEmergencyWithdrawFees(bool _waived) external adminOnly {
		emergencyWithdrawFeesWaived = _waived;
	}

	/**
	 * @notice Withdraws tokens deposited in the contract, excluding LAMA and staked LP tokens
	 * @dev Only callable by the contract owner
	 */
	function drainStuckToken(IBEP20 token, uint256 amount) external adminOnly {
		require(address(token) != address(lama), "LAMA cannot be drained");
		require(tokenList[token] == false, "Pool tokens cannot be drained");
		token.transfer(msg.sender, amount);
		emit EmergencyBEP20Drain(address(token), msg.sender, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IMasterShepherd {
    function lamaPerBlock() external view returns (uint256);

    function pendingLama(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function setDevAddress(address _devaddr) external;
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.6.0;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/utils/ReentrancyGuard.sol";
import "@pancakeswap/pancake-swap-lib/contracts/utils/EnumerableSet.sol";

import "../interfaces/IPancakePair.sol";

interface IVIPLevels {
	function getVipLevel(address user) external view returns (uint256);

	function getUserStakedValue(address user) external view returns (uint256);

	function resetTimestamp(
		address user,
		uint256 level,
		uint256 timestamp
	) external;
}

contract VIPLevels is Ownable, IVIPLevels {
	using SafeMath for uint256;
	using SafeBEP20 for IBEP20;
	using EnumerableSet for EnumerableSet.AddressSet;

	EnumerableSet.AddressSet private _users;

	IBEP20 public immutable lamaWoolLp;
	IBEP20 public immutable lamaBusdLp;
	IBEP20 public immutable lama;

	// vip levels requirement in BUSD value
	uint256[] public vipLevels;

	// Amount of lamaWoolLp of each user
	mapping(address => uint256) public userAmount;
	mapping(address => mapping(uint256 => uint256)) public userLevel; // user[level] => level reached timestamp
	mapping(uint256 => uint256) public assignedLevels; // level => user count

	uint256 public totalStaked;

	// whitelisted contracts
	mapping(address => bool) public whitelist;
	// privileged access
	mapping(address => bool) public authorized;

	event Deposit(address indexed user, uint256 amount);
	event Withdraw(address indexed user, uint256 amount);
	event EmergencyBEP20Drain(address token, address recipient, uint256 amount);

	constructor(
		IBEP20 _lama,
		IBEP20 _lamaBusdLp,
		IBEP20 _lamaWoolLp
	) public {
		lama = _lama;
		lamaBusdLp = _lamaBusdLp;
		lamaWoolLp = _lamaWoolLp;

		// default levels
		vipLevels = new uint256[](3);
		vipLevels[0] = 500 ether;
		vipLevels[1] = 1000 ether;
		vipLevels[2] = 2000 ether;
	}

	modifier nonZeroAddress(address addr) {
		require(addr != address(0), "Address cannot be ZERO");
		_;
	}

	/**
	 * @notice Checks if the msg.sender is a contract or a proxy
	 */
	modifier notContract() {
		require(!_isContract(msg.sender) || whitelist[msg.sender], "contract not allowed");
		require(msg.sender == tx.origin, "proxy contract not allowed");
		_;
	}

	modifier onlyAuthorized() {
		require(msg.sender == owner() || authorized[msg.sender], "Unauthorized");
		_;
	}

	/**
	 * @notice Checks if address is a contract
	 * @dev It prevents contract from being targetted
	 */
	function _isContract(address addr) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(addr)
		}
		return size > 0;
	}

	function setWhitelist(address addr, bool enabled) public onlyOwner nonZeroAddress(addr) {
		whitelist[addr] = enabled;
	}

	function setAuthorized(address addr, bool enabled) public onlyOwner nonZeroAddress(addr) {
		authorized[addr] = enabled;
	}

	function setVipLevels(uint256[] memory newLevels) public onlyOwner {
		vipLevels = newLevels;
	}

	function deposit(uint256 amount) public notContract {
		require(amount > 0, "Insufficient amount");

		lamaWoolLp.safeTransferFrom(address(msg.sender), address(this), amount);

		userAmount[msg.sender] = userAmount[msg.sender].add(amount);
		_users.add(msg.sender);
		totalStaked = totalStaked.add(amount);

		_assignLevel(msg.sender);

		emit Deposit(msg.sender, amount);
	}

	function withdraw(uint256 amount) public notContract {
		require(userAmount[msg.sender] >= amount, "Amount too big");

		userAmount[msg.sender] = userAmount[msg.sender].sub(amount);
		if (userAmount[msg.sender] == 0) {
			_users.remove(msg.sender);
		}
		totalStaked = totalStaked.sub(amount);

		_assignLevel(msg.sender);

		lamaWoolLp.safeTransfer(address(msg.sender), amount);

		emit Withdraw(msg.sender, amount);
	}

	function _assignLevel(address user) internal {
		uint256 newLevel = getVipLevel(user);
		if (userLevel[user][newLevel] == 0) {
			userLevel[user][newLevel] = block.timestamp;
			assignedLevels[newLevel]++;
		}
		// reset all higher levels
		for (uint256 index = newLevel + 1; index <= vipLevels.length; index++) {
			userLevel[user][index] = 0;
			if (assignedLevels[index] != 0) {
				assignedLevels[index]--;
			}
		}
		// decrement all lower levels
		for (uint256 index = newLevel > 0 ? newLevel - 1 : 0; index > 0; index--) {
			if (assignedLevels[index] != 0) {
				assignedLevels[index]--;				
			}
		}
	}

	function claimLevel() public notContract {
		_assignLevel(msg.sender);
	}

	function resetTimestamp(
		address user,
		uint256 level,
		uint256 timestamp
	) public override onlyAuthorized {
		userLevel[user][level] = timestamp;
	}

	/**
	 * @notice Withdraws tokens sent here by mistake, excluding LamaWoolLp tokens
	 * @dev Only callable by the contract owner
	 */
	function drainStuckToken(IBEP20 token) external onlyOwner {
		require(address(token) != address(lamaWoolLp), "LamaWoolLp cannot be drained");
		uint256 amount = token.balanceOf(address(this));
		token.transfer(msg.sender, amount);
		emit EmergencyBEP20Drain(address(token), msg.sender, amount);
	}

	function users() external view returns (address[] memory allUsers) {
		allUsers = new address[](_users.length());
		for (uint256 index = 0; index < _users.length(); index++) {
			allUsers[index] = _users.at(index);
		}
		return allUsers;
	}

	function getVipLevel(address user) public view override returns (uint256) {
		uint256 userStakedValue = getUserStakedValue(user);
		if (userStakedValue == 0) return 0;
		for (uint256 index = vipLevels.length; index > 0; index--) {
			if (userStakedValue >= vipLevels[index - 1]) return index;
		}
		return 0;
	}

	function getUserStakedValue(address user) public view override returns (uint256) {
		uint256 amount = userAmount[user];
		if (amount == 0) return 0;
		uint256 userStakedValue = getLamaWoolLpValue().mul(amount).div(1e18);
		return userStakedValue;
	}

	function getLamaPrice() public view returns (uint256) {
		IPancakePair lamaBusdPair = IPancakePair(address(lamaBusdLp));
		(uint256 lamaBalance, uint256 busdBalace, ) = lamaBusdPair.getReserves();
		return uint256(1 ether).mul(busdBalace) / lamaBalance;
	}

	function getLamaWoolLpValue() public view returns (uint256) {
		IPancakePair lamaWoolPair = IPancakePair(address(lamaWoolLp));
		(uint256 lamaBalance, , ) = lamaWoolPair.getReserves();
		uint256 lpTotalValue = lamaBalance.mul(2).mul(getLamaPrice());
		return lpTotalValue / lamaWoolPair.totalSupply();
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, 'EnumerableSet: index out of bounds');
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

