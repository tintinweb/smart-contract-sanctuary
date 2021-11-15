// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {IResolver} from "./interfaces/IResolver.sol";

interface ICounter {
    function lastExecuted() external view returns (uint256);

    function increaseCount(uint256 amount) external;
}

contract Counter is IResolver {
    uint256 public count;
    uint256 public lastExecuted;

    function increaseCount(uint256 amount) external {
        require(
            ((block.timestamp - lastExecuted) > 180),
            "Counter: increaseCount: Time not elapsed"
        );

        count += amount;
        lastExecuted = block.timestamp;
    }

    function checker(uint256 amount)
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (block.timestamp - lastExecuted) > 180;

        execPayload = abi.encodeWithSelector(
            ICounter.increaseCount.selector,
            uint256(amount)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IResolver {
    function checker(uint256 amount)
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

