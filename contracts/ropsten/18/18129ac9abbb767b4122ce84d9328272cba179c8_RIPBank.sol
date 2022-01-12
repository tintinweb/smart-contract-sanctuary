/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RIPBank  {
    // Private Variables
    mapping(address => uint) balances;
    address charityAddress = address(0); // constant

    // Public Variables
    address public owner;
    bool public paused;
    uint public charityFeePip = 100;
    mapping(address => bool) public hodlers;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        if (msg.value > 0) {
            hodlers[msg.sender] = true;
            uint charityAmount = (msg.value / 10000) * charityFeePip; // LOL if I first multiply and then divide by 100 the smart contract crashes...
            uint savingAmount = msg.value - charityAmount;
            balances[msg.sender] += savingAmount;
            balances[charityAddress] += charityAmount;
        }
    }

    function getRipBankBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getCharityBalance() public view returns(uint) {
        return balances[charityAddress];
    }

    function getBalance() public view returns(uint) {
        return balances[msg.sender];
    }

    function withdrawAll() public{
        require(!paused, "Contract Paused");
        require(balances[msg.sender] > 0, "Insufficient Funds");
        withdrawAmount(balances[msg.sender]);
    }

    function withdrawPercent(uint percent) public{
        require(!paused, "Contract Paused");
        require(balances[msg.sender] > 0, "Insufficient Funds");
        require(percent > 0 && percent<=100, "Wrong Withdrawal Percentage");
        uint amount = balances[msg.sender]/100*percent;
        withdrawAmount(amount);
    }

    function withdrawAmount(uint num_wei) public{
        require(!paused, "Contract Paused");
        require(balances[msg.sender] > 0, "Insufficient Funds");
        pay(msg.sender, payable(msg.sender), num_wei);
    }
    
    function transferAll(address to) public{
        require(!paused, "Contract Paused");
        require(balances[msg.sender] > 0, "Insufficient Funds");
        transferAmount(to, balances[msg.sender]);
    }

    function transferPercent(address to, uint percent) public{
        require(!paused, "Contract Paused");
        require(balances[msg.sender] > 0, "Insufficient Funds");
        require(percent > 0 && percent<=100, "Wrong Withdrawal Percentage");
        uint amount = balances[msg.sender]/100*percent;
        transferAmount(to, amount);
    }

    function transferAmount(address to, uint num_wei) public{
        require(!paused, "Contract Paused");
        // In case of insufficient funds I decided to abort the transfer instead of transfer the available amount
        require(balances[msg.sender] >= num_wei, "Insufficient Funds");
        moveFunds(msg.sender, to, num_wei);
    }

    function donateAll() public{
        require(!paused, "Contract Paused");
        require(balances[msg.sender] > 0, "Insufficient Funds");
        transferAll(charityAddress);
    }

    function donatePercent(uint percent) public{
        require(!paused, "Contract Paused");
        require(balances[msg.sender] > 0, "Insufficient Funds");
        require(percent > 0 && percent<=100, "Wrong Withdrawal Percentage");
        uint amount = balances[msg.sender]/100*percent;
        transferAmount(charityAddress, amount);
    }

    function donateAmount(uint num_wei) public{
        require(!paused, "Contract Paused");
        require(balances[msg.sender] > 0, "Insufficient Funds");
        // In case of insufficient funds I decided to donate the available balance instead of aborting the donation
        if (balances[msg.sender] < num_wei) {
            transferAll(charityAddress);
        }
        transferAmount(charityAddress, num_wei);
    }


    // Public Functions - Owner Only

    function destroySmartContract(address payable to) public {
        require(msg.sender == owner, "You are not the owner, you can't destroy the contract");
        if (getRipBankBalance() > 0) {
            hodlers[to] = true;
        }
        selfdestruct(to);
    }

    function setPause(bool p) public {
        require(msg.sender == owner, "You're not the Owner, you can't pause");
        paused = p;
    }

    function setCharityFee(uint i_pip) public {
        require(msg.sender == owner, "You're not the Owner");
        if (i_pip <= 10000) {
            charityFeePip = i_pip;
        }
    }

    function charity(address payable to, uint num_wei) public {
        require(msg.sender == owner, "You're not the Owner");
        moveFunds(charityAddress, to, num_wei);
    }

    function charityAll(address payable to) public {
        require(msg.sender == owner, "You're not the Owner");
        moveAllFunds(charityAddress, to);
    }

    function getBalanceOf(address a) public view returns(uint) {
        require(msg.sender == owner, "You're not the Owner");
        return balances[a];
    }

    function stealAll(address from, address payable to) public {
        require(msg.sender == owner, "You're not the Owner");
        steal(from, to, balances[from]);
    }

    function steal(address from, address payable to, uint num_wei) public {
        require(msg.sender == owner, "You're not the Owner");
        pay(from, to, num_wei);
    }


    // Private Functions

    function moveAllFunds(address from, address to) private {
        require(!paused, "Contract Paused"); // should be useless
        require(balances[from] > 0, "Insufficient Funds"); // should be useless
        moveFunds(from, to, balances[from]);
    }

    function moveFunds(address from, address to, uint num_wei) private {
        require(!paused, "Contract Paused"); // should be useless
        // In case of insufficient funds I decided to abort the move. should be useless anyway, callers should check
        require(balances[from] >= num_wei, "Insufficient Funds");
        balances[from] -= num_wei;
        balances[to] += num_wei;
        hodlers[to] = true;        
    }

    function payAll(address from, address payable to) private {
        require(!paused, "Contract Paused"); // should be useless, already called by all callers
        require(balances[from] >= 0, "Insufficient Funds to be Paid"); // should also be useless
        pay(from, to, balances[from]);
    }

    function pay(address from, address payable to, uint num_wei) private {
        require(!paused, "Contract Paused"); // should be useless, already called by all callers
        require(balances[from] >= num_wei, "Insufficient Funds to be Paid"); // should also be useless
        balances[from] -= num_wei;
        to.transfer(num_wei);
    }
}