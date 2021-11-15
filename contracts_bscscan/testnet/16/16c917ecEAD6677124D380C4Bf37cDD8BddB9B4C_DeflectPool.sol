//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
    ▓█████▄ ▓█████   ████ ▒██▓    ▓█████  ▄████▄  ▄▄▄█████▓   ██▓███   ▒█████   ▒█████   ██▓
    ▒██▀ ██▌▓█   ▀  ▓██   ▒▓██▒    ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒   ▓██░  ██▒▒██▒  ██▒▒██▒  ██▒ ▓██▒
    ░██   █▌▒███    ▒████ ░▒██░    ▒███   ▒▓█    ▄    ██░ ▒    ▓██░ ██▓▒▒██   ██▒▒██░  ██▒ ▒██░
    ░▓█▄   ▌▒▓█  ▄ ░ ▓█▒  ░▒██░    ▒▓█  ▄ ▒▓▓▄ ▄██▒░  ██ ░    ▒██▄█▓▒ ▒▒██   ██░▒██   ██░ ▒██░
    ░▒████▓ ░▒████▒░ ▒█░   ░██████▒░▒████▒▒ ▓███▀ ░  ▒██▒     ▒██▒ ░  ░░ ████▓▒░░ ████▓▒░░██████▒
     ▒▒▓  ▒ ░░ ▒░ ░ ▒ ░   ░ ▒░▓  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░        ▒▓▒░ ░  ░░ ▒░▒░▒░ ░ ▒░▒░▒░ ░ ▒░▓  ░
     ░ ▒  ▒  ░ ░  ░ ░     ░ ░ ▒  ░ ░ ░  ░  ░  ▒       ░          ░▒ ░       ░ ▒ ▒░   ░ ▒ ▒░ ░ ░ ▒  ░
     ░ ░  ░    ░    ░ ░     ░ ░      ░   ░             ░             ░░         ░ ░ ░ ▒  ░ ░ ░ ▒
*/

import "@openzeppelin/contracts/math/Math.sol";
import "./LPTokenWrapper.sol";
import "./interfaces/IDeflector.sol";
import "./interfaces/IERC20Metadata.sol";

/**
 * @title DeflectPool
 * @author DEFLECT PROTOCOL
 * @dev This contract is a time-based yield farming pool with effective-staking multiplier mechanics.
 *
 * * * NOTE: A withdrawal fee of 1.5% is included which is sent to the treasury address. Fee is reduced by holding PRISM * * *
 */

