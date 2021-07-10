// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Test {
    function test() public pure returns (bool) {
        return String.contains("abcdefg", "cd");
    }
}

library String {
    /**
     * Convert a string to lowercase
     */
    function lowercase(string memory input) internal pure returns (string memory) {
        bytes memory _input = bytes(input);
        for (uint inputIdx = 0; inputIdx < _input.length; inputIdx++) {
            uint8 character = uint8(_input[inputIdx]);
            if (character >= 65 && character <= 90) {
                character += 0x20;
                _input[inputIdx] = bytes1(character);
            }
        }
        return string(_input);
    }

    /**
     * Convert a string to uppercase
     */
    function uppercase(string memory input) internal pure returns (string memory) {
        bytes memory _input = bytes(input);
        for (uint inputIdx = 0; inputIdx < _input.length; inputIdx++) {
            uint8 character = uint8(_input[inputIdx]);
            if (character >= 97 && character <= 122) {
                character -= 0x20;
                _input[inputIdx] = bytes1(character);
            }
        }
        return string(_input);
    }

    /**
     * Search for a needle in a haystack
     */
    function contains(string memory haystack, string memory needle) internal pure returns (bool) {
        return indexOf(needle, haystack) >= 0;
    }
    
    /**
     * Convert bytes32 to string and remove padding
     */
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /**
     * Case insensitive string search
     *
     * @param needle The string to search for
     * @param haystack The string to search in
     * @return Returns -1 if no match is found, otherwise returns the index of the match 
     */
    function indexOf(string memory needle, string memory haystack) internal pure returns (int256) {
        bytes memory _needle = bytes(lowercase(needle));
        bytes memory _haystack = bytes(lowercase(haystack));
        if (_haystack.length < _needle.length) {
            return -1;
        }
        bool _match;
        for (uint256 haystackIdx; haystackIdx < _haystack.length; haystackIdx++) {
            for (uint256 needleIdx; needleIdx < _needle.length; needleIdx++) {
                uint8 needleChar = uint8(_needle[needleIdx]);
                uint8 haystackChar = uint8(_haystack[haystackIdx + needleIdx]);
                if (needleChar == haystackChar) {
                    _match = true;
                    if (needleIdx == _needle.length - 1) {
                        return int(haystackIdx);
                    }
                } else {
                    _match = false;
                    break;
                }
            }
        }
        return -1;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
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