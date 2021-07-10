/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


/**
 * @title Vault
 * @dev Contract for locking up tokens for set periods of time
 * Tokens locked in this contract DO NOT count towards voting power
 */
contract Vault {
    using SafeMath for uint256;

    /// @notice Lock definition
    struct Lock {
        address token;
        address receiver;
        uint256 startTime;
        uint256 amount;
        uint16 duration;
        uint256 amountClaimed;
    }

    /// @dev Used to translate lock periods specified in days to seconds
    uint256 constant internal SECONDS_PER_DAY = 86400;
    
    /// @notice Mapping of lock id > token locks
    mapping (uint256 => Lock) public tokenLocks;

    /// @notice Mapping of address to lock id
    mapping (address => uint[]) public activeLocks;

    ///@notice Number of locks
    uint256 public numLocks;

    /// @notice Event emitted when a new lock is created
    event LockCreated(address indexed token, address indexed locker, address indexed receiver, uint256 amount, uint256 startTime, uint16 durationInDays, uint256 lockId);
    
    /// @notice Event emitted when tokens are claimed by a receiver from an unlocked balance
    event UnlockedTokensClaimed(address indexed receiver, address indexed token, uint256 indexed amountClaimed, uint256 lockId);

    /// @notice Event emitted when lock duration extended
    event LockExtended(uint16 indexed oldDuration, uint16 indexed newDuration, uint256 startTime, uint256 lockId);
    
    /**
     * @notice Lock tokens
     * @param locker The account that is locking tokens
     * @param receiver The account that will be able to retrieve unlocked tokens
     * @param startTime The unix timestamp when the lock period will start
     * @param amount The amount of tokens being locked
     * @param lockDurationInDays The lock period in days
     */
    function lockTokens(
        address token,
        address locker,
        address receiver,
        uint256 startTime,
        uint256 amount,
        uint16 lockDurationInDays
    ) 
        external
    {
        require(lockDurationInDays > 0, "Vault::lockTokens: duration must be > 0");
        require(lockDurationInDays <= 25*365, "Vault::lockTokens: duration more than 25 years");
        require(amount > 0, "Vault::lockTokens: amount not > 0");

        // Transfer the tokens under the control of the vault contract
        require(PancakeswapV2BEP20(token).transferFrom(locker, address(this), amount), "Vault::lockTokens: transfer failed");

        uint256 lockStartTime = startTime == 0 ? block.timestamp : startTime;

        Lock memory lock = Lock({
            token: token,
            receiver: receiver,
            startTime: lockStartTime,
            amount: amount,
            duration: lockDurationInDays,
            amountClaimed: 0
        });
        tokenLocks[numLocks] = lock;
        activeLocks[receiver].push(numLocks);
        emit LockCreated(token, locker, receiver, amount, lockStartTime, lockDurationInDays, numLocks);
        numLocks++;
    }

    /**
     * @notice Lock tokens
     * @param token Address of token to lock
     * @param locker The account that is locking tokens
     * @param receiver The account that will be able to retrieve unlocked tokens
     * @param startTime The unix timestamp when the lock period will start
     * @param amount The amount of tokens being locked
     * @param lockDurationInDays The lock period in days
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function lockTokensWithPermit(
        address token,
        address locker,
        address receiver,
        uint256 startTime,
        uint256 amount,
        uint16 lockDurationInDays,
        uint256 deadline,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        external
    {
        require(lockDurationInDays > 0, "Vault::lockTokensWithPermit: duration must be > 0");
        require(lockDurationInDays <= 25*365, "Vault::lockTokensWithPermit: duration more than 25 years");
        require(amount > 0, "Vault::lockTokensWithPermit: amount not > 0");

        // Set approval using permit signature
        PancakeswapV2BEP20(token).permit(locker, address(this), amount, deadline, v, r, s);

        // Transfer the tokens under the control of the vault contract
        require(PancakeswapV2BEP20(token).transferFrom(locker, address(this), amount), "Vault::lockTokensWithPermit: transfer failed");

        uint256 lockStartTime = startTime == 0 ? block.timestamp : startTime;

        Lock memory lock = Lock({
            token: token,
            receiver: receiver,
            startTime: lockStartTime,
            amount: amount,
            duration: lockDurationInDays,
            amountClaimed: 0
        });
        tokenLocks[numLocks] = lock;
        activeLocks[receiver].push(numLocks);
        emit LockCreated(token, locker, receiver, amount, lockStartTime, lockDurationInDays, numLocks);
        numLocks++;
    }

    /**
     * @notice Get token locks for receiver
     * @param receiver The address that has locked balances
     * @return the lock ids
     */
    function getActiveLocks(address receiver) public view returns(uint256[] memory){
        return activeLocks[receiver];
    }

    /**
     * @notice Get token lock for given lock id
     * @param lockId The ID for the locked balance
     * @return the lock
     */
    function getTokenLock(uint256 lockId) public view returns(Lock memory){
        return tokenLocks[lockId];
    }

    /**
     * @notice Get all active token locks for receiver
     * @param receiver The address that has locked balances
     * @return receiverLocks the lock ids
     */
    function getAllActiveLocks(address receiver) public view returns(Lock[] memory receiverLocks){
        uint256[] memory lockIds = getActiveLocks(receiver);
        receiverLocks = new Lock[](lockIds.length);
        for (uint256 i; i < lockIds.length; i++) {
            receiverLocks[i] = getTokenLock(lockIds[i]);
        }
    }

    /**
     * @notice Get total locked token balance of receiver
     * @param token The token to check
     * @param receiver The address that has locked balances
     * @return lockedBalance the total amount of `token` locked 
     */
    function getLockedTokenBalance(address token, address receiver) public view returns(uint256 lockedBalance){
        Lock[] memory locks = getAllActiveLocks(receiver);
        for (uint256 i; i < locks.length; i++) {
            if(locks[i].token == token){
                if(block.timestamp <= locks[i].startTime) {
                    lockedBalance = lockedBalance.add(locks[i].amount);
                } else {
                    // Check if duration was reached
                    uint256 elapsedTime = block.timestamp.sub(locks[i].startTime);
                    uint256 elapsedDays = elapsedTime.div(SECONDS_PER_DAY);

                    if (elapsedDays < locks[i].duration) {
                        lockedBalance = lockedBalance.add(locks[i].amount);
                    }
                }
            }
        }
    }

     /**
     * @notice Get total unlocked token balance of receiver
     * @param token The token to check
     * @param receiver The address that has unlocked balances
     * @return unlockedBalance the total amount of `token` unlocked 
     */
    function getUnlockedTokenBalance(address token, address receiver) public view returns(uint256 unlockedBalance){
        Lock[] memory locks = getAllActiveLocks(receiver);
        for (uint256 i; i < locks.length; i++) {
            if(locks[i].token == token){
                if(block.timestamp > locks[i].startTime) {
                    // Check if duration was reached
                    uint256 elapsedTime = block.timestamp.sub(locks[i].startTime);
                    uint256 elapsedDays = elapsedTime.div(SECONDS_PER_DAY);

                    if (elapsedDays >= locks[i].duration && locks[i].amountClaimed != locks[i].amount) {
                        unlockedBalance = unlockedBalance.add(locks[i].amount).sub(locks[i].amountClaimed);
                    }
                }
            }
        }
    }

    /**
     * @notice Get locked balance for a given lock id
     * @dev Returns 0 if duration has ended
     * @param lockId The lock ID
     * @return The amount that is locked
     */
    function getLockedBalance(uint256 lockId) public view returns (uint256) {
        Lock storage lock = tokenLocks[lockId];

        if (block.timestamp <= lock.startTime) {
            return lock.amount;
        }

        // Check duration was reached
        uint256 elapsedTime = block.timestamp.sub(lock.startTime);
        uint256 elapsedDays = elapsedTime.div(SECONDS_PER_DAY);
        
        if (elapsedDays >= lock.duration) {
            return 0;
        } else {
            return lock.amount;
        }
    }

    /**
     * @notice Get unlocked balance for a given lock id
     * @dev Returns 0 if duration has not ended
     * @param lockId The lock ID
     * @return The amount that can be claimed
     */
    function getUnlockedBalance(uint256 lockId) public view returns (uint256) {
        Lock storage lock = tokenLocks[lockId];

        // For locks created with a future start date, that hasn't been reached, return 0
        if (block.timestamp < lock.startTime) {
            return 0;
        }

        // Check duration was reached
        uint256 elapsedTime = block.timestamp.sub(lock.startTime);
        uint256 elapsedDays = elapsedTime.div(SECONDS_PER_DAY);
        
        if (elapsedDays < lock.duration) {
            return 0;
        } else {
            return lock.amount.sub(lock.amountClaimed);
        }
    }

    /**
     * @notice Allows receiver to claim all of their unlocked tokens for a given lock
     * @dev Errors if no tokens are unlocked
     * @dev It is advised receivers check they are entitled to claim via `getUnlockedBalance` before calling this
     * @param lockId The lock id for an unlocked token balance
     */
    function claimAllUnlockedTokens(uint256 lockId) external {
        uint256 unlockedAmount = getUnlockedBalance(lockId);
        require(unlockedAmount > 0, "Vault::claimAllUnlockedTokens: unlockedAmount is 0");

        Lock storage lock = tokenLocks[lockId];
        lock.amountClaimed = unlockedAmount;
        
        require(msg.sender == lock.receiver, "Vault::claimAllUnlockedTokens: msg.sender must be receiver");
        require(PancakeswapV2BEP20(lock.token).transfer(lock.receiver, unlockedAmount), "Vault::claimAllUnlockedTokens: transfer failed");
        emit UnlockedTokensClaimed(lock.receiver, lock.token, unlockedAmount, lockId);
    }

    /**
     * @notice Allows receiver to claim a portion of their unlocked tokens for a given lock
     * @dev Errors if no tokens are unlocked
     * @dev It is advised receivers check they are entitled to claim via `getUnlockedBalance` before calling this
     * @param lockId The lock id for an unlocked token balance
     * @param amount The amount of unlocked tokens to claim
     */
    function claimUnlockedTokens(uint256 lockId, uint256 amount) external {
        uint256 unlockedAmount = getUnlockedBalance(lockId);
        require(unlockedAmount >= amount, "Vault::claimUnlockedTokens: unlockedAmount < amount");

        Lock storage lock = tokenLocks[lockId];
        lock.amountClaimed = lock.amountClaimed.add(amount);
        
        require(msg.sender == lock.receiver, "Vault::claimUnlockedTokens: msg.sender must be receiver");
        require(PancakeswapV2BEP20(lock.token).transfer(lock.receiver, amount), "Vault::claimUnlockedTokens: transfer failed");
        emit UnlockedTokensClaimed(lock.receiver, lock.token, amount, lockId);
    }

    /**
     * @notice Allows receiver extend lock period for a given lock
     * @param lockId The lock id for a locked token balance
     * @param daysToAdd The number of days to add to duration
     */
    function extendLock(uint256 lockId, uint16 daysToAdd) external {
        Lock storage lock = tokenLocks[lockId];
        require(msg.sender == lock.receiver, "Vault::extendLock: msg.sender must be receiver");
        uint16 oldDuration = lock.duration;
        uint16 newDuration = _add16(oldDuration, daysToAdd, "Vault::extendLock: max days exceeded");
        lock.duration = newDuration;
        emit LockExtended(oldDuration, newDuration, lock.startTime, lockId);
    }

    /**
     * @notice Adds uint16 to uint16 safely
     * @param a First number
     * @param b Second number
     * @param errorMessage Error message to use if numbers cannot be added
     * @return uint16 number
     */
    function _add16(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        uint16 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
}


pragma solidity ^0.7.0;




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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.7.0;

interface PancakeswapV2BEP20 {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}