/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract OneAct {
  uint public eventId = 0;
    mapping (uint => FundRaiseEvent) public fundRaises; // will also create getEvents automatically by solidity 

    struct FundRaiseEvent{
        string title;
        string description; 
        uint goal; 
        uint current; 
        uint id; 
        bool status; 
        address creator; 
    }

    
    struct HomeCard{
        string title; 
        string des; 
        uint id;
    }
    constructor() {
        uint idForNewEvent = eventId; 
        address eventCreator = msg.sender; 
        FundRaiseEvent memory newFundRaise = FundRaiseEvent("Test Title", "Test Description", 500, 0, idForNewEvent, true, eventCreator);
        fundRaises[idForNewEvent] = newFundRaise; 
        eventId += 1; 
        emit EventCreated(idForNewEvent);
    }

    event EventCreated(uint id); 
    event Donated(uint amount); 
    event Withdraw(uint id); 

    function createEvent(string memory title, string memory description, uint goal) public {

        uint idForNewEvent = eventId; 
        address eventCreator = msg.sender; 
        FundRaiseEvent memory newFundRaise = FundRaiseEvent(title, description, goal, 0, idForNewEvent, true, eventCreator);
        fundRaises[idForNewEvent] = newFundRaise; 
        eventId += 1; 
        emit EventCreated(idForNewEvent);
    }

    function donate(uint idForEvent) public payable{
        FundRaiseEvent storage fundRaise = fundRaises[idForEvent]; 
        require(fundRaise.creator == msg.sender, "You are the Creator");
        uint amount = msg.value; 
        fundRaise.current = fundRaise.current + amount; 
        emit Donated(amount);
    }

    function withdraw(uint idForEvent) public {
        address payable accountWithDrawing = payable(msg.sender); 
        FundRaiseEvent storage fundRaise = fundRaises[idForEvent]; 
        require(accountWithDrawing == fundRaise.creator); //only if the address is creator address
        accountWithDrawing.transfer(fundRaise.current); 
        fundRaise.status = false; 
        emit Withdraw(idForEvent);
    }


    function getHomeData() public view returns(HomeCard[] memory){
        HomeCard[] memory cards = new HomeCard[](eventId); 
        for(uint i =0; i<eventId; i++){
            HomeCard memory homeCard = HomeCard(fundRaises[i].title, fundRaises[i].description, i); 
            cards[i] = homeCard;         
        }
        return cards; 
    }
}