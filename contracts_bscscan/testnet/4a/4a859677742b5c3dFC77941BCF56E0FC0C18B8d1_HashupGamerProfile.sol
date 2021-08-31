/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

pragma solidity ^0.8.4;

contract HashupGamerProfile {
    mapping(address => address[]) followers;
    mapping(address => address[]) followedProfiles;
    mapping(address => string) profileImage;
    mapping(address => string) description;
    
    function follow(address user) public {
        followedProfiles[msg.sender].push(user);
        followers[user].push(msg.sender);
    }
    
    function getFollowers(address user) public view returns (address[] memory) {
        return followers[user];
    }
    
    function getFollowed(address user) public view returns (address[] memory) {
        return followedProfiles[user];
    }
    
    function setProfileImage(string memory imageURL) public {
        profileImage[msg.sender] = imageURL;
    }
    
    function getProfileImage(address user) public view returns (string memory) {
        return profileImage[user];
    }
    
    function setDescription(string memory newDescription) public {
        description[msg.sender] = newDescription;
    }
    
    function getDescription(address user) public view returns (string memory) {
        return description[user];
    }
    
}