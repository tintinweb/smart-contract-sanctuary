//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Namer {
    // Used to append suffixes on taken names.
    mapping (string => uint) namesRegistry;

    // bytes32 could be used instead of string
    // We could optimize further by storing fixed-length hashes.
    mapping (address => string) names;

    function setName(string memory _name) public {
      bool isTaken = namesRegistry[_name] != 0;
      names[msg.sender] = !isTaken ? _name : string(abi.encodePacked(_name, uintToString(namesRegistry[_name])));
      namesRegistry[_name] += 1;
    }

    function readName(address owner) public view returns (string memory) {
        return names[owner];
    }

    function uintToString(uint v) public pure returns (string memory) {
        bytes memory reversed = new bytes(100);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v /=  10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i); // i + 1 is inefficient
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
        }
        string memory str = string(s);  // memory isn't implicitly convertible to storage
        return str;
    }
}