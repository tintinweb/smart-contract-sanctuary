/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

contract TriggerTest{
    
    uint public triggerTimestamp;
    uint public triggerBlock;
    
    mapping(address=> uint) public succesfullCalls;
    
    function setTriggerTimestamp(uint256 ts) public {
        triggerTimestamp = ts;
    }
    
    function setTriggerBlock(uint256 bn) public {
        triggerBlock = bn;
    }
    
    function timeLockedFunction() public{
        require(block.timestamp >= triggerTimestamp, "Called Before Timestamp");
        succesfullCalls[msg.sender] = succesfullCalls[msg.sender] + 1;
    }
    
    function blockLockedFunction() public{
        require(block.number >= triggerBlock, "Called Before Blocknumber");
        succesfullCalls[msg.sender] = succesfullCalls[msg.sender] + 1;
    }
    
    function resetCount() public {
        succesfullCalls[msg.sender] = 0;
    }
    
    function currentTimestamp() public view returns(uint){
       return block.timestamp;
    }
    
    function currentBlock() public view returns(uint){
       return block.number;
    }
}