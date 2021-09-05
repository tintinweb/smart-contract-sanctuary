/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Deposit {
    
    address private owner;
    
    struct DepositTransaction {
        address _address;
        uint256 _amount;
    }

    mapping(uint256 => DepositTransaction) public transactions;
    uint256 public id;
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withdraw() public isOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }
    
    receive() external payable {
        DepositTransaction storage newTx = transactions[id++];
        newTx._address = msg.sender;
        newTx._amount = msg.value;
    }
}