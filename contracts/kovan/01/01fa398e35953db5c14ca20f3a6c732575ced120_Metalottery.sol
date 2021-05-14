// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./LinkTokenInterface.sol";
import "./RandomNumberConsumer.sol";

contract Metalottery is RandomNumberConsumer {
    
    address public team;
    uint public prize;
    uint public gameDuration;
    uint public ticketPrice;
    uint public poolPart;
    uint public startTime;
    address[] public ticketOwners;
    bool public isPreLaunch;
    
    event newGame(uint _duration, uint _ticketPrice, uint poolPart, uint _time);
    event ticketsHaveBeenBought(address indexed _from, uint indexed _numberOfTickets, uint _value, uint _currentPrize, uint _time);
    event priceWasChanged(uint indexed _newPrice, uint _time);
    event gameDurationWasChanged(uint _newGameDuration, uint _time);
    event poolPartWasIncreased(uint _newPoolPart, uint _time);
    event winnerWasAwarded(address indexed _winner, uint _prize, uint _time);
    
    constructor() public {
        ticketPrice = 0.02 ether;
        gameDuration = 7 days;
        team = msg.sender;
	    poolPart = 9300;
	    isPreLaunch = true;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only the team can execute this");
        _;
    }
    
    function launchParty() public onlyOwner {
        require(isPreLaunch, "Party's over");
        startTime = block.timestamp;
        delete isPreLaunch;
        emit newGame(gameDuration, ticketPrice, poolPart, startTime);
    }
    
    function getTicket() external payable {
        require(block.timestamp < startTime + gameDuration && block.timestamp > startTime, "Ticket sales are closed");
	    require(msg.value > 0, "Cannot buy 0 ticket");
	    require(msg.value % ticketPrice == 0, "Cannot buy a fraction of a ticket");
        uint ticketsBought = msg.value / ticketPrice;
        prize += poolPart*msg.value/10000;
        for (uint i=0; i < ticketsBought; i++) {
            ticketOwners.push(msg.sender);
        }
        emit ticketsHaveBeenBought(msg.sender, ticketsBought, msg.value, prize, block.timestamp);
    }
    
    
    function changeTicketPrice(uint _newPrice) public onlyOwner {
        require(ticketOwners.length == 0, "In order not to disadvantage players, the price cannot be changed if the current game already has players");
        require(_newPrice > 0);
    	ticketPrice = _newPrice;
    	emit priceWasChanged(_newPrice, block.timestamp);
    	
  }
    
    function changeGameDuration(uint _newGameDuration) public onlyOwner {
        require(ticketOwners.length == 0, "In order not to disadvantage players, the duration cannot be changed if the current game already has players");
    	gameDuration = _newGameDuration;
    	emit gameDurationWasChanged(_newGameDuration, block.timestamp);
  }

    
    function awardWinner(bool _rewardTeam, uint _delay) public onlyOwner {
        require(block.timestamp > startTime + gameDuration, "Ticket sales are still open.");
        uint ticketsSold = ticketOwners.length;
        if (ticketsSold != 0 ) {
            uint winnerID = block.timestamp % ticketsSold;
            payable(ticketOwners[winnerID]).transfer(prize);
            emit winnerWasAwarded(ticketOwners[winnerID], prize, block.timestamp);
            if (_rewardTeam) {
                uint teamContribution = address(this).balance;
                payable(team).transfer(teamContribution);
            }
	        delete prize;
            delete ticketOwners;
	        delete winnerID;   
        }
        delete ticketsSold;
        //The possible delay will be used to make changes while there is no player
        startTime = block.timestamp + _delay;
        emit newGame(gameDuration, ticketPrice, poolPart, startTime);
    }
    
    function changePoolPart(uint _newPoolPart) public onlyOwner {
        require(ticketOwners.length == 0);
	    require(_newPoolPart > poolPart);
	    if (_newPoolPart < 9900) {
		    require(_newPoolPart % 25 == 0);
	    } 
	    poolPart = _newPoolPart;
	    emit poolPartWasIncreased(poolPart, block.timestamp);
    }

    function ticketsSold() public view returns (uint) {
       return ticketOwners.length;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function changeTeamAddress(address _newTeamAddress) public onlyOwner {
	    team = _newTeamAddress;
    }	
    
    
     // withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(0xa36085F69e2889c224210F603D836748e7dC0088);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}