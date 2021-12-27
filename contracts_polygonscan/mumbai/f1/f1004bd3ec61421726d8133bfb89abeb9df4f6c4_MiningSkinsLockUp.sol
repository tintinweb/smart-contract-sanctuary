/**
 *Submitted for verification at polygonscan.com on 2021-12-26
*/

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

/**
 * @dev Interface of the TRX20 standard as defined in the EIP.
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

contract MiningSkinsLockUp is Ownable {
    constructor(address _token) public {
        token = IERC20(_token);
    }

    IERC20 token;

    struct LockUpRecord {
        address owner;
        uint256 amount;
        uint withdrawSumm;
        uint startTime;
        uint lastPaymentTime;
        bool complete;
    }

    //dev
    mapping(address => LockUpRecord) public lockup_record;
    //the time for which tokens are frozen before the start of payment 240 days
    uint constant LOCKUP_FREEZE = 1 minutes;
    //the period between token payments is 30 days
    uint constant PERIOD_TIME = 10 seconds;
    //the percentage that is paid during the period
    uint constant PERIOD_PERCENT = 10;
    //number of investors     
    uint public countHolders = 0;
    //number of lock tokens    
    uint public lockupFounds = 0;
    //number of tokens withdrawn    
    uint public withdrawFounds = 0;

    event NewFounder(address indexed _to, uint amount);
    event UnlockFounds(address indexed _to, uint _amount);
    event LockupComplete(address indexed _to, uint _amount);

    //The function of blocking tokens on the owner's account
    function lockUp(address _target, uint256 _amount) public onlyOwner {
        require(_target != address(0));
        require(_amount > 0);

        uint256 balance = token.balanceOf(address(this));
        
        if (lockupFounds != 0) {
            balance = balance - lockupFounds;
        }
        require(_amount <= balance);

        lockup_record[_target] = LockUpRecord({
            owner: _target,
            amount: _amount,
            withdrawSumm: 0,
            startTime: block.timestamp,
            lastPaymentTime: 0,
            complete: false
        });

        lockupFounds += _amount;
        countHolders++;
        emit NewFounder(_target, _amount);
    }

    function unlock() public isNotFreeze {
        LockUpRecord storage lock = lockup_record[_msgSender()];
        require(msg.sender == lock.owner);
        require(lock.complete == false);
        //get balance available for withdrawal
        uint withdrawalBalance = getWithdrawalBalance(_msgSender());

        require(withdrawalBalance > 0, 'The balance available for withdrawal is 0');

        lock.withdrawSumm += withdrawalBalance;
        lock.lastPaymentTime = block.timestamp;

        if (lock.withdrawSumm <= lock.amount) {
            token.transfer(_msgSender(), withdrawalBalance);
            emit UnlockFounds(lock.owner, withdrawalBalance);
        }

        lockupFounds -= withdrawalBalance;
        withdrawFounds += withdrawalBalance;

        if (lock.withdrawSumm == lock.amount) {
            lock.complete = true;
            emit LockupComplete(_msgSender(), lock.amount);
        }
    }

    modifier isNotFreeze() {
        LockUpRecord storage locupToken = lockup_record[_msgSender()];
        uint unfreezeTime = locupToken.startTime + LOCKUP_FREEZE + PERIOD_TIME;
        require(block.timestamp >= unfreezeTime, "Founds is freeze");
        _;
    }

    // The function of obtaining the balance available for withdrawal
    function getWithdrawalBalance(address _target) public view returns(uint) {
        LockUpRecord storage lockupToken = lockup_record[_target];
        uint unfreezeTime = lockupToken.startTime + LOCKUP_FREEZE;

        if (block.timestamp < unfreezeTime || lockupToken.complete == true) {
            return 0;
        }

        uint timeLeft = block.timestamp - unfreezeTime;
        uint periodLeft = timeLeft / PERIOD_TIME;
        uint periodAmt = lockupToken.amount / PERIOD_PERCENT;
        uint availableWithdraw = (periodLeft * periodAmt) - lockupToken.withdrawSumm;
        uint totalWithdrawal = lockupToken.withdrawSumm + availableWithdraw;

        if (totalWithdrawal > lockupToken.amount) {
            return lockupToken.amount - lockupToken.withdrawSumm;
        }

        return (availableWithdraw);
    }
}