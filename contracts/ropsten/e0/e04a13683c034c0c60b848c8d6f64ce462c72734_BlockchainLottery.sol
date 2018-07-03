pragma solidity ^0.4.23;

contract BlockchainLottery {
    
    address owner;
    
    uint ticketPrice = 0.0001 ether;
    mapping(uint => address) public tickets;
    uint public ticketCount; 
    
    event LotteryResult(address winner, uint ticketId, uint prise);
    event NewTicket(uint ticketId);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function buyTicket() public payable {
        require(msg.value == ticketPrice);
        tickets[ticketCount] = msg.sender;
        emit NewTicket(ticketCount);
        ticketCount = ticketCount + 1;
    }
    
    function startLottery() public onlyOwner {
        require(ticketCount >= 5);
        uint random = uint(sha3(block.timestamp)) % (ticketCount - 1);
        address winner = tickets[random];
        uint prize = (ticketCount * 0.0001 ether) * 80 / 100;
        winner.transfer(prize);
        emit LotteryResult(winner, random, prize);
        for(uint i=0; i<=ticketCount-1; i++)
        {
            delete tickets[i];
        } 
        ticketCount = 0;
    }
    
   
}