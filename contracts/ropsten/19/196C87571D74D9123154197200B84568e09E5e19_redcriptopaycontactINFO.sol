pragma solidity ^0.8.4;

//recriptopay

contract redcriptopaycontactINFO { 
    
 mapping (address => string) usercontactinfo; 
 
  event userEvent(address user, string info);
 
 function Setusercontactinfo (string memory info) external {
     require(tx.origin == msg.sender, "Contracts can not call this function");
     usercontactinfo [msg.sender] = info;
     
     emit userEvent(msg.sender, info);
 }
 function getusercontactinfo (address user) external view returns (string memory) {
     return usercontactinfo [user];
 }
}