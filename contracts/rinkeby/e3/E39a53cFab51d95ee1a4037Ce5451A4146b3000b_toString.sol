// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract toString {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    string public constant con = "abcd";

    function toStringOne(address a) external pure returns (string memory) {
        return string(abi.encodePacked(con, abi.encodePacked(a)));
    }

    function toStringTwo(address a) external pure returns (string memory) {
        return string(abi.encodePacked(con, a));
    }

    function toStringThree(address a) external pure returns (string memory) {
        return string(abi.encodePacked(con, uint160(a)));
    }

    function toStringFinal(address a) external pure returns (string memory) {
        return string(abi.encodePacked(con, toHexString(uint256(uint160(a)))));
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(42);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 41; i > 1; i--) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}