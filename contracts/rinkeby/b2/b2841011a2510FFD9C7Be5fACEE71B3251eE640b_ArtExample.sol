// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IAsciiArt.sol";

//  _________        .---"""      """---.
// :______.-':      :  .--------------.  :
// | ______  |      | :                : |
// |:______B:|      | |  Hello World   | |
// |:______B:|      | |                | |
// |:______B:|      | |  contracts     | |
// |         |      | |  as            | |
// |:_____:  |      | |  art           | |
// |    ==   |      | :                : |
// |       O |      :  '--------------'  :
// |       o |      :'---...______...---'
// |       o |-._.-i___/'             \._
// |'-.____o_|   '-.   '-...______...-'  `-._
// :_________:      `.____________________   `-.___.-.
//                  .'.eeeeeeeeeeeeeeeeee.'.      :___:
//     fsc        .'.eeeeeeeeeeeeeeeeeeeeee.'.
//               :____________________________:
contract ArtExample {
    address public asciiArtAddress;

    constructor(address _asciiArtAddress, address mintTo) public {
        asciiArtAddress = _asciiArtAddress;
        IAsciiArt ascii = IAsciiArt(_asciiArtAddress);
        ascii.mint(mintTo);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IAsciiArt {
    function mint(address mintTo) external;
}

{
  "optimizer": {
    "enabled": false,
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
  },
  "libraries": {}
}