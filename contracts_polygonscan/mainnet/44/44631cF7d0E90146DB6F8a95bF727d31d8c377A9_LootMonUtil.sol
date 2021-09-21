// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library LootMonUtil {
    function getColors(string memory _element) public pure returns(string memory, string memory) {
        if(compareString(_element, "Fire")) {
            return("#FF7A00", "#FA1E0E");
        } else if (compareString(_element, "Water")) {
            return("#39a9cb", "#005f99");
        } else if (compareString(_element, "Wind")) {
            return("#91c788", "#1e6f5c");
        } else if (compareString(_element, "Earth")) {
            return("#c68b59", "#5c3d2e");
        } else if (compareString(_element, "Dark")) {
            return("#cd113b","#52006a");
        } else {
            return("#ffec85", "#ffcd3c");
        }
    }

    function compareString(string memory _str1, string memory _str2) public pure returns (bool) {
        return keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
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