/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.8.6;

contract ZapMail {
    
   event SendZapMail(address indexed fromAddress, address indexed toAddress, string ipfsHash);

   function sendEmail(address to, string memory ipfsHash) external returns (bool result) {
       emit SendZapMail(msg.sender, to, ipfsHash);
       return true;
   }
}