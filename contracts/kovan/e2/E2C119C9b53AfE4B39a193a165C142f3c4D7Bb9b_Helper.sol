//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Helper {

  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory temp = bytes(source);
    if (temp.length == 0) {
        return 0x0;
    }

    assembly {
      result := mload(add(source, 32))
    }
  }
}

