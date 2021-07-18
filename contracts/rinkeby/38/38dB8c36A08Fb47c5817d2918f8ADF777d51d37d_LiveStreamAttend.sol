/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

pragma solidity ^0.8.0;

contract LiveStreamAttend {
    
    uint256 public finalSubmitBlock;
    
    address [] public attendees;
    
    
    constructor(){
        finalSubmitBlock = block.number + 1200;
    }
    
    
    function submit(address _address) public{
        require(block.number <= finalSubmitBlock, "ERROR: the guessing period has ended");
        attendees.push(_address);
    }
    
    function viewAttendees() public view returns(address [] memory){
        return attendees;
    }
    
}