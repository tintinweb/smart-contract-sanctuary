/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract MerkleHashStorage {

	struct MerkleHashData {
		bytes32 hash;
		uint256 block_timestamp;
	}

	address public contrat_owner;
	
	mapping (bytes9 => MerkleHashData) public merkleHashDataArray;
	
	
	/* events */
	/* ------ */
	event MerkleHashAdded(bytes9 indexed merkle_ref, bytes32 merkle_hash, uint256 block_timestamp);
 	/* end events */
 	/* ---------- */
	
	constructor() {
		contrat_owner = msg.sender;
	}
	
	/* external functions */
	/* ------------------ */
	function addMerkleHashData(bytes9 merkle_ref, bytes32 merkle_hash) external {
		require(merkle_ref != 0, "merkle_ref must be > 0");
		require(merkle_hash != 0, "merkle_hash must be > 0");
		require(msg.sender == contrat_owner, "only contract owner can call addMerkleHashData");
		
		/* check if merkle_hash has been already added for this merkle_ref */
		require(merkleHashDataArray[merkle_ref].hash == 0, "merkle_hash has been already added for this merkle_ref");
		
		/* add new merkleHashData into merkleHashDataArray */
		merkleHashDataArray[merkle_ref] = MerkleHashData(merkle_hash, block.timestamp);
		emit MerkleHashAdded(merkle_ref, merkle_hash, block.timestamp);
	}
	/* end external functions */
	/* ---------------------- */
    	
	/* external view function */
	/* ---------------------- */
	function getMerkleHashData(bytes9 merkle_ref) external view returns (MerkleHashData memory) {
		require(merkle_ref != 0, "merkle_ref must be > 0");
		
		MerkleHashData memory merkleHashData = merkleHashDataArray[merkle_ref];

		if (merkleHashData.hash == 0)
			return MerkleHashData(0, 0);

		return merkleHashData;
	}
	/* end external view function */
	/* -------------------------- */
}