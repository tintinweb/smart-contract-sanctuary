/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// version2
// Stolen with love from Synthetixio
// https://raw.githubusercontent.com/Synthetixio/synthetix/develop/contracts/StakingRewards.sol

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
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

interface ERC20 {
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        ERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        ERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        ERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(
            localCounter == _guardCounter,
            "ReentrancyGuard: reentrant call"
        );
    }
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    // Mutative

    function stakeLocked(uint256 amount, uint256 sec) external;

    function withdrawLocked(bytes32 id) external;

    function getReward() external;
}

contract StakingRewards is IStakingRewards, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ========== */

    ERC20 public rewardsToken;
    ERC20 public stakingToken;
    ERC20 public vToken;
    uint256 public periodFinish;

    // Constant for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant MULTIPLIER_BASE = 1e6;
    uint256 public minting_fee = 50000;
    // Max reward per second
    uint256 public rewardRate;

    // uint256 public rewardsDuration = 86400 hours;
    // uint256 public rewardsDuration = 604800; // 7 * 86400  (7 days)
    uint256 public rewardsDuration = 365 * 86400; // 7 * 86400  (7 days)

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored = 0;

    address public owner_address;
    address public owner_mintingfee_address;
    address public timelock_address; // Governance timelock address

    uint256 public locked_stake_max_multiplier = 1500000; // 6 decimals of precision. 1x = 1000000
    uint256 public locked_stake_time_for_max_multiplier = 1 * 365 * 86400; // 1 years
    uint256 public locked_stake_min_time = 7884000; // 365 * 86400 / 12  (3 month)
    string private locked_stake_min_time_str = "7884000";

    uint256 public cr_boost_max_multiplier = 1500000; // 6 decimals of precision. 1x = 1000000

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _staking_token_supply = 0;
    uint256 private _staking_token_boosted_supply = 0;
    mapping(address => uint256) private _locked_balances;
    mapping(address => uint256) private _boosted_balances;
    mapping(address => uint256) public totalClaimedRewards;

    mapping(address => LockedStake[]) private lockedStakes;

    bool public unlockedStakes; // Release lock stakes in case of system migration

    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 amount;
        uint256 ending_timestamp;
        uint256 multiplier; // 6 decimals of precision. 1x = 1000000
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _rewardsToken,
        address _stakingToken
    ) public {
        owner_address = _owner;
        rewardsToken = ERC20(_rewardsToken);
        stakingToken = ERC20(_stakingToken);
        lastUpdateTime = block.timestamp;
        unlockedStakes = false;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _staking_token_supply;
    }

    function totalBoostedSupply() external view returns (uint256) {
        return _staking_token_boosted_supply;
    }

    function stakingMultiplier(uint256 secs) public view returns (uint256) {
        if (secs == locked_stake_min_time) {
            return MULTIPLIER_BASE;
        }
        if (secs == locked_stake_min_time * 2) {
            return (MULTIPLIER_BASE * 12) / 10;
        }
        if (secs >= locked_stake_min_time * 4) {
            return locked_stake_max_multiplier;
        }
        return MULTIPLIER_BASE;
    }

    function crBoostMultiplier() public pure returns (uint256) {
        // uint256 multiplier = uint(MULTIPLIER_BASE).add((uint(MULTIPLIER_BASE).sub(PUSD.global_collateral_ratio())).mul(cr_boost_max_multiplier.sub(MULTIPLIER_BASE)).div(MULTIPLIER_BASE) );
        return uint256(MULTIPLIER_BASE);
    }

    // function crBoostMultiplier() public view returns (uint256) {
    //     uint256 multiplier = uint(MULTIPLIER_BASE).add((uint(MULTIPLIER_BASE).sub(PUSD.global_collateral_ratio())).mul(cr_boost_max_multiplier.sub(MULTIPLIER_BASE)).div(MULTIPLIER_BASE) );
    //     return multiplier;
    // }

    // Total locked liquidity tokens
    function lockedBalanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _locked_balances[account];
    }

    // Total 'balance' used for calculating the percent of the pool the account owns
    // Takes into account the locked stake time multiplier
    function boostedBalanceOf(address account) external view returns (uint256) {
        return _boosted_balances[account];
    }

    function lockedStakesOf(address account)
        external
        view
        returns (LockedStake[] memory)
    {
        return lockedStakes[account];
    }

    // function stakingDecimals() external view returns (uint256) {
    //     return stakingToken.decimals();
    // }

    function rewardsFor(address account) external view returns (uint256) {
        // You may have use earned() instead, because of the order in which the contract executes
        return rewards[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view override returns (uint256) {
        if (_staking_token_supply == 0) {
            return rewardPerTokenStored;
        } else {
            return
                rewardPerTokenStored.add(
                    lastTimeRewardApplicable()
                        .sub(lastUpdateTime)
                        .mul(rewardRate)
                        .mul(crBoostMultiplier())
                        .mul(1e18)
                        .div(PRICE_PRECISION)
                        .div(_staking_token_boosted_supply)
                );
        }
    }

    function earned(address account) public view override returns (uint256) {
        return
            _boosted_balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return
            rewardRate.mul(rewardsDuration).mul(crBoostMultiplier()).div(
                PRICE_PRECISION
            );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stakeLocked(uint256 amount, uint256 secs)
        external
        override
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        require(secs >= locked_stake_min_time, "Minimum stake time not met");

        uint256 multiplier = stakingMultiplier(secs);
        uint256 boostedAmount = amount.mul(multiplier).div(PRICE_PRECISION);
        lockedStakes[msg.sender].push(
            LockedStake(
                keccak256(
                    abi.encodePacked(msg.sender, block.timestamp, amount)
                ),
                block.timestamp,
                amount,
                block.timestamp.add(secs),
                multiplier
            )
        );

        // Pull the tokens from the staker
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // Staking token supply and boosted supply
        _staking_token_supply = _staking_token_supply.add(amount);
        _staking_token_boosted_supply = _staking_token_boosted_supply.add(
            boostedAmount
        );

        // Staking token balance and boosted balance
        _locked_balances[msg.sender] = _locked_balances[msg.sender].add(amount);
        _boosted_balances[msg.sender] = _boosted_balances[msg.sender].add(
            boostedAmount
        );
        vToken.mint(msg.sender, amount);

        emit StakeLocked(msg.sender, amount, secs);
    }

    function withdrawLocked(bytes32 kek_id)
        public
        override
        nonReentrant
        updateReward(msg.sender)
    {
        LockedStake memory thisStake;
        thisStake.amount = 0;
        uint256 theIndex;
        for (uint256 i = 0; i < lockedStakes[msg.sender].length; i++) {
            if (kek_id == lockedStakes[msg.sender][i].kek_id) {
                thisStake = lockedStakes[msg.sender][i];
                theIndex = i;
                break;
            }
        }
        require(thisStake.kek_id == kek_id, "Stake not found");

        uint256 theAmount = thisStake.amount;
        uint256 boostedAmount = theAmount.mul(thisStake.multiplier).div(
            PRICE_PRECISION
        );
        if (theAmount > 0) {
            // Staking token balance and boosted balance
            _locked_balances[msg.sender] = _locked_balances[msg.sender].sub(
                theAmount
            );
            _boosted_balances[msg.sender] = _boosted_balances[msg.sender].sub(
                boostedAmount
            );

            // Staking token supply and boosted supply
            _staking_token_supply = _staking_token_supply.sub(theAmount);
            _staking_token_boosted_supply = _staking_token_boosted_supply.sub(
                boostedAmount
            );

            // Remove the stake from the array
            delete lockedStakes[msg.sender][theIndex];
            vToken.burn(msg.sender, theAmount);

            if (
                block.timestamp >= thisStake.ending_timestamp ||
                unlockedStakes == true
            ) {
                stakingToken.safeTransfer(msg.sender, theAmount);
                emit WithdrawnLocked(msg.sender, theAmount, kek_id);
            } else {
                stakingToken.safeTransfer(msg.sender, theAmount / 2);
                stakingToken.safeTransfer(owner_address, theAmount / 2);
                emit WithdrawnLockedPenalty(msg.sender, theAmount / 2, kek_id);
            }
        }
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint256 minting_fee_amount = reward.mul(minting_fee).div(
                MULTIPLIER_BASE
            );
            rewardsToken.transfer(msg.sender, reward.sub(minting_fee_amount));
            rewardsToken.transfer(owner_mintingfee_address, minting_fee_amount);
            totalClaimedRewards[msg.sender] = totalClaimedRewards[msg.sender]
            .add(reward.sub(minting_fee_amount));
            emit RewardPaid(msg.sender, reward);
        }
    }

    function getUserTotalRewards(address _addr)
        public
        view
        returns (uint256 userTotalClaimedRewards)
    {
        userTotalClaimedRewards = totalClaimedRewards[_addr];
    }

    function notifyRewardAmount(uint256 reward, uint256 _rewardsDuration)
        external
        onlyByOwnerOrGovernance
        updateReward(address(0))
    {
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        // uint256 balance = rewardsToken.balanceOf(address(this));
        if (block.timestamp >= periodFinish) {
            // require(reward <= balance, "Provided reward too high");
            rewardsDuration = _rewardsDuration;
            periodFinish = block.timestamp.add(rewardsDuration);
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            reward = reward.add(leftover);
            // require(reward <= balance, "Provided reward too high");
            rewardRate = reward.div(remaining);
        }

        lastUpdateTime = block.timestamp;
        emit RewardAdded(reward, _rewardsDuration);
    }

    // Added to support recovering LP Rewards from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyByOwnerOrGovernance
    {
        // Admin cannot withdraw the staking token from the contract
        require(tokenAddress != address(stakingToken));
        ERC20(tokenAddress).transfer(owner_address, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration)
        external
        onlyByOwnerOrGovernance
    {
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setMultipliers(
        uint256 _locked_stake_max_multiplier,
        uint256 _cr_boost_max_multiplier
    ) external onlyByOwnerOrGovernance {
        require(
            _locked_stake_max_multiplier >= 1,
            "Multiplier must be greater than or equal to 1"
        );
        require(
            _cr_boost_max_multiplier >= 1,
            "Max CR Boost must be greater than or equal to 1"
        );

        locked_stake_max_multiplier = _locked_stake_max_multiplier;
        cr_boost_max_multiplier = _cr_boost_max_multiplier;

        emit MaxCRBoostMultiplier(cr_boost_max_multiplier);
        emit LockedStakeMaxMultiplierUpdated(locked_stake_max_multiplier);
    }

    function setLockedStakeTimeForMinAndMaxMultiplier(
        uint256 _locked_stake_time_for_max_multiplier,
        uint256 _locked_stake_min_time
    ) external onlyByOwnerOrGovernance {
        require(
            _locked_stake_time_for_max_multiplier >= 1,
            "Multiplier Max Time must be greater than or equal to 1"
        );
        require(
            _locked_stake_min_time >= 1,
            "Multiplier Min Time must be greater than or equal to 1"
        );

        locked_stake_time_for_max_multiplier = _locked_stake_time_for_max_multiplier;

        locked_stake_min_time = _locked_stake_min_time;
        locked_stake_min_time_str = uint2str(_locked_stake_min_time);

        emit LockedStakeTimeForMaxMultiplier(
            locked_stake_time_for_max_multiplier
        );
        emit LockedStakeMinTime(_locked_stake_min_time);
    }

    function initializeDefault() external onlyByOwnerOrGovernance {
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        owner_mintingfee_address = owner_address;
        emit DefaultInitialization();
    }

    function setVtoken(address _addr) external onlyByOwnerOrGovernance {
        vToken = ERC20(_addr);
    }

    function unlockStakes() external onlyByOwnerOrGovernance {
        unlockedStakes = !unlockedStakes;
    }

    function setRewardRate(uint256 _new_rate) external onlyByOwnerOrGovernance {
        rewardRate = _new_rate;
    }

    function setMintingFee(uint256 _minting_fee)
        external
        onlyByOwnerOrGovernance
    {
        minting_fee = _minting_fee;
    }

    function setMintingFeeAddress(address _feeAddress)
        external
        onlyByOwnerOrGovernance
    {
        owner_mintingfee_address = _feeAddress;
    }

    function setOwnerAndTimelock(address _new_owner, address _new_timelock)
        external
        onlyByOwnerOrGovernance
    {
        owner_address = _new_owner;
        timelock_address = _new_timelock;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyByOwnerOrGovernance() {
        require(
            msg.sender == owner_address || msg.sender == timelock_address,
            "You are not the owner or the governance timelock"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint256 duration);
    event Staked(address indexed user, uint256 amount);
    event StakeLocked(address indexed user, uint256 amount, uint256 secs);
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawnLocked(address indexed user, uint256 amount, bytes32 kek_id);
    event WithdrawnLockedPenalty(
        address indexed user,
        uint256 amount,
        bytes32 kek_id
    );
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event RewardsPeriodRenewed(address token);
    event DefaultInitialization();
    event LockedStakeMaxMultiplierUpdated(uint256 multiplier);
    event LockedStakeTimeForMaxMultiplier(uint256 secs);
    event LockedStakeMinTime(uint256 secs);
    event MaxCRBoostMultiplier(uint256 multiplier);
}