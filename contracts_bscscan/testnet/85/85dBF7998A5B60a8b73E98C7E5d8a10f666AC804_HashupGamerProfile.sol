/**
 *Submitted for verification at BscScan.com on 2021-11-24
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
    mapping(address => string) socialMedia;
    
    address HashupNicknames = 0x81732cceC32d7f99c1babd4bDC56bc8fe59670e3;

    event descriptionSet(address index, string description);
    event imageSet(address index, string image);

    event followed(address follower, address followedAddress);
    event unfollowed(address follower, address unfollowedAddress);
    
    function follow(string memory user) public {
        address userAddress = IHashupNicknames(HashupNicknames).getAddress(user);
        require(userAddress != address(0), 'Followed user must have nickname!');
        
        followedProfiles[msg.sender].push(userAddress);
        followers[userAddress].push(msg.sender);

        emit followed(msg.sender, userAddress);
    }
    
    function removeFollowerByIndex(uint256 index) public {
        emit unfollowed(followers[msg.sender][index], msg.sender);

        followers[msg.sender][index] = followers[msg.sender][followers[msg.sender].length - 1];
        followers[msg.sender].pop();
    }
    
    function removeFollowedByIndex(uint256 index) public {
        emit unfollowed(msg.sender, followedProfiles[msg.sender][index]);

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

        emit imageSet(msg.sender, imageURL);
    }
    
    function getProfileImage(address user) public view returns (string memory) {
        return profileImage[user];
    }
    
    function setDescription(string memory newDescription) public {
        description[msg.sender] = newDescription;

        emit descriptionSet(msg.sender, newDescription);
    }
    
    function getDescription(address user) public view returns (string memory) {
        return description[user];
    }

    function setSocialMedia(string memory _socialMedia) public {
        socialMedia[msg.sender] = _socialMedia;
    }

    function getSocialMedia(address user) public view returns (string memory) {
        return socialMedia[user];
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