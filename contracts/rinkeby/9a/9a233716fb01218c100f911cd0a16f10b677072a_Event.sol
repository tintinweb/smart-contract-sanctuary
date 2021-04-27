/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^ 0.5.0;

contract Event {

struct Registration {

    uint8 noOfTickets;
    uint amount;
    string email;
}
    address payable public owner;
    uint public ticketsSold;
    uint public totalTickets;
    uint public price;

    mapping (address => Registration) public registrations;

    event Deposit(address _from, uint _amount);
    event Refund(address _to, uint _amount);

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    modifier soldout() {
        require (ticketsSold < totalTickets);
        _;
    }

    
    constructor (uint8 _total,
                 uint _price)
                 public {
    owner = msg.sender;
    totalTickets = _total;
    price = _price;
    ticketsSold = 0;
    }
    
    function buyTickets (string calldata _email,
                         uint8 _amount)
                         soldout()
                         external
                         payable {
    
       uint totalAmount = _amount * price;
       
       require(ticketsSold + _amount <= totalTickets); 
    
      if(msg.value < totalAmount)
            revert();
    
       if(registrations[msg.sender].amount > 0)
       {
            registrations[msg.sender].amount = registrations[msg.sender].amount + totalAmount;
            registrations[msg.sender].noOfTickets = registrations[msg.sender].noOfTickets + _amount;
       }
       else {
            registrations[msg.sender].amount = totalAmount;
            registrations[msg.sender].noOfTickets = _amount;
            registrations[msg.sender].email = _email;
       }
    
       ticketsSold = ticketsSold + _amount;
    
       if(msg.value > totalAmount)
       {
            uint refund = msg.value - totalAmount;
        
            msg.sender.transfer(refund);
       }
    
       emit Deposit(msg.sender, msg.value);
}
    
    function refundAmount(address payable _customer)
                          external
                          payable {
        if(registrations[_customer].amount > 0){
            if(address(this).balance >= registrations[_customer].amount) {
    
                ticketsSold = ticketsSold - registrations[_customer].noOfTickets;
                registrations[_customer].noOfTickets = 0;
                registrations[_customer].email = " ";
                uint refundCustAmount = registrations[_customer].amount;
                registrations[_customer].amount = 0;
                
                _customer.transfer(refundCustAmount);
                
                emit Refund(_customer, refundCustAmount);
        }
    
    }

    }
    
    function withdraw()
                     onlyOwner()
                     external
                     payable
                     {
        
        owner.transfer(address(this).balance);
                         
    }
    
    function balanceOfRegistrant (address _buyer)
                                  external
                                  view
                                  returns 
                                 (uint balance){
    return registrations[_buyer].amount;
   }
   
   function kill()
            external
            onlyOwner() {
                
        if(address(this).balance > 0)
            owner.transfer(address(this).balance);
            
        selfdestruct(owner);            
    }
    
    function() 
            external{
        revert();
    }
    
}