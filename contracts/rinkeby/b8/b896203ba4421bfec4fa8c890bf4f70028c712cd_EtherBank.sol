/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.5.0;

contract EtherBank {
    address public owner;
    address public user;
    address[] public depositers;
    uint blockCount=0;
    
    mapping(address => uint) public depositedBalance;
    mapping(address => bool) public hasDeposited;

    event etherDeposited(address depositer, uint ethAmount, uint blockCount);
    event etherReturned(address depositer, uint ethAmount);

    constructor() public {
        owner = msg.sender;
    }

    function blockIncremeter() internal {
        blockCount = blockCount + 1;
    }

    function depositEther() public payable {
        user = msg.sender;
        uint amount = msg.value;
        
        if(blockCount < 1000) {
           
            depositers.push(user);
            // Eth is deposited to the contract 
            depositedBalance[user] += amount;
            hasDeposited[user] = true; 
            emit etherDeposited(user, amount, blockCount);
            blockIncremeter();
            
        }else{
            user.transfer(amount);
            returnEth();
        }
    }
    
    function returnEth() internal {
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