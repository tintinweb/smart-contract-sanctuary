//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuadraticAds {

    uint256 public adCount;
    uint256 public likeFee = 300000 gwei;

    mapping(uint256 => Ad) public ads;
    mapping(uint256 => mapping(address => uint256)) idToUserLikes;

    struct Ad {
        uint256 id;
        string uri;
        address creator;
        uint256 likes;
    }

    event AdCreated (
        uint256 indexed id,
        string uri,
        address indexed creator
    );

    event AdLiked (
        uint256 indexed id,
        address liker
    );


    function createAd(string memory _uri) public payable {
        require(bytes(_uri).length > 0);
        ads[adCount] = Ad(adCount, _uri, msg.sender, 0);

        emit AdCreated(adCount, _uri, msg.sender);

        adCount++;
    }

    function likeAd(uint256 id) public payable {
        uint256 likes = idToUserLikes[id][msg.sender];
        uint256 fee = likeFee * (likes + 1);
        require(msg.value == fee, "User must send correct amount of Ether");
        address creator = ads[id].creator;
        ads[id].likes++;

        idToUserLikes[id][msg.sender] += 1;
        payable(creator).transfer(fee);

        emit AdLiked(id, msg.sender);

    }

    function getAd(uint256 _id) public view returns (Ad memory) {
        return ads[_id];
    }
    
    function getUserLikes(uint256 _id) public view returns (uint256) {
        return idToUserLikes[_id][msg.sender];
    }

}