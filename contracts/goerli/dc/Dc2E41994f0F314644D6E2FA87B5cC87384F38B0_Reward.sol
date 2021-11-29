// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Target.sol";

contract Reward {
    function f(Target target, uint reward) external {
        require(target.blockNumber() != 0, "ASDASD");
        block.coinbase.transfer(reward);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Target {
    uint public blockNumber;

    function f() external {
        if (block.timestamp % 10 == 0) {
            blockNumber = block.number;
        }
    }
}