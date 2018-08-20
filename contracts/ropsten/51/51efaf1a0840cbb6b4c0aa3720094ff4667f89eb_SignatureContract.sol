pragma solidity ^0.4.24;
contract SignatureContract {

    address private owner;
	address public signer;
	mapping(bytes32 => bool) public isSignedMerkleRoot;

	event SignerSet(address indexed newSigner);
	event Signed(bytes32 indexed hash);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyByOwner {
        require(msg.sender == owner, "Only owner can call this function!");
        _;
    }
    
    modifier onlyBySigner {
        require(msg.sender == signer, "Only the current signer can call this function!");
        _;
    }

    function setSigner(address aSigner) external onlyByOwner {
        require(aSigner != signer, "This address is already set as the current signer!");
        signer = aSigner;
        emit SignerSet(aSigner);
    }

    function disable() external onlyByOwner {
       delete signer;
       delete owner;
    }

    /*
    *  Adds a SHA2-256 hash to the persisted map. This hash is supposed to be the root of the Merkle Tree of documents being signed.
    *  As a convention, atleast one leaf of the Merkle Tree must be the hash of this smart contract address.
    */
    function sign(bytes32 hash) external onlyBySigner {
		require(!isSignedMerkleRoot[hash], "This SHA2-256 hash is already signed!");
		isSignedMerkleRoot[hash] = true;
		emit Signed(hash);
    }
    
    /*
    *  Checks a given document hash for being a leaf of a signed Merkle Tree.
    *  For the check to be performed the corresponding Merkle Proof is required along with an index encoding the position of siblings at each level (left or right).
    */
    function verifyDocument(bytes32 docHash, bytes merkleProof, uint16 index) external view returns (bool) {
        require(merkleProof.length <= 512, "The Merkle Proof given is too long! It can be upto only 512 bytes as the Merkle Tree is allowed a maximum depth of 16 under conventions of this contract.");
        require(merkleProof.length%32 == 0, "The Merkle Proof given is not a multiple of 32 bytes! It must be a sequence of 32-byte SHA2-256 hashes each representing the sibling at every non-root level starting from leaf level in the Merkle Tree.");
        
        bytes32 root = docHash;
        bytes32 sibling;
        bytes memory proof = merkleProof;
        
        for(uint16 i=32; i<=proof.length; i+=32) {
            assembly {
                sibling := mload(add(proof, i))
            }
            if(index & (uint16(1)<<(i/32-1)) == 0) {
                root = sha256(abi.encodePacked(root, sibling));
            } else {
                root = sha256(abi.encodePacked(sibling, root));
            }
        }
        
        return isSignedMerkleRoot[root];
    }
}