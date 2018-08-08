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

library MathUtils {
    using SafeMath for uint256;

    // Divisor used for representing percentages
    uint256 public constant PERC_DIVISOR = 1000000;

    /*
     * @dev Returns whether an amount is a valid percentage out of PERC_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }

    /*
     * @dev Compute percentage of a value with the percentage represented by a fraction
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage
     * @param _fracDenom Denominator of fraction representing the percentage
     */
    function percOf(uint256 _amount, uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _amount.mul(percPoints(_fracNum, _fracDenom)).div(PERC_DIVISOR);
    }

    /*
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PERC_DIVISOR as the denominator
     */
    function percOf(uint256 _amount, uint256 _fracNum) internal pure returns (uint256) {
        return _amount.mul(_fracNum).div(PERC_DIVISOR);
    }

    /*
     * @dev Compute percentage representation of a fraction
     * @param _fracNum Numerator of fraction represeting the percentage
     * @param _fracDenom Denominator of fraction represeting the percentage
     */
    function percPoints(uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _fracNum.mul(PERC_DIVISOR).div(_fracDenom);
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(bytes32 _id, address _contractAddress, bytes20 _gitCommitHash) external;
    function updateController(bytes32 _id, address _controller) external;
    function getContract(bytes32 _id) public view returns (address);
}

contract IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}

