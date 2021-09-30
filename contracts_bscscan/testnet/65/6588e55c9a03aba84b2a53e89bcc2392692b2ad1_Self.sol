/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT



contract Self
{
    /**
     * A profile composed by a name, avatar and bio
     **/
    struct Profile
    {
        string bio;
        string name;
        string avatar;
        address account;
    }


    mapping(address => Profile) public profiles;
    
    /**
     * Builds a new profile object based on the inputted properties
     **/
    function profileFactory (address _account, string memory _name, string memory _bio, string memory _avatar) private pure returns(Profile memory)
    {
        return Profile({name:_name, bio:_bio, avatar:_avatar, account:_account});
    }
    
   function setProfile(string memory name, string memory avatar, string memory bio)  public{
       if(bytes(name).length == 0)
       {
           revert("The name is required");
       }
       profiles[msg.sender]= profileFactory(msg.sender, name, bio, avatar);
   }
   
   function setName(string memory name)  external 
   {
       profiles[msg.sender].name = name;
   }
   
   function getName(address account)  external view returns(string memory)
   {
       return profiles[account].name;
   }
   
   function setBio(string memory bio)  external
   {
       profiles[msg.sender].bio = bio;
   }
   
   function getBio(address account)  external view returns(string memory)
   {
       return profiles[account].bio;
   }
   
   function setAvatar(string memory avatar)  external
   {
       profiles[msg.sender].avatar = avatar;
   }
   
   function getAvatar(address account)  external view returns(string memory)
   {
       return profiles[account].avatar;
   }
   
}