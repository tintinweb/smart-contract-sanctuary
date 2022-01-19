/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

// This contract handles locking PKN to get rewards
contract LockedPool12 is Ownable {

    uint256 public constant TIER_MIN = 98000 * 10**18;
    uint256 public constant TIER_MID = TIER_MIN * 10;
    uint256 public constant TIER_MAX = TIER_MIN * 100;
    
    uint256 public constant REWARD_MIN = 25;
    uint256 public constant REWARD_MID = 30;
    uint256 public constant REWARD_MAX = 35;

    uint256 public constant TOTAL_DURATION = 365 days;
    uint256 public constant ENTRY_LIMIT = 1671624000; // Wednesday, December 21, 2022 12:00:00 PM GMT

    uint256 public totalOwed;
    uint256 public totalDeposit;

    mapping(address => uint256) private userOwed;
    mapping(address => uint256) private userDeposit;
    mapping(address => uint256) private userFirstTS;

    IERC20 public immutable PKN;

    constructor(IERC20 _PKN) {
        PKN = _PKN;
    }

    function splitTiers(uint256 amount) public pure returns(uint256 tA, uint256 tB, uint256 tC) {
        if(amount > TIER_MAX) {
            tC = amount - TIER_MAX;
        }
        if(amount > TIER_MID) {
            tB = amount - tC - TIER_MID;
        }
        tA = amount - tC - tB;
    }

    function depositOf(address account) public view returns (uint256) {
        return userDeposit[account];
    }

    function totalRewardOf(address account) public view returns (uint256) {
        return userOwed[account];
    }

    function unlockTimeOf(address account) public view returns (uint256) {
        require(userFirstTS[account] != 0, "No deposit yet");
        return userFirstTS[account] + TOTAL_DURATION;
    }

    function pendingRewards() external view returns(uint256 pending) {
        uint256 currentBalance = PKN.balanceOf(address(this));
        if(totalOwed > currentBalance) {
            pending = totalOwed - currentBalance;
        }
    }

    function enter(uint256 _amount) external {
        require(block.timestamp < ENTRY_LIMIT, "Locking period ended");

        uint256 amount = _receivePKN(msg.sender, _amount);
        uint256 uDeposit = userDeposit[msg.sender];
        uint256 uTotal = uDeposit + amount;

        require(uTotal >= TIER_MIN, "Amount less than minimum deposit");

        (uint256 depA, uint256 depB, uint256 depC) = splitTiers(uDeposit);
        (uint256 totA, uint256 totB, uint256 totC) = splitTiers(uTotal);

        uint256 amtA = totA - depA;
        uint256 amtB = totB - depB;
        uint256 amtC = totC - depC;

        if(uDeposit == 0) {
            // first deposit for this user
            userFirstTS[msg.sender] = block.timestamp;
        }

        uint256 remainingTime = unlockTimeOf(msg.sender) - block.timestamp;
        uint256 owed;
        if(amtA > 0) {
            owed += amtA + amtA * REWARD_MIN * remainingTime / (100 * TOTAL_DURATION);
        }

        if(amtB > 0) {
            owed += amtB + amtB * REWARD_MID * remainingTime / (100 * TOTAL_DURATION);
        }

        if(amtC > 0) {
            owed += amtC + amtC * REWARD_MAX * remainingTime / (100 * TOTAL_DURATION);
        }

        userDeposit[msg.sender] += amount;
        totalDeposit += amount;
        userOwed[msg.sender] += owed;
        totalOwed += owed;
    }

    function leave() external {
        require(block.timestamp >= unlockTimeOf(msg.sender), "Not unlocked yet");

        uint256 amount = userOwed[msg.sender];
        require(amount > 0, "No pending withdrawal");
        userOwed[msg.sender] = 0;
        totalOwed -= amount;
        PKN.transfer(msg.sender, amount);
    }

    // only to be called in an emergency after a wait period of 2 * TOTAL_DURATION
    function emergencyRescue() external onlyOwner() {
        require(block.timestamp >= ENTRY_LIMIT + 2 * TOTAL_DURATION, "Not needed yet");
        PKN.transfer(msg.sender, PKN.balanceOf(address(this)));
    }

    function _receivePKN(address from, uint256 amount) internal returns (uint256) {
        uint256 balanceBefore = PKN.balanceOf(address(this));
        PKN.transferFrom(from, address(this), amount);
        return PKN.balanceOf(address(this)) - balanceBefore;
    }
}