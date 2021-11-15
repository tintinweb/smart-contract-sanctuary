// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

import "./lib/ReEncryptionValidator.sol";
import "./lib/SignatureVerifier.sol";
import "./StakingEscrow.sol";
import "./proxy/Upgradeable.sol";
import "../zeppelin/math/SafeMath.sol";
import "../zeppelin/math/Math.sol";


/**
* @title Adjudicator
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

import "./UmbralDeserializer.sol";
import "./SignatureVerifier.sol";

/**
* @notice Validates re-encryption correctness.
*/
library ReEncryptionValidator {

    using UmbralDeserializer for bytes;


    //------------------------------//
    //   Umbral-specific constants  //
    //------------------------------//

    // See parameter `u` of `UmbralParameters` class in pyUmbral
    // https://github.com/nucypher/pyUmbral/blob/master/umbral/params.py
    uint8 public constant UMBRAL_PARAMETER_U_SIGN = 0x02;
    uint256 public constant UMBRAL_PARAMETER_U_XCOORD = 0x03c98795773ff1c241fc0b1cced85e80f8366581dda5c9452175ebd41385fa1f;
    uint256 public constant UMBRAL_PARAMETER_U_YCOORD = 0x7880ed56962d7c0ae44d6f14bb53b5fe64b31ea44a41d0316f3a598778f0f936;


    //------------------------------//
    // SECP256K1-specific constants //
    //------------------------------//

    // Base field order
    uint256 constant FIELD_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // -2 mod FIELD_ORDER
    uint256 constant MINUS_2 = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2d;

    // (-1/2) mod FIELD_ORDER
    uint256 constant MINUS_ONE_HALF = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffff7ffffe17;


    //

    /**
    * @notice Check correctness of re-encryption
    * @param _capsuleBytes Capsule
    * @param _cFragBytes Capsule frag
    * @param _precomputedBytes Additional precomputed data
    */
    function validateCFrag(
        bytes memory _capsuleBytes,
        bytes memory _cFragBytes,
        bytes memory _precomputedBytes
    )
        internal pure returns (bool)
    {
        UmbralDeserializer.Capsule memory _capsule = _capsuleBytes.toCapsule();
        UmbralDeserializer.CapsuleFrag memory _cFrag = _cFragBytes.toCapsuleFrag();
        UmbralDeserializer.PreComputedData memory _precomputed = _precomputedBytes.toPreComputedData();

        // Extract Alice's address and check that it corresponds to the one provided
        address alicesAddress = SignatureVerifier.recover(
            _precomputed.hashedKFragValidityMessage,
            abi.encodePacked(_cFrag.proof.kFragSignature, _precomputed.lostBytes[0])
        );
        require(alicesAddress == _precomputed.alicesKeyAsAddress, "Bad KFrag signature");

        // Compute proof's challenge scalar h, used in all ZKP verification equations
        uint256 h = computeProofChallengeScalar(_capsule, _cFrag);

        //////
        // Verifying 1st equation: z*E == h*E_1 + E_2
        //////

        // Input validation: E
        require(checkCompressedPoint(
            _capsule.pointE.sign,
            _capsule.pointE.xCoord,
            _precomputed.pointEyCoord),
            "Precomputed Y coordinate of E doesn't correspond to compressed E point"
        );

        // Input validation: z*E
        require(isOnCurve(_precomputed.pointEZxCoord, _precomputed.pointEZyCoord),
                "Point zE is not a valid EC point"
        );
        require(ecmulVerify(
            _capsule.pointE.xCoord,         // E_x
            _precomputed.pointEyCoord,      // E_y
            _cFrag.proof.bnSig,             // z
            _precomputed.pointEZxCoord,     // zE_x
            _precomputed.pointEZyCoord),    // zE_y
            "Precomputed z*E value is incorrect"
        );

        // Input validation: E1
        require(checkCompressedPoint(
            _cFrag.pointE1.sign,          // E1_sign
            _cFrag.pointE1.xCoord,        // E1_x
            _precomputed.pointE1yCoord),  // E1_y
            "Precomputed Y coordinate of E1 doesn't correspond to compressed E1 point"
        );

        // Input validation: h*E1
        require(isOnCurve(_precomputed.pointE1HxCoord, _precomputed.pointE1HyCoord),
                "Point h*E1 is not a valid EC point"
        );
        require(ecmulVerify(
            _cFrag.pointE1.xCoord,          // E1_x
            _precomputed.pointE1yCoord,     // E1_y
            h,
            _precomputed.pointE1HxCoord,    // hE1_x
            _precomputed.pointE1HyCoord),   // hE1_y
            "Precomputed h*E1 value is incorrect"
        );

        // Input validation: E2
        require(checkCompressedPoint(
            _cFrag.proof.pointE2.sign,        // E2_sign
            _cFrag.proof.pointE2.xCoord,      // E2_x
            _precomputed.pointE2yCoord),      // E2_y
            "Precomputed Y coordinate of E2 doesn't correspond to compressed E2 point"
        );

        bool equation_holds = eqAffineJacobian(
            [_precomputed.pointEZxCoord,  _precomputed.pointEZyCoord],
            addAffineJacobian(
                [_cFrag.proof.pointE2.xCoord, _precomputed.pointE2yCoord],
                [_precomputed.pointE1HxCoord, _precomputed.pointE1HyCoord]
            )
        );

        if (!equation_holds){
            return false;
        }

        //////
        // Verifying 2nd equation: z*V == h*V_1 + V_2
        //////

        // Input validation: V
        require(checkCompressedPoint(
            _capsule.pointV.sign,
            _capsule.pointV.xCoord,
            _precomputed.pointVyCoord),
            "Precomputed Y coordinate of V doesn't correspond to compressed V point"
        );

        // Input validation: z*V
        require(isOnCurve(_precomputed.pointVZxCoord, _precomputed.pointVZyCoord),
                "Point zV is not a valid EC point"
        );
        require(ecmulVerify(
            _capsule.pointV.xCoord,         // V_x
            _precomputed.pointVyCoord,      // V_y
            _cFrag.proof.bnSig,             // z
            _precomputed.pointVZxCoord,     // zV_x
            _precomputed.pointVZyCoord),    // zV_y
            "Precomputed z*V value is incorrect"
        );

        // Input validation: V1
        require(checkCompressedPoint(
            _cFrag.pointV1.sign,         // V1_sign
            _cFrag.pointV1.xCoord,       // V1_x
            _precomputed.pointV1yCoord), // V1_y
            "Precomputed Y coordinate of V1 doesn't correspond to compressed V1 point"
        );

        // Input validation: h*V1
        require(isOnCurve(_precomputed.pointV1HxCoord, _precomputed.pointV1HyCoord),
            "Point h*V1 is not a valid EC point"
        );
        require(ecmulVerify(
            _cFrag.pointV1.xCoord,          // V1_x
            _precomputed.pointV1yCoord,     // V1_y
            h,
            _precomputed.pointV1HxCoord,    // h*V1_x
            _precomputed.pointV1HyCoord),   // h*V1_y
            "Precomputed h*V1 value is incorrect"
        );

        // Input validation: V2
        require(checkCompressedPoint(
            _cFrag.proof.pointV2.sign,        // V2_sign
            _cFrag.proof.pointV2.xCoord,      // V2_x
            _precomputed.pointV2yCoord),      // V2_y
            "Precomputed Y coordinate of V2 doesn't correspond to compressed V2 point"
        );

        equation_holds = eqAffineJacobian(
            [_precomputed.pointVZxCoord,  _precomputed.pointVZyCoord],
            addAffineJacobian(
                [_cFrag.proof.pointV2.xCoord, _precomputed.pointV2yCoord],
                [_precomputed.pointV1HxCoord, _precomputed.pointV1HyCoord]
            )
        );

        if (!equation_holds){
            return false;
        }

        //////
        // Verifying 3rd equation: z*U == h*U_1 + U_2
        //////

        // We don't have to validate U since it's fixed and hard-coded

        // Input validation: z*U
        require(isOnCurve(_precomputed.pointUZxCoord, _precomputed.pointUZyCoord),
                "Point z*U is not a valid EC point"
        );
        require(ecmulVerify(
            UMBRAL_PARAMETER_U_XCOORD,      // U_x
            UMBRAL_PARAMETER_U_YCOORD,      // U_y
            _cFrag.proof.bnSig,             // z
            _precomputed.pointUZxCoord,     // zU_x
            _precomputed.pointUZyCoord),    // zU_y
            "Precomputed z*U value is incorrect"
        );

        // Input validation: U1  (a.k.a. KFragCommitment)
        require(checkCompressedPoint(
            _cFrag.proof.pointKFragCommitment.sign,     // U1_sign
            _cFrag.proof.pointKFragCommitment.xCoord,   // U1_x
            _precomputed.pointU1yCoord),                // U1_y
            "Precomputed Y coordinate of U1 doesn't correspond to compressed U1 point"
        );

        // Input validation: h*U1
        require(isOnCurve(_precomputed.pointU1HxCoord, _precomputed.pointU1HyCoord),
                "Point h*U1 is not a valid EC point"
        );
        require(ecmulVerify(
            _cFrag.proof.pointKFragCommitment.xCoord,   // U1_x
            _precomputed.pointU1yCoord,                 // U1_y
            h,
            _precomputed.pointU1HxCoord,    // h*V1_x
            _precomputed.pointU1HyCoord),   // h*V1_y
            "Precomputed h*V1 value is incorrect"
        );

        // Input validation: U2  (a.k.a. KFragPok ("proof of knowledge"))
        require(checkCompressedPoint(
            _cFrag.proof.pointKFragPok.sign,    // U2_sign
            _cFrag.proof.pointKFragPok.xCoord,  // U2_x
            _precomputed.pointU2yCoord),        // U2_y
            "Precomputed Y coordinate of U2 doesn't correspond to compressed U2 point"
        );

        equation_holds = eqAffineJacobian(
            [_precomputed.pointUZxCoord,  _precomputed.pointUZyCoord],
            addAffineJacobian(
                [_cFrag.proof.pointKFragPok.xCoord, _precomputed.pointU2yCoord],
                [_precomputed.pointU1HxCoord, _precomputed.pointU1HyCoord]
            )
        );

        return equation_holds;
    }

    function computeProofChallengeScalar(
        UmbralDeserializer.Capsule memory _capsule,
        UmbralDeserializer.CapsuleFrag memory _cFrag
    ) internal pure returns (uint256) {

        // Compute h = hash_to_bignum(e, e1, e2, v, v1, v2, u, u1, u2, metadata)
        bytes memory hashInput = abi.encodePacked(
            // Point E
            _capsule.pointE.sign,
            _capsule.pointE.xCoord,
            // Point E1
            _cFrag.pointE1.sign,
            _cFrag.pointE1.xCoord,
            // Point E2
            _cFrag.proof.pointE2.sign,
            _cFrag.proof.pointE2.xCoord
        );

        hashInput = abi.encodePacked(
            hashInput,
            // Point V
            _capsule.pointV.sign,
            _capsule.pointV.xCoord,
            // Point V1
            _cFrag.pointV1.sign,
            _cFrag.pointV1.xCoord,
            // Point V2
            _cFrag.proof.pointV2.sign,
            _cFrag.proof.pointV2.xCoord
        );

        hashInput = abi.encodePacked(
            hashInput,
            // Point U
            bytes1(UMBRAL_PARAMETER_U_SIGN),
            bytes32(UMBRAL_PARAMETER_U_XCOORD),
            // Point U1
            _cFrag.proof.pointKFragCommitment.sign,
            _cFrag.proof.pointKFragCommitment.xCoord,
            // Point U2
            _cFrag.proof.pointKFragPok.sign,
            _cFrag.proof.pointKFragPok.xCoord,
            // Re-encryption metadata
            _cFrag.proof.metadata
        );

        uint256 h = extendedKeccakToBN(hashInput);
        return h;

    }

    function extendedKeccakToBN (bytes memory _data) internal pure returns (uint256) {

        bytes32 upper;
        bytes32 lower;

        // Umbral prepends to the data a customization string of 64-bytes.
        // In the case of hash_to_curvebn is 'hash_to_curvebn', padded with zeroes.
        bytes memory input = abi.encodePacked(bytes32("hash_to_curvebn"), bytes32(0x00), _data);

        (upper, lower) = (keccak256(abi.encodePacked(uint8(0x00), input)),
                          keccak256(abi.encodePacked(uint8(0x01), input)));

        // Let n be the order of secp256k1's group (n = 2^256 - 0x1000003D1)
        // n_minus_1 = n - 1
        // delta = 2^256 mod n_minus_1
        uint256 delta = 0x14551231950b75fc4402da1732fc9bec0;
        uint256 n_minus_1 = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140;

        uint256 upper_half = mulmod(uint256(upper), delta, n_minus_1);
        return 1 + addmod(upper_half, uint256(lower), n_minus_1);
    }

    /// @notice Tests if a compressed point is valid, wrt to its corresponding Y coordinate
    /// @param _pointSign The sign byte from the compressed notation: 0x02 if the Y coord is even; 0x03 otherwise
    /// @param _pointX The X coordinate of an EC point in affine representation
    /// @param _pointY The Y coordinate of an EC point in affine representation
    /// @return true iff _pointSign and _pointX are the compressed representation of (_pointX, _pointY)
	function checkCompressedPoint(
		uint8 _pointSign,
		uint256 _pointX,
		uint256 _pointY
	) internal pure returns(bool) {
		bool correct_sign = _pointY % 2 == _pointSign - 2;
		return correct_sign && isOnCurve(_pointX, _pointY);
	}

    /// @notice Tests if the given serialized coordinates represent a valid EC point
    /// @param _coords The concatenation of serialized X and Y coordinates
    /// @return true iff coordinates X and Y are a valid point
    function checkSerializedCoordinates(bytes memory _coords) internal pure returns(bool) {
        require(_coords.length == 64, "Serialized coordinates should be 64 B");
        uint256 coordX;
        uint256 coordY;
        assembly {
            coordX := mload(add(_coords, 32))
            coordY := mload(add(_coords, 64))
        }
		return isOnCurve(coordX, coordY);
	}

    /// @notice Tests if a point is on the secp256k1 curve
    /// @param Px The X coordinate of an EC point in affine representation
    /// @param Py The Y coordinate of an EC point in affine representation
    /// @return true if (Px, Py) is a valid secp256k1 point; false otherwise
    function isOnCurve(uint256 Px, uint256 Py) internal pure returns (bool) {
        uint256 p = FIELD_ORDER;

        if (Px >= p || Py >= p){
            return false;
        }

        uint256 y2 = mulmod(Py, Py, p);
        uint256 x3_plus_7 = addmod(mulmod(mulmod(Px, Px, p), Px, p), 7, p);
        return y2 == x3_plus_7;
    }

    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/4
    function ecmulVerify(
    	uint256 x1,
    	uint256 y1,
    	uint256 scalar,
    	uint256 qx,
    	uint256 qy
    ) internal pure returns(bool) {
	    uint256 curve_order = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
	    address signer = ecrecover(0, uint8(27 + (y1 % 2)), bytes32(x1), bytes32(mulmod(scalar, x1, curve_order)));
	    address xyAddress = address(uint256(keccak256(abi.encodePacked(qx, qy))) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
	    return xyAddress == signer;
	}

    /// @notice Equality test of two points, in affine and Jacobian coordinates respectively
    /// @param P An EC point in affine coordinates
    /// @param Q An EC point in Jacobian coordinates
    /// @return true if P and Q represent the same point in affine coordinates; false otherwise
    function eqAffineJacobian(
    	uint256[2] memory P,
    	uint256[3] memory Q
    ) internal pure returns(bool){
        uint256 Qz = Q[2];
        if(Qz == 0){
            return false;       // Q is zero but P isn't.
        }

        uint256 p = FIELD_ORDER;
        uint256 Q_z_squared = mulmod(Qz, Qz, p);
        return mulmod(P[0], Q_z_squared, p) == Q[0] && mulmod(P[1], mulmod(Q_z_squared, Qz, p), p) == Q[1];

    }

    /// @notice Adds two points in affine coordinates, with the result in Jacobian
    /// @dev Based on the addition formulas from http://www.hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/addition/add-2001-b.op3
    /// @param P An EC point in affine coordinates
    /// @param Q An EC point in affine coordinates
    /// @return R An EC point in Jacobian coordinates with the sum, represented by an array of 3 uint256
    function addAffineJacobian(
    	uint[2] memory P,
    	uint[2] memory Q
    ) internal pure returns (uint[3] memory R) {

        uint256 p = FIELD_ORDER;
        uint256 a   = P[0];
        uint256 c   = P[1];
        uint256 t0  = Q[0];
        uint256 t1  = Q[1];

        if ((a == t0) && (c == t1)){
            return doubleJacobian([a, c, 1]);
        }
        uint256 d = addmod(t1, p-c, p); // d = t1 - c
        uint256 b = addmod(t0, p-a, p); // b = t0 - a
        uint256 e = mulmod(b, b, p); // e = b^2
        uint256 f = mulmod(e, b, p);  // f = b^3
        uint256 g = mulmod(a, e, p);
        R[0] = addmod(mulmod(d, d, p), p-addmod(mulmod(2, g, p), f, p), p);
        R[1] = addmod(mulmod(d, addmod(g, p-R[0], p), p), p-mulmod(c, f, p), p);
        R[2] = b;
    }

    /// @notice Point doubling in Jacobian coordinates
    /// @param P An EC point in Jacobian coordinates.
    /// @return Q An EC point in Jacobian coordinates
    function doubleJacobian(uint[3] memory P) internal pure returns (uint[3] memory Q) {
        uint256 z = P[2];
        if (z == 0)
            return Q;
        uint256 p = FIELD_ORDER;
        uint256 x = P[0];
        uint256 _2y = mulmod(2, P[1], p);
        uint256 _4yy = mulmod(_2y, _2y, p);
        uint256 s = mulmod(_4yy, x, p);
        uint256 m = mulmod(3, mulmod(x, x, p), p);
        uint256 t = addmod(mulmod(m, m, p), mulmod(MINUS_2, s, p),p);
        Q[0] = t;
        Q[1] = addmod(mulmod(m, addmod(s, p - t, p), p), mulmod(MINUS_ONE_HALF, mulmod(_4yy, _4yy, p), p), p);
        Q[2] = mulmod(_2y, z, p);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


/**
* @notice Deserialization library for Umbral objects
*/
library UmbralDeserializer {

    struct Point {
        uint8 sign;
        uint256 xCoord;
    }

    struct Capsule {
        Point pointE;
        Point pointV;
        uint256 bnSig;
    }

    struct CorrectnessProof {
        Point pointE2;
        Point pointV2;
        Point pointKFragCommitment;
        Point pointKFragPok;
        uint256 bnSig;
        bytes kFragSignature; // 64 bytes
        bytes metadata; // any length
    }

    struct CapsuleFrag {
        Point pointE1;
        Point pointV1;
        bytes32 kFragId;
        Point pointPrecursor;
        CorrectnessProof proof;
    }

    struct PreComputedData {
        uint256 pointEyCoord;
        uint256 pointEZxCoord;
        uint256 pointEZyCoord;
        uint256 pointE1yCoord;
        uint256 pointE1HxCoord;
        uint256 pointE1HyCoord;
        uint256 pointE2yCoord;
        uint256 pointVyCoord;
        uint256 pointVZxCoord;
        uint256 pointVZyCoord;
        uint256 pointV1yCoord;
        uint256 pointV1HxCoord;
        uint256 pointV1HyCoord;
        uint256 pointV2yCoord;
        uint256 pointUZxCoord;
        uint256 pointUZyCoord;
        uint256 pointU1yCoord;
        uint256 pointU1HxCoord;
        uint256 pointU1HyCoord;
        uint256 pointU2yCoord;
        bytes32 hashedKFragValidityMessage;
        address alicesKeyAsAddress;
        bytes5  lostBytes;
    }

    uint256 constant BIGNUM_SIZE = 32;
    uint256 constant POINT_SIZE = 33;
    uint256 constant SIGNATURE_SIZE = 64;
    uint256 constant CAPSULE_SIZE = 2 * POINT_SIZE + BIGNUM_SIZE;
    uint256 constant CORRECTNESS_PROOF_SIZE = 4 * POINT_SIZE + BIGNUM_SIZE + SIGNATURE_SIZE;
    uint256 constant CAPSULE_FRAG_SIZE = 3 * POINT_SIZE + BIGNUM_SIZE;
    uint256 constant FULL_CAPSULE_FRAG_SIZE = CAPSULE_FRAG_SIZE + CORRECTNESS_PROOF_SIZE;
    uint256 constant PRECOMPUTED_DATA_SIZE = (20 * BIGNUM_SIZE) + 32 + 20 + 5;

    /**
    * @notice Deserialize to capsule (not activated)
    */
    function toCapsule(bytes memory _capsuleBytes)
        internal pure returns (Capsule memory capsule)
    {
        require(_capsuleBytes.length == CAPSULE_SIZE);
        uint256 pointer = getPointer(_capsuleBytes);
        pointer = copyPoint(pointer, capsule.pointE);
        pointer = copyPoint(pointer, capsule.pointV);
        capsule.bnSig = uint256(getBytes32(pointer));
    }

    /**
    * @notice Deserialize to correctness proof
    * @param _pointer Proof bytes memory pointer
    * @param _proofBytesLength Proof bytes length
    */
    function toCorrectnessProof(uint256 _pointer, uint256 _proofBytesLength)
        internal pure returns (CorrectnessProof memory proof)
    {
        require(_proofBytesLength >= CORRECTNESS_PROOF_SIZE);

        _pointer = copyPoint(_pointer, proof.pointE2);
        _pointer = copyPoint(_pointer, proof.pointV2);
        _pointer = copyPoint(_pointer, proof.pointKFragCommitment);
        _pointer = copyPoint(_pointer, proof.pointKFragPok);
        proof.bnSig = uint256(getBytes32(_pointer));
        _pointer += BIGNUM_SIZE;

        proof.kFragSignature = new bytes(SIGNATURE_SIZE);
        // TODO optimize, just two mload->mstore (#1500)
        _pointer = copyBytes(_pointer, proof.kFragSignature, SIGNATURE_SIZE);
        if (_proofBytesLength > CORRECTNESS_PROOF_SIZE) {
            proof.metadata = new bytes(_proofBytesLength - CORRECTNESS_PROOF_SIZE);
            copyBytes(_pointer, proof.metadata, proof.metadata.length);
        }
    }

    /**
    * @notice Deserialize to correctness proof
    */
    function toCorrectnessProof(bytes memory _proofBytes)
        internal pure returns (CorrectnessProof memory proof)
    {
        uint256 pointer = getPointer(_proofBytes);
        return toCorrectnessProof(pointer, _proofBytes.length);
    }

    /**
    * @notice Deserialize to CapsuleFrag
    */
    function toCapsuleFrag(bytes memory _cFragBytes)
        internal pure returns (CapsuleFrag memory cFrag)
    {
        uint256 cFragBytesLength = _cFragBytes.length;
        require(cFragBytesLength >= FULL_CAPSULE_FRAG_SIZE);

        uint256 pointer = getPointer(_cFragBytes);
        pointer = copyPoint(pointer, cFrag.pointE1);
        pointer = copyPoint(pointer, cFrag.pointV1);
        cFrag.kFragId = getBytes32(pointer);
        pointer += BIGNUM_SIZE;
        pointer = copyPoint(pointer, cFrag.pointPrecursor);

        cFrag.proof = toCorrectnessProof(pointer, cFragBytesLength - CAPSULE_FRAG_SIZE);
    }

    /**
    * @notice Deserialize to precomputed data
    */
    function toPreComputedData(bytes memory _preComputedData)
        internal pure returns (PreComputedData memory data)
    {
        require(_preComputedData.length == PRECOMPUTED_DATA_SIZE);
        uint256 initial_pointer = getPointer(_preComputedData);
        uint256 pointer = initial_pointer;

        data.pointEyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointEZxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointEZyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointE1yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointE1HxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointE1HyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointE2yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointVyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointVZxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointVZyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointV1yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointV1HxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointV1HyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointV2yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointUZxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointUZyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointU1yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointU1HxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointU1HyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointU2yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.hashedKFragValidityMessage = getBytes32(pointer);
        pointer += 32;

        data.alicesKeyAsAddress = address(bytes20(getBytes32(pointer)));
        pointer += 20;

        // Lost bytes: a bytes5 variable holding the following byte values:
        //     0: kfrag signature recovery value v
        //     1: cfrag signature recovery value v
        //     2: metadata signature recovery value v
        //     3: specification signature recovery value v
        //     4: ursula pubkey sign byte
        data.lostBytes = bytes5(getBytes32(pointer));
        pointer += 5;

        require(pointer == initial_pointer + PRECOMPUTED_DATA_SIZE);
    }

    // TODO extract to external library if needed (#1500)
    /**
    * @notice Get the memory pointer for start of array
    */
    function getPointer(bytes memory _bytes) internal pure returns (uint256 pointer) {
        assembly {
            pointer := add(_bytes, 32) // skip array length
        }
    }

    /**
    * @notice Copy point data from memory in the pointer position
    */
    function copyPoint(uint256 _pointer, Point memory _point)
        internal pure returns (uint256 resultPointer)
    {
        // TODO optimize, copy to point memory directly (#1500)
        uint8 temp;
        uint256 xCoord;
        assembly {
            temp := byte(0, mload(_pointer))
            xCoord := mload(add(_pointer, 1))
        }
        _point.sign = temp;
        _point.xCoord = xCoord;
        resultPointer = _pointer + POINT_SIZE;
    }

    /**
    * @notice Read 1 byte from memory in the pointer position
    */
    function getByte(uint256 _pointer) internal pure returns (byte result) {
        bytes32 word;
        assembly {
            word := mload(_pointer)
        }
        result = word[0];
        return result;
    }

    /**
    * @notice Read 32 bytes from memory in the pointer position
    */
    function getBytes32(uint256 _pointer) internal pure returns (bytes32 result) {
        assembly {
            result := mload(_pointer)
        }
    }

    /**
    * @notice Copy bytes from the source pointer to the target array
    * @dev Assumes that enough memory has been allocated to store in target.
    * Also assumes that '_target' was the last thing that was allocated
    * @param _bytesPointer Source memory pointer
    * @param _target Target array
    * @param _bytesLength Number of bytes to copy
    */
    function copyBytes(uint256 _bytesPointer, bytes memory _target, uint256 _bytesLength)
        internal
        pure
        returns (uint256 resultPointer)
    {
        // Exploiting the fact that '_target' was the last thing to be allocated,
        // we can write entire words, and just overwrite any excess.
        assembly {
            // evm operations on words
            let words := div(add(_bytesLength, 31), 32)
            let source := _bytesPointer
            let destination := add(_target, 32)
            for
                { let i := 0 } // start at arr + 32 -> first byte corresponds to length
                lt(i, words)
                { i := add(i, 1) }
            {
                let offset := mul(i, 32)
                mstore(add(destination, offset), mload(add(source, offset)))
            }
            mstore(add(_target, add(32, mload(_target))), 0)
        }
        resultPointer = _bytesPointer + _bytesLength;
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


/**
* @notice Library to recover address and verify signatures
* @dev Simple wrapper for `ecrecover`
*/
library SignatureVerifier {

    enum HashAlgorithm {KECCAK256, SHA256, RIPEMD160}

    // Header for Version E as defined by EIP191. First byte ('E') is also the version
    bytes25 constant EIP191_VERSION_E_HEADER = "Ethereum Signed Message:\n";

    /**
    * @notice Recover signer address from hash and signature
    * @param _hash 32 bytes message hash
    * @param _signature Signature of hash - 32 bytes r + 32 bytes s + 1 byte v (could be 0, 1, 27, 28)
    */
    function recover(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28);
        return ecrecover(_hash, v, r, s);
    }

    /**
    * @notice Transform public key to address
    * @param _publicKey secp256k1 public key
    */
    function toAddress(bytes memory _publicKey) internal pure returns (address) {
        return address(uint160(uint256(keccak256(_publicKey))));
    }

    /**
    * @notice Hash using one of pre built hashing algorithm
    * @param _message Signed message
    * @param _algorithm Hashing algorithm
    */
    function hash(bytes memory _message, HashAlgorithm _algorithm)
        internal
        pure
        returns (bytes32 result)
    {
        if (_algorithm == HashAlgorithm.KECCAK256) {
            result = keccak256(_message);
        } else if (_algorithm == HashAlgorithm.SHA256) {
            result = sha256(_message);
        } else {
            result = ripemd160(_message);
        }
    }

    /**
    * @notice Verify ECDSA signature
    * @dev Uses one of pre built hashing algorithm
    * @param _message Signed message
    * @param _signature Signature of message hash
    * @param _publicKey secp256k1 public key in uncompressed format without prefix byte (64 bytes)
    * @param _algorithm Hashing algorithm
    */
    function verify(
        bytes memory _message,
        bytes memory _signature,
        bytes memory _publicKey,
        HashAlgorithm _algorithm
    )
        internal
        pure
        returns (bool)
    {
        require(_publicKey.length == 64);
        return toAddress(_publicKey) == recover(hash(_message, _algorithm), _signature);
    }

    /**
    * @notice Hash message according to EIP191 signature specification
    * @dev It always assumes Keccak256 is used as hashing algorithm
    * @dev Only supports version 0 and version E (0x45)
    * @param _message Message to sign
    * @param _version EIP191 version to use
    */
    function hashEIP191(
        bytes memory _message,
        byte _version
    )
        internal
        view
        returns (bytes32 result)
    {
        if(_version == byte(0x00)){  // Version 0: Data with intended validator
            address validator = address(this);
            return keccak256(abi.encodePacked(byte(0x19), byte(0x00), validator, _message));
        } else if (_version == byte(0x45)){  // Version E: personal_sign messages
            uint256 length = _message.length;
            require(length > 0, "Empty message not allowed for version E");

            // Compute text-encoded length of message
            uint256 digits = 0;
            while (length != 0) {
                digits++;
                length /= 10;
            }
            bytes memory lengthAsText = new bytes(digits);
            length = _message.length;
            uint256 index = digits - 1;
            while (length != 0) {
                lengthAsText[index--] = byte(uint8(48 + length % 10));
                length /= 10;
            }

            return keccak256(abi.encodePacked(byte(0x19), EIP191_VERSION_E_HEADER, lengthAsText, _message));
        } else {
            revert("Unsupported EIP191 version");
        }
    }

    /**
    * @notice Verify EIP191 signature
    * @dev It always assumes Keccak256 is used as hashing algorithm
    * @dev Only supports version 0 and version E (0x45)
    * @param _message Signed message
    * @param _signature Signature of message hash
    * @param _publicKey secp256k1 public key in uncompressed format without prefix byte (64 bytes)
    * @param _version EIP191 version to use
    */
    function verifyEIP191(
        bytes memory _message,
        bytes memory _signature,
        bytes memory _publicKey,
        byte _version
    )
        internal
        view
        returns (bool)
    {
        require(_publicKey.length == 64);
        return toAddress(_publicKey) == recover(hashEIP191(_message, _version), _signature);
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "../aragon/interfaces/IERC900History.sol";
import "./Issuer.sol";
import "./lib/Bits.sol";
import "./lib/Snapshot.sol";
import "../zeppelin/math/SafeMath.sol";
import "../zeppelin/token/ERC20/SafeERC20.sol";


/**
* @notice PolicyManager interface
*/
interface PolicyManagerInterface {
    function secondsPerPeriod() external view returns (uint32);
    function register(address _node, uint16 _period) external;
    function migrate(address _node) external;
    function ping(
        address _node,
        uint16 _processedPeriod1,
        uint16 _processedPeriod2,
        uint16 _periodToSetDefault
    ) external;
}


/**
* @notice Adjudicator interface
*/
interface AdjudicatorInterface {
    function rewardCoefficient() external view returns (uint32);
}


/**
* @notice WorkLock interface
*/
interface WorkLockInterface {
    function token() external view returns (NuCypherToken);
}

/**
* @title StakingEscrowStub
* @notice Stub is used to deploy main StakingEscrow after all other contract and make some variables immutable
* @dev |v1.0.0|
*/
contract StakingEscrowStub is Upgradeable {
    using AdditionalMath for uint32;

    NuCypherToken public immutable token;
    uint32 public immutable genesisSecondsPerPeriod;
    uint32 public immutable secondsPerPeriod;
    uint16 public immutable minLockedPeriods;
    uint256 public immutable minAllowableLockedTokens;
    uint256 public immutable maxAllowableLockedTokens;

    /**
    * @notice Predefines some variables for use when deploying other contracts
    * @param _token Token contract
    * @param _genesisHoursPerPeriod Size of period in hours at genesis
    * @param _hoursPerPeriod Size of period in hours
    * @param _minLockedPeriods Min amount of periods during which tokens can be locked
    * @param _minAllowableLockedTokens Min amount of tokens that can be locked
    * @param _maxAllowableLockedTokens Max amount of tokens that can be locked
    */
    constructor(
        NuCypherToken _token,
        uint32 _genesisHoursPerPeriod,
        uint32 _hoursPerPeriod,
        uint16 _minLockedPeriods,
        uint256 _minAllowableLockedTokens,
        uint256 _maxAllowableLockedTokens
    ) {
        require(_token.totalSupply() > 0 &&
            _hoursPerPeriod != 0 &&
            _genesisHoursPerPeriod != 0 &&
            _genesisHoursPerPeriod <= _hoursPerPeriod &&
            _minLockedPeriods > 1 &&
            _maxAllowableLockedTokens != 0);

        token = _token;
        secondsPerPeriod = _hoursPerPeriod.mul32(1 hours);
        genesisSecondsPerPeriod = _genesisHoursPerPeriod.mul32(1 hours);
        minLockedPeriods = _minLockedPeriods;
        minAllowableLockedTokens = _minAllowableLockedTokens;
        maxAllowableLockedTokens = _maxAllowableLockedTokens;
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `verifyState`
    function verifyState(address _testTarget) public override virtual {
        super.verifyState(_testTarget);

        // we have to use real values even though this is a stub
        require(address(delegateGet(_testTarget, this.token.selector)) == address(token));
        // TODO uncomment after merging this PR #2579
//        require(uint32(delegateGet(_testTarget, this.genesisSecondsPerPeriod.selector)) == genesisSecondsPerPeriod);
        require(uint32(delegateGet(_testTarget, this.secondsPerPeriod.selector)) == secondsPerPeriod);
        require(uint16(delegateGet(_testTarget, this.minLockedPeriods.selector)) == minLockedPeriods);
        require(delegateGet(_testTarget, this.minAllowableLockedTokens.selector) == minAllowableLockedTokens);
        require(delegateGet(_testTarget, this.maxAllowableLockedTokens.selector) == maxAllowableLockedTokens);
    }
}


/**
* @title StakingEscrow
* @notice Contract holds and locks stakers tokens.
* Each staker that locks their tokens will receive some compensation
* @dev |v5.7.1|
*/
contract StakingEscrow is Issuer, IERC900History {

    using AdditionalMath for uint256;
    using AdditionalMath for uint16;
    using Bits for uint256;
    using SafeMath for uint256;
    using Snapshot for uint128[];
    using SafeERC20 for NuCypherToken;

    /**
    * @notice Signals that tokens were deposited
    * @param staker Staker address
    * @param value Amount deposited (in NuNits)
    * @param periods Number of periods tokens will be locked
    */
    event Deposited(address indexed staker, uint256 value, uint16 periods);

    /**
    * @notice Signals that tokens were stake locked
    * @param staker Staker address
    * @param value Amount locked (in NuNits)
    * @param firstPeriod Starting lock period
    * @param periods Number of periods tokens will be locked
    */
    event Locked(address indexed staker, uint256 value, uint16 firstPeriod, uint16 periods);

    /**
    * @notice Signals that a sub-stake was divided
    * @param staker Staker address
    * @param oldValue Old sub-stake value (in NuNits)
    * @param lastPeriod Final locked period of old sub-stake
    * @param newValue New sub-stake value (in NuNits)
    * @param periods Number of periods to extend sub-stake
    */
    event Divided(
        address indexed staker,
        uint256 oldValue,
        uint16 lastPeriod,
        uint256 newValue,
        uint16 periods
    );

    /**
    * @notice Signals that two sub-stakes were merged
    * @param staker Staker address
    * @param value1 Value of first sub-stake (in NuNits)
    * @param value2 Value of second sub-stake (in NuNits)
    * @param lastPeriod Final locked period of merged sub-stake
    */
    event Merged(address indexed staker, uint256 value1, uint256 value2, uint16 lastPeriod);

    /**
    * @notice Signals that a sub-stake was prolonged
    * @param staker Staker address
    * @param value Value of sub-stake
    * @param lastPeriod Final locked period of old sub-stake
    * @param periods Number of periods sub-stake was extended
    */
    event Prolonged(address indexed staker, uint256 value, uint16 lastPeriod, uint16 periods);

    /**
    * @notice Signals that tokens were withdrawn to the staker
    * @param staker Staker address
    * @param value Amount withdraws (in NuNits)
    */
    event Withdrawn(address indexed staker, uint256 value);

    /**
    * @notice Signals that the worker associated with the staker made a commitment to next period
    * @param staker Staker address
    * @param period Period committed to
    * @param value Amount of tokens staked for the committed period
    */
    event CommitmentMade(address indexed staker, uint16 indexed period, uint256 value);

    /**
    * @notice Signals that tokens were minted for previous periods
    * @param staker Staker address
    * @param period Previous period tokens minted for
    * @param value Amount minted (in NuNits)
    */
    event Minted(address indexed staker, uint16 indexed period, uint256 value);

    /**
    * @notice Signals that the staker was slashed
    * @param staker Staker address
    * @param penalty Slashing penalty
    * @param investigator Investigator address
    * @param reward Value of reward provided to investigator (in NuNits)
    */
    event Slashed(address indexed staker, uint256 penalty, address indexed investigator, uint256 reward);

    /**
    * @notice Signals that the restake parameter was activated/deactivated
    * @param staker Staker address
    * @param reStake Updated parameter value
    */
    event ReStakeSet(address indexed staker, bool reStake);

    /**
    * @notice Signals that a worker was bonded to the staker
    * @param staker Staker address
    * @param worker Worker address
    * @param startPeriod Period bonding occurred
    */
    event WorkerBonded(address indexed staker, address indexed worker, uint16 indexed startPeriod);

    /**
    * @notice Signals that the winddown parameter was activated/deactivated
    * @param staker Staker address
    * @param windDown Updated parameter value
    */
    event WindDownSet(address indexed staker, bool windDown);

    /**
    * @notice Signals that the snapshot parameter was activated/deactivated
    * @param staker Staker address
    * @param snapshotsEnabled Updated parameter value
    */
    event SnapshotSet(address indexed staker, bool snapshotsEnabled);

    /**
    * @notice Signals that the staker migrated their stake to the new period length
    * @param staker Staker address
    * @param period Period when migration happened
    */
    event Migrated(address indexed staker, uint16 indexed period);

    /// internal event
    event WorkMeasurementSet(address indexed staker, bool measureWork);

    struct SubStakeInfo {
        uint16 firstPeriod;
        uint16 lastPeriod;
        uint16 unlockingDuration;
        uint128 lockedValue;
    }

    struct Downtime {
        uint16 startPeriod;
        uint16 endPeriod;
    }

    struct StakerInfo {
        uint256 value;
        /*
        * Stores periods that are committed but not yet rewarded.
        * In order to optimize storage, only two values are used instead of an array.
        * commitToNextPeriod() method invokes mint() method so there can only be two committed
        * periods that are not yet rewarded: the current and the next periods.
        */
        uint16 currentCommittedPeriod;
        uint16 nextCommittedPeriod;
        uint16 lastCommittedPeriod;
        uint16 stub1; // former slot for lockReStakeUntilPeriod
        uint256 completedWork;
        uint16 workerStartPeriod; // period when worker was bonded
        address worker;
        uint256 flags; // uint256 to acquire whole slot and minimize operations on it

        uint256 reservedSlot1;
        uint256 reservedSlot2;
        uint256 reservedSlot3;
        uint256 reservedSlot4;
        uint256 reservedSlot5;

        Downtime[] pastDowntime;
        SubStakeInfo[] subStakes;
        uint128[] history;

    }

    // used only for upgrading
    uint16 internal constant RESERVED_PERIOD = 0;
    uint16 internal constant MAX_CHECKED_VALUES = 5;
    // to prevent high gas consumption in loops for slashing
    uint16 public constant MAX_SUB_STAKES = 30;
    uint16 internal constant MAX_UINT16 = 65535;

    // indices for flags
    uint8 internal constant RE_STAKE_DISABLED_INDEX = 0;
    uint8 internal constant WIND_DOWN_INDEX = 1;
    uint8 internal constant MEASURE_WORK_INDEX = 2;
    uint8 internal constant SNAPSHOTS_DISABLED_INDEX = 3;
    uint8 internal constant MIGRATED_INDEX = 4;

    uint16 public immutable minLockedPeriods;
    uint16 public immutable minWorkerPeriods;
    uint256 public immutable minAllowableLockedTokens;
    uint256 public immutable maxAllowableLockedTokens;

    PolicyManagerInterface public immutable policyManager;
    AdjudicatorInterface public immutable adjudicator;
    WorkLockInterface public immutable workLock;

    mapping (address => StakerInfo) public stakerInfo;
    address[] public stakers;
    mapping (address => address) public stakerFromWorker;

    mapping (uint16 => uint256) stub4; // former slot for lockedPerPeriod
    uint128[] public balanceHistory;

    address stub1; // former slot for PolicyManager
    address stub2; // former slot for Adjudicator
    address stub3; // former slot for WorkLock

    mapping (uint16 => uint256) _lockedPerPeriod;
    // only to make verifyState from previous version work, temporary
    // TODO remove after upgrade #2579
    function lockedPerPeriod(uint16 _period) public view returns (uint256) {
        return _period != RESERVED_PERIOD ? _lockedPerPeriod[_period] : 111;
    }

    /**
    * @notice Constructor sets address of token contract and coefficients for minting
    * @param _token Token contract
    * @param _policyManager Policy Manager contract
    * @param _adjudicator Adjudicator contract
    * @param _workLock WorkLock contract. Zero address if there is no WorkLock
    * @param _genesisHoursPerPeriod Size of period in hours at genesis
    * @param _hoursPerPeriod Size of period in hours
    * @param _issuanceDecayCoefficient (d) Coefficient which modifies the rate at which the maximum issuance decays,
    * only applicable to Phase 2. d = 365 * half-life / LOG2 where default half-life = 2.
    * See Equation 10 in Staking Protocol & Economics paper
    * @param _lockDurationCoefficient1 (k1) Numerator of the coefficient which modifies the extent
    * to which a stake's lock duration affects the subsidy it receives. Affects stakers differently.
    * Applicable to Phase 1 and Phase 2. k1 = k2 * small_stake_multiplier where default small_stake_multiplier = 0.5.
    * See Equation 8 in Staking Protocol & Economics paper.
    * @param _lockDurationCoefficient2 (k2) Denominator of the coefficient which modifies the extent
    * to which a stake's lock duration affects the subsidy it receives. Affects stakers differently.
    * Applicable to Phase 1 and Phase 2. k2 = maximum_rewarded_periods / (1 - small_stake_multiplier)
    * where default maximum_rewarded_periods = 365 and default small_stake_multiplier = 0.5.
    * See Equation 8 in Staking Protocol & Economics paper.
    * @param _maximumRewardedPeriods (kmax) Number of periods beyond which a stake's lock duration
    * no longer increases the subsidy it receives. kmax = reward_saturation * 365 where default reward_saturation = 1.
    * See Equation 8 in Staking Protocol & Economics paper.
    * @param _firstPhaseTotalSupply Total supply for the first phase
    * @param _firstPhaseMaxIssuance (Imax) Maximum number of new tokens minted per period during Phase 1.
    * See Equation 7 in Staking Protocol & Economics paper.
    * @param _minLockedPeriods Min amount of periods during which tokens can be locked
    * @param _minAllowableLockedTokens Min amount of tokens that can be locked
    * @param _maxAllowableLockedTokens Max amount of tokens that can be locked
    * @param _minWorkerPeriods Min amount of periods while a worker can't be changed
    */
    constructor(
        NuCypherToken _token,
        PolicyManagerInterface _policyManager,
        AdjudicatorInterface _adjudicator,
        WorkLockInterface _workLock,
        uint32 _genesisHoursPerPeriod,
        uint32 _hoursPerPeriod,
        uint256 _issuanceDecayCoefficient,
        uint256 _lockDurationCoefficient1,
        uint256 _lockDurationCoefficient2,
        uint16 _maximumRewardedPeriods,
        uint256 _firstPhaseTotalSupply,
        uint256 _firstPhaseMaxIssuance,
        uint16 _minLockedPeriods,
        uint256 _minAllowableLockedTokens,
        uint256 _maxAllowableLockedTokens,
        uint16 _minWorkerPeriods
    )
        Issuer(
            _token,
            _genesisHoursPerPeriod,
            _hoursPerPeriod,
            _issuanceDecayCoefficient,
            _lockDurationCoefficient1,
            _lockDurationCoefficient2,
            _maximumRewardedPeriods,
            _firstPhaseTotalSupply,
            _firstPhaseMaxIssuance
        )
    {
        // constant `1` in the expression `_minLockedPeriods > 1` uses to simplify the `lock` method
        require(_minLockedPeriods > 1 && _maxAllowableLockedTokens != 0);
        minLockedPeriods = _minLockedPeriods;
        minAllowableLockedTokens = _minAllowableLockedTokens;
        maxAllowableLockedTokens = _maxAllowableLockedTokens;
        minWorkerPeriods = _minWorkerPeriods;

        require((_policyManager.secondsPerPeriod() == _hoursPerPeriod * (1 hours) ||
            _policyManager.secondsPerPeriod() == _genesisHoursPerPeriod * (1 hours)) &&
            _adjudicator.rewardCoefficient() != 0 &&
            (address(_workLock) == address(0) || _workLock.token() == _token));
        policyManager = _policyManager;
        adjudicator = _adjudicator;
        workLock = _workLock;
    }

    /**
    * @dev Checks the existence of a staker in the contract
    */
    modifier onlyStaker()
    {
        StakerInfo storage info = stakerInfo[msg.sender];
        require((info.value > 0 || info.nextCommittedPeriod != 0) &&
            info.flags.bitSet(MIGRATED_INDEX));
        _;
    }

    //------------------------Main getters------------------------
    /**
    * @notice Get all tokens belonging to the staker
    */
    function getAllTokens(address _staker) external view returns (uint256) {
        return stakerInfo[_staker].value;
    }

    /**
    * @notice Get all flags for the staker
    */
    function getFlags(address _staker)
        external view returns (
            bool windDown,
            bool reStake,
            bool measureWork,
            bool snapshots,
            bool migrated
        )
    {
        StakerInfo storage info = stakerInfo[_staker];
        windDown = info.flags.bitSet(WIND_DOWN_INDEX);
        reStake = !info.flags.bitSet(RE_STAKE_DISABLED_INDEX);
        measureWork = info.flags.bitSet(MEASURE_WORK_INDEX);
        snapshots = !info.flags.bitSet(SNAPSHOTS_DISABLED_INDEX);
        migrated = info.flags.bitSet(MIGRATED_INDEX);
    }

    /**
    * @notice Get the start period. Use in the calculation of the last period of the sub stake
    * @param _info Staker structure
    * @param _currentPeriod Current period
    */
    function getStartPeriod(StakerInfo storage _info, uint16 _currentPeriod)
        internal view returns (uint16)
    {
        // if the next period (after current) is committed
        if (_info.flags.bitSet(WIND_DOWN_INDEX) && _info.nextCommittedPeriod > _currentPeriod) {
            return _currentPeriod + 1;
        }
        return _currentPeriod;
    }

    /**
    * @notice Get the last period of the sub stake
    * @param _subStake Sub stake structure
    * @param _startPeriod Pre-calculated start period
    */
    function getLastPeriodOfSubStake(SubStakeInfo storage _subStake, uint16 _startPeriod)
        internal view returns (uint16)
    {
        if (_subStake.lastPeriod != 0) {
            return _subStake.lastPeriod;
        }
        uint32 lastPeriod = uint32(_startPeriod) + _subStake.unlockingDuration;
        if (lastPeriod > uint32(MAX_UINT16)) {
            return MAX_UINT16;
        }
        return uint16(lastPeriod);
    }

    /**
    * @notice Get the last period of the sub stake
    * @param _staker Staker
    * @param _index Stake index
    */
    function getLastPeriodOfSubStake(address _staker, uint256 _index)
        public view returns (uint16)
    {
        StakerInfo storage info = stakerInfo[_staker];
        SubStakeInfo storage subStake = info.subStakes[_index];
        uint16 startPeriod = getStartPeriod(info, getCurrentPeriod());
        return getLastPeriodOfSubStake(subStake, startPeriod);
    }


    /**
    * @notice Get the value of locked tokens for a staker in a specified period
    * @dev Information may be incorrect for rewarded or not committed surpassed period
    * @param _info Staker structure
    * @param _currentPeriod Current period
    * @param _period Next period
    */
    function getLockedTokens(StakerInfo storage _info, uint16 _currentPeriod, uint16 _period)
        internal view returns (uint256 lockedValue)
    {
        lockedValue = 0;
        uint16 startPeriod = getStartPeriod(_info, _currentPeriod);
        for (uint256 i = 0; i < _info.subStakes.length; i++) {
            SubStakeInfo storage subStake = _info.subStakes[i];
            if (subStake.firstPeriod <= _period &&
                getLastPeriodOfSubStake(subStake, startPeriod) >= _period) {
                lockedValue += subStake.lockedValue;
            }
        }
    }

    /**
    * @notice Get the value of locked tokens for a staker in a future period
    * @dev This function is used by PreallocationEscrow so its signature can't be updated.
    * @param _staker Staker
    * @param _offsetPeriods Amount of periods that will be added to the current period
    */
    function getLockedTokens(address _staker, uint16 _offsetPeriods)
        external view returns (uint256 lockedValue)
    {
        StakerInfo storage info = stakerInfo[_staker];
        uint16 currentPeriod = getCurrentPeriod();
        uint16 nextPeriod = currentPeriod.add16(_offsetPeriods);
        return getLockedTokens(info, currentPeriod, nextPeriod);
    }

    /**
    * @notice Get the last committed staker's period
    * @param _staker Staker
    */
    function getLastCommittedPeriod(address _staker) public view returns (uint16) {
        StakerInfo storage info = stakerInfo[_staker];
        return info.nextCommittedPeriod != 0 ? info.nextCommittedPeriod : info.lastCommittedPeriod;
    }

    /**
    * @notice Get the value of locked tokens for active stakers in (getCurrentPeriod() + _offsetPeriods) period
    * as well as stakers and their locked tokens
    * @param _offsetPeriods Amount of periods for locked tokens calculation
    * @param _startIndex Start index for looking in stakers array
    * @param _maxStakers Max stakers for looking, if set 0 then all will be used
    * @return allLockedTokens Sum of locked tokens for active stakers
    * @return activeStakers Array of stakers and their locked tokens. Stakers addresses stored as uint256
    * @dev Note that activeStakers[0] in an array of uint256, but you want addresses. Careful when used directly!
    */
    function getActiveStakers(uint16 _offsetPeriods, uint256 _startIndex, uint256 _maxStakers)
        external view returns (uint256 allLockedTokens, uint256[2][] memory activeStakers)
    {
        require(_offsetPeriods > 0);

        uint256 endIndex = stakers.length;
        require(_startIndex < endIndex);
        if (_maxStakers != 0 && _startIndex + _maxStakers < endIndex) {
            endIndex = _startIndex + _maxStakers;
        }
        activeStakers = new uint256[2][](endIndex - _startIndex);
        allLockedTokens = 0;

        uint256 resultIndex = 0;
        uint16 currentPeriod = getCurrentPeriod();
        uint16 nextPeriod = currentPeriod.add16(_offsetPeriods);

        for (uint256 i = _startIndex; i < endIndex; i++) {
            address staker = stakers[i];
            StakerInfo storage info = stakerInfo[staker];
            if (info.currentCommittedPeriod != currentPeriod &&
                info.nextCommittedPeriod != currentPeriod) {
                continue;
            }
            uint256 lockedTokens = getLockedTokens(info, currentPeriod, nextPeriod);
            if (lockedTokens != 0) {
                activeStakers[resultIndex][0] = uint256(staker);
                activeStakers[resultIndex++][1] = lockedTokens;
                allLockedTokens += lockedTokens;
            }
        }
        assembly {
            mstore(activeStakers, resultIndex)
        }
    }

    /**
    * @notice Get worker using staker's address
    */
    function getWorkerFromStaker(address _staker) external view returns (address) {
        return stakerInfo[_staker].worker;
    }

    /**
    * @notice Get work that completed by the staker
    */
    function getCompletedWork(address _staker) external view returns (uint256) {
        return stakerInfo[_staker].completedWork;
    }

    /**
    * @notice Find index of downtime structure that includes specified period
    * @dev If specified period is outside all downtime periods, the length of the array will be returned
    * @param _staker Staker
    * @param _period Specified period number
    */
    function findIndexOfPastDowntime(address _staker, uint16 _period) external view returns (uint256 index) {
        StakerInfo storage info = stakerInfo[_staker];
        for (index = 0; index < info.pastDowntime.length; index++) {
            if (_period <= info.pastDowntime[index].endPeriod) {
                return index;
            }
        }
    }

    //------------------------Main methods------------------------
    /**
    * @notice Start or stop measuring the work of a staker
    * @param _staker Staker
    * @param _measureWork Value for `measureWork` parameter
    * @return Work that was previously done
    */
    function setWorkMeasurement(address _staker, bool _measureWork) external returns (uint256) {
        require(msg.sender == address(workLock));
        StakerInfo storage info = stakerInfo[_staker];
        if (info.flags.bitSet(MEASURE_WORK_INDEX) == _measureWork) {
            return info.completedWork;
        }
        info.flags = info.flags.toggleBit(MEASURE_WORK_INDEX);
        emit WorkMeasurementSet(_staker, _measureWork);
        return info.completedWork;
    }

    /**
    * @notice Bond worker
    * @param _worker Worker address. Must be a real address, not a contract
    */
    function bondWorker(address _worker) external onlyStaker {
        StakerInfo storage info = stakerInfo[msg.sender];
        // Specified worker is already bonded with this staker
        require(_worker != info.worker);
        uint16 currentPeriod = getCurrentPeriod();
        if (info.worker != address(0)) { // If this staker had a worker ...
            // Check that enough time has passed to change it
            require(currentPeriod >= info.workerStartPeriod.add16(minWorkerPeriods));
            // Remove the old relation "worker->staker"
            stakerFromWorker[info.worker] = address(0);
        }

        if (_worker != address(0)) {
            // Specified worker is already in use
            require(stakerFromWorker[_worker] == address(0));
            // Specified worker is a staker
            require(stakerInfo[_worker].subStakes.length == 0 || _worker == msg.sender);
            // Set new worker->staker relation
            stakerFromWorker[_worker] = msg.sender;
        }

        // Bond new worker (or unbond if _worker == address(0))
        info.worker = _worker;
        info.workerStartPeriod = currentPeriod;
        emit WorkerBonded(msg.sender, _worker, currentPeriod);
    }

    /**
    * @notice Set `reStake` parameter. If true then all staking rewards will be added to locked stake
    * @param _reStake Value for parameter
    */
    function setReStake(bool _reStake) external {
        StakerInfo storage info = stakerInfo[msg.sender];
        if (info.flags.bitSet(RE_STAKE_DISABLED_INDEX) == !_reStake) {
            return;
        }
        info.flags = info.flags.toggleBit(RE_STAKE_DISABLED_INDEX);
        emit ReStakeSet(msg.sender, _reStake);
    }

    /**
    * @notice Deposit tokens from WorkLock contract
    * @param _staker Staker address
    * @param _value Amount of tokens to deposit
    * @param _unlockingDuration Amount of periods during which tokens will be unlocked when wind down is enabled
    */
    function depositFromWorkLock(
        address _staker,
        uint256 _value,
        uint16 _unlockingDuration
    )
        external
    {
        require(msg.sender == address(workLock));
        StakerInfo storage info = stakerInfo[_staker];
        if (!info.flags.bitSet(WIND_DOWN_INDEX) && info.subStakes.length == 0) {
            info.flags = info.flags.toggleBit(WIND_DOWN_INDEX);
            emit WindDownSet(_staker, true);
        }
        // WorkLock still uses the genesis period length (24h)
        _unlockingDuration = recalculatePeriod(_unlockingDuration);
        deposit(_staker, msg.sender, MAX_SUB_STAKES, _value, _unlockingDuration);
    }

    /**
    * @notice Set `windDown` parameter.
    * If true then stake's duration will be decreasing in each period with `commitToNextPeriod()`
    * @param _windDown Value for parameter
    */
    function setWindDown(bool _windDown) external {
        StakerInfo storage info = stakerInfo[msg.sender];
        if (info.flags.bitSet(WIND_DOWN_INDEX) == _windDown) {
            return;
        }
        info.flags = info.flags.toggleBit(WIND_DOWN_INDEX);
        emit WindDownSet(msg.sender, _windDown);

        // duration adjustment if next period is committed
        uint16 nextPeriod = getCurrentPeriod() + 1;
        if (info.nextCommittedPeriod != nextPeriod) {
           return;
        }

        // adjust sub-stakes duration for the new value of winding down parameter
        for (uint256 index = 0; index < info.subStakes.length; index++) {
            SubStakeInfo storage subStake = info.subStakes[index];
            // sub-stake does not have fixed last period when winding down is disabled
            if (!_windDown && subStake.lastPeriod == nextPeriod) {
                subStake.lastPeriod = 0;
                subStake.unlockingDuration = 1;
                continue;
            }
            // this sub-stake is no longer affected by winding down parameter
            if (subStake.lastPeriod != 0 || subStake.unlockingDuration == 0) {
                continue;
            }

            subStake.unlockingDuration = _windDown ? subStake.unlockingDuration - 1 : subStake.unlockingDuration + 1;
            if (subStake.unlockingDuration == 0) {
                subStake.lastPeriod = nextPeriod;
            }
        }
    }

    /**
    * @notice Activate/deactivate taking snapshots of balances
    * @param _enableSnapshots True to activate snapshots, False to deactivate
    */
    function setSnapshots(bool _enableSnapshots) external {
        StakerInfo storage info = stakerInfo[msg.sender];
        if (info.flags.bitSet(SNAPSHOTS_DISABLED_INDEX) == !_enableSnapshots) {
            return;
        }

        uint256 lastGlobalBalance = uint256(balanceHistory.lastValue());
        if(_enableSnapshots){
            info.history.addSnapshot(info.value);
            balanceHistory.addSnapshot(lastGlobalBalance + info.value);
        } else {
            info.history.addSnapshot(0);
            balanceHistory.addSnapshot(lastGlobalBalance - info.value);
        }
        info.flags = info.flags.toggleBit(SNAPSHOTS_DISABLED_INDEX);

        emit SnapshotSet(msg.sender, _enableSnapshots);
    }

    /**
    * @notice Adds a new snapshot to both the staker and global balance histories,
    * assuming the staker's balance was already changed
    * @param _info Reference to affected staker's struct
    * @param _addition Variance in balance. It can be positive or negative.
    */
    function addSnapshot(StakerInfo storage _info, int256 _addition) internal {
        if(!_info.flags.bitSet(SNAPSHOTS_DISABLED_INDEX)){
            _info.history.addSnapshot(_info.value);
            uint256 lastGlobalBalance = uint256(balanceHistory.lastValue());
            balanceHistory.addSnapshot(lastGlobalBalance.addSigned(_addition));
        }
    }

    /**
    * @notice Implementation of the receiveApproval(address,uint256,address,bytes) method
    * (see NuCypherToken contract). Deposit all tokens that were approved to transfer
    * @param _from Staker
    * @param _value Amount of tokens to deposit
    * @param _tokenContract Token contract address
    * @notice (param _extraData) Amount of periods during which tokens will be unlocked when wind down is enabled
    */
    function receiveApproval(
        address _from,
        uint256 _value,
        address _tokenContract,
        bytes calldata /* _extraData */
    )
        external
    {
        require(_tokenContract == address(token) && msg.sender == address(token));

        // Copy first 32 bytes from _extraData, according to calldata memory layout:
        //
        // 0x00: method signature      4 bytes
        // 0x04: _from                 32 bytes after encoding
        // 0x24: _value                32 bytes after encoding
        // 0x44: _tokenContract        32 bytes after encoding
        // 0x64: _extraData pointer    32 bytes. Value must be 0x80 (offset of _extraData wrt to 1st parameter)
        // 0x84: _extraData length     32 bytes
        // 0xA4: _extraData data       Length determined by previous variable
        //
        // See https://solidity.readthedocs.io/en/latest/abi-spec.html#examples

        uint256 payloadSize;
        uint256 payload;
        assembly {
            payloadSize := calldataload(0x84)
            payload := calldataload(0xA4)
        }
        payload = payload >> 8*(32 - payloadSize);
        deposit(_from, _from, MAX_SUB_STAKES, _value, uint16(payload));
    }

    /**
    * @notice Deposit tokens and create new sub-stake. Use this method to become a staker
    * @param _staker Staker
    * @param _value Amount of tokens to deposit
    * @param _unlockingDuration Amount of periods during which tokens will be unlocked when wind down is enabled
    */
    function deposit(address _staker, uint256 _value, uint16 _unlockingDuration) external {
        deposit(_staker, msg.sender, MAX_SUB_STAKES, _value, _unlockingDuration);
    }

    /**
    * @notice Deposit tokens and increase lock amount of an existing sub-stake
    * @dev This is preferable way to stake tokens because will be fewer active sub-stakes in the result
    * @param _index Index of the sub stake
    * @param _value Amount of tokens which will be locked
    */
    function depositAndIncrease(uint256 _index, uint256 _value) external onlyStaker {
        require(_index < MAX_SUB_STAKES);
        deposit(msg.sender, msg.sender, _index, _value, 0);
    }

    /**
    * @notice Deposit tokens
    * @dev Specify either index and zero periods (for an existing sub-stake)
    * or index >= MAX_SUB_STAKES and real value for periods (for a new sub-stake), not both
    * @param _staker Staker
    * @param _payer Owner of tokens
    * @param _index Index of the sub stake
    * @param _value Amount of tokens to deposit
    * @param _unlockingDuration Amount of periods during which tokens will be unlocked when wind down is enabled
    */
    function deposit(address _staker, address _payer, uint256 _index, uint256 _value, uint16 _unlockingDuration) internal {
        require(_value != 0);
        StakerInfo storage info = stakerInfo[_staker];
        // A staker can't be a worker for another staker
        require(stakerFromWorker[_staker] == address(0) || stakerFromWorker[_staker] == info.worker);
        // initial stake of the staker
        if (info.subStakes.length == 0 && info.lastCommittedPeriod == 0) {
            stakers.push(_staker);
            policyManager.register(_staker, getCurrentPeriod() - 1);
            info.flags = info.flags.toggleBit(MIGRATED_INDEX);
        }
        require(info.flags.bitSet(MIGRATED_INDEX));
        token.safeTransferFrom(_payer, address(this), _value);
        info.value += _value;
        lock(_staker, _index, _value, _unlockingDuration);

        addSnapshot(info, int256(_value));
        if (_index >= MAX_SUB_STAKES) {
            emit Deposited(_staker, _value, _unlockingDuration);
        } else {
            uint16 lastPeriod = getLastPeriodOfSubStake(_staker, _index);
            emit Deposited(_staker, _value, lastPeriod - getCurrentPeriod());
        }
    }

    /**
    * @notice Lock some tokens as a new sub-stake
    * @param _value Amount of tokens which will be locked
    * @param _unlockingDuration Amount of periods during which tokens will be unlocked when wind down is enabled
    */
    function lockAndCreate(uint256 _value, uint16 _unlockingDuration) external onlyStaker {
        lock(msg.sender, MAX_SUB_STAKES, _value, _unlockingDuration);
    }

    /**
    * @notice Increase lock amount of an existing sub-stake
    * @param _index Index of the sub-stake
    * @param _value Amount of tokens which will be locked
    */
    function lockAndIncrease(uint256 _index, uint256 _value) external onlyStaker {
        require(_index < MAX_SUB_STAKES);
        lock(msg.sender, _index, _value, 0);
    }

    /**
    * @notice Lock some tokens as a stake
    * @dev Specify either index and zero periods (for an existing sub-stake)
    * or index >= MAX_SUB_STAKES and real value for periods (for a new sub-stake), not both
    * @param _staker Staker
    * @param _index Index of the sub stake
    * @param _value Amount of tokens which will be locked
    * @param _unlockingDuration Amount of periods during which tokens will be unlocked when wind down is enabled
    */
    function lock(address _staker, uint256 _index, uint256 _value, uint16 _unlockingDuration) internal {
        if (_index < MAX_SUB_STAKES) {
            require(_value > 0);
        } else {
            require(_value >= minAllowableLockedTokens && _unlockingDuration >= minLockedPeriods);
        }

        uint16 currentPeriod = getCurrentPeriod();
        uint16 nextPeriod = currentPeriod + 1;
        StakerInfo storage info = stakerInfo[_staker];
        uint256 lockedTokens = getLockedTokens(info, currentPeriod, nextPeriod);
        uint256 requestedLockedTokens = _value.add(lockedTokens);
        require(requestedLockedTokens <= info.value && requestedLockedTokens <= maxAllowableLockedTokens);

        // next period is committed
        if (info.nextCommittedPeriod == nextPeriod) {
            _lockedPerPeriod[nextPeriod] += _value;
            emit CommitmentMade(_staker, nextPeriod, _value);
        }

        // if index was provided then increase existing sub-stake
        if (_index < MAX_SUB_STAKES) {
            lockAndIncrease(info, currentPeriod, nextPeriod, _staker, _index, _value);
        // otherwise create new
        } else {
            lockAndCreate(info, nextPeriod, _staker, _value, _unlockingDuration);
        }
    }

    /**
    * @notice Lock some tokens as a new sub-stake
    * @param _info Staker structure
    * @param _nextPeriod Next period
    * @param _staker Staker
    * @param _value Amount of tokens which will be locked
    * @param _unlockingDuration Amount of periods during which tokens will be unlocked when wind down is enabled
    */
    function lockAndCreate(
        StakerInfo storage _info,
        uint16 _nextPeriod,
        address _staker,
        uint256 _value,
        uint16 _unlockingDuration
    )
        internal
    {
        uint16 duration = _unlockingDuration;
        // if winding down is enabled and next period is committed
        // then sub-stakes duration were decreased
        if (_info.nextCommittedPeriod == _nextPeriod && _info.flags.bitSet(WIND_DOWN_INDEX)) {
            duration -= 1;
        }
        saveSubStake(_info, _nextPeriod, 0, duration, _value);

        emit Locked(_staker, _value, _nextPeriod, _unlockingDuration);
    }

    /**
    * @notice Increase lock amount of an existing sub-stake
    * @dev Probably will be created a new sub-stake but it will be active only one period
    * @param _info Staker structure
    * @param _currentPeriod Current period
    * @param _nextPeriod Next period
    * @param _staker Staker
    * @param _index Index of the sub-stake
    * @param _value Amount of tokens which will be locked
    */
    function lockAndIncrease(
        StakerInfo storage _info,
        uint16 _currentPeriod,
        uint16 _nextPeriod,
        address _staker,
        uint256 _index,
        uint256 _value
    )
        internal
    {
        SubStakeInfo storage subStake = _info.subStakes[_index];
        (, uint16 lastPeriod) = checkLastPeriodOfSubStake(_info, subStake, _currentPeriod);

        // create temporary sub-stake for current or previous committed periods
        // to leave locked amount in this period unchanged
        if (_info.currentCommittedPeriod != 0 &&
            _info.currentCommittedPeriod <= _currentPeriod ||
            _info.nextCommittedPeriod != 0 &&
            _info.nextCommittedPeriod <= _currentPeriod)
        {
            saveSubStake(_info, subStake.firstPeriod, _currentPeriod, 0, subStake.lockedValue);
        }

        subStake.lockedValue += uint128(_value);
        // all new locks should start from the next period
        subStake.firstPeriod = _nextPeriod;

        emit Locked(_staker, _value, _nextPeriod, lastPeriod - _currentPeriod);
    }

    /**
    * @notice Checks that last period of sub-stake is greater than the current period
    * @param _info Staker structure
    * @param _subStake Sub-stake structure
    * @param _currentPeriod Current period
    * @return startPeriod Start period. Use in the calculation of the last period of the sub stake
    * @return lastPeriod Last period of the sub stake
    */
    function checkLastPeriodOfSubStake(
        StakerInfo storage _info,
        SubStakeInfo storage _subStake,
        uint16 _currentPeriod
    )
        internal view returns (uint16 startPeriod, uint16 lastPeriod)
    {
        startPeriod = getStartPeriod(_info, _currentPeriod);
        lastPeriod = getLastPeriodOfSubStake(_subStake, startPeriod);
        // The sub stake must be active at least in the next period
        require(lastPeriod > _currentPeriod);
    }

    /**
    * @notice Save sub stake. First tries to override inactive sub stake
    * @dev Inactive sub stake means that last period of sub stake has been surpassed and already rewarded
    * @param _info Staker structure
    * @param _firstPeriod First period of the sub stake
    * @param _lastPeriod Last period of the sub stake
    * @param _unlockingDuration Duration of the sub stake in periods
    * @param _lockedValue Amount of locked tokens
    */
    function saveSubStake(
        StakerInfo storage _info,
        uint16 _firstPeriod,
        uint16 _lastPeriod,
        uint16 _unlockingDuration,
        uint256 _lockedValue
    )
        internal
    {
        for (uint256 i = 0; i < _info.subStakes.length; i++) {
            SubStakeInfo storage subStake = _info.subStakes[i];
            if (subStake.lastPeriod != 0 &&
                (_info.currentCommittedPeriod == 0 ||
                subStake.lastPeriod < _info.currentCommittedPeriod) &&
                (_info.nextCommittedPeriod == 0 ||
                subStake.lastPeriod < _info.nextCommittedPeriod))
            {
                subStake.firstPeriod = _firstPeriod;
                subStake.lastPeriod = _lastPeriod;
                subStake.unlockingDuration = _unlockingDuration;
                subStake.lockedValue = uint128(_lockedValue);
                return;
            }
        }
        require(_info.subStakes.length < MAX_SUB_STAKES);
        _info.subStakes.push(SubStakeInfo(_firstPeriod, _lastPeriod, _unlockingDuration, uint128(_lockedValue)));
    }

    /**
    * @notice Divide sub stake into two parts
    * @param _index Index of the sub stake
    * @param _newValue New sub stake value
    * @param _additionalDuration Amount of periods for extending sub stake
    */
    function divideStake(uint256 _index, uint256 _newValue, uint16 _additionalDuration) external onlyStaker {
        StakerInfo storage info = stakerInfo[msg.sender];
        require(_newValue >= minAllowableLockedTokens && _additionalDuration > 0);
        SubStakeInfo storage subStake = info.subStakes[_index];
        uint16 currentPeriod = getCurrentPeriod();
        (, uint16 lastPeriod) = checkLastPeriodOfSubStake(info, subStake, currentPeriod);

        uint256 oldValue = subStake.lockedValue;
        subStake.lockedValue = uint128(oldValue.sub(_newValue));
        require(subStake.lockedValue >= minAllowableLockedTokens);
        uint16 requestedPeriods = subStake.unlockingDuration.add16(_additionalDuration);
        saveSubStake(info, subStake.firstPeriod, 0, requestedPeriods, _newValue);
        emit Divided(msg.sender, oldValue, lastPeriod, _newValue, _additionalDuration);
        emit Locked(msg.sender, _newValue, subStake.firstPeriod, requestedPeriods);
    }

    /**
    * @notice Prolong active sub stake
    * @param _index Index of the sub stake
    * @param _additionalDuration Amount of periods for extending sub stake
    */
    function prolongStake(uint256 _index, uint16 _additionalDuration) external onlyStaker {
        StakerInfo storage info = stakerInfo[msg.sender];
        // Incorrect parameters
        require(_additionalDuration > 0);
        SubStakeInfo storage subStake = info.subStakes[_index];
        uint16 currentPeriod = getCurrentPeriod();
        (uint16 startPeriod, uint16 lastPeriod) = checkLastPeriodOfSubStake(info, subStake, currentPeriod);

        subStake.unlockingDuration = subStake.unlockingDuration.add16(_additionalDuration);
        // if the sub stake ends in the next committed period then reset the `lastPeriod` field
        if (lastPeriod == startPeriod) {
            subStake.lastPeriod = 0;
        }
        // The extended sub stake must not be less than the minimum value
        require(uint32(lastPeriod - currentPeriod) + _additionalDuration >= minLockedPeriods);
        emit Locked(msg.sender, subStake.lockedValue, lastPeriod + 1, _additionalDuration);
        emit Prolonged(msg.sender, subStake.lockedValue, lastPeriod, _additionalDuration);
    }

    /**
    * @notice Merge two sub-stakes into one if their last periods are equal
    * @dev It's possible that both sub-stakes will be active after this transaction.
    * But only one of them will be active until next call `commitToNextPeriod` (in the next period)
    * @param _index1 Index of the first sub-stake
    * @param _index2 Index of the second sub-stake
    */
    function mergeStake(uint256 _index1, uint256 _index2) external onlyStaker {
        require(_index1 != _index2); // must be different sub-stakes

        StakerInfo storage info = stakerInfo[msg.sender];
        SubStakeInfo storage subStake1 = info.subStakes[_index1];
        SubStakeInfo storage subStake2 = info.subStakes[_index2];
        uint16 currentPeriod = getCurrentPeriod();

        (, uint16 lastPeriod1) = checkLastPeriodOfSubStake(info, subStake1, currentPeriod);
        (, uint16 lastPeriod2) = checkLastPeriodOfSubStake(info, subStake2, currentPeriod);
        // both sub-stakes must have equal last period to be mergeable
        require(lastPeriod1 == lastPeriod2);
        emit Merged(msg.sender, subStake1.lockedValue, subStake2.lockedValue, lastPeriod1);

        if (subStake1.firstPeriod == subStake2.firstPeriod) {
            subStake1.lockedValue += subStake2.lockedValue;
            subStake2.lastPeriod = 1;
            subStake2.unlockingDuration = 0;
        } else if (subStake1.firstPeriod > subStake2.firstPeriod) {
            subStake1.lockedValue += subStake2.lockedValue;
            subStake2.lastPeriod = subStake1.firstPeriod - 1;
            subStake2.unlockingDuration = 0;
        } else {
            subStake2.lockedValue += subStake1.lockedValue;
            subStake1.lastPeriod = subStake2.firstPeriod - 1;
            subStake1.unlockingDuration = 0;
        }
    }

    /**
    * @notice Remove unused sub-stake to decrease gas cost for several methods
    */
    function removeUnusedSubStake(uint16 _index) external onlyStaker {
        StakerInfo storage info = stakerInfo[msg.sender];

        uint256 lastIndex = info.subStakes.length - 1;
        SubStakeInfo storage subStake = info.subStakes[_index];
        require(subStake.lastPeriod != 0 &&
                (info.currentCommittedPeriod == 0 ||
                subStake.lastPeriod < info.currentCommittedPeriod) &&
                (info.nextCommittedPeriod == 0 ||
                subStake.lastPeriod < info.nextCommittedPeriod));

        if (_index != lastIndex) {
            SubStakeInfo storage lastSubStake = info.subStakes[lastIndex];
            subStake.firstPeriod = lastSubStake.firstPeriod;
            subStake.lastPeriod = lastSubStake.lastPeriod;
            subStake.unlockingDuration = lastSubStake.unlockingDuration;
            subStake.lockedValue = lastSubStake.lockedValue;
        }
        info.subStakes.pop();
    }

    /**
    * @notice Withdraw available amount of tokens to staker
    * @param _value Amount of tokens to withdraw
    */
    function withdraw(uint256 _value) external onlyStaker {
        uint16 currentPeriod = getCurrentPeriod();
        uint16 nextPeriod = currentPeriod + 1;
        StakerInfo storage info = stakerInfo[msg.sender];
        // the max locked tokens in most cases will be in the current period
        // but when the staker locks more then we should use the next period
        uint256 lockedTokens = Math.max(getLockedTokens(info, currentPeriod, nextPeriod),
            getLockedTokens(info, currentPeriod, currentPeriod));
        require(_value <= info.value.sub(lockedTokens));
        info.value -= _value;

        addSnapshot(info, - int256(_value));
        token.safeTransfer(msg.sender, _value);
        emit Withdrawn(msg.sender, _value);

        // unbond worker if staker withdraws last portion of NU
        if (info.value == 0 &&
            info.nextCommittedPeriod == 0 &&
            info.worker != address(0))
        {
            stakerFromWorker[info.worker] = address(0);
            info.worker = address(0);
            emit WorkerBonded(msg.sender, address(0), currentPeriod);
        }
    }

    /**
    * @notice Make a commitment to the next period and mint for the previous period
    */
    function commitToNextPeriod() external isInitialized {
        address staker = stakerFromWorker[msg.sender];
        StakerInfo storage info = stakerInfo[staker];
        // Staker must have a stake to make a commitment
        require(info.value > 0);
        // Only worker with real address can make a commitment
        require(msg.sender == tx.origin);

        migrate(staker);

        uint16 currentPeriod = getCurrentPeriod();
        uint16 nextPeriod = currentPeriod + 1;
        // the period has already been committed
        require(info.nextCommittedPeriod != nextPeriod);

        uint16 lastCommittedPeriod = getLastCommittedPeriod(staker);
        (uint16 processedPeriod1, uint16 processedPeriod2) = mint(staker);

        uint256 lockedTokens = getLockedTokens(info, currentPeriod, nextPeriod);
        require(lockedTokens > 0);
        _lockedPerPeriod[nextPeriod] += lockedTokens;

        info.currentCommittedPeriod = info.nextCommittedPeriod;
        info.nextCommittedPeriod = nextPeriod;

        decreaseSubStakesDuration(info, nextPeriod);

        // staker was inactive for several periods
        if (lastCommittedPeriod < currentPeriod) {
            info.pastDowntime.push(Downtime(lastCommittedPeriod + 1, currentPeriod));
        }

        policyManager.ping(staker, processedPeriod1, processedPeriod2, nextPeriod);
        emit CommitmentMade(staker, nextPeriod, lockedTokens);
    }

    /**
    * @notice Migrate from the old period length to the new one. Can be done only once
    * @param _staker Staker
    */
    function migrate(address _staker) public {
        StakerInfo storage info = stakerInfo[_staker];
        // check that provided address is/was a staker
        require(info.subStakes.length != 0 || info.lastCommittedPeriod != 0);
        if (info.flags.bitSet(MIGRATED_INDEX)) {
            return;
        }

        // reset state
        info.currentCommittedPeriod = 0;
        info.nextCommittedPeriod = 0;
        // maintain case when no more sub-stakes and need to avoid re-registering this staker during deposit
        info.lastCommittedPeriod = 1;
        info.workerStartPeriod = recalculatePeriod(info.workerStartPeriod);
        delete info.pastDowntime;

        // recalculate all sub-stakes
        uint16 currentPeriod = getCurrentPeriod();
        for (uint256 i = 0; i < info.subStakes.length; i++) {
            SubStakeInfo storage subStake = info.subStakes[i];
            subStake.firstPeriod = recalculatePeriod(subStake.firstPeriod);
            // sub-stake has fixed last period
            if (subStake.lastPeriod != 0) {
                subStake.lastPeriod = recalculatePeriod(subStake.lastPeriod);
                if (subStake.lastPeriod == 0) {
                    subStake.lastPeriod = 1;
                }
                subStake.unlockingDuration = 0;
            // sub-stake has no fixed ending but possible that with new period length will have
            } else {
                uint16 oldCurrentPeriod = uint16(block.timestamp / genesisSecondsPerPeriod);
                uint16 lastPeriod = recalculatePeriod(oldCurrentPeriod + subStake.unlockingDuration);
                subStake.unlockingDuration = lastPeriod - currentPeriod;
                if (subStake.unlockingDuration == 0) {
                    subStake.lastPeriod = lastPeriod;
                }
            }
        }

        policyManager.migrate(_staker);
        info.flags = info.flags.toggleBit(MIGRATED_INDEX);
        emit Migrated(_staker, currentPeriod);
    }

    /**
    * @notice Decrease sub-stakes duration if `windDown` is enabled
    */
    function decreaseSubStakesDuration(StakerInfo storage _info, uint16 _nextPeriod) internal {
        if (!_info.flags.bitSet(WIND_DOWN_INDEX)) {
            return;
        }
        for (uint256 index = 0; index < _info.subStakes.length; index++) {
            SubStakeInfo storage subStake = _info.subStakes[index];
            if (subStake.lastPeriod != 0 || subStake.unlockingDuration == 0) {
                continue;
            }
            subStake.unlockingDuration--;
            if (subStake.unlockingDuration == 0) {
                subStake.lastPeriod = _nextPeriod;
            }
        }
    }

    /**
    * @notice Mint tokens for previous periods if staker locked their tokens and made a commitment
    */
    function mint() external onlyStaker {
        // save last committed period to the storage if both periods will be empty after minting
        // because we won't be able to calculate last committed period
        // see getLastCommittedPeriod(address)
        StakerInfo storage info = stakerInfo[msg.sender];
        uint16 previousPeriod = getCurrentPeriod() - 1;
        if (info.nextCommittedPeriod <= previousPeriod && info.nextCommittedPeriod != 0) {
            info.lastCommittedPeriod = info.nextCommittedPeriod;
        }
        (uint16 processedPeriod1, uint16 processedPeriod2) = mint(msg.sender);

        if (processedPeriod1 != 0 || processedPeriod2 != 0) {
            policyManager.ping(msg.sender, processedPeriod1, processedPeriod2, 0);
        }
    }

    /**
    * @notice Mint tokens for previous periods if staker locked their tokens and made a commitment
    * @param _staker Staker
    * @return processedPeriod1 Processed period: currentCommittedPeriod or zero
    * @return processedPeriod2 Processed period: nextCommittedPeriod or zero
    */
    function mint(address _staker) internal returns (uint16 processedPeriod1, uint16 processedPeriod2) {
        uint16 currentPeriod = getCurrentPeriod();
        uint16 previousPeriod = currentPeriod - 1;
        StakerInfo storage info = stakerInfo[_staker];

        if (info.nextCommittedPeriod == 0 ||
            info.currentCommittedPeriod == 0 &&
            info.nextCommittedPeriod > previousPeriod ||
            info.currentCommittedPeriod > previousPeriod) {
            return (0, 0);
        }

        uint16 startPeriod = getStartPeriod(info, currentPeriod);
        uint256 reward = 0;
        bool reStake = !info.flags.bitSet(RE_STAKE_DISABLED_INDEX);

        if (info.currentCommittedPeriod != 0) {
            reward = mint(info, info.currentCommittedPeriod, currentPeriod, startPeriod, reStake);
            processedPeriod1 = info.currentCommittedPeriod;
            info.currentCommittedPeriod = 0;
            if (reStake) {
                _lockedPerPeriod[info.nextCommittedPeriod] += reward;
            }
        }
        if (info.nextCommittedPeriod <= previousPeriod) {
            reward += mint(info, info.nextCommittedPeriod, currentPeriod, startPeriod, reStake);
            processedPeriod2 = info.nextCommittedPeriod;
            info.nextCommittedPeriod = 0;
        }

        info.value += reward;
        if (info.flags.bitSet(MEASURE_WORK_INDEX)) {
            info.completedWork += reward;
        }

        addSnapshot(info, int256(reward));
        emit Minted(_staker, previousPeriod, reward);
    }

    /**
    * @notice Calculate reward for one period
    * @param _info Staker structure
    * @param _mintingPeriod Period for minting calculation
    * @param _currentPeriod Current period
    * @param _startPeriod Pre-calculated start period
    */
    function mint(
        StakerInfo storage _info,
        uint16 _mintingPeriod,
        uint16 _currentPeriod,
        uint16 _startPeriod,
        bool _reStake
    )
        internal returns (uint256 reward)
    {
        reward = 0;
        for (uint256 i = 0; i < _info.subStakes.length; i++) {
            SubStakeInfo storage subStake =  _info.subStakes[i];
            uint16 lastPeriod = getLastPeriodOfSubStake(subStake, _startPeriod);
            if (subStake.firstPeriod <= _mintingPeriod && lastPeriod >= _mintingPeriod) {
                uint256 subStakeReward = mint(
                    _currentPeriod,
                    subStake.lockedValue,
                    _lockedPerPeriod[_mintingPeriod],
                    lastPeriod.sub16(_mintingPeriod));
                reward += subStakeReward;
                if (_reStake) {
                    subStake.lockedValue += uint128(subStakeReward);
                }
            }
        }
        return reward;
    }

    //-------------------------Slashing-------------------------
    /**
    * @notice Slash the staker's stake and reward the investigator
    * @param _staker Staker's address
    * @param _penalty Penalty
    * @param _investigator Investigator
    * @param _reward Reward for the investigator
    */
    function slashStaker(
        address _staker,
        uint256 _penalty,
        address _investigator,
        uint256 _reward
    )
        public isInitialized
    {
        require(msg.sender == address(adjudicator));
        require(_penalty > 0);
        StakerInfo storage info = stakerInfo[_staker];
        require(info.flags.bitSet(MIGRATED_INDEX));
        if (info.value <= _penalty) {
            _penalty = info.value;
        }
        info.value -= _penalty;
        if (_reward > _penalty) {
            _reward = _penalty;
        }

        uint16 currentPeriod = getCurrentPeriod();
        uint16 nextPeriod = currentPeriod + 1;
        uint16 startPeriod = getStartPeriod(info, currentPeriod);

        (uint256 currentLock, uint256 nextLock, uint256 currentAndNextLock, uint256 shortestSubStakeIndex) =
            getLockedTokensAndShortestSubStake(info, currentPeriod, nextPeriod, startPeriod);

        // Decrease the stake if amount of locked tokens in the current period more than staker has
        uint256 lockedTokens = currentLock + currentAndNextLock;
        if (info.value < lockedTokens) {
           decreaseSubStakes(info, lockedTokens - info.value, currentPeriod, startPeriod, shortestSubStakeIndex);
        }
        // Decrease the stake if amount of locked tokens in the next period more than staker has
        if (nextLock > 0) {
            lockedTokens = nextLock + currentAndNextLock -
                (currentAndNextLock > info.value ? currentAndNextLock - info.value : 0);
            if (info.value < lockedTokens) {
               decreaseSubStakes(info, lockedTokens - info.value, nextPeriod, startPeriod, MAX_SUB_STAKES);
            }
        }

        emit Slashed(_staker, _penalty, _investigator, _reward);
        if (_penalty > _reward) {
            unMint(_penalty - _reward);
        }
        // TODO change to withdrawal pattern (#1499)
        if (_reward > 0) {
            token.safeTransfer(_investigator, _reward);
        }

        addSnapshot(info, - int256(_penalty));

    }

    /**
    * @notice Get the value of locked tokens for a staker in the current and the next period
    * and find the shortest sub stake
    * @param _info Staker structure
    * @param _currentPeriod Current period
    * @param _nextPeriod Next period
    * @param _startPeriod Pre-calculated start period
    * @return currentLock Amount of tokens that locked in the current period and unlocked in the next period
    * @return nextLock Amount of tokens that locked in the next period and not locked in the current period
    * @return currentAndNextLock Amount of tokens that locked in the current period and in the next period
    * @return shortestSubStakeIndex Index of the shortest sub stake
    */
    function getLockedTokensAndShortestSubStake(
        StakerInfo storage _info,
        uint16 _currentPeriod,
        uint16 _nextPeriod,
        uint16 _startPeriod
    )
        internal view returns (
            uint256 currentLock,
            uint256 nextLock,
            uint256 currentAndNextLock,
            uint256 shortestSubStakeIndex
        )
    {
        uint16 minDuration = MAX_UINT16;
        uint16 minLastPeriod = MAX_UINT16;
        shortestSubStakeIndex = MAX_SUB_STAKES;
        currentLock = 0;
        nextLock = 0;
        currentAndNextLock = 0;

        for (uint256 i = 0; i < _info.subStakes.length; i++) {
            SubStakeInfo storage subStake = _info.subStakes[i];
            uint16 lastPeriod = getLastPeriodOfSubStake(subStake, _startPeriod);
            if (lastPeriod < subStake.firstPeriod) {
                continue;
            }
            if (subStake.firstPeriod <= _currentPeriod &&
                lastPeriod >= _nextPeriod) {
                currentAndNextLock += subStake.lockedValue;
            } else if (subStake.firstPeriod <= _currentPeriod &&
                lastPeriod >= _currentPeriod) {
                currentLock += subStake.lockedValue;
            } else if (subStake.firstPeriod <= _nextPeriod &&
                lastPeriod >= _nextPeriod) {
                nextLock += subStake.lockedValue;
            }
            uint16 duration = lastPeriod - subStake.firstPeriod;
            if (subStake.firstPeriod <= _currentPeriod &&
                lastPeriod >= _currentPeriod &&
                (lastPeriod < minLastPeriod ||
                lastPeriod == minLastPeriod && duration < minDuration))
            {
                shortestSubStakeIndex = i;
                minDuration = duration;
                minLastPeriod = lastPeriod;
            }
        }
    }

    /**
    * @notice Decrease short sub stakes
    * @param _info Staker structure
    * @param _penalty Penalty rate
    * @param _decreasePeriod The period when the decrease begins
    * @param _startPeriod Pre-calculated start period
    * @param _shortestSubStakeIndex Index of the shortest period
    */
    function decreaseSubStakes(
        StakerInfo storage _info,
        uint256 _penalty,
        uint16 _decreasePeriod,
        uint16 _startPeriod,
        uint256 _shortestSubStakeIndex
    )
        internal
    {
        SubStakeInfo storage shortestSubStake = _info.subStakes[0];
        uint16 minSubStakeLastPeriod = MAX_UINT16;
        uint16 minSubStakeDuration = MAX_UINT16;
        while(_penalty > 0) {
            if (_shortestSubStakeIndex < MAX_SUB_STAKES) {
                shortestSubStake = _info.subStakes[_shortestSubStakeIndex];
                minSubStakeLastPeriod = getLastPeriodOfSubStake(shortestSubStake, _startPeriod);
                minSubStakeDuration = minSubStakeLastPeriod - shortestSubStake.firstPeriod;
                _shortestSubStakeIndex = MAX_SUB_STAKES;
            } else {
                (shortestSubStake, minSubStakeDuration, minSubStakeLastPeriod) =
                    getShortestSubStake(_info, _decreasePeriod, _startPeriod);
            }
            if (minSubStakeDuration == MAX_UINT16) {
                break;
            }
            uint256 appliedPenalty = _penalty;
            if (_penalty < shortestSubStake.lockedValue) {
                shortestSubStake.lockedValue -= uint128(_penalty);
                saveOldSubStake(_info, shortestSubStake.firstPeriod, _penalty, _decreasePeriod);
                _penalty = 0;
            } else {
                shortestSubStake.lastPeriod = _decreasePeriod - 1;
                _penalty -= shortestSubStake.lockedValue;
                appliedPenalty = shortestSubStake.lockedValue;
            }
            if (_info.currentCommittedPeriod >= _decreasePeriod &&
                _info.currentCommittedPeriod <= minSubStakeLastPeriod)
            {
                _lockedPerPeriod[_info.currentCommittedPeriod] -= appliedPenalty;
            }
            if (_info.nextCommittedPeriod >= _decreasePeriod &&
                _info.nextCommittedPeriod <= minSubStakeLastPeriod)
            {
                _lockedPerPeriod[_info.nextCommittedPeriod] -= appliedPenalty;
            }
        }
    }

    /**
    * @notice Get the shortest sub stake
    * @param _info Staker structure
    * @param _currentPeriod Current period
    * @param _startPeriod Pre-calculated start period
    * @return shortestSubStake The shortest sub stake
    * @return minSubStakeDuration Duration of the shortest sub stake
    * @return minSubStakeLastPeriod Last period of the shortest sub stake
    */
    function getShortestSubStake(
        StakerInfo storage _info,
        uint16 _currentPeriod,
        uint16 _startPeriod
    )
        internal view returns (
            SubStakeInfo storage shortestSubStake,
            uint16 minSubStakeDuration,
            uint16 minSubStakeLastPeriod
        )
    {
        shortestSubStake = shortestSubStake;
        minSubStakeDuration = MAX_UINT16;
        minSubStakeLastPeriod = MAX_UINT16;
        for (uint256 i = 0; i < _info.subStakes.length; i++) {
            SubStakeInfo storage subStake = _info.subStakes[i];
            uint16 lastPeriod = getLastPeriodOfSubStake(subStake, _startPeriod);
            if (lastPeriod < subStake.firstPeriod) {
                continue;
            }
            uint16 duration = lastPeriod - subStake.firstPeriod;
            if (subStake.firstPeriod <= _currentPeriod &&
                lastPeriod >= _currentPeriod &&
                (lastPeriod < minSubStakeLastPeriod ||
                lastPeriod == minSubStakeLastPeriod && duration < minSubStakeDuration))
            {
                shortestSubStake = subStake;
                minSubStakeDuration = duration;
                minSubStakeLastPeriod = lastPeriod;
            }
        }
    }

    /**
    * @notice Save the old sub stake values to prevent decreasing reward for the previous period
    * @dev Saving happens only if the previous period is committed
    * @param _info Staker structure
    * @param _firstPeriod First period of the old sub stake
    * @param _lockedValue Locked value of the old sub stake
    * @param _currentPeriod Current period, when the old sub stake is already unlocked
    */
    function saveOldSubStake(
        StakerInfo storage _info,
        uint16 _firstPeriod,
        uint256 _lockedValue,
        uint16 _currentPeriod
    )
        internal
    {
        // Check that the old sub stake should be saved
        bool oldCurrentCommittedPeriod = _info.currentCommittedPeriod != 0 &&
            _info.currentCommittedPeriod < _currentPeriod;
        bool oldnextCommittedPeriod = _info.nextCommittedPeriod != 0 &&
            _info.nextCommittedPeriod < _currentPeriod;
        bool crosscurrentCommittedPeriod = oldCurrentCommittedPeriod && _info.currentCommittedPeriod >= _firstPeriod;
        bool crossnextCommittedPeriod = oldnextCommittedPeriod && _info.nextCommittedPeriod >= _firstPeriod;
        if (!crosscurrentCommittedPeriod && !crossnextCommittedPeriod) {
            return;
        }
        // Try to find already existent proper old sub stake
        uint16 previousPeriod = _currentPeriod - 1;
        for (uint256 i = 0; i < _info.subStakes.length; i++) {
            SubStakeInfo storage subStake = _info.subStakes[i];
            if (subStake.lastPeriod == previousPeriod &&
                ((crosscurrentCommittedPeriod ==
                (oldCurrentCommittedPeriod && _info.currentCommittedPeriod >= subStake.firstPeriod)) &&
                (crossnextCommittedPeriod ==
                (oldnextCommittedPeriod && _info.nextCommittedPeriod >= subStake.firstPeriod))))
            {
                subStake.lockedValue += uint128(_lockedValue);
                return;
            }
        }
        saveSubStake(_info, _firstPeriod, previousPeriod, 0, _lockedValue);
    }

    //-------------Additional getters for stakers info-------------
    /**
    * @notice Return the length of the array of stakers
    */
    function getStakersLength() external view returns (uint256) {
        return stakers.length;
    }

    /**
    * @notice Return the length of the array of sub stakes
    */
    function getSubStakesLength(address _staker) external view returns (uint256) {
        return stakerInfo[_staker].subStakes.length;
    }

    /**
    * @notice Return the information about sub stake
    */
    function getSubStakeInfo(address _staker, uint256 _index)
    // TODO change to structure when ABIEncoderV2 is released (#1501)
//        public view returns (SubStakeInfo)
        // TODO "virtual" only for tests, probably will be removed after #1512
        external view virtual returns (
            uint16 firstPeriod,
            uint16 lastPeriod,
            uint16 unlockingDuration,
            uint128 lockedValue
        )
    {
        SubStakeInfo storage info = stakerInfo[_staker].subStakes[_index];
        firstPeriod = info.firstPeriod;
        lastPeriod = info.lastPeriod;
        unlockingDuration = info.unlockingDuration;
        lockedValue = info.lockedValue;
    }

    /**
    * @notice Return the length of the array of past downtime
    */
    function getPastDowntimeLength(address _staker) external view returns (uint256) {
        return stakerInfo[_staker].pastDowntime.length;
    }

    /**
    * @notice Return the information about past downtime
    */
    function  getPastDowntime(address _staker, uint256 _index)
    // TODO change to structure when ABIEncoderV2 is released (#1501)
//        public view returns (Downtime)
        external view returns (uint16 startPeriod, uint16 endPeriod)
    {
        Downtime storage downtime = stakerInfo[_staker].pastDowntime[_index];
        startPeriod = downtime.startPeriod;
        endPeriod = downtime.endPeriod;
    }

    //------------------ ERC900 connectors ----------------------

    function totalStakedForAt(address _owner, uint256 _blockNumber) public view override returns (uint256){
        return stakerInfo[_owner].history.getValueAt(_blockNumber);
    }

    function totalStakedAt(uint256 _blockNumber) public view override returns (uint256){
        return balanceHistory.getValueAt(_blockNumber);
    }

    function supportsHistory() external pure override returns (bool){
        return true;
    }

    //------------------------Upgradeable------------------------
    /**
    * @dev Get StakerInfo structure by delegatecall
    */
    function delegateGetStakerInfo(address _target, bytes32 _staker)
        internal returns (StakerInfo memory result)
    {
        bytes32 memoryAddress = delegateGetData(_target, this.stakerInfo.selector, 1, _staker, 0);
        assembly {
            result := memoryAddress
        }
    }

    /**
    * @dev Get SubStakeInfo structure by delegatecall
    */
    function delegateGetSubStakeInfo(address _target, bytes32 _staker, uint256 _index)
        internal returns (SubStakeInfo memory result)
    {
        bytes32 memoryAddress = delegateGetData(
            _target, this.getSubStakeInfo.selector, 2, _staker, bytes32(_index));
        assembly {
            result := memoryAddress
        }
    }

    /**
    * @dev Get Downtime structure by delegatecall
    */
    function delegateGetPastDowntime(address _target, bytes32 _staker, uint256 _index)
        internal returns (Downtime memory result)
    {
        bytes32 memoryAddress = delegateGetData(
            _target, this.getPastDowntime.selector, 2, _staker, bytes32(_index));
        assembly {
            result := memoryAddress
        }
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `verifyState`
    function verifyState(address _testTarget) public override virtual {
        super.verifyState(_testTarget);
        require(delegateGet(_testTarget, this.lockedPerPeriod.selector,
            bytes32(bytes2(RESERVED_PERIOD))) == lockedPerPeriod(RESERVED_PERIOD));
        require(address(delegateGet(_testTarget, this.stakerFromWorker.selector, bytes32(0))) ==
            stakerFromWorker[address(0)]);

        require(delegateGet(_testTarget, this.getStakersLength.selector) == stakers.length);
        if (stakers.length == 0) {
            return;
        }
        address stakerAddress = stakers[0];
        require(address(uint160(delegateGet(_testTarget, this.stakers.selector, 0))) == stakerAddress);
        StakerInfo storage info = stakerInfo[stakerAddress];
        bytes32 staker = bytes32(uint256(stakerAddress));
        StakerInfo memory infoToCheck = delegateGetStakerInfo(_testTarget, staker);
        require(infoToCheck.value == info.value &&
            infoToCheck.currentCommittedPeriod == info.currentCommittedPeriod &&
            infoToCheck.nextCommittedPeriod == info.nextCommittedPeriod &&
            infoToCheck.flags == info.flags &&
            infoToCheck.lastCommittedPeriod == info.lastCommittedPeriod &&
            infoToCheck.completedWork == info.completedWork &&
            infoToCheck.worker == info.worker &&
            infoToCheck.workerStartPeriod == info.workerStartPeriod);

        require(delegateGet(_testTarget, this.getPastDowntimeLength.selector, staker) ==
            info.pastDowntime.length);
        for (uint256 i = 0; i < info.pastDowntime.length && i < MAX_CHECKED_VALUES; i++) {
            Downtime storage downtime = info.pastDowntime[i];
            Downtime memory downtimeToCheck = delegateGetPastDowntime(_testTarget, staker, i);
            require(downtimeToCheck.startPeriod == downtime.startPeriod &&
                downtimeToCheck.endPeriod == downtime.endPeriod);
        }

        require(delegateGet(_testTarget, this.getSubStakesLength.selector, staker) == info.subStakes.length);
        for (uint256 i = 0; i < info.subStakes.length && i < MAX_CHECKED_VALUES; i++) {
            SubStakeInfo storage subStakeInfo = info.subStakes[i];
            SubStakeInfo memory subStakeInfoToCheck = delegateGetSubStakeInfo(_testTarget, staker, i);
            require(subStakeInfoToCheck.firstPeriod == subStakeInfo.firstPeriod &&
                subStakeInfoToCheck.lastPeriod == subStakeInfo.lastPeriod &&
                subStakeInfoToCheck.unlockingDuration == subStakeInfo.unlockingDuration &&
                subStakeInfoToCheck.lockedValue == subStakeInfo.lockedValue);
        }

        // it's not perfect because checks not only slot value but also decoding
        // at least without additional functions
        require(delegateGet(_testTarget, this.totalStakedForAt.selector, staker, bytes32(block.number)) ==
            totalStakedForAt(stakerAddress, block.number));
        require(delegateGet(_testTarget, this.totalStakedAt.selector, bytes32(block.number)) ==
            totalStakedAt(block.number));

        if (info.worker != address(0)) {
            require(address(delegateGet(_testTarget, this.stakerFromWorker.selector, bytes32(uint256(info.worker)))) ==
                stakerFromWorker[info.worker]);
        }
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `finishUpgrade`
    function finishUpgrade(address _target) public override virtual {
        super.finishUpgrade(_target);
        // Create fake period
        _lockedPerPeriod[RESERVED_PERIOD] = 111;

        // Create fake worker
        stakerFromWorker[address(0)] = address(this);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;


// Minimum interface to interact with Aragon's Aggregator
interface IERC900History {
    function totalStakedForAt(address addr, uint256 blockNumber) external view returns (uint256);
    function totalStakedAt(uint256 blockNumber) external view returns (uint256);
    function supportsHistory() external pure returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "./NuCypherToken.sol";
import "../zeppelin/math/Math.sol";
import "./proxy/Upgradeable.sol";
import "./lib/AdditionalMath.sol";
import "../zeppelin/token/ERC20/SafeERC20.sol";


/**
* @title Issuer
* @notice Contract for calculation of issued tokens
* @dev |v3.4.1|
*/
abstract contract Issuer is Upgradeable {
    using SafeERC20 for NuCypherToken;
    using AdditionalMath for uint32;

    event Donated(address indexed sender, uint256 value);
    /// Issuer is initialized with a reserved reward
    event Initialized(uint256 reservedReward);

    uint128 constant MAX_UINT128 = uint128(0) - 1;

    NuCypherToken public immutable token;
    uint128 public immutable totalSupply;

    // d * k2
    uint256 public immutable mintingCoefficient;
    // k1
    uint256 public immutable lockDurationCoefficient1;
    // k2
    uint256 public immutable lockDurationCoefficient2;

    uint32 public immutable genesisSecondsPerPeriod;
    uint32 public immutable secondsPerPeriod;

    // kmax
    uint16 public immutable maximumRewardedPeriods;

    uint256 public immutable firstPhaseMaxIssuance;
    uint256 public immutable firstPhaseTotalSupply;

    /**
    * Current supply is used in the minting formula and is stored to prevent different calculation
    * for stakers which get reward in the same period. There are two values -
    * supply for previous period (used in formula) and supply for current period which accumulates value
    * before end of period.
    */
    uint128 public previousPeriodSupply;
    uint128 public currentPeriodSupply;
    uint16 public currentMintingPeriod;

    /**
    * @notice Constructor sets address of token contract and coefficients for minting
    * @dev Minting formula for one sub-stake in one period for the first phase
    firstPhaseMaxIssuance * (lockedValue / totalLockedValue) * (k1 + min(allLockedPeriods, kmax)) / k2
    * @dev Minting formula for one sub-stake in one period for the second phase
    (totalSupply - currentSupply) / d * (lockedValue / totalLockedValue) * (k1 + min(allLockedPeriods, kmax)) / k2
    if allLockedPeriods > maximumRewardedPeriods then allLockedPeriods = maximumRewardedPeriods
    * @param _token Token contract
    * @param _genesisHoursPerPeriod Size of period in hours at genesis
    * @param _hoursPerPeriod Size of period in hours
    * @param _issuanceDecayCoefficient (d) Coefficient which modifies the rate at which the maximum issuance decays,
    * only applicable to Phase 2. d = 365 * half-life / LOG2 where default half-life = 2.
    * See Equation 10 in Staking Protocol & Economics paper
    * @param _lockDurationCoefficient1 (k1) Numerator of the coefficient which modifies the extent 
    * to which a stake's lock duration affects the subsidy it receives. Affects stakers differently. 
    * Applicable to Phase 1 and Phase 2. k1 = k2 * small_stake_multiplier where default small_stake_multiplier = 0.5.  
    * See Equation 8 in Staking Protocol & Economics paper.
    * @param _lockDurationCoefficient2 (k2) Denominator of the coefficient which modifies the extent
    * to which a stake's lock duration affects the subsidy it receives. Affects stakers differently.
    * Applicable to Phase 1 and Phase 2. k2 = maximum_rewarded_periods / (1 - small_stake_multiplier)
    * where default maximum_rewarded_periods = 365 and default small_stake_multiplier = 0.5.
    * See Equation 8 in Staking Protocol & Economics paper.
    * @param _maximumRewardedPeriods (kmax) Number of periods beyond which a stake's lock duration
    * no longer increases the subsidy it receives. kmax = reward_saturation * 365 where default reward_saturation = 1.
    * See Equation 8 in Staking Protocol & Economics paper.
    * @param _firstPhaseTotalSupply Total supply for the first phase
    * @param _firstPhaseMaxIssuance (Imax) Maximum number of new tokens minted per period during Phase 1.
    * See Equation 7 in Staking Protocol & Economics paper.
    */
    constructor(
        NuCypherToken _token,
        uint32 _genesisHoursPerPeriod,
        uint32 _hoursPerPeriod,
        uint256 _issuanceDecayCoefficient,
        uint256 _lockDurationCoefficient1,
        uint256 _lockDurationCoefficient2,
        uint16 _maximumRewardedPeriods,
        uint256 _firstPhaseTotalSupply,
        uint256 _firstPhaseMaxIssuance
    ) {
        uint256 localTotalSupply = _token.totalSupply();
        require(localTotalSupply > 0 &&
            _issuanceDecayCoefficient != 0 &&
            _hoursPerPeriod != 0 &&
            _genesisHoursPerPeriod != 0 &&
            _genesisHoursPerPeriod <= _hoursPerPeriod &&
            _lockDurationCoefficient1 != 0 &&
            _lockDurationCoefficient2 != 0 &&
            _maximumRewardedPeriods != 0);
        require(localTotalSupply <= uint256(MAX_UINT128), "Token contract has supply more than supported");

        uint256 maxLockDurationCoefficient = _maximumRewardedPeriods + _lockDurationCoefficient1;
        uint256 localMintingCoefficient = _issuanceDecayCoefficient * _lockDurationCoefficient2;
        require(maxLockDurationCoefficient > _maximumRewardedPeriods &&
            localMintingCoefficient / _issuanceDecayCoefficient ==  _lockDurationCoefficient2 &&
            // worst case for `totalLockedValue * d * k2`, when totalLockedValue == totalSupply
            localTotalSupply * localMintingCoefficient / localTotalSupply == localMintingCoefficient &&
            // worst case for `(totalSupply - currentSupply) * lockedValue * (k1 + min(allLockedPeriods, kmax))`,
            // when currentSupply == 0, lockedValue == totalSupply
            localTotalSupply * localTotalSupply * maxLockDurationCoefficient / localTotalSupply / localTotalSupply ==
                maxLockDurationCoefficient,
            "Specified parameters cause overflow");

        require(maxLockDurationCoefficient <= _lockDurationCoefficient2,
            "Resulting locking duration coefficient must be less than 1");
        require(_firstPhaseTotalSupply <= localTotalSupply, "Too many tokens for the first phase");
        require(_firstPhaseMaxIssuance <= _firstPhaseTotalSupply, "Reward for the first phase is too high");

        token = _token;
        secondsPerPeriod = _hoursPerPeriod.mul32(1 hours);
        genesisSecondsPerPeriod = _genesisHoursPerPeriod.mul32(1 hours);
        lockDurationCoefficient1 = _lockDurationCoefficient1;
        lockDurationCoefficient2 = _lockDurationCoefficient2;
        maximumRewardedPeriods = _maximumRewardedPeriods;
        firstPhaseTotalSupply = _firstPhaseTotalSupply;
        firstPhaseMaxIssuance = _firstPhaseMaxIssuance;
        totalSupply = uint128(localTotalSupply);
        mintingCoefficient = localMintingCoefficient;
    }

    /**
    * @dev Checks contract initialization
    */
    modifier isInitialized()
    {
        require(currentMintingPeriod != 0);
        _;
    }

    /**
    * @return Number of current period
    */
    function getCurrentPeriod() public view returns (uint16) {
        return uint16(block.timestamp / secondsPerPeriod);
    }

    /**
    * @return Recalculate period value using new basis
    */
    function recalculatePeriod(uint16 _period) internal view returns (uint16) {
        return uint16(uint256(_period) * genesisSecondsPerPeriod / secondsPerPeriod);
    }

    /**
    * @notice Initialize reserved tokens for reward
    */
    function initialize(uint256 _reservedReward, address _sourceOfFunds) external onlyOwner {
        require(currentMintingPeriod == 0);
        // Reserved reward must be sufficient for at least one period of the first phase
        require(firstPhaseMaxIssuance <= _reservedReward);
        currentMintingPeriod = getCurrentPeriod();
        currentPeriodSupply = totalSupply - uint128(_reservedReward);
        previousPeriodSupply = currentPeriodSupply;
        token.safeTransferFrom(_sourceOfFunds, address(this), _reservedReward);
        emit Initialized(_reservedReward);
    }

    /**
    * @notice Function to mint tokens for one period.
    * @param _currentPeriod Current period number.
    * @param _lockedValue The amount of tokens that were locked by user in specified period.
    * @param _totalLockedValue The amount of tokens that were locked by all users in specified period.
    * @param _allLockedPeriods The max amount of periods during which tokens will be locked after specified period.
    * @return amount Amount of minted tokens.
    */
    function mint(
        uint16 _currentPeriod,
        uint256 _lockedValue,
        uint256 _totalLockedValue,
        uint16 _allLockedPeriods
    )
        internal returns (uint256 amount)
    {
        if (currentPeriodSupply == totalSupply) {
            return 0;
        }

        if (_currentPeriod > currentMintingPeriod) {
            previousPeriodSupply = currentPeriodSupply;
            currentMintingPeriod = _currentPeriod;
        }

        uint256 currentReward;
        uint256 coefficient;

        // first phase
        // firstPhaseMaxIssuance * lockedValue * (k1 + min(allLockedPeriods, kmax)) / (totalLockedValue * k2)
        if (previousPeriodSupply + firstPhaseMaxIssuance <= firstPhaseTotalSupply) {
            currentReward = firstPhaseMaxIssuance;
            coefficient = lockDurationCoefficient2;
        // second phase
        // (totalSupply - currentSupply) * lockedValue * (k1 + min(allLockedPeriods, kmax)) / (totalLockedValue * d * k2)
        } else {
            currentReward = totalSupply - previousPeriodSupply;
            coefficient = mintingCoefficient;
        }

        uint256 allLockedPeriods =
            AdditionalMath.min16(_allLockedPeriods, maximumRewardedPeriods) + lockDurationCoefficient1;
        amount = (uint256(currentReward) * _lockedValue * allLockedPeriods) /
            (_totalLockedValue * coefficient);

        // rounding the last reward
        uint256 maxReward = getReservedReward();
        if (amount == 0) {
            amount = 1;
        } else if (amount > maxReward) {
            amount = maxReward;
        }

        currentPeriodSupply += uint128(amount);
    }

    /**
    * @notice Return tokens for future minting
    * @param _amount Amount of tokens
    */
    function unMint(uint256 _amount) internal {
        previousPeriodSupply -= uint128(_amount);
        currentPeriodSupply -= uint128(_amount);
    }

    /**
    * @notice Donate sender's tokens. Amount of tokens will be returned for future minting
    * @param _value Amount to donate
    */
    function donate(uint256 _value) external isInitialized {
        token.safeTransferFrom(msg.sender, address(this), _value);
        unMint(_value);
        emit Donated(msg.sender, _value);
    }

    /**
    * @notice Returns the number of tokens that can be minted
    */
    function getReservedReward() public view returns (uint256) {
        return totalSupply - currentPeriodSupply;
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `verifyState`
    function verifyState(address _testTarget) public override virtual {
        super.verifyState(_testTarget);
        require(uint16(delegateGet(_testTarget, this.currentMintingPeriod.selector)) == currentMintingPeriod);
        require(uint128(delegateGet(_testTarget, this.previousPeriodSupply.selector)) == previousPeriodSupply);
        require(uint128(delegateGet(_testTarget, this.currentPeriodSupply.selector)) == currentPeriodSupply);
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `finishUpgrade`
    function finishUpgrade(address _target) public override virtual {
        super.finishUpgrade(_target);
        // recalculate currentMintingPeriod if needed
        if (currentMintingPeriod > getCurrentPeriod()) {
            currentMintingPeriod = recalculatePeriod(currentMintingPeriod);
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/token/ERC20/ERC20Detailed.sol";


/**
* @title NuCypherToken
* @notice ERC20 token
* @dev Optional approveAndCall() functionality to notify a contract if an approve() has occurred.
*/
contract NuCypherToken is ERC20, ERC20Detailed('NuCypher', 'NU', 18) {

    /**
    * @notice Set amount of tokens
    * @param _totalSupplyOfTokens Total number of tokens
    */
    constructor (uint256 _totalSupplyOfTokens) {
        _mint(msg.sender, _totalSupplyOfTokens);
    }

    /**
    * @notice Approves and then calls the receiving contract
    *
    * @dev call the receiveApproval function on the contract you want to be notified.
    * receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
    */
    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData)
        external returns (bool success)
    {
        approve(_spender, _value);
        TokenRecipient(_spender).receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
    }

}


/**
* @dev Interface to use the receiveApproval method
*/
interface TokenRecipient {

    /**
    * @notice Receives a notification of approval of the transfer
    * @param _from Sender of approval
    * @param _value  The amount of tokens to be spent
    * @param _tokenContract Address of the token contract
    * @param _extraData Extra data
    */
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes calldata _extraData) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


import "./IERC20.sol";
import "../../math/SafeMath.sol";


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(value == 0 || _allowed[msg.sender][spender] == 0);

        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


import "./IERC20.sol";


/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Calculates the average of two numbers. Since these are integers,
     * averages of an even and odd number cannot be represented, and will be
     * rounded down.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "../../zeppelin/ownership/Ownable.sol";


/**
* @notice Base contract for upgradeable contract
* @dev Inherited contract should implement verifyState(address) method by checking storage variables
* (see verifyState(address) in Dispatcher). Also contract should implement finishUpgrade(address)
* if it is using constructor parameters by coping this parameters to the dispatcher storage
*/
abstract contract Upgradeable is Ownable {

    event StateVerified(address indexed testTarget, address sender);
    event UpgradeFinished(address indexed target, address sender);

    /**
    * @dev Contracts at the target must reserve the same location in storage for this address as in Dispatcher
    * Stored data actually lives in the Dispatcher
    * However the storage layout is specified here in the implementing contracts
    */
    address public target;

    /**
    * @dev Previous contract address (if available). Used for rollback
    */
    address public previousTarget;

    /**
    * @dev Upgrade status. Explicit `uint8` type is used instead of `bool` to save gas by excluding 0 value
    */
    uint8 public isUpgrade;

    /**
    * @dev Guarantees that next slot will be separated from the previous
    */
    uint256 stubSlot;

    /**
    * @dev Constants for `isUpgrade` field
    */
    uint8 constant UPGRADE_FALSE = 1;
    uint8 constant UPGRADE_TRUE = 2;

    /**
    * @dev Checks that function executed while upgrading
    * Recommended to add to `verifyState` and `finishUpgrade` methods
    */
    modifier onlyWhileUpgrading()
    {
        require(isUpgrade == UPGRADE_TRUE);
        _;
    }

    /**
    * @dev Method for verifying storage state.
    * Should check that new target contract returns right storage value
    */
    function verifyState(address _testTarget) public virtual onlyWhileUpgrading {
        emit StateVerified(_testTarget, msg.sender);
    }

    /**
    * @dev Copy values from the new target to the current storage
    * @param _target New target contract address
    */
    function finishUpgrade(address _target) public virtual onlyWhileUpgrading {
        emit UpgradeFinished(_target, msg.sender);
    }

    /**
    * @dev Base method to get data
    * @param _target Target to call
    * @param _selector Method selector
    * @param _numberOfArguments Number of used arguments
    * @param _argument1 First method argument
    * @param _argument2 Second method argument
    * @return memoryAddress Address in memory where the data is located
    */
    function delegateGetData(
        address _target,
        bytes4 _selector,
        uint8 _numberOfArguments,
        bytes32 _argument1,
        bytes32 _argument2
    )
        internal returns (bytes32 memoryAddress)
    {
        assembly {
            memoryAddress := mload(0x40)
            mstore(memoryAddress, _selector)
            if gt(_numberOfArguments, 0) {
                mstore(add(memoryAddress, 0x04), _argument1)
            }
            if gt(_numberOfArguments, 1) {
                mstore(add(memoryAddress, 0x24), _argument2)
            }
            switch delegatecall(gas(), _target, memoryAddress, add(0x04, mul(0x20, _numberOfArguments)), 0, 0)
                case 0 {
                    revert(memoryAddress, 0)
                }
                default {
                    returndatacopy(memoryAddress, 0x0, returndatasize())
                }
        }
    }

    /**
    * @dev Call "getter" without parameters.
    * Result should not exceed 32 bytes
    */
    function delegateGet(address _target, bytes4 _selector)
        internal returns (uint256 result)
    {
        bytes32 memoryAddress = delegateGetData(_target, _selector, 0, 0, 0);
        assembly {
            result := mload(memoryAddress)
        }
    }

    /**
    * @dev Call "getter" with one parameter.
    * Result should not exceed 32 bytes
    */
    function delegateGet(address _target, bytes4 _selector, bytes32 _argument)
        internal returns (uint256 result)
    {
        bytes32 memoryAddress = delegateGetData(_target, _selector, 1, _argument, 0);
        assembly {
            result := mload(memoryAddress)
        }
    }

    /**
    * @dev Call "getter" with two parameters.
    * Result should not exceed 32 bytes
    */
    function delegateGet(
        address _target,
        bytes4 _selector,
        bytes32 _argument1,
        bytes32 _argument2
    )
        internal returns (uint256 result)
    {
        bytes32 memoryAddress = delegateGetData(_target, _selector, 2, _argument1, _argument2);
        assembly {
            result := mload(memoryAddress)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "../../zeppelin/math/SafeMath.sol";


/**
* @notice Additional math operations
*/
library AdditionalMath {
    using SafeMath for uint256;

    function max16(uint16 a, uint16 b) internal pure returns (uint16) {
        return a >= b ? a : b;
    }

    function min16(uint16 a, uint16 b) internal pure returns (uint16) {
        return a < b ? a : b;
    }

    /**
    * @notice Division and ceil
    */
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a.add(b) - 1) / b;
    }

    /**
    * @dev Adds signed value to unsigned value, throws on overflow.
    */
    function addSigned(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return a.add(uint256(b));
        } else {
            return a.sub(uint256(-b));
        }
    }

    /**
    * @dev Subtracts signed value from unsigned value, throws on overflow.
    */
    function subSigned(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return a.sub(uint256(b));
        } else {
            return a.add(uint256(-b));
        }
    }

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add16(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub16(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds signed value to unsigned value, throws on overflow.
    */
    function addSigned16(uint16 a, int16 b) internal pure returns (uint16) {
        if (b >= 0) {
            return add16(a, uint16(b));
        } else {
            return sub16(a, uint16(-b));
        }
    }

    /**
    * @dev Subtracts signed value from unsigned value, throws on overflow.
    */
    function subSigned16(uint16 a, int16 b) internal pure returns (uint16) {
        if (b >= 0) {
            return sub16(a, uint16(b));
        } else {
            return add16(a, uint16(-b));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


import "./IERC20.sol";
import "../../math/SafeMath.sol";


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

/**
* @dev Taken from https://github.com/ethereum/solidity-examples/blob/master/src/bits/Bits.sol
*/
library Bits {

    uint256 internal constant ONE = uint256(1);

    /**
    * @notice Sets the bit at the given 'index' in 'self' to:
    *  '1' - if the bit is '0'
    *  '0' - if the bit is '1'
    * @return The modified value
    */
    function toggleBit(uint256 self, uint8 index) internal pure returns (uint256) {
        return self ^ ONE << index;
    }

    /**
    * @notice Get the value of the bit at the given 'index' in 'self'.
    */
    function bit(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8(self >> index & 1);
    }

    /**
    * @notice Check if the bit at the given 'index' in 'self' is set.
    * @return  'true' - if the value of the bit is '1',
    *          'false' - if the value of the bit is '0'
    */
    function bitSet(uint256 self, uint8 index) internal pure returns (bool) {
        return self >> index & 1 == 1;
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


/**
 * @title Snapshot
 * @notice Manages snapshots of size 128 bits (32 bits for timestamp, 96 bits for value)
 * 96 bits is enough for storing NU token values, and 32 bits should be OK for block numbers
 * @dev Since each storage slot can hold two snapshots, new slots are allocated every other TX. Thus, gas cost of adding snapshots is 51400 and 36400 gas, alternately.
 * Based on Aragon's Checkpointing (https://https://github.com/aragonone/voting-connectors/blob/master/shared/contract-utils/contracts/Checkpointing.sol)
 * On average, adding snapshots spends ~6500 less gas than the 256-bit checkpoints of Aragon's Checkpointing
 */
library Snapshot {

    function encodeSnapshot(uint32 _time, uint96 _value) internal pure returns(uint128) {
        return uint128(uint256(_time) << 96 | uint256(_value));
    }

    function decodeSnapshot(uint128 _snapshot) internal pure returns(uint32 time, uint96 value){
        time = uint32(bytes4(bytes16(_snapshot)));
        value = uint96(_snapshot);
    }

    function addSnapshot(uint128[] storage _self, uint256 _value) internal {
        addSnapshot(_self, block.number, _value);
    }

    function addSnapshot(uint128[] storage _self, uint256 _time, uint256 _value) internal {
        uint256 length = _self.length;
        if (length != 0) {
            (uint32 currentTime, ) = decodeSnapshot(_self[length - 1]);
            if (uint32(_time) == currentTime) {
                _self[length - 1] = encodeSnapshot(uint32(_time), uint96(_value));
                return;
            } else if (uint32(_time) < currentTime){
                revert();
            }
        }
        _self.push(encodeSnapshot(uint32(_time), uint96(_value)));
    }

    function lastSnapshot(uint128[] storage _self) internal view returns (uint32, uint96) {
        uint256 length = _self.length;
        if (length > 0) {
            return decodeSnapshot(_self[length - 1]);
        }

        return (0, 0);
    }

    function lastValue(uint128[] storage _self) internal view returns (uint96) {
        (, uint96 value) = lastSnapshot(_self);
        return value;
    }

    function getValueAt(uint128[] storage _self, uint256 _time256) internal view returns (uint96) {
        uint32 _time = uint32(_time256);
        uint256 length = _self.length;

        // Short circuit if there's no checkpoints yet
        // Note that this also lets us avoid using SafeMath later on, as we've established that
        // there must be at least one checkpoint
        if (length == 0) {
            return 0;
        }

        // Check last checkpoint
        uint256 lastIndex = length - 1;
        (uint32 snapshotTime, uint96 snapshotValue) = decodeSnapshot(_self[length - 1]);
        if (_time >= snapshotTime) {
            return snapshotValue;
        }

        // Check first checkpoint (if not already checked with the above check on last)
        (snapshotTime, snapshotValue) = decodeSnapshot(_self[0]);
        if (length == 1 || _time < snapshotTime) {
            return 0;
        }

        // Do binary search
        // As we've already checked both ends, we don't need to check the last checkpoint again
        uint256 low = 0;
        uint256 high = lastIndex - 1;
        uint32 midTime;
        uint96 midValue;

        while (high > low) {
            uint256 mid = (high + low + 1) / 2; // average, ceil round
            (midTime, midValue) = decodeSnapshot(_self[mid]);

            if (_time > midTime) {
                low = mid;
            } else if (_time < midTime) {
                // Note that we don't need SafeMath here because mid must always be greater than 0
                // from the while condition
                high = mid - 1;
            } else {
                // _time == midTime
                return midValue;
            }
        }

        (, snapshotValue) = decodeSnapshot(_self[low]);
        return snapshotValue;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

interface IForwarder {

    function isForwarder() external pure returns (bool);
    function canForward(address sender, bytes calldata evmCallScript) external view returns (bool);
    function forward(bytes calldata evmCallScript) external;
    
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

interface TokenManager {

    function mint(address _receiver, uint256 _amount) external;
    function issue(uint256 _amount) external;
    function assign(address _receiver, uint256 _amount) external;
    function burn(address _holder, uint256 _amount) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

import "./IForwarder.sol";

// Interface for Voting contract, as found in https://github.com/aragon/aragon-apps/blob/master/apps/voting/contracts/Voting.sol
interface Voting is IForwarder{

    enum VoterState { Absent, Yea, Nay }

    // Public getters
    function token() external returns (address);
    function supportRequiredPct() external returns (uint64);
    function minAcceptQuorumPct() external returns (uint64);
    function voteTime() external returns (uint64);
    function votesLength() external returns (uint256);

    // Setters
    function changeSupportRequiredPct(uint64 _supportRequiredPct) external;
    function changeMinAcceptQuorumPct(uint64 _minAcceptQuorumPct) external;

    // Creating new votes
    function newVote(bytes calldata _executionScript, string memory _metadata) external returns (uint256 voteId);
    function newVote(bytes calldata _executionScript, string memory _metadata, bool _castVote, bool _executesIfDecided)
        external returns (uint256 voteId);

    // Voting
    function canVote(uint256 _voteId, address _voter) external view returns (bool);
    function vote(uint256 _voteId, bool _supports, bool _executesIfDecided) external;

    // Executing a passed vote
    function canExecute(uint256 _voteId) external view returns (bool);
    function executeVote(uint256 _voteId) external;

    // Additional info
    function getVote(uint256 _voteId) external view
        returns (
            bool open,
            bool executed,
            uint64 startDate,
            uint64 snapshotBlock,
            uint64 supportRequired,
            uint64 minAcceptQuorum,
            uint256 yea,
            uint256 nay,
            uint256 votingPower,
            bytes memory script
        );
    function getVoterState(uint256 _voteId, address _voter) external view returns (VoterState);

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "../zeppelin/math/SafeMath.sol";


/**
* @notice Multi-signature contract with off-chain signing
*/
contract MultiSig {
    using SafeMath for uint256;

    event Executed(address indexed sender, uint256 indexed nonce, address indexed destination, uint256 value);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event RequirementChanged(uint16 required);

    uint256 constant public MAX_OWNER_COUNT = 50;

    uint256 public nonce;
    uint8 public required;
    mapping (address => bool) public isOwner;
    address[] public owners;

    /**
    * @notice Only this contract can call method
    */
    modifier onlyThisContract() {
        require(msg.sender == address(this));
        _;
    }

    receive() external payable {}

    /**
    * @param _required Number of required signings
    * @param _owners List of initial owners.
    */
    constructor (uint8 _required, address[] memory _owners) {
        require(_owners.length <= MAX_OWNER_COUNT &&
            _required <= _owners.length &&
            _required > 0);

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(!isOwner[owner] && owner != address(0));
            isOwner[owner] = true;
        }
        owners = _owners;
        required = _required;
    }

    /**
    * @notice Get unsigned hash for transaction parameters
    * @dev Follows ERC191 signature scheme: https://github.com/ethereum/EIPs/issues/191
    * @param _sender Trustee who will execute the transaction
    * @param _destination Destination address
    * @param _value Amount of ETH to transfer
    * @param _data Call data
    * @param _nonce Nonce
    */
    function getUnsignedTransactionHash(
        address _sender,
        address _destination,
        uint256 _value,
        bytes memory _data,
        uint256 _nonce
    )
        public view returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(byte(0x19), byte(0), address(this), _sender, _destination, _value, _data, _nonce));
    }

    /**
    * @dev Note that address recovered from signatures must be strictly increasing
    * @param _sigV Array of signatures values V
    * @param _sigR Array of signatures values R
    * @param _sigS Array of signatures values S
    * @param _destination Destination address
    * @param _value Amount of ETH to transfer
    * @param _data Call data
    */
    function execute(
        uint8[] calldata _sigV,
        bytes32[] calldata _sigR,
        bytes32[] calldata _sigS,
        address _destination,
        uint256 _value,
        bytes calldata _data
    )
        external
    {
        require(_sigR.length >= required &&
            _sigR.length == _sigS.length &&
            _sigR.length == _sigV.length);

        bytes32 txHash = getUnsignedTransactionHash(msg.sender, _destination, _value, _data, nonce);
        address lastAdd = address(0);
        for (uint256 i = 0; i < _sigR.length; i++) {
            address recovered = ecrecover(txHash, _sigV[i], _sigR[i], _sigS[i]);
            require(recovered > lastAdd && isOwner[recovered]);
            lastAdd = recovered;
        }

        emit Executed(msg.sender, nonce, _destination, _value);
        nonce = nonce.add(1);
        (bool callSuccess,) = _destination.call{value: _value}(_data);
        require(callSuccess);
    }

    /**
    * @notice Allows to add a new owner
    * @dev Transaction has to be sent by `execute` method.
    * @param _owner Address of new owner
    */
    function addOwner(address _owner)
        external
        onlyThisContract
    {
        require(owners.length < MAX_OWNER_COUNT &&
            _owner != address(0) &&
            !isOwner[_owner]);
        isOwner[_owner] = true;
        owners.push(_owner);
        emit OwnerAdded(_owner);
    }

    /**
    * @notice Allows to remove an owner
    * @dev Transaction has to be sent by `execute` method.
    * @param _owner Address of owner
    */
    function removeOwner(address _owner)
        external
        onlyThisContract
    {
        require(owners.length > required && isOwner[_owner]);
        isOwner[_owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        emit OwnerRemoved(_owner);
    }

    /**
    * @notice Returns the number of owners of this MultiSig
    */
    function getNumberOfOwners() external view returns (uint256) {
        return owners.length;
    }

    /**
    * @notice Allows to change the number of required signatures
    * @dev Transaction has to be sent by `execute` method
    * @param _required Number of required signatures
    */
    function changeRequirement(uint8 _required)
        external
        onlyThisContract
    {
        require(_required <= owners.length && _required > 0);
        required = _required;
        emit RequirementChanged(_required);
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "../zeppelin/token/ERC20/SafeERC20.sol";
import "../zeppelin/math/SafeMath.sol";
import "../zeppelin/math/Math.sol";
import "../zeppelin/utils/Address.sol";
import "./lib/AdditionalMath.sol";
import "./lib/SignatureVerifier.sol";
import "./StakingEscrow.sol";
import "./NuCypherToken.sol";
import "./proxy/Upgradeable.sol";


/**
* @title PolicyManager
* @notice Contract holds policy data and locks accrued policy fees
* @dev |v6.3.1|
*/
contract PolicyManager is Upgradeable {
    using SafeERC20 for NuCypherToken;
    using SafeMath for uint256;
    using AdditionalMath for uint256;
    using AdditionalMath for int256;
    using AdditionalMath for uint16;
    using Address for address payable;

    event PolicyCreated(
        bytes16 indexed policyId,
        address indexed sponsor,
        address indexed owner,
        uint256 feeRate,
        uint64 startTimestamp,
        uint64 endTimestamp,
        uint256 numberOfNodes
    );
    event ArrangementRevoked(
        bytes16 indexed policyId,
        address indexed sender,
        address indexed node,
        uint256 value
    );
    event RefundForArrangement(
        bytes16 indexed policyId,
        address indexed sender,
        address indexed node,
        uint256 value
    );
    event PolicyRevoked(bytes16 indexed policyId, address indexed sender, uint256 value);
    event RefundForPolicy(bytes16 indexed policyId, address indexed sender, uint256 value);
    event MinFeeRateSet(address indexed node, uint256 value);
    // TODO #1501
    // Range range
    event FeeRateRangeSet(address indexed sender, uint256 min, uint256 defaultValue, uint256 max);
    event Withdrawn(address indexed node, address indexed recipient, uint256 value);

    struct ArrangementInfo {
        address node;
        uint256 indexOfDowntimePeriods;
        uint16 lastRefundedPeriod;
    }

    struct Policy {
        bool disabled;
        address payable sponsor;
        address owner;

        uint128 feeRate;
        uint64 startTimestamp;
        uint64 endTimestamp;

        uint256 reservedSlot1;
        uint256 reservedSlot2;
        uint256 reservedSlot3;
        uint256 reservedSlot4;
        uint256 reservedSlot5;

        ArrangementInfo[] arrangements;
    }

    struct NodeInfo {
        uint128 fee;
        uint16 previousFeePeriod;
        uint256 feeRate;
        uint256 minFeeRate;
        mapping (uint16 => int256) stub; // former slot for feeDelta
        mapping (uint16 => int256) feeDelta;
    }

    // TODO used only for `delegateGetNodeInfo`, probably will be removed after #1512
    struct MemoryNodeInfo {
        uint128 fee;
        uint16 previousFeePeriod;
        uint256 feeRate;
        uint256 minFeeRate;
    }

    struct Range {
        uint128 min;
        uint128 defaultValue;
        uint128 max;
    }

    bytes16 internal constant RESERVED_POLICY_ID = bytes16(0);
    address internal constant RESERVED_NODE = address(0);
    uint256 internal constant MAX_BALANCE = uint256(uint128(0) - 1);
    // controlled overflow to get max int256
    int256 public constant DEFAULT_FEE_DELTA = int256((uint256(0) - 1) >> 1);

    StakingEscrow public immutable escrow;
    uint32 public immutable genesisSecondsPerPeriod;
    uint32 public immutable secondsPerPeriod;

    mapping (bytes16 => Policy) public policies;
    mapping (address => NodeInfo) public nodes;
    Range public feeRateRange;
    uint64 public resetTimestamp;

    /**
    * @notice Constructor sets address of the escrow contract
    * @dev Put same address in both inputs variables except when migration is happening
    * @param _escrowDispatcher Address of escrow dispatcher
    * @param _escrowImplementation Address of escrow implementation
    */
    constructor(StakingEscrow _escrowDispatcher, StakingEscrow _escrowImplementation) {
        escrow = _escrowDispatcher;
        // if the input address is not the StakingEscrow then calling `secondsPerPeriod` will throw error
        uint32 localSecondsPerPeriod = _escrowImplementation.secondsPerPeriod();
        require(localSecondsPerPeriod > 0);
        secondsPerPeriod = localSecondsPerPeriod;
        uint32 localgenesisSecondsPerPeriod = _escrowImplementation.genesisSecondsPerPeriod();
        require(localgenesisSecondsPerPeriod > 0);
        genesisSecondsPerPeriod = localgenesisSecondsPerPeriod;
        // handle case when we deployed new StakingEscrow but not yet upgraded
        if (_escrowDispatcher != _escrowImplementation) {
            require(_escrowDispatcher.secondsPerPeriod() == localSecondsPerPeriod ||
                _escrowDispatcher.secondsPerPeriod() == localgenesisSecondsPerPeriod);
        }
    }

    /**
    * @dev Checks that sender is the StakingEscrow contract
    */
    modifier onlyEscrowContract()
    {
        require(msg.sender == address(escrow));
        _;
    }

    /**
    * @return Number of current period
    */
    function getCurrentPeriod() public view returns (uint16) {
        return uint16(block.timestamp / secondsPerPeriod);
    }

    /**
    * @return Recalculate period value using new basis
    */
    function recalculatePeriod(uint16 _period) internal view returns (uint16) {
        return uint16(uint256(_period) * genesisSecondsPerPeriod / secondsPerPeriod);
    }

    /**
    * @notice Register a node
    * @param _node Node address
    * @param _period Initial period
    */
    function register(address _node, uint16 _period) external onlyEscrowContract {
        NodeInfo storage nodeInfo = nodes[_node];
        require(nodeInfo.previousFeePeriod == 0 && _period < getCurrentPeriod());
        nodeInfo.previousFeePeriod = _period;
    }

    /**
    * @notice Migrate from the old period length to the new one
    * @param _node Node address
    */
    function migrate(address _node) external onlyEscrowContract {
        NodeInfo storage nodeInfo = nodes[_node];
        // with previous period length any previousFeePeriod will be greater than current period
        // this is a sign of not migrated node
        require(nodeInfo.previousFeePeriod >= getCurrentPeriod());
        nodeInfo.previousFeePeriod = recalculatePeriod(nodeInfo.previousFeePeriod);
        nodeInfo.feeRate = 0;
    }

    /**
    * @notice Set minimum, default & maximum fee rate for all stakers and all policies ('global fee range')
    */
    // TODO # 1501
    // function setFeeRateRange(Range calldata _range) external onlyOwner {
    function setFeeRateRange(uint128 _min, uint128 _default, uint128 _max) external onlyOwner {
        require(_min <= _default && _default <= _max);
        feeRateRange = Range(_min, _default, _max);
        emit FeeRateRangeSet(msg.sender, _min, _default, _max);
    }

    /**
    * @notice Set the minimum acceptable fee rate (set by staker for their associated worker)
    * @dev Input value must fall within `feeRateRange` (global fee range)
    */
    function setMinFeeRate(uint256 _minFeeRate) external {
        require(_minFeeRate >= feeRateRange.min &&
            _minFeeRate <= feeRateRange.max,
            "The staker's min fee rate must fall within the global fee range");
        NodeInfo storage nodeInfo = nodes[msg.sender];
        if (nodeInfo.minFeeRate == _minFeeRate) {
            return;
        }
        nodeInfo.minFeeRate = _minFeeRate;
        emit MinFeeRateSet(msg.sender, _minFeeRate);
    }

    /**
    * @notice Get the minimum acceptable fee rate (set by staker for their associated worker)
    */
    function getMinFeeRate(NodeInfo storage _nodeInfo) internal view returns (uint256) {
        // if minFeeRate has not been set or chosen value falls outside the global fee range
        // a default value is returned instead
        if (_nodeInfo.minFeeRate == 0 ||
            _nodeInfo.minFeeRate < feeRateRange.min ||
            _nodeInfo.minFeeRate > feeRateRange.max) {
            return feeRateRange.defaultValue;
        } else {
            return _nodeInfo.minFeeRate;
        }
    }

    /**
    * @notice Get the minimum acceptable fee rate (set by staker for their associated worker)
    */
    function getMinFeeRate(address _node) public view returns (uint256) {
        NodeInfo storage nodeInfo = nodes[_node];
        return getMinFeeRate(nodeInfo);
    }

    /**
    * @notice Create policy
    * @dev Generate policy id before creation
    * @param _policyId Policy id
    * @param _policyOwner Policy owner. Zero address means sender is owner
    * @param _endTimestamp End timestamp of the policy in seconds
    * @param _nodes Nodes that will handle policy
    */
    function createPolicy(
        bytes16 _policyId,
        address _policyOwner,
        uint64 _endTimestamp,
        address[] calldata _nodes
    )
        external payable
    {
        require(
            _endTimestamp > block.timestamp &&
            msg.value > 0
        );

        require(address(this).balance <= MAX_BALANCE);
        uint16 currentPeriod = getCurrentPeriod();
        uint16 endPeriod = uint16(_endTimestamp / secondsPerPeriod) + 1;
        uint256 numberOfPeriods = endPeriod - currentPeriod;

        uint128 feeRate = uint128(msg.value.div(_nodes.length) / numberOfPeriods);
        require(feeRate > 0 && feeRate * numberOfPeriods * _nodes.length  == msg.value);

        Policy storage policy = createPolicy(_policyId, _policyOwner, _endTimestamp, feeRate, _nodes.length);

        for (uint256 i = 0; i < _nodes.length; i++) {
            address node = _nodes[i];
            addFeeToNode(currentPeriod, endPeriod, node, feeRate, int256(feeRate));
            policy.arrangements.push(ArrangementInfo(node, 0, 0));
        }
    }

    /**
    * @notice Create multiple policies with the same owner, nodes and length
    * @dev Generate policy ids before creation
    * @param _policyIds Policy ids
    * @param _policyOwner Policy owner. Zero address means sender is owner
    * @param _endTimestamp End timestamp of all policies in seconds
    * @param _nodes Nodes that will handle all policies
    */
    function createPolicies(
        bytes16[] calldata _policyIds,
        address _policyOwner,
        uint64 _endTimestamp,
        address[] calldata _nodes
    )
        external payable
    {
        require(
            _endTimestamp > block.timestamp &&
            msg.value > 0 &&
            _policyIds.length > 1
        );

        require(address(this).balance <= MAX_BALANCE);
        uint16 currentPeriod = getCurrentPeriod();
        uint16 endPeriod = uint16(_endTimestamp / secondsPerPeriod) + 1;
        uint256 numberOfPeriods = endPeriod - currentPeriod;

        uint128 feeRate = uint128(msg.value.div(_nodes.length) / numberOfPeriods / _policyIds.length);
        require(feeRate > 0 && feeRate * numberOfPeriods * _nodes.length * _policyIds.length == msg.value);

        for (uint256 i = 0; i < _policyIds.length; i++) {
            Policy storage policy = createPolicy(_policyIds[i], _policyOwner, _endTimestamp, feeRate, _nodes.length);

            for (uint256 j = 0; j < _nodes.length; j++) {
                policy.arrangements.push(ArrangementInfo(_nodes[j], 0, 0));
            }
        }

        int256 fee = int256(_policyIds.length * feeRate);

        for (uint256 i = 0; i < _nodes.length; i++) {
            address node = _nodes[i];
            addFeeToNode(currentPeriod, endPeriod, node, feeRate, fee);
        }
    }

    /**
    * @notice Create policy
    * @param _policyId Policy id
    * @param _policyOwner Policy owner. Zero address means sender is owner
    * @param _endTimestamp End timestamp of the policy in seconds
    * @param _feeRate Fee rate for policy
    * @param _nodesLength Number of nodes that will handle policy
    */
    function createPolicy(
        bytes16 _policyId,
        address _policyOwner,
        uint64 _endTimestamp,
        uint128 _feeRate,
        uint256 _nodesLength
    )
        internal returns (Policy storage policy)
    {
        policy = policies[_policyId];
        require(
            _policyId != RESERVED_POLICY_ID &&
            policy.feeRate == 0 &&
            !policy.disabled
        );

        policy.sponsor = msg.sender;
        policy.startTimestamp = uint64(block.timestamp);
        policy.endTimestamp = _endTimestamp;
        policy.feeRate = _feeRate;

        if (_policyOwner != msg.sender && _policyOwner != address(0)) {
            policy.owner = _policyOwner;
        }

        emit PolicyCreated(
            _policyId,
            msg.sender,
            _policyOwner == address(0) ? msg.sender : _policyOwner,
            _feeRate,
            policy.startTimestamp,
            policy.endTimestamp,
            _nodesLength
        );
    }

    /**
    * @notice Increase fee rate for specified node
    * @param _currentPeriod Current period
    * @param _endPeriod End period of policy
    * @param _node Node that will handle policy
    * @param _feeRate Fee rate for one policy
    * @param _overallFeeRate Fee rate for all policies
    */
    function addFeeToNode(
        uint16 _currentPeriod,
        uint16 _endPeriod,
        address _node,
        uint128 _feeRate,
        int256 _overallFeeRate
    )
        internal
    {
        require(_node != RESERVED_NODE);
        NodeInfo storage nodeInfo = nodes[_node];
        require(nodeInfo.previousFeePeriod != 0 &&
            nodeInfo.previousFeePeriod < _currentPeriod &&
            _feeRate >= getMinFeeRate(nodeInfo));
        // Check default value for feeDelta
        if (nodeInfo.feeDelta[_currentPeriod] == DEFAULT_FEE_DELTA) {
            nodeInfo.feeDelta[_currentPeriod] = _overallFeeRate;
        } else {
            // Overflow protection removed, because ETH total supply less than uint255/int256
            nodeInfo.feeDelta[_currentPeriod] += _overallFeeRate;
        }
        if (nodeInfo.feeDelta[_endPeriod] == DEFAULT_FEE_DELTA) {
            nodeInfo.feeDelta[_endPeriod] = -_overallFeeRate;
        } else {
            nodeInfo.feeDelta[_endPeriod] -= _overallFeeRate;
        }
        // Reset to default value if needed
        if (nodeInfo.feeDelta[_currentPeriod] == 0) {
            nodeInfo.feeDelta[_currentPeriod] = DEFAULT_FEE_DELTA;
        }
        if (nodeInfo.feeDelta[_endPeriod] == 0) {
            nodeInfo.feeDelta[_endPeriod] = DEFAULT_FEE_DELTA;
        }
    }

    /**
    * @notice Get policy owner
    */
    function getPolicyOwner(bytes16 _policyId) public view returns (address) {
        Policy storage policy = policies[_policyId];
        return policy.owner == address(0) ? policy.sponsor : policy.owner;
    }

    /**
    * @notice Call from StakingEscrow to update node info once per period.
    * Set default `feeDelta` value for specified period and update node fee
    * @param _node Node address
    * @param _processedPeriod1 Processed period
    * @param _processedPeriod2 Processed period
    * @param _periodToSetDefault Period to set
    */
    function ping(
        address _node,
        uint16 _processedPeriod1,
        uint16 _processedPeriod2,
        uint16 _periodToSetDefault
    )
        external onlyEscrowContract
    {
        NodeInfo storage node = nodes[_node];
        // protection from calling not migrated node, see migrate()
        require(node.previousFeePeriod <= getCurrentPeriod());
        if (_processedPeriod1 != 0) {
            updateFee(node, _processedPeriod1);
        }
        if (_processedPeriod2 != 0) {
            updateFee(node, _processedPeriod2);
        }
        // This code increases gas cost for node in trade of decreasing cost for policy sponsor
        if (_periodToSetDefault != 0 && node.feeDelta[_periodToSetDefault] == 0) {
            node.feeDelta[_periodToSetDefault] = DEFAULT_FEE_DELTA;
        }
    }

    /**
    * @notice Update node fee
    * @param _info Node info structure
    * @param _period Processed period
    */
    function updateFee(NodeInfo storage _info, uint16 _period) internal {
        if (_info.previousFeePeriod == 0 || _period <= _info.previousFeePeriod) {
            return;
        }
        for (uint16 i = _info.previousFeePeriod + 1; i <= _period; i++) {
            int256 delta = _info.feeDelta[i];
            if (delta == DEFAULT_FEE_DELTA) {
                // gas refund
                _info.feeDelta[i] = 0;
                continue;
            }

            _info.feeRate = _info.feeRate.addSigned(delta);
            // gas refund
            _info.feeDelta[i] = 0;
        }
        _info.previousFeePeriod = _period;
        _info.fee += uint128(_info.feeRate);
    }

    /**
    * @notice Withdraw fee by node
    */
    function withdraw() external returns (uint256) {
        return withdraw(msg.sender);
    }

    /**
    * @notice Withdraw fee by node
    * @param _recipient Recipient of the fee
    */
    function withdraw(address payable _recipient) public returns (uint256) {
        NodeInfo storage node = nodes[msg.sender];
        uint256 fee = node.fee;
        require(fee != 0);
        node.fee = 0;
        _recipient.sendValue(fee);
        emit Withdrawn(msg.sender, _recipient, fee);
        return fee;
    }

    /**
    * @notice Calculate amount of refund
    * @param _policy Policy
    * @param _arrangement Arrangement
    */
    function calculateRefundValue(Policy storage _policy, ArrangementInfo storage _arrangement)
        internal view returns (uint256 refundValue, uint256 indexOfDowntimePeriods, uint16 lastRefundedPeriod)
    {
        uint16 policyStartPeriod = uint16(_policy.startTimestamp / secondsPerPeriod);
        uint16 maxPeriod = AdditionalMath.min16(getCurrentPeriod(), uint16(_policy.endTimestamp / secondsPerPeriod));
        uint16 minPeriod = AdditionalMath.max16(policyStartPeriod, _arrangement.lastRefundedPeriod);
        uint16 downtimePeriods = 0;
        uint256 length = escrow.getPastDowntimeLength(_arrangement.node);
        uint256 initialIndexOfDowntimePeriods;
        if (_arrangement.lastRefundedPeriod == 0) {
            initialIndexOfDowntimePeriods = escrow.findIndexOfPastDowntime(_arrangement.node, policyStartPeriod);
        } else {
            initialIndexOfDowntimePeriods = _arrangement.indexOfDowntimePeriods;
        }

        for (indexOfDowntimePeriods = initialIndexOfDowntimePeriods;
             indexOfDowntimePeriods < length;
             indexOfDowntimePeriods++)
        {
            (uint16 startPeriod, uint16 endPeriod) =
                escrow.getPastDowntime(_arrangement.node, indexOfDowntimePeriods);
            if (startPeriod > maxPeriod) {
                break;
            } else if (endPeriod < minPeriod) {
                continue;
            }
            downtimePeriods += AdditionalMath.min16(maxPeriod, endPeriod)
                .sub16(AdditionalMath.max16(minPeriod, startPeriod)) + 1;
            if (maxPeriod <= endPeriod) {
                break;
            }
        }

        uint16 lastCommittedPeriod = escrow.getLastCommittedPeriod(_arrangement.node);
        if (indexOfDowntimePeriods == length && lastCommittedPeriod < maxPeriod) {
            // Overflow protection removed:
            // lastCommittedPeriod < maxPeriod and minPeriod <= maxPeriod + 1
            downtimePeriods += maxPeriod - AdditionalMath.max16(minPeriod - 1, lastCommittedPeriod);
        }

        refundValue = _policy.feeRate * downtimePeriods;
        lastRefundedPeriod = maxPeriod + 1;
    }

    /**
    * @notice Revoke/refund arrangement/policy by the sponsor
    * @param _policyId Policy id
    * @param _node Node that will be excluded or RESERVED_NODE if full policy should be used
    ( @param _forceRevoke Force revoke arrangement/policy
    */
    function refundInternal(bytes16 _policyId, address _node, bool _forceRevoke)
        internal returns (uint256 refundValue)
    {
        refundValue = 0;
        Policy storage policy = policies[_policyId];
        require(!policy.disabled && policy.startTimestamp >= resetTimestamp);
        uint16 endPeriod = uint16(policy.endTimestamp / secondsPerPeriod) + 1;
        uint256 numberOfActive = policy.arrangements.length;
        uint256 i = 0;
        for (; i < policy.arrangements.length; i++) {
            ArrangementInfo storage arrangement = policy.arrangements[i];
            address node = arrangement.node;
            if (node == RESERVED_NODE || _node != RESERVED_NODE && _node != node) {
                numberOfActive--;
                continue;
            }
            uint256 nodeRefundValue;
            (nodeRefundValue, arrangement.indexOfDowntimePeriods, arrangement.lastRefundedPeriod) =
                calculateRefundValue(policy, arrangement);
            if (_forceRevoke) {
                NodeInfo storage nodeInfo = nodes[node];

                // Check default value for feeDelta
                uint16 lastRefundedPeriod = arrangement.lastRefundedPeriod;
                if (nodeInfo.feeDelta[lastRefundedPeriod] == DEFAULT_FEE_DELTA) {
                    nodeInfo.feeDelta[lastRefundedPeriod] = -int256(policy.feeRate);
                } else {
                    nodeInfo.feeDelta[lastRefundedPeriod] -= int256(policy.feeRate);
                }
                if (nodeInfo.feeDelta[endPeriod] == DEFAULT_FEE_DELTA) {
                    nodeInfo.feeDelta[endPeriod] = int256(policy.feeRate);
                } else {
                    nodeInfo.feeDelta[endPeriod] += int256(policy.feeRate);
                }

                // Reset to default value if needed
                if (nodeInfo.feeDelta[lastRefundedPeriod] == 0) {
                    nodeInfo.feeDelta[lastRefundedPeriod] = DEFAULT_FEE_DELTA;
                }
                if (nodeInfo.feeDelta[endPeriod] == 0) {
                    nodeInfo.feeDelta[endPeriod] = DEFAULT_FEE_DELTA;
                }
                nodeRefundValue += uint256(endPeriod - lastRefundedPeriod) * policy.feeRate;
            }
            if (_forceRevoke || arrangement.lastRefundedPeriod >= endPeriod) {
                arrangement.node = RESERVED_NODE;
                arrangement.indexOfDowntimePeriods = 0;
                arrangement.lastRefundedPeriod = 0;
                numberOfActive--;
                emit ArrangementRevoked(_policyId, msg.sender, node, nodeRefundValue);
            } else {
                emit RefundForArrangement(_policyId, msg.sender, node, nodeRefundValue);
            }

            refundValue += nodeRefundValue;
            if (_node != RESERVED_NODE) {
               break;
            }
        }
        address payable policySponsor = policy.sponsor;
        if (_node == RESERVED_NODE) {
            if (numberOfActive == 0) {
                policy.disabled = true;
                // gas refund
                policy.sponsor = address(0);
                policy.owner = address(0);
                policy.feeRate = 0;
                policy.startTimestamp = 0;
                policy.endTimestamp = 0;
                emit PolicyRevoked(_policyId, msg.sender, refundValue);
            } else {
                emit RefundForPolicy(_policyId, msg.sender, refundValue);
            }
        } else {
            // arrangement not found
            require(i < policy.arrangements.length);
        }
        if (refundValue > 0) {
            policySponsor.sendValue(refundValue);
        }
    }

    /**
    * @notice Calculate amount of refund
    * @param _policyId Policy id
    * @param _node Node or RESERVED_NODE if all nodes should be used
    */
    function calculateRefundValueInternal(bytes16 _policyId, address _node)
        internal view returns (uint256 refundValue)
    {
        refundValue = 0;
        Policy storage policy = policies[_policyId];
        require((policy.owner == msg.sender || policy.sponsor == msg.sender) && !policy.disabled);
        uint256 i = 0;
        for (; i < policy.arrangements.length; i++) {
            ArrangementInfo storage arrangement = policy.arrangements[i];
            if (arrangement.node == RESERVED_NODE || _node != RESERVED_NODE && _node != arrangement.node) {
                continue;
            }
            (uint256 nodeRefundValue,,) = calculateRefundValue(policy, arrangement);
            refundValue += nodeRefundValue;
            if (_node != RESERVED_NODE) {
               break;
            }
        }
        if (_node != RESERVED_NODE) {
            // arrangement not found
            require(i < policy.arrangements.length);
        }
    }

    /**
    * @notice Revoke policy by the sponsor
    * @param _policyId Policy id
    */
    function revokePolicy(bytes16 _policyId) external returns (uint256 refundValue) {
        require(getPolicyOwner(_policyId) == msg.sender);
        return refundInternal(_policyId, RESERVED_NODE, true);
    }

    /**
    * @notice Revoke arrangement by the sponsor
    * @param _policyId Policy id
    * @param _node Node that will be excluded
    */
    function revokeArrangement(bytes16 _policyId, address _node)
        external returns (uint256 refundValue)
    {
        require(_node != RESERVED_NODE);
        require(getPolicyOwner(_policyId) == msg.sender);
        return refundInternal(_policyId, _node, true);
    }

    /**
    * @notice Get unsigned hash for revocation
    * @param _policyId Policy id
    * @param _node Node that will be excluded
    * @return Revocation hash, EIP191 version 0x45 ('E')
    */
    function getRevocationHash(bytes16 _policyId, address _node) public view returns (bytes32) {
        return SignatureVerifier.hashEIP191(abi.encodePacked(_policyId, _node), byte(0x45));
    }

    /**
    * @notice Check correctness of signature
    * @param _policyId Policy id
    * @param _node Node that will be excluded, zero address if whole policy will be revoked
    * @param _signature Signature of owner
    */
    function checkOwnerSignature(bytes16 _policyId, address _node, bytes memory _signature) internal view {
        bytes32 hash = getRevocationHash(_policyId, _node);
        address recovered = SignatureVerifier.recover(hash, _signature);
        require(getPolicyOwner(_policyId) == recovered);
    }

    /**
    * @notice Revoke policy or arrangement using owner's signature
    * @param _policyId Policy id
    * @param _node Node that will be excluded, zero address if whole policy will be revoked
    * @param _signature Signature of owner, EIP191 version 0x45 ('E')
    */
    function revoke(bytes16 _policyId, address _node, bytes calldata _signature)
        external returns (uint256 refundValue)
    {
        checkOwnerSignature(_policyId, _node, _signature);
        return refundInternal(_policyId, _node, true);
    }

    /**
    * @notice Refund part of fee by the sponsor
    * @param _policyId Policy id
    */
    function refund(bytes16 _policyId) external {
        Policy storage policy = policies[_policyId];
        require(policy.owner == msg.sender || policy.sponsor == msg.sender);
        refundInternal(_policyId, RESERVED_NODE, false);
    }

    /**
    * @notice Refund part of one node's fee by the sponsor
    * @param _policyId Policy id
    * @param _node Node address
    */
    function refund(bytes16 _policyId, address _node)
        external returns (uint256 refundValue)
    {
        require(_node != RESERVED_NODE);
        Policy storage policy = policies[_policyId];
        require(policy.owner == msg.sender || policy.sponsor == msg.sender);
        return refundInternal(_policyId, _node, false);
    }

    /**
    * @notice Calculate amount of refund
    * @param _policyId Policy id
    */
    function calculateRefundValue(bytes16 _policyId)
        external view returns (uint256 refundValue)
    {
        return calculateRefundValueInternal(_policyId, RESERVED_NODE);
    }

    /**
    * @notice Calculate amount of refund
    * @param _policyId Policy id
    * @param _node Node
    */
    function calculateRefundValue(bytes16 _policyId, address _node)
        external view returns (uint256 refundValue)
    {
        require(_node != RESERVED_NODE);
        return calculateRefundValueInternal(_policyId, _node);
    }

    /**
    * @notice Get number of arrangements in the policy
    * @param _policyId Policy id
    */
    function getArrangementsLength(bytes16 _policyId) external view returns (uint256) {
        return policies[_policyId].arrangements.length;
    }

    /**
    * @notice Get information about staker's fee rate
    * @param _node Address of staker
    * @param _period Period to get fee delta
    */
    function getNodeFeeDelta(address _node, uint16 _period)
        // TODO "virtual" only for tests, probably will be removed after #1512
        public view virtual returns (int256)
    {
        // TODO remove after upgrade #2579
        if (_node == RESERVED_NODE && _period == 11) {
            return 55;
        }
        return nodes[_node].feeDelta[_period];
    }

    /**
    * @notice Return the information about arrangement
    */
    function getArrangementInfo(bytes16 _policyId, uint256 _index)
    // TODO change to structure when ABIEncoderV2 is released (#1501)
//        public view returns (ArrangementInfo)
        external view returns (address node, uint256 indexOfDowntimePeriods, uint16 lastRefundedPeriod)
    {
        ArrangementInfo storage info = policies[_policyId].arrangements[_index];
        node = info.node;
        indexOfDowntimePeriods = info.indexOfDowntimePeriods;
        lastRefundedPeriod = info.lastRefundedPeriod;
    }


    /**
    * @dev Get Policy structure by delegatecall
    */
    function delegateGetPolicy(address _target, bytes16 _policyId)
        internal returns (Policy memory result)
    {
        bytes32 memoryAddress = delegateGetData(_target, this.policies.selector, 1, bytes32(_policyId), 0);
        assembly {
            result := memoryAddress
        }
    }

    /**
    * @dev Get ArrangementInfo structure by delegatecall
    */
    function delegateGetArrangementInfo(address _target, bytes16 _policyId, uint256 _index)
        internal returns (ArrangementInfo memory result)
    {
        bytes32 memoryAddress = delegateGetData(
            _target, this.getArrangementInfo.selector, 2, bytes32(_policyId), bytes32(_index));
        assembly {
            result := memoryAddress
        }
    }

    /**
    * @dev Get NodeInfo structure by delegatecall
    */
    function delegateGetNodeInfo(address _target, address _node)
        internal returns (MemoryNodeInfo memory result)
    {
        bytes32 memoryAddress = delegateGetData(_target, this.nodes.selector, 1, bytes32(uint256(_node)), 0);
        assembly {
            result := memoryAddress
        }
    }

    /**
    * @dev Get feeRateRange structure by delegatecall
    */
    function delegateGetFeeRateRange(address _target) internal returns (Range memory result) {
        bytes32 memoryAddress = delegateGetData(_target, this.feeRateRange.selector, 0, 0, 0);
        assembly {
            result := memoryAddress
        }
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `verifyState`
    function verifyState(address _testTarget) public override virtual {
        super.verifyState(_testTarget);
        require(uint64(delegateGet(_testTarget, this.resetTimestamp.selector)) == resetTimestamp);

        Range memory rangeToCheck = delegateGetFeeRateRange(_testTarget);
        require(feeRateRange.min == rangeToCheck.min &&
            feeRateRange.defaultValue == rangeToCheck.defaultValue &&
            feeRateRange.max == rangeToCheck.max);

        Policy storage policy = policies[RESERVED_POLICY_ID];
        Policy memory policyToCheck = delegateGetPolicy(_testTarget, RESERVED_POLICY_ID);
        require(policyToCheck.sponsor == policy.sponsor &&
            policyToCheck.owner == policy.owner &&
            policyToCheck.feeRate == policy.feeRate &&
            policyToCheck.startTimestamp == policy.startTimestamp &&
            policyToCheck.endTimestamp == policy.endTimestamp &&
            policyToCheck.disabled == policy.disabled);

        require(delegateGet(_testTarget, this.getArrangementsLength.selector, RESERVED_POLICY_ID) ==
            policy.arrangements.length);
        if (policy.arrangements.length > 0) {
            ArrangementInfo storage arrangement = policy.arrangements[0];
            ArrangementInfo memory arrangementToCheck = delegateGetArrangementInfo(
                _testTarget, RESERVED_POLICY_ID, 0);
            require(arrangementToCheck.node == arrangement.node &&
                arrangementToCheck.indexOfDowntimePeriods == arrangement.indexOfDowntimePeriods &&
                arrangementToCheck.lastRefundedPeriod == arrangement.lastRefundedPeriod);
        }

        NodeInfo storage nodeInfo = nodes[RESERVED_NODE];
        MemoryNodeInfo memory nodeInfoToCheck = delegateGetNodeInfo(_testTarget, RESERVED_NODE);
        require(nodeInfoToCheck.fee == nodeInfo.fee &&
            nodeInfoToCheck.feeRate == nodeInfo.feeRate &&
            nodeInfoToCheck.previousFeePeriod == nodeInfo.previousFeePeriod &&
            nodeInfoToCheck.minFeeRate == nodeInfo.minFeeRate);

        require(int256(delegateGet(_testTarget, this.getNodeFeeDelta.selector,
            bytes32(bytes20(RESERVED_NODE)), bytes32(uint256(11)))) == getNodeFeeDelta(RESERVED_NODE, 11));
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `finishUpgrade`
    function finishUpgrade(address _target) public override virtual {
        super.finishUpgrade(_target);

        if (resetTimestamp == 0) {
            resetTimestamp = uint64(block.timestamp);
        }

        // Create fake Policy and NodeInfo to use them in verifyState(address)
        Policy storage policy = policies[RESERVED_POLICY_ID];
        policy.sponsor = msg.sender;
        policy.owner = address(this);
        policy.startTimestamp = 1;
        policy.endTimestamp = 2;
        policy.feeRate = 3;
        policy.disabled = true;
        policy.arrangements.push(ArrangementInfo(RESERVED_NODE, 11, 22));
        NodeInfo storage nodeInfo = nodes[RESERVED_NODE];
        nodeInfo.fee = 100;
        nodeInfo.feeRate = 33;
        nodeInfo.previousFeePeriod = 44;
        nodeInfo.feeDelta[11] = 55;
        nodeInfo.minFeeRate = 777;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "./Upgradeable.sol";
import "../../zeppelin/utils/Address.sol";


/**
* @notice ERC897 - ERC DelegateProxy
*/
interface ERCProxy {
    function proxyType() external pure returns (uint256);
    function implementation() external view returns (address);
}


/**
* @notice Proxying requests to other contracts.
* Client should use ABI of real contract and address of this contract
*/
contract Dispatcher is Upgradeable, ERCProxy {
    using Address for address;

    event Upgraded(address indexed from, address indexed to, address owner);
    event RolledBack(address indexed from, address indexed to, address owner);

    /**
    * @dev Set upgrading status before and after operations
    */
    modifier upgrading()
    {
        isUpgrade = UPGRADE_TRUE;
        _;
        isUpgrade = UPGRADE_FALSE;
    }

    /**
    * @param _target Target contract address
    */
    constructor(address _target) upgrading {
        require(_target.isContract());
        // Checks that target contract inherits Dispatcher state
        verifyState(_target);
        // `verifyState` must work with its contract
        verifyUpgradeableState(_target, _target);
        target = _target;
        finishUpgrade();
        emit Upgraded(address(0), _target, msg.sender);
    }

    //------------------------ERC897------------------------
    /**
     * @notice ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() external pure override returns (uint256) {
        return 2;
    }

    /**
     * @notice ERC897, gets the address of the implementation where every call will be delegated
     */
    function implementation() external view override returns (address) {
        return target;
    }
    //------------------------------------------------------------

    /**
    * @notice Verify new contract storage and upgrade target
    * @param _target New target contract address
    */
    function upgrade(address _target) public onlyOwner upgrading {
        require(_target.isContract());
        // Checks that target contract has "correct" (as much as possible) state layout
        verifyState(_target);
        //`verifyState` must work with its contract
        verifyUpgradeableState(_target, _target);
        if (target.isContract()) {
            verifyUpgradeableState(target, _target);
        }
        previousTarget = target;
        target = _target;
        finishUpgrade();
        emit Upgraded(previousTarget, _target, msg.sender);
    }

    /**
    * @notice Rollback to previous target
    * @dev Test storage carefully before upgrade again after rollback
    */
    function rollback() public onlyOwner upgrading {
        require(previousTarget.isContract());
        emit RolledBack(target, previousTarget, msg.sender);
        // should be always true because layout previousTarget -> target was already checked
        // but `verifyState` is not 100% accurate so check again
        verifyState(previousTarget);
        if (target.isContract()) {
            verifyUpgradeableState(previousTarget, target);
        }
        target = previousTarget;
        previousTarget = address(0);
        finishUpgrade();
    }

    /**
    * @dev Call verifyState method for Upgradeable contract
    */
    function verifyUpgradeableState(address _from, address _to) private {
        (bool callSuccess,) = _from.delegatecall(abi.encodeWithSelector(this.verifyState.selector, _to));
        require(callSuccess);
    }

    /**
    * @dev Call finishUpgrade method from the Upgradeable contract
    */
    function finishUpgrade() private {
        (bool callSuccess,) = target.delegatecall(abi.encodeWithSelector(this.finishUpgrade.selector, target));
        require(callSuccess);
    }

    function verifyState(address _testTarget) public override onlyWhileUpgrading {
        //checks equivalence accessing state through new contract and current storage
        require(address(uint160(delegateGet(_testTarget, this.owner.selector))) == owner());
        require(address(uint160(delegateGet(_testTarget, this.target.selector))) == target);
        require(address(uint160(delegateGet(_testTarget, this.previousTarget.selector))) == previousTarget);
        require(uint8(delegateGet(_testTarget, this.isUpgrade.selector)) == isUpgrade);
    }

    /**
    * @dev Override function using empty code because no reason to call this function in Dispatcher
    */
    function finishUpgrade(address) public override {}

    /**
    * @dev Receive function sends empty request to the target contract
    */
    receive() external payable {
        assert(target.isContract());
        // execute receive function from target contract using storage of the dispatcher
        (bool callSuccess,) = target.delegatecall("");
        if (!callSuccess) {
            revert();
        }
    }

    /**
    * @dev Fallback function sends all requests to the target contract
    */
    fallback() external payable {
        assert(target.isContract());
        // execute requested function from target contract using storage of the dispatcher
        (bool callSuccess,) = target.delegatecall(msg.data);
        if (callSuccess) {
            // copy result of the request to the return data
            // we can use the second return value from `delegatecall` (bytes memory)
            // but it will consume a little more gas
            assembly {
                returndatacopy(0x0, 0x0, returndatasize())
                return(0x0, returndatasize())
            }
        } else {
            revert();
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

import "../../zeppelin/ownership/Ownable.sol";
import "../../zeppelin/utils/Address.sol";
import "../../zeppelin/token/ERC20/SafeERC20.sol";
import "./StakingInterface.sol";
import "../../zeppelin/proxy/Initializable.sol";


/**
* @notice Router for accessing interface contract
*/
contract StakingInterfaceRouter is Ownable {
    BaseStakingInterface public target;

    /**
    * @param _target Address of the interface contract
    */
    constructor(BaseStakingInterface _target) {
        require(address(_target.token()) != address(0));
        target = _target;
    }

    /**
    * @notice Upgrade interface
    * @param _target New contract address
    */
    function upgrade(BaseStakingInterface _target) external onlyOwner {
        require(address(_target.token()) != address(0));
        target = _target;
    }

}


/**
* @notice Internal base class for AbstractStakingContract and InitializableStakingContract
*/
abstract contract RawStakingContract {
    using Address for address;

    /**
    * @dev Returns address of StakingInterfaceRouter
    */
    function router() public view virtual returns (StakingInterfaceRouter);

    /**
    * @dev Checks permission for calling fallback function
    */
    function isFallbackAllowed() public virtual returns (bool);

    /**
    * @dev Withdraw tokens from staking contract
    */
    function withdrawTokens(uint256 _value) public virtual;

    /**
    * @dev Withdraw ETH from staking contract
    */
    function withdrawETH() public virtual;

    receive() external payable {}

    /**
    * @dev Function sends all requests to the target contract
    */
    fallback() external payable {
        require(isFallbackAllowed());
        address target = address(router().target());
        require(target.isContract());
        // execute requested function from target contract
        (bool callSuccess, ) = target.delegatecall(msg.data);
        if (callSuccess) {
            // copy result of the request to the return data
            // we can use the second return value from `delegatecall` (bytes memory)
            // but it will consume a little more gas
            assembly {
                returndatacopy(0x0, 0x0, returndatasize())
                return(0x0, returndatasize())
            }
        } else {
            revert();
        }
    }
}


/**
* @notice Base class for any staking contract (not usable with openzeppelin proxy)
* @dev Implement `isFallbackAllowed()` or override fallback function
* Implement `withdrawTokens(uint256)` and `withdrawETH()` functions
*/
abstract contract AbstractStakingContract is RawStakingContract {

    StakingInterfaceRouter immutable router_;
    NuCypherToken public immutable token;

    /**
    * @param _router Interface router contract address
    */
    constructor(StakingInterfaceRouter _router) {
        router_ = _router;
        NuCypherToken localToken = _router.target().token();
        require(address(localToken) != address(0));
        token = localToken;
    }

    /**
    * @dev Returns address of StakingInterfaceRouter
    */
    function router() public view override returns (StakingInterfaceRouter) {
        return router_;
    }

}


/**
* @notice Base class for any staking contract usable with openzeppelin proxy
* @dev Implement `isFallbackAllowed()` or override fallback function
* Implement `withdrawTokens(uint256)` and `withdrawETH()` functions
*/
abstract contract InitializableStakingContract is Initializable, RawStakingContract {

    StakingInterfaceRouter router_;
    NuCypherToken public token;

    /**
    * @param _router Interface router contract address
    */
    function initialize(StakingInterfaceRouter _router) public initializer {
        router_ = _router;
        NuCypherToken localToken = _router.target().token();
        require(address(localToken) != address(0));
        token = localToken;
    }

    /**
    * @dev Returns address of StakingInterfaceRouter
    */
    function router() public view override returns (StakingInterfaceRouter) {
        return router_;
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "./AbstractStakingContract.sol";
import "../NuCypherToken.sol";
import "../StakingEscrow.sol";
import "../PolicyManager.sol";
import "../WorkLock.sol";


/**
* @notice Base StakingInterface
*/
contract BaseStakingInterface {

    address public immutable stakingInterfaceAddress;
    NuCypherToken public immutable token;
    StakingEscrow public immutable escrow;
    PolicyManager public immutable policyManager;
    WorkLock public immutable workLock;

    /**
    * @notice Constructor sets addresses of the contracts
    * @param _token Token contract
    * @param _escrow Escrow contract
    * @param _policyManager PolicyManager contract
    * @param _workLock WorkLock contract
    */
    constructor(
        NuCypherToken _token,
        StakingEscrow _escrow,
        PolicyManager _policyManager,
        WorkLock _workLock
    ) {
        require(_token.totalSupply() > 0 &&
            _escrow.secondsPerPeriod() > 0 &&
            _policyManager.secondsPerPeriod() > 0 &&
            // in case there is no worklock contract
            (address(_workLock) == address(0) || _workLock.boostingRefund() > 0));
        token = _token;
        escrow = _escrow;
        policyManager = _policyManager;
        workLock = _workLock;
        stakingInterfaceAddress = address(this);
    }

    /**
    * @dev Checks executing through delegate call
    */
    modifier onlyDelegateCall()
    {
        require(stakingInterfaceAddress != address(this));
        _;
    }

    /**
    * @dev Checks the existence of the worklock contract
    */
    modifier workLockSet()
    {
        require(address(workLock) != address(0));
        _;
    }

}


/**
* @notice Interface for accessing main contracts from a staking contract
* @dev All methods must be stateless because this code will be executed by delegatecall call, use immutable fields.
* @dev |v1.7.1|
*/
contract StakingInterface is BaseStakingInterface {

    event DepositedAsStaker(address indexed sender, uint256 value, uint16 periods);
    event WithdrawnAsStaker(address indexed sender, uint256 value);
    event DepositedAndIncreased(address indexed sender, uint256 index, uint256 value);
    event LockedAndCreated(address indexed sender, uint256 value, uint16 periods);
    event LockedAndIncreased(address indexed sender, uint256 index, uint256 value);
    event Divided(address indexed sender, uint256 index, uint256 newValue, uint16 periods);
    event Merged(address indexed sender, uint256 index1, uint256 index2);
    event Minted(address indexed sender);
    event PolicyFeeWithdrawn(address indexed sender, uint256 value);
    event MinFeeRateSet(address indexed sender, uint256 value);
    event ReStakeSet(address indexed sender, bool reStake);
    event WorkerBonded(address indexed sender, address worker);
    event Prolonged(address indexed sender, uint256 index, uint16 periods);
    event WindDownSet(address indexed sender, bool windDown);
    event SnapshotSet(address indexed sender, bool snapshotsEnabled);
    event Bid(address indexed sender, uint256 depositedETH);
    event Claimed(address indexed sender, uint256 claimedTokens);
    event Refund(address indexed sender, uint256 refundETH);
    event BidCanceled(address indexed sender);
    event CompensationWithdrawn(address indexed sender);

    /**
    * @notice Constructor sets addresses of the contracts
    * @param _token Token contract
    * @param _escrow Escrow contract
    * @param _policyManager PolicyManager contract
    * @param _workLock WorkLock contract
    */
    constructor(
        NuCypherToken _token,
        StakingEscrow _escrow,
        PolicyManager _policyManager,
        WorkLock _workLock
    )
        BaseStakingInterface(_token, _escrow, _policyManager, _workLock)
    {
    }

    /**
    * @notice Bond worker in the staking escrow
    * @param _worker Worker address
    */
    function bondWorker(address _worker) public onlyDelegateCall {
        escrow.bondWorker(_worker);
        emit WorkerBonded(msg.sender, _worker);
    }

    /**
    * @notice Set `reStake` parameter in the staking escrow
    * @param _reStake Value for parameter
    */
    function setReStake(bool _reStake) public onlyDelegateCall {
        escrow.setReStake(_reStake);
        emit ReStakeSet(msg.sender, _reStake);
    }

    /**
    * @notice Deposit tokens to the staking escrow
    * @param _value Amount of token to deposit
    * @param _periods Amount of periods during which tokens will be locked
    */
    function depositAsStaker(uint256 _value, uint16 _periods) public onlyDelegateCall {
        require(token.balanceOf(address(this)) >= _value);
        token.approve(address(escrow), _value);
        escrow.deposit(address(this), _value, _periods);
        emit DepositedAsStaker(msg.sender, _value, _periods);
    }

    /**
    * @notice Deposit tokens to the staking escrow
    * @param _index Index of the sub-stake
    * @param _value Amount of tokens which will be locked
    */
    function depositAndIncrease(uint256 _index, uint256 _value) public onlyDelegateCall {
        require(token.balanceOf(address(this)) >= _value);
        token.approve(address(escrow), _value);
        escrow.depositAndIncrease(_index, _value);
        emit DepositedAndIncreased(msg.sender, _index, _value);
    }

    /**
    * @notice Withdraw available amount of tokens from the staking escrow to the staking contract
    * @param _value Amount of token to withdraw
    */
    function withdrawAsStaker(uint256 _value) public onlyDelegateCall {
        escrow.withdraw(_value);
        emit WithdrawnAsStaker(msg.sender, _value);
    }

    /**
    * @notice Lock some tokens in the staking escrow
    * @param _value Amount of tokens which should lock
    * @param _periods Amount of periods during which tokens will be locked
    */
    function lockAndCreate(uint256 _value, uint16 _periods) public onlyDelegateCall {
        escrow.lockAndCreate(_value, _periods);
        emit LockedAndCreated(msg.sender, _value, _periods);
    }

    /**
    * @notice Lock some tokens in the staking escrow
    * @param _index Index of the sub-stake
    * @param _value Amount of tokens which will be locked
    */
    function lockAndIncrease(uint256 _index, uint256 _value) public onlyDelegateCall {
        escrow.lockAndIncrease(_index, _value);
        emit LockedAndIncreased(msg.sender, _index, _value);
    }

    /**
    * @notice Divide stake into two parts
    * @param _index Index of stake
    * @param _newValue New stake value
    * @param _periods Amount of periods for extending stake
    */
    function divideStake(uint256 _index, uint256 _newValue, uint16 _periods) public onlyDelegateCall {
        escrow.divideStake(_index, _newValue, _periods);
        emit Divided(msg.sender, _index, _newValue, _periods);
    }

    /**
    * @notice Merge two sub-stakes into one
    * @param _index1 Index of the first sub-stake
    * @param _index2 Index of the second sub-stake
    */
    function mergeStake(uint256 _index1, uint256 _index2) public onlyDelegateCall {
        escrow.mergeStake(_index1, _index2);
        emit Merged(msg.sender, _index1, _index2);
    }

    /**
    * @notice Mint tokens in the staking escrow
    */
    function mint() public onlyDelegateCall {
        escrow.mint();
        emit Minted(msg.sender);
    }

    /**
    * @notice Withdraw available policy fees from the policy manager to the staking contract
    */
    function withdrawPolicyFee() public onlyDelegateCall {
        uint256 value = policyManager.withdraw();
        emit PolicyFeeWithdrawn(msg.sender, value);
    }

    /**
    * @notice Set the minimum fee that the staker will accept in the policy manager contract
    */
    function setMinFeeRate(uint256 _minFeeRate) public onlyDelegateCall {
        policyManager.setMinFeeRate(_minFeeRate);
        emit MinFeeRateSet(msg.sender, _minFeeRate);
    }


    /**
    * @notice Prolong active sub stake
    * @param _index Index of the sub stake
    * @param _periods Amount of periods for extending sub stake
    */
    function prolongStake(uint256 _index, uint16 _periods) public onlyDelegateCall {
        escrow.prolongStake(_index, _periods);
        emit Prolonged(msg.sender, _index, _periods);
    }

    /**
    * @notice Set `windDown` parameter in the staking escrow
    * @param _windDown Value for parameter
    */
    function setWindDown(bool _windDown) public onlyDelegateCall {
        escrow.setWindDown(_windDown);
        emit WindDownSet(msg.sender, _windDown);
    }

    /**
    * @notice Set `snapshots` parameter in the staking escrow
    * @param _enableSnapshots Value for parameter
    */
    function setSnapshots(bool _enableSnapshots) public onlyDelegateCall {
        escrow.setSnapshots(_enableSnapshots);
        emit SnapshotSet(msg.sender, _enableSnapshots);
    }

    /**
    * @notice Bid for tokens by transferring ETH
    */
    function bid(uint256 _value) public payable onlyDelegateCall workLockSet {
        workLock.bid{value: _value}();
        emit Bid(msg.sender, _value);
    }

    /**
    * @notice Cancel bid and refund deposited ETH
    */
    function cancelBid() public onlyDelegateCall workLockSet {
        workLock.cancelBid();
        emit BidCanceled(msg.sender);
    }

    /**
    * @notice Withdraw compensation after force refund
    */
    function withdrawCompensation() public onlyDelegateCall workLockSet {
        workLock.withdrawCompensation();
        emit CompensationWithdrawn(msg.sender);
    }

    /**
    * @notice Claimed tokens will be deposited and locked as stake in the StakingEscrow contract
    */
    function claim() public onlyDelegateCall workLockSet {
        uint256 claimedTokens = workLock.claim();
        emit Claimed(msg.sender, claimedTokens);
    }

    /**
    * @notice Refund ETH for the completed work
    */
    function refund() public onlyDelegateCall workLockSet {
        uint256 refundETH = workLock.refund();
        emit Refund(msg.sender, refundETH);
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "../zeppelin/math/SafeMath.sol";
import "../zeppelin/token/ERC20/SafeERC20.sol";
import "../zeppelin/utils/Address.sol";
import "../zeppelin/ownership/Ownable.sol";
import "./NuCypherToken.sol";
import "./StakingEscrow.sol";
import "./lib/AdditionalMath.sol";


/**
* @notice The WorkLock distribution contract
*/
contract WorkLock is Ownable {
    using SafeERC20 for NuCypherToken;
    using SafeMath for uint256;
    using AdditionalMath for uint256;
    using Address for address payable;
    using Address for address;

    event Deposited(address indexed sender, uint256 value);
    event Bid(address indexed sender, uint256 depositedETH);
    event Claimed(address indexed sender, uint256 claimedTokens);
    event Refund(address indexed sender, uint256 refundETH, uint256 completedWork);
    event Canceled(address indexed sender, uint256 value);
    event BiddersChecked(address indexed sender, uint256 startIndex, uint256 endIndex);
    event ForceRefund(address indexed sender, address indexed bidder, uint256 refundETH);
    event CompensationWithdrawn(address indexed sender, uint256 value);
    event Shutdown(address indexed sender);

    struct WorkInfo {
        uint256 depositedETH;
        uint256 completedWork;
        bool claimed;
        uint128 index;
    }

    uint16 public constant SLOWING_REFUND = 100;
    uint256 private constant MAX_ETH_SUPPLY = 2e10 ether;

    NuCypherToken public immutable token;
    StakingEscrow public immutable escrow;

    /*
    * @dev WorkLock calculations:
    * bid = minBid + bonusETHPart
    * bonusTokenSupply = tokenSupply - bidders.length * minAllowableLockedTokens
    * bonusDepositRate = bonusTokenSupply / bonusETHSupply
    * claimedTokens = minAllowableLockedTokens + bonusETHPart * bonusDepositRate
    * bonusRefundRate = bonusDepositRate * SLOWING_REFUND / boostingRefund
    * refundETH = completedWork / refundRate
    */
    uint256 public immutable boostingRefund;
    uint256 public immutable minAllowedBid;
    uint16 public immutable stakingPeriods;
    // copy from the escrow contract
    uint256 public immutable maxAllowableLockedTokens;
    uint256 public immutable minAllowableLockedTokens;

    uint256 public tokenSupply;
    uint256 public startBidDate;
    uint256 public endBidDate;
    uint256 public endCancellationDate;

    uint256 public bonusETHSupply;
    mapping(address => WorkInfo) public workInfo;
    mapping(address => uint256) public compensation;

    address[] public bidders;
    // if value == bidders.length then WorkLock is fully checked
    uint256 public nextBidderToCheck;

    /**
    * @dev Checks timestamp regarding cancellation window
    */
    modifier afterCancellationWindow()
    {
        require(block.timestamp >= endCancellationDate,
            "Operation is allowed when cancellation phase is over");
        _;
    }

    /**
    * @param _token Token contract
    * @param _escrow Escrow contract
    * @param _startBidDate Timestamp when bidding starts
    * @param _endBidDate Timestamp when bidding will end
    * @param _endCancellationDate Timestamp when cancellation will ends
    * @param _boostingRefund Coefficient to boost refund ETH
    * @param _stakingPeriods Amount of periods during which tokens will be locked after claiming
    * @param _minAllowedBid Minimum allowed ETH amount for bidding
    */
    constructor(
        NuCypherToken _token,
        StakingEscrow _escrow,
        uint256 _startBidDate,
        uint256 _endBidDate,
        uint256 _endCancellationDate,
        uint256 _boostingRefund,
        uint16 _stakingPeriods,
        uint256 _minAllowedBid
    ) {
        uint256 totalSupply = _token.totalSupply();
        require(totalSupply > 0 &&                              // token contract is deployed and accessible
            _escrow.secondsPerPeriod() > 0 &&                   // escrow contract is deployed and accessible
            _escrow.token() == _token &&                        // same token address for worklock and escrow
            _endBidDate > _startBidDate &&                      // bidding period lasts some time
            _endBidDate > block.timestamp &&                    // there is time to make a bid
            _endCancellationDate >= _endBidDate &&              // cancellation window includes bidding
            _minAllowedBid > 0 &&                               // min allowed bid was set
            _boostingRefund > 0 &&                              // boosting coefficient was set
            _stakingPeriods >= _escrow.minLockedPeriods());     // staking duration is consistent with escrow contract
        // worst case for `ethToWork()` and `workToETH()`,
        // when ethSupply == MAX_ETH_SUPPLY and tokenSupply == totalSupply
        require(MAX_ETH_SUPPLY * totalSupply * SLOWING_REFUND / MAX_ETH_SUPPLY / totalSupply == SLOWING_REFUND &&
            MAX_ETH_SUPPLY * totalSupply * _boostingRefund / MAX_ETH_SUPPLY / totalSupply == _boostingRefund);

        token = _token;
        escrow = _escrow;
        startBidDate = _startBidDate;
        endBidDate = _endBidDate;
        endCancellationDate = _endCancellationDate;
        boostingRefund = _boostingRefund;
        stakingPeriods = _stakingPeriods;
        minAllowedBid = _minAllowedBid;
        maxAllowableLockedTokens = _escrow.maxAllowableLockedTokens();
        minAllowableLockedTokens = _escrow.minAllowableLockedTokens();
    }

    /**
    * @notice Deposit tokens to contract
    * @param _value Amount of tokens to transfer
    */
    function tokenDeposit(uint256 _value) external {
        require(block.timestamp < endBidDate, "Can't deposit more tokens after end of bidding");
        token.safeTransferFrom(msg.sender, address(this), _value);
        tokenSupply += _value;
        emit Deposited(msg.sender, _value);
    }

    /**
    * @notice Calculate amount of tokens that will be get for specified amount of ETH
    * @dev This value will be fixed only after end of bidding
    */
    function ethToTokens(uint256 _ethAmount) public view returns (uint256) {
        if (_ethAmount < minAllowedBid) {
            return 0;
        }

        // when all participants bid with the same minimum amount of eth
        if (bonusETHSupply == 0) {
            return tokenSupply / bidders.length;
        }

        uint256 bonusETH = _ethAmount - minAllowedBid;
        uint256 bonusTokenSupply = tokenSupply - bidders.length * minAllowableLockedTokens;
        return minAllowableLockedTokens + bonusETH.mul(bonusTokenSupply).div(bonusETHSupply);
    }

    /**
    * @notice Calculate amount of work that need to be done to refund specified amount of ETH
    */
    function ethToWork(uint256 _ethAmount, uint256 _tokenSupply, uint256 _ethSupply)
        internal view returns (uint256)
    {
        return _ethAmount.mul(_tokenSupply).mul(SLOWING_REFUND).divCeil(_ethSupply.mul(boostingRefund));
    }

    /**
    * @notice Calculate amount of work that need to be done to refund specified amount of ETH
    * @dev This value will be fixed only after end of bidding
    * @param _ethToReclaim Specified sum of ETH staker wishes to reclaim following completion of work
    * @param _restOfDepositedETH Remaining ETH in staker's deposit once ethToReclaim sum has been subtracted
    * @dev _ethToReclaim + _restOfDepositedETH = depositedETH
    */
    function ethToWork(uint256 _ethToReclaim, uint256 _restOfDepositedETH) internal view returns (uint256) {

        uint256 baseETHSupply = bidders.length * minAllowedBid;
        // when all participants bid with the same minimum amount of eth
        if (bonusETHSupply == 0) {
            return ethToWork(_ethToReclaim, tokenSupply, baseETHSupply);
        }

        uint256 baseETH = 0;
        uint256 bonusETH = 0;

        // If the staker's total remaining deposit (including the specified sum of ETH to reclaim)
        // is lower than the minimum bid size,
        // then only the base part is used to calculate the work required to reclaim ETH
        if (_ethToReclaim + _restOfDepositedETH <= minAllowedBid) {
            baseETH = _ethToReclaim;

        // If the staker's remaining deposit (not including the specified sum of ETH to reclaim)
        // is still greater than the minimum bid size,
        // then only the bonus part is used to calculate the work required to reclaim ETH
        } else if (_restOfDepositedETH >= minAllowedBid) {
            bonusETH = _ethToReclaim;

        // If the staker's remaining deposit (not including the specified sum of ETH to reclaim)
        // is lower than the minimum bid size,
        // then both the base and bonus parts must be used to calculate the work required to reclaim ETH
        } else {
            bonusETH = _ethToReclaim + _restOfDepositedETH - minAllowedBid;
            baseETH = _ethToReclaim - bonusETH;
        }

        uint256 baseTokenSupply = bidders.length * minAllowableLockedTokens;
        uint256 work = 0;
        if (baseETH > 0) {
            work = ethToWork(baseETH, baseTokenSupply, baseETHSupply);
        }

        if (bonusETH > 0) {
            uint256 bonusTokenSupply = tokenSupply - baseTokenSupply;
            work += ethToWork(bonusETH, bonusTokenSupply, bonusETHSupply);
        }

        return work;
    }

    /**
    * @notice Calculate amount of work that need to be done to refund specified amount of ETH
    * @dev This value will be fixed only after end of bidding
    */
    function ethToWork(uint256 _ethAmount) public view returns (uint256) {
        return ethToWork(_ethAmount, 0);
    }

    /**
    * @notice Calculate amount of ETH that will be refund for completing specified amount of work
    */
    function workToETH(uint256 _completedWork, uint256 _ethSupply, uint256 _tokenSupply)
        internal view returns (uint256)
    {
        return _completedWork.mul(_ethSupply).mul(boostingRefund).div(_tokenSupply.mul(SLOWING_REFUND));
    }

    /**
    * @notice Calculate amount of ETH that will be refund for completing specified amount of work
    * @dev This value will be fixed only after end of bidding
    */
    function workToETH(uint256 _completedWork, uint256 _depositedETH) public view returns (uint256) {
        uint256 baseETHSupply = bidders.length * minAllowedBid;
        // when all participants bid with the same minimum amount of eth
        if (bonusETHSupply == 0) {
            return workToETH(_completedWork, baseETHSupply, tokenSupply);
        }

        uint256 bonusWork = 0;
        uint256 bonusETH = 0;
        uint256 baseTokenSupply = bidders.length * minAllowableLockedTokens;

        if (_depositedETH > minAllowedBid) {
            bonusETH = _depositedETH - minAllowedBid;
            uint256 bonusTokenSupply = tokenSupply - baseTokenSupply;
            bonusWork = ethToWork(bonusETH, bonusTokenSupply, bonusETHSupply);

            if (_completedWork <= bonusWork) {
                return workToETH(_completedWork, bonusETHSupply, bonusTokenSupply);
            }
        }

        _completedWork -= bonusWork;
        return bonusETH + workToETH(_completedWork, baseETHSupply, baseTokenSupply);
    }

    /**
    * @notice Get remaining work to full refund
    */
    function getRemainingWork(address _bidder) external view returns (uint256) {
        WorkInfo storage info = workInfo[_bidder];
        uint256 completedWork = escrow.getCompletedWork(_bidder).sub(info.completedWork);
        uint256 remainingWork = ethToWork(info.depositedETH);
        if (remainingWork <= completedWork) {
            return 0;
        }
        return remainingWork - completedWork;
    }

    /**
    * @notice Get length of bidders array
    */
    function getBiddersLength() external view returns (uint256) {
        return bidders.length;
    }

    /**
    * @notice Bid for tokens by transferring ETH
    */
    function bid() external payable {
        require(block.timestamp >= startBidDate, "Bidding is not open yet");
        require(block.timestamp < endBidDate, "Bidding is already finished");
        WorkInfo storage info = workInfo[msg.sender];

        // first bid
        if (info.depositedETH == 0) {
            require(msg.value >= minAllowedBid, "Bid must be at least minimum");
            require(bidders.length < tokenSupply / minAllowableLockedTokens, "Not enough tokens for more bidders");
            info.index = uint128(bidders.length);
            bidders.push(msg.sender);
            bonusETHSupply = bonusETHSupply.add(msg.value - minAllowedBid);
        } else {
            bonusETHSupply = bonusETHSupply.add(msg.value);
        }

        info.depositedETH = info.depositedETH.add(msg.value);
        emit Bid(msg.sender, msg.value);
    }

    /**
    * @notice Cancel bid and refund deposited ETH
    */
    function cancelBid() external {
        require(block.timestamp < endCancellationDate,
            "Cancellation allowed only during cancellation window");
        WorkInfo storage info = workInfo[msg.sender];
        require(info.depositedETH > 0, "No bid to cancel");
        require(!info.claimed, "Tokens are already claimed");
        uint256 refundETH = info.depositedETH;
        info.depositedETH = 0;

        // remove from bidders array, move last bidder to the empty place
        uint256 lastIndex = bidders.length - 1;
        if (info.index != lastIndex) {
            address lastBidder = bidders[lastIndex];
            bidders[info.index] = lastBidder;
            workInfo[lastBidder].index = info.index;
        }
        bidders.pop();

        if (refundETH > minAllowedBid) {
            bonusETHSupply = bonusETHSupply.sub(refundETH - minAllowedBid);
        }
        msg.sender.sendValue(refundETH);
        emit Canceled(msg.sender, refundETH);
    }

    /**
    * @notice Cancels distribution, makes possible to retrieve all bids and owner gets all tokens
    */
    function shutdown() external onlyOwner {
        require(!isClaimingAvailable(), "Claiming has already been enabled");
        internalShutdown();
    }

    /**
    * @notice Cancels distribution, makes possible to retrieve all bids and owner gets all tokens
    */
    function internalShutdown() internal {
        startBidDate = 0;
        endBidDate = 0;
        endCancellationDate = uint256(0) - 1; // "infinite" cancellation window
        token.safeTransfer(owner(), tokenSupply);
        emit Shutdown(msg.sender);
    }

    /**
    * @notice Make force refund to bidders who can get tokens more than maximum allowed
    * @param _biddersForRefund Sorted list of unique bidders. Only bidders who must receive a refund
    */
    function forceRefund(address payable[] calldata _biddersForRefund) external afterCancellationWindow {
        require(nextBidderToCheck != bidders.length, "Bidders have already been checked");

        uint256 length = _biddersForRefund.length;
        require(length > 0, "Must be at least one bidder for a refund");

        uint256 minNumberOfBidders = tokenSupply.divCeil(maxAllowableLockedTokens);
        if (bidders.length < minNumberOfBidders) {
            internalShutdown();
            return;
        }

        address previousBidder = _biddersForRefund[0];
        uint256 minBid = workInfo[previousBidder].depositedETH;
        uint256 maxBid = minBid;

        // get minimum and maximum bids
        for (uint256 i = 1; i < length; i++) {
            address bidder = _biddersForRefund[i];
            uint256 depositedETH = workInfo[bidder].depositedETH;
            require(bidder > previousBidder && depositedETH > 0, "Addresses must be an array of unique bidders");
            if (minBid > depositedETH) {
                minBid = depositedETH;
            } else if (maxBid < depositedETH) {
                maxBid = depositedETH;
            }
            previousBidder = bidder;
        }

        uint256[] memory refunds = new uint256[](length);
        // first step - align at a minimum bid
        if (minBid != maxBid) {
            for (uint256 i = 0; i < length; i++) {
                address bidder = _biddersForRefund[i];
                WorkInfo storage info = workInfo[bidder];
                if (info.depositedETH > minBid) {
                    refunds[i] = info.depositedETH - minBid;
                    info.depositedETH = minBid;
                    bonusETHSupply -= refunds[i];
                }
            }
        }

        require(ethToTokens(minBid) > maxAllowableLockedTokens,
            "At least one of bidders has allowable bid");

        // final bids adjustment (only for bonus part)
        // (min_whale_bid * token_supply - max_stake * eth_supply) / (token_supply - max_stake * n_whales)
        uint256 maxBonusTokens = maxAllowableLockedTokens - minAllowableLockedTokens;
        uint256 minBonusETH = minBid - minAllowedBid;
        uint256 bonusTokenSupply = tokenSupply - bidders.length * minAllowableLockedTokens;
        uint256 refundETH = minBonusETH.mul(bonusTokenSupply)
                                .sub(maxBonusTokens.mul(bonusETHSupply))
                                .divCeil(bonusTokenSupply - maxBonusTokens.mul(length));
        uint256 resultBid = minBid.sub(refundETH);
        bonusETHSupply -= length * refundETH;
        for (uint256 i = 0; i < length; i++) {
            address bidder = _biddersForRefund[i];
            WorkInfo storage info = workInfo[bidder];
            refunds[i] += refundETH;
            info.depositedETH = resultBid;
        }

        // reset verification
        nextBidderToCheck = 0;

        // save a refund
        for (uint256 i = 0; i < length; i++) {
            address bidder = _biddersForRefund[i];
            compensation[bidder] += refunds[i];
            emit ForceRefund(msg.sender, bidder, refunds[i]);
        }

    }

    /**
    * @notice Withdraw compensation after force refund
    */
    function withdrawCompensation() external {
        uint256 refund = compensation[msg.sender];
        require(refund > 0, "There is no compensation");
        compensation[msg.sender] = 0;
        msg.sender.sendValue(refund);
        emit CompensationWithdrawn(msg.sender, refund);
    }

    /**
    * @notice Check that the claimed tokens are within `maxAllowableLockedTokens` for all participants,
    * starting from the last point `nextBidderToCheck`
    * @dev Method stops working when the remaining gas is less than `_gasToSaveState`
    * and saves the state in `nextBidderToCheck`.
    * If all bidders have been checked then `nextBidderToCheck` will be equal to the length of the bidders array
    */
    function verifyBiddingCorrectness(uint256 _gasToSaveState) external afterCancellationWindow returns (uint256) {
        require(nextBidderToCheck != bidders.length, "Bidders have already been checked");

        // all participants bid with the same minimum amount of eth
        uint256 index = nextBidderToCheck;
        if (bonusETHSupply == 0) {
            require(tokenSupply / bidders.length <= maxAllowableLockedTokens, "Not enough bidders");
            index = bidders.length;
        }

        uint256 maxBonusTokens = maxAllowableLockedTokens - minAllowableLockedTokens;
        uint256 bonusTokenSupply = tokenSupply - bidders.length * minAllowableLockedTokens;
        uint256 maxBidFromMaxStake = minAllowedBid + maxBonusTokens.mul(bonusETHSupply).div(bonusTokenSupply);


        while (index < bidders.length && gasleft() > _gasToSaveState) {
            address bidder = bidders[index];
            require(workInfo[bidder].depositedETH <= maxBidFromMaxStake, "Bid is greater than max allowable bid");
            index++;
        }

        if (index != nextBidderToCheck) {
            emit BiddersChecked(msg.sender, nextBidderToCheck, index);
            nextBidderToCheck = index;
        }
        return nextBidderToCheck;
    }

    /**
    * @notice Checks if claiming available
    */
    function isClaimingAvailable() public view returns (bool) {
        return block.timestamp >= endCancellationDate &&
            nextBidderToCheck == bidders.length;
    }

    /**
    * @notice Claimed tokens will be deposited and locked as stake in the StakingEscrow contract.
    */
    function claim() external returns (uint256 claimedTokens) {
        require(isClaimingAvailable(), "Claiming has not been enabled yet");
        WorkInfo storage info = workInfo[msg.sender];
        require(!info.claimed, "Tokens are already claimed");
        claimedTokens = ethToTokens(info.depositedETH);
        require(claimedTokens > 0, "Nothing to claim");

        info.claimed = true;
        token.approve(address(escrow), claimedTokens);
        escrow.depositFromWorkLock(msg.sender, claimedTokens, stakingPeriods);
        info.completedWork = escrow.setWorkMeasurement(msg.sender, true);
        emit Claimed(msg.sender, claimedTokens);
    }

    /**
    * @notice Get available refund for bidder
    */
    function getAvailableRefund(address _bidder) public view returns (uint256) {
        WorkInfo storage info = workInfo[_bidder];
        // nothing to refund
        if (info.depositedETH == 0) {
            return 0;
        }

        uint256 currentWork = escrow.getCompletedWork(_bidder);
        uint256 completedWork = currentWork.sub(info.completedWork);
        // no work that has been completed since last refund
        if (completedWork == 0) {
            return 0;
        }

        uint256 refundETH = workToETH(completedWork, info.depositedETH);
        if (refundETH > info.depositedETH) {
            refundETH = info.depositedETH;
        }
        return refundETH;
    }

    /**
    * @notice Refund ETH for the completed work
    */
    function refund() external returns (uint256 refundETH) {
        WorkInfo storage info = workInfo[msg.sender];
        require(info.claimed, "Tokens must be claimed before refund");
        refundETH = getAvailableRefund(msg.sender);
        require(refundETH > 0, "Nothing to refund: there is no ETH to refund or no completed work");

        if (refundETH == info.depositedETH) {
            escrow.setWorkMeasurement(msg.sender, false);
        }
        info.depositedETH = info.depositedETH.sub(refundETH);
        // convert refund back to work to eliminate potential rounding errors
        uint256 completedWork = ethToWork(refundETH, info.depositedETH);

        info.completedWork = info.completedWork.add(completedWork);
        emit Refund(msg.sender, refundETH, completedWork);
        msg.sender.sendValue(refundETH);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "../../zeppelin/ownership/Ownable.sol";
import "../../zeppelin/math/SafeMath.sol";
import "./AbstractStakingContract.sol";


/**
* @notice Contract acts as delegate for sub-stakers and owner
**/
contract PoolingStakingContract is AbstractStakingContract, Ownable {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for NuCypherToken;

    event TokensDeposited(address indexed sender, uint256 value, uint256 depositedTokens);
    event TokensWithdrawn(address indexed sender, uint256 value, uint256 depositedTokens);
    event ETHWithdrawn(address indexed sender, uint256 value);
    event DepositSet(address indexed sender, bool value);

    struct Delegator {
        uint256 depositedTokens;
        uint256 withdrawnReward;
        uint256 withdrawnETH;
    }

    StakingEscrow public immutable escrow;

    uint256 public totalDepositedTokens;
    uint256 public totalWithdrawnReward;
    uint256 public totalWithdrawnETH;

    uint256 public ownerFraction;
    uint256 public ownerWithdrawnReward;
    uint256 public ownerWithdrawnETH;

    mapping (address => Delegator) public delegators;
    bool depositIsEnabled = true;

    /**
    * @param _router Address of the StakingInterfaceRouter contract
    * @param _ownerFraction Base owner's portion of reward
    */
    constructor(
        StakingInterfaceRouter _router,
        uint256 _ownerFraction
    )
        AbstractStakingContract(_router)
    {
        escrow = _router.target().escrow();
        ownerFraction = _ownerFraction;
    }

    /**
    * @notice Enabled deposit
    */
    function enableDeposit() external onlyOwner {
        depositIsEnabled = true;
        emit DepositSet(msg.sender, depositIsEnabled);
    }

    /**
    * @notice Disable deposit
    */
    function disableDeposit() external onlyOwner {
        depositIsEnabled = false;
        emit DepositSet(msg.sender, depositIsEnabled);
    }

    /**
    * @notice Transfer tokens as delegator
    * @param _value Amount of tokens to transfer
    */
    function depositTokens(uint256 _value) external {
        require(depositIsEnabled, "Deposit must be enabled");
        require(_value > 0, "Value must be not empty");
        totalDepositedTokens = totalDepositedTokens.add(_value);
        Delegator storage delegator = delegators[msg.sender];
        delegator.depositedTokens += _value;
        token.safeTransferFrom(msg.sender, address(this), _value);
        emit TokensDeposited(msg.sender, _value, delegator.depositedTokens);
    }

    /**
    * @notice Get available reward for all delegators and owner
    */
    function getAvailableReward() public view returns (uint256) {
        uint256 stakedTokens = escrow.getAllTokens(address(this));
        uint256 freeTokens = token.balanceOf(address(this));
        uint256 reward = stakedTokens + freeTokens - totalDepositedTokens;
        if (reward > freeTokens) {
            return freeTokens;
        }
        return reward;
    }

    /**
    * @notice Get cumulative reward
    */
    function getCumulativeReward() public view returns (uint256) {
        return getAvailableReward().add(totalWithdrawnReward);
    }

    /**
    * @notice Get available reward in tokens for pool owner
    */
    function getAvailableOwnerReward() public view returns (uint256) {
        uint256 reward = getCumulativeReward();

        uint256 maxAllowableReward;
        if (totalDepositedTokens != 0) {
            maxAllowableReward = reward.mul(ownerFraction).div(totalDepositedTokens.add(ownerFraction));
        } else {
            maxAllowableReward = reward;
        }

        return maxAllowableReward.sub(ownerWithdrawnReward);
    }

    /**
    * @notice Get available reward in tokens for delegator
    */
    function getAvailableReward(address _delegator) public view returns (uint256) {
        if (totalDepositedTokens == 0) {
            return 0;
        }

        uint256 reward = getCumulativeReward();
        Delegator storage delegator = delegators[_delegator];
        uint256 maxAllowableReward = reward.mul(delegator.depositedTokens)
            .div(totalDepositedTokens.add(ownerFraction));

        return maxAllowableReward > delegator.withdrawnReward ? maxAllowableReward - delegator.withdrawnReward : 0;
    }

    /**
    * @notice Withdraw reward in tokens to owner
    */
    function withdrawOwnerReward() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        uint256 availableReward = getAvailableOwnerReward();

        if (availableReward > balance) {
            availableReward = balance;
        }
        require(availableReward > 0, "There is no available reward to withdraw");
        ownerWithdrawnReward  = ownerWithdrawnReward.add(availableReward);
        totalWithdrawnReward = totalWithdrawnReward.add(availableReward);

        token.safeTransfer(msg.sender, availableReward);
        emit TokensWithdrawn(msg.sender, availableReward, 0);
    }

    /**
    * @notice Withdraw amount of tokens to delegator
    * @param _value Amount of tokens to withdraw
    */
    function withdrawTokens(uint256 _value) public override {
        uint256 balance = token.balanceOf(address(this));
        require(_value <= balance, "Not enough tokens in the contract");

        uint256 availableReward = getAvailableReward(msg.sender);

        Delegator storage delegator = delegators[msg.sender];
        require(_value <= availableReward + delegator.depositedTokens,
            "Requested amount of tokens exceeded allowed portion");

        if (_value <= availableReward) {
            delegator.withdrawnReward += _value;
            totalWithdrawnReward += _value;
        } else {
            delegator.withdrawnReward = delegator.withdrawnReward.add(availableReward);
            totalWithdrawnReward = totalWithdrawnReward.add(availableReward);

            uint256 depositToWithdraw = _value - availableReward;
            uint256 newDepositedTokens = delegator.depositedTokens - depositToWithdraw;
            uint256 newWithdrawnReward = delegator.withdrawnReward.mul(newDepositedTokens).div(delegator.depositedTokens);
            uint256 newWithdrawnETH = delegator.withdrawnETH.mul(newDepositedTokens).div(delegator.depositedTokens);
            totalDepositedTokens -= depositToWithdraw;
            totalWithdrawnReward -= (delegator.withdrawnReward - newWithdrawnReward);
            totalWithdrawnETH -= (delegator.withdrawnETH - newWithdrawnETH);
            delegator.depositedTokens = newDepositedTokens;
            delegator.withdrawnReward = newWithdrawnReward;
            delegator.withdrawnETH = newWithdrawnETH;
        }

        token.safeTransfer(msg.sender, _value);
        emit TokensWithdrawn(msg.sender, _value, delegator.depositedTokens);
    }

    /**
    * @notice Get available ether for owner
    */
    function getAvailableOwnerETH() public view returns (uint256) {
        // TODO boilerplate code
        uint256 balance = address(this).balance;
        balance = balance.add(totalWithdrawnETH);
        uint256 maxAllowableETH = balance.mul(ownerFraction).div(totalDepositedTokens.add(ownerFraction));

        uint256 availableETH = maxAllowableETH.sub(ownerWithdrawnETH);
        if (availableETH > balance) {
            availableETH = balance;
        }
        return availableETH;
    }

    /**
    * @notice Get available ether for delegator
    */
    function getAvailableETH(address _delegator) public view returns (uint256) {
        Delegator storage delegator = delegators[_delegator];
        // TODO boilerplate code
        uint256 balance = address(this).balance;
        balance = balance.add(totalWithdrawnETH);
        uint256 maxAllowableETH = balance.mul(delegator.depositedTokens)
            .div(totalDepositedTokens.add(ownerFraction));

        uint256 availableETH = maxAllowableETH.sub(delegator.withdrawnETH);
        if (availableETH > balance) {
            availableETH = balance;
        }
        return availableETH;
    }

    /**
    * @notice Withdraw available amount of ETH to pool owner
    */
    function withdrawOwnerETH() public onlyOwner {
        uint256 availableETH = getAvailableOwnerETH();
        require(availableETH > 0, "There is no available ETH to withdraw");

        ownerWithdrawnETH = ownerWithdrawnETH.add(availableETH);
        totalWithdrawnETH = totalWithdrawnETH.add(availableETH);

        msg.sender.sendValue(availableETH);
        emit ETHWithdrawn(msg.sender, availableETH);
    }

    /**
    * @notice Withdraw available amount of ETH to delegator
    */
    function withdrawETH() public override {
        uint256 availableETH = getAvailableETH(msg.sender);
        require(availableETH > 0, "There is no available ETH to withdraw");

        Delegator storage delegator = delegators[msg.sender];
        delegator.withdrawnETH = delegator.withdrawnETH.add(availableETH);

        totalWithdrawnETH = totalWithdrawnETH.add(availableETH);
        msg.sender.sendValue(availableETH);
        emit ETHWithdrawn(msg.sender, availableETH);
    }

    /**
    * @notice Calling fallback function is allowed only for the owner
    **/
    function isFallbackAllowed() public view override returns (bool) {
        return msg.sender == owner();
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

import "../../zeppelin/ownership/Ownable.sol";
import "../../zeppelin/math/SafeMath.sol";
import "./AbstractStakingContract.sol";

/**
 * @notice Contract acts as delegate for sub-stakers
 **/
contract PoolingStakingContractV2 is InitializableStakingContract, Ownable {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for NuCypherToken;

    event TokensDeposited(
        address indexed sender,
        uint256 value,
        uint256 depositedTokens
    );
    event TokensWithdrawn(
        address indexed sender,
        uint256 value,
        uint256 depositedTokens
    );
    event ETHWithdrawn(address indexed sender, uint256 value);
    event WorkerOwnerSet(address indexed sender, address indexed workerOwner);

    struct Delegator {
        uint256 depositedTokens;
        uint256 withdrawnReward;
        uint256 withdrawnETH;
    }

    /**
     * Defines base fraction and precision of worker fraction.
     * E.g., for a value of 10000, a worker fraction of 100 represents 1% of reward (100/10000)
     */
    uint256 public constant BASIS_FRACTION = 10000;

    StakingEscrow public escrow;
    address public workerOwner;

    uint256 public totalDepositedTokens;
    uint256 public totalWithdrawnReward;
    uint256 public totalWithdrawnETH;

    uint256 workerFraction;
    uint256 public workerWithdrawnReward;

    mapping(address => Delegator) public delegators;

    /**
     * @notice Initialize function for using with OpenZeppelin proxy
     * @param _workerFraction Share of token reward that worker node owner will get.
     * Use value up to BASIS_FRACTION (10000), if _workerFraction = BASIS_FRACTION -> means 100% reward as commission.
     * For example, 100 worker fraction is 1% of reward
     * @param _router StakingInterfaceRouter address
     * @param _workerOwner Owner of worker node, only this address can withdraw worker commission
     */
    function initialize(
        uint256 _workerFraction,
        StakingInterfaceRouter _router,
        address _workerOwner
    ) external initializer {
        require(_workerOwner != address(0) && _workerFraction <= BASIS_FRACTION);
        InitializableStakingContract.initialize(_router);
        _transferOwnership(msg.sender);
        escrow = _router.target().escrow();
        workerFraction = _workerFraction;
        workerOwner = _workerOwner;
        emit WorkerOwnerSet(msg.sender, _workerOwner);
    }

    /**
     * @notice withdrawAll() is allowed
     */
    function isWithdrawAllAllowed() public view returns (bool) {
        // no tokens in StakingEscrow contract which belong to pool
        return escrow.getAllTokens(address(this)) == 0;
    }

    /**
     * @notice deposit() is allowed
     */
    function isDepositAllowed() public view returns (bool) {
        // tokens which directly belong to pool
        uint256 freeTokens = token.balanceOf(address(this));

        // no sub-stakes and no earned reward
        return isWithdrawAllAllowed() && freeTokens == totalDepositedTokens;
    }

    /**
     * @notice Set worker owner address
     */
    function setWorkerOwner(address _workerOwner) external onlyOwner {
        workerOwner = _workerOwner;
        emit WorkerOwnerSet(msg.sender, _workerOwner);
    }

    /**
     * @notice Calculate worker's fraction depending on deposited tokens
     * Override to implement dynamic worker fraction.
     */
    function getWorkerFraction() public view virtual returns (uint256) {
        return workerFraction;
    }

    /**
     * @notice Transfer tokens as delegator
     * @param _value Amount of tokens to transfer
     */
    function depositTokens(uint256 _value) external {
        require(isDepositAllowed(), "Deposit must be enabled");
        require(_value > 0, "Value must be not empty");
        totalDepositedTokens = totalDepositedTokens.add(_value);
        Delegator storage delegator = delegators[msg.sender];
        delegator.depositedTokens = delegator.depositedTokens.add(_value);
        token.safeTransferFrom(msg.sender, address(this), _value);
        emit TokensDeposited(msg.sender, _value, delegator.depositedTokens);
    }

    /**
     * @notice Get available reward for all delegators and owner
     */
    function getAvailableReward() public view returns (uint256) {
        // locked + unlocked tokens in StakingEscrow contract which belong to pool
        uint256 stakedTokens = escrow.getAllTokens(address(this));
        // tokens which directly belong to pool
        uint256 freeTokens = token.balanceOf(address(this));
        // tokens in excess of the initially deposited
        uint256 reward = stakedTokens.add(freeTokens).sub(totalDepositedTokens);
        // check how many of reward tokens belong directly to pool
        if (reward > freeTokens) {
            return freeTokens;
        }
        return reward;
    }

    /**
     * @notice Get cumulative reward.
     * Available and withdrawn reward together to use in delegator/owner reward calculations
     */
    function getCumulativeReward() public view returns (uint256) {
        return getAvailableReward().add(totalWithdrawnReward);
    }

    /**
     * @notice Get available reward in tokens for worker node owner
     */
    function getAvailableWorkerReward() public view returns (uint256) {
        // total current and historical reward
        uint256 reward = getCumulativeReward();

        // calculate total reward for worker including historical reward
        uint256 maxAllowableReward;
        // usual case
        if (totalDepositedTokens != 0) {
            uint256 fraction = getWorkerFraction();
            maxAllowableReward = reward.mul(fraction).div(BASIS_FRACTION);
        // special case when there are no delegators
        } else {
            maxAllowableReward = reward;
        }

        // check that worker has any new reward
        if (maxAllowableReward > workerWithdrawnReward) {
            return maxAllowableReward - workerWithdrawnReward;
        }
        return 0;
    }

    /**
     * @notice Get available reward in tokens for delegator
     */
    function getAvailableDelegatorReward(address _delegator) public view returns (uint256) {
        // special case when there are no delegators
        if (totalDepositedTokens == 0) {
            return 0;
        }

        // total current and historical reward
        uint256 reward = getCumulativeReward();
        Delegator storage delegator = delegators[_delegator];
        uint256 fraction = getWorkerFraction();

        // calculate total reward for delegator including historical reward
        // excluding worker share
        uint256 maxAllowableReward = reward.mul(delegator.depositedTokens).mul(BASIS_FRACTION - fraction).div(
            totalDepositedTokens.mul(BASIS_FRACTION)
        );

        // check that worker has any new reward
        if (maxAllowableReward > delegator.withdrawnReward) {
            return maxAllowableReward - delegator.withdrawnReward;
        }
        return 0;
    }

    /**
     * @notice Withdraw reward in tokens to worker node owner
     */
    function withdrawWorkerReward() external {
        require(msg.sender == workerOwner);
        uint256 balance = token.balanceOf(address(this));
        uint256 availableReward = getAvailableWorkerReward();

        if (availableReward > balance) {
            availableReward = balance;
        }
        require(
            availableReward > 0,
            "There is no available reward to withdraw"
        );
        workerWithdrawnReward = workerWithdrawnReward.add(availableReward);
        totalWithdrawnReward = totalWithdrawnReward.add(availableReward);

        token.safeTransfer(msg.sender, availableReward);
        emit TokensWithdrawn(msg.sender, availableReward, 0);
    }

    /**
     * @notice Withdraw reward to delegator
     * @param _value Amount of tokens to withdraw
     */
    function withdrawTokens(uint256 _value) public override {
        uint256 balance = token.balanceOf(address(this));
        require(_value <= balance, "Not enough tokens in the contract");

        Delegator storage delegator = delegators[msg.sender];
        uint256 availableReward = getAvailableDelegatorReward(msg.sender);

        require( _value <= availableReward, "Requested amount of tokens exceeded allowed portion");
        delegator.withdrawnReward = delegator.withdrawnReward.add(_value);
        totalWithdrawnReward = totalWithdrawnReward.add(_value);

        token.safeTransfer(msg.sender, _value);
        emit TokensWithdrawn(msg.sender, _value, delegator.depositedTokens);
    }

    /**
     * @notice Withdraw reward, deposit and fee to delegator
     */
    function withdrawAll() public {
        require(isWithdrawAllAllowed(), "Withdraw deposit and reward must be enabled");
        uint256 balance = token.balanceOf(address(this));

        Delegator storage delegator = delegators[msg.sender];
        uint256 availableReward = getAvailableDelegatorReward(msg.sender);
        uint256 value = availableReward.add(delegator.depositedTokens);
        require(value <= balance, "Not enough tokens in the contract");

        // TODO remove double reading: availableReward and availableWorkerReward use same calls to external contracts
        uint256 availableWorkerReward = getAvailableWorkerReward();

        // potentially could be less then due reward
        uint256 availableETH = getAvailableDelegatorETH(msg.sender);

        // prevent losing reward for worker after calculations
        uint256 workerReward = availableWorkerReward.mul(delegator.depositedTokens).div(totalDepositedTokens);
        if (workerReward > 0) {
            require(value.add(workerReward) <= balance, "Not enough tokens in the contract");
            token.safeTransfer(workerOwner, workerReward);
            emit TokensWithdrawn(workerOwner, workerReward, 0);
        }

        uint256 withdrawnToDecrease = workerWithdrawnReward.mul(delegator.depositedTokens).div(totalDepositedTokens);

        workerWithdrawnReward = workerWithdrawnReward.sub(withdrawnToDecrease);
        totalWithdrawnReward = totalWithdrawnReward.sub(withdrawnToDecrease).sub(delegator.withdrawnReward);
        totalDepositedTokens = totalDepositedTokens.sub(delegator.depositedTokens);

        delegator.withdrawnReward = 0;
        delegator.depositedTokens = 0;

        token.safeTransfer(msg.sender, value);
        emit TokensWithdrawn(msg.sender, value, 0);

        totalWithdrawnETH = totalWithdrawnETH.sub(delegator.withdrawnETH);
        delegator.withdrawnETH = 0;
        if (availableETH > 0) {
            emit ETHWithdrawn(msg.sender, availableETH);
            msg.sender.sendValue(availableETH);
        }
    }

    /**
     * @notice Get available ether for delegator
     */
    function getAvailableDelegatorETH(address _delegator) public view returns (uint256) {
        Delegator storage delegator = delegators[_delegator];
        uint256 balance = address(this).balance;
        // ETH balance + already withdrawn
        balance = balance.add(totalWithdrawnETH);
        uint256 maxAllowableETH = balance.mul(delegator.depositedTokens).div(totalDepositedTokens);

        uint256 availableETH = maxAllowableETH.sub(delegator.withdrawnETH);
        if (availableETH > balance) {
            availableETH = balance;
        }
        return availableETH;
    }

    /**
     * @notice Withdraw available amount of ETH to delegator
     */
    function withdrawETH() public override {
        Delegator storage delegator = delegators[msg.sender];
        uint256 availableETH = getAvailableDelegatorETH(msg.sender);
        require(availableETH > 0, "There is no available ETH to withdraw");
        delegator.withdrawnETH = delegator.withdrawnETH.add(availableETH);

        totalWithdrawnETH = totalWithdrawnETH.add(availableETH);
        emit ETHWithdrawn(msg.sender, availableETH);
        msg.sender.sendValue(availableETH);
    }

    /**
     * @notice Calling fallback function is allowed only for the owner
     */
    function isFallbackAllowed() public override view returns (bool) {
        return msg.sender == owner();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "../../zeppelin/ownership/Ownable.sol";
import "../../zeppelin/math/SafeMath.sol";
import "./AbstractStakingContract.sol";


/**
* @notice Contract holds tokens for vesting.
* Also tokens can be used as a stake in the staking escrow contract
*/
contract PreallocationEscrow is AbstractStakingContract, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for NuCypherToken;
    using Address for address payable;

    event TokensDeposited(address indexed sender, uint256 value, uint256 duration);
    event TokensWithdrawn(address indexed owner, uint256 value);
    event ETHWithdrawn(address indexed owner, uint256 value);

    StakingEscrow public immutable stakingEscrow;

    uint256 public lockedValue;
    uint256 public endLockTimestamp;

    /**
    * @param _router Address of the StakingInterfaceRouter contract
    */
    constructor(StakingInterfaceRouter _router) AbstractStakingContract(_router) {
        stakingEscrow = _router.target().escrow();
    }

    /**
    * @notice Initial tokens deposit
    * @param _sender Token sender
    * @param _value Amount of token to deposit
    * @param _duration Duration of tokens locking
    */
    function initialDeposit(address _sender, uint256 _value, uint256 _duration) internal {
        require(lockedValue == 0 && _value > 0);
        endLockTimestamp = block.timestamp.add(_duration);
        lockedValue = _value;
        token.safeTransferFrom(_sender, address(this), _value);
        emit TokensDeposited(_sender, _value, _duration);
    }

    /**
    * @notice Initial tokens deposit
    * @param _value Amount of token to deposit
    * @param _duration Duration of tokens locking
    */
    function initialDeposit(uint256 _value, uint256 _duration) external {
        initialDeposit(msg.sender, _value, _duration);
    }

    /**
    * @notice Implementation of the receiveApproval(address,uint256,address,bytes) method
    * (see NuCypherToken contract). Initial tokens deposit
    * @param _from Sender
    * @param _value Amount of tokens to deposit
    * @param _tokenContract Token contract address
    * @notice (param _extraData) Amount of seconds during which tokens will be locked
    */
    function receiveApproval(
        address _from,
        uint256 _value,
        address _tokenContract,
        bytes calldata /* _extraData */
    )
        external
    {
        require(_tokenContract == address(token) && msg.sender == address(token));

        // Copy first 32 bytes from _extraData, according to calldata memory layout:
        //
        // 0x00: method signature      4 bytes
        // 0x04: _from                 32 bytes after encoding
        // 0x24: _value                32 bytes after encoding
        // 0x44: _tokenContract        32 bytes after encoding
        // 0x64: _extraData pointer    32 bytes. Value must be 0x80 (offset of _extraData wrt to 1st parameter)
        // 0x84: _extraData length     32 bytes
        // 0xA4: _extraData data       Length determined by previous variable
        //
        // See https://solidity.readthedocs.io/en/latest/abi-spec.html#examples

        uint256 payloadSize;
        uint256 payload;
        assembly {
            payloadSize := calldataload(0x84)
            payload := calldataload(0xA4)
        }
        payload = payload >> 8*(32 - payloadSize);
        initialDeposit(_from, _value, payload);
    }

    /**
    * @notice Get locked tokens value
    */
    function getLockedTokens() public view returns (uint256) {
        if (endLockTimestamp <= block.timestamp) {
            return 0;
        }
        return lockedValue;
    }

    /**
    * @notice Withdraw available amount of tokens to owner
    * @param _value Amount of token to withdraw
    */
    function withdrawTokens(uint256 _value) public override onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _value);
        // Withdrawal invariant for PreallocationEscrow:
        // After withdrawing, the sum of all escrowed tokens (either here or in StakingEscrow) must exceed the locked amount
        require(balance - _value + stakingEscrow.getAllTokens(address(this)) >= getLockedTokens());
        token.safeTransfer(msg.sender, _value);
        emit TokensWithdrawn(msg.sender, _value);
    }

    /**
    * @notice Withdraw available ETH to the owner
    */
    function withdrawETH() public override onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0);
        msg.sender.sendValue(balance);
        emit ETHWithdrawn(msg.sender, balance);
    }

    /**
    * @notice Calling fallback function is allowed only for the owner
    */
    function isFallbackAllowed() public view override returns (bool) {
        return msg.sender == owner();
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

import "../../zeppelin/ownership/Ownable.sol";
import "../../zeppelin/math/SafeMath.sol";
import "./AbstractStakingContract.sol";

/**
 * @notice Contract acts as delegate for sub-stakers and owner
 * @author @vzotova and @roma_k
 **/
contract WorkLockPoolingContract is InitializableStakingContract, Ownable {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for NuCypherToken;

    event TokensDeposited(
        address indexed sender,
        uint256 value,
        uint256 depositedTokens
    );
    event TokensWithdrawn(
        address indexed sender,
        uint256 value,
        uint256 depositedTokens
    );
    event ETHWithdrawn(address indexed sender, uint256 value);
    event DepositSet(address indexed sender, bool value);
    event Bid(address indexed sender, uint256 depositedETH);
    event Claimed(address indexed sender, uint256 claimedTokens);
    event Refund(address indexed sender, uint256 refundETH);

    struct Delegator {
        uint256 depositedTokens;
        uint256 withdrawnReward;
        uint256 withdrawnETH;

        uint256 depositedETHWorkLock;
        uint256 refundedETHWorkLock;
        bool claimedWorkLockTokens;
    }

    uint256 public constant BASIS_FRACTION = 100;

    StakingEscrow public escrow;
    WorkLock public workLock;
    address public workerOwner;

    uint256 public totalDepositedTokens;
    uint256 public workLockClaimedTokens;

    uint256 public totalWithdrawnReward;
    uint256 public totalWithdrawnETH;

    uint256 public totalWorkLockETHReceived;
    uint256 public totalWorkLockETHRefunded;
    uint256 public totalWorkLockETHWithdrawn;

    uint256 workerFraction;
    uint256 public workerWithdrawnReward;

    mapping(address => Delegator) public delegators;
    bool depositIsEnabled = true;

    /**
     * @notice Initialize function for using with OpenZeppelin proxy
     * @param _workerFraction Share of token reward that worker node owner will get.
     * Use value up to BASIS_FRACTION, if _workerFraction = BASIS_FRACTION -> means 100% reward as commission
     * @param _router StakingInterfaceRouter address
     * @param _workerOwner Owner of worker node, only this address can withdraw worker commission
     */
    function initialize(
        uint256 _workerFraction,
        StakingInterfaceRouter _router,
        address _workerOwner
    ) public initializer {
        require(_workerOwner != address(0) && _workerFraction <= BASIS_FRACTION);
        InitializableStakingContract.initialize(_router);
        _transferOwnership(msg.sender);
        escrow = _router.target().escrow();
        workLock = _router.target().workLock();
        workerFraction = _workerFraction;
        workerOwner = _workerOwner;
    }

    /**
     * @notice Enabled deposit
     */
    function enableDeposit() external onlyOwner {
        depositIsEnabled = true;
        emit DepositSet(msg.sender, depositIsEnabled);
    }

    /**
     * @notice Disable deposit
     */
    function disableDeposit() external onlyOwner {
        depositIsEnabled = false;
        emit DepositSet(msg.sender, depositIsEnabled);
    }

    /**
     * @notice Calculate worker's fraction depending on deposited tokens
     */
    function getWorkerFraction() public view returns (uint256) {
        return workerFraction;
    }

    /**
     * @notice Transfer tokens as delegator
     * @param _value Amount of tokens to transfer
     */
    function depositTokens(uint256 _value) external {
        require(depositIsEnabled, "Deposit must be enabled");
        require(_value > 0, "Value must be not empty");
        totalDepositedTokens = totalDepositedTokens.add(_value);
        Delegator storage delegator = delegators[msg.sender];
        delegator.depositedTokens = delegator.depositedTokens.add(_value);
        token.safeTransferFrom(msg.sender, address(this), _value);
        emit TokensDeposited(msg.sender, _value, delegator.depositedTokens);
    }

    /**
     * @notice Delegator can transfer ETH directly to workLock
     */
    function escrowETH() external payable {
        Delegator storage delegator = delegators[msg.sender];
        delegator.depositedETHWorkLock = delegator.depositedETHWorkLock.add(msg.value);
        totalWorkLockETHReceived = totalWorkLockETHReceived.add(msg.value);
        workLock.bid{value: msg.value}();
        emit Bid(msg.sender, msg.value);
    }

    /**
     * @dev Hide method from StakingInterface
     */
    function bid(uint256) public payable {
        revert();
    }

    /**
     * @dev Hide method from StakingInterface
     */
    function withdrawCompensation() public pure {
        revert();
    }

    /**
     * @dev Hide method from StakingInterface
     */
    function cancelBid() public pure {
        revert();
    }

    /**
     * @dev Hide method from StakingInterface
     */
    function claim() public pure {
        revert();
    }

    /**
     * @notice Claim tokens in WorkLock and save number of claimed tokens
     */
    function claimTokensFromWorkLock() public {
        workLockClaimedTokens = workLock.claim();
        totalDepositedTokens = totalDepositedTokens.add(workLockClaimedTokens);
        emit Claimed(address(this), workLockClaimedTokens);
    }

    /**
     * @notice Calculate and save number of claimed tokens for specified delegator
     */
    function calculateAndSaveTokensAmount() external {
        Delegator storage delegator = delegators[msg.sender];
        calculateAndSaveTokensAmount(delegator);
    }

    /**
     * @notice Calculate and save number of claimed tokens for specified delegator
     */
    function calculateAndSaveTokensAmount(Delegator storage _delegator) internal {
        if (workLockClaimedTokens == 0 ||
            _delegator.depositedETHWorkLock == 0 ||
            _delegator.claimedWorkLockTokens)
        {
            return;
        }

        uint256 delegatorTokensShare = _delegator.depositedETHWorkLock.mul(workLockClaimedTokens)
            .div(totalWorkLockETHReceived);

        _delegator.depositedTokens = _delegator.depositedTokens.add(delegatorTokensShare);
        _delegator.claimedWorkLockTokens = true;
        emit Claimed(msg.sender, delegatorTokensShare);
    }

    /**
     * @notice Get available reward for all delegators and owner
     */
    function getAvailableReward() public view returns (uint256) {
        uint256 stakedTokens = escrow.getAllTokens(address(this));
        uint256 freeTokens = token.balanceOf(address(this));
        uint256 reward = stakedTokens.add(freeTokens).sub(totalDepositedTokens);
        if (reward > freeTokens) {
            return freeTokens;
        }
        return reward;
    }

    /**
     * @notice Get cumulative reward
     */
    function getCumulativeReward() public view returns (uint256) {
        return getAvailableReward().add(totalWithdrawnReward);
    }

    /**
     * @notice Get available reward in tokens for worker node owner
     */
    function getAvailableWorkerReward() public view returns (uint256) {
        uint256 reward = getCumulativeReward();

        uint256 maxAllowableReward;
        if (totalDepositedTokens != 0) {
            uint256 fraction = getWorkerFraction();
            maxAllowableReward = reward.mul(fraction).div(BASIS_FRACTION);
        } else {
            maxAllowableReward = reward;
        }

        if (maxAllowableReward > workerWithdrawnReward) {
            return maxAllowableReward - workerWithdrawnReward;
        }
        return 0;
    }

    /**
     * @notice Get available reward in tokens for delegator
     */
    function getAvailableReward(address _delegator)
        public
        view
        returns (uint256)
    {
        if (totalDepositedTokens == 0) {
            return 0;
        }

        uint256 reward = getCumulativeReward();
        Delegator storage delegator = delegators[_delegator];
        uint256 fraction = getWorkerFraction();
        uint256 maxAllowableReward = reward.mul(delegator.depositedTokens).mul(BASIS_FRACTION - fraction).div(
            totalDepositedTokens.mul(BASIS_FRACTION)
        );

        return
            maxAllowableReward > delegator.withdrawnReward
                ? maxAllowableReward - delegator.withdrawnReward
                : 0;
    }

    /**
     * @notice Withdraw reward in tokens to worker node owner
     */
    function withdrawWorkerReward() external {
        require(msg.sender == workerOwner);
        uint256 balance = token.balanceOf(address(this));
        uint256 availableReward = getAvailableWorkerReward();

        if (availableReward > balance) {
            availableReward = balance;
        }
        require(
            availableReward > 0,
            "There is no available reward to withdraw"
        );
        workerWithdrawnReward = workerWithdrawnReward.add(availableReward);
        totalWithdrawnReward = totalWithdrawnReward.add(availableReward);

        token.safeTransfer(msg.sender, availableReward);
        emit TokensWithdrawn(msg.sender, availableReward, 0);
    }

    /**
     * @notice Withdraw reward to delegator
     * @param _value Amount of tokens to withdraw
     */
    function withdrawTokens(uint256 _value) public override {
        uint256 balance = token.balanceOf(address(this));
        require(_value <= balance, "Not enough tokens in the contract");

        Delegator storage delegator = delegators[msg.sender];
        calculateAndSaveTokensAmount(delegator);

        uint256 availableReward = getAvailableReward(msg.sender);

        require( _value <= availableReward, "Requested amount of tokens exceeded allowed portion");
        delegator.withdrawnReward = delegator.withdrawnReward.add(_value);
        totalWithdrawnReward = totalWithdrawnReward.add(_value);

        token.safeTransfer(msg.sender, _value);
        emit TokensWithdrawn(msg.sender, _value, delegator.depositedTokens);
    }

    /**
     * @notice Withdraw reward, deposit and fee to delegator
     */
    function withdrawAll() public {
        uint256 balance = token.balanceOf(address(this));

        Delegator storage delegator = delegators[msg.sender];
        calculateAndSaveTokensAmount(delegator);

        uint256 availableReward = getAvailableReward(msg.sender);
        uint256 value = availableReward.add(delegator.depositedTokens);
        require(value <= balance, "Not enough tokens in the contract");

        // TODO remove double reading
        uint256 availableWorkerReward = getAvailableWorkerReward();

        // potentially could be less then due reward
        uint256 availableETH = getAvailableETH(msg.sender);

        // prevent losing reward for worker after calculations
        uint256 workerReward = availableWorkerReward.mul(delegator.depositedTokens).div(totalDepositedTokens);
        if (workerReward > 0) {
            require(value.add(workerReward) <= balance, "Not enough tokens in the contract");
            token.safeTransfer(workerOwner, workerReward);
            emit TokensWithdrawn(workerOwner, workerReward, 0);
        }

        uint256 withdrawnToDecrease = workerWithdrawnReward.mul(delegator.depositedTokens).div(totalDepositedTokens);

        workerWithdrawnReward = workerWithdrawnReward.sub(withdrawnToDecrease);
        totalWithdrawnReward = totalWithdrawnReward.sub(withdrawnToDecrease).sub(delegator.withdrawnReward);
        totalDepositedTokens = totalDepositedTokens.sub(delegator.depositedTokens);

        delegator.withdrawnReward = 0;
        delegator.depositedTokens = 0;

        token.safeTransfer(msg.sender, value);
        emit TokensWithdrawn(msg.sender, value, 0);

        totalWithdrawnETH = totalWithdrawnETH.sub(delegator.withdrawnETH);
        delegator.withdrawnETH = 0;
        if (availableETH > 0) {
            msg.sender.sendValue(availableETH);
            emit ETHWithdrawn(msg.sender, availableETH);
        }
    }

    /**
     * @notice Get available ether for delegator
     */
    function getAvailableETH(address _delegator) public view returns (uint256) {
        Delegator storage delegator = delegators[_delegator];
        uint256 balance = address(this).balance;
        // ETH balance + already withdrawn - (refunded - refundWithdrawn)
        balance = balance.add(totalWithdrawnETH).add(totalWorkLockETHWithdrawn).sub(totalWorkLockETHRefunded);
        uint256 maxAllowableETH = balance.mul(delegator.depositedTokens).div(totalDepositedTokens);

        uint256 availableETH = maxAllowableETH.sub(delegator.withdrawnETH);
        if (availableETH > balance) {
            availableETH = balance;
        }
        return availableETH;
    }

    /**
     * @notice Withdraw available amount of ETH to delegator
     */
    function withdrawETH() public override {
        Delegator storage delegator = delegators[msg.sender];
        calculateAndSaveTokensAmount(delegator);

        uint256 availableETH = getAvailableETH(msg.sender);
        require(availableETH > 0, "There is no available ETH to withdraw");
        delegator.withdrawnETH = delegator.withdrawnETH.add(availableETH);

        totalWithdrawnETH = totalWithdrawnETH.add(availableETH);
        msg.sender.sendValue(availableETH);
        emit ETHWithdrawn(msg.sender, availableETH);
    }

    /**
     * @notice Withdraw compensation and refund from WorkLock and save these numbers
     */
    function refund() public {
        uint256 balance = address(this).balance;
        if (workLock.compensation(address(this)) > 0) {
            workLock.withdrawCompensation();
        }
        workLock.refund();
        uint256 refundETH = address(this).balance - balance;
        totalWorkLockETHRefunded = totalWorkLockETHRefunded.add(refundETH);
        emit Refund(address(this), refundETH);
    }

    /**
     * @notice Get available refund for delegator
     */
    function getAvailableRefund(address _delegator) public view returns (uint256) {
        Delegator storage delegator = delegators[_delegator];
        uint256 maxAllowableETH = totalWorkLockETHRefunded.mul(delegator.depositedETHWorkLock)
            .div(totalWorkLockETHReceived);

        uint256 availableETH = maxAllowableETH.sub(delegator.refundedETHWorkLock);
        uint256 balance = totalWorkLockETHRefunded.sub(totalWorkLockETHWithdrawn);

        if (availableETH > balance) {
            availableETH = balance;
        }
        return availableETH;
    }

    /*
     * @notice Withdraw available amount of ETH to delegator
     */
    function withdrawRefund() external {
        uint256 availableETH = getAvailableRefund(msg.sender);
        require(availableETH > 0, "There is no available ETH to withdraw");

        Delegator storage delegator = delegators[msg.sender];
        delegator.refundedETHWorkLock = delegator.refundedETHWorkLock.add(availableETH);

        totalWorkLockETHWithdrawn = totalWorkLockETHWithdrawn.add(availableETH);
        msg.sender.sendValue(availableETH);
        emit Refund(msg.sender, availableETH);
    }

    /**
     * @notice Calling fallback function is allowed only for the owner
     */
    function isFallbackAllowed() public override view returns (bool) {
        return msg.sender == owner();
    }
}

