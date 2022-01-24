// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Counter } from "../storage/Counter.sol";

contract Test2Facet {
    function test2Func1() external view returns (uint256) {
        Counter.CounterStorage storage ds = Counter.counterStorage();
        return ds.counter;
    }
    function test2Func10() external {}

    function test2Func11() external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Counter {
    bytes32 constant COUNTER_STORAGE_POSITION = keccak256("diamond.standard.counter.storage");

    struct CounterStorage {
        uint256 counter;
    }

    function counterStorage() internal pure returns (CounterStorage storage ds) {
        bytes32 position = COUNTER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}