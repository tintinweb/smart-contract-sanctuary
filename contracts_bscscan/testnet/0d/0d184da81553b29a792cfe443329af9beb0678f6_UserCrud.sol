/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract UserCrud {

  struct Account {
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
  
  mapping(address => Account) private AccountStruct;
  address[] private AccountIndex;

  //event LogNewUser   (address indexed userAddress, uint index, string userEmail, uint userAge, address userAddr);
  event LogNewUser   (string UserName, string NameSurname, string Birthday, string Email, string Description, string WebSite, address Address);
  event LogUpdateUser(address indexed userAddress, uint index, string userEmail, uint userAge);
  
  function isUser(address userAddress) public view returns(bool isIndeed) {
    if(AccountIndex.length == 0) return false;
    return (AccountIndex[AccountStruct[userAddress].index] == userAddress);
  }

  /*function insertUser(address userAddress, string memory userEmail, uint userAge) public returns(uint index) {
    require (isUser(userAddress), "User Address Found"); 
    AccountStruct[userAddress].userEmail = userEmail;
    AccountStruct[userAddress].userAge   = userAge;
    AccountIndex.push(userAddress);
    AccountStruct[userAddress].index     = AccountIndex.length -1;

    emit LogNewUser(userAddress, AccountStruct[userAddress].index, userEmail, userAge, msg.sender);
    return AccountIndex.length -1;
  }*/
  
     //- Create Account Control in Code
    modifier CreateAccountControl(address _address, string memory _username, string memory _namesurname, string memory _email) {
        require(keccak256(abi.encodePacked(_username)) != keccak256(abi.encodePacked("")), "err_code : 7");
        require(keccak256(abi.encodePacked(_namesurname)) != keccak256(abi.encodePacked("")), "err_code : 8");
        require(keccak256(abi.encodePacked(_email)) != keccak256(abi.encodePacked("")), "err_code : 9");
        for ( uint i = 0; i < AccountIndex.length; i++ ) {
            //- Address Control
            if ( AccountStruct[AccountIndex[i]].Account_Address == _address  ) revert("err_code : 3");        
            //- UserName Control
            if ( keccak256(abi.encodePacked(AccountStruct[AccountIndex[i]].UserName)) == keccak256(abi.encodePacked(_username)) ) revert("err_code : 4");
            //- EMail Control
            if ( keccak256(abi.encodePacked(AccountStruct[AccountIndex[i]].Email)) == keccak256(abi.encodePacked(_email)) ) revert("err_code : 5");
        } _;
    }
  
   function CreatetUser(address userAddress, string memory _UserName, string memory _NameSurname, string memory _Birthday, string memory _Email, string memory _Description, string memory _WebSite) public 
    CreateAccountControl(userAddress, _UserName, _NameSurname, _Email) {
    AccountStruct[userAddress].CreateTime = block.timestamp;
    AccountStruct[userAddress].UserName = _UserName;
    AccountStruct[userAddress].NameSurname = _NameSurname;
    AccountStruct[userAddress].Birthday = _Birthday;
    AccountStruct[userAddress].Email = _Email;
    AccountStruct[userAddress].Description = _Description;
    AccountStruct[userAddress].WebSite = _WebSite;
    AccountStruct[userAddress].Account_Address  = msg.sender;
    AccountStruct[userAddress].index     = AccountIndex.length;
    AccountIndex.push(userAddress);    
    //emit LogNewUser(userAddress, AccountStruct[userAddress].index, userEmail, userAge, msg.sender);
    emit LogNewUser(_UserName, _NameSurname, _Birthday, _Email, _Description, _WebSite, msg.sender);
  }
  
  function getUser(address userAddress) public view returns(string memory UserName, string memory NameSurname, string memory Birthday, string memory EMail, string memory Description, string memory WebSite, uint index) {
    require (isUser(userAddress), "User Address Not Found"); 
    return(AccountStruct[userAddress].UserName, 
           AccountStruct[userAddress].NameSurname, 
           AccountStruct[userAddress].Birthday, 
           AccountStruct[userAddress].Email, 
           AccountStruct[userAddress].Description, 
           AccountStruct[userAddress].WebSite, 
           AccountStruct[userAddress].index);} 
  
  function getUserCount() public view returns(uint count){
    return AccountIndex.length;
  }

  function getUserAtIndex(uint index) public view returns(address userAddress) {
    return AccountIndex[index];
  }

}