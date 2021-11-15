// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./api/tools.sol";
contract Main is A{
    function get()external  view returns(uint256){
        return a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract A {
    uint256 public a = 25;
}

