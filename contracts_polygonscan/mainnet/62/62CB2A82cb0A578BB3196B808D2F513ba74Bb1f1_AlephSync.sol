/**
 *Submitted for verification at polygonscan.com on 2021-07-23
*/

pragma solidity ^0.5.11;

contract AlephSync{

    event SyncEvent(uint256 timestamp, address addr, string message); 
    event MessageEvent(uint256 timestamp, address addr, string msgtype, string msgcontent); 
    
    function doEmit(string memory message) public {
        emit SyncEvent(block.timestamp, msg.sender, message);
    }
    
    function doMessage(string memory msgtype, string memory msgcontent) public {
        emit MessageEvent(block.timestamp, msg.sender, msgtype, msgcontent);
    }

}