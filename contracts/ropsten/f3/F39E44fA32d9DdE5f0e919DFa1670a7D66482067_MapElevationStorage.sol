/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.11;

contract MapElevationStorage
{
    uint8[1089] elevations; // while this is a [a,b,c,d,a1,b1,c1,d1...] array, it should be thought of as
    // [[a,b,c,d], [a1,b1,c1,d1]...] where each subarray is a column.
    // since you'd access the subarray-style 2D array like this: col, row
    // that means that in the 1D array, the first grouping is the first col. The second grouping is the second col, etc
    // As such, element 1 is equivalent to 0,1 -- element 2 = 0,2 -- element 33 = 1,0 -- element 34 = 1,1
    // this is a bit counter intuitive. You might think it would be arranged first row, second row, etc... but you'd be wrong.
    address creator;
    function MapElevationStorage()
    {
    	creator = msg.sender;
    }
    
    function getElevations() constant returns (uint8[1089])
    {
    	return elevations;
    }
    
    function getElevation(uint8 col, uint8 row) constant returns (uint8)
    {
    	//uint index = col * 33 + row;
    	return elevations[uint(col) * 33 + uint(row)];
    }
    
    function initElevations(uint8 col, uint8[33] _elevations) public 
    {
    	if(locked) // lockout
    		return;
    	uint skip = (uint(col) * 33); // e.g. if row 2, start with element 66
    	uint counter = 0;
    	while(counter < 33)
    	{
    		elevations[counter+skip] = _elevations[counter];
    		counter++;
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