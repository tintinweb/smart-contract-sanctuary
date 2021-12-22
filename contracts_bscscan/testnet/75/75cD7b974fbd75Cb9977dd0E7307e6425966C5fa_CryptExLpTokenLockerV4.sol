/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

This contract for locking and vesting liquidity tokens. Locked liquidity cannot be removed from DEX
until the specified unlock date has been reached. Supports several dexes.

Version 4

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IFeesCalculator.sol";
import "../interfaces/IMigrator.sol";
import "../LockAndVestBase.sol";

contract CryptExLpTokenLockerV4 is LockAndVestBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address;

    mapping(address => bool) public isFactorySupported;
    IMigrator public migrator;

    struct TokenLock {
        address lpToken;
        address owner;
        uint256 tokenAmount;
        uint256 unlockTime;
        uint256 lockedCrx;
    }

    mapping(uint256 => TokenLock) public tokenLocks;

    mapping(address => EnumerableSet.UintSet) private userLocks;

    event OnTokenLock(
        uint256 indexed lockId,
        address indexed tokenAddress,
        address indexed owner,
        uint256 amount,
        uint256 unlockTime
    );
    event OnLockMigration(uint256 indexed lockId, address indexed migrator);

    modifier onlyLockOwner(uint256 lockId) {
        TokenLock storage lock = tokenLocks[lockId];
        require(
            lock.owner == address(msg.sender),
            "NO ACTIVE LOCK OR NOT OWNER"
        );
        _;
    }

    constructor(
        address[] memory supportedFactories,
        address _feesCalculator,
        address payable _feesReceiver,
        address _feeToken
    ) {
        feesCalculator = IFeesCalculator(_feesCalculator);
        feeReceiver = _feesReceiver;
        feeToken = IERC20(_feeToken);

        for (uint256 i = 0; i < supportedFactories.length; ++i) {
            for (uint256 j = i + 1; j < supportedFactories.length; ++j) {
                require(
                    supportedFactories[i] != supportedFactories[j],
                    "WRONG FACTORIES"
                );
            }

            require(
                _checkIfAddressIsFactory(supportedFactories[i]),
                "WRONG FACTORIES"
            );
            isFactorySupported[supportedFactories[i]] = true;
        }
    }

    /**
     * @notice allow/disallow factory for locking and vesting
     * @param factory factory address
     * @param value false - disallow,
     *              true  - allow
     */
    function setIsFactorySupported(address factory, bool value)
        external
        onlyOwner
    {
        require(_checkIfAddressIsFactory(factory), "WRONG FACTORY");
        isFactorySupported[factory] = value;
    }

    function _proceedLock(
        address token,
        address withdrawer,
        uint256 amountToLock,
        uint256 unlockTime,
        uint256 crxToLock,
        bool needToCheck
    ) internal virtual override returns (uint256 lockId) {
        if (needToCheck) {
            require(isLpToken(token), "NOT DEX PAIR");
        }

        TokenLock memory lock = TokenLock({
            lpToken: token,
            owner: withdrawer,
            tokenAmount: amountToLock,
            unlockTime: unlockTime,
            lockedCrx: crxToLock
        });

        lockId = lockNonce++;
        tokenLocks[lockId] = lock;

        userLocks[withdrawer].add(lockId);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amountToLock);
        emit OnTokenLock(lockId, token, withdrawer, amountToLock, unlockTime);
        return lockId;
    }

    function isLpToken(address lpToken) private view returns (bool) {
        if (!lpToken.isContract()) {
            return false;
        }

        IPancakePair pair = IPancakePair(lpToken);
        address factory;
        try pair.factory() returns (address _factory) {
            factory = _factory;
        } catch (bytes memory) {
            return false;
        }

        if (!isFactorySupported[factory]) {
            return false;
        }

        address factoryPair = IPancakeFactory(factory).getPair(
            pair.token0(),
            pair.token1()
        );
        return factoryPair == lpToken;
    }

    /**
     * @notice increase unlock time of already locked tokens
     * @param newUnlockTime new unlock time (unix time in seconds)
     */
    function extendLockTime(uint256 lockId, uint256 newUnlockTime)
        external
        nonReentrant
        onlyLockOwner(lockId)
    {
        require(newUnlockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        require(
            newUnlockTime < 10000000000,
            "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS"
        );
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.unlockTime < newUnlockTime, "NOT INCREASING UNLOCK TIME");
        lock.unlockTime = newUnlockTime;
        emit OnLockDurationIncreased(lockId, newUnlockTime);
    }

    /**
     * @notice add tokens to an existing lock
     * @param amountToIncrement tokens amount to add
     * @param feePaymentMode fee payment mode
     */
    function increaseLockAmount(
        uint256 lockId,
        uint256 amountToIncrement,
        uint8 feePaymentMode
    ) external payable nonReentrant onlyLockOwner(lockId) {
        require(amountToIncrement > 0, "ZERO AMOUNT");
        TokenLock storage lock = tokenLocks[lockId];

        address _lpToken = lock.lpToken;
        (
            uint256 actualIncrementAmount,
            uint256 crxToLock
        ) = _getIncreaseLockAmounts(
                _lpToken,
                amountToIncrement,
                lock.unlockTime,
                feePaymentMode
            );

        lock.tokenAmount = lock.tokenAmount.add(actualIncrementAmount);
        lock.lockedCrx = lock.lockedCrx.add(crxToLock);
        IERC20(_lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            actualIncrementAmount
        );
        emit OnLockAmountIncreased(lockId, amountToIncrement);
    }

    /**
     * @notice withdraw all tokens from lock. Current time must be greater than unlock time
     * @param lockId lock id to withdraw
     */
    function withdraw(uint256 lockId) external {
        TokenLock storage lock = tokenLocks[lockId];
        withdrawPartially(lockId, lock.tokenAmount);
    }

    /**
     * @notice withdraw specified amount of tokens from lock. Current time must be greater than unlock time
     * @param lockId lock id to withdraw tokens from
     * @param amount amount of tokens to withdraw
     */
    function withdrawPartially(uint256 lockId, uint256 amount)
        public
        nonReentrant
        onlyLockOwner(lockId)
    {
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.tokenAmount >= amount, "AMOUNT EXCEEDS LOCKED");
        require(block.timestamp >= lock.unlockTime, "NOT YET UNLOCKED");

        address _owner = lock.owner;

        IERC20(lock.lpToken).safeTransfer(_owner, amount);

        uint256 tokenAmount = lock.tokenAmount.sub(amount);
        lock.tokenAmount = tokenAmount;
        if (tokenAmount == 0) {
            uint256 lockedCrx = lock.lockedCrx;
            if (lockedCrx > 0) {
                feeToken.safeTransfer(_owner, lockedCrx);
            }
            //clean up storage to save gas
            userLocks[_owner].remove(lockId);
            delete tokenLocks[lockId];
            emit OnTokenUnlock(lockId);
        }
        emit OnLockWithdrawal(lockId, amount);
    }

    /**
     * @notice transfer lock ownership to another account. If crxTokens were locked as a paymentFee, the new owner
     * will receive them after the unlock
     * @param lockId lock id to transfer
     * @param newOwner account to transfer lock
     */
    function transferLock(uint256 lockId, address newOwner)
        external
        onlyLockOwner(lockId)
    {
        require(newOwner != address(0), "ZERO NEW OWNER");
        TokenLock storage lock = tokenLocks[lockId];
        userLocks[lock.owner].remove(lockId);
        userLocks[newOwner].add(lockId);
        lock.owner = newOwner;
        emit OnLockOwnershipTransferred(lockId, newOwner);
    }

    /**
     * @notice get user's locks number
     * @param user user's address
     */
    function userLocksLength(address user) external view returns (uint256) {
        return userLocks[user].length();
    }

    /**
     * @notice get user lock id at specified index
     * @param user user's address
     * @param index index of lock id
     */
    function userLockAt(address user, uint256 index)
        external
        view
        returns (uint256)
    {
        return userLocks[user].at(index);
    }

    /**
     * @notice Sets the migrator contract that will perform the migration in case a new update of Pancake was
     * rolled out. Callable only by the owner of this contract.
     * @param newMigrator address of the migrator contract
     */
    function setMigrator(address newMigrator) external onlyOwner {
        migrator = IMigrator(newMigrator);
    }

    /**
     * @notice migrates liquidity in case new update of Pancake was rolled out.
     * @param lockId id of the lock
     * @param migratorContract address of migrator contract that will perform the migration (prevents frontrun attack
     * if a locker owner changes the migrator contract before the migration function was mined)
     */
    function migrate(uint256 lockId, address migratorContract)
        external
        nonReentrant
    {
        require(address(migrator) != address(0), "NO MIGRATOR");
        require(migratorContract == address(migrator), "WRONG MIGRATOR"); //frontrun prevention

        TokenLock storage lock = tokenLocks[lockId];
        require(lock.owner == msg.sender, "ONLY LOCK OWNER");
        IERC20(lock.lpToken).safeApprove(address(migrator), lock.tokenAmount);
        migrator.migrate(
            lock.lpToken,
            lock.tokenAmount,
            lock.unlockTime,
            lock.owner
        );
        emit OnLockMigration(lockId, address(migrator));

        userLocks[lock.owner].remove(lockId);
        delete tokenLocks[lockId];
    }

    /**
     * @notice recover accidentally sent tokens to the contract. Callable only by contract owner
     * @param tokenAddress token address to recover
     */
    function recoverLockedTokens(address tokenAddress) external onlyOwner {
        require(!isLpToken(tokenAddress), "unable to recover LP token");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    function _checkIfAddressIsFactory(address addressCheck)
        private
        view
        returns (bool)
    {
        if (!addressCheck.isContract()) {
            return false;
        }
        try IPancakeFactory(addressCheck).allPairsLength() returns (uint256) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IPancakePair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IFeesCalculator {

    function calculateFees(
        address token,
        uint256 amount,
        uint256 unlockTime,
        uint8 paymentMode,
        address referrer,
        address sender
    ) external view
    returns(uint256 ethFee, uint256 systemTokenFee, uint256 tokenFee, uint256 lockAmount, uint256 referralPercentScaled);

    function calculateIncreaseAmountFees(
        address token,
        uint256 amount,
        uint256 unlockTime,
        uint8 paymentMode,
        address sender
    ) external view
    returns(uint256 ethFee, uint256 systemTokenFee, uint256 tokenFee, uint256 lockAmount);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IMigrator {

    function migrate(address lpToken, uint256 amount, uint256 unlockTime, address owner) external;

}

/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

 Base functionality for locking and vesting contract.

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFeesCalculator.sol";

abstract contract LockAndVestBase is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IFeesCalculator public feesCalculator;
    address payable public feeReceiver;
    IERC20 public feeToken;
    uint256 public minimalLockTime;

    uint256 internal lockNonce;

    event OnFeesCalculatorUpdate(
        address lastFeesCalculator,
        address newFeesCalculator
    );
    event OnFeeReceiverUpdate(address lastFeeReceiver, address newFeeReceiver);
    event OnFeeTokenUpdate(address newAddress);
    event OnMinimalLockTimeChange(
        uint256 oldMinimalLockTime,
        uint256 newMinimalLockTime
    );
    event OnTokenUnlock(uint256 indexed lockId);
    event OnLockWithdrawal(uint256 indexed lockId, uint256 amount);
    event OnLockAmountIncreased(uint256 indexed lockId, uint256 amount);
    event OnLockDurationIncreased(
        uint256 indexed lockId,
        uint256 newUnlockTime
    );
    event OnLockOwnershipTransferred(
        uint256 indexed lockId,
        address indexed newOwner
    );

    /**
     * @notice locks BEP20 token until specified time
     * @param token token address to lock
     * @param amount amount of tokens to lock
     * @param unlockTime unix time in seconds after that tokens can be withdrawn
     * @param withdrawer account that can withdraw tokens to it's balance
     * @param feePaymentMode 0 - pay fees in ETH + % of token,
     *                       1 - pay fees in CRX + % of token,
     *                       2 - pay fees fully in BNB,
     *                       3 - pay fees fully in CRX
     *                       4 - pay fees by locking CRX
     * @param referrer account of referrer
     */
    function lockTokens(
        address token,
        uint256 amount,
        uint256 unlockTime,
        address payable withdrawer,
        uint8 feePaymentMode,
        address referrer
    ) external payable nonReentrant returns (uint256 lockId) {
        require(amount > 0, "ZERO AMOUNT");
        require(token != address(0), "ZERO TOKEN");
        require(withdrawer != address(0), "ZERO WITHDRAWER");
        require(
            unlockTime < 10000000000,
            "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS"
        );
        require(
            unlockTime > block.timestamp + minimalLockTime,
            "TOO SMALL UNLOCK TIME"
        );

        (uint256 amountToLock, uint256 crxToLock) = _getLockAmounts(
            token,
            amount,
            unlockTime,
            feePaymentMode,
            referrer
        );

        lockId = _proceedLock(
            token,
            withdrawer,
            amountToLock,
            unlockTime,
            crxToLock,
            true
        );
    }

    /**
     * @notice token vesting
     * @param token token address to lock
     * @param amount overall amount of tokens to lock
     * @param percents[] array of amount percentage (1e4 = 100%). Sum must be 100%
     * @param unlockTimes[] sorted array of unix times in seconds, must be same length as percents[]
     * @param withdrawer account that can withdraw tokens to it's balance
     * @param feePaymentMode 0 - pay fees in ETH + % of token,
     *                       1 - pay fees in CRX + % of token,
     *                       2 - pay fees fully in BNB,
     *                       3 - pay fees fully in CRX
     *                       4 - pay fees by locking CRX
     * @param referrer account of referrer
     */
    function vestTokens(
        address token,
        uint256 amount,
        uint256[] memory percents,
        uint256[] memory unlockTimes,
        address payable withdrawer,
        uint8 feePaymentMode,
        address referrer
    ) external payable nonReentrant {
        require(percents.length == unlockTimes.length, "ARRAY SIZES MISMATCH");
        require(percents.length >= 2, "LOW LOCKS COUNT");
        require(amount > 0, "ZERO AMOUNT");
        require(withdrawer != address(0), "ZERO WITHDRAWER");
        require(
            unlockTimes[0] > block.timestamp + minimalLockTime,
            "TOO SMALL UNLOCK TIME"
        );
        require(
            unlockTimes[unlockTimes.length - 1] < 10000000000,
            "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS"
        );

        (uint256 amountToLockTotal, uint256 crxToLockTotal) = _getLockAmounts(
            token,
            amount,
            unlockTimes[unlockTimes.length - 1],
            feePaymentMode,
            referrer
        );

        uint256 percentsOverall;
        uint256 amountToLockRest = amountToLockTotal;
        uint256 crxToLockRest = crxToLockTotal;
        for (uint256 i = 0; i < unlockTimes.length; ++i) {
            percentsOverall += percents[i];
            uint256 amountToLockNow;
            uint256 crxToLockNow;
            if (i < unlockTimes.length - 1) {
                require(
                    unlockTimes[i] < unlockTimes[i + 1],
                    "UNSORTED UNLOCK TIMES"
                );

                amountToLockNow = amountToLockTotal.mul(percents[i]).div(1e4);
                crxToLockNow = crxToLockTotal.mul(percents[i]).div(1e4);

                amountToLockRest -= amountToLockNow;
                crxToLockRest -= crxToLockNow;
            } else {
                amountToLockNow = amountToLockRest;
                crxToLockNow = crxToLockRest;
            }
            _proceedLock(
                token,
                withdrawer,
                amountToLockNow,
                unlockTimes[i],
                crxToLockNow,
                i == 0
            );
        }
        require(percentsOverall == 1e4, "INVALID PERCENTS");
    }

    /**
     * @notice sets new contract to calculate fees
     * @param newFeesCalculator address of new fees calculator contract
     */
    function setFeesCalculator(address newFeesCalculator) external onlyOwner {
        require(newFeesCalculator != address(0), "ZERO ADDRESS");
        address oldFeesCalculator = address(feesCalculator);
        feesCalculator = IFeesCalculator(newFeesCalculator);

        emit OnFeesCalculatorUpdate(oldFeesCalculator, newFeesCalculator);
    }

    /**
     * @notice sets new beneficiary
     * @param newFeeReceiver address of new fees receiver
     */
    function setFeeReceiver(address payable newFeeReceiver) external onlyOwner {
        require(newFeeReceiver != address(0), "ZERO ADDRESS");
        address lastFeeReceiver = feeReceiver;
        feeReceiver = newFeeReceiver;

        emit OnFeeReceiverUpdate(lastFeeReceiver, newFeeReceiver);
    }

    /**
     * @notice initialize fee token
     * @param _feeToken address of fee token
     */
    function setFeeTokenAddress(address _feeToken) external onlyOwner {
        require(address(feeToken) == address(0), "already set");
        feeToken = IERC20(_feeToken);

        emit OnFeeTokenUpdate(_feeToken);
    }

    /**
     * @notice sets new minimal lock time
     * @param newMinimalLockTime address of new fees receiver
     */
    function setMinimalLockTime(uint256 newMinimalLockTime) external onlyOwner {
        uint256 oldMinimalLockTime = minimalLockTime;
        minimalLockTime = newMinimalLockTime;
        emit OnMinimalLockTimeChange(oldMinimalLockTime, newMinimalLockTime);
    }

    function website() external pure returns (string memory) {
        return "https://cryptexlock.me";
    }

    function _proceedLock(
        address token,
        address withdrawer,
        uint256 amountToLock,
        uint256 unlockTime,
        uint256 crxToLock,
        bool needToCheck
    ) internal virtual returns (uint256 lockId);

    function _getLockAmounts(
        address token,
        uint256 amount,
        uint256 unlockTime,
        uint8 feePaymentMode,
        address referrer
    ) private returns (uint256 amountToLock, uint256 crxToLock) {
        (
            uint256 ethFee,
            uint256 systemTokenFee,
            uint256 tokenFee,
            uint256 crxLockAmount,
            uint256 refPercentScaled
        ) = feesCalculator.calculateFees(
                token,
                amount,
                unlockTime,
                feePaymentMode,
                referrer,
                msg.sender
            );
        require(tokenFee <= amount.div(100), "TOKEN FEE EXCEEDS 1%");
        //safeguard for token fee
        _transferFees(
            token,
            ethFee,
            systemTokenFee,
            tokenFee,
            crxLockAmount,
            referrer,
            refPercentScaled
        );
        if (msg.value > ethFee) {
            // transfer excess back
            _transferBnb(msg.sender, msg.value.sub(ethFee));
        }

        return (amount.sub(tokenFee), crxLockAmount);
    }

    function _getIncreaseLockAmounts(
        address token,
        uint256 amount,
        uint256 unlockTime,
        uint8 feePaymentMode
    ) internal returns (uint256 actualIncrementAmount, uint256 crxToLock) {
        (
            uint256 ethFee,
            uint256 systemTokenFee,
            uint256 tokenFee,
            uint256 crxLockAmount
        ) = feesCalculator.calculateIncreaseAmountFees(
                token,
                amount,
                unlockTime,
                feePaymentMode,
                msg.sender
            );
        require(tokenFee <= amount.div(100), "TOKEN FEE EXCEEDS 1%");
        //safeguard for token fee
        _transferFees(
            token,
            ethFee,
            systemTokenFee,
            tokenFee,
            crxLockAmount,
            address(0),
            0
        );
        if (msg.value > ethFee) {
            // transfer excess back
            _transferBnb(msg.sender, msg.value.sub(ethFee));
        }

        return (amount.sub(tokenFee), crxLockAmount);
    }

    function _transferFees(
        address token,
        uint256 ethFee,
        uint256 systemTokenFee,
        uint256 tokenFee,
        uint256 crxLockAmount,
        address referrer,
        uint256 referralPercentScaled
    ) internal {
        address _feeReceiver = feeReceiver;
        IERC20 _feeToken = feeToken;
        if (ethFee > 0) {
            require(msg.value >= ethFee, "ETH FEES NOT MET");
            if (referrer != address(0) && referralPercentScaled > 0) {
                uint256 referralFee = ethFee.mul(referralPercentScaled).div(
                    1e4
                );
                _transferBnb(referrer, referralFee);
                _transferBnb(_feeReceiver, ethFee.sub(referralFee));
            } else {
                _transferBnb(_feeReceiver, ethFee);
            }
        }
        if (systemTokenFee > 0) {
            require(
                address(_feeToken) != address(0),
                "TOKEN FEE TYPE NOT SUPPORTED"
            );
            require(
                _feeToken.allowance(msg.sender, address(this)) >=
                    systemTokenFee,
                "TOKEN FEE NOT MET"
            );
            if (referrer != address(0) && referralPercentScaled > 0) {
                uint256 referralFee = systemTokenFee
                    .mul(referralPercentScaled)
                    .div(1e4);
                _feeToken.safeTransferFrom(msg.sender, referrer, referralFee);
                _feeToken.safeTransferFrom(
                    msg.sender,
                    _feeReceiver,
                    systemTokenFee.sub(referralFee)
                );
            } else {
                _feeToken.safeTransferFrom(
                    msg.sender,
                    _feeReceiver,
                    systemTokenFee
                );
            }
        }
        if (tokenFee > 0) {
            require(
                IERC20(token).allowance(msg.sender, address(this)) >= tokenFee,
                "LP TOKEN FEE NOT MET"
            );
            IERC20(token).safeTransferFrom(msg.sender, _feeReceiver, tokenFee);
        }
        if (crxLockAmount > 0) {
            require(
                address(_feeToken) != address(0),
                "TOKEN FEE TYPE NOT SUPPORTED"
            );
            _feeToken.safeTransferFrom(
                msg.sender,
                address(this),
                crxLockAmount
            );
        }
    }

    function _transferBnb(address recipient, uint256 amount) private {
        (bool res, ) = recipient.call{value: amount}("");
        require(res, "BNB TRANSFER FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}