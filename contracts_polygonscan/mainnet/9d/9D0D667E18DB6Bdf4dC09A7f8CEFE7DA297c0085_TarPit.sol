/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/******************************************/
/*       IERC20 starts here               */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

    /**a
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

/******************************************/
/*       Context starts here              */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/******************************************/
/*       Ownable starts here              */
/******************************************/

// File: @openzeppelin/contracts/access/Ownable.sol

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

/******************************************/
/*          TarPit starts here            */
/******************************************/

contract TarPit is Ownable {
    
    IERC20 public immutable DINO;
    uint256 constant secondsPerYear = 31536000;
    uint256 public stakedDinos;

    mapping(address => TokenLock[]) public locks;
    mapping(uint8 => LockingPeriod) public lockingPeriods;

    struct TokenLock {
        uint256 amount;
        uint256 validity;
        uint256 reward;
        bool claimed;
    }

    struct LockingPeriod {
        uint256 duration;
        uint256 multiplier;
    }

    event Locked (address indexed _of, uint256 _amount, uint256 _reward, uint256 _validity);
    event Unlocked (address indexed _of, uint256 _amount);
    event EmergencyUnlocked (address indexed _of, uint256 _amount);

    constructor(IERC20 _DINO) {
        DINO = _DINO;
        
    }

    /**
     * @dev Locks a specified amount of tokens against an address,
     *      for a specified time.
     * @param _amount Number of tokens to be locked.
     * @param _lockingPeriod Identifier of locking period.
     */
    function lock(uint256 _amount, uint8 _lockingPeriod) external returns (bool) {
        require(_amount != 0, "Amount must not be zero.");
        require(lockingPeriods[_lockingPeriod].duration != 0 && lockingPeriods[_lockingPeriod].multiplier != 0, "Invalid locking period.");
        uint256 duration = lockingPeriods[_lockingPeriod].duration;
        uint256 validUntil = block.timestamp + duration;
        uint256 lockMultiplier = lockingPeriods[_lockingPeriod].multiplier;
        uint256 lockReward = (lockMultiplier * _amount / 1000) * duration / secondsPerYear;  // 1 year (31536000) = 100% rewards

        DINO.transferFrom(msg.sender, address(this), _amount);
        stakedDinos += _amount + lockReward;
        locks[msg.sender].push(TokenLock(_amount, validUntil, lockReward, false));

        emit Locked(msg.sender, _amount, lockReward, validUntil);
        return true;
    }
    
    /**
     * @dev Transfers and locks a specified amount of tokens,
     *      for a specified time.
     * @param _to Address to which tokens are to be transferred.
     * @param _amount Number of tokens to be transferred and locked.
     * @param _lockingPeriod Identifier of locking period.
     */
    function transferWithLock(address _to, uint256 _amount, uint8 _lockingPeriod) external returns (bool) {
        require(_amount != 0, "Amount must not be zero.");
        require(lockingPeriods[_lockingPeriod].duration != 0 && lockingPeriods[_lockingPeriod].multiplier != 0, "Invalid locking period.");
        uint256 duration = lockingPeriods[_lockingPeriod].duration;
        uint256 validUntil = block.timestamp + duration;
        uint256 lockMultiplier = lockingPeriods[_lockingPeriod].multiplier;
        uint256 lockReward = (lockMultiplier * _amount / 1000) * duration / secondsPerYear; // 1 year (31536000) = 100% rewards

        DINO.transferFrom(msg.sender, address(this), _amount);
        stakedDinos += _amount + lockReward;
        locks[_to].push(TokenLock(_amount, validUntil, lockReward, false));

        emit Locked(_to, _amount, lockReward, validUntil);
        return true;
    }
  
    /**
     * @dev Gets the unlockable tokens of a specified address.
     * @param _of The address to query the unlockable token count of.
     */
    function getUnlockableTokens(address _of) public view returns (uint256) {
        uint256 unlockableTokens;
        uint256 locksLength = locks[_of].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (locks[_of][i].validity <= block.timestamp && !locks[_of][i].claimed) {
                unlockableTokens = unlockableTokens + locks[_of][i].amount + locks[_of][i].reward;
            }
        }
        return unlockableTokens;
    }    
    
    /**
     * @dev Gets the locked tokens of a specified address.
     * @param _of The address to query the locked token count of.
     */
    function getLockedTokens(address _of) public view returns (uint256) {
        uint256 lockedTokens;
        uint256 locksLength = locks[_of].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (locks[_of][i].validity > block.timestamp && !locks[_of][i].claimed) {
                lockedTokens = lockedTokens + locks[_of][i].amount + locks[_of][i].reward;
            }
        }
        return lockedTokens;
    }   

    /**
     * @dev Unlocks the unlockable tokens of a specified address.
     * @param _of Address of user, claiming unlockable tokens.
     */
    function unlock(address _of) external returns (uint256) {
        uint256 unlockableTokens;
        uint256 locksLength = locks[_of].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (locks[_of][i].validity <= block.timestamp && !locks[_of][i].claimed) {
                unlockableTokens = unlockableTokens + locks[_of][i].amount + locks[_of][i].reward;
                locks[_of][i].claimed = true;
            }
        }

        if (unlockableTokens > 0) {
            DINO.transfer(_of, unlockableTokens);
            stakedDinos -= unlockableTokens;
            emit Unlocked(_of, unlockableTokens);
        }
        return unlockableTokens;
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     */
    function emergencyWithdraw() external returns (uint256) {
        uint256 unlockableTokens;
        uint256 locksLength = locks[msg.sender].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (locks[msg.sender][i].validity <= block.timestamp && !locks[msg.sender][i].claimed) {
                unlockableTokens = unlockableTokens + locks[msg.sender][i].amount;
                locks[msg.sender][i].claimed = true;
            }
        }
        
        if (unlockableTokens > 0) {
            DINO.transfer(msg.sender, unlockableTokens);
            stakedDinos -= unlockableTokens;
            emit EmergencyUnlocked(msg.sender, unlockableTokens);
        }
        return unlockableTokens;
    }
    
    /**
     * @dev Set duration and multiplier of a specific locking period.
     * @param _lockingPeriod Identifier of the locking period.
     * @param _duration Duration of locking period.
     * @param _multiplier Multiplier of locking period.
     */
    function setLockingPeriod(uint8 _lockingPeriod, uint256 _duration, uint256 _multiplier) external onlyOwner {
        lockingPeriods[_lockingPeriod].duration = _duration;
        lockingPeriods[_lockingPeriod].multiplier = _multiplier; 
    }
    
    /**
     * @dev Transfer DINO tokens.
     * @return Success.
     */
    function emergencyTransfer(address to) external onlyOwner returns (bool) {
        return DINO.transfer(to, DINO.balanceOf(address(this)) - stakedDinos);
    }
    
}