pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./Utils.sol";

contract MyContract {
    using Utils for UtilType;
    UtilType state;

    function foo(uint256 extra) public {
        state.addExtra(extra);
    }
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./UtilType.sol";

library Utils {
    function addExtra(UtilType storage state, uint256 extra) public {
        state.var1 += extra;
    }
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

struct UtilType {
    uint256 var1;
    bool var2;
}

