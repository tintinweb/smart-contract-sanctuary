/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity 0.4.26;

contract EtherBank {
    address public owner;
    address public user;
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
            // Eth is deposited to the contract 
            depositedBalance[user] += amount;
            hasDeposited[user] = true; 
            emit etherDeposited(user, amount);
    }
    
/*
    1. OnlyOwner can call returnEth() in order to return ethers to all the addresses
    2. returnEth() should be automated and can only be called from inside the contract
    3. If the etherBank Contract is deployed on rinkeby at Block : 0 
       Then 
       after 10 blocks are mined  ( 0 + 10 ) on the rinkeby testnet 
          => An automated scheduler should call the returnEth() function 
                from inside the deployed EtherBank smartContract
          => To return ethers deposited by the depositers
*/
    
    function returnEth() public {
        
        for (uint i=0; i<depositers.length; i++) {
            user = depositers[i];
            uint refundedAmount = depositedBalance[user];
            
            user.transfer(refundedAmount);
            depositedBalance[user] = 0;
            hasDeposited[user] = false;
            emit etherReturned(user, refundedAmount);
        }
    }                
}