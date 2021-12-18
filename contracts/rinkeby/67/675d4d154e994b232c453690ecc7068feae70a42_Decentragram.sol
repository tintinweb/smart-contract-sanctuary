/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Decentragram {
    struct Image {
        uint256 id;
        string description;
        string hash;
        address payable author;
        uint256 timestamp;
        uint256 tipAmount;
    }
    mapping(uint256 => Image) public images;
    uint256 public counter;

    event imagePosted(uint256 id,
        string description,
        string hash,
        address author,
        uint256 timestamp,
        uint256 tipAmount);
    event imageUpdated(uint256 id,
        string description,
        string hash,
        address author,
        uint256 timestamp,
        uint256 tipAmount);
    event imageTipped(uint256 id, address author, uint256 tip);

    constructor() {
        counter = 0;
    }

    function postImage(string memory description, string memory hash) public {
        require(bytes(description).length > 0, "No image description sent.");
        require(bytes(hash).length > 0, "No IPFS hash sent.");

        Image memory newImage = Image(counter, description, hash, payable(msg.sender), block.timestamp, 0);
        images[counter] = newImage;

        emit imagePosted(counter, description, hash, msg.sender, block.timestamp, 0);
        counter++;
    }

    function updateImage(uint256 id, string memory description, string memory hash) public {
        require(images[id].author == msg.sender, "Only author can make changes to image.");

        Image memory updatedImage = Image(id, description, hash, payable(msg.sender), block.timestamp, images[id].tipAmount);
        images[id] = updatedImage;

        emit imageUpdated(images[id].id, images[id].description, images[id].hash, msg.sender, block.timestamp, images[id].tipAmount);
    }

    function tipAuthor(uint256 id) public payable {
        require(id < counter, "Image doesn't exist.");
        require(msg.value > 0, "Tipping nothing.");

        (bool success, ) = address(images[id].author).call{value: msg.value}("");
        require(success, "An error has occured.");

        emit imageTipped(id, images[id].author, msg.value);
    }

}