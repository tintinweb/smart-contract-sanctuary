/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Auction {
    // Gewinn ist nur eine Nachricht auf dem Netzwerk!
    
    address highestBidder;
    uint highestBidAmount;
    mapping(address => uint) public OwnBidAmount;
    /*uint[][] public AllParticipants; Versuch*/
    address public owner;
    
    uint AuctionEndTimeStamp;   // wird im constructor festgelegt
    string winnerText;  // wird im constructor festgelegt 
    
    constructor (uint bidTime, uint _winnerMessage) {
        AuctionEndTimeStamp = block.timestamp + bidTime;
        if (_winnerMessage == 1) {
            winnerText = "Sehr Gut!";
        } else if (_winnerMessage == 2) {
            winnerText = "Gut!";
        }
        else {
            winnerText = "Ausgezeichnet";
        }
        owner = msg.sender;
    }
    
    
    function initialbid() payable external {
        require(OwnBidAmount[msg.sender] == 0, 'Sie haben bereits ein Gebot abgegeben');
        require(msg.value > 0, 'Sie muessen etwas ueberweisen');
        // keine gleichen ersten Plaetze:
        require(msg.value != highestBidAmount, 'Keine gleichen ersten Plaetze');
        require(AuctionEndTimeStamp > block.timestamp, 'Gebote koennen nicht mehr abgegeben werden, Auktion ist beendet');
        
        OwnBidAmount[msg.sender] = msg.value;
        
        if (msg.value > highestBidAmount) {
            highestBidder = msg.sender;
            highestBidAmount = msg.value;
        }
    } 
    
    function increasebid() payable external {
        require(OwnBidAmount[msg.sender] > 0, "Sie haben noch kein Gebot abgegeben, geben Sie Ihr Initalgebot ab!");
        require(msg.value > 0, 'Sie muessen etwas ueberweisen');
        require((OwnBidAmount[msg.sender] + msg.value) != highestBidAmount, 'Keine gleichen ersten Plaetze');
        require(AuctionEndTimeStamp > block.timestamp, 'Gebote koennen nicht mehr abgegeben werden, Auktion ist beendet');
        
        OwnBidAmount[msg.sender] += msg.value;
        
        if (OwnBidAmount[msg.sender] > highestBidAmount) {
            highestBidder = msg.sender;
            highestBidAmount = OwnBidAmount[msg.sender];
        }
    }
    
    modifier isOwner () {
        require(msg.sender == owner, 'Luegner!!');
        _;
    }
    
    function withdrawAfterEnded() external isOwner{
        require(AuctionEndTimeStamp <= block.timestamp, 'Gebote koennen noch abgegeben werden. Auktion ist noch nicht beendet');
        require(msg.sender != highestBidder, 'Sie haben die Auktion gewonnen, aber koennen Ihr Gebot nicht mehr zuruecknehmen!');
        
        payable(msg.sender).transfer(OwnBidAmount[msg.sender]);
        
        if (msg.sender == owner) {
            payable(msg.sender).transfer(highestBidAmount);
        }
    }
    
    function ShowLeadingBidder() view external returns(address, uint) {
        require(highestBidAmount != 0, "Es wurde noch nichts geboten!");
        require(AuctionEndTimeStamp > block.timestamp, 'Auktion ist vorbei. Bite guck dir den Gewinner an!');
        return (highestBidder, highestBidAmount);
    }
    
    function ShowWinner() view external returns(address, uint) {
        require(AuctionEndTimeStamp <= block.timestamp, 'Auktion ist noch im Gange!');
        return (highestBidder, highestBidAmount);
    }
    
    // reiner Versuch
    /*function start() payable external {
        AllParticipants.push([0,1]);
        AllParticipants.push([1,2]);
    }*/
    /*function ShowAllParticipants() external view returns(uint[][] memory) {
        return (AllParticipants);
    }*/
}