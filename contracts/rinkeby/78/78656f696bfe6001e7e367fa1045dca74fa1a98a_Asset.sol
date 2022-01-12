/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Asset {
    address private owner;
    string[] private imageHashes;
    string private nameOfAsset;
    string private idOfAsset;

    constructor(string memory _name, string memory _idOfAsset) {
        owner = msg.sender;
        nameOfAsset = _name;
        idOfAsset = _idOfAsset;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function addImageHash(string memory _imgHash) public {
        imageHashes.push(_imgHash);
        require(msg.sender == owner);
    }

    function getHashes() external view returns (string[] memory) {
        require(msg.sender == owner);
        return imageHashes;
    }

    function getName() external view returns (string memory) {
        return nameOfAsset;
    }

    function getID() external view returns (string memory) {
        return idOfAsset;
    }
}