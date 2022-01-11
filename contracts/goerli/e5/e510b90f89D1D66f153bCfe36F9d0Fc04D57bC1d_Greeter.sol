//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Math.sol";

contract Greeter {
    using Math for uint256;

    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library Math {
    function isEven(uint256 n) public pure returns (bool) {
        return n % 2 == 0;
    }
}