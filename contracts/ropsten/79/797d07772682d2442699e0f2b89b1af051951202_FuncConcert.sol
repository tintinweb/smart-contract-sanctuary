pragma solidity ^0.4.24;

contract FuncConcert {
    
    uint constant price = .1 ether;
    
    address public owner;
    uint public tickets;
    mapping (address => uint ) public purchasers;
    
    constructor (uint t) public payable {
        owner = msg.sender;
        tickets = t;
    }
    
    function () public payable {
        buyTickets(1);
    }
    
    function buyTickets(uint reqTkts) public payable {  
        
        require (msg.value == (reqTkts * price) && reqTkts <= tickets);
        
        purchasers[msg.sender] += reqTkts;
        tickets-= reqTkts;
        if (tickets ==0 ) {
            selfdestruct(owner);
        }
    }
    
    function buyTickets(uint reqTkts,uint freeTickets) public payable { 
        require (msg.value == (reqTkts * price) && (reqTkts+freeTickets) <= tickets);
        
        purchasers[msg.sender] += (freeTickets+reqTkts);
        tickets-= (freeTickets+reqTkts);
        
        if (tickets ==0 ) {
            selfdestruct(owner);
        }
    }
    
    function website() public pure returns (string){ 
        return "www.FuncConcert.com"; 
    }
   
   
    // this is how we add a modifier to the function 
    // there can be zero of more number of modifiers
    function kill() public onlyCreator { 
    	selfdestruct(owner);
    }

    modifier onlyCreator() {
        // if a condition is not met then throw an exception 
         require (msg.sender == owner); 
        // or else just continue executing the function
        _;
    }
       


}