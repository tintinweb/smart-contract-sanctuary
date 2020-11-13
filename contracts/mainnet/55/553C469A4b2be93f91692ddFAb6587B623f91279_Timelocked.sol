// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./PunkVaultSafe.sol";
import "./SafeMath.sol";

contract Timelocked is PunkVaultSafe {
    using SafeMath for uint256;
    enum Timelock {Short, Medium, Long}

    uint256 private securityLevel;

    function getSecurityLevel() public view returns (string memory) {
        if (securityLevel == 0) {
            return "red";
        } else if (securityLevel == 1) {
            return "orange";
        } else if (securityLevel == 2) {
            return "yellow";
        } else {
            return "green";
        }
    }

    function increaseSecurityLevel() public onlyOwner {
        require(securityLevel < 3, "Already max");
        securityLevel = securityLevel + 1;
    }

    function timeInDays(uint256 num) internal pure returns (uint256) {
        return num * 60 * 60 * 24;
    }

    function getDelay(Timelock lockId) public view returns (uint256) {
        if (securityLevel == 0) {
            return 2; // for testing
        }
        if (lockId == Timelock.Short) {
            if (securityLevel == 1) {
                return timeInDays(1);
            } else if (securityLevel == 2) {
                return timeInDays(2);
            } else {
                return timeInDays(3);
            }
        } else if (lockId == Timelock.Medium) {
            if (securityLevel == 1) {
                return timeInDays(2);
            } else if (securityLevel == 2) {
                return timeInDays(3);
            } else {
                return timeInDays(5);
            }
        } else {
            if (securityLevel == 1) {
                return timeInDays(3);
            } else if (securityLevel == 2) {
                return timeInDays(5);
            } else {
                return timeInDays(10);
            }
        }
    }

    mapping(Timelock => uint256) private releaseTimes;

    event Locked(Timelock lockId);

    event UnlockInitiated(Timelock lockId, uint256 whenUnlocked);

    function getReleaseTime(Timelock lockId) public view returns (uint256) {
        return releaseTimes[lockId];
    }

    function initiateUnlock(Timelock lockId) public onlyOwner {
        uint256 newReleaseTime = now.add(getDelay(lockId));
        releaseTimes[lockId] = newReleaseTime;
        emit UnlockInitiated(lockId, newReleaseTime);
    }

    function lock(Timelock lockId) public onlyOwner {
        releaseTimes[lockId] = 0;
        emit Locked(lockId);
    }

    modifier whenNotLockedS {
        uint256 releaseTime = releaseTimes[Timelock.Short];
        require(releaseTime > 0, "Locked");
        require(now > releaseTime, "Not unlocked");
        _;
    }
    modifier whenNotLockedM {
        uint256 releaseTime = releaseTimes[Timelock.Medium];
        require(releaseTime > 0, "Locked");
        require(now > releaseTime, "Not unlocked");
        _;
    }
    modifier whenNotLockedL {
        uint256 releaseTime = releaseTimes[Timelock.Long];
        require(releaseTime > 0, "Locked");
        require(now > releaseTime, "Not unlocked");
        _;
    }
}
