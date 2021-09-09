/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity 0.8.7;

contract Message {
    
    string public currentMsg;
    uint public highestBid;
    
    event Broadcast(string currentMsg, uint highestBid);
    
    constructor() public {
        currentMsg = "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks.";
        highestBid = 0;
        emit Broadcast(currentMsg, highestBid);
    }
    
    function changeMsg(uint bid, string memory message) public{
        if(bid > highestBid){
            highestBid = bid;
            currentMsg = message;
            emit Broadcast(currentMsg, highestBid);
        }
    }
    
    function getAddr() public view returns(address){
        return address(this);
    }

}