/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-29
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        assembly { codehash := extcodehash(account) }
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: contracts/Ownable.sol

pragma solidity 0.6.10;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the a
     * specified account.
     * @param initalOwner The address of the inital owner.
     */
    constructor(address initalOwner) internal {
        _owner = initalOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Only owner can call");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Owner should not be 0 address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/TokenPool.sol

pragma solidity 0.6.10;



/**
 * @title A simple holder of tokens.
 * This is a simple contract to hold tokens. It's useful in the case where a separate contract
 * needs to hold multiple distinct pools of the same token.
 */
contract TokenPool is Ownable {
    IERC20 public token;

    constructor(IERC20 _token) Ownable(msg.sender) public {
        token = _token;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(address to, uint256 value) external onlyOwner returns (bool) {
        return token.transfer(to, value);
    }
}

// File: contracts/AbstractStaking.sol

pragma solidity 0.6.10;






/**
 * @title Abstract Staking
 * @dev Skeleton of the staking pool for user to stake Balancer BPT token and get bella as reward.
 */
abstract contract AbstractStaking is Ownable {
    using SafeMath for uint256;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    TokenPool public stakingPool;
    TokenPool public lockedPool;
    TokenPool public unlockedPool;

    uint256 public startTime;

    //
    // Global state
    //
    uint256 public totalStakingAmount;
    uint256 public totalStakingAmountTime; // total time * amount staked
    uint256 public lastUpdatedTimestamp;

    //
    // Addional bella locking related
    //
    uint256 public currentUnlockCycle; // linear count down to release bella token
    uint256 public lastUnlockTime;

    /**
     * @param stakingBPT The BPT token users deposit as stake.
     * @param bellaToken The bonus token is bella.
     * @param admin The admin address
     * @param _startTime Timestamp that user can stake
     */
    constructor(
        IERC20 stakingBPT,
        IERC20 bellaToken,
        address admin,
        uint256 _startTime
        ) Ownable(admin) 
        internal {
        stakingPool = new TokenPool(stakingBPT);
        lockedPool = new TokenPool(bellaToken);
        unlockedPool = new TokenPool(bellaToken);
        startTime = _startTime;
    }

    /**
     * @return The user's total staking BPT amount
     */
    function totalStakedFor(address user) public view virtual returns (uint256);

    function totalStaked() public view returns (uint256) {
        return totalStakingAmount;
    }

    /**
     * @dev Stake for the user self
     * @param amount The amount of BPT tokens that the user wishes to stake
     */
    function stake(uint256 amount) external {
        require(!Address.isContract(msg.sender), "No harvest thanks");
        require(now >= startTime, "not started yet");
        _stake(msg.sender, msg.sender, amount);
    }

    /**
     * @return User's total rewards when clamining
     */
    function totalRewards() external view returns (uint256) {
        return _totalRewardsFor(msg.sender);
    }

    /**
     * @return A specific user's total rewards when clamining
     */
    function totalRewardsFor(address user) external view returns (uint256) {
        return _totalRewardsFor(user);
    }

    /**
     * @dev Claim=withdraw all the bella rewards
     */
    function claim() external {
        require(!Address.isContract(msg.sender), "No harvest thanks");
        // cumulate user and global time*amount
        _updateTotalStaking(0);
        _updateUserStaking(0, msg.sender);

        _poolUnlock();

        uint256 reward = _calculateRewardAndBurnAll(msg.sender);

        unlockedPool.transfer(msg.sender, reward);

        emit Claimed(msg.sender, reward);
    }

    /**
     * @dev Claim=withdraw all the bella rewards and the staking BPT token,
     * which stops the user's staking
     */
    function claimAndUnstake() external {
        require(!Address.isContract(msg.sender), "No harvest thanks");
        // cumulate user and global time*amount
        _updateTotalStaking(0);
        _updateUserStaking(0, msg.sender);

        _poolUnlock();

        (uint256 staking, uint256 reward) = _calculateRewardAndCleanUser(msg.sender);

        unlockedPool.transfer(msg.sender, reward);
        stakingPool.transfer(msg.sender, staking);

        emit Claimed(msg.sender, reward);
        emit Unstaked(msg.sender, staking);
    }

    /**
     * @dev we will lock more bella tokens on the begining of the next releasing cycle
     * @param amount the amount of bella token to lock
     * @param nextUnlockCycle next reward releasing cycle, unit=day
     */
    function lock(uint256 amount, uint256 nextUnlockCycle) external onlyOwner {
        currentUnlockCycle = nextUnlockCycle * 1 days;
        if (now >= startTime) {
            lastUnlockTime = now;
        } else {
            lastUnlockTime = startTime;
        }
            
        require(
            lockedPool.token().transferFrom(msg.sender, address(lockedPool), amount),
            "Additional bella transfer failed"
        );
    }

    /**
     * @dev Actual logic to handle user staking
     * @param from The user who pays the staking BPT
     * @param beneficiary The user who actually controls the staking BPT
     * @param amount The amount of BPT tokens to stake
     */
    function _stake(address from, address beneficiary, uint256 amount) private {
        require(amount > 0, "can not stake 0 token");
        require(
            stakingPool.token().transferFrom(from, address(stakingPool), amount),
            "Staking BPT transfer failed"
        );

        _updateUserStaking(amount, beneficiary);

        _updateTotalStaking(amount);

        emit Staked(beneficiary, amount);
    }

    /**
     * @dev Update the global state due to more time cumulated and/or new BPT staking token
     * @param amount New BPT staking deposited (can be 0)
     */
    function _updateTotalStaking(uint256 amount) private {
        uint256 additionalAmountTime = totalStakingAmount.mul(now.sub(lastUpdatedTimestamp));
        totalStakingAmount = totalStakingAmount.add(amount);
        totalStakingAmountTime = totalStakingAmountTime.add(additionalAmountTime);
        lastUpdatedTimestamp = now;
    }

    /**
     * @dev Update a specific user's state due to more time cumulated and/or new BPT staking token
     * @param amount New BPT staking deposited (can be 0)
     * @param user The account to be updated
     */
    function _updateUserStaking(uint256 amount, address user) internal virtual;

    /**
     * @dev linear count down from 30 days to release bella token,
     * from the locked pool to the unlocked pool
     */
    function _poolUnlock() private {
        if (currentUnlockCycle == 0)
            return; // release ended
        uint256 timeDelta = now.sub(lastUnlockTime);
        if (currentUnlockCycle < timeDelta)
            currentUnlockCycle = timeDelta; // release all

        uint256 amount = lockedPool.balance().mul(timeDelta).div(currentUnlockCycle);

        currentUnlockCycle = currentUnlockCycle.sub(timeDelta);
        lastUnlockTime = now;

        lockedPool.transfer(address(unlockedPool), amount);
    }

    /**
     * @dev Calculate user's total cumulated reward and burn his/her all staking amount*time
     * @return User cumulated reward bella during the staking process
     */
    function _calculateRewardAndBurnAll(address user) internal virtual returns (uint256);

    /**
     * @dev Calculate user's total cumulated reward and staking,
     * and remove him/her from the staking process
     * @return [1] User cumulated staking BPT
     * @return [2] User cumulated reward bella during the staking process
     */
    function _calculateRewardAndCleanUser(address user) internal virtual returns (uint256, uint256);

    /**
     * @dev Internal function to calculate user's total rewards
     * @return A specific user's total rewards when clamining
     */
    function _totalRewardsFor(address user) internal view virtual returns (uint256);
    
}

// File: contracts/IncrementalStaking.sol

pragma solidity 0.6.10;



/**
 * @title Incremental Staking
 * @dev A staking pool for user to stake Balancer BPT token and get bella as reward.
 * Regarding the staking time, there is a linear bonus amplifier goes from 1.0 (initially)
 * to 2.0 (at the end of the 60th day). The reward is added by the admin at the 0th, 30th
 * and 60th day, respectively.
 * @notice If the user stakes too many times (which is irrational considiering the gas fee),
 * he will get stuck later
 */
contract IncrementalStaking is AbstractStaking {
    using SafeMath for uint256;

    mapping(address=>Staking[]) public stakingInfo;

    struct Staking {
        uint256 amount;
        uint256 time;
    }

    //
    // Reward amplifier related
    //
    uint256 constant STARTING_BONUS = 5_000;
    uint256 constant ENDING_BONUS = 10_000;
    uint256 constant ONE = 10_000;
    uint256 constant BONUS_PERIOD = 60 days;

    /**
     * @param stakingBPT The BPT token users deposit as stake.
     * @param bellaToken The bonus token is bella.
     * @param admin The admin address
     * @param _startTime Timestamp that user can stake
     */
    constructor(
        IERC20 stakingBPT, 
        IERC20 bellaToken,
        address admin,
        uint256 _startTime     
        ) AbstractStaking(
            stakingBPT,
            bellaToken,
            admin,
            _startTime
        ) public {}

    /**
     * @return The user's total staking BPT amount
     */
    function totalStakedFor(address user) public view override returns (uint256) {
        uint amount = 0;
        Staking[] memory userStaking = stakingInfo[user];
        for (uint256 i=0; i < userStaking.length; i++) {
            amount = amount.add(userStaking[i].amount);
        }
        return amount;
    }

    /**
     * @dev Update a specific user's state due to more time cumulated and/or new BPT staking token
     * @param amount New BPT staking deposited (can be 0)
     * @param user The account to be updated
     */
    function _updateUserStaking(uint256 amount, address user) internal override {
        if (amount == 0)
            return;

        Staking memory newStaking = Staking({amount: amount, time: now});
        stakingInfo[user].push(newStaking);
    }

    /**
     * @dev Calculate user's total cumulated reward and burn his/her all staking amount*time
     * @return User cumulated reward bella during the staking process
     */
    function _calculateRewardAndBurnAll(address user) internal override returns (uint256) {
        
        uint256 totalReward = 0;
        uint256 totalStaking = 0;
        uint256 totalTimeAmount = 0;

        Staking[] memory userStakings = stakingInfo[user];

        // iterate through user's staking
        for (uint256 i=0; i<userStakings.length; i++) {
            totalStaking = totalStaking.add(userStakings[i].amount);
            // get the staking part's reward (amplified) and the time*amount to reduce
            (uint256 reward, uint256 timeAmount) = _getRewardAndTimeAmountToBurn(userStakings[i]);
            totalReward = totalReward.add(reward);
            totalTimeAmount = totalTimeAmount.add(timeAmount);
        }

        totalStakingAmountTime = totalStakingAmountTime.sub(totalTimeAmount);

        // user staking information reset
        delete stakingInfo[user];
        stakingInfo[user].push(Staking({amount: totalStaking, time: now}));

        return totalReward;
    }

    /**
     * @dev Calculate user's total cumulated reward and staking, 
     * and remove him/her from the staking process
     * @return [1] User cumulated staking BPT
     * @return [2] User cumulated reward bella during the staking process
     */
    function _calculateRewardAndCleanUser(address user) internal override returns (uint256, uint256) {

        uint256 totalStaking = 0;
        uint256 totalReward = 0;
        uint256 totalTimeAmount = 0;

        Staking[] memory userStakings = stakingInfo[user];

        // iterate through user's staking
        for (uint256 i=0; i<userStakings.length; i++) {
            totalStaking = totalStaking.add(userStakings[i].amount);
            // get the staking part's reward (amplified) and the time*amount to reduce
            (uint256 reward, uint256 timeAmount) = _getRewardAndTimeAmountToBurn(userStakings[i]);
            totalReward = totalReward.add(reward);
            totalTimeAmount = totalTimeAmount.add(timeAmount);
        }

        totalStakingAmount = totalStakingAmount.sub(totalStaking);
        totalStakingAmountTime = totalStakingAmountTime.sub(totalTimeAmount);

        // clear user 
        delete stakingInfo[user];
        return (totalStaking, totalReward);

    }

    /**
     * @dev Calculate user's reward of one portion of stake amplified 
     * @return [1] Reward of this portion of stake
     * @return [2] Time*amount to burn
     */
    function _getRewardAndTimeAmountToBurn(Staking memory staking) private view returns (uint256, uint256) {
        uint256 timeDelta = now.sub(staking.time);
        uint256 timeAmount = staking.amount.mul(timeDelta);

        uint256 rewardFullBonus = unlockedPool.balance().mul(timeAmount).div(totalStakingAmountTime);

        if (timeDelta >= BONUS_PERIOD)
            return (rewardFullBonus, timeAmount);

        uint256 reward = (ENDING_BONUS - STARTING_BONUS).mul(timeDelta).div(BONUS_PERIOD).add(STARTING_BONUS).mul(rewardFullBonus).div(ONE);

        return (reward, timeAmount);

    }

    /**
     * @dev Internal function to calculate user's total rewards
     * @return A specific user's total rewards when clamining
     */
    function _totalRewardsFor(address user) internal view override returns (uint256) {

        // calculate new total staking amount*time
        uint256 additionalAmountTime = totalStakingAmount.mul(now.sub(lastUpdatedTimestamp));
        uint256 newTotalStakingAmountTime = totalStakingAmountTime.add(additionalAmountTime);

        // calculate total unlocked pool
        uint256 unlockedAmount = unlockedPool.balance();
        if (currentUnlockCycle != 0) {
            uint256 timeDelta = now.sub(lastUnlockTime);
            if (currentUnlockCycle <= timeDelta) {
                unlockedAmount = unlockedAmount.add(lockedPool.balance());
            } else {
                uint256 additionalAmount = lockedPool.balance().mul(timeDelta).div(currentUnlockCycle);
                unlockedAmount = unlockedAmount.add(additionalAmount);
            }
        }

        uint256 totalReward = 0;

        Staking[] memory userStakings = stakingInfo[user];

        // iterate through user's staking
        for (uint256 i=0; i<userStakings.length; i++) {
            // get the staking part's reward (amplified) and the time*amount to reduce
            Staking memory staking = userStakings[i];
            uint256 timeDelta = now.sub(staking.time);
            uint256 timeAmount = staking.amount.mul(timeDelta);

            uint256 reward = unlockedAmount.mul(timeAmount).div(newTotalStakingAmountTime);

            if (timeDelta < BONUS_PERIOD)
                reward = (ENDING_BONUS - STARTING_BONUS).mul(timeDelta).div(BONUS_PERIOD).add(
                    STARTING_BONUS).mul(reward).div(ONE);

            totalReward = totalReward.add(reward);
        }

        return totalReward;
    }
}