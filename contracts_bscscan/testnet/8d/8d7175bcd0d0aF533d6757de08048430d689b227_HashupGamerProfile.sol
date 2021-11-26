/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IHashupNicknames {
    function getNickname(address user) external view returns (string memory);
    function getAddress(string memory nickname) external view returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract HashupGamerProfile {
    mapping(address => address[]) followers;
    mapping(address => address[]) followedProfiles;
    mapping(address => string) profileImage;
    mapping(address => string) backgroundImage;
    mapping(address => string) description;
    mapping(address => string) socialMedia;

    uint256 descriptionSetPool;
    uint256 imageSetPool;
    uint256 backgroundSetPool;
    uint256 socialsSetPool;

    mapping(address => bool) hasSetDescription;
    mapping(address => bool) hasSetImage;
    mapping(address => bool) hasSetBackground;
    mapping(address => bool) hasSetSocials;

    uint256 poolLowerLimit = 100_000;    
    uint256 poolHigherLimit = 1_000_000;

    uint256 poolLowerLimitReward = 50;
    uint256 poolHigherLimitReward = 10;

    address HashupNicknames = 0x81732cceC32d7f99c1babd4bDC56bc8fe59670e3;
    address Hash = 0xecE74A8ca5c1eA2037a36EA54B69A256803FD6ea;

    event descriptionSet(address indexed index, string description);
    event imageSet(address indexed index, string image);
    event backgroundImageSet(address indexed index, string image);

    event followed(address indexed follower, address indexed followedAddress);
    event unfollowed(address indexed follower, address indexed unfollowedAddress);
    
    function follow(string memory user) public {
        address userAddress = IHashupNicknames(HashupNicknames).getAddress(user);
        require(userAddress != address(0), 'Followed user has to have a nickname');
        require(userAddress != msg.sender, 'Cannot follow oneself');
        
        followedProfiles[msg.sender].push(userAddress);
        followers[userAddress].push(msg.sender);

        emit followed(msg.sender, userAddress);
    }
    
    function removeFollowerByIndex(uint256 index) public {
        emit unfollowed(followers[msg.sender][index], msg.sender);

        address followerAddress = followers[msg.sender][index];
        for (uint256 i = 0; i < followedProfiles[followerAddress].length; ++i) {
            if (followedProfiles[followerAddress][i] == msg.sender) {
                followedProfiles[followerAddress][i] = followedProfiles[followerAddress][followedProfiles[followerAddress].length - 1];
                followedProfiles[followerAddress].pop();
                break;
            }
        }

        followers[msg.sender][index] = followers[msg.sender][followers[msg.sender].length - 1];
        followers[msg.sender].pop();
    }
    
    function removeFollowedByIndex(uint256 index) public {
        emit unfollowed(msg.sender, followedProfiles[msg.sender][index]);

        address unfollowedAddress = followedProfiles[msg.sender][index];
        for (uint256 i = 0; i < followers[unfollowedAddress].length; ++i) {
            if (followers[unfollowedAddress][i] == msg.sender) {
                followers[unfollowedAddress][i] = followers[unfollowedAddress][followers[unfollowedAddress].length - 1];
                followers[unfollowedAddress].pop();
                break;
            }
        }

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

    function setProfileImageWithReward(string memory imageURL) public {
        require(imageSetPool < poolHigherLimit && !hasSetImage[msg.sender]);

        imageSetPool += 1;
        hasSetImage[msg.sender] = true;

        sendReward(imageSetPool);

        this.setProfileImage(imageURL);
    }

    function setBackgroundImage(string memory imageURL) public {
        backgroundImage[msg.sender] = imageURL;

        emit backgroundImageSet(msg.sender, imageURL);
    }

    function setBackgroundImageWithReward(string memory imageURL) public {
        require(backgroundSetPool < poolHigherLimit && !hasSetBackground[msg.sender]);

        backgroundSetPool += 1;
        hasSetBackground[msg.sender] = true;

        sendReward(backgroundSetPool);

        this.setBackgroundImage(imageURL);
    }

    function getBackgroundImage(address user) public view returns (string memory) {
        return backgroundImage[user];
    }
    
    function getProfileImage(address user) public view returns (string memory) {
        return profileImage[user];
    }
    
    function setDescription(string memory newDescription) public {
        description[msg.sender] = newDescription;

        emit descriptionSet(msg.sender, newDescription);
    }

    function setDescriptionWithReward(string memory newDescription) public {
        require(descriptionSetPool < poolHigherLimit && !hasSetDescription[msg.sender]);

        descriptionSetPool += 1;
        hasSetDescription[msg.sender] = true;

        sendReward(descriptionSetPool);

        this.setDescription(newDescription);
    }
    
    function getDescription(address user) public view returns (string memory) {
        return description[user];
    }

    function setSocialMedia(string memory _socialMedia) public {
        socialMedia[msg.sender] = _socialMedia;
    }

    function setSocialMediaWithReward(string memory _socialMedia) public {
        require(socialsSetPool < poolHigherLimit && !hasSetSocials[msg.sender]);

        socialsSetPool += 1;
        hasSetSocials[msg.sender] = true;

        sendReward(socialsSetPool);

        this.setSocialMedia(_socialMedia);
    }

    function getSocialMedia(address user) public view returns (string memory) {
        return socialMedia[user];
    }

    function generateEarlyAdopterReward(uint256 pool) internal view returns (uint256) {
        if (pool < poolLowerLimit) {
            return poolLowerLimitReward;
        } else if (pool < poolHigherLimit) {
            return poolHigherLimitReward;
        }
        
        return 0;
    }

    function sendReward(uint256 pool) internal {
        IERC20(Hash).transfer(msg.sender, generateEarlyAdopterReward(pool) * (10 ** uint256(17)));
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