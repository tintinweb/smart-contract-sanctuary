pragma solidity 0.4.24;

/**
 * This contract is used to protect the users of Storm4:
 * https://www.storm4.cloud
 * 
 * That is, to ensure the public keys of users are verifiable, auditable & tamper-proof.
 * 
 * Here&#39;s the general idea:
 * - We batch the public keys of multiple users into a merkle tree.
 * - We publish the merkle tree root to this contract.
 * - The merkle tree root for any user can only be assigned once.
 * 
 * In order to verify a user:
 * - Use this contract to fetch the merkle tree root value for the userID.
 * - Then use HTTPS to fetch the corresponding merkle file from our server.
 *   For example, if the merkle tree root value is
 *   "0xcd59b7bda6dc1dd82cb173d0cdfa408db30e9a747d4366eb5b60597899eb69c1",
 *   then you could fetch the corresponding JSON file at
 *   https://blockchain.storm4.cloud/cd59b7bda6dc1dd82cb173d0cdfa408db30e9a747d4366eb5b60597899eb69c1.json
 * - The JSON file allows you to independently verify the public key information
 *   by calculating the merkle tree root for yourself.
**/
contract PubKeyTrust {
	address public owner;
	string public constant HASH_TYPE = "sha256";

	/**
	 * users[userID] => merkleTreeRoot
	 * 
	 * A value of zero indicates that a merkleTreeRoot has not been
	 * published for the userID.
	**/
	mapping(bytes20 => bytes32) private users;
	
	/**
	 * merkleTreeRoots[merkleTreeRootValue] => blockNumber
	 * 
	 * Note: merkleTreeRoots[0x0] is initialized in the constructor to store
	 * the block number of when the contract was published.
	**/
	mapping(bytes32 => uint) private merkleTreeRoots;

	constructor() public {
		owner = msg.sender;
		merkleTreeRoots[bytes32(0)] = block.number;
	}

	modifier onlyByOwner()
	{
		if (msg.sender != owner)
			require(false);
		else
			_;
	}

	/**
	 * We originally passed the userIDs as: bytes20[] userIDs
	 * But it was discovered that this was inefficiently packed,
	 * and ended up sending 12 bytes of zero&#39;s per userID.
	 * Since gtxdatazero is set to 4 gas/bytes, this translated into
	 * 48 gas wasted per user due to inefficient packing.
	**/
	function addMerkleTreeRoot(bytes32 merkleTreeRoot, bytes userIDsPacked) public onlyByOwner {

		if (merkleTreeRoot == bytes32(0)) require(false);

		bool addedUser = false;

		uint numUserIDs = userIDsPacked.length / 20;
		for (uint i = 0; i < numUserIDs; i++)
		{
			bytes20 userID;
			assembly {
				userID := mload(add(userIDsPacked, add(32, mul(20, i))))
			}

			bytes32 existingMerkleTreeRoot = users[userID];
			if (existingMerkleTreeRoot == bytes32(0))
			{
				users[userID] = merkleTreeRoot;
				addedUser = true;
			}
		}

		if (addedUser && (merkleTreeRoots[merkleTreeRoot] == 0))
		{
			merkleTreeRoots[merkleTreeRoot] = block.number;
		}
	}

	function getMerkleTreeRoot(bytes20 userID) public view returns (bytes32) {

		return users[userID];
	}

	function getBlockNumber(bytes32 merkleTreeRoot) public view returns (uint) {

		return merkleTreeRoots[merkleTreeRoot];
	}

    function getUserInfo(bytes20 userID) public view returns (bytes32, uint) {
        
        bytes32 merkleTreeRoot = users[userID];
        uint blockNumber = merkleTreeRoots[merkleTreeRoot];
        
        return (merkleTreeRoot, blockNumber);
    }	
}