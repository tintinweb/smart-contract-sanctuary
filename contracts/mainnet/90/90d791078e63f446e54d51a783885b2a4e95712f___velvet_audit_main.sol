/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

//SPDX-License-Identifier: no-comment
pragma solidity ^0.8.9;

// total = 235898;
contract __velvet_audit_main
{
    function audit( address a, address b ) external view returns(bool)
    {
        if( ( a.codehash == b.codehash ) && 
	        ( a.code.length == b.code.length ) ) 
	    { 
	        return true;
	    }	    
	    else return false;
    }
}