/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DungeonRandom {

    function dungeonswap_random(uint _yourLastDecisionBlock , address _yourAddress)
		public view  returns(uint32 battleResult, uint32 nftResult) {
		
		// We calculate the random numbers with the NEXT block hash of the your submitted block 
		// in order to made the random result unpredictable.
		// You need to check the result at least 2 block after your submittion
		require(blockhash(_yourLastDecisionBlock+2)!=bytes32(0),"hash error");
		
		uint randomSource = uint256(keccak256(abi.encodePacked(blockhash(_yourLastDecisionBlock+1), _yourAddress)));
        battleResult = uint32((randomSource >> 32))%1000000;
        nftResult = uint32(randomSource)%1000000;
		
		//The result will be two numbers within 0~999999.
    }
    
}