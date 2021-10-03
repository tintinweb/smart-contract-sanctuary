/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.11;

contract BlockDefStorage
{
	
    Block[18] blocks;
    struct Block
    {
    	int8[24] occupies; // [x0,y0,z0,x1,y1,z1...,x7,y7,z7] 
    	int8[48] attachesto; // [x0,y0,z0,x1,y1,z1...,x15,y15,z15] // first one that is 0,0,0 is the end
    }
    
    address creator;
    function BlockDefStorage()
    {
    	creator = msg.sender;
    }
    
    function getOccupies(uint8 which) public constant returns (int8[24])
    {
    	return blocks[which].occupies;
    }
    
    function getAttachesto(uint8 which) public constant returns (int8[48])
    {
    	return blocks[which].attachesto;
    }

    function initOccupies(uint8 which, int8[24] occupies) public 
    {
    	if(locked) // lockout
    		return;
    	for(uint8 index = 0; index < 24; index++)
    	{
    		blocks[which].occupies[index] = occupies[index];
    	}	
    }
    
    function initAttachesto(uint8 which, int8[48] attachesto) public
    {
    	if(locked) // lockout
    		return;
    	for(uint8 index = 0; index <  48; index++)
    	{
    		blocks[which].attachesto[index] = attachesto[index];
    	}	
    }
    
    /**********
    Standard lock-kill methods 
    **********/
    bool locked;
    function setLocked()
    {
 	   locked = true;
    }
    function getLocked() public constant returns (bool)
    {
 	   return locked;
    }
    function kill()
    { 
        if (!locked && msg.sender == creator)
            suicide(creator);  // kills this contract and sends remaining funds back to creator
    }
}