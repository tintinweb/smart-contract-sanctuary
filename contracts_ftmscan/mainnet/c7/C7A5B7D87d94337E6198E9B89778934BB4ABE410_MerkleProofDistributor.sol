/**
 *Submitted for verification at FtmScan.com on 2021-11-28
*/

// File: erc20/MerkleProofDistributor.sol


pragma solidity ^0.8.7;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

interface IMerkleProofDistributor {
    function token() external view returns (address);

    function isClaimed(uint8 _type, uint256 _index) external view returns (bool);

    function claim(uint8 _type, uint256 _index, address _receiver, uint256 _amount, bytes32[] calldata _merkleProof) external;

    event Claimed(uint256 index, address receiver, uint256 amount);
}


interface IMonsterERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

contract MerkleProofDistributor is IMerkleProofDistributor {
    address public immutable override token;

    mapping(uint8 => bytes32) public merkleRoot;
    mapping(uint8 => mapping (uint8 => mapping(uint256 => uint256))) private claimedBitMap;
    
    uint private constant phaseLimit = 250_000;
    uint256 public phaseDroppedCount;
    // limit the drops to the rarity per phase
    uint private constant type3Limit = 30_000;
    uint256 public type3DroppedCount;

    uint public startTime;
    uint public endTime;
    uint8 public phase;

    address private immutable owner;

    constructor(address token_, bytes32 merkleRoot1_, bytes32 merkleRoot2_, bytes32 merkleRoot3_, uint startTime_, uint endTime_, uint8 phase_) {
        owner = msg.sender;
        token = token_;
        merkleRoot[1] = merkleRoot1_;
        merkleRoot[2] = merkleRoot2_;
        merkleRoot[3] = merkleRoot3_;
        startTime = startTime_;
        endTime = endTime_;
        phase = phase_;
    }

    function reset(uint _startTime, uint _endTime, uint8 _phase, uint256 _type3DroppedCount, uint256 _phaseDroppedCount) external {
        require(msg.sender == owner, "Only Owner");
        require(_phase <= 4 && _phase > 0, "Phase error");

        startTime = _startTime;
        endTime = _endTime;
        phase = _phase;

        type3DroppedCount = _type3DroppedCount;
        phaseDroppedCount = _phaseDroppedCount;
    }

    function setRoot(uint8 _type, bytes32 _merkleRoot) external {
        require(msg.sender == owner, "Only Owner");

        merkleRoot[_type] = _merkleRoot;
    }

    function isClaimed(uint8 _type, uint256 _index) public view override returns (bool) {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        uint256 claimedWord = claimedBitMap[phase][_type][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function isType3Available(uint256 _amount) public view returns (bool) {
        return type3DroppedCount + _amount/4 <= type3Limit;
    }

    function _setClaimed(uint8 _type, uint256 _index) private {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        claimedBitMap[phase][_type][claimedWordIndex] = claimedBitMap[phase][_type][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint8 _type, uint256 _index, address _receiver, uint256 _amount, bytes32[] calldata _merkleProof) external override {
        require(!isClaimed(_type, _index), 'Already claimed');
        require(phaseDroppedCount <= phaseLimit, 'Hit the phase limit');

        require(block.timestamp <= endTime && block.timestamp >= startTime, 'Not in the time frame');

        if (_type == 3){
            require(isType3Available(_amount), 'Hit the limit');
        }

        bytes32 node = keccak256(abi.encodePacked(_index, _receiver, _amount));

        require(MerkleProof.verify(_merkleProof, merkleRoot[_type], node), 'Invalid proof');

        _setClaimed(_type, _index);
        if (_type == 3) {
            type3DroppedCount += _amount/4;
        }
        phaseDroppedCount += _amount/4;
        require(IMonsterERC20(token).mint(_receiver, _amount*1e18/4), 'Mint failed');

        emit Claimed(_index, _receiver, _amount*1e18/4);
    }

    function isValidated(uint8 _type, uint256 _index, address _receiver, uint256 _amount, bytes32[] calldata _merkleProof) view external returns (bool){

        bytes32 node = keccak256(abi.encodePacked(_index, _receiver, _amount));

        return MerkleProof.verify(_merkleProof, merkleRoot[_type], node);
    }
}