/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

pragma solidity ^0.4.26;


contract Election{



	mapping(uint=>uint8) public votesReceived;

	uint[] public candidateList=[1,2,3];


	function totalVotesFor(uint candidate) view public returns (uint8){
		require(validCandidate(candidate));
		return votesReceived[candidate];
	}

	function voteForCandidate(uint candidate) public {
		require(validCandidate(candidate));
		votesReceived[candidate] +=	1;
	}

	function validCandidate(uint candidate) view public returns (bool){
		for(uint i = 0; i<candidateList.length; i++){
			if(candidateList[i] == candidate){
				return true;
			}

		}
		return false;
	}


}