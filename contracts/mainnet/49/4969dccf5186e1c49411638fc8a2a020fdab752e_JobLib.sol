pragma solidity 0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/*
 * @title MerkleProof
 * @dev Merkle proof verification
 * @note Based on https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
 */
library MerkleProof {
  /*
   * @dev Verifies a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that each pair of leaves
   * and each pair of pre-images is sorted.
   * @param _proof Merkle proof containing sibling hashes on the branch from the leaf to the root of the Merkle tree
   * @param _root Merkle root
   * @param _leaf Leaf of Merkle tree
   */
  function verifyProof(bytes _proof, bytes32 _root, bytes32 _leaf) public pure returns (bool) {
    // Check if proof length is a multiple of 32
    if (_proof.length % 32 != 0) return false;

    bytes32 proofElement;
    bytes32 computedHash = _leaf;

    for (uint256 i = 32; i <= _proof.length; i += 32) {
      assembly {
        // Load the current element of the proof
        proofElement := mload(add(_proof, i))
      }

      if (computedHash < proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(computedHash, proofElement);
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(proofElement, computedHash);
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == _root;
  }
}

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 */
library ECRecovery {

  /**
   * @dev Recover signer address from a message by using his signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

library JobLib {
    using SafeMath for uint256;
    // Prefix hashed with message hash when a signature is produced by the eth_sign RPC call
    string constant PERSONAL_HASH_PREFIX = "\u0019Ethereum Signed Message:\n32";
    // # of bytes used to store a video profile identifier as a utf8 encoded string
    // Video profile identifier is currently stored as bytes4(keccak256(PROFILE_NAME))
    // We use 2 * 4 = 8 bytes because we store the bytes in a utf8 encoded string so
    // the identifiers can be easily parsed off-chain
    uint8 constant VIDEO_PROFILE_SIZE = 8;

    /*
     * @dev Checks if a transcoding options string is valid
     * A transcoding options string is composed of video profile ids so its length
     * must be a multiple of VIDEO_PROFILE_SIZE
     * @param _transcodingOptions Transcoding options string
     */
    function validTranscodingOptions(string _transcodingOptions) public pure returns (bool) {
        uint256 transcodingOptionsLength = bytes(_transcodingOptions).length;
        return transcodingOptionsLength > 0 && transcodingOptionsLength % VIDEO_PROFILE_SIZE == 0;
    }

    /*
     * @dev Computes the amount of fees given total segments, total number of profiles and price per segment
     * @param _totalSegments # of segments
     * @param _transcodingOptions String containing video profiles for a job
     * @param _pricePerSegment Price in LPT base units per segment
     */
    function calcFees(uint256 _totalSegments, string _transcodingOptions, uint256 _pricePerSegment) public pure returns (uint256) {
        // Calculate total profiles defined in the transcoding options string
        uint256 totalProfiles = bytes(_transcodingOptions).length.div(VIDEO_PROFILE_SIZE);
        return _totalSegments.mul(totalProfiles).mul(_pricePerSegment);
    }

    /*
     * Computes whether a segment is eligible for verification based on the last call to claimWork()
     * @param _segmentNumber Sequence number of segment in stream
     * @param _segmentRange Range of segments claimed
     * @param _challengeBlock Block afer the block when claimWork() was called
     * @param _challengeBlockHash Block hash of challenge block
     * @param _verificationRate Rate at which a particular segment should be verified
     */
    function shouldVerifySegment(
        uint256 _segmentNumber,
        uint256[2] _segmentRange,
        uint256 _challengeBlock,
        bytes32 _challengeBlockHash,
        uint64 _verificationRate
    )
        public
        pure
        returns (bool)
    {
        // Segment must be in segment range
        if (_segmentNumber < _segmentRange[0] || _segmentNumber > _segmentRange[1]) {
            return false;
        }

        // Use block hash and block number of the block after a claim to determine if a segment
        // should be verified
        if (uint256(keccak256(_challengeBlock, _challengeBlockHash, _segmentNumber)) % _verificationRate == 0) {
            return true;
        } else {
            return false;
        }
    }

    /*
     * @dev Checks if a segment was signed by a broadcaster address
     * @param _streamId Stream ID for the segment
     * @param _segmentNumber Sequence number of segment in the stream
     * @param _dataHash Hash of segment data
     * @param _broadcasterSig Broadcaster signature over h(streamId, segmentNumber, dataHash)
     * @param _broadcaster Broadcaster address
     */
    function validateBroadcasterSig(
        string _streamId,
        uint256 _segmentNumber,
        bytes32 _dataHash,
        bytes _broadcasterSig,
        address _broadcaster
    )
        public
        pure
        returns (bool)
    {
        return ECRecovery.recover(personalSegmentHash(_streamId, _segmentNumber, _dataHash), _broadcasterSig) == _broadcaster;
    }

    /*
     * @dev Checks if a transcode receipt hash was included in a committed merkle root
     * @param _streamId StreamID for the segment
     * @param _segmentNumber Sequence number of segment in the stream
     * @param _dataHash Hash of segment data
     * @param _transcodedDataHash Hash of transcoded segment data
     * @param _broadcasterSig Broadcaster signature over h(streamId, segmentNumber, dataHash)
     * @param _broadcaster Broadcaster address
     */
    function validateReceipt(
        string _streamId,
        uint256 _segmentNumber,
        bytes32 _dataHash,
        bytes32 _transcodedDataHash,
        bytes _broadcasterSig,
        bytes _proof,
        bytes32 _claimRoot
    )
        public
        pure
        returns (bool)
    {
        return MerkleProof.verifyProof(_proof, _claimRoot, transcodeReceiptHash(_streamId, _segmentNumber, _dataHash, _transcodedDataHash, _broadcasterSig));
    }

    /*
     * Compute the hash of a segment
     * @param _streamId Stream identifier
     * @param _segmentSequenceNumber Segment sequence number in stream
     * @param _dataHash Content-addressed storage hash of segment data
     */
    function segmentHash(string _streamId, uint256 _segmentNumber, bytes32 _dataHash) public pure returns (bytes32) {
        return keccak256(_streamId, _segmentNumber, _dataHash);
    }

    /*
     * @dev Compute the personal segment hash of a segment. Hashes the concatentation of the personal hash prefix and the segment hash
     * @param _streamId Stream identifier
     * @param _segmentSequenceNumber Segment sequence number in stream
     * @param _dataHash Content-addrssed storage hash of segment data
     */
    function personalSegmentHash(string _streamId, uint256 _segmentNumber, bytes32 _dataHash) public pure returns (bytes32) {
        bytes memory prefixBytes = bytes(PERSONAL_HASH_PREFIX);

        return keccak256(prefixBytes, segmentHash(_streamId, _segmentNumber, _dataHash));
    }

    /*
     * Compute the hash of a transcode receipt
     * @param _streamId Stream identifier
     * @param _segmentSequenceNumber Segment sequence number in stream
     * @param _dataHash Content-addressed storage hash of segment data
     * @param _transcodedDataHash Content-addressed storage hash of transcoded segment data
     * @param _broadcasterSig Broadcaster&#39;s signature over segment
     */
    function transcodeReceiptHash(
        string _streamId,
        uint256 _segmentNumber,
        bytes32 _dataHash,
        bytes32 _transcodedDataHash,
        bytes _broadcasterSig
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(_streamId, _segmentNumber, _dataHash, _transcodedDataHash, _broadcasterSig);
    }
}