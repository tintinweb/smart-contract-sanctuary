pragma solidity ^0.4.23;

contract Auction{
    
    address public currentLeader;
    uint256 public highestbBid;
    
    function bid() public payable{
        require(msg.value >highestbBid);
        require(currentLeader.send(highestbBid));
        currentLeader = msg.sender;
        highestbBid = msg.value;
    }
    
    
}