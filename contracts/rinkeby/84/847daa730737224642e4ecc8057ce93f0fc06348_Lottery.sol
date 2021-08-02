pragma solidity >=0.6.0;

import "./01_Owner.sol";

contract Lottery is Owner{
    uint32 ticketNumber;
    uint32 ticketCounter;
    uint256 winnerTicket;
    uint ticketValue = 10^9 wei;
    uint256 poolValue = 0 wei;
    uint256 cooldown;
    mapping (address=>uint256[]) public myTickets;
    mapping (address=>uint256) public myticketCounter;
    mapping (address=>bool) public approval;
    mapping (uint=>address[]) public ticketOwner;
    mapping (uint=>uint) public ticketIDCounter;
    
    
    constructor() public{
        ticketCounter = 0;
    }
    
    function startLottery(uint256 _time) public isOwner{
        cooldown = block.number + _time;
    }
    
    modifier isCooldownOK(){
        require(cooldown >= block.number, "Lottery has not been started!");
        _;
    }
    
    modifier gameEnded(){
        require(cooldown<block.number, "Lottery has not been ended!");
        _;
    }
    
    function setTicketValue(uint256 _ticketValueGwei) public isOwner{
        ticketValue = _ticketValueGwei * 10^9;
    }
    
   function buyRandomTicket() private {
       uint256 _ticket = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, msg.value, block.difficulty)))%1000;
       myTickets[msg.sender].push(_ticket);
       ticketOwner[_ticket].push(msg.sender);
       ticketIDCounter[_ticket] ++;
   }
   
    function viewMyTickets() public view returns(uint256[] memory){
        return myTickets[msg.sender];
    }
    
    function endGame() public isOwner gameEnded returns(address[] memory){
        winnerTicket = uint256(keccak256(abi.encodePacked(msg.sender, msg.data, block.timestamp, block.number, block.difficulty)))%1000;
        for(uint i=0; i<ticketIDCounter[winnerTicket]; i++){
            address payable winner = payable(ticketOwner[winnerTicket][i]);
            winner.transfer(poolValue/(ticketIDCounter[winnerTicket]+1));
        }
        msg.sender.transfer(poolValue/(ticketIDCounter[winnerTicket]+1));
        winnerTicket = 0;
        return ticketOwner[winnerTicket];
    }
    
    function buyTicket(bool _random, uint16 _ticketNumber) public payable isCooldownOK{
       require(msg.value >= ticketValue, "Not enough money!");
       msg.sender.transfer(msg.value - ticketValue);
       myticketCounter[msg.sender] ++;
       if (_random){
           buyRandomTicket();
       }else{
           myTickets[msg.sender].push(_ticketNumber%1000);
           ticketOwner[_ticketNumber%1000].push(msg.sender);
           ticketIDCounter[_ticketNumber%1000]++;
       }
   }
}