/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

pragma solidity >=0.8.11 <0.9.0;
// SPDX-License-Identifier: UNLICENSED

interface IBase62Library {
    function toBase(uint val) external pure returns (string memory);
    function toDec(string memory val) external pure returns (uint);
    function fromBase(string memory val) external pure returns (uint);
}

contract Base62 {
    address internal constant Base62LibraryAddr = 0x9f22E8494Abac1Ed098D6dB688d6DdF3ce175749;
    function toBase(uint val) public pure returns (string memory) { return IBase62Library(Base62LibraryAddr).toBase(val); }
    function toDec(string memory val) public pure returns (uint) { return IBase62Library(Base62LibraryAddr).toDec(val); }
    function fromBase(string memory val) public pure returns (uint)  { return IBase62Library(Base62LibraryAddr).fromBase(val); }
}