/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: ISocial

interface ISocial {
     function isValidUser(address _user) external view returns (bool);
}

// File: MomintLikes.sol

contract MomintLikes {

    mapping(uint256 => uint256) tokenLikes;
    mapping(uint256 => mapping(address => bool)) userLikedToken;

    ISocial SOCIAL;
    constructor(ISocial _social) public {
        SOCIAL = ISocial(_social);
    }

     modifier onlyUser {
        require(SOCIAL.isValidUser(msg.sender) == true, "You are not a valid user!");
         _;
    }

    /*Like a post => Pass in a valid tokenID */
    function likePost(uint256 _tokenID) external onlyUser
    {
        require(userLikedToken[_tokenID][msg.sender] == false, "You have already liked this post!");
        userLikedToken[_tokenID][msg.sender] = true;
        tokenLikes[_tokenID] += 1;
    }
    /*Unlike a post => Pass in a valid tokenID*/
    function unlikePost(uint256 _tokenID) external onlyUser
    {
        require(userLikedToken[_tokenID][msg.sender] == true, "You have not liked this post!");
        userLikedToken[_tokenID][msg.sender] = false;
        tokenLikes[_tokenID] -= 1;
    }

    /*Return how many likes a token has*/
    function getAmountLikes(uint256 _tokenID) external view returns(uint256 likes)
    {
        return tokenLikes[_tokenID];
    }

}