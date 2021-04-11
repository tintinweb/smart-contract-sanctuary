/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// Part: IMomint

interface IMomint
{
    function balanceOf(address _owner) external view returns (uint256);
}

// File: MomintSocial.sol

contract MomintSocial
{
    struct User
    {
        string name;
        string bio;
        string avatarHash;
        uint256 amountFollowing;
        uint256 amountFollowers;
        bool verified;
    }

    mapping(address => User) userMap;
    mapping(address => bool) isUser;
    mapping(string => bool) isUsernameTaken;

    modifier onlyUser
    {
        require(isUser[msg.sender] == true);
        _;
    }

    mapping(address => uint256[]) userTokens;
    mapping(address => address[]) userFollowing;
    mapping(address => address[]) userFollowers;


    IMomint MOMINT;
    constructor(address _MOMINT) public
    {
        MOMINT = IMomint(_MOMINT);
    }

    /*Returns bool based on if user is registered on the platform */
    function isValidUser(address _user) external view returns (bool)
    {
        return isUser[_user];
    }

    /*User Functions*/
    /*Pass a username, biography, and IPFS hash to an avatar*/
    function setUserInfo(string memory _name, string memory _bio, string memory _avatarHash) external
    {
        if(isUser[msg.sender] == true)
        {
            User memory user = userMap[msg.sender];
            if (keccak256(abi.encodePacked((_name))) == keccak256(abi.encodePacked((user.name))))
            {
                userMap[msg.sender] = User(_name, _bio, _avatarHash, user.amountFollowing, user.amountFollowers, user.verified);
            }
            else
            {
                require(isUsernameTaken[_name] != true, "Username is taken");
                isUsernameTaken[user.name] = false;
                isUsernameTaken[_name] = true;

                userMap[msg.sender] = User(_name, _bio, _avatarHash, user.amountFollowing, user.amountFollowers, user.verified);
            }

        }
        else
        {
            require(isUsernameTaken[_name] != true, "Username is taken");
            userMap[msg.sender] = User(_name, _bio, _avatarHash, 0, 0, false);
            isUser[msg.sender] = true;
            isUsernameTaken[_name] = true;
        }
    }

    /*Return a user's profile information*/
    function getUserInfo(address _user) external view
    returns(string memory _name, string memory _bio, string memory _ipfs, uint256 _amountFollowing, uint256 _amountFollowers, uint256 amountTokens)
    {
        User memory user = userMap[_user];
        return (user.name, user.bio, user.avatarHash, user.amountFollowing, user.amountFollowers, MOMINT.balanceOf(_user));
    }


    /*Follow a user => Pass in a valid user address*/
    function followUser(address _user) external onlyUser
    {
        require(isUser[_user] == true, "User does not exist!");
        require(_user != msg.sender, "You can not follow yourself!");
        User memory user = userMap[msg.sender];
        User memory toFollow = userMap[_user];

        userFollowing[msg.sender].push(_user);
        userFollowers[_user].push(msg.sender);

        user.amountFollowing += 1;
        toFollow.amountFollowers += 1;
    }
    /*Unfollow a user => Pass in a valid user address*/
    function unfollowUser(address _user) external onlyUser
    {
        require(isUser[_user] == true, "User does not exist!");
        User memory user = userMap[msg.sender];
        User memory toUnfollow = userMap[_user];

        for(uint i = 0; i < userFollowing[msg.sender].length; i++)
        {
            if (userFollowing[msg.sender][i] == _user)
            {
                delete userFollowing[msg.sender][i];
                user.amountFollowing -= 1;
                break;
            }
        }
        for(uint i = 0; i < userFollowers[_user].length; i++)
        {
            if(userFollowers[_user][i] == msg.sender)
            {
                delete userFollowers[_user][i];
                toUnfollow.amountFollowers -= 1;
                break;
            }
        }
    }

     /*Return a user's following at a specific index*/
    function getUserFollowing(address _user, uint256 _i) external view
    returns(address user)
    {
        return userFollowing[_user][_i];
    }
    /*Return a user's follower at a specific index*/
    function getUserFollowers(address _user, uint256 _i) external view
    returns(address user)
    {
        return userFollowers[_user][_i];
    }

}