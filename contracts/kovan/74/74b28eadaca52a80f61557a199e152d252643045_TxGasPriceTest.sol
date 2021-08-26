// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

library Debug {
    function debug(uint256 value) internal pure {
        revert(string(abi.encodePacked('Debug: ', uint_to_string(value))));
    }

    function debug(uint256 first, uint256 second) internal pure {
        revert(string(abi.encodePacked('Debug: ', uint_to_string(first), ', ', uint_to_string(second))));
    }

    function debug(int256 value) internal pure {
        if (value < 0) {
            revert(string(abi.encodePacked('Debug: -', uint_to_string(uint256(value * -1)))));
        }
        revert(string(abi.encodePacked('Debug: ', uint_to_string(uint256(value)))));
    }

    function debug(int256 first, int256 second) internal pure {
        string memory firstString;
        string memory secondString;

        if (first < 0) {
            firstString = string(abi.encodePacked('-', uint_to_string(uint256(first * -1))));
        } else {
            firstString = uint_to_string(uint256(first));
        }

        if (second < 0) {
            secondString = string(abi.encodePacked('-', uint_to_string(uint256(second * -1))));
        } else {
            secondString = uint_to_string(uint256(second));
        }

        revert(string(abi.encodePacked('Debug: ', firstString, ', ', secondString)));
    }

    function debug(bool value) internal pure {
        revert(value ? 'Debug: true' : 'Debug: false');
    }

    function debug(address value) internal pure {
        revert(string(abi.encodePacked('Debug: ', address_to_string(value))));
    }

    function uint_to_string(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }
        uint256 counter = value;
        uint256 length;
        while (counter != 0) {
            length++;
            counter /= 10;
        }
        bytes memory result = new bytes(length);
        uint256 k = length - 1;
        while (value != 0) {
            result[k--] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(result);
    }

    function address_to_string(address value) public pure returns (string memory) {
        bytes memory data = abi.encodePacked(value);
        bytes memory alphabet = '0123456789abcdef';

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import 'Debug.sol';

contract TxGasPriceTest {
  uint256 public gasPrice;

  function setTxGasPrice () external {
    gasPrice = tx.gasprice;
  }
}

{
  "libraries": {
    "Debug.sol": {},
    "TxGasPriceTest.sol": {}
  },
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