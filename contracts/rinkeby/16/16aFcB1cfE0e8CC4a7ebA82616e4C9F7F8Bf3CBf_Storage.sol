/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.0;

    
contract Storage {
    
    string  senderName;
    string  receiverName;
    string  observerNames;
    string  date;


    function saveContractParticipants(string memory newSenderName, string memory newReceiverName, string memory newObserverNames, string memory newDate) public {
        senderName = newSenderName;
        receiverName = newReceiverName;
        observerNames = newObserverNames;
        date = newDate;
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

}