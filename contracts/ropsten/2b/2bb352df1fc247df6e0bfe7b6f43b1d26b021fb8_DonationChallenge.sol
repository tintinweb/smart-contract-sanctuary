/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.8.7;

contract DonationChallenge {
    
    struct Donation {
        uint256 timestamp;
        uint256 etherAmount;
    }
    Donation[] public donations;
    address public owner;
    
    uint[] public array;
    
    constructor () {
        owner = msg.sender;
    }
    
    function donate(uint amount) public {
        
        Donation memory donation = DonationChallenge.Donation(block.timestamp, amount);
        donation.timestamp = block.timestamp;
        donation.etherAmount = amount;

        donations.push(donation);
    }
    
    function add(uint element) public {
        array.push(element);
    }
}