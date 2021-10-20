// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Vesting is Ownable {
    struct Category {
        uint256 lockPeriod;
        uint256 period;
        uint256 timeUnit;
        uint256 afterUnlock;
        uint256 afterUnlockDenominator;
    }
    
    // dev:
    // uint256 constant MONTH = 30 days;
    // uint256 constant WEEK = 7 days;
    // test: 
    uint256 constant MONTH = 5 minutes;
    uint256 constant WEEK = 1 minutes;

    IERC20 token;

    uint256 public startTimestamp;

    mapping(string => Category) public categories;
    mapping(address => mapping(string => uint256)) public allocations;
    mapping(address => uint256) public earned;

    event Claimed(uint256 indexed timestamp, address indexed user, uint256 amount);

    constructor(address tokenAddress, address owner) {
        // setup defaults
        token = IERC20(tokenAddress);
        transferOwnership(owner);

        // setup Categories
        categories['team'] = Category({
            lockPeriod: 6 * MONTH,
            period: 31 * MONTH,
            timeUnit: MONTH,
            afterUnlock: 0,
            afterUnlockDenominator: 100
        });
        categories['marketing'] = Category({
            lockPeriod: 0,
            period: 8 * MONTH,
            timeUnit: MONTH,
            afterUnlock: 0,
            afterUnlockDenominator: 100
        });
        categories['seed'] = Category({
            lockPeriod: 0,
            period: 15 * MONTH,
            timeUnit: MONTH,
            afterUnlock: 10,
            afterUnlockDenominator: 100
        });
        categories['strategic'] = Category({
            lockPeriod: 0,
            period: 12 * MONTH,
            timeUnit: MONTH,
            afterUnlock: 10,
            afterUnlockDenominator: 100
        });
        categories['presale'] = Category({
            lockPeriod: 0,
            period: 5 * MONTH,
            timeUnit: MONTH,
            afterUnlock: 30,
            afterUnlockDenominator: 100
        });
        categories['public'] = Category({
            lockPeriod: 0,
            period: 2 * MONTH,
            timeUnit: 1 * WEEK,
            afterUnlock: 30,
            afterUnlockDenominator: 100
        });
        categories['game'] = Category({
            lockPeriod: 10 days,
            period: 38 * MONTH,
            timeUnit: MONTH,
            afterUnlock: 5,
            afterUnlockDenominator: 100
        });
        categories['eco'] = Category({
            lockPeriod: 3 * MONTH,
            period: 43 * MONTH,
            timeUnit: MONTH,
            afterUnlock: 0,
            afterUnlockDenominator: 100
        });
        categories['community'] = Category({
            lockPeriod: 0,
            period: 37 * MONTH,
            timeUnit: MONTH,
            afterUnlock: 0,
            afterUnlockDenominator: 100
        });
    }

    /// @dev starts claim for users
    function start() public onlyOwner isNotStarted {
        startTimestamp = block.timestamp;
    }

    /// @dev let users to claim their tokens from start to last claim
    function claim() public isStarted {
        uint256 claimed_ = claimed(msg.sender);
        require(claimed_ > 0, 'You dont have tokens now');
        require(
            token.balanceOf(address(this)) > claimed_,
            'Vesting contract doesnt have enough tokens'
        );
        earned[msg.sender] += claimed_;
        token.transfer(msg.sender, claimed_);

        emit Claimed(block.timestamp, msg.sender, claimed_);
    }

    /// @dev calculates claimed amount for user
    function claimed(address user) public view isStarted returns (uint256 amount) {
        uint256 total = claimedInCategory(user, 'team') +
            claimedInCategory(user, 'marketing') +
            claimedInCategory(user, 'seed') +
            claimedInCategory(user, 'strategic') +
            claimedInCategory(user, 'presale') +
            claimedInCategory(user, 'public') +
            claimedInCategory(user, 'game') +
            claimedInCategory(user, 'eco') +
            claimedInCategory(user, 'community') -
            earned[user];
        return total;
    }

    /// @dev calculates for category
    function claimedInCategory(address user, string memory categoryName)
        public
        view
        isStarted
        returns (uint256 amount)
    {
        Category memory category = categories[categoryName];
        uint256 vestingTime = block.timestamp - startTimestamp;

        // before lock period
        if (category.lockPeriod >= vestingTime) return 0;

        // after lock period
        uint256 bank = allocations[user][categoryName];
        uint256 amountOnUnlock = (bank * category.afterUnlock) /
            category.afterUnlockDenominator;

        uint256 timePassed = vestingTime - category.lockPeriod;
        uint256 totalUnits = (category.period - category.lockPeriod) / category.timeUnit;
        uint256 amountOfUnits = timePassed / category.timeUnit;
        uint256 amountAfterUnlock = ((bank - amountOnUnlock) * amountOfUnits) /
            totalUnits;

        return amountOnUnlock + amountAfterUnlock;
    }

    function setupWallets(
        string memory category,
        address[] memory users,
        uint256[] memory allocations_
    ) external onlyOwner isNotStarted {
        require(users.length == allocations_.length, 'Wrong inputs');
        uint256 length = users.length;
        for (uint256 i = 0; i < length; i++) {
            allocations[users[i]][category] = allocations_[i];
        }
    }

    /// @dev Throws if called before start.
    modifier isStarted() {
        require(startTimestamp != 0, 'Vesting have not started yet');
        _;
    }

    /// @dev Throws if called after start.
    modifier isNotStarted() {
        require(startTimestamp == 0, 'Vesting have already started');
        _;
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