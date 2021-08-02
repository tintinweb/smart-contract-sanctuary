// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import 'YieldManager.sol';

contract UltraFaucet
{
    mapping (bytes32=>bool) admin;

    mapping (address => Holder) public Account;

    YieldManager private _yieldContract;
    
    uint public SpotsLeft = 100;
    
    struct DepositLog {uint256 transactionTime;uint256 lastCollection;uint256 amount;}
    
    struct Holder   
    {
        uint256 balance;
        DepositLog[] deposits;
    }
    
    receive() external payable{}
    
    function Deposit() public payable {
        Holder storage account = Account[msg.sender];
        require(msg.value >= MinSum, "The deposited amount is too low.");
        require(SpotsLeft > 0, "There are no spots left.");
        if(account.deposits.length == 0)
        {
            SpotsLeft--;
        }
        DepositLog memory log;
        log.transactionTime = block.timestamp;
        log.amount = msg.value;
        account.deposits.push(log);
        account.balance += msg.value;
        payable(_yieldContract).transfer(msg.value);
    }
    
    function CollectYield() public {
        Holder storage account = Account[msg.sender];
        uint256 yieldToPay = 0;
        require(account.deposits.length > 0, "You have not made any deposits.");
        for(uint i = 0; i < account.deposits.length; i++) {
            DepositLog memory dep = account.deposits[i];
            if(dep.transactionTime + 1 days <= block.timestamp && dep.lastCollection + 1 days <= block.timestamp)
            {
                dep.lastCollection = block.timestamp;
                yieldToPay += (account.deposits[i].amount / 100) * 7;    
            }
        }
        require(yieldToPay > 0, "No deposits fulfill requirements for yield payments.");
        _yieldContract.withdrawYield(yieldToPay);
        address payable receiver = payable(msg.sender);
        receiver.transfer(yieldToPay);    
    }

    function Withdraw(uint256 _amount)
    public
    {
        Holder memory account = Account[msg.sender];
        require(account.balance >= _amount, "You're trying to withdraw more than your deposited balance.");
        uint256 balanceAvailableForWithdrawal = 0;
        for(uint i = 0; i < account.deposits.length; i++) {
            DepositLog memory dep = account.deposits[i];
            if(dep.transactionTime + 10 days <= block.timestamp)
            {
                balanceAvailableForWithdrawal += account.deposits[i].amount;    
            }
        }
        require(balanceAvailableForWithdrawal <= _amount, "Not enough withdrawable balance.");
        _yieldContract.withdrawDeposit(_amount);
        account.balance-=balanceAvailableForWithdrawal;
        address payable receiver = payable(msg.sender);
        receiver.transfer(_amount);
    }
    
    function getDeposits() public view returns(DepositLog[] memory) 
    {
        Holder memory account = Account[msg.sender];
        return account.deposits;
    }
    
    function getBalance() public view returns(uint256){
        Holder memory account = Account[msg.sender];
        return account.balance;
    }

    constructor() {
        admin[keccak256(abi.encodePacked(msg.sender))] = true;
    }
    
    // Sets the address of the YieldManager
    function setYieldContract(address payable contractAddress) public payable isAdmin {
        _yieldContract = YieldManager(contractAddress);
    }
    
    // Called to add more open spots to the contract to allow for growth.
    function openMoreSpots(uint _spotsToAdd) public isAdmin {
        SpotsLeft += _spotsToAdd;
    }
    
    // Gets the current yield percentage from the YieldManager.
    function getYieldPercentage() public view returns(int) {
        return YieldManager(_yieldContract).getCurrentYieldPercentage();
    }

    fallback() 
    external
    payable
    {
        Deposit();
    }

    uint256 public MinSum = 10000000000000000 wei;    
    
    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }
}