/**
 *Submitted for verification at snowtrace.io on 2021-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.13;
// My First Test Contract
contract GetAvax {
    address owner;
    address payable public tresury = 0x3e63601b3C520278D08490DDA419c764F27d5492; //My Metamask Avax Address
    uint public fundsReceived;
    bool public paused;
    address public smartContractAddress = address(this);
    constructor() public{
        owner = msg.sender; // In this case 0x3e63601b3C520278D08490DDA419c764F27d5492;
    }
    // Function to pause the contract at will
    function pause(bool _bool) public {
        require(owner == msg.sender, 'You are not the owner!!!');
        paused = _bool;
    }
    // Function to destroy the contract at will
    function destroySmartContract(address payable _liquitdateTo) public {
        require(owner == msg.sender, 'You are not the owner!!!');
        require(paused == true, 'Contract Status: Not-Paused - Must first pause!!!');
        selfdestruct(_liquitdateTo);
    }
    // Function to get funds and check how much funds recived in total from the beginning
    function getFunds() public payable {
        fundsReceived += msg.value;
        tresury.transfer(address(this).balance);
    }
    // Function to get the current balance, in theroy it should always be zero, as funds are always diverted to treasury
    function getCurrentBalance() public view returns(uint) {
        require(owner == msg.sender, 'You are not the owner!!!');
        require(paused == false, 'Contract Status: Paused!!!');
        return address(this).balance;
    }

}