pragma solidity =0.5.17;

import "./MerkleTreeWithHistory.sol";
import "./Ownable.sol";

contract IVerifier {
    function verifyProof(bytes memory _proof, uint256[6] memory _input)
        public
        returns (bool);
}

contract AnonymousTree is Ownable, MerkleTreeWithHistory {
    mapping(bytes32 => bool) public COMMITMENTS;
    mapping(bytes32 => bool) public NULLIFIER_HASHES;
    IVerifier public VERIFIER;

    event Bind(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event UnBind(
        address to,
        bytes32 nullifierHash,
        address indexed relayer,
        uint256 fee
    );

    constructor(address _verifier, uint32 _merkleTreeHeight)
        public
        MerkleTreeWithHistory(_merkleTreeHeight)
    {
        VERIFIER = IVerifier(_verifier);
    }

    function bind(bytes32 _commitment) public onlyOwner returns (bytes32){
        (uint32 insertedIndex, bytes32 root) = _insert(_commitment);

        COMMITMENTS[_commitment] = true;

        emit Bind(_commitment, insertedIndex, block.timestamp);

        return root;
    }

    function unBind(
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external onlyOwner {
        require(
            !NULLIFIER_HASHES[_nullifierHash],
            "The note has been already spent"
        );
        require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
        require(
            VERIFIER.verifyProof(
                _proof,
                [
                    uint256(_root),
                    uint256(_nullifierHash),
                    uint256(_recipient),
                    uint256(_relayer),
                    _fee,
                    _refund
                ]
            ),
            "Invalid withdraw proof"
        );

        NULLIFIER_HASHES[_nullifierHash] = true;

        emit UnBind(_recipient, _nullifierHash, _relayer, _fee);
    }

    function isSpent(bytes32 _nullifierHash) public view returns (bool) {
        return NULLIFIER_HASHES[_nullifierHash];
    }

    function isSpentArray(bytes32[] calldata _nullifierHashes)
        external
        view
        returns (bool[] memory spent)
    {
        spent = new bool[](_nullifierHashes.length);
        for (uint256 i = 0; i < _nullifierHashes.length; i++) {
            if (isSpent(_nullifierHashes[i])) {
                spent[i] = true;
            }
        }
    }
}