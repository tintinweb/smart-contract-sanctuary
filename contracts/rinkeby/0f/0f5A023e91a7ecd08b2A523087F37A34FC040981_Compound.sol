//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// compound once a day
contract Compound is Ownable {
    /* ========== STATE VARIABLES ========== */

    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 stakeTime; // time of user deposit
        uint256 fee;
        uint256 excess;
    }

    uint256 public constant MINIMUM_STAKE = 1000 ether;
    uint256 public constant LOCK_PERIOD = 7 days;

    uint256 public totalStaked; // total amount of tokens staked
    uint256 public totalShares;
    uint256 public rewardRate; // token rewards per second
    uint256 public beginDate; // start date of rewards
    uint256 public endDate; // end date of rewards
    uint256 public lastUpdateTime;
    uint256 public feePerShare;
    uint256 public shareWorth;

    IERC20 public stakedToken; // token allowed to be staked

    mapping(address => uint256) public fees;
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
        lastUpdateTime = _beginDate;
        beginDate = _beginDate;
        endDate = _endDate;
        shareWorth = 1 ether;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claim() external started updateShareWorth {
        uint256 reward;

        reward += calculateFees(msg.sender);
        reward += fees[msg.sender];

        if (reward > 0) {
            fees[msg.sender] = 0;
            stakedToken.transfer(msg.sender, reward);
            emit Claimed(msg.sender, reward);
        }
    }

    function deposit(uint256 amount) external started updateShareWorth {
        require(amount >= MINIMUM_STAKE, "Stake too small");

        totalShares += (amount) / shareWorth;

        userInfo[msg.sender].push(
            UserInfo(
                amount / shareWorth,
                block.timestamp,
                feePerShare,
                amount - ((amount / shareWorth) * shareWorth)
            )
        );

        totalStaked -= ((amount / shareWorth) * shareWorth);
        stakedToken.transferFrom(msg.sender, address(this), amount);

        emit Deposit(
            msg.sender,
            amount,
            currentAmount(msg.sender),
            block.timestamp
        );
    }

    function withdrawAll() external updateShareWorth {
        uint256 _totalShares;
        uint256 _excess;

        for (uint256 i = 0; i < userInfo[msg.sender].length; i++) {
            if (
                userInfo[msg.sender][i].stakeTime + LOCK_PERIOD <=
                block.timestamp &&
                userInfo[msg.sender][i].shares > 0
            ) {
                uint256 _shares = userInfo[msg.sender][i].shares;
                _totalShares += _shares;
                _excess += userInfo[msg.sender][i].excess;
                userInfo[msg.sender][i].shares -= _shares;
                fees[msg.sender] = ((_shares *
                    (feePerShare - userInfo[msg.sender][i].fee)) / 1 ether);
            }
        }

        if (totalShares > 0) {
            totalShares -= _totalShares;
            totalStaked -= _totalShares * shareWorth;
            stakedToken.transfer(
                msg.sender,
                _totalShares * shareWorth + _excess
            );
            emit Withdraw(msg.sender, currentAmount(msg.sender), _totalShares);
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
            userInfo[msg.sender][index].stakeTime + LOCK_PERIOD <=
                block.timestamp,
            "Minimum lock period hasn't passed"
        );

        totalShares -= _shares;
        userInfo[msg.sender][index].shares -= _shares;

        fees[msg.sender] +=
            (_shares * (feePerShare - userInfo[msg.sender][index].fee)) /
            1 ether;

        totalStaked -= _shares * shareWorth;

        stakedToken.transfer(
            msg.sender,
            _shares * shareWorth + userInfo[msg.sender][index].excess
        );

        emit Withdraw(msg.sender, currentAmount(msg.sender), _shares);
    }

    function calculateFees(address user) internal returns (uint256) {
        uint256 _fees;

        for (uint256 i = 0; i < userInfo[user].length; i++) {
            _fees += ((userInfo[user][i].shares *
                (feePerShare - userInfo[user][i].fee)) / 1 ether);

            userInfo[user][i].fee = feePerShare;
        }

        return _fees;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function harvest() external updateShareWorth {
        emit Harvest(msg.sender);
    }

    function addReward(uint256 amount) external updateShareWorth {
        require(amount > 0, "Cannot add 0 reward");

        uint256 time = (endDate - firstTimeRewardApplicable());
        rewardRate += (amount) / time;

        stakedToken.transferFrom(
            msg.sender,
            address(this),
            (amount / time) * time
        );

        emit RewardAdded((amount / time) * time);
    }

    function feeDistribution(uint256 amount) external {
        require(amount > 0, "Cannot distribute 0 fee");
        require(totalStaked > 0, "Noone to distribute fee to");

        feePerShare += (amount * 1 ether) / (totalShares);
        uint256 result = (((amount * 1 ether) / (totalShares)) * totalShares) /
            1 ether;
        stakedToken.transferFrom(msg.sender, address(this), result);

        emit FeeDistributed(block.timestamp, result);
    }

    /* ========== VIEWS ========== */

    function currentAmount(address user) public view returns (uint256) {
        uint256 amount;

        for (uint256 i = 0; i < userInfo[user].length; i++) {
            amount += userInfo[user][i].shares;
        }

        return amount;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < endDate ? block.timestamp : endDate;
    }

    function firstTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < beginDate ? beginDate : block.timestamp;
    }

    /* ========== MODIFIERS ========== */

    modifier updateShareWorth() {
        if (totalStaked > 0) {
            for (
                uint256 i = 0;
                i < (lastTimeRewardApplicable() - lastUpdateTime) / 1 hours;
                i++
            ) {
                uint256 placeHolder = shareWorth;
                shareWorth += (shareWorth * 1 hours * rewardRate) / totalStaked;
                totalStaked += totalShares * (shareWorth - placeHolder);
            }
            lastUpdateTime = (lastTimeRewardApplicable() / 1 hours) * 1 hours;
        }
        _;
    }

    modifier started() {
        require(block.timestamp >= beginDate, "Stake period hasn't started");
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