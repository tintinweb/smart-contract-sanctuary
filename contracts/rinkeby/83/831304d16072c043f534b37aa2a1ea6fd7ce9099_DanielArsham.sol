/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract DanielArsham {
      
	function getBlockTimestamp() public view returns(uint) {
		return block.timestamp;
	}

	function getMinute() public view returns (uint8) {
		return uint8((block.timestamp / 60) % 60);
	}

	BuilderMaster public builder = BuilderMaster(0xCA9fC51835DBB525BB6E6ebfcc67b8bE1b08BDfA);

   /**
	* @dev Returns an URI for a given token ID.
	*/
   function tokenURI() external view returns (string memory) {

		string memory tokenIdStr = "vMbC8xqhIf9ny.gif";
		if(getMinute() % 2 == 0) {
			tokenIdStr = "lJNoBCvQYp7nq.gif";
		} 
		string memory uri = builder.strConcat("https://i.giphy.com/", tokenIdStr);
		return uri;
   }
}

abstract contract BuilderMaster {
	function strConcat(string memory _a, string memory _b) virtual public view returns (string memory);
}