/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract MultiSignatureWallet {
    
    struct Transaction {
        address payable destination;
        uint256 value;
        bool executed;
    }

    mapping (uint => Transaction) transactions;
    uint256 transactionCount;

    mapping (uint256 => mapping (address => bool)) confirmations;
    uint256 public confirmationsRequired;

    address[] public owners;
    mapping (address => bool) isOwner;


    constructor(address[] memory _owners) {
        owners = _owners;
        owners.push(msg.sender);
        for (uint8 i=0; i<_owners.length; i++ ){
            isOwner[_owners[i]] = true;
        }
        transactionCount = 0;
        confirmationsRequired = _owners.length/2 + 1;
    }

    function addTransaction(address payable _destination, uint256 _value) public returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction(_destination, _value, false);
        transactionCount+=1;
    }
    
    function getConfirmations(uint256 _transactionId) public view returns (uint256 count) {
        count = 0;
        for (uint256 i = 0; i < owners.length -1; i++ ) {
            if (confirmations[_transactionId][owners[i]] == true) {
                count += 1;
            }
        }
        return count;
    }
    
    function isConfirmed(uint256 _transactionId) internal view returns (bool) {
        if (getConfirmations(_transactionId) >= confirmationsRequired) {
            return true;
        } else {
            return false;
        }
    }

    function executeTransaction(uint256 _transactionId) public {
        if ( isConfirmed(_transactionId) ) {
            // transactions[_transactionId].destination.transfer(transactions[_transactionId].value);
            transactions[_transactionId].executed = true;
        }
    }

    function getTransaction(uint256 _transactionId) public view returns (Transaction memory) {
        return transactions[_transactionId];
    }

    function signTransaction(uint256 _transactionId) public {
        confirmations[_transactionId][msg.sender] = true;
    }


}