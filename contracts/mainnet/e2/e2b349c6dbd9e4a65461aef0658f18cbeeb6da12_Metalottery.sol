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
    
    function launchParty() external onlyOwner {
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
    
    
    function changeTicketPrice(uint _newPrice) external onlyOwner {
        require(ticketOwners.length == 0, "In order not to disadvantage players, the price cannot be changed if the current game already has players");
    	ticketPrice = _newPrice;
    	emit priceWasChanged(_newPrice, block.timestamp);
    	
  }
    
    function changeGameDuration(uint _newGameDuration) external onlyOwner {
        require(ticketOwners.length == 0, "In order not to disadvantage players, the duration cannot be changed if the current game already has players");
    	gameDuration = _newGameDuration;
    	emit gameDurationWasChanged(_newGameDuration, block.timestamp);
  }

    
    function endOfGame(bool _rewardTeam, uint _delay) external onlyOwner {
        require(block.timestamp > startTime + gameDuration, "Ticket sales are still open.");
        uint ticketsSold = ticketOwners.length;
        if (ticketsSold != 0 ) {
            getRandomNumber(0);
            uint winnerID = randomResult % ticketsSold;
            payable(ticketOwners[winnerID]).transfer(prize);
            emit winnerWasAwarded(ticketOwners[winnerID], prize, block.timestamp);
            if (_rewardTeam) {
                payable(team).transfer(address(this).balance);
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
    
    function changePoolPart(uint _newPoolPart) external onlyOwner {
        require(ticketOwners.length == 0);
	    require(_newPoolPart <= 10000);
	    require(_newPoolPart > poolPart);
	    if (_newPoolPart < 9900) {
		    require(_newPoolPart % 25 == 0);
	    } 
	    poolPart = _newPoolPart;
	    emit poolPartWasIncreased(poolPart, block.timestamp);
    }

    function ticketsSold() external view returns (uint) {
       return ticketOwners.length;
    }
    
    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    
    function changeTeamAddress(address _newTeamAddress) external onlyOwner {
	    team = _newTeamAddress;
    }	
    
    function changeFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
    }
    
    function kill() external onlyOwner {
        withdrawLink();
        if (ticketOwners.length != 0) {
            uint256 randomPerson = block.timestamp % ticketOwners.length;
            payable(ticketOwners[randomPerson]).transfer(prize);
            } 
        selfdestruct(payable(owner));
    }
    
     // withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}