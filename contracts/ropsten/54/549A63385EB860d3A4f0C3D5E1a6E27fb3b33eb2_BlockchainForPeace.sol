pragma solidity ^0.4.24;

contract BlockchainForPeace {
    

    // to see the total raised 
    uint public raised;
    address public charity; 
    
    //struct for the donation 
    struct Donation {
        address donor; 
        string message; 
        uint value; 
    }
    
    Donation[] public donations; 
    
    //mapping an address to the donation struct 
    //mapping (address => donation) public donors;
    event Donate(address indexed from, uint amount, string message);
    
    //constructor to initiate the address of the charity being donated to
    constructor () public {
        charity = msg.sender;
    }
   
    // payable function which auto transfers money to charity address, collects the value and increases the total value counter. Also allows for anonoymous donations
     function fallback() payable public {
        raised += msg.value;
        charity.transfer(msg.value);
     }
    // optional message to be sent with donation, peace message.
    function messageForPeace(string _message) payable public {
        require(msg.value > 0);
        donations.push(Donation(msg.sender, _message, msg.value));
        charity.transfer(msg.value);
        raised += msg.value;
        emit Donate(msg.sender, msg.value, _message);
    }

    function getDonation(uint _index) public view returns (address, string, uint) {
        Donation memory don = donations[_index];
        return (don.donor, don.message, don.value);
    }
    
    function getDonationLength() public view returns (uint){
        return donations.length;
    }

     function getRaised() public view returns (uint){
        return raised;
    }
}