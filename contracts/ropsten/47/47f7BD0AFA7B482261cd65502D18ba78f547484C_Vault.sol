// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20Permit.sol";
import "./interfaces/ILockManager.sol";
import "./lib/SafeERC20.sol";

/**
 * @title Vault
 * @dev Contract for locking up tokens for set periods of time 
 * + optionally providing locked tokens with voting power
 */
contract Vault {
    using SafeERC20 for IERC20Permit;

    /// @notice lockManager contract
    ILockManager public immutable lockManager;

    /// @notice Lock definition
    struct Lock {
        address token;
        address receiver;
        uint48 startTime;
        uint16 vestingDurationInDays;
        uint16 cliffDurationInDays;
        uint256 amount;
        uint256 amountClaimed;
        uint256 votingPower;
    }

    /// @notice Lock balance definition
    struct LockBalance {
        uint256 id;
        uint256 claimableAmount;
        Lock lock;
    }

    ///@notice Token balance definition
    struct TokenBalance {
        uint256 totalAmount;
        uint256 claimableAmount;
        uint256 claimedAmount;
        uint256 votingPower;
    }

    /// @dev Used to translate lock periods specified in days to seconds
    uint256 constant internal SECONDS_PER_DAY = 86400;
    
    /// @notice Mapping of lock id > token locks
    mapping (uint256 => Lock) public tokenLocks;

    /// @notice Mapping of address to lock id
    mapping (address => uint256[]) public lockIds;

    ///@notice Number of locks
    uint256 public numLocks;

    /// @notice Event emitted when a new lock is created
    event LockCreated(address indexed token, address indexed locker, address indexed receiver, uint256 lockId, uint256 amount, uint48 startTime, uint16 durationInDays, uint16 cliffInDays, uint256 votingPower);
    
    /// @notice Event emitted when tokens are claimed by a receiver from an unlocked balance
    event UnlockedTokensClaimed(address indexed receiver, address indexed token, uint256 indexed lockId, uint256 amountClaimed, uint256 votingPowerRemoved);

    /// @notice Event emitted when lock duration extended
    event LockExtended(uint256 indexed lockId, uint16 indexed oldDuration, uint16 indexed newDuration, uint16 oldCliff, uint16 newCliff, uint48 startTime);

    /**
     * @notice Create a new Vault contract
     */
    constructor(address _lockManager) {
        lockManager = ILockManager(_lockManager);
    }

    /**
     * @notice Lock tokens, optionally providing voting power
     * @param locker The account that is locking tokens
     * @param receiver The account that will be able to retrieve unlocked tokens
     * @param startTime The unix timestamp when the lock period will start
     * @param amount The amount of tokens being locked
     * @param vestingDurationInDays The vesting period in days
     * @param cliffDurationInDays The cliff duration in days
     * @param grantVotingPower if true, give user voting power from tokens
     */
    function lockTokens(
        address token,
        address locker,
        address receiver,
        uint48 startTime,
        uint256 amount,
        uint16 vestingDurationInDays,
        uint16 cliffDurationInDays,
        bool grantVotingPower
    )
        external
    {
        require(vestingDurationInDays > 0, "Vault::lockTokens: vesting duration must be > 0");
        require(vestingDurationInDays <= 25*365, "Vault::lockTokens: vesting duration more than 25 years");
        require(vestingDurationInDays >= cliffDurationInDays, "Vault::lockTokens: vesting duration < cliff");
        require(amount > 0, "Vault::lockTokens: amount not > 0");
        _lockTokens(token, locker, receiver, startTime, amount, vestingDurationInDays, cliffDurationInDays, grantVotingPower);
    }

    /**
     * @notice Lock tokens, using permit for approval
     * @dev It is up to the frontend developer to ensure the token implements permit - otherwise this will fail
     * @param token Address of token to lock
     * @param locker The account that is locking tokens
     * @param receiver The account that will be able to retrieve unlocked tokens
     * @param startTime The unix timestamp when the lock period will start
     * @param amount The amount of tokens being locked
     * @param vestingDurationInDays The lock period in days
     * @param cliffDurationInDays The lock cliff duration in days
     * @param grantVotingPower if true, give user voting power from tokens
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function lockTokensWithPermit(
        address token,
        address locker,
        address receiver,
        uint48 startTime,
        uint256 amount,
        uint16 vestingDurationInDays,
        uint16 cliffDurationInDays,
        bool grantVotingPower,
        uint256 deadline,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        external
    {
        require(vestingDurationInDays > 0, "Vault::lockTokensWithPermit: vesting duration must be > 0");
        require(vestingDurationInDays <= 25*365, "Vault::lockTokensWithPermit: vesting duration more than 25 years");
        require(vestingDurationInDays >= cliffDurationInDays, "Vault::lockTokensWithPermit: duration < cliff");
        require(amount > 0, "Vault::lockTokensWithPermit: amount not > 0");

        // Set approval using permit signature
        IERC20Permit(token).permit(locker, address(this), amount, deadline, v, r, s);
        _lockTokens(token, locker, receiver, startTime, amount, vestingDurationInDays, cliffDurationInDays, grantVotingPower);
    }

    /**
     * @notice Get all active token lock ids
     * @return the lock ids
     */
    function allActiveLockIds() external view returns(uint256[] memory){
        uint256 activeCount;

        // Get number of active locks
        for (uint256 i; i < numLocks; i++) {
            Lock memory lock = tokenLocks[i];
            if(lock.amount != lock.amountClaimed) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        uint256[] memory result = new uint256[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < numLocks; i++) {
            Lock memory lock = tokenLocks[i];
            if(lock.amount != lock.amountClaimed) {
                result[j] = i;
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all active token locks
     * @return the locks
     */
    function allActiveLocks() external view returns(Lock[] memory){
        uint256 activeCount;

        // Get number of active locks
        for (uint256 i; i < numLocks; i++) {
            Lock memory lock = tokenLocks[i];
            if(lock.amount != lock.amountClaimed) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        Lock[] memory result = new Lock[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < numLocks; i++) {
            Lock memory lock = tokenLocks[i];
            if(lock.amount != lock.amountClaimed) {
                result[j] = lock;
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all active token lock balances
     * @return the active lock balances
     */
    function allActiveLockBalances() external view returns(LockBalance[] memory){
        uint256 activeCount;

        // Get number of active locks
        for (uint256 i; i < numLocks; i++) {
            Lock memory lock = tokenLocks[i];
            if(lock.amount != lock.amountClaimed) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        LockBalance[] memory result = new LockBalance[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < numLocks; i++) {
            Lock memory lock = tokenLocks[i];
            if(lock.amount != lock.amountClaimed) {
                result[j] = lockBalance(i);
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all active token lock ids for receiver
     * @param receiver The address that has locked balances
     * @return the active lock ids
     */
    function activeLockIds(address receiver) external view returns(uint256[] memory){
        uint256 activeCount;
        uint256[] memory receiverLockIds = lockIds[receiver];

        // Get number of active locks
        for (uint256 i; i < receiverLockIds.length; i++) {
            Lock memory lock = tokenLocks[receiverLockIds[i]];
            if(lock.amount != lock.amountClaimed) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        uint256[] memory result = new uint256[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < receiverLockIds.length; i++) {
            Lock memory lock = tokenLocks[receiverLockIds[i]];
            if(lock.amount != lock.amountClaimed) {
                result[j] = receiverLockIds[i];
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all token locks for receiver
     * @param receiver The address that has locked balances
     * @return the locks
     */
    function allLocks(address receiver) external view returns(Lock[] memory){
        uint256[] memory allLockIds = lockIds[receiver];
        Lock[] memory result = new Lock[](allLockIds.length);
        for (uint256 i; i < allLockIds.length; i++) {
            result[i] = tokenLocks[allLockIds[i]];
        }
        return result;
    }

    /**
     * @notice Get all active token locks for receiver
     * @param receiver The address that has locked balances
     * @return the locks
     */
    function activeLocks(address receiver) external view returns(Lock[] memory){
        uint256 activeCount;
        uint256[] memory receiverLockIds = lockIds[receiver];

        // Get number of active locks
        for (uint256 i; i < receiverLockIds.length; i++) {
            Lock memory lock = tokenLocks[receiverLockIds[i]];
            if(lock.amount != lock.amountClaimed) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        Lock[] memory result = new Lock[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < receiverLockIds.length; i++) {
            Lock memory lock = tokenLocks[receiverLockIds[i]];
            if(lock.amount != lock.amountClaimed) {
                result[j] = tokenLocks[receiverLockIds[i]];
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all active token lock balances for receiver
     * @param receiver The address that has locked balances
     * @return the active lock balances
     */
    function activeLockBalances(address receiver) external view returns(LockBalance[] memory){
        uint256 activeCount;
        uint256[] memory receiverLockIds = lockIds[receiver];

        // Get number of active locks
        for (uint256 i; i < receiverLockIds.length; i++) {
            Lock memory lock = tokenLocks[receiverLockIds[i]];
            if(lock.amount != lock.amountClaimed) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        LockBalance[] memory result = new LockBalance[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < receiverLockIds.length; i++) {
            Lock memory lock = tokenLocks[receiverLockIds[i]];
            if(lock.amount != lock.amountClaimed) {
                result[j] = lockBalance(receiverLockIds[i]);
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get total token balance
     * @param token The token to check
     * @return balance the total active balance of `token`
     */
    function totalTokenBalance(address token) external view returns(TokenBalance memory balance){
        for (uint256 i; i < numLocks; i++) {
            Lock memory tokenLock = tokenLocks[i];
            if(tokenLock.token == token && tokenLock.amount != tokenLock.amountClaimed){
                balance.totalAmount = balance.totalAmount + tokenLock.amount;
                balance.votingPower = balance.votingPower + tokenLock.votingPower;
                if(block.timestamp > tokenLock.startTime) {
                    balance.claimedAmount = balance.claimedAmount + tokenLock.amountClaimed;

                    uint256 elapsedTime = block.timestamp - tokenLock.startTime;
                    uint256 elapsedDays = elapsedTime / SECONDS_PER_DAY;

                    if (
                        elapsedDays >= tokenLock.cliffDurationInDays
                    ) {
                        if (elapsedDays >= tokenLock.vestingDurationInDays) {
                            balance.claimableAmount = balance.claimableAmount + tokenLock.amount - tokenLock.amountClaimed;
                        } else {
                            uint256 vestingDurationInSecs = uint256(tokenLock.vestingDurationInDays) * SECONDS_PER_DAY;
                            uint256 vestingAmountPerSec = tokenLock.amount / vestingDurationInSecs;
                            uint256 amountVested = vestingAmountPerSec * elapsedTime;
                            balance.claimableAmount = balance.claimableAmount + amountVested - tokenLock.amountClaimed;
                        }
                    }
                }
            }
        }
    }

    /**
     * @notice Get token balance of receiver
     * @param token The token to check
     * @param receiver The address that has unlocked balances
     * @return balance the total active balance of `token` for `receiver`
     */
    function tokenBalance(address token, address receiver) external view returns(TokenBalance memory balance){
        uint256[] memory receiverLockIds = lockIds[receiver];
        for (uint256 i; i < receiverLockIds.length; i++) {
            Lock memory receiverLock = tokenLocks[receiverLockIds[i]];
            if(receiverLock.token == token && receiverLock.amount != receiverLock.amountClaimed){
                balance.totalAmount = balance.totalAmount + receiverLock.amount;
                balance.votingPower = balance.votingPower + receiverLock.votingPower;
                if(block.timestamp > receiverLock.startTime) {
                    balance.claimedAmount = balance.claimedAmount + receiverLock.amountClaimed;

                    uint256 elapsedTime = block.timestamp - receiverLock.startTime;
                    uint256 elapsedDays = elapsedTime / SECONDS_PER_DAY;

                    if (
                        elapsedDays >= receiverLock.cliffDurationInDays
                    ) {
                        if (elapsedDays >= receiverLock.vestingDurationInDays) {
                            balance.claimableAmount = balance.claimableAmount + receiverLock.amount - receiverLock.amountClaimed;
                        } else {
                            uint256 vestingDurationInSecs = uint256(receiverLock.vestingDurationInDays) * SECONDS_PER_DAY;
                            uint256 vestingAmountPerSec = receiverLock.amount / vestingDurationInSecs;
                            uint256 amountVested = vestingAmountPerSec * elapsedTime;
                            balance.claimableAmount = balance.claimableAmount + amountVested - receiverLock.amountClaimed;
                        }
                    }
                }
            }
        }
    }

    /**
     * @notice Get lock balance for a given lock id
     * @param lockId The lock ID
     * @return balance the lock balance
     */
    function lockBalance(uint256 lockId) public view returns (LockBalance memory balance) {
        balance.id = lockId;
        balance.claimableAmount = claimableBalance(lockId);
        balance.lock = tokenLocks[lockId];
    }

    /**
     * @notice Get claimable balance for a given lock id
     * @dev Returns 0 if cliff duration has not ended
     * @param lockId The lock ID
     * @return The amount that can be claimed
     */
    function claimableBalance(uint256 lockId) public view returns (uint256) {
        Lock storage lock = tokenLocks[lockId];

        // For locks created with a future start date, that hasn't been reached, return 0
        if (block.timestamp < lock.startTime) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - lock.startTime;
        uint256 elapsedDays = elapsedTime / SECONDS_PER_DAY;
        
        if (elapsedDays < lock.cliffDurationInDays) {
            return 0;
        } 
        
        if (elapsedDays >= lock.vestingDurationInDays) {
            return lock.amount - lock.amountClaimed;
        } else {
            uint256 vestingDurationInSecs = uint256(lock.vestingDurationInDays) * SECONDS_PER_DAY;
            uint256 vestingAmountPerSec = lock.amount / vestingDurationInSecs;
            uint256 amountVested = vestingAmountPerSec * elapsedTime;
            return amountVested - lock.amountClaimed;
        }
    }

    /**
     * @notice Allows receiver to claim all of their unlocked tokens for a set of locks
     * @dev Errors if no tokens are claimable
     * @dev It is advised receivers check they are entitled to claim via `claimableBalance` before calling this
     * @param locks The lock ids for unlocked token balances
     */
    function claimAllUnlockedTokens(uint256[] memory locks) external {
        for (uint i = 0; i < locks.length; i++) {
            uint256 claimableAmount = claimableBalance(locks[i]);
            require(claimableAmount > 0, "Vault::claimAllUnlockedTokens: claimableAmount is 0");
            _claimTokens(locks[i], claimableAmount);
        }
    }

    /**
     * @notice Allows receiver to claim a portion of their unlocked tokens for a given lock
     * @dev Errors if token amounts provided are > claimable amounts
     * @dev It is advised receivers check they are entitled to claim via `claimableBalance` before calling this
     * @param locks The lock ids for unlocked token balances
     * @param amounts The amount of each unlocked token to claim
     */
    function claimUnlockedTokenAmounts(uint256[] memory locks, uint256[] memory amounts) external {
        require(locks.length == amounts.length, "Vault::claimUnlockedTokenAmounts: arrays must be same length");
        for (uint i = 0; i < locks.length; i++) {
            uint256 claimableAmount = claimableBalance(locks[i]);
            require(claimableAmount >= amounts[i], "Vault::claimUnlockedTokenAmounts: claimableAmount < amount");
            _claimTokens(locks[i], amounts[i]);
        }
    }

    /**
     * @notice Allows receiver extend lock periods for a given lock
     * @param lockId The lock id for a locked token balance
     * @param vestingDaysToAdd The number of days to add to vesting duration
     * @param cliffDaysToAdd The number of days to add to cliff duration
     */
    function extendLock(uint256 lockId, uint16 vestingDaysToAdd, uint16 cliffDaysToAdd) external {
        Lock storage lock = tokenLocks[lockId];
        require(msg.sender == lock.receiver, "Vault::extendLock: msg.sender must be receiver");
        uint16 oldVestingDuration = lock.vestingDurationInDays;
        uint16 newVestingDuration = _add16(oldVestingDuration, vestingDaysToAdd, "Vault::extendLock: vesting max days exceeded");
        uint16 oldCliffDuration = lock.cliffDurationInDays;
        uint16 newCliffDuration = _add16(oldCliffDuration, cliffDaysToAdd, "Vault::extendLock: cliff max days exceeded");
        require(newCliffDuration <= 10*365, "Vault::extendLock: cliff more than 10 years");
        require(newVestingDuration <= 25*365, "Vault::extendLock: vesting duration more than 25 years");
        require(newVestingDuration >= newCliffDuration, "Vault::extendLock: duration < cliff");
        lock.vestingDurationInDays = newVestingDuration;
        emit LockExtended(lockId, oldVestingDuration, newVestingDuration, oldCliffDuration, newCliffDuration, lock.startTime);
    }

    /**
     * @notice Internal implementation of lockTokens
     * @param locker The account that is locking tokens
     * @param receiver The account that will be able to retrieve unlocked tokens
     * @param startTime The unix timestamp when the lock period will start
     * @param amount The amount of tokens being locked
     * @param vestingDurationInDays The vesting period in days
     * @param cliffDurationInDays The cliff duration in days
     * @param grantVotingPower if true, give user voting power from tokens
     */
    function _lockTokens(
        address token,
        address locker,
        address receiver,
        uint48 startTime,
        uint256 amount,
        uint16 vestingDurationInDays,
        uint16 cliffDurationInDays,
        bool grantVotingPower
    ) internal {

        // Transfer the tokens under the control of the vault contract
        IERC20Permit(token).safeTransferFrom(locker, address(this), amount);

        uint48 lockStartTime = startTime == 0 ? uint48(block.timestamp) : startTime;
        uint256 votingPowerGranted;
        
        // Grant voting power, if specified
        if(grantVotingPower) {
            votingPowerGranted = lockManager.grantVotingPower(receiver, token, amount);
        }

        // Create lock
        Lock memory lock = Lock({
            token: token,
            receiver: receiver,
            startTime: lockStartTime,
            vestingDurationInDays: vestingDurationInDays,
            cliffDurationInDays: cliffDurationInDays,
            amount: amount,
            amountClaimed: 0,
            votingPower: votingPowerGranted
        });

        tokenLocks[numLocks] = lock;
        lockIds[receiver].push(numLocks);
        emit LockCreated(token, locker, receiver, numLocks, amount, lockStartTime, vestingDurationInDays, cliffDurationInDays, votingPowerGranted);
        
        // Increment lock id
        numLocks++;
    }

    /**
     * @notice Internal implementation of token claims
     * @param lockId The lock id for claim
     * @param claimAmount The amount to claim
     */
    function _claimTokens(uint256 lockId, uint256 claimAmount) internal {
        Lock storage lock = tokenLocks[lockId];
        uint256 votingPowerRemoved;

        // Remove voting power, if exists
        if (lock.votingPower > 0) {
            votingPowerRemoved = lockManager.removeVotingPower(lock.receiver, lock.token, claimAmount);
            lock.votingPower = lock.votingPower - votingPowerRemoved;
        }

        // Update claimed amount
        lock.amountClaimed = lock.amountClaimed + claimAmount;

        // Release tokens
        IERC20Permit(lock.token).safeTransfer(lock.receiver, claimAmount);
        emit UnlockedTokensClaimed(lock.receiver, lock.token, lockId, claimAmount, votingPowerRemoved);
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

import "./IERC20.sol";

interface IERC20Permit is IERC20 {
    function getDomainSeparator() external view returns (bytes32);
    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function VERSION_HASH() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address) external view returns (uint);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockManager {
    struct LockedStake {
        uint256 amount;
        uint256 votingPower;
    }

    function getAmountStaked(address staker, address stakedToken) external view returns (uint256);
    function getStake(address staker, address stakedToken) external view returns (LockedStake memory);
    function calculateVotingPower(address token, uint256 amount) external view returns (uint256);
    function grantVotingPower(address receiver, address token, uint256 tokenAmount) external returns (uint256 votingPowerGranted);
    function removeVotingPower(address receiver, address token, uint256 tokenAmount) external returns (uint256 votingPowerRemoved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}