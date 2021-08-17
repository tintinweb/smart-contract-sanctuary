/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.0;

    
contract Storage {
    
    string  senderName;
    string  receiverName;
    string  observerNames;
    string  date;
    string  dataHashed;


    function saveContractParticipants(string memory SenderName, string memory ReceiverName, string memory ObserverNames, string memory transactionDate, string memory hashedData) public {
        senderName = SenderName;
        receiverName = ReceiverName;
        observerNames = ObserverNames;
        date = transactionDate;
        dataHashed = hashedData;
    }

    function getSenderName() public view returns ( string memory) {
      return senderName;
    }

    function getReceiverName() public view returns ( string memory) {
      return receiverName;
    }
    
    function getObserverNames() public view returns ( string memory) {
      return observerNames;
    }
    
    function getDate() public view returns ( string memory) {
      return date;
    }
    
    function getHashedData() public view returns ( string memory) {
      return dataHashed;
    }

}