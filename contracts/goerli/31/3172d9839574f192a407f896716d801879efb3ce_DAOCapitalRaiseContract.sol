/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.5.13;

contract DAOCapitalRaiseContract {
    
// define balanceRec as integer, enables tracking of individual deposits when contributed

uint balanceRec;

// creates a ledger to track the address that a deposit originated from and the amount conributed

mapping(address => uint) depositMapping;
    
// Set raise parametres, minimum, maximum contribtuons and size of total raise in gwei

// dev note - upgrades: prohibit an address from contributing more than once

uint minContribution = 2000000000000000000; // 2 ETH minimum 
uint maxContribution = 10000000000000000000; // 10 ETH max
uint totalRaise = 50000000000000000000; // 50 ETH total raise

// Functions Below

function contributeETH() public payable {
    
    require(msg.value >= minContribution, "Minimum Contribution Not Met, Please Incease Amount");
    require(msg.value <= maxContribution, "Max Contribution Exceeded, Please Lower Amount");
    require(balanceRec + msg.value < totalRaise, "Total Raise Amount Has Been Met, Contact Admin");

    balanceRec += msg.value;
    depositMapping[msg.sender] = msg.value;
}

// Creates a view command, whereby a depositor can check to see how much they have contributed to the contract

function myDeposit() public view returns(uint) {
    return depositMapping[msg.sender];
}

// Creates a view command, whereby anyone can check the total deposits into the smart contract

function totalDeposits() public view returns(uint) {
    return uint(balanceRec); 
}

// Creates a view command, whereby anyone can check the total raise size

function totalRaiseSize() public view returns(uint) {
    return uint(totalRaise);
}

// Creates a view command, whereby anyone can check the balance of the smart contract

function raiseBalance() public view returns(uint) {
    return address(this).balance;   
}
    
// Function when called transfers the balance of ETH to DAO Capital multisig contract

function sendToMultiSig() public {
    address payable to = 0x5791b08B3F51e80903af7a694392B793DBd9CA38;
    to.transfer(this.totalDeposits());
        
    }
}