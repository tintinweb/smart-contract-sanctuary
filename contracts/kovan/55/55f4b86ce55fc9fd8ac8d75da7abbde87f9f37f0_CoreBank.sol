/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// File: SimpleBank.sol

pragma solidity ^0.5.0;

contract CoreBank {
    mapping (address => uint256) public balances;
    address[] accounts;
    address owner;
    
    uint256 rate = 3;

    //envent users
    event DepositMode(address accountAddress, uint256 amount);
    event WithdrawMode(address accountAddress, uint256 amount);

    //envent admin
    event SystemDepositMode(address indexed admin, uint256 amount);
    event SysteWithdrawMode(address indexed admin, uint256 amount);

    constructor() public {
        owner = msg.sender;
    }
    function deposit() public payable  returns(uint256) {
        balances[msg.sender] += msg.value;

        // Broadcase deposit event;
        emit DepositMode(msg.sender, msg.value);
        return balances[msg.sender];
    }

    function withdraw(uint256 withdrawAmount) public returns(uint256 reminingBalance) {
        require(balances[msg.sender] >= withdrawAmount, "amount to withdraw is not enoungth!");
        balances[msg.sender] -= withdrawAmount;

        msg.sender.transfer(withdrawAmount);

        // Broadcasr event
        emit WithdrawMode(msg.sender, withdrawAmount);

        reminingBalance = balances[msg.sender];

    } 

    function systemBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function systemDeposit(uint256) public payable returns(uint256) {
        require(owner == msg.sender, "yo're not autorized to perform this function");
        //Boardcase event
        emit SystemDepositMode(msg.sender, msg.value);
        return systemBalance();
    }
    function calculateInterest(address user, uint256 _rate) public view returns(uint256) {
        uint256 interest = balances[user] * _rate / 100;
        return interest;
    }

    function payDividendsPerYear() public payable {
        require(owner == msg.sender, "yo're not autorized to perform this function");
        uint256 totalInterest = 0;
        for(uint256 i= 0; i<accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            balances[account] +=interest;
        }

        require(msg.value == totalInterest, "Not eoungth interest to pay");
    }

     function totalInterestYear() external view returns(uint256) {
        uint256 totalInterest = 0;
        for(uint256 i= 0; i<accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            totalInterest += interest;
        }
        return totalInterest;
    }
}