/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

pragma solidity ^0.8.4;


contract ZenChipSports

{
 

   function Sports() public view returns(
	
	string memory , 
	address SportsInitiator, 
	uint256 time)
    
	{
        
		return ("ZenChip Sports Smart Contracts Taking Sports to the Blockchain for fans, sports figures, and memorabilia.", msg.sender, block.timestamp);
    
	}
    

}