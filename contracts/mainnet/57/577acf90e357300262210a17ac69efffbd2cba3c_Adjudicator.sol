// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

import "./ReEncryptionValidator.sol";
import "./SignatureVerifier.sol";
import "./StakingEscrow.sol";
import "./Upgradeable.sol";
import "./SafeMath.sol";
import "./Math.sol";


/**
* @notice Supervises stakers' behavior and punishes when something's wrong.
* @dev |v2.1.2|
*/
contract Adjudicator is Upgradeable {

    using SafeMath for uint256;
    using UmbralDeserializer for bytes;

    event CFragEvaluated(
        bytes32 indexed evaluationHash,
        address indexed investigator,
        bool correctness
    );
    event IncorrectCFragVerdict(
        bytes32 indexed evaluationHash,
        address indexed worker,
        address indexed staker
    );

    // used only for upgrading
    bytes32 constant RESERVED_CAPSULE_AND_CFRAG_BYTES = bytes32(0);
    address constant RESERVED_ADDRESS = address(0);

    StakingEscrow public immutable escrow;
    SignatureVerifier.HashAlgorithm public immutable hashAlgorithm;
    uint256 public immutable basePenalty;
    uint256 public immutable penaltyHistoryCoefficient;
    uint256 public immutable percentagePenaltyCoefficient;
    uint256 public immutable rewardCoefficient;

    mapping (address => uint256) public penaltyHistory;
    mapping (bytes32 => bool) public evaluatedCFrags;

    /**
    * @param _escrow Escrow contract
    * @param _hashAlgorithm Hashing algorithm
    * @param _basePenalty Base for the penalty calculation
    * @param _penaltyHistoryCoefficient Coefficient for calculating the penalty depending on the history
    * @param _percentagePenaltyCoefficient Coefficient for calculating the percentage penalty
    * @param _rewardCoefficient Coefficient for calculating the reward
    */
    constructor(
        StakingEscrow _escrow,
        SignatureVerifier.HashAlgorithm _hashAlgorithm,
        uint256 _basePenalty,
        uint256 _penaltyHistoryCoefficient,
        uint256 _percentagePenaltyCoefficient,
        uint256 _rewardCoefficient
    ) {
        // Sanity checks.
        require(_escrow.secondsPerPeriod() > 0 &&  // This contract has an escrow, and it's not the null address.
            // The reward and penalty coefficients are set.
            _percentagePenaltyCoefficient != 0 &&
            _rewardCoefficient != 0);
        escrow = _escrow;
        hashAlgorithm = _hashAlgorithm;
        basePenalty = _basePenalty;
        percentagePenaltyCoefficient = _percentagePenaltyCoefficient;
        penaltyHistoryCoefficient = _penaltyHistoryCoefficient;
        rewardCoefficient = _rewardCoefficient;
    }

    /**
    * @notice Submit proof that a worker created wrong CFrag
    * @param _capsuleBytes Serialized capsule
    * @param _cFragBytes Serialized CFrag
    * @param _cFragSignature Signature of CFrag by worker
    * @param _taskSignature Signature of task specification by Bob
    * @param _requesterPublicKey Bob's signing public key, also known as "stamp"
    * @param _workerPublicKey Worker's signing public key, also known as "stamp"
    * @param _workerIdentityEvidence Signature of worker's public key by worker's eth-key
    * @param _preComputedData Additional pre-computed data for CFrag correctness verification
    */
    function evaluateCFrag(
        bytes memory _capsuleBytes,
        bytes memory _cFragBytes,
        bytes memory _cFragSignature,
        bytes memory _taskSignature,
        bytes memory _requesterPublicKey,
        bytes memory _workerPublicKey,
        bytes memory _workerIdentityEvidence,
        bytes memory _preComputedData
    )
        public
    {
        // 1. Check that CFrag is not evaluated yet
        bytes32 evaluationHash = SignatureVerifier.hash(
            abi.encodePacked(_capsuleBytes, _cFragBytes), hashAlgorithm);
        require(!evaluatedCFrags[evaluationHash], "This CFrag has already been evaluated.");
        evaluatedCFrags[evaluationHash] = true;

        // 2. Verify correctness of re-encryption
        bool cFragIsCorrect = ReEncryptionValidator.validateCFrag(_capsuleBytes, _cFragBytes, _preComputedData);
        emit CFragEvaluated(evaluationHash, msg.sender, cFragIsCorrect);

        // 3. Verify associated public keys and signatures
        require(ReEncryptionValidator.checkSerializedCoordinates(_workerPublicKey),
                "Staker's public key is invalid");
        require(ReEncryptionValidator.checkSerializedCoordinates(_requesterPublicKey),
                "Requester's public key is invalid");

        UmbralDeserializer.PreComputedData memory precomp = _preComputedData.toPreComputedData();

        // Verify worker's signature of CFrag
        require(SignatureVerifier.verify(
                _cFragBytes,
                abi.encodePacked(_cFragSignature, precomp.lostBytes[1]),
                _workerPublicKey,
                hashAlgorithm),
                "CFrag signature is invalid"
        );

        // Verify worker's signature of taskSignature and that it corresponds to cfrag.proof.metadata
        UmbralDeserializer.CapsuleFrag memory cFrag = _cFragBytes.toCapsuleFrag();
        require(SignatureVerifier.verify(
                _taskSignature,
                abi.encodePacked(cFrag.proof.metadata, precomp.lostBytes[2]),
                _workerPublicKey,
                hashAlgorithm),
                "Task signature is invalid"
        );

        // Verify that _taskSignature is bob's signature of the task specification.
        // A task specification is: capsule + ursula pubkey + alice address + blockhash
        bytes32 stampXCoord;
        assembly {
            stampXCoord := mload(add(_workerPublicKey, 32))
        }
        bytes memory stamp = abi.encodePacked(precomp.lostBytes[4], stampXCoord);

        require(SignatureVerifier.verify(
                abi.encodePacked(_capsuleBytes,
                                 stamp,
                                 _workerIdentityEvidence,
                                 precomp.alicesKeyAsAddress,
                                 bytes32(0)),
                abi.encodePacked(_taskSignature, precomp.lostBytes[3]),
                _requesterPublicKey,
                hashAlgorithm),
                "Specification signature is invalid"
        );

        // 4. Extract worker address from stamp signature.
        address worker = SignatureVerifier.recover(
            SignatureVerifier.hashEIP191(stamp, byte(0x45)), // Currently, we use version E (0x45) of EIP191 signatures
            _workerIdentityEvidence);
        address staker = escrow.stakerFromWorker(worker);
        require(staker != address(0), "Worker must be related to a staker");

        // 5. Check that staker can be slashed
        uint256 stakerValue = escrow.getAllTokens(staker);
        require(stakerValue > 0, "Staker has no tokens");

        // 6. If CFrag was incorrect, slash staker
        if (!cFragIsCorrect) {
            (uint256 penalty, uint256 reward) = calculatePenaltyAndReward(staker, stakerValue);
            escrow.slashStaker(staker, penalty, msg.sender, reward);
            emit IncorrectCFragVerdict(evaluationHash, worker, staker);
        }
    }

    /**
    * @notice Calculate penalty to the staker and reward to the investigator
    * @param _staker Staker's address
    * @param _stakerValue Amount of tokens that belong to the staker
    */
    function calculatePenaltyAndReward(address _staker, uint256 _stakerValue)
        internal returns (uint256 penalty, uint256 reward)
    {
        penalty = basePenalty.add(penaltyHistoryCoefficient.mul(penaltyHistory[_staker]));
        penalty = Math.min(penalty, _stakerValue.div(percentagePenaltyCoefficient));
        reward = penalty.div(rewardCoefficient);
        // TODO add maximum condition or other overflow protection or other penalty condition (#305?)
        penaltyHistory[_staker] = penaltyHistory[_staker].add(1);
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `verifyState`
    function verifyState(address _testTarget) public override virtual {
        super.verifyState(_testTarget);
        bytes32 evaluationCFragHash = SignatureVerifier.hash(
            abi.encodePacked(RESERVED_CAPSULE_AND_CFRAG_BYTES), SignatureVerifier.HashAlgorithm.SHA256);
        require(delegateGet(_testTarget, this.evaluatedCFrags.selector, evaluationCFragHash) ==
            (evaluatedCFrags[evaluationCFragHash] ? 1 : 0));
        require(delegateGet(_testTarget, this.penaltyHistory.selector, bytes32(bytes20(RESERVED_ADDRESS))) ==
            penaltyHistory[RESERVED_ADDRESS]);
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `finishUpgrade`
    function finishUpgrade(address _target) public override virtual {
        super.finishUpgrade(_target);
        // preparation for the verifyState method
        bytes32 evaluationCFragHash = SignatureVerifier.hash(
            abi.encodePacked(RESERVED_CAPSULE_AND_CFRAG_BYTES), SignatureVerifier.HashAlgorithm.SHA256);
        evaluatedCFrags[evaluationCFragHash] = true;
        penaltyHistory[RESERVED_ADDRESS] = 123;
    }
}
