/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface IHashupNicknames {
    function getNickname(address user) external view returns (string memory);
    function getAddress(string memory nickname) external view returns (address);
}

contract HashupGamerProfile {
    mapping(address => address[]) followers;
    mapping(address => address[]) followedProfiles;
    mapping(address => string) profileImage;
    mapping(address => string) description;
    
    address HashupNicknames = 0x81732cceC32d7f99c1babd4bDC56bc8fe59670e3;
    
    function follow(string memory user) public {
        address userAddress = IHashupNicknames(HashupNicknames).getAddress(user);
        require(userAddress != address(0), 'Followed user must have nickname!');
        
        followedProfiles[msg.sender].push(userAddress);
        followers[userAddress].push(msg.sender);
    }
    
    function removeFollowerByIndex(uint256 index) public {
        followers[msg.sender][index] = followers[msg.sender][followers[msg.sender].length - 1];
        followers[msg.sender].pop();
    }
    
    function removeFollowedByIndex(uint256 index) public {
        followedProfiles[msg.sender][index] = followedProfiles[msg.sender][followedProfiles[msg.sender].length - 1];
        followedProfiles[msg.sender].pop();
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
    
    struct JsonInterface {
        address[] followers;
        address[] followedProfiles;
        string    profileImage;
        string    description;
        address   HashupNicknames;
    }

    /**
     * Dumps all public contract data for a user at the given address.
     */
    function toJson(address user) public view returns (JsonInterface memory) {
        return JsonInterface(
            followers[user],
            followedProfiles[user],
            profileImage[user],
            description[user],
            HashupNicknames
        );
    }
}