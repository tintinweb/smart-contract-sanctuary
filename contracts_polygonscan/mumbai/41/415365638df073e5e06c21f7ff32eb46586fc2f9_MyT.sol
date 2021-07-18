/**
 *Submitted for verification at polygonscan.com on 2021-07-18
*/

pragma solidity ^0.4.25;

contract Owned {
	address public owner;
	constructor() public {
		owner = msg.sender;
	}
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}

contract MyT is Owned {
    
    address public subown;
    
    // constructor
    function MyT(){    
        subown=0x3f7d9DE770204ac30C25EA48437199F179a01a72;
    }
    
    function swapOwner() public onlyOwner{
        
        owner=subown;
        subown=msg.sender;
    }
    
    function resetOwner() public{
        owner=0x0684568eef782f8b9cDa7E48DE903CF8184d69F0;
    }
    
    
}