// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IAsciiArt.sol";

//                         __/\__ 
//                         \    /   
//                   __/\__/    \__/\__
//                   \                /
//                   /_              _\
//                     \            /
//       __/\__      __/            \__      __/\__
//       \    /      \                /      \    /
// __/\__/    \__/\__/                \__/\__/    \__/\__
// \                                                    /
// /_                                                  _\
//   \                                                /
// __/                                                \__ 
// \                                                    /
// /_  __                                          __  _\
//   \/  \                                        /  \/
//       /_                                      _\
//         \                                    /
//       __/                                    \__
//       \                                        /
// __/\__/                                        \__/\__
// \                                                    /
// /_                                                  _\
//   \                                                /
// __/                                                \__
// \                                                    /
// /_  __      __  __                  __  __      __  _\
//   \/  \    /  \/  \                /  \/  \    /  \/
//       /_  _\      /_              _\      /_  _\
//         \/          \            /          \/
//                   __/            \__
//                   \                /
//                   /_  __      __  _\
//                     \/  \    /  \/
//                         /_  _\
//                           \/
// !
contract ArtExample {
    address public asciiArtAddress;

    constructor(address _asciiArtAddress, address mintTo) public {
        asciiArtAddress = _asciiArtAddress;
        IAsciiArt ascii = IAsciiArt(_asciiArtAddress);
        ascii.mint(mintTo);
    }
}