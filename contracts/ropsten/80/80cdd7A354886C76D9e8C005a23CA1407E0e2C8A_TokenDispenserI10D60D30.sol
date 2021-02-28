pragma solidity ^0.5.16;

import "./TokenDispenserBase.sol";

contract TokenDispenserI10D60D30 is TokenDispenserBase {
    uint public day1EndTime;
    uint public day2EndTime;
    uint public constant immediateVestRatio = 1e17;
    uint public constant d1VestRatio = 6e17;
    uint public constant d2VestRatio = 3e17;
    uint public constant d1rate = d1VestRatio / 1 days;
    uint public constant d2rate = d2VestRatio / 1 days;

    constructor (address kine_, uint startTime_) public {
        kine = IERC20(kine_);
        startTime = startTime_;
        transferPaused = false;
        day1EndTime = startTime_.add(1 days);
        day2EndTime = startTime_.add(2 days);
    }

    function vestedPerAllocation() public view returns (uint) {
        uint currentTime = block.timestamp;
        if (currentTime <= startTime) {
            return 0;
        }
        if (currentTime <= day1EndTime) {
            return immediateVestRatio.add(currentTime.sub(startTime).mul(d1rate));
        }
        if (currentTime <= day2EndTime) {
            return immediateVestRatio.add(d1VestRatio).add(currentTime.sub(day1EndTime).mul(d2rate));
        }
        return 1e18;
    }
}