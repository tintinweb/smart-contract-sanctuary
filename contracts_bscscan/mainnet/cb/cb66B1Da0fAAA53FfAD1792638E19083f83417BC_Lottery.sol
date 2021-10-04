/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Lottery
{
    address public owner;
    constructor(){
        owner=msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Lottery///////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 public lotteryTicketPrice=(10**18)/10; //StartPrize Lottery 0.1 BNB
    //The Lottery tickets array, each address stored is a ticket
    address[] private lotteryTickets;
    mapping(address=> uint) TicketCount;
    mapping(address=> uint) LastParticipationRound;
    //The Amount of Lottery tickets in the current round
    uint256 public LotteryParticipants;
    uint lotteryRound;
    event OnBuyLotteryTickets(uint256 FirstTicketID, uint256 LastTicketID, address account);
    //Buys entry to the Lottery, burns token
    function BuyLotteryTickets() public payable{
        uint256 tickets=msg.value/lotteryTicketPrice;
        require(tickets<500);
        require(tickets>0,"<1 ticket");
        uint256 FirstTicketID=LotteryParticipants;
        for(uint256 i=0; i<tickets; i++){
            if(lotteryTickets.length>LotteryParticipants)
                lotteryTickets[LotteryParticipants]=msg.sender;
            else lotteryTickets.push(msg.sender);    
            LotteryParticipants++;
        }   
        if(LastParticipationRound[msg.sender]<lotteryRound){
            TicketCount[msg.sender]==tickets;
            LastParticipationRound[msg.sender]==lotteryRound;
        } 
        else TicketCount[msg.sender]+=tickets;
        emit  OnBuyLotteryTickets(FirstTicketID,LotteryParticipants-1,msg.sender);
    }
    
    function _getPseudoRandomNumber(uint256 modulo) private view returns(uint256) {
        //uses WBNB-Balance to add a bit unpredictability
        uint256 WBNBBalance = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balance;
        
        //generates a PseudoRandomNumber
        uint256 randomResult = uint256(keccak256(abi.encodePacked(
            WBNBBalance + 
            block.timestamp + 
            block.difficulty +
            block.gaslimit
            ))) % modulo;
            
        return randomResult;    
    }
    event OnDrawLotteryWinner(address winner, uint256 amount);
    function DrawLotteryWinner(uint256 newLotteryTicketPrice) public onlyOwner{
        require(LotteryParticipants>0);
        uint256 winner=_getPseudoRandomNumber(LotteryParticipants);
        address winnerAddress=lotteryTickets[winner];
        LotteryParticipants=0;
        lotteryRound++;
        lotteryTicketPrice=newLotteryTicketPrice;
        uint prize=address(this).balance;
        uint taxes=prize*2/10;
        prize-=taxes;
       (bool sent,) = msg.sender.call{value: prize}("");
        require(sent);
       (sent,) = winnerAddress.call{value: prize}("");
        require(sent);
        emit OnDrawLotteryWinner(winnerAddress, prize);

    }
    function getLotteryTicketHolder(uint256 TicketID) public view returns(address){
        require(TicketID<LotteryParticipants,"Doesn't exist");
        return lotteryTickets[TicketID];
    }
    function getTicketCount(address account) public view returns(uint){
        if(LastParticipationRound[account]<lotteryRound) return 0;
        return TicketCount[account];
    }
}