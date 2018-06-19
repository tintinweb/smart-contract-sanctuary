pragma solidity ^0.4.20;

contract olty_6 {

event test_value(uint256 indexed value1);

address public owner;

// variables to store who needs to get what %
address public charity;
address public dividend;
address public maintain;
address public fuel;
address public winner;

// each ticket is 0.002 ether
uint constant uprice = 0.002 ether;

mapping (address => uint) public ownershipDistribute;
mapping (address => uint) public tickets;


// constructor function
function olty_6() {
    owner = msg.sender;
    
    charity = 0x889cbf08666fa94B2E74Dc6645059A60E25f9079;
    dividend = 0xD942E1F5f0fACD4540896843087E1e937A399828;
    maintain = 0x0e0146235236FC9E3f700991193E189f63eC4c32;
    fuel = 0x7aC1BC1E05Fc374e287Df5537fd03e5ef40b7333;
    winner = 0x6b730f4D92e236D0eC22b2baFf26873F297d7e67;
    
    ownershipDistribute[charity] = 5;
    ownershipDistribute[dividend] =10;
    ownershipDistribute[maintain] = 15;
    ownershipDistribute[fuel] = 5;
    ownershipDistribute[winner] = 65;    
}


function() payable {
    buyTickets(1);
}

function buyTickets(uint no_tickets) payable {
    tickets[msg.sender] += no_tickets;
}

function distribute(uint winner_select, uint winning_no, address win, uint promo)
     returns(bool success) {
         
    uint bal = this.balance;
    
    if (promo != 1) {
    if (msg.sender == owner) {
    charity.transfer(bal * ownershipDistribute[charity] / 100);
    fuel.transfer(bal * ownershipDistribute[fuel] / 100);    
    dividend.transfer(bal * ownershipDistribute[dividend] / 100);
    maintain.transfer(bal * ownershipDistribute[maintain] / 100);
    if (winner_select == 1) {
        winner.transfer(bal * ownershipDistribute[winner] / 100);
    } else if (winner_select == 2) {
        winner.transfer(bal * ownershipDistribute[winner] / 100);
    } else {
        // do nothing
        test_value(999);
    }
        } else {
    throw;
    } // else statement
    return true;
    }   
    
    if (promo == 1) {
    if (msg.sender == owner) {
    charity.transfer(bal * ownershipDistribute[charity] / 100);
    fuel.transfer(bal * ownershipDistribute[fuel] / 100);    
    dividend.transfer(bal * ownershipDistribute[dividend] / 100);

    if (winner_select == 1) {
        winner.transfer(bal * 80 / 100);
    } else if (winner_select == 2) {
        winner.transfer(bal * 80 / 100);
    } else {
        // do nothing
        test_value(999);
    }
        } else {
    throw;
    } // else statement
    return true;
    }       
    
}  // function distribute

}  // contract olty_6