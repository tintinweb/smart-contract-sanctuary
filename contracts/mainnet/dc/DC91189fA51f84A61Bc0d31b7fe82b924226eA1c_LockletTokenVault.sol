// contracts/LockletTokenVault.sol
// SPDX-License-Identifier: No License

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./LockletToken.sol";

contract LockletTokenVault is AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint16;

    using SignedSafeMath for int256;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    address public lockletTokenAddress;

    struct RecipientCallData {
        address recipientAddress;
        uint256 amount;
    }

    struct Recipient {
        address recipientAddress;
        uint256 amount;
        uint16 daysClaimed;
        uint256 amountClaimed;
        bool isActive;
    }

    struct Lock {
        uint256 creationTime;
        address tokenAddress;
        uint256 startTime;
        uint16 durationInDays;
        address initiatorAddress;
        bool isRevocable;
        bool isRevoked;
        bool isActive;
    }

    struct LockWithRecipients {
        uint256 index;
        Lock lock;
        Recipient[] recipients;
    }

    uint256 private _nextLockIndex;
    Lock[] private _locks;
    mapping(uint256 => Recipient[]) private _locksRecipients;

    mapping(address => uint256[]) private _initiatorsLocksIndexes;
    mapping(address => uint256[]) private _recipientsLocksIndexes;

    mapping(address => mapping(address => uint256)) private _refunds;

    address private _stakersRedisAddress;
    address private _foundationRedisAddress;
    bool private _isDeprecated;

    // #region Governance Variables

    uint256 private _creationFlatFeeLktAmount;
    uint256 private _revocationFlatFeeLktAmount;

    uint256 private _creationPercentFee;

    // #endregion

    // #region Events

    event LockAdded(uint256 indexed lockIndex);
    event LockedTokensClaimed(uint256 indexed lockIndex, address indexed recipientAddress, uint256 claimedAmount);
    event LockRevoked(uint256 indexed lockIndex, uint256 unlockedAmount, uint256 remainingLockedAmount);
    event LockRefundPulled(address indexed recipientAddress, address indexed tokenAddress, uint256 refundedAmount);

    // #endregion

    constructor(address lockletTokenAddr) {
        lockletTokenAddress = lockletTokenAddr;

        _nextLockIndex = 0;

        _stakersRedisAddress = address(0);
        _foundationRedisAddress = 0x25Bd291bE258E90e7A0648aC5c690555aA9e8930;
        _isDeprecated = false;

        _creationFlatFeeLktAmount = 0;
        _revocationFlatFeeLktAmount = 0;
        _creationPercentFee = 0;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GOVERNOR_ROLE, msg.sender);
    }

    function addLock(
        address tokenAddress,
        uint256 totalAmount,
        uint16 cliffInDays,
        uint16 durationInDays,
        RecipientCallData[] calldata recipientsData,
        bool isRevocable,
        bool payFeesWithLkt
    ) external nonReentrant whenNotPaused contractNotDeprecated {
        require(Address.isContract(tokenAddress), "LockletTokenVault: Token address is not a contract");
        ERC20 token = ERC20(tokenAddress);

        require(totalAmount > 0, "LockletTokenVault: The total amount is equal to zero");

        if (payFeesWithLkt) {
            LockletToken lktToken = lockletToken();

            if (_creationFlatFeeLktAmount > 0) {
                require(lktToken.balanceOf(msg.sender) >= _creationFlatFeeLktAmount, "LockletTokenVault: Not enough LKT to pay fees");
                require(lktToken.transferFrom(msg.sender, address(this), _creationFlatFeeLktAmount));

                uint256 burnAmount = _creationFlatFeeLktAmount.mul(45).div(100);
                uint256 stakersRedisAmount = _creationFlatFeeLktAmount.mul(45).div(100);
                uint256 foundationRedisAmount = _creationFlatFeeLktAmount.mul(10).div(100);

                require(lktToken.burn(burnAmount));
                require(lktToken.transfer(_stakersRedisAddress, stakersRedisAmount));
                require(lktToken.transfer(_foundationRedisAddress, foundationRedisAmount));
            }

            require(token.balanceOf(msg.sender) >= totalAmount, "LockletTokenVault: Token insufficient balance");
            require(token.transferFrom(msg.sender, address(this), totalAmount));
        } else {
            uint256 creationPercentFeeAmount = 0;
            if (_creationPercentFee > 0) {
                creationPercentFeeAmount = totalAmount.mul(_creationPercentFee).div(10000);
            }

            uint256 totalAmountWithFees = totalAmount.add(creationPercentFeeAmount);

            require(token.balanceOf(msg.sender) >= totalAmountWithFees, "LockletTokenVault: Token insufficient balance");
            require(token.transferFrom(msg.sender, address(this), totalAmountWithFees));

            if (creationPercentFeeAmount > 0) {
                uint256 stakersRedisAmount = creationPercentFeeAmount.mul(90).div(100);
                uint256 foundationRedisAmount = creationPercentFeeAmount.mul(10).div(100);

                require(token.transfer(_stakersRedisAddress, stakersRedisAmount));
                require(token.transfer(_foundationRedisAddress, foundationRedisAmount));
            }
        }

        uint256 lockIndex = _nextLockIndex;
        _nextLockIndex = _nextLockIndex.add(1);

        Lock memory lock = Lock({
            creationTime: blockTime(),
            tokenAddress: tokenAddress,
            startTime: blockTime().add(cliffInDays * 1 days),
            durationInDays: durationInDays,
            initiatorAddress: msg.sender,
            isRevocable: durationInDays > 1 ? isRevocable : false,
            isRevoked: false,
            isActive: true
        });

        _locks.push(lock);
        _initiatorsLocksIndexes[msg.sender].push(lockIndex);

        uint256 totalAmountCheck = 0;

        for (uint256 i = 0; i < recipientsData.length; i++) {
            RecipientCallData calldata recipientData = recipientsData[i];

            uint256 unlockedAmountPerDay = recipientData.amount.div(durationInDays);
            require(unlockedAmountPerDay > 0, "LockletTokenVault: The unlocked amount per day is equal to zero");

            totalAmountCheck = totalAmountCheck.add(recipientData.amount);

            Recipient memory recipient = Recipient({
                recipientAddress: recipientData.recipientAddress,
                amount: recipientData.amount,
                daysClaimed: 0,
                amountClaimed: 0,
                isActive: true
            });

            _recipientsLocksIndexes[recipientData.recipientAddress].push(lockIndex);
            _locksRecipients[lockIndex].push(recipient);
        }

        require(totalAmountCheck == totalAmount, "LockletTokenVault: The calculated total amount is not equal to the actual total amount");

        emit LockAdded(lockIndex);
    }

    function claimLockedTokens(uint256 lockIndex) external nonReentrant whenNotPaused {
        Lock storage lock = _locks[lockIndex];
        require(lock.isActive == true, "LockletTokenVault: Lock not existing");
        require(lock.isRevoked == false, "LockletTokenVault: This lock has been revoked");

        Recipient[] storage recipients = _locksRecipients[lockIndex];

        int256 recipientIndex = getRecipientIndexByAddress(recipients, msg.sender);
        require(recipientIndex != -1, "LockletTokenVault: Forbidden");

        Recipient storage recipient = recipients[uint256(recipientIndex)];

        uint16 daysVested;
        uint256 unlockedAmount;
        (daysVested, unlockedAmount) = calculateClaim(lock, recipient);
        require(unlockedAmount > 0, "LockletTokenVault: The amount of unlocked tokens is equal to zero");

        recipient.daysClaimed = uint16(recipient.daysClaimed.add(daysVested));
        recipient.amountClaimed = uint256(recipient.amountClaimed.add(unlockedAmount));

        ERC20 token = ERC20(lock.tokenAddress);

        require(token.transfer(recipient.recipientAddress, unlockedAmount), "LockletTokenVault: Unlocked tokens transfer failed");
        emit LockedTokensClaimed(lockIndex, recipient.recipientAddress, unlockedAmount);
    }

    function revokeLock(uint256 lockIndex) external nonReentrant whenNotPaused {
        Lock storage lock = _locks[lockIndex];
        require(lock.isActive == true, "LockletTokenVault: Lock not existing");
        require(lock.initiatorAddress == msg.sender, "LockletTokenVault: Forbidden");
        require(lock.isRevocable == true, "LockletTokenVault: Lock not revocable");
        require(lock.isRevoked == false, "LockletTokenVault: This lock has already been revoked");

        lock.isRevoked = true;

        if (_revocationFlatFeeLktAmount > 0) {
            LockletToken lktToken = lockletToken();
            require(lktToken.balanceOf(msg.sender) >= _revocationFlatFeeLktAmount, "LockletTokenVault: Not enough LKT to pay fees");
            require(lktToken.transferFrom(msg.sender, address(this), _revocationFlatFeeLktAmount));

            uint256 burnAmount = _revocationFlatFeeLktAmount.mul(45).div(100);
            uint256 stakersRedisAmount = _revocationFlatFeeLktAmount.mul(45).div(100);
            uint256 foundationRedisAmount = _revocationFlatFeeLktAmount.mul(10).div(100);

            require(lktToken.burn(burnAmount));
            require(lktToken.transfer(_stakersRedisAddress, stakersRedisAmount));
            require(lktToken.transfer(_foundationRedisAddress, foundationRedisAmount));
        }

        Recipient[] storage recipients = _locksRecipients[lockIndex];

        address tokenAddr = lock.tokenAddress;
        address initiatorAddr = lock.initiatorAddress;

        uint256 totalAmount = 0;
        uint256 totalUnlockedAmount = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            Recipient storage recipient = recipients[i];

            totalAmount = totalAmount.add(recipient.amount);

            uint16 daysVested;
            uint256 unlockedAmount;
            (daysVested, unlockedAmount) = calculateClaim(lock, recipient);

            if (unlockedAmount > 0) {
                address recipientAddr = recipient.recipientAddress;
                _refunds[recipientAddr][tokenAddr] = _refunds[recipientAddr][tokenAddr].add(unlockedAmount);
            }

            totalUnlockedAmount = totalUnlockedAmount.add(recipient.amountClaimed.add(unlockedAmount));
        }

        uint256 totalLockedAmount = totalAmount.sub(totalUnlockedAmount);
        _refunds[initiatorAddr][tokenAddr] = _refunds[initiatorAddr][tokenAddr].add(totalLockedAmount);

        emit LockRevoked(lockIndex, totalUnlockedAmount, totalLockedAmount);
    }

    function pullRefund(address tokenAddress) external nonReentrant whenNotPaused {
        uint256 refundAmount = getRefundAmount(tokenAddress);
        require(refundAmount > 0, "LockletTokenVault: No refund found for this token");

        _refunds[msg.sender][tokenAddress] = 0;

        ERC20 token = ERC20(tokenAddress);
        require(token.transfer(msg.sender, refundAmount), "LockletTokenVault: Refund tokens transfer failed");

        emit LockRefundPulled(msg.sender, tokenAddress, refundAmount);
    }

    // #region Views

    function getLock(uint256 lockIndex) public view returns (LockWithRecipients memory) {
        Lock storage lock = _locks[lockIndex];
        require(lock.isActive == true, "LockletTokenVault: Lock not existing");

        return LockWithRecipients({index: lockIndex, lock: lock, recipients: _locksRecipients[lockIndex]});
    }

    function getLocksLength() public view returns (uint256) {
        return _locks.length;
    }

    function getLocks(int256 page, int256 pageSize) public view returns (LockWithRecipients[] memory) {
        require(getLocksLength() > 0, "LockletTokenVault: There is no lock");

        int256 queryStartLockIndex = int256(getLocksLength()).sub(pageSize.mul(page)).add(pageSize).sub(1);
        require(queryStartLockIndex >= 0, "LockletTokenVault: Out of bounds");

        int256 queryEndLockIndex = queryStartLockIndex.sub(pageSize).add(1);
        if (queryEndLockIndex < 0) {
            queryEndLockIndex = 0;
        }

        int256 currentLockIndex = queryStartLockIndex;
        require(uint256(currentLockIndex) <= getLocksLength().sub(1), "LockletTokenVault: Out of bounds");

        LockWithRecipients[] memory results = new LockWithRecipients[](uint256(pageSize));
        uint256 index = 0;

        for (currentLockIndex; currentLockIndex >= queryEndLockIndex; currentLockIndex--) {
            uint256 currentLockIndexAsUnsigned = uint256(currentLockIndex);
            if (currentLockIndexAsUnsigned <= getLocksLength().sub(1)) {
                results[index] = getLock(currentLockIndexAsUnsigned);
            }

            index++;
        }

        return results;
    }

    function getLocksByInitiator(address initiatorAddress) public view returns (LockWithRecipients[] memory) {
        uint256 initiatorLocksLength = _initiatorsLocksIndexes[initiatorAddress].length;
        require(initiatorLocksLength > 0, "LockletTokenVault: The initiator has no lock");

        LockWithRecipients[] memory results = new LockWithRecipients[](initiatorLocksLength);

        for (uint256 index = 0; index < initiatorLocksLength; index++) {
            uint256 lockIndex = _initiatorsLocksIndexes[initiatorAddress][index];
            results[index] = getLock(lockIndex);
        }

        return results;
    }

    function getLocksByRecipient(address recipientAddress) public view returns (LockWithRecipients[] memory) {
        uint256 recipientLocksLength = _recipientsLocksIndexes[recipientAddress].length;
        require(recipientLocksLength > 0, "LockletTokenVault: The recipient has no lock");

        LockWithRecipients[] memory results = new LockWithRecipients[](recipientLocksLength);

        for (uint256 index = 0; index < recipientLocksLength; index++) {
            uint256 lockIndex = _recipientsLocksIndexes[recipientAddress][index];
            results[index] = getLock(lockIndex);
        }

        return results;
    }

    function getRefundAmount(address tokenAddress) public view returns (uint256) {
        return _refunds[msg.sender][tokenAddress];
    }

    function getClaimByLockAndRecipient(uint256 lockIndex, address recipientAddress) public view returns (uint16, uint256) {
        Lock storage lock = _locks[lockIndex];
        require(lock.isActive == true, "LockletTokenVault: Lock not existing");

        Recipient[] storage recipients = _locksRecipients[lockIndex];

        int256 recipientIndex = getRecipientIndexByAddress(recipients, recipientAddress);
        require(recipientIndex != -1, "LockletTokenVault: Forbidden");

        Recipient storage recipient = recipients[uint256(recipientIndex)];

        uint16 daysVested;
        uint256 unlockedAmount;
        (daysVested, unlockedAmount) = calculateClaim(lock, recipient);

        return (daysVested, unlockedAmount);
    }

    function getCreationFlatFeeLktAmount() public view returns (uint256) {
        return _creationFlatFeeLktAmount;
    }

    function getRevocationFlatFeeLktAmount() public view returns (uint256) {
        return _revocationFlatFeeLktAmount;
    }

    function getCreationPercentFee() public view returns (uint256) {
        return _creationPercentFee;
    }

    function isDeprecated() public view returns (bool) {
        return _isDeprecated;
    }

    function getRecipientIndexByAddress(Recipient[] storage recipients, address recipientAddress) private view returns (int256) {
        int256 recipientIndex = -1;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i].recipientAddress == recipientAddress) {
                recipientIndex = int256(i);
                break;
            }
        }
        return recipientIndex;
    }

    function calculateClaim(Lock storage lock, Recipient storage recipient) private view returns (uint16, uint256) {
        require(recipient.amountClaimed < recipient.amount, "LockletTokenVault: The recipient has already claimed the maximum amount");

        if (blockTime() < lock.startTime) {
            return (0, 0);
        }

        // check if cliff has reached
        uint256 elapsedDays = blockTime().sub(lock.startTime).div(1 days);

        if (elapsedDays >= lock.durationInDays) {
            // if over duration, all tokens vested
            uint256 remainingAmount = recipient.amount.sub(recipient.amountClaimed);
            return (lock.durationInDays, remainingAmount);
        } else {
            uint16 daysVested = uint16(elapsedDays.sub(recipient.daysClaimed));
            uint256 unlockedAmountPerDay = recipient.amount.div(uint256(lock.durationInDays));
            uint256 unlockedAmount = uint256(daysVested.mul(unlockedAmountPerDay));
            return (daysVested, unlockedAmount);
        }
    }

    function blockTime() private view returns (uint256) {
        return block.timestamp;
    }

    function lockletToken() private view returns (LockletToken) {
        return LockletToken(lockletTokenAddress);
    }

    // #endregion

    // #region Governance

    function setCreationFlatFeeLktAmount(uint256 amount) external onlyGovernor {
        require(amount >= 0, "LockletTokenVault: Invalid value");
        _creationFlatFeeLktAmount = amount;
    }

    function setRevocationFlatFeeLktAmount(uint256 amount) external onlyGovernor {
        require(amount >= 0, "LockletTokenVault: Invalid value");
        _revocationFlatFeeLktAmount = amount;
    }

    function setCreationPercentFee(uint256 amount) external onlyGovernor {
        require(amount >= 0 && amount <= 10000, "LockletTokenVault: Invalid value");
        _creationPercentFee = amount;
    }

    function setStakersRedisAddress(address addr) external onlyGovernor {
        require(addr != address(0), "LockletTokenVault: Invalid value");
        _stakersRedisAddress = addr;
    }

    function pause() external onlyGovernor {
        _pause();
    }

    function unpause() external onlyGovernor {
        _unpause();
    }

    function setDeprecated(bool deprecated) external onlyGovernor {
        _isDeprecated = deprecated;
    }

    // #endregion

    // #region Modifiers

    modifier onlyGovernor() {
        require(hasRole(GOVERNOR_ROLE, msg.sender), "LockletTokenVault: Caller is not a GOVERNOR");
        _;
    }

    modifier contractNotDeprecated() {
        require(!_isDeprecated, "LockletTokenVault: This version of the contract is deprecated");
        _;
    }

    // #endregion
}

// contracts/LockletToken.sol
// SPDX-License-Identifier: No License

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LockletToken is ERC20 {
    uint256 private _initialSupply;
    uint256 private _totalSupply;

    constructor() ERC20("Locklet", "LKT") {
        _initialSupply = 150000000 * 10**18;
        _totalSupply = _initialSupply;
        _mint(msg.sender, _initialSupply);
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor () {
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 5000
  },
  "evmVersion": "istanbul",
  "libraries": {},
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