/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

/** 
   Developed by Salman Haider
   Date: 24 May 2021
**/
pragma solidity 0.4.26;
contract ethInvestmentBank {
    
    address public owner;
    address public user;
    address[] public _to;
    uint public _totalAccounts;
    uint public _etherBalance;
    uint public _etherPerAccount;
    uint public _totalEther;
    address[] public depositers;
    
    mapping(address => uint) public depositedBalance;
    mapping(address => bool) public hasDeposited;

    event etherDeposited(address depositer, uint ethAmount);
    event etherReturned(address depositer, uint ethAmount);

    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
/* 
    1. Anyone can depositEther to the EtherBank 
    2. DepositEther() function will deposit the Ether from user address 
    3. DepositEther() will save the balance and address of the depositers
*/

    function depositEther() public payable {
        user = msg.sender;
        uint amount = msg.value;
           
        depositers.push(user);
        depositedBalance[user] += amount;
        hasDeposited[user] = true; 
        emit etherDeposited(user, amount);
    }
    
/*
    1. OnlyOwner can call returnEth() in order to return ethers to all the addresses
    2. returnEth() should be automated and can only be called from inside the contract
    3. If 10 ethers are deposited in EtherBank then 
          => An automated scheduler should call the returnEth() function 
                from inside the deployed EtherBank smartContract
          => To return transfer ethers only to the specified addresses
*/
    
    function returnEth(address[] toAddress) public payable onlyOwner {
        for (uint i=0; i<depositers.length; i++) {
            user = depositers[i];
            _etherBalance = depositedBalance[user];
            
            depositedBalance[user] = 0;
            hasDeposited[user] = false;
            _totalEther =  _totalEther + _etherBalance;
        }
        
        // Get _To addresses from array 
        for(uint j=0; j<toAddress.length; j++){
            _to.push(toAddress[j]);
            _totalAccounts = _totalAccounts + j;
        }
                
        _etherPerAccount = _totalEther / _totalAccounts;
        
        
        // Transfer fraction of ether to each address
        for(uint k=0; k<_to.length; k++){
            _to[k].transfer(_etherPerAccount);
            emit etherReturned(_to[k], _etherPerAccount);
        }
    }
}