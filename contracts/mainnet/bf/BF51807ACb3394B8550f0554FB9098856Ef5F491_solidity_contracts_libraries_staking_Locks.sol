pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { AuthorityVerifier } from "../../Authorizations.sol";
import "./LockUtils.sol";

library Locks {
    using SafeMath for uint256;
    using LockUtils for LockUtils.LockSet;

    event StakeLocked(address indexed operator, address lockCreator, uint256 until);
    event LockReleased(address indexed operator, address lockCreator);
    event ExpiredLockReleased(address indexed operator, address lockCreator);

    uint256 public constant maximumLockDuration = 86400 * 200; // 200 days in seconds

    struct Storage {
        // Locks placed on the operator.
        // `operatorLocks[operator]` returns all locks placed on the operator.
        // Each authorized operator contract can place one lock on an operator.
        mapping(address => LockUtils.LockSet) operatorLocks;
    }

    function lockStake(
        Storage storage self,
        address operator,
        uint256 duration
    ) public {
        require(duration <= maximumLockDuration, "Lock duration too long");
        self.operatorLocks[operator].setLock(
            msg.sender,
            uint96(block.timestamp.add(duration))
        );
        emit StakeLocked(operator, msg.sender, block.timestamp.add(duration));
    }

    function releaseLock(
        Storage storage self,
        address operator
    ) public {
        self.operatorLocks[operator].releaseLock(msg.sender);
        emit LockReleased(operator, msg.sender);
    }

    function releaseExpiredLock(
        Storage storage self,
        address operator,
        address operatorContract,
        address authorityVerifier
    ) public {
        LockUtils.LockSet storage locks = self.operatorLocks[operator];

        require(
            locks.contains(operatorContract),
            "No matching lock present"
        );

        bool expired = block.timestamp >= locks.getLockTime(operatorContract);
        bool disabled = !AuthorityVerifier(authorityVerifier)
            .isApprovedOperatorContract(operatorContract);

        require(
            expired || disabled,
            "Lock still active and valid"
        );

        locks.releaseLock(operatorContract);

        emit ExpiredLockReleased(operator, operatorContract);
    }

    /// @dev AuthorityVerifier is a trusted implementation and not a third-party,
    /// external contract. AuthorityVerifier never reverts on the check and
    /// has a reasonable gas consumption.
    function isStakeLocked(
        Storage storage self,
        address operator,
        address authorityVerifier
    ) public view returns (bool) {
        LockUtils.Lock[] storage _locks = self.operatorLocks[operator].locks;
        LockUtils.Lock memory lock;
        for (uint i = 0; i < _locks.length; i++) {
            lock = _locks[i];
            if (block.timestamp < lock.expiresAt) {
                if (
                    AuthorityVerifier(authorityVerifier)
                        .isApprovedOperatorContract(lock.creator)
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    function isStakeReleased(
        Storage storage self,
        address operator,
        address operatorContract
    ) public view returns (bool) {
        LockUtils.LockSet storage locks = self.operatorLocks[operator];
        // `getLockTime` returns 0 if the lock doesn't exist,
        // thus we don't need to check for its presence separately.
        return block.timestamp >= locks.getLockTime(operatorContract);
    }

    function getLocks(
        Storage storage self,
        address operator
    ) public view returns (address[] memory creators, uint256[] memory expirations) {
        uint256 lockCount = self.operatorLocks[operator].locks.length;
        creators = new address[](lockCount);
        expirations = new uint256[](lockCount);
        LockUtils.Lock memory lock;
        for (uint i = 0; i < lockCount; i++) {
            lock = self.operatorLocks[operator].locks[i];
            creators[i] = lock.creator;
            expirations[i] = lock.expiresAt;
        }
    }
} 
