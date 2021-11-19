/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract DonateContract {
  uint totalDonations = address(this).balance; // the amount of donations
  address payable owner; // contract creator's address
  
   mapping(address => uint) public contributors;
    address public admin = msg.sender;
    uint public totalContributors;
    uint public maxAcceptingContribution = 5000000000000000000;
    uint public goal = 100000000000;
    uint public amountRaised;

     function contribute() public payable{
       
        require(msg.value <= maxAcceptingContribution,"Contribution amount is too beyond donation limit ");
        
        if(contributors[msg.sender] == 0){
            totalContributors++;
        }
        
        contributors[msg.sender] += msg.value;
        amountRaised += msg.value;
    }
    
    function currentBalance()public view returns(uint){
        return address(this).balance;
    } 
    
    
    //should not be able to transfer more than bal 
    //transfer from - to
    
    function transfer(address payable recipient, uint256 amount) public payable{
        require(msg.sender == admin,"you are not the owner");
        recipient.transfer(amount);
        // require(msg.value < currentBalance);
        }
}