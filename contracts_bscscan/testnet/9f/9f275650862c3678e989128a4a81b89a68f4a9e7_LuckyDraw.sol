/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

pragma solidity 0.6.0;

contract LuckyDraw{
    
    uint private maxParticipantNumbers;
    uint private participantNumbers;
    uint private ticketPrice;
    uint public contractValue;
    address private owner;
    address payable[] participants;
    
    address payable simurgShareContractAddress = 0xB59419787B83d6bD202f5D6A85d3cfAB3BafAb6c;
    
    constructor() public {  
        owner =  msg.sender;
        maxParticipantNumbers = 2;
        ticketPrice = 1000000000000000 wei;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Access denied!");
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
    
    function joinLottery() payable public{
        if (participantNumbers < maxParticipantNumbers){
            require(msg.value >= ticketPrice);
            msg.sender.transfer(msg.value - ticketPrice);
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
        uint poolSize = address(this).balance*99/100;
        
        participants[win].transfer(poolSize);
        
        delete participants;
        participantNumbers = 0;
    }
    
    function sendProfit() public{
        simurgShareContractAddress.transfer(address(this).balance);
        contractValue = 0;
    }
    
    function endGame() external onlyOwner{
        uint win = random() % participants.length;
        uint poolSize = address(this).balance*99/100;
        
        participants[win].transfer(poolSize);
        
        delete participants;
        participantNumbers = 0;
    }
}