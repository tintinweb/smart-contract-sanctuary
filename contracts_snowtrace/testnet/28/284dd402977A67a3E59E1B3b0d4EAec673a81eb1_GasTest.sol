// SPDX-License-Identifier: MIT


// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract GasTest { 
    struct TestArray { 
        uint256 count;
    }

    // Info of each Fee Reward Token.
    TestArray[] public testArray;

    function testFee(
        uint256 _count
    ) public {
        // respect startBlock!
        for (uint256 i=0; i < _count; i++ ) { 
            testArray.push(
                TestArray({
                    count: i * _count / _count
                })
            );
        }
    }
}