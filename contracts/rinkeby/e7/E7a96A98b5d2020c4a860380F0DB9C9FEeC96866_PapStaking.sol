// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PAPStaking
 * @author gotbit.io
 */

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract PapStaking is Ownable {
    IERC20 public DFTY;

    uint256 public TIER1_MIN_VALUE;
    uint256 public TIER2_MIN_VALUE;
    uint256 public TIER3_MIN_VALUE;

    uint256 public COOLDOWN_TO_UNSTAKE;
    uint256 public APY;
    uint256 public YEAR = 360; //change this for test purposes

    enum Tier {
        NOTIER,
        TIER3,
        TIER2,
        TIER1
    }

    struct StakeInstance {
        uint256 amount;
        uint256 lastInteracted;
        uint256 lastStaked;
        uint256 rewards;
        Tier tier;
    }

    mapping(address => StakeInstance) private stakes;

    event Staked(uint256 indexed timeStamp, uint256 amount, address indexed user);
    event Unstaked(uint256 indexed timeStamp, uint256 amount, address indexed user);
    event RewardsClaimed(uint256 indexed timeStamp, uint256 amount, address indexed user);

    /**
        @dev Creates PapStaking contract
        @param TOKEN_ERC20 address of DFTY token, which user could stake to get Tier and rewards in DFTY
        @param cooldownToUnstake There is cooldown for unstake after user stake tokens. In days
        @param tier3Value value in DFTY tokens, after this user can get Tier 3, or bigger, if less then user will get NOTIER, which doesn't allow to participate in Deftify IDO pools
        @param tier2Value value in DFTY tokens, after this user can get Tier 2, or bigger
        @param tier1Value value in DFTY tokens, after this user can get Tier 1
        @param apy APY in format: x% * 100, only two digits after comma precision for x is allowed! Example: for 20,87% apy is 2087

     */

    constructor(
        address TOKEN_ERC20,
        uint256 cooldownToUnstake,
        uint256 tier3Value,
        uint256 tier2Value,
        uint256 tier1Value,
        uint256 apy
    ) {
        DFTY = IERC20(TOKEN_ERC20);

        TIER1_MIN_VALUE = tier1Value;
        TIER2_MIN_VALUE = tier2Value;
        TIER3_MIN_VALUE = tier3Value;

        COOLDOWN_TO_UNSTAKE = cooldownToUnstake; // in seconds now, but need to change for mainnet

        APY = apy;

        transferOwnership(msg.sender);
    }

    /**
        @notice Stake DFTY tokens to get Tier and be allowed to participate in Deftify PAP Pools.
        @dev Allows msg.sender to stake DFTY tokens (transfer DFTY from this contract to msg.sender) to get Tier, which allows to participate in Deftify IDO pools. If user stakes amount more than TIERX_MIN_VALUE he gets this TIER; 
        @param amount Amount to stake in wei
     */
    function stake(uint256 amount) external {
        require(
            DFTY.balanceOf(msg.sender) >= amount,
            "You don't have enough money to stake"
        );
        require(amount > 0, 'Amount must be grater than zero');

        StakeInstance storage userStake = stakes[msg.sender];
        Tier userTier;

        uint256 pending = getPendingRewards(msg.sender);

        if (pending > 0) {
            userStake.rewards += pending;
            userStake.lastInteracted = block.timestamp;
            require(DFTY.transfer(msg.sender, userStake.rewards), "Transfer DFTY rewards failed!");
            userStake.rewards = 0;
        }

        DFTY.transferFrom(msg.sender, address(this), amount);
        if (userStake.amount + amount >= TIER1_MIN_VALUE) {
            userTier = Tier.TIER1;
        } else if (userStake.amount + amount >= TIER2_MIN_VALUE) {
            userTier = Tier.TIER2;
        } else if (userStake.amount + amount >= TIER3_MIN_VALUE) {
            userTier = Tier.TIER3;
        } else userTier = Tier.NOTIER;

        userStake.amount += amount;
        userStake.lastStaked = block.timestamp;
        userStake.tier = userTier;
        emit Staked(block.timestamp, amount, msg.sender);
    }

    /**
        @notice Unstake DFTY tokens
        @dev This function allows user to unstake (transfer DFTY from this contract to msg.sender) amount of DFTY tokens, checks if COOLDOWN_TO_UNSTAKE
        is passed since user last stake (userStake.lastStaked), updates user rewards in DFTY tokens. 
        If user unstake DFTY, and if remaining amount of staked tokens will be less than TIER minimal
        amount user's Tier can decrease (Tier1 => Tier2 => Tier3 => NoTier)
        @param amount amount in wei of DFTY tokens to unstake, can't be bigger than userStake.amount
     */
    function unstake(uint256 amount) external {
        require(amount > 0, 'Cannot unstake 0');
        StakeInstance storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, 'Cannot unstake amount more than available');
        require(
            block.timestamp >= userStake.lastStaked + COOLDOWN_TO_UNSTAKE,
            'Cooldown for unstake is not finished yet!'
        ); //for test in seconds now
        Tier userTier;
        uint256 pending = getPendingRewards(msg.sender);
        if (pending > 0) {
            userStake.rewards += pending;
            userStake.lastInteracted = block.timestamp;
            require(DFTY.transfer(msg.sender, userStake.rewards), "Transfer DFTY rewards failed!");
            userStake.rewards = 0;
        }

        DFTY.transfer(msg.sender, amount);

        if (userStake.amount - amount >= TIER1_MIN_VALUE) {
            userTier = Tier.TIER1;
        } else if (userStake.amount - amount >= TIER2_MIN_VALUE) {
            userTier = Tier.TIER2;
        } else if (userStake.amount - amount >= TIER3_MIN_VALUE) {
            userTier = Tier.TIER3;
        } else userTier = Tier.NOTIER;
        userStake.amount -= amount;
        userStake.tier = userTier;
        emit Unstaked(block.timestamp, amount, msg.sender);
    }

    /**
        @notice Claim reward in DFTY tokens for participating in staking programm
        @dev Allows user to claim his rewards. Reward = stakes[user].amount + pendingRewards since last time interacted with this contract;
     */
    function claimRewards() external {
        uint256 pending = getPendingRewards(msg.sender);
        uint256 amount = stakes[msg.sender].rewards + pending;
        require(amount > 0, 'Nothing to claim now');
        require(DFTY.transfer(msg.sender, amount), 'ERC20: transfer issue');
        stakes[msg.sender].lastInteracted = block.timestamp;
        stakes[msg.sender].rewards = 0;
        emit RewardsClaimed(block.timestamp, amount, msg.sender);
    }

    /**
        @notice Get full info of user's stake
        @dev Returns a StakeInstance structure
        @param user address of user
        @return StakeInstance structure 
     */
    function UserInfo(address user) external view returns (StakeInstance memory) {
        return stakes[user];
    }

    /**
        @notice Get current rewards amount of a user
        @dev This function need for UI, returns current rewards amount of a user at this point in time
        @param user address of a user
        @return uint256 : rewards amount in wei
     */
    function getRewardInfo(address user) external view returns (uint256) {
        uint256 amount = getPendingRewards(user) + stakes[user].rewards;
        return amount;
    }

    /**
        @notice Get pending rewards at this point of time
        @dev Returns rewards of user based on his staked amount, APY and time passed since last time he interacted with a stake: used functions as a claimRewards, stake, unstake; 
        @param user address of a user
        @return uint256 user's pending rewards
     */
    function getPendingRewards(address user) internal view returns (uint256) {
        StakeInstance memory userStake = stakes[user];
        uint256 timePassed = block.timestamp - userStake.lastInteracted;
        uint256 pending = (userStake.amount * APY * timePassed) / (1 * YEAR) / 10000;
        return pending;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}