/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Types {
	
	// Declaring a dynamic array
	uint[] data;
	

	function loop() public returns(uint[] memory){
    for(uint i=0; i<8888; i++){
        data.push(i);
     }
      return data;
    }
}