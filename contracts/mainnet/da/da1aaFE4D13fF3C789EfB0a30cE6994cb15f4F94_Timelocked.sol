// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./XVaultSafe.sol";
import "./SafeMath.sol";

contract Timelocked is XVaultSafe {
    using SafeMath for uint256;
    enum Timelock {Short, Medium, Long}

    uint256 private securityLevel;

    function increaseSecurityLevel() public onlyOwner {
        require(securityLevel < 3, "Already max");
        securityLevel = securityLevel + 1;
    }

    function timeInDays(uint256 num) internal pure returns (uint256) {
        return num * 60 * 60 * 24;
    }

    function getDelay(Timelock length) public view returns (uint256) {
        if (securityLevel == 0) {
            return 2; // for testing
        }
        if (length == Timelock.Short) {
            if (securityLevel == 1) {
                return timeInDays(1);
            } else if (securityLevel == 2) {
                return timeInDays(2);
            } else {
                return timeInDays(3);
            }
        } else if (length == Timelock.Medium) {
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

    event Locked(Timelock length);

    event UnlockInitiated(Timelock length, uint256 whenUnlocked);

    function getReleaseTime(Timelock length) public view returns (uint256) {
        return releaseTimes[length];
    }

    function initiateUnlock(Timelock length) public onlyOwner {
        uint256 newReleaseTime = now.add(getDelay(length));
        releaseTimes[length] = newReleaseTime;
        emit UnlockInitiated(length, newReleaseTime);
    }

    function lock(Timelock length) public onlyOwner {
        releaseTimes[length] = 0;
        emit Locked(length);
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
