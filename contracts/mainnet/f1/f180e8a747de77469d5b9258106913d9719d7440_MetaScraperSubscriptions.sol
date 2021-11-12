/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract MetaScraperSubscriptions{
    
    mapping(uint256 => uint256) public subscriptionPrices;
    mapping(address => uint256) public addressSubscriptionDate;
    mapping(address => uint256) public addressSubscriptionDays;

    address public owner1;
    address public owner2;

    event SubscriptionSet(address indexed user, uint256 startDate, uint256 subscriptionDays);

    constructor(uint256 weeklyPrice, uint256 monthlyPrice){
        subscriptionPrices[7] = weeklyPrice;
        subscriptionPrices[30] = monthlyPrice;
        owner1=msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==owner1 || msg.sender==owner2,"ONLY OWNER");  
        _;
    }

    function buySubscription(uint256 subscriptionDays,uint256 startDate) external payable{

        require(subscriptionPrices[subscriptionDays] > 0, "INEXISTENT SUBSCRIPTION");
        require(subscriptionPrices[subscriptionDays] == msg.value, "VALUE ERROR"); 
        require(startDate >= (block.timestamp - 1 hours), "INVALID START DATE");
        require(addressSubscriptionDate[msg.sender] < block.timestamp,"ALREADY SUBSCRIBED");        

        if(isSubscribedOnDate(msg.sender, startDate)){
            addressSubscriptionDays[msg.sender] = addressSubscriptionDays[msg.sender] + subscriptionDays;   
        }
        else{
            require((addressSubscriptionDate[msg.sender] + (addressSubscriptionDays[msg.sender] * 1 days)) < block.timestamp,"INVALID START DATE: SUBSCRIPTION IN PROGRESS");
            addressSubscriptionDate[msg.sender] = startDate;
            addressSubscriptionDays[msg.sender] = subscriptionDays;            
        } 

        emit SubscriptionSet(msg.sender,addressSubscriptionDate[msg.sender],subscriptionDays);        

    }

    function moveSubscription(uint256 startDate) external{
        require(startDate >= (block.timestamp - 1 hours), "MOVE FORBIDDEN:0");
        require(addressSubscriptionDate[msg.sender] > block.timestamp, "MOVE FORBIDDEN:1");        
        addressSubscriptionDate[msg.sender] = startDate; 
        emit SubscriptionSet(msg.sender,startDate,addressSubscriptionDays[msg.sender]);        
    }

    function isSubscribedOnDate(address subscriber, uint256 checkDate) public view returns(bool){        
        uint256 subscriptionDate = addressSubscriptionDate[subscriber];
        uint256 subscriptionDays = addressSubscriptionDays[subscriber];
        return (subscriptionDays > 0 && (checkDate >= subscriptionDate) && (checkDate <= (subscriptionDate + subscriptionDays * 1 days)));
    }

    function setSubscriptionPrice(uint256 subscriptionDays,uint256 price) external onlyOwner{        
        subscriptionPrices[subscriptionDays]=price;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }    

    function changeOwner1(address newOwner) external onlyOwner{
        owner1 = newOwner;
    }
    
    function changeOwner2(address newOwner) external onlyOwner{
        owner2 = newOwner;
    }
    
    function setSubscription(address user,uint256 startDate,uint256 subscriptionDays) external onlyOwner{
        addressSubscriptionDate[user] = startDate;
        addressSubscriptionDays[user] = subscriptionDays;
        emit SubscriptionSet(user,startDate,subscriptionDays);        
    }

}