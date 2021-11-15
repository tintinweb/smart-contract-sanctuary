//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./interfaces/IGreeter.sol";

contract Greeter is IGreeter {
    string greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view override returns (string memory _greeting) {
        _greeting = greeting;
    }

    function setGreeting(string memory _greeting) public override {
        greeting = _greeting;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IGreeter {
    function greet() external view returns (string memory _greeting);

    function setGreeting(string memory _greeting) external;
}

