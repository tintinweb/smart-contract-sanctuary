/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// File: contracts/SimpleBank.sol

pragma solidity ^0.5.0;
 

contract CoreBank {

    //dictionary that map addressed to balances
    mapping (address => uint256) public balances;

    //Users to system
    address[] accounts;

    //Owner of the system
    address public owner;

    // Interest rate
    uint256 rate =3;

    //Event User
    event DepositMade(address indexed accountAddress, uint256 amount);
    event WithdrawMade(address indexed accounAddress , uint256 amount);

    //Event System
    event SystemDepositMade(address indexed admin, uint256 amount);
    event SystemWithdrawMade(address indexed admin, uint256 amount);
    event PayDividendMade(address indexed admin, uint256 totalInterest);

    constructor() public {
        owner = msg.sender;
    }

    function deposit() public payable returns (uint256) {
        if (balances[msg.sender] == 0) {
            accounts.push(msg.sender);
        }
        balances[msg.sender] += msg.value;
        //Broadcast deposit event
        emit DepositMade(msg.sender, msg.value);
        return balances[msg.sender];
    }

    function withdraw(uint256 withdrawAmount) 
    public returns (uint256 remainingBalance) {
        require(balances[msg.sender] >= withdrawAmount, "amount to withdraw is not enought!");
        balances[msg.sender] -= withdrawAmount;

        //Transfer ether back to user , revert on failed
        msg.sender.transfer(withdrawAmount);

        //return balances[msg,sender];
        remainingBalance = balances[msg.sender];
        //Broadcast event
        emit WithdrawMade(msg.sender, withdrawAmount);

    }

    function systemBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function systemWithdraw(uint256 withdrawAmount) public returns (uint256) {
        //Only owner
        require(owner == msg.sender, "you 're not authorized to perform this action");
        require(withdrawAmount <= systemBalance(), "amount to withdraw is not enough!");

        //Transfer ether back to user , revert on failed
        msg.sender.transfer(withdrawAmount);

        //Broadcast eventemit SystemWithdrawMade
        emit SystemWithdrawMade(msg.sender, withdrawAmount);
        return systemBalance();
    }

    function systemDeposit() public payable returns (uint256) {
        //Only owner
        require(owner == msg.sender, "you 're not authorized to perform this action");
        //Broadcast event
        emit SystemDepositMade(msg.sender, msg.value);
        return systemBalance();
    }
    // interest per year
    function calculateInterest(address user, uint256 _rate) private view returns (uint256) {
        uint256 interest = balances[user] * _rate/100;
        return interest;
    }

    function totalInterestPerYear() external view returns(uint256) {
        uint256 totalInterest = 0;
        for (uint256 i=0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            totalInterest += interest;
        }
        return totalInterest;
    }

    function payDividendsPerYear() public payable {
        require(owner ==msg.sender, "you 're not authorized to perform this action");
        uint256 totalInterest = 0;
        for (uint256 i=0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            balances[account] += interest;
            totalInterest += interest;

        }
        //Broadcat event
        emit PayDividendMade(msg.sender, totalInterest);
        require(msg.value == totalInterest, "Not enough interest to pay");
    }
}