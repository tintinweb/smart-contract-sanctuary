//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;



/// @title A contract for boilerplating
/// @author Hardhat (and DeFi Wonderland)
/// @notice You can use this contract for only the most basic tests
/// @dev This is just a try out
/// @custom:experimental This is an experimental contract.

contract Greeter {
  event GreetingSet(string _greeting);

  error EmptyGreeting();

  string public greeting;

  constructor(string memory _greeting) {

    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function sum1(uint number) public view returns (uint) {
    return number + 1;
  }

  /// @notice Sets greeting that will be used during greet
  /// @dev Some explanation only defined for devs
  /// @param _greeting The greeting to be used
  /// @return _changedGreet Was greeting changed or nah
  function setGreeting(string memory _greeting) public returns (bool _changedGreet) {
    if (bytes(_greeting).length == 0) revert EmptyGreeting();

    greeting = _greeting;
    _changedGreet = true;
    emit GreetingSet(_greeting);
  }
}