contract DeflectPool is LPTokenWrapper {
    using SafeERC20 for IERC20Metadata;

    IDeflector public immutable deflector;
    uint256 public immutable stakingTokenMultiplier;
    uint256 public immutable deployedTime;
    address public immutable devFund;

    struct PoolInfo {
        IERC20Metadata rewardTokenAddress;
        uint256 rewardPoolID;
        uint256 duration;
        uint256 periodFinish;
        uint256 startTime;
        uint256 lastUpdateTime;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
    }

    struct UserRewardInfo {
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    PoolInfo[] public poolInfo;

    mapping(address => bool) public addedRewardTokens; // Used for preventing LP tokens from being added twice in add().
    mapping(uint256 => mapping(address => UserRewardInfo)) public rewardsInPool;

    event Withdrawn(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address rewardToken, uint256 rewardAmount);
    event Boost(address _token, uint256 level);
    event RewardPoolAdded(uint256 rewardPoolID, address rewardTokenAddress, uint256 rewardDuration);
    event RewardPoolStarted(uint256 rewardPoolID, address rewardTokenAddress, uint256 rewardAmount, uint256 rewardPeriodFinish);

    // Set the staking token, addresses, various fee variables and the prism fee reduction level amounts
    constructor(
        address _stakingToken,
        address _deflector,
        address _treasury,
        address _devFund,
        uint256 _devFee,
        uint256 _burnFee,
        address _prism
    ) public LPTokenWrapper(_devFee, _stakingToken, _treasury, _burnFee, _prism) {
        require(_stakingToken != address(0) && _deflector != address(0) && _treasury != address(0) && _devFund != address(0), "!constructor");
        deflector = IDeflector(_deflector);
        stakingTokenMultiplier = 10**uint256(IERC20Metadata(_stakingToken).decimals());
        deployedTime = block.timestamp;
        devFund = _devFund;
    }

    /* @dev Updates the rewards a user has earned */
    function updateReward(address account) internal {
        // loop through all reward pools for user
        for (uint i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            
            if (address(pool.rewardTokenAddress) == address(0)) {
                continue;
            }   else {
                    rewardsInPool[i][account].rewards = earned(account, i);
                    rewardsInPool[i][account].userRewardPerTokenPaid = pool.rewardPerTokenStored;
                    updateRewardPerTokenStored(i);                    
                }
        }
    }

    function updateRewardPerTokenStored(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];

        pool.rewardPerTokenStored = rewardPerToken(_pid);
        pool.lastUpdateTime = lastTimeRewardsActive(_pid);
    }

    function lastTimeRewardsActive(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return Math.min(block.timestamp, pool.periodFinish);
    }

    /* @dev Returns the current rate of rewards per token */
    function rewardPerToken(uint256 _pid) public view returns (uint256) {

        PoolInfo storage pool = poolInfo[_pid];

        // Do not distribute rewards before startTime.
        if (block.timestamp < pool.startTime) {
            return 0;
        }

        if (totalSupply == 0) {
            return pool.rewardPerTokenStored;
        }

        // Effective total supply takes into account all the multipliers bought by userbase.
        uint256 effectiveTotalSupply = totalSupply.add(boostedTotalSupply);
        // The returrn value is time-based on last time the contract had rewards active multipliede by the reward-rate.
        // It's evened out with a division of bonus effective supply.
        return pool.rewardPerTokenStored
        .add(
            lastTimeRewardsActive(_pid)
            .sub(pool.lastUpdateTime)
            .mul(pool.rewardRate)
            .mul(stakingTokenMultiplier)
            .div(effectiveTotalSupply)
        );
    }

    /** @dev Returns the claimable tokens for user.*/
    function earned(address account, uint256 _pid) public view returns (uint256) {
     
        uint256 effectiveBalance = _balances[account].balance.add(_balances[account].boostedBalance);
        uint256 reward = rewardsInPool[_pid][msg.sender].rewards;
        uint256 rewardPerTokenPaid = rewardsInPool[_pid][msg.sender].userRewardPerTokenPaid;

        return effectiveBalance.mul(rewardPerToken(_pid).sub(rewardPerTokenPaid)).div(stakingTokenMultiplier).add(reward);
    }

    /** @dev Staking function which updates the user balances in the parent contract */
    function stake(uint256 amount) public override {
        require(amount > 0, "Cannot stake 0");

        updateReward(msg.sender);

        // Call the parent to adjust the balances.
        super.stake(amount);

        // Adjust the bonus effective stake according to the multiplier.
        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        adjustBoostedBalance(boostedBalance);
        emit Staked(msg.sender, amount);
    }

    /** @dev Withdraw function, this pool contains a tax which is defined in the constructor */
    function withdraw(uint256 amount, address) public override {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);

        // Adjust regular balances
        super.withdraw(amount, msg.sender);

        // And the bonus balances
        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        adjustBoostedBalance(boostedBalance);
        emit Withdrawn(msg.sender, amount);
    }

    /** @dev Adjust the bonus effective stakee for user and whole userbase */
    function adjustBoostedBalance(uint256 _boostedBalance) private {
        Balance storage balances = _balances[msg.sender];
        uint256 previousBoostedBalance = balances.boostedBalance;
        if (_boostedBalance < previousBoostedBalance) {
            uint256 diffBalancesAccounting = previousBoostedBalance.sub(_boostedBalance);
            boostedTotalSupply = boostedTotalSupply.sub(diffBalancesAccounting);
        } else if (_boostedBalance > previousBoostedBalance) {
            uint256 diffBalancesAccounting = _boostedBalance.sub(previousBoostedBalance);
            boostedTotalSupply = boostedTotalSupply.add(diffBalancesAccounting);
        }
        balances.boostedBalance = _boostedBalance;
    }

    /** @dev Ease-of-access function for user to remove assets from the pool */
    function exit() external {
        getReward();
        withdraw(balanceOf(msg.sender), msg.sender);
    }

    /** @dev Sends out the reward tokens to the user */
    function getReward() public {
        updateReward(msg.sender);
        
        // loop through all the reward pools for a user
        for (uint i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            
            if (address(pool.rewardTokenAddress) == address(0)) {
                continue;
            }   else {
                    uint256 reward = rewardsInPool[i][msg.sender].rewards;
                    rewardsInPool[i][msg.sender].rewards = 0;
                    pool.rewardTokenAddress.safeTransfer(msg.sender, reward);
                    emit RewardPaid(msg.sender, address(pool.rewardTokenAddress), reward);
                }
        }
    }

    /** @dev Purchase a multiplier level, same level cannot be purchased twice */
    function purchase(address _token, uint256 _newLevel) external {

        updateReward(msg.sender);
        
        // Calculates cost, ensures it is a new level too
        uint256 cost = deflector.calculateCost(msg.sender, _token, _newLevel);
        require(cost > 0, "cost cannot be 0");

        // Update level in multiplier contract
        uint256 newBoostedBalance = deflector.updateLevel(msg.sender, _token, _newLevel, _balances[msg.sender].balance);

        // Adjust new level
        adjustBoostedBalance(newBoostedBalance);

        emit Boost(_token, _newLevel);

        uint256 devPortion = cost.mul(25) / 100;

        // Transfer the bonus cost into the treasury and dev fund.
        IERC20Metadata(_token).safeTransferFrom(msg.sender, devFund, devPortion);
        IERC20Metadata(_token).safeTransferFrom(msg.sender, treasury, cost - devPortion);
    }

    /** @dev Sync after minting more prism */
    function sync() external {
        updateReward(msg.sender);

        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        require(boostedBalance > _balances[msg.sender].boostedBalance, "DeflectPool::sync: Invalid sync invocation");
        // Adjust new level
        adjustBoostedBalance(boostedBalance);
    }

    /** @dev Returns the multiplier for user */
    function getUserMultiplier() external view returns (uint256) {
         // And the bonus balances
        uint256 boostedBalance = deflector.calculateBoostedBalance(msg.sender, _balances[msg.sender].balance);
        
        if (boostedBalance == 0) return 0;

        return boostedBalance * 100 / _balances[msg.sender].balance;
    }

    /** @dev Returns the amount of tokens needed to purchase the boost level input */
    function getLevelCost(address _token, uint256 _level) external view returns (uint256) {
        return deflector.calculateCost(msg.sender, _token, _level);
    }

    /** @dev Adds a new reward pool with specified duration */
    function addRewardPool(IERC20Metadata _rewardToken, uint256 _duration) public onlyOwner {
        require(address(_rewardToken) != address(0), "Cannot add burn address");
        require(_duration != 0, "Must define valid duration length");

        // calculate info relevant for storing in the pool array
        uint256 totalPools = poolInfo.length;
        uint256 _rewardTokenID = totalPools++;

        poolInfo.push(PoolInfo({
            rewardTokenAddress: _rewardToken,
            rewardPoolID: _rewardTokenID,
            duration: _duration,
            periodFinish: 0,
            startTime: 0,
            lastUpdateTime: 0,
            rewardRate: 0,
            rewardPerTokenStored: 0
        }));

        addedRewardTokens[address(_rewardToken)] = true;

        emit RewardPoolAdded(_rewardTokenID, address(_rewardToken), _duration);
    }

    /** @dev Called to start the pool. Owner must have already sent rewards to the contract. Reward amount is defined in the input. */
    function notifyRewardAmount(uint256 _pid, uint256 _reward) external onlyOwner() {
        require(_reward > 0, "!reward added");

        PoolInfo storage pool = poolInfo[_pid];
        
        // Sets the pools finish time to end after duration length
        pool.periodFinish = block.timestamp + pool.duration;

        // Update reward values
        updateRewardPerTokenStored(_pid);

        // Rewardrate must stay at a constant since it's used by end-users claiming rewards after the reward period has finished.
        if (block.timestamp >= pool.periodFinish) {
            pool.rewardRate = _reward.div(pool.duration);
        } else {
            // Remaining time for the pool
            uint256 remainingTime = pool.periodFinish.sub(block.timestamp);
            // And the rewards
            uint256 rewardsRemaining = remainingTime.mul(pool.rewardRate);
            // Set the current rate
            pool.rewardRate = _reward.add(rewardsRemaining).div(pool.duration);
        }

        // Set the last updated time
        pool.lastUpdateTime = block.timestamp;
        pool.startTime = block.timestamp;

        // Add the period to be equal to duration set
        pool.periodFinish = block.timestamp.add(pool.duration);
        emit RewardPoolStarted(_pid, address(pool.rewardTokenAddress), _reward, pool.periodFinish);
    }

    /** @dev Ejects any remaining tokens from the reward pool specified. Callable only after the pool has started and the pools reward distribution period has finished. */
    function eject(uint256 _pid) public onlyOwner() {
        PoolInfo storage pool = poolInfo[_pid];

        require(block.timestamp >= pool.periodFinish + 12 hours, "Cannot eject before period finishes or pool has started");
        uint256 currBalance = pool.rewardTokenAddress.balanceOf(address(this));
        pool.rewardTokenAddress.safeTransfer(msg.sender, currBalance);
    }

    /** @dev Ejects any remaining tokens from all reward pools */
    function ejectAll() public onlyOwner() {
        // loop through all reward pools to eject all
        for (uint i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            
            if (address(pool.rewardTokenAddress) == address(0)) {
                continue;
            }   else {
                    require(block.timestamp >= pool.periodFinish + 12 hours, "Cannot eject before period finishes or pool has started, check all reward pool durations");
                    uint256 currBalance = pool.rewardTokenAddress.balanceOf(address(this));
                    pool.rewardTokenAddress.safeTransfer(msg.sender, currBalance);
                }
        }
    }

    /** @dev Removes a specific pool in the array, leaving the pid slot empty */
    function removeRewardPool(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        addedRewardTokens[address(pool.rewardTokenAddress)] = false;
        eject(_pid);
        delete poolInfo[_pid];
    }

    /** @dev Removes all reward pools */
    function removeAllRewardPools() external onlyOwner {
        for (uint i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            addedRewardTokens[address(pool.rewardTokenAddress)] = false;
        }
        ejectAll();
        delete poolInfo;
    }

    /** @dev Forcefully retire a pool. Only sets the period finish to 0. Will prevent more rewards from being distributed */
    function kill(uint256 _pid) external onlyOwner() {
        PoolInfo storage pool = poolInfo[_pid];

        pool.periodFinish = block.timestamp;
    }

    /** @dev Callable only after the pool has started and the pools reward distribution period has finished */
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.timestamp >= pool.periodFinish + 12 hours, "DeflectPool::emergencyWithdraw: Cannot emergency withdraw before period finishes or pool has started");
        uint256 fullWithdrawal = pool.rewardTokenAddress.balanceOf(msg.sender);
        require(fullWithdrawal > 0, "DeflectPool::emergencyWithdraw: Cannot withdraw 0");
        super.withdraw(fullWithdrawal, msg.sender);
        emit Withdrawn(msg.sender, fullWithdrawal);
    }

    /** @dev Sets a new treasury address */ 
    function setNewTreasury(address _treasury) external onlyOwner() {
        treasury = _treasury;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IDeflector {
    function calculateBoostedBalance(address _user, uint256 _balance)
        external
        view
        returns (uint256);

    function calculateCost(
        address _user,
        address _token,
        uint256 _nextLevel
    ) external view returns (uint256);

    function updateLevel(
        address _user,
        address _token,
        uint256 _nextLevel,
        uint256 _balance
    ) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract LPTokenWrapper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable prism;
    IERC20 public immutable stakingToken;
    uint256 public immutable devFee;

    // Returns the total staked tokens within the contract
    uint256 public totalSupply;
    uint256 public boostedTotalSupply;
    uint256 public startTime;
    uint256 public burnFee;

    // Variables for determing the reduction of unstaking fees based on holding PRISM
    uint256 public unstakeFeeReduceLvl1Amount;
    uint256 public unstakeFeeReduceLvl2Amount;
    uint256 public unstakeFeeReduceLvl3Amount;
    uint256 public unstakeFeeReduceLvl1Discount;
    uint256 public unstakeFeeReduceLvl2Discount;
    uint256 public unstakeFeeReduceLvl3Discount;
    
    struct Balance {
        uint256 balance;
        uint256 boostedBalance;
    }

    address public treasury;

    mapping(address => Balance) internal _balances;

    constructor(
        uint256 _devFee,
        address _stakingToken,
        address _treasury,
        uint256 _burnFee,
        address _prism
    ) public {
        devFee = _devFee;
        stakingToken = IERC20(_stakingToken);
        treasury = _treasury;
        burnFee = _burnFee;
        prism = IERC20(_prism);

        unstakeFeeReduceLvl1Amount = 25000000000000000000;
        unstakeFeeReduceLvl2Amount = 50000000000000000000;
        unstakeFeeReduceLvl3Amount = 100000000000000000000;
        unstakeFeeReduceLvl1Discount = 25;
        unstakeFeeReduceLvl2Discount = 50;
        unstakeFeeReduceLvl3Discount = 100;
    }

    // Returns staking balance of the account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].balance;
    }

    // Returns boosted balance of the account
    function boostedBalanceOf(address account) public view returns (uint256) {
        return _balances[account].boostedBalance;
    }

    // Stake funds into the pool
    function stake(uint256 amount) public virtual {
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        if (burnFee > 0 ) {
            uint tokenBurnBalance = amount.mul(burnFee).div(10000);
            uint stakedBalance = amount.sub(tokenBurnBalance);
            _balances[msg.sender].balance = _balances[msg.sender].balance.add(
            stakedBalance
           );
            totalSupply = totalSupply.add(stakedBalance);
            return;
        }
         // Increment sender's balances and total supply
        _balances[msg.sender].balance = _balances[msg.sender].balance.add(
            amount
        );
        totalSupply = totalSupply.add(amount);
    }

    // Subtract balances withdrawn from the user
    function withdraw(uint256 amount, address user) public virtual {
        totalSupply = totalSupply.sub(amount);
        _balances[msg.sender].balance = _balances[msg.sender].balance.sub(
            amount
        );

        // Calculate the withdraw tax (it's 1.5% of the amount)
        uint256 tax = amount.mul(devFee).div(1000);

        // Apply any Fee Reduction from holding PRISM
        uint256 userFeeReduceLvlDiscount;
        uint256 prismBalance = prism.balanceOf(user);

        if (prismBalance < unstakeFeeReduceLvl1Amount) {
            userFeeReduceLvlDiscount = 0;
        } else if (prismBalance >= unstakeFeeReduceLvl1Amount && prismBalance < unstakeFeeReduceLvl2Amount) {
            userFeeReduceLvlDiscount = unstakeFeeReduceLvl1Discount;
        } else if (prismBalance >= unstakeFeeReduceLvl2Amount && prismBalance < unstakeFeeReduceLvl3Amount) {
            userFeeReduceLvlDiscount = unstakeFeeReduceLvl2Discount;
        } else if (prismBalance >= unstakeFeeReduceLvl3Amount) {
            userFeeReduceLvlDiscount = unstakeFeeReduceLvl3Discount;
        }
        

        // Calculate fee reductions if applicable for users holding PRISM
        uint256 userDiscount = 100 - userFeeReduceLvlDiscount;
        uint256 feeReducedTax = tax.div(100).mul(userDiscount);

        // Transfer the tokens to user
        stakingToken.safeTransfer(msg.sender, amount - feeReducedTax);
        // Tax to treasury
        stakingToken.safeTransfer(treasury, feeReducedTax);
    }

    // Edits the values for the Fee Reduction on unstaking for holding PRISM
    function editFeeReduceVariables(uint256 _unstakeFeeReduceLvl1Amount, uint256 _unstakeFeeReduceLvl2Amount,
    uint256 _unstakeFeeReduceLvl3Amount, uint256 _unstakeFeeReduceLvl1Discount,
    uint256 _unstakeFeeReduceLvl2Discount, uint256 _unstakeFeeReduceLvl3Discount
    ) external onlyOwner() {

        unstakeFeeReduceLvl1Amount = _unstakeFeeReduceLvl1Amount;
        unstakeFeeReduceLvl2Amount = _unstakeFeeReduceLvl2Amount;
        unstakeFeeReduceLvl3Amount = _unstakeFeeReduceLvl3Amount;
        unstakeFeeReduceLvl1Discount = _unstakeFeeReduceLvl1Discount;
        unstakeFeeReduceLvl2Discount = _unstakeFeeReduceLvl2Discount;
        unstakeFeeReduceLvl3Discount = _unstakeFeeReduceLvl3Discount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

