pragma solidity ^0.4.25;


/*////////////////////////////////////////////////////////
______  ___  ______  ___  ___  ________ _   _ _   _ _____ 
| ___ \/ _ \ | ___ \/ _ \ |  \/  |  _  | | | | \ | |_   _|
| |_/ / /_\ \| |_/ / /_\ \| .  . | | | | | | |  \| | | |  
|  __/|  _  ||    /|  _  || |\/| | | | | | | | . ` | | |  
| |   | | | || |\ \| | | || |  | \ \_/ / |_| | |\  | | |  
\_|   \_| |_/\_| \_\_| |_/\_|  |_/\___/ \___/\_| \_/ \_/  

////////////////////////////////////////////////////////*/


contract Paramount {
    address owner;
    address lastBidder;
    uint lastBidBlock;
    uint decimals = 18;
    uint minBid = 10 * decimals / 100;
    uint maxDelta = 6000;
    uint minDelta = 10;
    uint currentDelta = maxDelta;
    
    
    constructor () public {
        owner = msg.sender;
        lastBidBlock = block.number;
    }
    
    
    function () external payable {
        uint currentBalance = address(this).balance;
        owner.transfer(msg.value / 20);
        if (lastBidBlock + currentDelta <= block.number) {
            lastBidder.transfer(currentBalance);
        } else if (msg.value > currentBalance) {
            lastBidder = msg.sender;
            currentDelta = minDelta;
        } else if (msg.value >= minBid) {
            lastBidder = msg.sender;
            currentDelta = maxDelta * (1 - msg.value/currentBalance) + minDelta;
        }
    }
    
    function getLastBidder () public view returns (address) {
        return lastBidder;
    }
    
    function blocksUntilWin () public view returns (uint) {
        if (lastBidBlock + currentDelta > block.number) {
            return lastBidBlock + currentDelta - block.number;
        } else {
            return 0;
        }
    }
    
}