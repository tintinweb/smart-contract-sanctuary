// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Counter } from "../storage/Counter.sol";

contract Test1Facet {
    event TestEvent(address something);

    function test1Func1() external payable {
        Counter.CounterStorage storage ds = Counter.counterStorage();
        ds.counter += 1;
    }

    function test1Func2() external {}

    function test1Func10() external pure returns (string memory) {
        return 'ciao';
    }
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