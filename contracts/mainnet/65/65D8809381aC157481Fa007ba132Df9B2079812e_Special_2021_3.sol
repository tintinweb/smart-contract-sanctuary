// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./SpecialInterface.sol";

contract Special_2021_3 is SpecialInterface {
  function getURI() override  external pure returns (string memory) {
    return "ipfs://QmVHUPsvFHg7SodWjaJkw1oXoQv4EwadjtrkzFRXWszLDs";
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface SpecialInterface {
  function getURI() external pure returns (string memory);
}