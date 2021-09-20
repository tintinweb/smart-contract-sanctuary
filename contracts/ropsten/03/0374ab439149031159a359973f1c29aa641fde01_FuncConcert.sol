/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0; 

contract FuncConcert {
    uint constant price = .1 ether;
    address public owner;
    uint public tickets;
    mapping (address => uint ) public purchasers;
    
    constructor (uint t) public payable {
        owner = msg.sender;
        tickets = t;
    } 

    function buyTickets(uint reqTkts) public payable {  
        
        require (msg.value == (reqTkts * price) && reqTkts <= tickets);
        
        purchasers[msg.sender] += reqTkts;
        tickets-= reqTkts;
        if (tickets ==0 ) {
            require(msg.sender == owner);
            selfdestruct(msg.sender);
        }
    }
    
    function buyTickets(uint reqTkts,uint freeTickets) public payable { 
        require (msg.value == (reqTkts * price) && (reqTkts+freeTickets) <= tickets);
        
        purchasers[msg.sender] += (freeTickets+reqTkts);
        tickets-= (freeTickets+reqTkts);
        
        if (tickets ==0 ) {
            require(msg.sender == owner);
            selfdestruct(msg.sender);
        }
    }
    
    function website() public pure returns (string memory){ 
        return "www.FuncConcert.com"; 
    }
   
   
    // this is how we add a modifier to the function 
    // there can be zero of more number of modifiers
    function kill() public onlyCreator {  
        selfdestruct(msg.sender);
    }

    modifier onlyCreator() {
        // if a condition is not met then throw an exception 
         require (msg.sender == owner); 
        // or else just continue executing the function
        _;
    }
}