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
