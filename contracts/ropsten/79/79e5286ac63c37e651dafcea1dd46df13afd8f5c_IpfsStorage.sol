/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

contract IpfsStorage {

    string[] private files;

    function addFile(string memory ipfsHash) public returns (bool) {
        files.push(ipfsHash);
        return true;
    }


    function getFile(uint256 index) public view returns (string memory) {
        return files[index];
    }

}