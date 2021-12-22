//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    /* ========== STATE VARIABLES ========== */

    struct Stake {
        uint256 amount;
        uint256 stakeTime;
        uint256 fee;
    }

    uint256 public minimumStake = 1000 * 1e18;
    uint256 public lockPeriod = 31 days;

    uint256 public totalStaked; // total amount of tokens staked
    uint256 public rewardRate; // token rewards per second
    uint256 public beginDate; // start date of rewards
    uint256 public endDate; // end date of rewards
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public feePerToken;
    address public compound; // compound contract address
    IERC20 public stakedToken; // token allowed to be staked

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public fees;
    mapping(address => Stake[]) public stakes;

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event FeeDistributed(uint256 block, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 index);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IERC20 _stakedToken,
        uint256 _beginDate,
        uint256 _endDate
    ) {
        stakedToken = _stakedToken;
        beginDate = _beginDate;
        endDate = _endDate;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount)
        external
        started
        distributeReward(msg.sender)
    {
        require(amount >= minimumStake, "Stake too small");
        totalStaked += amount;
        stakes[msg.sender].push(Stake(amount, block.timestamp, feePerToken));
        stakedToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function claim() external started distributeReward(msg.sender) {
        uint256 reward = rewards[msg.sender];

        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            reward +=
                stakes[msg.sender][i].amount *
                (feePerToken - stakes[msg.sender][i].fee);
            stakes[msg.sender][i].fee = feePerToken;
        }

        reward += fees[msg.sender];
        fees[msg.sender] = 0;

        if (reward > 0) {
            rewards[msg.sender] = 0;
            stakedToken.transfer(msg.sender, reward);
            emit Claimed(msg.sender, reward);
        }
    }

    function unstake(uint256 amount, uint256 index)
        public
        started
        distributeReward(msg.sender)
    {
        require(amount > 0, "Cannot unstake 0");
        require(amount <= stakes[msg.sender][index].amount, "Stake too big");
        require(
            stakes[msg.sender][index].stakeTime + lockPeriod <= block.timestamp
        );
        totalStaked -= amount;
        stakes[msg.sender][index].amount -= amount;
        fees[msg.sender] +=
            amount *
            (feePerToken - stakes[msg.sender][index].fee);
        stakedToken.transferFrom(msg.sender, address(this), amount);
        emit Unstaked(msg.sender, amount, index);
    }

    function unstakeAll() external started {
        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            if (
                stakes[msg.sender][i].stakeTime + lockPeriod <= block.timestamp
            ) {
                unstake(stakes[msg.sender][i].amount, i);
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function autoCompStake(uint256 amount) external onlyCompound {
        totalStaked += amount;
    }

    function autoCompUnstake(uint256 amount) external onlyCompound {
        totalStaked -= amount;
    }

    function transferReward(uint256 amount, address recipient)
        external
        onlyCompound
    {
        stakedToken.transferFrom(address(this), recipient, amount);
    }

    function setOnlyCompoundStaking(bool _onlyCompoundStaking)
        public
        onlyOwner
    {}

    function setCompoundAddress(address _compound) public onlyOwner {
        compound = _compound;
    }

    function feeDistribution(uint256 amount) external onlyOwner {
        feePerToken += amount / totalStaked;
        stakedToken.transferFrom(msg.sender, address(this), amount);
        emit FeeDistributed(block.number, amount);
    }

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < endDate ? block.timestamp : endDate;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) /
            totalStaked;
    }

    function pendingReward(address user) public view returns (uint256) {
        uint256 amount;

        for (uint256 i = 0; i < stakes[user].length; i++) {
            amount += stakes[user][i].amount;
        }
        return
            (amount * (rewardPerToken() - (userRewardPerTokenPaid[user]))) /
            (1e18) +
            (rewards[user]);
    }

    function pendingFee(address user) public view returns (uint256) {
        uint256 amount = fees[user];

        for (uint256 i = 0; i < stakes[user].length; i++) {
            amount +=
                stakes[user][i].amount *
                (feePerToken - stakes[user][i].fee);
        }

        return amount;
    }

    function getUserStakes(address user) public view returns (Stake[] memory) {
        return stakes[user];
    }

    function totalUserStakes(address _user) public view returns (uint256) {
        return stakes[_user].length;
    }

    /* ========== MODIFIERS ========== */

    modifier distributeReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = pendingReward(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier started() {
        require(block.timestamp >= beginDate);
        _;
    }

    modifier onlyCompound() {
        require(msg.sender == compound, "Staking:: Only compound");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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