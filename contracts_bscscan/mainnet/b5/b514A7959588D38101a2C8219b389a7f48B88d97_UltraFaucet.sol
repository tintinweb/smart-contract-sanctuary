/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


abstract contract Ownable {
    address private _owner;event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);constructor() {_setOwner(msg.sender);}function owner() public view virtual returns (address) {return _owner;}modifier onlyOwner() {require(owner() == msg.sender, "Ownable: caller is not the owner");_;}function renounceOwnership() public virtual onlyOwner {_setOwner(address(0));}function transferOwnership(address newOwner) public virtual onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address");_setOwner(newOwner);}function _setOwner(address newOwner) private {address oldOwner = _owner;_owner = newOwner;emit OwnershipTransferred(oldOwner, newOwner);}
}

interface IYieldManager {
    function getCurrentYieldPercentage() external pure returns(uint);
    function withdrawYield(uint256 _amount, address _recipient) external payable;
    function transferOwnership(address newOwner) external;
    function withdrawDeposit(uint256 _amount, address _recipient) external payable;
}

contract UltraFaucet is Ownable
{
    event NewDeposit(uint date,address sender,uint amount);
    event NewWithdrawal(uint date,address withdrawer,uint amount,bool taxAccepted);
    event SpotTaken(uint currentSpots);
    event SpotsOpened(uint date,uint newSpots,uint availableSpots);
    event NewYieldPayment(uint date, address withdrawer, uint amount);

    mapping (address => Holder) public Account;

    IYieldManager private _yieldContract;
    address private _yieldContractAddress;
    
    uint public SpotsLeft = 50;
    
    struct DepositLog {uint256 transactionTime;uint256 lastCollection;uint256 amount;}
    struct WithdrawalLog {uint256 transactionTime;uint256 amount;uint256 tax;}
    struct Holder {uint256 balance;DepositLog[] deposits;WithdrawalLog[] withdrawals;}
    
    constructor() {}
    receive() external payable{}
    
    function Deposit() public payable {
        Holder storage account = Account[msg.sender];
        require(SpotsLeft > 0, "There are no spots left.");
        if(account.deposits.length == 0)
        {
            SpotsLeft--;
            emit SpotTaken(SpotsLeft);
        }
            
        DepositLog memory log;
        log.transactionTime = block.timestamp;
        log.amount = msg.value;
        log.lastCollection = block.timestamp;
        account.deposits.push(log);
        payable(_yieldContractAddress).transfer(msg.value);
        account.balance += msg.value;
        emit NewDeposit(block.timestamp, msg.sender, msg.value);
    }
    
    function CollectYield() public {
        Holder storage account = Account[msg.sender];
        uint256 yieldToPay = 0;
        for(uint i = 0; i < account.deposits.length; i++) {
            DepositLog memory dep = account.deposits[i];
            if(dep.lastCollection + 1 days <= block.timestamp)
            {
                uint daysSinceCollection = (block.timestamp - dep.lastCollection) / 60 / 60 / 24;
                dep.lastCollection = block.timestamp;
                yieldToPay += ((account.deposits[i].amount / 100) * _yieldContract.getCurrentYieldPercentage())*daysSinceCollection;    
            }
        }
        require(yieldToPay > 0, "No deposits fulfill requirements for yield payments.");
        _yieldContract.withdrawYield(yieldToPay, msg.sender);
        emit NewYieldPayment(block.timestamp, msg.sender, yieldToPay);
    }

    function Withdraw(uint256 _amount, bool _acceptEarlyWithdrawalTax)
    public
    {
        Holder storage account = Account[msg.sender];
        require(account.balance >= _amount, "You're trying to withdraw more than your deposited balance.");
        uint256 balanceAvailableForWithdrawal = 0;
        uint256 withdrawalTax = 0;
        for(uint i = 0; i < account.deposits.length; i++) {
            DepositLog memory dep = account.deposits[i];
            uint256 missingAmount = _amount-balanceAvailableForWithdrawal;
            if((dep.transactionTime + 10 days <= block.timestamp || _acceptEarlyWithdrawalTax) && missingAmount > 0)
            {
                // If it hasn't been 10 days since the deposit was made, and we haven't found enough eligible funds - apply tax.
                if(dep.transactionTime + 10 days > block.timestamp)
                {
                    if(dep.amount >= missingAmount) // If the amount available from this deposit is larger than missing amount, tax only the part missing.
                        withdrawalTax += (missingAmount / 100) * 10;
                    else if(dep.amount < missingAmount) // If it is lower, tax the whole amount and move on to next.
                        withdrawalTax += (dep.amount / 100) * 10;
                }
                    
                balanceAvailableForWithdrawal += dep.amount > missingAmount ? missingAmount : dep.amount;
            }
        }
        require(balanceAvailableForWithdrawal >= _amount, "Not enough withdrawable balance.");
        uint256 newBalance = account.balance-_amount;
        account.balance = newBalance;
        WithdrawalLog memory log;
        log.transactionTime = block.timestamp;
        log.amount = _amount;
        log.tax = withdrawalTax;
        account.withdrawals.push(log);
        _yieldContract.withdrawDeposit(_amount-withdrawalTax, msg.sender);
        emit NewWithdrawal(block.timestamp, msg.sender, _amount,_acceptEarlyWithdrawalTax);
    }
    
    function getAmountAvailableForWithdrawal() public view returns(uint)
    {
        Holder storage account = Account[msg.sender];
        uint256 balanceAvailableForWithdrawal = 0;
        for(uint i = 0; i < account.deposits.length; i++) {
            DepositLog memory dep = account.deposits[i];
            if(dep.transactionTime + 10 days <= block.timestamp)
            {
                if(dep.transactionTime + 10 days < block.timestamp)
                    balanceAvailableForWithdrawal += dep.amount;
            }
        }
        return balanceAvailableForWithdrawal;
    }
    
    function getDeposits() public view returns(DepositLog[] memory) 
    {
        Holder storage account = Account[msg.sender];
        return account.deposits;
    }
    
    function getWithdrawals() public view returns(WithdrawalLog[] memory) 
    {
        Holder storage account = Account[msg.sender];
        return account.withdrawals;
    }
    
    function getBalance() public view returns(uint256){
        Holder storage account = Account[msg.sender];
        return account.balance;
    }
    
    // Sets the address of the YieldManager
    function setYieldContract(address payable contractAddress) public onlyOwner {
        _yieldContract = IYieldManager(contractAddress);
        _yieldContractAddress = contractAddress;
    }
    
    // Called to add more open spots to the contract to allow for growth.
    function openMoreSpots(uint _spotsToAdd) public onlyOwner {
        SpotsLeft += _spotsToAdd;
        emit SpotsOpened(block.timestamp, _spotsToAdd, SpotsLeft);
    }

    fallback() 
    external
    payable
    {
    }
}