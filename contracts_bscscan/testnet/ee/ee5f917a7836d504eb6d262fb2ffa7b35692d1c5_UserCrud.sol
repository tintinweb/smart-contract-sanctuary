/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract UserCrud {

  struct UserStruct {
        uint256 index;
        uint256 CreateTime;
        string  UserName;
        string  NameSurname;
        string  Birthday;
        string  Email;
        string  Description;
        string  WebSite;
        address Account_Address;
  }
  
  mapping(address => UserStruct) private userStructs;
  address[] private userIndex;

  //event LogNewUser   (address indexed userAddress, uint index, string userEmail, uint userAge, address userAddr);
  event LogNewUser   (string UserName, string NameSurname, string Birthday, string Email, string Description, string WebSite, address Address);
  event LogUpdateUser(address indexed userAddress, uint index, string userEmail, uint userAge);
  
  function isUser(address userAddress) public view returns(bool isIndeed) {
    if(userIndex.length == 0) return false;
    return (userIndex[userStructs[userAddress].index] == userAddress);
  }

  /*function insertUser(address userAddress, string memory userEmail, uint userAge) public returns(uint index) {
    require (isUser(userAddress), "User Address Found"); 
    userStructs[userAddress].userEmail = userEmail;
    userStructs[userAddress].userAge   = userAge;
    userIndex.push(userAddress);
    userStructs[userAddress].index     = userIndex.length -1;

    emit LogNewUser(userAddress, userStructs[userAddress].index, userEmail, userAge, msg.sender);
    return userIndex.length -1;
  }*/
  
   function CreatetUser(address userAddress, string memory _UserName, string memory _NameSurname, string memory _Birthday, string memory _Email, string memory _Description, string memory _WebSite) public {
    require (!isUser(userAddress), "User Address Found"); 
    userStructs[userAddress].CreateTime = block.timestamp;
    userStructs[userAddress].UserName = _UserName;
    userStructs[userAddress].NameSurname = _NameSurname;
    userStructs[userAddress].Birthday = _Birthday;
    userStructs[userAddress].Email = _Email;
    userStructs[userAddress].Description = _Description;
    userStructs[userAddress].WebSite = _WebSite;
    userStructs[userAddress].Account_Address  = msg.sender;
    userStructs[userAddress].index     = userIndex.length;
    userIndex.push(userAddress);    
    //emit LogNewUser(userAddress, userStructs[userAddress].index, userEmail, userAge, msg.sender);
    emit LogNewUser(_UserName, _NameSurname, _Birthday, _Email, _Description, _WebSite, msg.sender);
  }
  
  function getUser(address userAddress) public view returns(string memory UserName, string memory NameSurname, string memory Birthday, string memory EMail, string memory Description, string memory WebSite, uint index) {
    require (isUser(userAddress), "User Address Not Found"); 
    return(userStructs[userAddress].UserName, 
           userStructs[userAddress].NameSurname, 
           userStructs[userAddress].Birthday, 
           userStructs[userAddress].Email, 
           userStructs[userAddress].Description, 
           userStructs[userAddress].WebSite, 
           userStructs[userAddress].index);} 
  
  function getUserCount() public view returns(uint count){
    return userIndex.length;
  }

  function getUserAtIndex(uint index) public view returns(address userAddress) {
    return userIndex[index];
  }

}