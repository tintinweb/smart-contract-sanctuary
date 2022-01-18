/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

pragma solidity 0.6.0;

contract LuckyDraw {
    
    uint private maxParticipantNumbers;
    uint private participantNumbers;
    uint private ticketPrice;
    address private owner;
    address payable[] participants;
    
    constructor() public {  
        owner =  msg.sender;
        maxParticipantNumbers = 3;
        ticketPrice = 2 ether;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Access denied!");
        _;
    }
    
    modifier notOwner(){
        require(msg.sender != owner, "Access denied");
        _;
    }
    
    function setTicketPrice(uint _valueInEther) public onlyOwner{
        ticketPrice = (_valueInEther * 1000000000000000000);
    }
    
    function setMaximmNumbers(uint _maxNumbers) public onlyOwner{
        participantNumbers = _maxNumbers;
    }
    function viewTicketPrice() external view returns(uint){
        return ticketPrice;
    }
    
    function joinLottery() payable public notOwner(){
        require(msg.value == ticketPrice);
        if (participantNumbers < maxParticipantNumbers){
            participants.push(msg.sender);
            participantNumbers++;
        }
        else if (participantNumbers == maxParticipantNumbers){
            msg.sender.transfer(msg.value);
            pickwinner();
        }
    }
    
    function random() private view returns(uint){
        return uint(keccak256(abi.encode(block.difficulty, now, participants, block.number)));
    }
    
    function pickwinner() internal{
        uint win = random() % participants.length;
        
        participants[win].transfer(address(this).balance);
        
        delete participants;
        participantNumbers = 0;
    }
    
    function endGame() external onlyOwner{
        uint win = random() % participants.length;
        
        participants[win].transfer(address(this).balance);
        
        delete participants;
        participantNumbers = 0;
    }
}