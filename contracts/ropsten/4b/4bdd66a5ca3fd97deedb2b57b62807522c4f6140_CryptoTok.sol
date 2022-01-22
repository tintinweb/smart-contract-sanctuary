/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-20-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract CryptoTok {
    
    address public owner;
    
    // Define a NFT Video object
    struct Video {
        string videoUri;
        address advertiser;
        bool approved;
    }

    // Create a list of some sort to hold all the objects
    Video[] public videos;
    mapping (uint256 => address) public videoAdvertiser;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // Get the NFT Video objects list
    function getVideos() public view returns (Video[] memory) {
        return videos;
    }
    
    // Add to the NFT Video objects list
    function addVideo(Video memory _video) public {
            _video.approved = false;
            videos.push(_video);
            uint256 id = videos.length - 1;
            videoAdvertiser[id] = _video.advertiser;
    }
    
    // Update from the NFT Video objects list
    function updateVideo(
        uint256 _index, Video memory _video) public {
            require(msg.sender == videoAdvertiser[_index], "You are not the owner of this Video.");
            _video.approved = false;
            videos[_index] = _video;
    }
    
    // Approve an NFT Video object to enable displaying
    function approveVideo(uint256 _index) public onlyOwner {
        Video storage  video = videos[_index];
        video.approved = true;
    }
}