pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

contract A {
    
    uint256 public constant WEEK = 7 * 86400;

    //in weeks
    function aa(uint256 duration, uint256 startTimestamp) external view returns (
        uint256 currentTimestamp,
        uint256 durationAfterTimestamp,
        uint256 roundedDownTimestamp,
        uint256 diff,
        uint256 test_value,
        uint256 nb_weeks_duration,
        uint256 nb_weeks_adjusted_duration
    )
    {
        if(startTimestamp == 0){
            startTimestamp = block.timestamp;
        }
        uint256 a = startTimestamp + (duration * 1 weeks);
        uint256 b = (a / WEEK) * WEEK;
        uint256 c = a - b;
        
        //uint256 d = ((a + c) / WEEK) * WEEK;
        uint256 d = (((b - startTimestamp)) / WEEK < duration) ? ((a + WEEK) / WEEK) * WEEK : b;
        
        uint256 e = ((b - startTimestamp) * 100) / WEEK;
        uint256 f = ((d - startTimestamp) * 100) / WEEK;
        
        return (block.timestamp, a, b, c, d, e, f);
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
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