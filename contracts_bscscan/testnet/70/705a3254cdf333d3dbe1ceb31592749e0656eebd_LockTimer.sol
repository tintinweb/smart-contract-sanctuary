// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract LockTimer {

    // uint256 public pausedAt;

    // uint256 public canEmergencyWithDrawAfter;

    // event DelayTimeSet(uint256 delayTime);

    modifier isAbleToWithdraw(){
        // uint256 withdrawAfter = canEmergencyWithDrawAfter;

        // // Has not been set yet
        // if (withdrawAfter == 0) {
        //     withdrawAfter = 1800;
        // }
        // require(block.timestamp - pausedAt >= withdrawAfter, "Must wait for certain amount of time");
        // _;
        uint pausedAt;
        uint withdrawAfter;
        assembly {
            

        }

        _;
    }
    
    function _getPausedAt() public pure returns(uint256 pausedAt){
        
        bytes32 hashed = keccak256("pausedAt");

        assembly{
            pausedAt:=mload(hashed)
        }
    }

    function _setPausedAt(uint256 timestamp) public{
        bytes32 data = bytes32(timestamp);
        bytes32 hashed = keccak256("pausedAt");
        assembly{
            mstore(hashed, data)
        }
    }

    function _setEmergencyWithdrawDelayTime(uint delayInSecs) internal {
        // require(delayInSecs >= 600, "Please set it more than 10 mins");
        // require(delayInSecs <= 3600 * 24 * 7 , "Please set it less than 1 week");
        // emit DelayTimeSet(delayInSecs);
        // canEmergencyWithDrawAfter = delayInSecs;
    }

}

