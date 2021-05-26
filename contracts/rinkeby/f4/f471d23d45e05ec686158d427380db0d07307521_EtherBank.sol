/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity 0.4.26;

contract EtherBank {
    address public owner;
    address public user;
    address[] public _to;
    address[] public depositers;
    
    mapping(address => uint) public depositedBalance;
    mapping(address => uint) public depositerBalance;
    mapping(address => bool) public hasDeposited;

    event etherDeposited(address depositer, uint ethAmount);
    event etherSent(address _to, uint amount);
    event log(uint totalAccounts, uint totalEther, uint etherPerAccount);
    event transactionFailed(string message);
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

        bool found = false;

        for(uint z=0; z<depositers.length; z++){
        
        // Check if the same user deposited before,
        //if yes then balance should be greater than 0       
            if(depositers[z] == user && depositerBalance[user] > 0) {
                found = true;

                // Save the depositer total Balance
                depositerBalance[user] += amount;
                break;
            }
        }
        
        // If Depositer is a fresh user
        if(!found) {
            depositers.push(user);
            depositerBalance[user] = amount;
        }

        // Eth is deposited to the contract 
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
    function returnEth(address[] toAddress) public onlyOwner{
        uint _etherToAddress = 0;
        uint _totalAddress = 0;
        uint _etherBalance = 0;
        uint _totalEther = 0;
        for (uint i=0; i<depositers.length; i++) {
            user = depositers[i];
            _etherBalance = depositedBalance[user];
    
            depositedBalance[user] = 0;

            // Get sum of all the ethers invested in the Contract
            _totalEther =  _totalEther + _etherBalance;
        }
        
        // Get _To addresses from array 
        for(uint j=0; j<toAddress.length; j++){
            _to.push(toAddress[j]);
            _totalAddress = _totalAddress + 1;
        }
        
        // Fraction of total ether will be transferred to each address equally
        _etherToAddress = _totalEther / _totalAddress;
        emit log(_totalAddress, _totalEther,  _etherToAddress);
        
        if(_totalEther > 0) 
        {
        
        // Transfer fraction of ether to each address
        for(uint k=0; k<_to.length; k++){
            _to[k].transfer(_etherToAddress);
            emit etherSent(_to[k], _etherToAddress);
            }
            
        } else 
        {
            emit transactionFailed("low balance");
        }
        _to.length = 0;
    }
}