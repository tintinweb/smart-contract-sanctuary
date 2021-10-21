/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

/*
MIT License

Copyright (c) 2021 Joshua Iván Mendieta Zurita

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;

/// @dev This library let you store ipfs hash into stored bytes32. It also let you recombine the stored bytes32 into ipfs hash.
contract IpfsHashHandler {

    /// @dev function that decompose an ipfs hash string into bytes32
    function ipfsHashToBytes32(string memory source) external pure returns (bytes32 partA, bytes32 partB) {
        assembly {
            partA := mload(add(source, 32))
            partB := mload(add(source, 64))
        }
    }
    
    /// @dev function that recompose bytes32 into an ipfs hash string
    function bytes32ToIpfsHash(bytes32 partA, bytes32 partB) external pure returns (string memory) {
        bytes memory bytesArrayPartA = new bytes(32);
        bytes memory bytesArrayPartB = new bytes(32);
        for (uint8 i = 0; i < 32; i++) {
            bytesArrayPartA[i] = partA[i];
            bytesArrayPartB[i] = partB[i];
        }
        string memory _partA = string(bytesArrayPartA);
        string memory _partB = string(bytesArrayPartB);
        return string(abi.encodePacked(_partA, _partB));
    }
}