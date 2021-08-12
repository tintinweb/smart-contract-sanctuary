/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity 0.6.0;

contract LuckyDraw{
    
    uint private maxParticipantNumbers;
    uint private participantNumbers;
    uint private ticketPrice;
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
        require(msg.value >= ticketPrice);
        msg.sender.transfer(msg.value - ticketPrice);
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
        uint poolSize = address(this).balance;
        
        participants[win].transfer(poolSize*99/100);
        simurgShareContractAddress.transfer(address(this).balance);
        
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