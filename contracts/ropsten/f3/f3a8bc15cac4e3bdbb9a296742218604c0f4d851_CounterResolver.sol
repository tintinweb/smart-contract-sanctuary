/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ICounter {
    function lastExecuted() external view returns (uint256);
    function increaseCount(uint256 amount) external;
}

contract CounterResolver {
    address public immutable COUNTER;

    constructor(address _counter) {
        COUNTER = _counter;
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastExecuted = ICounter(COUNTER).lastExecuted();

        canExec = (block.timestamp - lastExecuted) > 180;

        execPayload = abi.encodeWithSelector(
            ICounter.increaseCount.selector,
            uint256(100)
        );
    }
}