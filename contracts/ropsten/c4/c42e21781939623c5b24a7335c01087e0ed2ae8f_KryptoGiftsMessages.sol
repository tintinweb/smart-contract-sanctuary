pragma solidity ^0.4.4;
    contract KryptoGiftsMessages {

     address private admin;

     mapping(string => string)  txIdMessages; 

      function KryptoGiftsMessages ()  {
        admin = msg.sender;
      }

     function addMessage(string txId, string userMsg) payable external{
         require(msg.sender == admin);
         txIdMessages[txId] = userMsg;
     }
     
     function getData(string txId) view returns (string){
         return txIdMessages[txId];
     }
     
}