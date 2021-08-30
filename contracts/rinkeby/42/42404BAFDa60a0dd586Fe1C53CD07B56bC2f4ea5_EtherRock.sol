/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

/**
 *Submitted for verification at Etherscan.io on 2017-12-26
*/

pragma solidity ^0.4.2;

// This is a revised version of the original EtherRock contract 0x37504ae0282f5f334ed29b4548646f887977b7cc with all the rock owners and rock properties the same at the time this new contract is being deployed.
// The original contract at 0x37504ae0282f5f334ed29b4548646f887977b7cc had a simple mistake in the buyRock() function. The line:
// require(rocks[rockNumber].currentlyForSale = true);
// Had to have double equals, as follows:
// require(rocks[rockNumber].currentlyForSale == true);
// Therefore in the original contract, anyone could buy anyone elses rock for the same price the owner purchased it for (regardless of whether the owner chose to sell it or not)

contract EtherRock {
    
    struct Rock {
        address owner;
        bool currentlyForSale;
        uint price;
        uint timesSold;
    }
    
    mapping (uint => Rock) public rocks;
    
    mapping (address => uint[]) public rockOwners;

    uint public latestNewRockForSale;
    
    address owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function EtherRock() {
        
        latestNewRockForSale = 99;
        
        rocks[99].owner = 0x789c778b340f17eb046a5a8633e362468aceeff6;
        rocks[99].currentlyForSale = true;
        rocks[99].price = 10000000000000000;
        rocks[99].timesSold = 2;
        rockOwners[0x789c778b340f17eb046a5a8633e362468aceeff6].push(0);
        
        owner = msg.sender;
    }
    
    function getRockInfo (uint rockNumber) returns (address, bool, uint, uint) {
        return (rocks[rockNumber].owner, rocks[rockNumber].currentlyForSale, rocks[rockNumber].price, rocks[rockNumber].timesSold);
    }
    
    function rockOwningHistory (address _address) returns (uint[]) {
        return rockOwners[_address];
    }
    
    function buyRock (uint rockNumber) payable {
        require(rocks[rockNumber].currentlyForSale == true);
        require(msg.value == rocks[rockNumber].price);
        rocks[rockNumber].currentlyForSale = false;
        rocks[rockNumber].timesSold++;
        if (rockNumber != latestNewRockForSale) {
            rocks[rockNumber].owner.transfer(rocks[rockNumber].price);
        }
        rocks[rockNumber].owner = msg.sender;
        rockOwners[msg.sender].push(rockNumber);
        if (rockNumber == latestNewRockForSale) {
            if (rockNumber != 99) {
                latestNewRockForSale++;
                rocks[latestNewRockForSale].price = 10**15 + (latestNewRockForSale**2 * 10**15);
                rocks[latestNewRockForSale].currentlyForSale = true;
            }
        }
    }
    
    function sellRock (uint rockNumber, uint price) {
        require(msg.sender == rocks[rockNumber].owner);
        require(price > 0);
        rocks[rockNumber].price = price;
        rocks[rockNumber].currentlyForSale = true;
    }
    
    function dontSellRock (uint rockNumber) {
        require(msg.sender == rocks[rockNumber].owner);
        rocks[rockNumber].currentlyForSale = false;
    }
    
    function giftRock (uint rockNumber, address receiver) {
        require(msg.sender == rocks[rockNumber].owner);
        rocks[rockNumber].owner = receiver;
        rockOwners[receiver].push(rockNumber);
    }
    
    function() payable {
        
    }
    
    function withdraw() onlyOwner {
        owner.transfer(this.balance);
    }
    
}