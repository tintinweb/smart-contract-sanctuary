/**
 *Submitted for verification at polygonscan.com on 2021-12-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;



contract Counter  {
    uint256 public count;
    uint256 public lastExecuted;

    // solhint-disable-next-line no-empty-blocks
    

    // solhint-disable not-rely-on-time
    function increaseCount(uint256 amount) external {
        require(
            ((block.timestamp - lastExecuted) > 180),
            "Counter: increaseCount: Time not elapsed"
        );

        count += amount;
        lastExecuted = block.timestamp;
    }
}