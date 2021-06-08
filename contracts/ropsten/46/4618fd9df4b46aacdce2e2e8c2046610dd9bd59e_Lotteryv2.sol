/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity^0.8.0;


contract Lotteryv2 {
     
    address public owner;
  
    struct Participant {
        uint entryCount;
        uint index;
    }
    
    address[] public localIndexes;
    mapping(address => Participant) participants;
    address[] public addressBag ;
   
    Participant public winner;
    
    bool public isLotteryActivated;
    uint public maxEntriesForEach;
    uint public coinToParticipate;
    
    uint public ownerRate;
  

    constructor()  {
        owner = msg.sender;
    }
    
    function lotteryParticipate() public payable {
        
        require(isLotteryActivated, "Lottery is not live");
        require(msg.value == coinToParticipate * 1 ether , "Entry fee is not matching");
        require(participants[msg.sender].entryCount < maxEntriesForEach , "Max entries reached for the Player");
        
        if (isNewParticipant(msg.sender)) {
            localIndexes.push(msg.sender);
            participants[msg.sender].entryCount = 1;
            participants[msg.sender].index = localIndexes.length - 1;
        } else {
            participants[msg.sender].entryCount += 1;
        }
        
        addressBag.push(msg.sender);
      
        //emit to UI 
    }
    
    function activateLottery(uint maxEntries, uint ethRequired) public restricted {
        isLotteryActivated = true;
        maxEntriesForEach = maxEntries == 0 ? 1: maxEntries;
        coinToParticipate = ethRequired == 0 ? 1: ethRequired;
        
        //emit to UI
    }
    
    function drawWinner() public restricted {
        require(addressBag.length > 0, "No players entered the lottery");
        uint index = generateRandomNumber() % addressBag.length;
        
        payable(owner).transfer(address(this).balance * (ownerRate/100));
        
        //wait for completion of previous transaction
        payable(addressBag[index]).transfer((address(this).balance));
    
        addressBag = new address[](0);
        localIndexes = new address[](0);
      
        isLotteryActivated = false;
       
        //emit to UI 
    }
    
    function getParticipants() public view returns(address[] memory) {
     return localIndexes;
    }
   
    function getWinningPrice() public view returns (uint) {
     return address(this).balance;
    }
  
    function isNewParticipant(address playerAddress) private view returns(bool) {
        if (localIndexes.length == 0) {
          return true;
        }
      return (localIndexes[participants[playerAddress].index] != playerAddress);
    }
    
    
    function generateRandomNumber() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, addressBag)));
    }
    
    
    modifier restricted() {
    require(msg.sender == owner, "Action is restricted !!! ");
    _;
    }
    
}