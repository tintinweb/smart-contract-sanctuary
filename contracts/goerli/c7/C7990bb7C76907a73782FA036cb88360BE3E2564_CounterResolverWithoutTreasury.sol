// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {IResolver} from "../interfaces/IResolver.sol";

interface ICounter {
    function lastExecuted() external view returns (uint256);

    function increaseCount(uint256 amount) external;
}

contract CounterResolverWithoutTreasury is IResolver {
    // solhint-disable var-name-mixedcase
    address public immutable COUNTER;

    constructor(address _counter) {
        COUNTER = _counter;
    }

    function checker()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastExecuted = ICounter(COUNTER).lastExecuted();

        // solhint-disable not-rely-on-time
        canExec = (block.timestamp - lastExecuted) > 180;

        execPayload = abi.encodeWithSelector(
            ICounter.increaseCount.selector,
            uint256(100)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IResolver {
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload);
}