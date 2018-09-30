pragma solidity ^0.4.25;


/*////////////////////////////////////////////////////////
______  ___  ______  ___  ___  ________ _   _ _   _ _____ 
| ___ \/ _ \ | ___ \/ _ \ |  \/  |  _  | | | | \ | |_   _|
| |_/ / /_\ \| |_/ / /_\ \| .  . | | | | | | |  \| | | |  
|  __/|  _  ||    /|  _  || |\/| | | | | | | | . ` | | |  
| |   | | | || |\ \| | | || |  | \ \_/ / |_| | |\  | | |  
\_|   \_| |_/\_| \_\_| |_/\_|  |_/\___/ \___/\_| \_/ \_/  

v 0.6

////////////////////////////////////////////////////////*/


contract Paramount {
    address owner;
    address lastBidder;
    uint lastBidBlock;
    uint decimals = 18;
    uint minBid = 10 ** decimals / 100;
    uint currentBid = minBid;
    uint blocksDelta = 240;
    
    
    constructor () public {
        owner = msg.sender;
        lastBidder = owner;
        lastBidBlock = block.number;
    }
    
    
    function () external payable {
        if (lastBidBlock + blocksDelta <= block.number) {
            lastBidder.transfer(address(this).balance);
            currentBid = minBid;
            lastBidBlock = block.number;
            lastBidder = msg.sender;
        } else if (msg.value >= currentBid) {
            owner.transfer(msg.value / 20);
            lastBidder = msg.sender;
            lastBidBlock = block.number;
            currentBid = currentBid + minBid;
        } else {
            owner.transfer(msg.value);
        }
    }
    
    function getLastBidder () public view returns (address) {
        return lastBidder;
    }
    
    function getCurrentBid () public view returns (uint) {
        return currentBid;
    }
    
    function blocksUntilWin () public view returns (uint) {
        if (lastBidBlock + blocksDelta > block.number) {
            return lastBidBlock + blocksDelta - block.number;
        } else {
            return 0;
        }
    }
    
}