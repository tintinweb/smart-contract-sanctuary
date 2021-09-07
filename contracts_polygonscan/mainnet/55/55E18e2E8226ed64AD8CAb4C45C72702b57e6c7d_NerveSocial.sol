/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NerveSocial
{
    mapping(address => bytes32) public addressRegister;
    mapping(bytes32 => address) public nameRegister;
    

    event NameRegistered(address indexed user, bytes32 registeredName);
    event SocialRegistered(address indexed user, string[] socialLinks, uint256[] socialIds);
    event LocationRegistered(address indexed user, uint256 latitude, uint256 longitude);  
    event UserBlacklisted(address indexed user, address userToBlacklist);
    
    
    /******************************************/
    /*       NerveSocial starts here         */
    /******************************************/


    /**
    * @dev Public function to register a unique name to an address. 
    * @param registeredName Name the user wishes to register. 
    */
    function registerName(bytes32 registeredName) external
    {
        if (registeredName [0] != 0) 
        {
            require(nameRegister[registeredName] == address(0), "Name already taken.");
            bytes32 actualName;
            if (addressRegister[msg.sender] != 0) 
            {
                actualName = addressRegister[msg.sender]; 
                delete nameRegister[actualName];
            }
            addressRegister[msg.sender] = registeredName;
            nameRegister[registeredName] = msg.sender;

            emit NameRegistered(msg.sender, registeredName);
        }
    }


    /**
    * @dev Public function to register social media links. 
    * @param registeredLink Link to a social media profile. 
    * @param socialID Dapp ID of social media link.
    */
    function registerSocial(string[] memory registeredLink, uint256[] memory socialID) external
    {            
        uint256 arrayLength = registeredLink.length;
        string[] memory socialLinks = new string[](arrayLength);
        
        uint256 socialArrayLength = socialID.length;
        uint256[] memory socialIds = new uint256[](socialArrayLength);
        emit SocialRegistered(msg.sender, socialLinks, socialIds);
    }
    
    
    /**
    * @dev Public function to set location for google maps.
    * @param latitude Coordinates of the latitude.
    * @param longitude Coordinates of the longitude.
    */
    function setLocation(uint256 latitude, uint256 longitude) external
    {
        emit LocationRegistered(msg.sender, latitude, longitude);
    }


    /**
    * @dev Public function to put a user on the blacklist. 
    * @param userToBlacklist Address of user to blacklist.
    */
    function setBlacklistUser(address userToBlacklist) external
    {
        emit UserBlacklisted(msg.sender, userToBlacklist);
    }
}