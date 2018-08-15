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
        require(aSigner != signer);
        signer = aSigner;
        emit SignerSet(aSigner);
    }

    function disable() external onlyByOwner {
       delete signer;
       delete owner;
    }

    /*
    *  Adds a hash to the persisted map. This hash is supposed to be the root of the Merkle Tree of documents being signed.
    */
    function sign(bytes32 hash) external onlyBySigner {
		require(!isSignedMerkleRoot[hash]);
		isSignedMerkleRoot[hash] = true;
		emit Signed(hash);
    }
    
    /*
    *  Checks a given document hash for being a leaf of a signed Merkle Tree.
    *  For the check to be performed the corresponding Merkle Proof is required (the list of right-siblings at every non-root level starting from leaf level).
    */
    function verifyDocument(bytes32 docHash, bytes32[] merkleProof) external view returns (bool) {
        bytes32 root = docHash;
        uint len = merkleProof.length;
        for(uint i=0; i<len; ++i) {
            root = sha256(abi.encodePacked(root, merkleProof[i]));
        }
        return isSignedMerkleRoot[root];
    }
}