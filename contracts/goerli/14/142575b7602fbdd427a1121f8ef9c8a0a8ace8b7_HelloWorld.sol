/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
// pragma solidity 0.4.24;
pragma solidity ^0.6.5;
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@aragon/os/contracts/apps/AragonApp.sol";

contract HelloWorld {
    string private greeting;
    // uint256 public immutable greetingNumber;
    uint256 public greetingNumber;

    constructor(uint256 _greetingNumber) public {
        greeting = "Hello World 3";
        greetingNumber = _greetingNumber;
    }

    /// @notice Just view the greeting string
    function getGreeting() public view returns(string memory) {
        return greeting;
    }
}