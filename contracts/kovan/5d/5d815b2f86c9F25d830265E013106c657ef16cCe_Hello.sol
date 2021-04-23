/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// Sources flattened with hardhat v2.2.0 https://hardhat.org

// File contracts/ISayHello.sol

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.0;

interface ISayHello {
    function sayHello(string memory str) external;
    function getLastSay() external view returns(string memory);
}


// File contracts/Greeter.sol

pragma solidity ^0.7.0;

contract Greeter{
  string greeting;

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
  }


  function delegateSayHello(ISayHello someContract, string memory _greeting) external{
    // require(someContract.isContract(), "not contract");
    someContract.sayHello(_greeting);
  }
}


// File contracts/Hello.sol

pragma solidity ^0.7.0;

contract Hello {
  string greeting;

  event SayHello(string str);

  constructor(string memory _greeting) {
    greeting = _greeting;

  }

  function sayHello (string memory str) external {
    greeting = str;
    emit SayHello(str);
  }
  function getLastSay() external view returns(string memory) {
    return greeting;
  }
}