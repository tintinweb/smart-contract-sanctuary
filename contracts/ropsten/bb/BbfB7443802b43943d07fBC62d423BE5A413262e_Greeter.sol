//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

//

/// @title An example Greeter contract
/// @notice This contract is only for simulation purposes
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {

        greeting = _greeting;
    }

    /// @notice Returns a greeting phrase
    /// @return Greeting string
    function greet() external view returns (string memory) {
        return greeting;
    }

    /// @notice Sets a greeting phrase
    /// @dev Contains a console log output
    /// @param _greeting The greeting phrase
    function setGreeting(string memory _greeting) external {

        greeting = _greeting;
    }
}

