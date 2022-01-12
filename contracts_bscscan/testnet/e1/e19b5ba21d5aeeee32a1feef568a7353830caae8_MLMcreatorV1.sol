/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract MLMcreatorV1{
    
    address public owner;
    address public collector;
    
    function initializeAddress (address ownerAddress, address collectorAddress) external{ // Owner Address is Owner of the Contract and Collectors is the Hot Wallet Address to aggregate collected funds. 
         owner = ownerAddress;
         collector = collectorAddress;
    }     
    
     struct User {
         address myAddress;
         string sponsorName;
    }
    
    mapping(string => User) public UserNameMap;
    mapping(address => string) public userAddressMap;
    mapping(string => uint) public userRegTime;
    mapping(string => address[]) public userDownline;
    mapping(address => bool) public userExist;

    function registration(string memory sponsorName, string memory _UserName) external{
         require (!doesUserExist(getUserfromAddress(msg.sender)), "User Exits");
         require(doesUserExist(sponsorName), "Sponsor is not a Registered User" );
         require(!doesUserExist(_UserName), "Sorry, The UserName is already in use");
         require(userExist[msg.sender] == false, "Sorry, The Useraddress is already a user");
         address userAddress = msg.sender;
         User memory users = User ({
            myAddress : userAddress,
            sponsorName : sponsorName
           });
        UserNameMap[_UserName] = users;
        userRegTime[_UserName] = block.timestamp;
        userDownline[sponsorName].push(userAddress);
        userExist[userAddress] = true;
    }
    
     function getSponsorName(string memory username) public view returns(string memory) { 
          return UserNameMap[username].sponsorName;
    }
    
    function getUserfromAddress(address userAddress) public view returns(string memory) {
        return userAddressMap[userAddress];
    }
     
    function doesUserExist (string memory username) public view returns(bool) {
        return UserNameMap[username].myAddress != address(0);
    }
    function getUserDownline(string memory username) public view returns(address [] memory ) {
        return userDownline[username];
    }
    function getUserDownlineCount(string memory username) public view returns(uint){
        return userDownline[username].length;
    }
    
    function getSuperRegister(string memory _username, address _userAddress, string memory _sponsorName, uint _RegTime) external {
        require (msg.sender == owner);
        require(userExist[_userAddress] == false, "Sorry, The Useraddress is already a user");
        User memory users = User ({
            myAddress : _userAddress,
            sponsorName : _sponsorName
          });
        UserNameMap[_username] = users;
        userRegTime[_username] = _RegTime;
        userDownline[ _sponsorName].push(_userAddress);
        userAddressMap[_userAddress] = _username;
        userExist[_userAddress] = true;
    }


}