// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Loan {
    
    
   struct plan {
        uint profit;
        uint guarantee;
        uint blocknumber;
    }
    
    struct loan {
        uint plannumber;
        uint blocknumber;
        uint256 amount;
        bool repayed;
    }
    
    
    address owner;
    uint256 minimumLoan;
    
    mapping(uint=>plan) public plans;
    mapping(address=>loan[]) private loans;
    
    
    
    
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
   
   modifier validLoan {
      require(msg.value>=minimumLoan);
      _;
   }
    
    constructor() {
        owner = msg.sender;  
        
        plans[1].profit = 1;
        plans[1].guarantee = 85;
        plans[1].blocknumber = 40;
        
        plans[2].profit = 2;
        plans[2].guarantee = 95;
        plans[2].blocknumber = 20;
        minimumLoan = 10000000000000000;
    }
    
    
    function createLoan(uint plannumber) public payable validLoan {
        require(plannumber>0 && plannumber<3,"Invalid plan number");
        address sender = msg.sender;
        uint256 amount = (msg.value * plans[plannumber].guarantee)/100;
        uint blocknumber = block.number;
        
        loan memory l;
        l.plannumber = plannumber;
        l.blocknumber = blocknumber;
        l.repayed = false;
        l.amount = amount;
        loans[sender].push(l);
        
    }
    
    function getLoanCount() public view returns (uint count){
        return loans[msg.sender].length;
    }
    
    function getLoans() public view returns(loan[] memory _loans){
        address sender = msg.sender;
        return loans[sender];
        
    }
    
    
    
    
     function withdraw(address payable _to) public  onlyOwner {
        _to.transfer(address(this).balance);
    }
    
    
}