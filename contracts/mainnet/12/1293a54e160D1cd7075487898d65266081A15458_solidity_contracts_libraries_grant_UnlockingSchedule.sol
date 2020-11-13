pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library UnlockingSchedule {
    using SafeMath for uint256;

    function getUnlockedAmount(
        uint256 _now,
        uint256 grantedAmount,
        uint256 duration,
        uint256 start,
        uint256 cliff
    ) internal pure returns (uint256) {
        bool cliffNotReached = _now < cliff;
        if (cliffNotReached) { return 0; }

        uint256 timeElapsed = _now.sub(start);

        bool unlockingPeriodFinished = timeElapsed >= duration;
        if (unlockingPeriodFinished) { return grantedAmount; }

        return grantedAmount.mul(timeElapsed).div(duration);
    }
}
