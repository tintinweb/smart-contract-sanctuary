pragma solidity ^0.8.0;

contract PascalTriangle {
    function newTriangle(uint256 size) pure public returns (uint256[] memory) {
        uint256[] memory currRow = new uint256[](1);
        currRow[0] = 1;

        for (uint256 r = 2; r <= size; r++) {
            uint256[] memory nextRow = new uint256[](r);
            for (uint256 c = 1; c < r - 1; c++) {
                nextRow[c] = currRow[c - 1] + currRow[c];
            }

            (currRow, nextRow) = (nextRow, currRow);
        }

        return currRow;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
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