//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Staking.sol";

// compound once a day
contract Compound is Ownable {
    /* ========== STATE VARIABLES ========== */

    struct UserInfo {
        uint256 sharePrice;
        uint256 shares; // number of shares for a user
        uint256 stakeTime; // time of user deposit
        uint256 fee;
    }

    uint256 public shareWorth;
    uint256 public lastUpdateTime;
    uint256 public shares;
    IERC20 public stakedToken;
    Staking public staking;

    mapping(address => UserInfo[]) public userInfo;

    /* ========== EVENTS ========== */

    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 shares,
        uint256 lastDepositedTime
    );
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender);

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20 _stakedToken, address _staking) {
        stakedToken = _stakedToken;
        staking = Staking(_staking);
        lastUpdateTime = staking.beginDate();

        shareWorth = 1 ether;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint256 amount) external started updateShareWorth {
        require(amount >= staking.MINIMUM_STAKE(), "Stake too small");
        shares += amount / shareWorth;
        userInfo[msg.sender].push(
            UserInfo(
                shareWorth,
                amount / shareWorth,
                block.timestamp,
                staking.feePerToken()
            )
        );
        staking.autoCompStake(amount);
        stakedToken.transferFrom(
            msg.sender,
            address(staking),
            (amount / shareWorth) * shareWorth
        );
        emit Deposit(
            msg.sender,
            (amount / shareWorth) * shareWorth,
            currentAmount(msg.sender),
            block.timestamp
        );
    }

    function withdrawAll() external {
        for (uint256 i = 0; i < userInfo[msg.sender].length; i++) {
            if (
                userInfo[msg.sender][i].stakeTime + staking.LOCK_PERIOD() <=
                block.timestamp
            ) {
                withdraw(userInfo[msg.sender][i].shares, i);
            }
        }
    }

    function withdraw(uint256 _shares, uint256 index)
        public
        started
        updateShareWorth
    {
        require(_shares > 0, "Cannot unstake 0");
        require(_shares <= userInfo[msg.sender][index].shares, "Stake too big");
        require(
            userInfo[msg.sender][index].stakeTime + staking.LOCK_PERIOD() <=
                block.timestamp,
            "Minimum lock period hasn't passed"
        );
        shares -= _shares;
        userInfo[msg.sender][index].shares -= _shares;

        staking.addFee(
            msg.sender,
            (_shares *
                userInfo[msg.sender][index].sharePrice *
                (staking.feePerToken() - userInfo[msg.sender][index].fee)) /
                1 ether
        );

        staking.autoCompUnstake(_shares * shareWorth, index);
        staking.transferReward(_shares * shareWorth, msg.sender);
        emit Withdraw(msg.sender, currentAmount(msg.sender), _shares);
    }

    function calculateFees(address user) external {
        for (uint256 i = 0; i < userInfo[user].length; i++) {
            staking.addFee(
                user,
                ((userInfo[user][i].shares * userInfo[user][i].sharePrice) *
                    (staking.feePerToken() - userInfo[user][i].fee)) / 1 ether
            );
            userInfo[user][i].fee = staking.feePerToken();
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function harvest() external updateShareWorth {
        emit Harvest(msg.sender);
    }

    /* ========== VIEWS ========== */

    function currentAmount(address user) public view returns (uint256) {
        uint256 amount;
        for (uint256 i = 0; i < userInfo[user].length; i++) {
            amount += userInfo[msg.sender][i].shares;
        }
        return amount;
    }

    /* ========== MODIFIERS ========== */

    modifier updateShareWorth() {
        if (staking.totalStaked() > 0) {
            for (
                uint256 i = 0;
                i <
                (staking.lastTimeRewardApplicable() - lastUpdateTime) / 86400;
                i++
            ) {
                uint256 placeHolder = shareWorth;
                shareWorth +=
                    (shareWorth *
                        ((86400 * staking.rewardRate() * 1 ether) /
                            staking.totalStaked())) /
                    1 ether;

                staking.autoCompStake(shares * (shareWorth - placeHolder));
            }

            lastUpdateTime =
                (staking.lastTimeRewardApplicable() / 86400) *
                86400;
        }
        _;
    }

    modifier started() {
        require(
            block.timestamp >= staking.beginDate(),
            "Stake period hasn't started"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Compound.sol";

contract Staking is Ownable {
    /* ========== STATE VARIABLES ========== */

    struct Stake {
        uint256 amount;
        uint256 stakeTime;
        uint256 fee;
    }

    uint256 public constant MINIMUM_STAKE = 1000 ether;
    uint256 public constant LOCK_PERIOD = 10 minutes;

    uint256 public totalStaked; // total amount of tokens staked
    uint256 public rewardRate; // token rewards per second
    uint256 public beginDate; // start date of rewards
    uint256 public endDate; // end date of rewards
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public feePerToken;
    bool public onlyCompoundStaking;
    Compound public compound; // compound contract address
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
    event RewardAdded(uint256 amount);

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
        require(amount >= MINIMUM_STAKE, "Stake too small");
        require(!onlyCompoundStaking, "Only auto-compound staking allowed");
        totalStaked += amount;
        stakes[msg.sender].push(Stake(amount, block.timestamp, feePerToken));
        stakedToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function claim() external started distributeReward(msg.sender) {
        uint256 reward = rewards[msg.sender];

        fees[msg.sender] = pendingFee(msg.sender);
        compound.calculateFees(msg.sender);

        reward += fees[msg.sender];

        if (reward > 0) {
            fees[msg.sender] = 0;
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
            stakes[msg.sender][index].stakeTime + LOCK_PERIOD <=
                block.timestamp,
            "Minimum lock period hasn't passed"
        );

        totalStaked -= amount;
        stakes[msg.sender][index].amount -= amount;
        fees[msg.sender] +=
            ((amount) * (feePerToken - stakes[msg.sender][index].fee)) /
            1 ether;
        stakedToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount, index);
    }

    function unstakeAll() external {
        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            if (
                stakes[msg.sender][i].stakeTime + LOCK_PERIOD <= block.timestamp
            ) {
                unstake(stakes[msg.sender][i].amount, i);
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addFee(address user, uint256 amount) external onlyCompound {
        fees[user] += amount;
    }

    function addReward(uint256 amount)
        external
        onlyOwner
        distributeReward(address(0))
    {
        require(amount > 0, "Cannot add 0 reward");
        rewardRate += (amount) / (endDate - firstTimeRewardApplicable());

        stakedToken.transferFrom(
            msg.sender,
            address(this),
            ((amount) / (endDate - firstTimeRewardApplicable())) *
                (endDate - firstTimeRewardApplicable())
        );

        emit RewardAdded(
            ((amount) / (endDate - firstTimeRewardApplicable())) *
                (endDate - firstTimeRewardApplicable())
        );
    }

    function autoCompStake(uint256 amount) external onlyCompound {
        totalStaked += amount;
        emit Staked(tx.origin, amount);
    }

    function autoCompUnstake(uint256 amount, uint256 index)
        external
        onlyCompound
    {
        totalStaked -= amount;
        emit Unstaked(tx.origin, amount, index);
    }

    function transferReward(uint256 amount, address recipient)
        external
        onlyCompound
    {
        stakedToken.transfer(recipient, amount);
    }

    function setOnlyCompoundStaking(bool _onlyCompoundStaking)
        external
        onlyOwner
    {
        onlyCompoundStaking = _onlyCompoundStaking;
    }

    function setCompoundAddress(address _compound) external onlyOwner {
        compound = Compound(_compound);
    }

    function feeDistribution(uint256 amount) external onlyOwner {
        require(amount > 0, "Cannot distribute 0 fee");
        require(totalStaked > 0, "Noone to distribute fee to");

        feePerToken += (amount * 1 ether) / (totalStaked);

        stakedToken.transferFrom(
            msg.sender,
            address(this),
            (((amount * 1 ether) / (totalStaked)) * totalStaked) / 1 ether
        );

        emit FeeDistributed(
            block.timestamp,
            (((amount * 1 ether) / (totalStaked)) * totalStaked) / 1 ether
        );
    }

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < endDate ? block.timestamp : endDate;
    }

    function firstTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < beginDate ? beginDate : block.timestamp;
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
                ((stakes[user][i].amount) *
                    (feePerToken - stakes[user][i].fee)) /
                1 ether;
        }

        return amount;
    }

    function getUserStakes(address user)
        external
        view
        returns (Stake[] memory)
    {
        return stakes[user];
    }

    function totalUserStakes(address _user) external view returns (uint256) {
        return stakes[_user].length;
    }

    /* ========== MODIFIERS ========== */

    modifier distributeReward(address account) {
        compound.harvest();
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = pendingReward(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier started() {
        require(block.timestamp >= beginDate, "Stake period hasn't started");
        _;
    }

    modifier onlyCompound() {
        require(msg.sender == address(compound), "Only compound");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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