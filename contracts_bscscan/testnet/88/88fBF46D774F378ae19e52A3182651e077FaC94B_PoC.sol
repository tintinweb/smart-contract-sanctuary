/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity ^0.8.7;

contract PoC{
   struct PersonalInfo {
       string name;
       uint256 id;
       string email;
       string password;
       bool accountCreate;
   }
   
   uint256 public accountCreationFee=1 ether;
   mapping(address=> PersonalInfo) public addressToPersonalInfo;
   mapping(uint256=> PersonalInfo) public idToPersonalInfo;
   
   function AccountCreation(string memory _name, uint256 _id, string memory _password) payable external returns(bool){
       require(msg.value>=accountCreationFee,"you are not paying enough fee");
       require(!addressToPersonalInfo[msg.sender].accountCreate,"You have already create the account"); 
       addressToPersonalInfo[msg.sender].name = _name;
       addressToPersonalInfo[msg.sender].id = _id;
        addressToPersonalInfo[msg.sender].password = _password;
       addressToPersonalInfo[msg.sender].accountCreate = true;
       return true;
   }
    
}