contract Manager is IManager {
    // Controller that contract is registered with
    IController public controller;

    // Check if sender is controller
    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

    // Check if sender is controller owner
    modifier onlyControllerOwner() {
        require(msg.sender == controller.owner());
        _;
    }

    // Check if controller is not paused
    modifier whenSystemNotPaused() {
        require(!controller.paused());
        _;
    }

    // Check if controller is paused
    modifier whenSystemPaused() {
        require(controller.paused());
        _;
    }

    function Manager(address _controller) public {
        controller = IController(_controller);
    }

    /*
     * @dev Set controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        SetController(_controller);
    }
}

/**
 * @title ManagerProxyTarget
 * @dev The base contract that target contracts used by a proxy contract should inherit from
 * Note: Both the target contract and the proxy contract (implemented as ManagerProxy) MUST inherit from ManagerProxyTarget in order to guarantee
 * that both contracts have the same storage layout. Differing storage layouts in a proxy contract and target contract can
 * potentially break the delegate proxy upgradeability mechanism
 */
contract ManagerProxyTarget is Manager {
    // Used to look up target contract address in controller&#39;s registry
    bytes32 public targetContractId;
}

/**
 * @title Minter interface
 */
contract IMinter {
    // Events
    event SetCurrentRewardTokens(uint256 currentMintableTokens, uint256 currentInflation);

    // External functions
    function createReward(uint256 _fracNum, uint256 _fracDenom) external returns (uint256);
    function trustedTransferTokens(address _to, uint256 _amount) external;
    function trustedBurnTokens(uint256 _amount) external;
    function trustedWithdrawETH(address _to, uint256 _amount) external;
    function depositETH() external payable returns (bool);
    function setCurrentRewardTokens() external;

    // Public functions
    function getController() public view returns (IController);
}

/**
 * @title Interface for a Verifier. Can be backed by any implementaiton including oracles or Truebit
 */
contract IVerifier {
    function verify(
                    uint256 _jobId,
                    uint256 _claimId,
                    uint256 _segmentNumber,
                    string _transcodingOptions,
                    string _dataStorageHash,
                    bytes32[2] _dataHashes
                    )
        external
        payable;

    function getPrice() public view returns (uint256);
}

/**
 * @title RoundsManager interface
 */
contract IRoundsManager {
    // Events
    event NewRound(uint256 round);

    // External functions
    function initializeRound() external;

    // Public functions
    function blockNum() public view returns (uint256);
    function blockHash(uint256 _block) public view returns (bytes32);
    function currentRound() public view returns (uint256);
    function currentRoundStartBlock() public view returns (uint256);
    function currentRoundInitialized() public view returns (bool);
    function currentRoundLocked() public view returns (bool);
}

/*
 * @title Interface for BondingManager
 */
contract IBondingManager {
    event TranscoderUpdate(address indexed transcoder, uint256 pendingRewardCut, uint256 pendingFeeShare, uint256 pendingPricePerSegment, bool registered);
    event TranscoderEvicted(address indexed transcoder);
    event TranscoderResigned(address indexed transcoder);
    event TranscoderSlashed(address indexed transcoder, address finder, uint256 penalty, uint256 finderReward);
    event Reward(address indexed transcoder, uint256 amount);
    event Bond(address indexed delegate, address indexed delegator);
    event Unbond(address indexed delegate, address indexed delegator);
    event WithdrawStake(address indexed delegator);
    event WithdrawFees(address indexed delegator);

    // External functions
    function setActiveTranscoders() external;
    function updateTranscoderWithFees(address _transcoder, uint256 _fees, uint256 _round) external;
    function slashTranscoder(address _transcoder, address _finder, uint256 _slashAmount, uint256 _finderFee) external;
    function electActiveTranscoder(uint256 _maxPricePerSegment, bytes32 _blockHash, uint256 _round) external view returns (address);

    // Public functions
    function transcoderTotalStake(address _transcoder) public view returns (uint256);
    function activeTranscoderTotalStake(address _transcoder, uint256 _round) public view returns (uint256);
    function isRegisteredTranscoder(address _transcoder) public view returns (bool);
    function getTotalBonded() public view returns (uint256);
}

/*
 * @title Interface for contract that receives verification results
 */
contract IVerifiable {
    // External functions
    function receiveVerification(uint256 _jobId, uint256 _claimId, uint256 _segmentNumber, bool _result) external;
}

/*
 * @title Interface for JobsManager
 */
contract IJobsManager {
    event Deposit(address indexed broadcaster, uint256 amount);
    event Withdraw(address indexed broadcaster);
    event NewJob(address indexed broadcaster, uint256 jobId, string streamId, string transcodingOptions, uint256 maxPricePerSegment, uint256 creationBlock);
    event NewClaim(address indexed transcoder, uint256 indexed jobId, uint256 claimId);
    event Verify(address indexed transcoder, uint256 indexed jobId, uint256 indexed claimId, uint256 segmentNumber);
    event DistributeFees(address indexed transcoder, uint256 indexed jobId, uint256 indexed claimId, uint256 fees);
    event PassedVerification(address indexed transcoder, uint256 indexed jobId, uint256 indexed claimId, uint256 segmentNumber);
    event FailedVerification(address indexed transcoder, uint256 indexed jobId, uint256 indexed claimId, uint256 segmentNumber);
}

contract JobsManager is ManagerProxyTarget, IVerifiable, IJobsManager {
    using SafeMath for uint256;

    // % of segments to be verified. 1 / verificationRate == % to be verified
    uint64 public verificationRate;

    // Time after a transcoder calls claimWork() that it has to complete verification of claimed work
    uint256 public verificationPeriod;

    // Time after a claim&#39;s verification period during which anyone can slash the transcoder for missing a required verification
    uint256 public verificationSlashingPeriod;

    // % of stake slashed for failed verification
    uint256 public failedVerificationSlashAmount;

    // % of stake slashed for missed verification
    uint256 public missedVerificationSlashAmount;

    // % of stake slashed for double claiming a segment
    uint256 public doubleClaimSegmentSlashAmount;

    // % of of slashed amount awarded to finder
    uint256 public finderFee;

    struct Broadcaster {
        uint256 deposit;         // Deposited tokens for jobs
        uint256 withdrawBlock;   // Block at which a deposit can be withdrawn
    }

    // Mapping broadcaster address => broadcaster info
    mapping (address => Broadcaster) public broadcasters;

    // Represents a transcode job
    struct Job {
        uint256 jobId;                        // Unique identifer for job
        string streamId;                      // Unique identifier for stream.
        string transcodingOptions;            // Options used for transcoding
        uint256 maxPricePerSegment;           // Max price (in LPT base units) per segment of a stream
        address broadcasterAddress;           // Address of broadcaster that requestes a transcoding job
        address transcoderAddress;            // Address of transcoder selected for the job
        uint256 creationRound;                // Round that a job is created
        uint256 creationBlock;                // Block that a job is created
        uint256 endBlock;                     // Block at which the job is ended and considered inactive
        Claim[] claims;                       // Claims submitted for this job
        uint256 escrow;                       // Claim fees before verification and slashing periods are complete
    }

    // States of a job
    enum JobStatus { Inactive, Active }

    // Represents a transcode claim
    struct Claim {
        uint256 claimId;                                   // Unique identifier for claim
        uint256[2] segmentRange;                           // Range of segments claimed
        bytes32 claimRoot;                                 // Merkle root of segment transcode proof data
        uint256 claimBlock;                                // Block number that claim was submitted
        uint256 endVerificationBlock;                      // End of verification period for this claim
        uint256 endVerificationSlashingBlock;              // End of verification slashing period for this claim
        mapping (uint256 => bool) segmentVerifications;    // Mapping segment number => whether segment was submitted for verification
        ClaimStatus status;                                // Status of claim (pending, slashed, complete)
    }

    // States of a transcode claim
    enum ClaimStatus { Pending, Slashed, Complete }

    // Transcode jobs
    mapping (uint256 => Job) public jobs;
    // Number of jobs created. Also used for sequential identifiers
    uint256 public numJobs;

    // Check if sender is Verifier
    modifier onlyVerifier() {
        require(msg.sender == controller.getContract(keccak256("Verifier")));
        _;
    }

    // Check if job exists
    modifier jobExists(uint256 _jobId) {
        require(_jobId < numJobs);
        _;
    }

    // Check if sender provided enough payment for verification
    modifier sufficientPayment() {
        require(msg.value >= verifier().getPrice());
        _;
    }

    function JobsManager(address _controller) public Manager(_controller) {}

    /*
     * @dev Set verification rate. Only callable by the controller owner
     * @param _verificationRate Verification rate such that 1 / verificationRate of segments are challenged
     */
    function setVerificationRate(uint64 _verificationRate) external onlyControllerOwner {
        // verificationRate cannot be 0
        require(_verificationRate > 0);

        verificationRate = _verificationRate;

        ParameterUpdate("verificationRate");
    }

    /*
     * @dev Set verification period. Only callable by the controller owner
     * @param _verificationPeriod Number of blocks to complete verification of claimed work
     */
    function setVerificationPeriod(uint256 _verificationPeriod) external onlyControllerOwner {
        // Verification period + verification slashing period currently cannot be longer than 256 blocks
        // because contracts can only access the last 256 blocks from
        // the current block
        require(_verificationPeriod.add(verificationSlashingPeriod) <= 256);

        verificationPeriod = _verificationPeriod;

        ParameterUpdate("verificationPeriod");
    }

    /*
     * @dev Set verification slashing period. Only callable by the controller owner
     * @param _verificationSlashingPeriod Number of blocks after the verification period to submit slashing proofs
     */
    function setVerificationSlashingPeriod(uint256 _verificationSlashingPeriod) external onlyControllerOwner {
        // Verification period + verification slashing period currently cannot be longer than 256 blocks
        // because contracts can only access the last 256 blocks from
        // the current block
        require(verificationPeriod.add(_verificationSlashingPeriod) <= 256);

        verificationSlashingPeriod = _verificationSlashingPeriod;

        ParameterUpdate("verificationSlashingPeriod");
    }

    /*
     * @dev Set failed verification slash amount. Only callable by the controller owner
     * @param _failedVerificationSlashAmount % of stake slashed for failed verification
     */
    function setFailedVerificationSlashAmount(uint256 _failedVerificationSlashAmount) external onlyControllerOwner {
        // Must be a valid percentage
        require(MathUtils.validPerc(_failedVerificationSlashAmount));

        failedVerificationSlashAmount = _failedVerificationSlashAmount;

        ParameterUpdate("failedVerificationSlashAmount");
    }

    /*
     * @dev Set missed verification slash amount. Only callable by the controller owner
     * @param _missedVerificationSlashAmount % of stake slashed for missed verification
     */
    function setMissedVerificationSlashAmount(uint256 _missedVerificationSlashAmount) external onlyControllerOwner {
        // Must be a valid percentage
        require(MathUtils.validPerc(_missedVerificationSlashAmount));

        missedVerificationSlashAmount = _missedVerificationSlashAmount;

        ParameterUpdate("missedVerificationSlashAmount");
    }

    /*
     * @dev Set double claim slash amount. Only callable by the controller owner
     * @param _doubleClaimSegmentSlashAmount % of stake slashed for double claiming a segment
     */
    function setDoubleClaimSegmentSlashAmount(uint256 _doubleClaimSegmentSlashAmount) external onlyControllerOwner {
        // Must be a valid percentage
        require(MathUtils.validPerc(_doubleClaimSegmentSlashAmount));

        doubleClaimSegmentSlashAmount = _doubleClaimSegmentSlashAmount;

        ParameterUpdate("doubleClaimSegmentSlashAmount");
    }

    /*
     * @dev Set finder fee. Only callable by the controller owner
     * @param _finderFee % of slashed amount awarded to finder
     */
    function setFinderFee(uint256 _finderFee) external onlyControllerOwner {
        // Must be a valid percentage
        require(MathUtils.validPerc(_finderFee));

        finderFee = _finderFee;
    }

    /*
     * @dev Deposit ETH for jobs
     */
    function deposit() external payable whenSystemNotPaused {
        broadcasters[msg.sender].deposit = broadcasters[msg.sender].deposit.add(msg.value);
        // Transfer ETH for deposit to Minter
        minter().depositETH.value(msg.value)();

        Deposit(msg.sender, msg.value);
    }

    /*
     * @dev Withdraw deposited funds
     */
    function withdraw() external whenSystemNotPaused {
        // Can only withdraw at or after the broadcster&#39;s withdraw block
        require(broadcasters[msg.sender].withdrawBlock <= roundsManager().blockNum());

        uint256 amount = broadcasters[msg.sender].deposit;
        delete broadcasters[msg.sender];
        minter().trustedWithdrawETH(msg.sender, amount);

        Withdraw(msg.sender);
    }

    /*
     * @dev Submit a transcoding job
     * @param _streamId Unique stream identifier
     * @param _transcodingOptions Output bitrates, formats, encodings
     * @param _maxPricePerSegment Max price (in LPT base units) to pay for transcoding a segment of a stream
     * @param _endBlock Block at which this job becomes inactive
     */
    function job(string _streamId, string _transcodingOptions, uint256 _maxPricePerSegment, uint256 _endBlock)
        external
        whenSystemNotPaused
    {
        uint256 blockNum = roundsManager().blockNum();

        // End block must be in the future
        require(_endBlock > blockNum);
        // Transcoding options must be valid
        require(JobLib.validTranscodingOptions(_transcodingOptions));

        Job storage job = jobs[numJobs];
        job.jobId = numJobs;
        job.streamId = _streamId;
        job.transcodingOptions = _transcodingOptions;
        job.maxPricePerSegment = _maxPricePerSegment;
        job.broadcasterAddress = msg.sender;
        job.creationRound = roundsManager().currentRound();
        job.creationBlock = blockNum;
        job.endBlock = _endBlock;

        NewJob(
            msg.sender,
            numJobs,
            _streamId,
            _transcodingOptions,
            _maxPricePerSegment,
            blockNum
        );

        // Increment number of created jobs
        numJobs = numJobs.add(1);

        if (_endBlock > broadcasters[msg.sender].withdrawBlock) {
            // Set new withdraw block if job end block is greater than current
            // broadcaster withdraw block
            broadcasters[msg.sender].withdrawBlock = _endBlock;
        }
    }

    /*
     * @dev Submit claim for a range of segments
     * @param _jobId Job identifier
     * @param _segmentRange Range of claimed segments
     * @param _claimRoot Merkle root of transcoded segment proof data for claimed segments
     */
    function claimWork(uint256 _jobId, uint256[2] _segmentRange, bytes32 _claimRoot)
        external
        whenSystemNotPaused
        jobExists(_jobId)
    {
        Job storage job = jobs[_jobId];

        // Job cannot be inactive
        require(jobStatus(_jobId) != JobStatus.Inactive);
        // Segment range must be valid
        require(_segmentRange[1] >= _segmentRange[0]);
        // Caller must be registered transcoder
        require(bondingManager().isRegisteredTranscoder(msg.sender));

        uint256 blockNum = roundsManager().blockNum();

        if (job.transcoderAddress != address(0)) {
            // If transcoder already assigned, check if sender is
            // the assigned transcoder
            require(job.transcoderAddress == msg.sender);
        } else {
            // If transcoder is not already assigned, check if sender should be assigned
            // roundsManager.blockHash() will ensure that the job creation block has been mined and it has not
            // been more than 256 blocks since the creation block
            require(bondingManager().electActiveTranscoder(job.maxPricePerSegment, roundsManager().blockHash(job.creationBlock), job.creationRound) == msg.sender);

            job.transcoderAddress = msg.sender;
        }

        // Move fees from broadcaster deposit to escrow
        uint256 fees = JobLib.calcFees(_segmentRange[1].sub(_segmentRange[0]).add(1), job.transcodingOptions, job.maxPricePerSegment);
        broadcasters[job.broadcasterAddress].deposit = broadcasters[job.broadcasterAddress].deposit.sub(fees);
        job.escrow = job.escrow.add(fees);

        uint256 endVerificationBlock = blockNum.add(verificationPeriod);
        uint256 endVerificationSlashingBlock = endVerificationBlock.add(verificationSlashingPeriod);

        job.claims.push(
            Claim({
                claimId: job.claims.length,
                segmentRange: _segmentRange,
                claimRoot: _claimRoot,
                claimBlock: blockNum,
                endVerificationBlock: endVerificationBlock,
                endVerificationSlashingBlock: endVerificationSlashingBlock,
                status: ClaimStatus.Pending
           })
        );

        NewClaim(job.transcoderAddress, _jobId, job.claims.length - 1);
    }

    /*
     * @dev Submit transcode receipt and invoke transcoding verification
     * @param _jobId Job identifier
     * @param _segmentNumber Segment sequence number in stream
     * @param _dataStorageHash Content-addressed storage hash of segment data
     * @param _dataHashes Hash of segment data and hash of transcoded segment data
     * @param _broadcasterSig Broadcaster&#39;s signature over segment hash
     * @param _proof Merkle proof for transcode receipt
     */
    function verify(
        uint256 _jobId,
        uint256 _claimId,
        uint256 _segmentNumber,
        string _dataStorageHash,
        bytes32[2] _dataHashes,
        bytes _broadcasterSig,
        bytes _proof
    )
        external
        payable
        whenSystemNotPaused
        sufficientPayment
        jobExists(_jobId)
    {
        Job storage job = jobs[_jobId];
        Claim storage claim = job.claims[_claimId];

        // Sender must be elected transcoder
        require(job.transcoderAddress == msg.sender);

        uint256 challengeBlock = claim.claimBlock + 1;
        // Segment must be eligible for verification
        // roundsManager().blockHash() ensures that the challenge block is within the last 256 blocks from the current block
        require(JobLib.shouldVerifySegment(_segmentNumber, claim.segmentRange, challengeBlock, roundsManager().blockHash(challengeBlock), verificationRate));
        // Segment must be signed by broadcaster
        require(
            JobLib.validateBroadcasterSig(
                job.streamId,
                _segmentNumber,
                _dataHashes[0],
                _broadcasterSig,
                job.broadcasterAddress
            )
        );
        // Receipt must be valid
        require(
            JobLib.validateReceipt(
                job.streamId,
                _segmentNumber,
                _dataHashes[0],
                _dataHashes[1],
                _broadcasterSig,
                _proof,
                claim.claimRoot
           )
        );

        // Mark segment as submitted for verification
        claim.segmentVerifications[_segmentNumber] = true;

        // Invoke transcoding verification. This is async and will result in a callback to receiveVerification() which is implemented by this contract
        invokeVerification(_jobId, _claimId, _segmentNumber, _dataStorageHash, _dataHashes);

        Verify(msg.sender, _jobId, _claimId, _segmentNumber);
    }

    /*
     * @dev Invoke transcoding verification by calling the Verifier contract
     * @param _jobId Job identifier
     * @param _claimId Claim identifier
     * @param _segmentNumber Segment sequence number in stream
     * @param _dataStorageHash Content addressable storage hash of segment data
     * @param _dataHashes Hash of segment data and hash of transcoded segment data
     */
    function invokeVerification(
        uint256 _jobId,
        uint256 _claimId,
        uint256 _segmentNumber,
        string _dataStorageHash,
        bytes32[2] _dataHashes
    )
        internal
    {
        IVerifier verifierContract = verifier();

        uint256 price = verifierContract.getPrice();

        // Send payment to verifier if price is greater than zero
        if (price > 0) {
            verifierContract.verify.value(price)(
                _jobId,
                _claimId,
                _segmentNumber,
                jobs[_jobId].transcodingOptions,
                _dataStorageHash,
                _dataHashes
            );
        } else {
            // If price is 0, reject any value transfers
            require(msg.value == 0);

            verifierContract.verify(
                _jobId,
                _claimId,
                _segmentNumber,
                jobs[_jobId].transcodingOptions,
                _dataStorageHash,
                _dataHashes
            );
        }
    }

    /*
     * @dev Callback function that receives the results of transcoding verification
     * @param _jobId Job identifier
     * @param _segmentNumber Segment being verified for job
     * @param _result Boolean result of whether verification succeeded or not
     */
    function receiveVerification(uint256 _jobId, uint256 _claimId, uint256 _segmentNumber, bool _result)
        external
        whenSystemNotPaused
        onlyVerifier
        jobExists(_jobId)
    {
        Job storage job = jobs[_jobId];
        Claim storage claim = job.claims[_claimId];
        // Claim must not be slashed
        require(claim.status != ClaimStatus.Slashed);
        // Segment must have been submitted for verification
        require(claim.segmentVerifications[_segmentNumber]);

        address transcoder = job.transcoderAddress;

        if (!_result) {
            // Refund broadcaster
            refundBroadcaster(_jobId);
            // Set claim as slashed
            claim.status = ClaimStatus.Slashed;
            // Protocol slashes transcoder for failing verification (no finder)
            bondingManager().slashTranscoder(transcoder, address(0), failedVerificationSlashAmount, 0);

            FailedVerification(transcoder, _jobId, _claimId, _segmentNumber);
        } else {
            PassedVerification(transcoder, _jobId, _claimId, _segmentNumber);
        }
    }

    /*
     * @dev Distribute fees for multiple claims
     * @param _jobId Job identifier
     * @param _claimId Claim identifier
     */
    function batchDistributeFees(uint256 _jobId, uint256[] _claimIds)
        external
        whenSystemNotPaused
    {
        for (uint256 i = 0; i < _claimIds.length; i++) {
            distributeFees(_jobId, _claimIds[i]);
        }
    }

    /*
     * @dev Slash transcoder for missing verification
     * @param _jobId Job identifier
     * @param _claimId Claim identifier
     * @param _segmentNumber Segment that was not verified
     */
    function missedVerificationSlash(uint256 _jobId, uint256 _claimId, uint256 _segmentNumber)
        external
        whenSystemNotPaused
        jobExists(_jobId)
    {
        Job storage job = jobs[_jobId];
        Claim storage claim = job.claims[_claimId];

        uint256 blockNum = roundsManager().blockNum();
        uint256 challengeBlock = claim.claimBlock + 1;
        // Must be after verification period
        require(blockNum >= claim.endVerificationBlock);
        // Must be before end of slashing period
        require(blockNum < claim.endVerificationSlashingBlock);
        // Claim must be pending
        require(claim.status == ClaimStatus.Pending);
        // Segment must be eligible for verification
        // roundsManager().blockHash() ensures that the challenge block is within the last 256 blocks from the current block
        require(JobLib.shouldVerifySegment(_segmentNumber, claim.segmentRange, challengeBlock, roundsManager().blockHash(challengeBlock), verificationRate));
        // Transcoder must have missed verification for the segment
        require(!claim.segmentVerifications[_segmentNumber]);

        refundBroadcaster(_jobId);

        // Slash transcoder and provide finder params
        bondingManager().slashTranscoder(job.transcoderAddress, msg.sender, missedVerificationSlashAmount, finderFee);

        // Set claim as slashed
        claim.status = ClaimStatus.Slashed;
    }

    /*
     * @dev Slash transcoder for claiming a segment twice
     * @param _jobId Job identifier
     * @param _claimId1 Claim 1 identifier
     * @param _claimId2 Claim 2 identifier
     * @param _segmentNumber Segment that was claimed twice
     */
    function doubleClaimSegmentSlash(
        uint256 _jobId,
        uint256 _claimId1,
        uint256 _claimId2,
        uint256 _segmentNumber
    )
        external
        whenSystemNotPaused
        jobExists(_jobId)
    {
        Job storage job = jobs[_jobId];
        Claim storage claim1 = job.claims[_claimId1];
        Claim storage claim2 = job.claims[_claimId2];

        // Claim 1 must not be slashed
        require(claim1.status != ClaimStatus.Slashed);
        // Claim 2 must not be slashed
        require(claim2.status != ClaimStatus.Slashed);
        // Segment must be in claim 1 segment range
        require(_segmentNumber >= claim1.segmentRange[0] && _segmentNumber <= claim1.segmentRange[1]);
        // Segment must be in claim 2 segment range
        require(_segmentNumber >= claim2.segmentRange[0] && _segmentNumber <= claim2.segmentRange[1]);

        // Slash transcoder and provide finder params
        bondingManager().slashTranscoder(job.transcoderAddress, msg.sender, doubleClaimSegmentSlashAmount, finderFee);

        refundBroadcaster(_jobId);

        // Set claim 1 as slashed
        claim1.status = ClaimStatus.Slashed;
        // Set claim 2 as slashed
        claim2.status = ClaimStatus.Slashed;
    }

    /*
     * @dev Distribute fees for a particular claim
     * @param _jobId Job identifier
     * @param _claimId Claim identifier
     */
    function distributeFees(uint256 _jobId, uint256 _claimId)
        public
        whenSystemNotPaused
        jobExists(_jobId)
    {
        Job storage job = jobs[_jobId];
        Claim storage claim = job.claims[_claimId];

        // Sender must be elected transcoder for job
        require(job.transcoderAddress == msg.sender);
        // Claim must not be complete
        require(claim.status == ClaimStatus.Pending);
        // Slashing period must be over for claim
        require(claim.endVerificationSlashingBlock <= roundsManager().blockNum());

        uint256 fees = JobLib.calcFees(claim.segmentRange[1].sub(claim.segmentRange[0]).add(1), job.transcodingOptions, job.maxPricePerSegment);
        // Deduct fees from escrow
        job.escrow = job.escrow.sub(fees);
        // Add fees to transcoder&#39;s fee pool
        bondingManager().updateTranscoderWithFees(msg.sender, fees, job.creationRound);

        // Set claim as complete
        claim.status = ClaimStatus.Complete;

        DistributeFees(msg.sender, _jobId, _claimId, fees);
    }

    /*
     * @dev Compute status of job
     * @param _jobId Job identifier
     */
    function jobStatus(uint256 _jobId) public view returns (JobStatus) {
        if (jobs[_jobId].endBlock <= roundsManager().blockNum()) {
            // A job is inactive if the current block is greater than or equal to the job&#39;s end block
            return JobStatus.Inactive;
        } else {
            // A job is active if the current block is less than the job&#39;s end block
            return JobStatus.Active;
        }
    }

    /*
     * @dev Return job info
     * @param _jobId Job identifier
     */
    function getJob(
        uint256 _jobId
    )
        public
        view
        returns (string streamId, string transcodingOptions, uint256 maxPricePerSegment, address broadcasterAddress, address transcoderAddress, uint256 creationRound, uint256 creationBlock, uint256 endBlock, uint256 escrow, uint256 totalClaims)
    {
        Job storage job = jobs[_jobId];

        streamId = job.streamId;
        transcodingOptions = job.transcodingOptions;
        maxPricePerSegment = job.maxPricePerSegment;
        broadcasterAddress = job.broadcasterAddress;
        transcoderAddress = job.transcoderAddress;
        creationRound = job.creationRound;
        creationBlock = job.creationBlock;
        endBlock = job.endBlock;
        escrow = job.escrow;
        totalClaims = job.claims.length;
    }

    /*
     * @dev Return claim info
     * @param _jobId Job identifier
     * @param _claimId Claim identifier
     */
    function getClaim(
        uint256 _jobId,
        uint256 _claimId
    )
        public
        view
        returns (uint256[2] segmentRange, bytes32 claimRoot, uint256 claimBlock, uint256 endVerificationBlock, uint256 endVerificationSlashingBlock, ClaimStatus status)
    {
        Claim storage claim = jobs[_jobId].claims[_claimId];

        segmentRange = claim.segmentRange;
        claimRoot = claim.claimRoot;
        claimBlock = claim.claimBlock;
        endVerificationBlock = claim.endVerificationBlock;
        endVerificationSlashingBlock = claim.endVerificationSlashingBlock;
        status = claim.status;
    }

    /*
     * @dev Return whether a segment was verified for a claim
     * @param _jobId Job identifier
     * @param _claimId Claim identifier
     * @param _segmentNumber Segment number
     */
    function isClaimSegmentVerified(
        uint256 _jobId,
        uint256 _claimId,
        uint256 _segmentNumber
    )
        public
        view
        returns (bool)
    {
        return jobs[_jobId].claims[_claimId].segmentVerifications[_segmentNumber];
    }

    /*
     * @dev Refund broadcaster for a job
     * @param _jobId Job identifier
     */
    function refundBroadcaster(uint256 _jobId) internal {
        Job storage job = jobs[_jobId];

        // Return all escrowed fees for a job
        uint256 fees = job.escrow;
        job.escrow = job.escrow.sub(fees);
        broadcasters[job.broadcasterAddress].deposit = broadcasters[job.broadcasterAddress].deposit.add(fees);
        // Set end block of job to current block - job becomes inactive
        job.endBlock = roundsManager().blockNum();
    }

    /*
     * @dev Returns Minter
     */
    function minter() internal view returns (IMinter) {
        return IMinter(controller.getContract(keccak256("Minter")));
    }

    /*
     * @dev Returns BondingManager
     */
    function bondingManager() internal view returns (IBondingManager) {
        return IBondingManager(controller.getContract(keccak256("BondingManager")));
    }

    /*
     * @dev Returns RoundsManager
     */
    function roundsManager() internal view returns (IRoundsManager) {
        return IRoundsManager(controller.getContract(keccak256("RoundsManager")));
    }

    /*
     * @dev Returns Verifier
     */
    function verifier() internal view returns (IVerifier) {
        return IVerifier(controller.getContract(keccak256("Verifier")));
    }
}