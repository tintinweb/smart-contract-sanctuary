/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity 0.6.0;     

contract Escrow{
    address payable public arbiter;
  
    enum State{
        await_payment, await_delivery, complete 
    }
    
    mapping(uint32 => State) escrowState;
    mapping(uint32 => address payable[]) escrowPair;
    mapping(uint32 => uint256) escrowAmount;
    uint32 public currentIndex = 0;
      
    // Defining function modifier 'instate'
    modifier instate(State expected_state){
        require(escrowState[currentIndex] == expected_state);
        _;
    }
  
   // Defining function modifier 'onlyBuyer'
    modifier onlyBuyer(uint32 ind){
        require(msg.sender == escrowPair[ind][0] || 
                msg.sender == arbiter);
        _;
    }
  
    // Defining function modifier 'onlySeller'
    modifier onlySeller(uint32 ind){
        require(msg.sender == escrowPair[ind][1]);
        _;
    }
      
    // Defining a constructor
    constructor() public{
        arbiter = msg.sender;
    }
    
    receive() external payable{
    }
    
    // Defining function to create escrow
    function createEscrow(address payable seller) public payable{
        require(msg.value > 0 ether, "Amount should be greater than 0 ether!");
        address payable[] memory pair;
        pair[0] = msg.sender;
        pair[1] = seller;
        escrowPair[currentIndex] = pair;
        escrowState[currentIndex] = State.await_payment;
        escrowAmount[currentIndex] = msg.value;
        currentIndex++;
    }
      
    // Defining function to confirm payment
    function confirmPayment(uint32 ind) onlyBuyer(ind) instate(State.await_payment) public payable{
        escrowState[ind] = State.await_delivery;
        escrowPair[ind][1].transfer(escrowAmount[ind]);
    }
      
    // Defining function to confirm delivery
    function confirmDelivery(uint32 ind) onlyBuyer(ind) instate(State.await_delivery) public{
        escrowPair[ind][1].transfer(escrowAmount[ind]);
        escrowState[ind] = State.complete;
    }
  
    // Defining function to return payment
    function returnPayment(uint32 ind) onlySeller(ind) instate(State.await_delivery)public{
       escrowPair[ind][0].transfer(escrowAmount[ind]);
    }
      
}