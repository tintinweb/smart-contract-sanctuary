/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

pragma solidity ^0.5.13;

contract DAOCapitalRaiseContract {

// define balanceRec as integer, enables tracking of individual deposits when contributed

uint balanceRec;
address ownerAddress;
bool public initiateRaise;

// set deployer address as contract owner

constructor() public {
    ownerAddress = msg.sender;
}
// create a ledger to track the address that a deposit originated from and the amount conributed

mapping(address => uint) depositMapping;

// create a ledger to track if the address has already contributed to the raise, 0 = not contributed, 1 = contributed

mapping(address => uint) doubleSpendCheck;
    
// Set raise parametres, minimum, maximum contribtuons and size of total raise in gwei


uint minContribution = 1000000000000000000; // 1 ETH minimum default
uint maxContribution = 10000000000000000000; // 10 ETH max default
uint totalRaise = 100000000000000000000; // 100 ETH total raise default

// function enables the owner to begin the raise, off by default on deployment

function startRaise() public {
    require(msg.sender == ownerAddress, "Only Owner Can Begin The Raise");
    initiateRaise = true;
}

// function enables the owner to pause or stop the raise in event of an error

function pauseRaise() public {
    require(msg.sender == ownerAddress, "Only Owner Can Pause/Stop The Raise");
    initiateRaise = false;
}

// function allows the owner to update the minimum contribution amount

function updateMinContribution(uint _minContribution) public {
    require(msg.sender == ownerAddress, "Only Owner Can Update");
    minContribution = _minContribution;
}

// function allows the owner to update the minimum contribution amount

function updateMaxContribution(uint _maxContribution) public {
    require(msg.sender == ownerAddress, "Only Owner Can Update");
    maxContribution = _maxContribution;
}

// function allows the owner to update the minimum contribution amount

function updateTotalRaise(uint _totalRaise) public {
    require(msg.sender == ownerAddress, "Only Owner Can Update");
    totalRaise = _totalRaise;
}

// function allows the owner to update the minimum contribution amount

function transferOwner(address _newOwner) public {
    require(msg.sender == ownerAddress, "Only Owner Can Transfer Ownership");
    ownerAddress = _newOwner;
}

// Contribution function, checks to see if parametres have been met. If so, balance is recorded in depositMapping and marked as contributed (1) in doubleSpendCheck ledger

function contributeETH() public payable {
    
    require(initiateRaise == true, "Raise Has Not Yet Begun");
    require(msg.value >= minContribution, "Minimum Contribution Not Met, Please Incease Amount");
    require(msg.value <= maxContribution, "Max Contribution Exceeded, Please Lower Amount");
    require(balanceRec + msg.value < totalRaise, "Total Raise Amount Has Been Met, Contact Admin");
    require(doubleSpendCheck[msg.sender] == 0, "You Have Already Contributed To This Raise");

    doubleSpendCheck[msg.sender] = 1;
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
    
// Function clears all existing data in the smart contract

function xclearData() public {
    require(msg.sender == ownerAddress, "Only Owner Can Clear Existing Data Storage");
    
    minContribution = 0; // Reset minContribution number to 0
    maxContribution = 0; // Reset maxContribution number to 0
    totalRaise = 0; // Reset totalRaise number to 0
    }
}