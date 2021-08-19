/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}


// File contracts/VRFv2/interfaces/BlockhashStoreInterface.sol


pragma solidity ^0.8.0;

interface BlockhashStoreInterface {
  function getBlockhash(uint256 number) external view returns (bytes32);
}


// File contracts/VRFv2/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File contracts/VRFv2/interfaces/TypeAndVersionInterface.sol


pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    virtual
    returns (
      string memory
    );
}


// File contracts/VRFv2/VRF.sol


pragma solidity ^0.8.0;

/** ****************************************************************************
  * @notice Verification of verifiable-random-function (VRF) proofs, following
  * @notice https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @notice See https://eprint.iacr.org/2017/099.pdf for security proofs.

  * @dev Bibliographic references:

  * @dev Goldberg, et al., "Verifiable Random Functions (VRFs)", Internet Draft
  * @dev draft-irtf-cfrg-vrf-05, IETF, Aug 11 2019,
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05

  * @dev Papadopoulos, et al., "Making NSEC5 Practical for DNSSEC", Cryptology
  * @dev ePrint Archive, Report 2017/099, https://eprint.iacr.org/2017/099.pdf
  * ****************************************************************************
  * @dev USAGE

  * @dev The main entry point is randomValueFromVRFProof. See its docstring.
  * ****************************************************************************
  * @dev PURPOSE

  * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
  * @dev to Vera the verifier in such a way that Vera can be sure he's not
  * @dev making his output up to suit himself. Reggie provides Vera a public key
  * @dev to which he knows the secret key. Each time Vera provides a seed to
  * @dev Reggie, he gives back a value which is computed completely
  * @dev deterministically from the seed and the secret key.

  * @dev Reggie provides a proof by which Vera can verify that the output was
  * @dev correctly computed once Reggie tells it to her, but without that proof,
  * @dev the output is computationally indistinguishable to her from a uniform
  * @dev random sample from the output space.

  * @dev The purpose of this contract is to perform that verification.
  * ****************************************************************************
  * @dev DESIGN NOTES

  * @dev The VRF algorithm verified here satisfies the full unqiqueness, full
  * @dev collision resistance, and full pseudorandomness security properties.
  * @dev See "SECURITY PROPERTIES" below, and
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-3

  * @dev An elliptic curve point is generally represented in the solidity code
  * @dev as a uint256[2], corresponding to its affine coordinates in
  * @dev GF(FIELD_SIZE).

  * @dev For the sake of efficiency, this implementation deviates from the spec
  * @dev in some minor ways:

  * @dev - Keccak hash rather than the SHA256 hash recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   Keccak costs much less gas on the EVM, and provides similar security.

  * @dev - Secp256k1 curve instead of the P-256 or ED25519 curves recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   For curve-point multiplication, it's much cheaper to abuse ECRECOVER

  * @dev - hashToCurve recursively hashes until it finds a curve x-ordinate. On
  * @dev   the EVM, this is slightly more efficient than the recommendation in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
  * @dev   step 5, to concatenate with a nonce then hash, and rehash with the
  * @dev   nonce updated until a valid x-ordinate is found.

  * @dev - hashToCurve does not include a cipher version string or the byte 0x1
  * @dev   in the hash message, as recommended in step 5.B of the draft
  * @dev   standard. They are unnecessary here because no variation in the
  * @dev   cipher suite is allowed.

  * @dev - Similarly, the hash input in scalarFromCurvePoints does not include a
  * @dev   commitment to the cipher suite, either, which differs from step 2 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
  * @dev   . Also, the hash input is the concatenation of the uncompressed
  * @dev   points, not the compressed points as recommended in step 3.

  * @dev - In the calculation of the challenge value "c", the "u" value (i.e.
  * @dev   the value computed by Reggie as the nonce times the secp256k1
  * @dev   generator point, see steps 5 and 7 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @dev   ) is replaced by its ethereum address, i.e. the lower 160 bits of the
  * @dev   keccak hash of the original u. This is because we only verify the
  * @dev   calculation of u up to its address, by abusing ECRECOVER.
  * ****************************************************************************
  * @dev   SECURITY PROPERTIES

  * @dev Here are the security properties for this VRF:

  * @dev Full uniqueness: For any seed and valid VRF public key, there is
  * @dev   exactly one VRF output which can be proved to come from that seed, in
  * @dev   the sense that the proof will pass verifyVRFProof.

  * @dev Full collision resistance: It's cryptographically infeasible to find
  * @dev   two seeds with same VRF output from a fixed, valid VRF key

  * @dev Full pseudorandomness: Absent the proofs that the VRF outputs are
  * @dev   derived from a given seed, the outputs are computationally
  * @dev   indistinguishable from randomness.

  * @dev https://eprint.iacr.org/2017/099.pdf, Appendix B contains the proofs
  * @dev for these properties.

  * @dev For secp256k1, the key validation described in section
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.6
  * @dev is unnecessary, because secp256k1 has cofactor 1, and the
  * @dev representation of the public key used here (affine x- and y-ordinates
  * @dev of the secp256k1 point on the standard y^2=x^3+7 curve) cannot refer to
  * @dev the point at infinity.
  * ****************************************************************************
  * @dev OTHER SECURITY CONSIDERATIONS
  *
  * @dev The seed input to the VRF could in principle force an arbitrary amount
  * @dev of work in hashToCurve, by requiring extra rounds of hashing and
  * @dev checking whether that's yielded the x ordinate of a secp256k1 point.
  * @dev However, under the Random Oracle Model the probability of choosing a
  * @dev point which forces n extra rounds in hashToCurve is 2⁻ⁿ. The base cost
  * @dev for calling hashToCurve is about 25,000 gas, and each round of checking
  * @dev for a valid x ordinate costs about 15,555 gas, so to find a seed for
  * @dev which hashToCurve would cost more than 2,017,000 gas, one would have to
  * @dev try, in expectation, about 2¹²⁸ seeds, which is infeasible for any
  * @dev foreseeable computational resources. (25,000 + 128 * 15,555 < 2,017,000.)

  * @dev Since the gas block limit for the Ethereum main net is 10,000,000 gas,
  * @dev this means it is infeasible for an adversary to prevent correct
  * @dev operation of this contract by choosing an adverse seed.

  * @dev (See TestMeasureHashToCurveGasCost for verification of the gas cost for
  * @dev hashToCurve.)

  * @dev It may be possible to make a secure constant-time hashToCurve function.
  * @dev See notes in hashToCurve docstring.
*/
contract VRF {

    // See https://www.secg.org/sec2-v2.pdf, section 2.4.1, for these constants.
    uint256 constant private GROUP_ORDER = // Number of points in Secp256k1
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    // Prime characteristic of the galois field over which Secp256k1 is defined
    uint256 constant private FIELD_SIZE =
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 constant private WORD_LENGTH_BYTES = 0x20;

    // (base^exponent) % FIELD_SIZE
    // Cribbed from https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
    function bigModExp(uint256 base, uint256 exponent)
    internal view returns (uint256 exponentiation) {
        uint256 callResult;
        uint256[6] memory bigModExpContractInputs;
        bigModExpContractInputs[0] = WORD_LENGTH_BYTES;  // Length of base
        bigModExpContractInputs[1] = WORD_LENGTH_BYTES;  // Length of exponent
        bigModExpContractInputs[2] = WORD_LENGTH_BYTES;  // Length of modulus
        bigModExpContractInputs[3] = base;
        bigModExpContractInputs[4] = exponent;
        bigModExpContractInputs[5] = FIELD_SIZE;
        uint256[1] memory output;
        assembly { // solhint-disable-line no-inline-assembly
            callResult := staticcall(
            not(0),                   // Gas cost: no limit
            0x05,                     // Bigmodexp contract address
            bigModExpContractInputs,
            0xc0,                     // Length of input segment: 6*0x20-bytes
            output,
            0x20                      // Length of output segment
            )
        }
        if (callResult == 0) {revert("bigModExp failure!");}
        return output[0];
    }

    // Let q=FIELD_SIZE. q % 4 = 3, ∴ x≡r^2 mod q ⇒ x^SQRT_POWER≡±r mod q.  See
    // https://en.wikipedia.org/wiki/Modular_square_root#Prime_or_prime_power_modulus
    uint256 constant private SQRT_POWER = (FIELD_SIZE + 1) >> 2;

    // Computes a s.t. a^2 = x in the field. Assumes a exists
    function squareRoot(uint256 x) internal view returns (uint256) {
        return bigModExp(x, SQRT_POWER);
    }

    // The value of y^2 given that (x,y) is on secp256k1.
    function ySquared(uint256 x) internal pure returns (uint256) {
        // Curve is y^2=x^3+7. See section 2.4.1 of https://www.secg.org/sec2-v2.pdf
        uint256 xCubed = mulmod(x, mulmod(x, x, FIELD_SIZE), FIELD_SIZE);
        return addmod(xCubed, 7, FIELD_SIZE);
    }

    // True iff p is on secp256k1
    function isOnCurve(uint256[2] memory p) internal pure returns (bool) {
        return ySquared(p[0]) == mulmod(p[1], p[1], FIELD_SIZE);
    }

    // Hash x uniformly into {0, ..., FIELD_SIZE-1}.
    function fieldHash(bytes memory b) internal pure returns (uint256 x_) {
        x_ = uint256(keccak256(b));
        // Rejecting if x >= FIELD_SIZE corresponds to step 2.1 in section 2.3.4 of
        // http://www.secg.org/sec1-v2.pdf , which is part of the definition of
        // string_to_point in the IETF draft
        while (x_ >= FIELD_SIZE) {
            x_ = uint256(keccak256(abi.encodePacked(x_)));
        }
    }

    // Hash b to a random point which hopefully lies on secp256k1. The y ordinate
    // is always even, due to
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
    // step 5.C, which references arbitrary_string_to_point, defined in
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5 as
    // returning the point with given x ordinate, and even y ordinate.
    function newCandidateSecp256k1Point(bytes memory b)
    internal view returns (uint256[2] memory p) {
        unchecked {
            p[0] = fieldHash(b);
            p[1] = squareRoot(ySquared(p[0]));
            if (p[1] % 2 == 1) {
                // Note that 0 <= p[1] < FIELD_SIZE
                // so this cannot wrap, we use unchecked to save gas.
                p[1] = FIELD_SIZE - p[1];
            }
        }
    }

    // Domain-separation tag for initial hash in hashToCurve. Corresponds to
    // vrf.go/hashToCurveHashPrefix
    uint256 constant HASH_TO_CURVE_HASH_PREFIX = 1;

    // Cryptographic hash function onto the curve.
    //
    // Corresponds to algorithm in section 5.4.1.1 of the draft standard. (But see
    // DESIGN NOTES above for slight differences.)
    //
    // TODO(alx): Implement a bounded-computation hash-to-curve, as described in
    // "Construction of Rational Points on Elliptic Curves over Finite Fields"
    // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.831.5299&rep=rep1&type=pdf
    // and suggested by
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-01#section-5.2.2
    // (Though we can't used exactly that because secp256k1's j-invariant is 0.)
    //
    // This would greatly simplify the analysis in "OTHER SECURITY CONSIDERATIONS"
    // https://www.pivotaltracker.com/story/show/171120900
    function hashToCurve(uint256[2] memory pk, uint256 input)
    internal view returns (uint256[2] memory rv) {
        rv = newCandidateSecp256k1Point(abi.encodePacked(HASH_TO_CURVE_HASH_PREFIX,
            pk, input));
        while (!isOnCurve(rv)) {
            rv = newCandidateSecp256k1Point(abi.encodePacked(rv[0]));
        }
    }

    /** *********************************************************************
     * @notice Check that product==scalar*multiplicand
     *
     * @dev Based on Vitalik Buterin's idea in ethresear.ch post cited below.
     *
     * @param multiplicand: secp256k1 point
     * @param scalar: non-zero GF(GROUP_ORDER) scalar
     * @param product: secp256k1 expected to be multiplier * multiplicand
     * @return verifies true iff product==scalar*ecmulVerify*multiplicand, with cryptographically high probability
     */
    function ecmulVerify(uint256[2] memory multiplicand, uint256 scalar,
        uint256[2] memory product) internal pure returns(bool verifies)
    {
        require(scalar != 0); // Rules out an ecrecover failure case
        uint256 x = multiplicand[0]; // x ordinate of multiplicand
        uint8 v = multiplicand[1] % 2 == 0 ? 27 : 28; // parity of y ordinate
        // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
        // Point corresponding to address ecrecover(0, v, x, s=scalar*x) is
        // (x⁻¹ mod GROUP_ORDER) * (scalar * x * multiplicand - 0 * g), i.e.
        // scalar*multiplicand. See https://crypto.stackexchange.com/a/18106
        bytes32 scalarTimesX = bytes32(mulmod(scalar, x, GROUP_ORDER));
        address actual = ecrecover(bytes32(0), v, bytes32(x), scalarTimesX);
        // Explicit conversion to address takes bottom 160 bits
        address expected = address(uint160(uint256(keccak256(abi.encodePacked(product)))));
        return (actual == expected);
    }

    // Returns x1/z1-x2/z2=(x1z2-x2z1)/(z1z2) in projective coordinates on P¹(𝔽ₙ)
    function projectiveSub(uint256 x1, uint256 z1, uint256 x2, uint256 z2)
    internal pure returns(uint256 x3, uint256 z3) {
        unchecked {
            uint256 num1 = mulmod(z2, x1, FIELD_SIZE);
            // Note this cannot wrap since x2 is a point in [0, FIELD_SIZE-1]
            // we use unchecked to save gas.
            uint256 num2 = mulmod(FIELD_SIZE - x2, z1, FIELD_SIZE);
            (x3, z3) = (addmod(num1, num2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
        }
    }

    // Returns x1/z1*x2/z2=(x1x2)/(z1z2), in projective coordinates on P¹(𝔽ₙ)
    function projectiveMul(uint256 x1, uint256 z1, uint256 x2, uint256 z2)
    internal pure returns(uint256 x3, uint256 z3) {
        (x3, z3) = (mulmod(x1, x2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }

    /** **************************************************************************
        @notice Computes elliptic-curve sum, in projective co-ordinates

        @dev Using projective coordinates avoids costly divisions

        @dev To use this with p and q in affine coordinates, call
        @dev projectiveECAdd(px, py, qx, qy). This will return
        @dev the addition of (px, py, 1) and (qx, qy, 1), in the
        @dev secp256k1 group.

        @dev This can be used to calculate the z which is the inverse to zInv
        @dev in isValidVRFOutput. But consider using a faster
        @dev re-implementation such as ProjectiveECAdd in the golang vrf package.

        @dev This function assumes [px,py,1],[qx,qy,1] are valid projective
             coordinates of secp256k1 points. That is safe in this contract,
             because this method is only used by linearCombination, which checks
             points are on the curve via ecrecover.
        **************************************************************************
        @param px The first affine coordinate of the first summand
        @param py The second affine coordinate of the first summand
        @param qx The first affine coordinate of the second summand
        @param qy The second affine coordinate of the second summand

        (px,py) and (qx,qy) must be distinct, valid secp256k1 points.
        **************************************************************************
        Return values are projective coordinates of [px,py,1]+[qx,qy,1] as points
        on secp256k1, in P²(𝔽ₙ)
        @return sx
        @return sy
        @return sz
    */
    function projectiveECAdd(uint256 px, uint256 py, uint256 qx, uint256 qy)
    internal pure returns(uint256 sx, uint256 sy, uint256 sz) {
        unchecked {
            // See "Group law for E/K : y^2 = x^3 + ax + b", in section 3.1.2, p. 80,
            // "Guide to Elliptic Curve Cryptography" by Hankerson, Menezes and Vanstone
            // We take the equations there for (sx,sy), and homogenize them to
            // projective coordinates. That way, no inverses are required, here, and we
            // only need the one inverse in affineECAdd.

            // We only need the "point addition" equations from Hankerson et al. Can
            // skip the "point doubling" equations because p1 == p2 is cryptographically
            // impossible, and required not to be the case in linearCombination.

            // Add extra "projective coordinate" to the two points
            (uint256 z1, uint256 z2) = (1, 1);

            // (lx, lz) = (qy-py)/(qx-px), i.e., gradient of secant line.
            // Cannot wrap since px and py are in [0, FIELD_SIZE-1]
            uint256 lx = addmod(qy, FIELD_SIZE - py, FIELD_SIZE);
            uint256 lz = addmod(qx, FIELD_SIZE - px, FIELD_SIZE);

            uint256 dx; // Accumulates denominator from sx calculation
            // sx=((qy-py)/(qx-px))^2-px-qx
            (sx, dx) = projectiveMul(lx, lz, lx, lz); // ((qy-py)/(qx-px))^2
            (sx, dx) = projectiveSub(sx, dx, px, z1); // ((qy-py)/(qx-px))^2-px
            (sx, dx) = projectiveSub(sx, dx, qx, z2); // ((qy-py)/(qx-px))^2-px-qx

            uint256 dy; // Accumulates denominator from sy calculation
            // sy=((qy-py)/(qx-px))(px-sx)-py
            (sy, dy) = projectiveSub(px, z1, sx, dx); // px-sx
            (sy, dy) = projectiveMul(sy, dy, lx, lz); // ((qy-py)/(qx-px))(px-sx)
            (sy, dy) = projectiveSub(sy, dy, py, z1); // ((qy-py)/(qx-px))(px-sx)-py

            if (dx != dy) { // Cross-multiply to put everything over a common denominator
                sx = mulmod(sx, dy, FIELD_SIZE);
                sy = mulmod(sy, dx, FIELD_SIZE);
                sz = mulmod(dx, dy, FIELD_SIZE);
            } else { // Already over a common denominator, use that for z ordinate
                sz = dx;
            }
        }
    }

    // p1+p2, as affine points on secp256k1.
    //
    // invZ must be the inverse of the z returned by projectiveECAdd(p1, p2).
    // It is computed off-chain to save gas.
    //
    // p1 and p2 must be distinct, because projectiveECAdd doesn't handle
    // point doubling.
    function affineECAdd(
        uint256[2] memory p1, uint256[2] memory p2,
        uint256 invZ) internal pure returns (uint256[2] memory) {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = projectiveECAdd(p1[0], p1[1], p2[0], p2[1]);
        require(mulmod(z, invZ, FIELD_SIZE) == 1, "invZ must be inverse of z");
        // Clear the z ordinate of the projective representation by dividing through
        // by it, to obtain the affine representation
        return [mulmod(x, invZ, FIELD_SIZE), mulmod(y, invZ, FIELD_SIZE)];
    }

    // True iff address(c*p+s*g) == lcWitness, where g is generator. (With
    // cryptographically high probability.)
    function verifyLinearCombinationWithGenerator(
        uint256 c, uint256[2] memory p, uint256 s, address lcWitness)
    internal pure returns (bool) {
        // Rule out ecrecover failure modes which return address 0.
        unchecked {
            require(lcWitness != address(0), "bad witness");
            uint8 v = (p[1] % 2 == 0) ? 27 : 28; // parity of y-ordinate of p
            // Note this cannot wrap (X - Y % X), but we use unchecked to save
            // gas.
            bytes32 pseudoHash = bytes32(GROUP_ORDER - mulmod(p[0], s, GROUP_ORDER)); // -s*p[0]
            bytes32 pseudoSignature = bytes32(mulmod(c, p[0], GROUP_ORDER)); // c*p[0]
            // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
            // The point corresponding to the address returned by
            // ecrecover(-s*p[0],v,p[0],c*p[0]) is
            // (p[0]⁻¹ mod GROUP_ORDER)*(c*p[0]-(-s)*p[0]*g)=c*p+s*g.
            // See https://crypto.stackexchange.com/a/18106
            // https://bitcoin.stackexchange.com/questions/38351/ecdsa-v-r-s-what-is-v
            address computed = ecrecover(pseudoHash, v, bytes32(p[0]), pseudoSignature);
            return computed == lcWitness;
        }
    }

    // c*p1 + s*p2. Requires cp1Witness=c*p1 and sp2Witness=s*p2. Also
    // requires cp1Witness != sp2Witness (which is fine for this application,
    // since it is cryptographically impossible for them to be equal. In the
    // (cryptographically impossible) case that a prover accidentally derives
    // a proof with equal c*p1 and s*p2, they should retry with a different
    // proof nonce.) Assumes that all points are on secp256k1
    // (which is checked in verifyVRFProof below.)
    function linearCombination(
        uint256 c, uint256[2] memory p1, uint256[2] memory cp1Witness,
        uint256 s, uint256[2] memory p2, uint256[2] memory sp2Witness,
        uint256 zInv)
    internal pure returns (uint256[2] memory) {
        unchecked {
            // Note we are relying on the wrap around here
            require(cp1Witness[0] - sp2Witness[0] % FIELD_SIZE != 0, "points in sum must be distinct");
            require(ecmulVerify(p1, c, cp1Witness), "First multiplication check failed");
            require(ecmulVerify(p2, s, sp2Witness), "Second multiplication check failed");
            return affineECAdd(cp1Witness, sp2Witness, zInv);
        }
    }

    // Domain-separation tag for the hash taken in scalarFromCurvePoints.
    // Corresponds to scalarFromCurveHashPrefix in vrf.go
    uint256 constant SCALAR_FROM_CURVE_POINTS_HASH_PREFIX = 2;

    // Pseudo-random number from inputs. Matches vrf.go/scalarFromCurvePoints, and
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
    // The draft calls (in step 7, via the definition of string_to_int, in
    // https://datatracker.ietf.org/doc/html/rfc8017#section-4.2 ) for taking the
    // first hash without checking that it corresponds to a number less than the
    // group order, which will lead to a slight bias in the sample.
    //
    // TODO(alx): We could save a bit of gas by following the standard here and
    // using the compressed representation of the points, if we collated the y
    // parities into a single bytes32.
    // https://www.pivotaltracker.com/story/show/171120588
    function scalarFromCurvePoints(
        uint256[2] memory hash, uint256[2] memory pk, uint256[2] memory gamma,
        address uWitness, uint256[2] memory v)
    internal pure returns (uint256 s) {
        return uint256(
            keccak256(abi.encodePacked(SCALAR_FROM_CURVE_POINTS_HASH_PREFIX,
            hash, pk, gamma, v, uWitness)));
    }

    // True if (gamma, c, s) is a correctly constructed randomness proof from pk
    // and seed. zInv must be the inverse of the third ordinate from
    // projectiveECAdd applied to cGammaWitness and sHashWitness. Corresponds to
    // section 5.3 of the IETF draft.
    //
    // TODO(alx): Since I'm only using pk in the ecrecover call, I could only pass
    // the x ordinate, and the parity of the y ordinate in the top bit of uWitness
    // (which I could make a uint256 without using any extra space.) Would save
    // about 2000 gas. https://www.pivotaltracker.com/story/show/170828567
    function verifyVRFProof(
        uint256[2] memory pk, uint256[2] memory gamma, uint256 c, uint256 s,
        uint256 seed, address uWitness, uint256[2] memory cGammaWitness,
        uint256[2] memory sHashWitness, uint256 zInv)
    internal view {
        unchecked {
            require(isOnCurve(pk), "public key is not on curve");
            require(isOnCurve(gamma), "gamma is not on curve");
            require(isOnCurve(cGammaWitness), "cGammaWitness is not on curve");
            require(isOnCurve(sHashWitness), "sHashWitness is not on curve");
            // Step 5. of IETF draft section 5.3 (pk corresponds to 5.3's Y, and here
            // we use the address of u instead of u itself. Also, here we add the
            // terms instead of taking the difference, and in the proof consruction in
            // vrf.GenerateProof, we correspondingly take the difference instead of
            // taking the sum as they do in step 7 of section 5.1.)
            require(
                verifyLinearCombinationWithGenerator(c, pk, s, uWitness),
                "addr(c*pk+s*g)!=_uWitness"
            );
            // Step 4. of IETF draft section 5.3 (pk corresponds to Y, seed to alpha_string)
            uint256[2] memory hash = hashToCurve(pk, seed);
            // Step 6. of IETF draft section 5.3, but see note for step 5 about +/- terms
            uint256[2] memory v = linearCombination(
                c, gamma, cGammaWitness, s, hash, sHashWitness, zInv);
            // Steps 7. and 8. of IETF draft section 5.3
            uint256 derivedC = scalarFromCurvePoints(hash, pk, gamma, uWitness, v);
            require(c == derivedC, "invalid proof");
        }
    }

    // Domain-separation tag for the hash used as the final VRF output.
    // Corresponds to vrfRandomOutputHashPrefix in vrf.go
    uint256 constant VRF_RANDOM_OUTPUT_HASH_PREFIX = 3;

    // Length of proof marshaled to bytes array. Shows layout of proof
    uint public constant PROOF_LENGTH = 64 + // PublicKey (uncompressed format.)
    64 + // Gamma
    32 + // C
    32 + // S
    32 + // Seed
    0 + // Dummy entry: The following elements are included for gas efficiency:
    32 + // uWitness (gets padded to 256 bits, even though it's only 160)
    64 + // cGammaWitness
    64 + // sHashWitness
    32; // zInv  (Leave Output out, because that can be efficiently calculated)

    /* ***************************************************************************
     * @notice Returns proof's output, if proof is valid. Otherwise reverts

     * @param proof A binary-encoded proof, as output by vrf.Proof.MarshalForSolidityVerifier
     *
     * Throws if proof is invalid, otherwise:
     * @return output i.e., the random output implied by the proof
     * ***************************************************************************
     * @dev See the calculation of PROOF_LENGTH for the binary layout of proof.
     */
    function randomValueFromVRFProof(bytes memory proof)
    internal view returns (uint256 output) {
        require(proof.length == PROOF_LENGTH, "wrong proof length");

        uint256[2] memory pk; // parse proof contents into these variables
        uint256[2] memory gamma;
        // c, s and seed combined (prevents "stack too deep" compilation error)
        uint256[3] memory cSSeed;
        address uWitness;
        uint256[2] memory cGammaWitness;
        uint256[2] memory sHashWitness;
        uint256 zInv;
        (pk, gamma, cSSeed, uWitness, cGammaWitness, sHashWitness, zInv) = abi.decode(
            proof, (uint256[2], uint256[2], uint256[3], address, uint256[2],
            uint256[2], uint256));
        verifyVRFProof(
            pk,
            gamma,
            cSSeed[0], // c
            cSSeed[1], // s
            cSSeed[2], // seed
            uWitness,
            cGammaWitness,
            sHashWitness,
            zInv
        );
        output = uint256(keccak256(abi.encode(VRF_RANDOM_OUTPUT_HASH_PREFIX, gamma)));
    }
}


// File contracts/VRFv2/interfaces/OwnableInterface.sol


pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner()
    external
    returns (
      address
    );

  function transferOwnership(
    address recipient
  )
    external;

  function acceptOwnership()
    external;
}


// File contracts/VRFv2/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {

  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor(
    address newOwner,
    address pendingOwner
  ) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(
    address to
  )
    public
    override
    onlyOwner()
  {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
    override
  {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner()
    public
    view
    override
    returns (
      address
    )
  {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(
    address to
  )
    private
  {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership()
    internal
    view
  {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }

}


// File contracts/VRFv2/ConfirmedOwner.sol


pragma solidity ^0.8.0;

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {

  constructor(
    address newOwner
  )
    ConfirmedOwnerWithProposal(
      newOwner,
      address(0)
    )
  {
  }

}


// File contracts/VRFv2/VRFConsumerBaseV2.sol

pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address immutable private vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(
    address _vrfCoordinator
  )
  {
      vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  )
    internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  )
    external
  {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}


// File contracts/VRFv2/VRFCoordinatorV2.sol


pragma solidity ^0.8.0;






contract VRFCoordinatorV2 is VRF, ConfirmedOwner, TypeAndVersionInterface {

  LinkTokenInterface public immutable LINK;
  AggregatorV3Interface public immutable LINK_ETH_FEED;
  BlockhashStoreInterface public immutable BLOCKHASH_STORE;

  // We need to maintain a list of consuming addresses.
  // This bound ensures we are able to loop over them as needed.
  // Should a user require more consumers, they can use multiple subscriptions.
  uint16 constant MAXIMUM_CONSUMERS = 100;
  error TooManyConsumers();
  error InsufficientBalance();
  error InvalidConsumer(uint64 subId, address consumer);
  error InvalidSubscription();
  error AlreadySubscribed(uint64 subId, address consumer);
  error OnlyCallableFromLink();
  error InvalidCalldata();
  error MustBeSubOwner(address owner);
  error MustBeRequestedOwner(address proposedOwner);
  error BalanceInvariantViolated(uint256 internalBalance, uint256 externalBalance); // Should never happen
  event FundsRecovered(address to, uint256 amount);
  // There are only 1e9*1e18 = 1e27 juels in existence, so the balance can fit in uint96 (2^96 ~ 7e28)
  struct Subscription {
    uint96 balance; // Common link balance used for all consumer requests.
    address owner; // Owner can fund/withdraw/cancel the sub.
    address requestedOwner; // For safe transfering sub ownership.
    // Maintains the list of keys in s_consumers.
    // We do this for 2 reasons:
    // 1. To be able to clean up all keys from s_consumers when canceling a subscription.
    // 2. To be able to return the list of all consumers in getSubscription.
    // Note that we need the s_consumers map to be able to directly check if a
    // consumer is valid without reading all the consumers from storage.
    address[] consumers;
  }
  mapping(address /* consumer */ => uint64 /* subId */) private s_consumers;
  mapping(uint64 /* subId */ => Subscription /* subscription */) private s_subscriptions;
  uint64 private s_currentSubId;
  // s_totalBalance tracks the total link sent to/from
  // this contract through onTokenTransfer, defundSubscription, cancelSubscription and oracleWithdraw.
  // A discrepancy with this contracts link balance indicates someone
  // sent tokens using transfer and so we may need to use recoverFunds.
  uint96 public s_totalBalance;
  event SubscriptionCreated(uint64 indexed subId, address owner, address[] consumers);
  event SubscriptionFunded(uint64 indexed subId, uint256 oldBalance, uint256 newBalance);
  event SubscriptionConsumerAdded(uint64 indexed subId, address consumer);
  event SubscriptionConsumerRemoved(uint64 indexed subId, address consumer);
  event SubscriptionDefunded(uint64 indexed subId, uint256 oldBalance, uint256 newBalance);
  event SubscriptionCanceled(uint64 indexed subId, address to, uint256 amount);
  event SubscriptionOwnerTransferRequested(uint64 indexed subId, address from, address to);
  event SubscriptionOwnerTransferred(uint64 indexed subId, address from, address to);

  // Set this maximum to 200 to give us a 56 block window to fulfill
  // the request before requiring the block hash feeder.
  uint16 constant MAX_REQUEST_CONFIRMATIONS = 200;
  uint256 constant private MINIMUM_GAS_LIMIT = 5_000;
  error InvalidRequestBlockConfs(uint16 have, uint16 min, uint16 max);
  error GasLimitTooBig(uint32 have, uint32 want);
  error KeyHashAlreadyRegistered(bytes32 keyHash);
  error InvalidFeedResponse(int256 linkWei);
  error InsufficientGasForConsumer(uint256 have, uint256 want);
  error InvalidProofLength(uint256 have, uint256 want);
  error NoCorrespondingRequest(uint256 preSeed);
  error IncorrectCommitment();
  error BlockhashNotInStore(uint256 blockNum);
  error PaymentTooLarge();
  // Just to relieve stack pressure
  struct FulfillmentParams {
    uint64 subId;
    uint32 callbackGasLimit;
    uint32 numWords;
    address sender;
  }
  mapping(bytes32 /* keyHash */ => address /* oracle */) private s_serviceAgreements;
  mapping(address /* oracle */ => uint96 /* LINK balance */) private s_withdrawableTokens;
  mapping(bytes32 /* keyHash */ => mapping(address /* consumer */ => uint256 /* nonce */)) private s_nonces;
  mapping(uint256 /* requestID */ => bytes32 /* commitment */) private s_commitments;
  event NewServiceAgreement(bytes32 keyHash, address indexed oracle);
  event RandomWordsRequested(
    bytes32 indexed keyHash,
    uint256 preSeedAndRequestId,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords,
    address indexed sender
  );
  event RandomWordsFulfilled(
    uint256 indexed requestId,
    uint256[] output,
    bool success
  );

  struct Config {
    uint16 minimumRequestBlockConfirmations;
    // Flat fee charged per fulfillment in millionths of link
    // So fee range is [0, 2^32/10^6].
    uint32 fulfillmentFlatFeeLinkPPM;
    uint32 maxGasLimit;
    // stalenessSeconds is how long before we consider the feed price to be stale
    // and fallback to fallbackWeiPerUnitLink.
    uint32 stalenessSeconds;
    // Gas to cover oracle payment after we calculate the payment.
    // We make it configurable in case those operations are repriced.
    uint32 gasAfterPaymentCalculation;
    uint96 minimumSubscriptionBalance;
  }
  int256 s_fallbackWeiPerUnitLink;
  Config private s_config;
  event ConfigSet(
    uint16 minimumRequestBlockConfirmations,
    uint32 fulfillmentFlatFeeLinkPPM,
    uint32 maxGasLimit,
    uint32 stalenessSeconds,
    uint32 gasAfterPaymentCalculation,
    uint96 minimumSubscriptionBalance,
    int256 fallbackWeiPerUnitLink
  );

  constructor(
    address link,
    address blockhashStore,
    address linkEthFeed
  )
    ConfirmedOwner(msg.sender)
  {
    LINK = LinkTokenInterface(link);
    LINK_ETH_FEED = AggregatorV3Interface(linkEthFeed);
    BLOCKHASH_STORE = BlockhashStoreInterface(blockhashStore);
  }

  function registerProvingKey(
    address oracle,
    uint256[2] calldata publicProvingKey
  )
    external
    onlyOwner()
  {
    bytes32 kh = hashOfKey(publicProvingKey);
    if (s_serviceAgreements[kh] != address(0)) {
      revert KeyHashAlreadyRegistered(kh);
    }
    s_serviceAgreements[kh] = oracle;
    emit NewServiceAgreement(kh, oracle);
  }

  /**
   * @notice Returns the serviceAgreements key associated with this public key
   * @param publicKey the key to return the address for
   */
  function hashOfKey(
    uint256[2] memory publicKey
  )
    public
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(publicKey));
  }

  function setConfig(
    uint16 minimumRequestBlockConfirmations,
    uint32 fulfillmentFlatFeeLinkPPM,
    uint32 maxGasLimit,
    uint32 stalenessSeconds,
    uint32 gasAfterPaymentCalculation,
    uint96 minimumSubscriptionBalance,
    int256 fallbackWeiPerUnitLink
  )
    external
    onlyOwner()
  {
    s_config = Config({
      minimumRequestBlockConfirmations: minimumRequestBlockConfirmations,
      fulfillmentFlatFeeLinkPPM: fulfillmentFlatFeeLinkPPM,
      maxGasLimit: maxGasLimit,
      stalenessSeconds: stalenessSeconds,
      gasAfterPaymentCalculation: gasAfterPaymentCalculation,
      minimumSubscriptionBalance: minimumSubscriptionBalance
    });
    s_fallbackWeiPerUnitLink = fallbackWeiPerUnitLink;
    emit ConfigSet(
      minimumRequestBlockConfirmations,
      fulfillmentFlatFeeLinkPPM,
      maxGasLimit,
      stalenessSeconds,
      gasAfterPaymentCalculation,
      minimumSubscriptionBalance,
      fallbackWeiPerUnitLink
    );
  }

  /**
   * @notice read the current configuration of the coordinator.
   */
  function getConfig()
    external
    view
    returns (
      uint16 minimumRequestBlockConfirmations,
      uint32 fulfillmentFlatFeeLinkPPM,
      uint32 maxGasLimit,
      uint32 stalenessSeconds,
      uint32 gasAfterPaymentCalculation,
      uint96 minimumSubscriptionBalance,
      int256 fallbackWeiPerUnitLink
    )
  {
    Config memory config = s_config;
    return (
      config.minimumRequestBlockConfirmations,
      config.fulfillmentFlatFeeLinkPPM,
      config.maxGasLimit,
      config.stalenessSeconds,
      config.gasAfterPaymentCalculation,
      config.minimumSubscriptionBalance,
      s_fallbackWeiPerUnitLink
    );
  }

  function recoverFunds(
    address to
  )
    external
    onlyOwner()
  {
    uint256 externalBalance = LINK.balanceOf(address(this));
    uint256 internalBalance = uint256(s_totalBalance);
    if (internalBalance > externalBalance) {
      revert BalanceInvariantViolated(internalBalance, externalBalance);
    }
    if (internalBalance < externalBalance) {
      uint256 amount = externalBalance - internalBalance;
      LINK.transfer(to, amount);
      emit FundsRecovered(to, amount);
    }
    // If the balances are equal, nothing to be done.
  }

  // Want to ensure these arguments can fit inside of 2 words
  // so in the worse case where the consuming contract has to read all of them
  // from storage, it only has to read 2 words.
  function requestRandomWords(
    bytes32 keyHash,  // Corresponds to a particular offchain job which uses that key for the proofs
    uint64  subId,
    uint16  requestConfirmations,
    uint32  callbackGasLimit,
    uint32  numWords  // Desired number of random words
  )
    external
    returns (
      uint256 requestId
    )
  {
    // Input validation using the subscription storage.
    if (s_subscriptions[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    // Its important to ensure that the consumer is in fact who they say they
    // are, otherwise they could use someone else's subscription balance.
    if (s_consumers[msg.sender] != subId) {
      revert InvalidConsumer(subId, msg.sender);
    }
    // Input validation using the config storage word.
    if (requestConfirmations < s_config.minimumRequestBlockConfirmations || requestConfirmations > MAX_REQUEST_CONFIRMATIONS) {
      revert InvalidRequestBlockConfs(requestConfirmations, s_config.minimumRequestBlockConfirmations, MAX_REQUEST_CONFIRMATIONS);
    }
    if (s_subscriptions[subId].balance < s_config.minimumSubscriptionBalance) {
      revert InsufficientBalance();
    }
    if (callbackGasLimit > s_config.maxGasLimit) {
      revert GasLimitTooBig(callbackGasLimit, s_config.maxGasLimit);
    }
    // We could additionally check s_serviceAgreements[keyHash] != address(0)
    // but that would require reading another word of storage. To save gas
    // we leave that out.
    uint256 nonce = s_nonces[keyHash][msg.sender] + 1;
    uint256 preSeedAndRequestId = uint256(keccak256(abi.encode(keyHash, msg.sender, nonce)));

    s_commitments[preSeedAndRequestId] = keccak256(abi.encodePacked(
        preSeedAndRequestId,
        block.number,
        subId,
        callbackGasLimit,
        numWords,
        msg.sender));
    emit RandomWordsRequested(keyHash, preSeedAndRequestId, subId, requestConfirmations, callbackGasLimit, numWords, msg.sender);
    s_nonces[keyHash][msg.sender] = nonce;

    return preSeedAndRequestId;
  }

  function getCommitment(
    uint256 requestId
  )
    external
    view
    returns (
      bytes32
    )
  {
    return s_commitments[requestId];
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available.
   * The maximum amount of gasAmount is all gas available but 1/64th.
   * The minimum amount of gasAmount MINIMUM_GAS_LIMIT.
   */
  function callWithExactGas(
    uint256 gasAmount,
    address target,
    bytes memory data
  )
    private
    returns (
      bool success
    )
  {
    assembly{
      let g := gas()
      // Compute g -= CUSHION and check for underflow
      if lt(g, MINIMUM_GAS_LIMIT) { revert(0, 0) }
      g := sub(g, MINIMUM_GAS_LIMIT)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) { revert(0, 0) }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) { revert(0, 0) }
      // call and return whether we succeeded. ignore return data
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  // Offsets into fulfillRandomnessRequest's proof of various values
  //
  // Public key. Skips byte array's length prefix.
  uint256 private constant PUBLIC_KEY_OFFSET = 0x20;
  // Seed is 7th word in proof, plus word for length, (6+1)*0x20=0xe0
  uint256 private constant PRESEED_OFFSET = 7*0x20;

  function fulfillRandomWords(
    bytes memory proof
  )
    external
  {
    uint256 startGas = gasleft();
    (
      bytes32 keyHash,
      uint256 requestId,
      uint256 randomness,
      FulfillmentParams memory fp
    ) = getRandomnessFromProof(proof);


    uint256[] memory randomWords = new uint256[](fp.numWords);
    for (uint256 i = 0; i < fp.numWords; i++) {
      randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
    }

    // Prevent re-entrancy. The user callback cannot call fulfillRandomWords again
    // with the same proof because this getRandomnessFromProof will revert because the requestId
    // is gone.
    delete s_commitments[requestId];
    VRFConsumerBaseV2 v;
    bytes memory resp = abi.encodeWithSelector(v.rawFulfillRandomWords.selector, requestId, randomWords);
    uint256 gasPreCallback = gasleft();
    if (gasPreCallback < fp.callbackGasLimit) {
      revert InsufficientGasForConsumer(gasPreCallback, fp.callbackGasLimit);
    }
    // Call with explicitly the amount of callback gas requested
    // Important to not let them exhaust the gas budget and avoid oracle payment.
    bool success = callWithExactGas(fp.callbackGasLimit, fp.sender, resp);
    emit RandomWordsFulfilled(requestId, randomWords, success);

    // We want to charge users exactly for how much gas they use in their callback.
    // The gasAfterPaymentCalculation is meant to cover these additional operations where we
    // decrement the subscription balance and increment the oracles withdrawable balance.
    // We also add the flat link fee to the payment amount.
    // Its specified in millionths of link, if s_config.fulfillmentFlatFeeLinkPPM = 1
    // 1 link / 1e6 = 1e18 juels / 1e6 = 1e12 juels.
    uint96 payment = calculatePaymentAmount(startGas, s_config.gasAfterPaymentCalculation, s_config.fulfillmentFlatFeeLinkPPM, tx.gasprice);
    if (s_subscriptions[fp.subId].balance < payment) {
      revert InsufficientBalance();
    }
    s_subscriptions[fp.subId].balance -= payment;
    s_withdrawableTokens[s_serviceAgreements[keyHash]] += payment;
  }

  // Get the amount of gas used for fulfillment
  function calculatePaymentAmount(
      uint256 startGas,
      uint256 gasAfterPaymentCalculation,
      uint32  fulfillmentFlatFeeLinkPPM,
      uint256 weiPerUnitGas
  )
    internal
    view
    returns (
      uint96
    )
  {
    int256 weiPerUnitLink;
    weiPerUnitLink = getFeedData();
    if (weiPerUnitLink < 0) {
      revert InvalidFeedResponse(weiPerUnitLink);
    }
    // (1e18 juels/link) (wei/gas * gas) / (wei/link) = jules
    uint256 paymentNoFee = 1e18*weiPerUnitGas*(gasAfterPaymentCalculation + startGas - gasleft()) / uint256(weiPerUnitLink);
    uint256 fee = 1e12*uint256(fulfillmentFlatFeeLinkPPM);
    if (paymentNoFee > (1e27-fee)) {
      revert PaymentTooLarge(); // Payment + fee cannot be more than all of the link in existence.
    }
    return uint96(paymentNoFee+fee);
  }

  function getRandomnessFromProof(
    bytes memory proof
  )
    private
    view 
    returns (
      bytes32 currentKeyHash,
      uint256 requestId, 
      uint256 randomness, 
      FulfillmentParams memory fp
    ) 
  {
    // blockNum follows proof, which follows length word (only direct-number
    // constants are allowed in assembly, so have to compute this in code)
    uint256 blockNumOffset = 0x20 + PROOF_LENGTH;
    // Note that proof.length skips the initial length word.
    // We expect the total length to be proof + 6 words
    // (blocknum, subId, callbackLimit, nw, sender)
    if (proof.length != PROOF_LENGTH + 0x20*5) {
      revert InvalidProofLength(proof.length, PROOF_LENGTH + 0x20*5);
    }
    uint256[2] memory publicKey;
    uint256 preSeed;
    uint256 blockNum;
    address sender;
    assembly { // solhint-disable-line no-inline-assembly
      publicKey := add(proof, PUBLIC_KEY_OFFSET)
      preSeed := mload(add(proof, PRESEED_OFFSET))
      blockNum := mload(add(proof, blockNumOffset))
      // We use a struct to limit local variables to avoid stack depth errors.
      mstore(fp, mload(add(add(proof, blockNumOffset), 0x20))) // subId
      mstore(add(fp, 0x20), mload(add(add(proof, blockNumOffset), 0x40))) // callbackGasLimit
      mstore(add(fp, 0x40), mload(add(add(proof, blockNumOffset), 0x60))) // numWords
      sender := mload(add(add(proof, blockNumOffset), 0x80))
    }
    currentKeyHash = hashOfKey(publicKey);
    bytes32 commitment = s_commitments[preSeed];
    requestId = preSeed;
    if (commitment == 0) {
      revert NoCorrespondingRequest(preSeed);
    }
    if (commitment != keccak256(abi.encodePacked(
        requestId,
        blockNum,
        fp.subId,
        fp.callbackGasLimit,
        fp.numWords,
        sender)))
    {
      revert IncorrectCommitment();
    }
    fp.sender = sender;

    bytes32 blockHash = blockhash(blockNum);
    if (blockHash == bytes32(0)) {
      blockHash = BLOCKHASH_STORE.getBlockhash(blockNum);
      if (blockHash == bytes32(0)) {
        revert BlockhashNotInStore(blockNum);
      }
    }
    // The seed actually used by the VRF machinery, mixing in the blockhash
    uint256 actualSeed = uint256(keccak256(abi.encodePacked(preSeed, blockHash)));
    // solhint-disable-next-line no-inline-assembly
    assembly { // Construct the actual proof from the remains of proof
      mstore(add(proof, PRESEED_OFFSET), actualSeed)
      mstore(proof, PROOF_LENGTH)
    }
    randomness = VRF.randomValueFromVRFProof(proof); // Reverts on failure
  }

  function getFeedData()
    private
    view
    returns (
      int256
    )
  {
    uint32 stalenessSeconds = s_config.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    int256 weiPerUnitLink;
    (,weiPerUnitLink,,timestamp,) = LINK_ETH_FEED.latestRoundData();
    if (staleFallback && stalenessSeconds < block.timestamp - timestamp) {
      weiPerUnitLink = s_fallbackWeiPerUnitLink;
    }
    return weiPerUnitLink;
  }

  function oracleWithdraw(
    address recipient,
    uint96 amount
  )
    external
  {
    if (s_withdrawableTokens[msg.sender] < amount) {
      revert InsufficientBalance();
    }
    s_withdrawableTokens[msg.sender] -= amount;
    s_totalBalance -= amount;
    if (!LINK.transfer(recipient, amount)) {
      revert InsufficientBalance();
    }
  }

  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  )
    external
  {
    if (msg.sender != address(LINK)) {
      revert OnlyCallableFromLink();
    }
    if (data.length != 32) {
      revert InvalidCalldata();
    }
    uint64 subId = abi.decode(data, (uint64));
    if (s_subscriptions[subId].owner == address(0))  {
      revert InvalidSubscription();
    }
    address owner = s_subscriptions[subId].owner;
    if (owner != sender) {
      revert MustBeSubOwner(owner);
    }
    uint256 oldBalance = s_subscriptions[subId].balance;
    s_subscriptions[subId].balance += uint96(amount);
    s_totalBalance += uint96(amount);
    emit SubscriptionFunded(subId, oldBalance, oldBalance+amount);
  }

  function getSubscription(
    uint64 subId
  )
    external
    view
    returns (
      uint96 balance,
      address owner,
      address[] memory consumers
    )
  {
    if (s_subscriptions[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    return (
      s_subscriptions[subId].balance,
      s_subscriptions[subId].owner,
      s_subscriptions[subId].consumers
    );
  }

  function createSubscription(
    address[] memory consumers // permitted consumers of the subscription
  )
    external
    returns (
      uint64
    )
  {
    if (consumers.length > MAXIMUM_CONSUMERS) {
      revert TooManyConsumers();
    }
    s_currentSubId++;
    uint64 currentSubId = s_currentSubId;
    s_subscriptions[currentSubId] = Subscription({
      balance: 0,
      owner: msg.sender,
      requestedOwner: address(0),
      consumers: consumers
    });
    for (uint256 i; i < consumers.length; i++) {
      s_consumers[consumers[i]] = currentSubId;
    }
    emit SubscriptionCreated(currentSubId, msg.sender, consumers);
    return currentSubId;
  }

  function requestSubscriptionOwnerTransfer(
    uint64 subId,
    address newOwner
  )
    external
    onlySubOwner(subId)
  {
    // Proposing to address(0) would never be claimable so don't need to check.
    if (s_subscriptions[subId].requestedOwner != newOwner) {
      s_subscriptions[subId].requestedOwner = newOwner;
      emit SubscriptionOwnerTransferRequested(subId, msg.sender, newOwner);
    }
  }

  function acceptSubscriptionOwnerTransfer(
    uint64 subId
  )
    external
  {
    if (s_subscriptions[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    if (s_subscriptions[subId].requestedOwner != msg.sender) {
      revert MustBeRequestedOwner(s_subscriptions[subId].requestedOwner);
    }
    address oldOwner = s_subscriptions[subId].owner;
    s_subscriptions[subId].owner = msg.sender;
    s_subscriptions[subId].requestedOwner = address(0);
    emit SubscriptionOwnerTransferred(subId, oldOwner, msg.sender);
  }

  function removeConsumer(
    uint64 subId,
    address consumer
  )
    external
    onlySubOwner(subId)
  {
    if (s_consumers[consumer] != subId) {
      revert InvalidConsumer(subId, consumer);
    }
    // Note bounded by MAXIMUM_CONSUMERS
    address[] memory consumers = s_subscriptions[subId].consumers;
    uint256 lastConsumerIndex = consumers.length-1;
    for (uint256 i = 0; i < consumers.length; i++) {
      if (consumers[i] == consumer) {
        address last = consumers[lastConsumerIndex];
        // Storage write removed element to the end
        s_subscriptions[subId].consumers[lastConsumerIndex] = consumers[i];
        // Storage write to preserve last element
        s_subscriptions[subId].consumers[i] = last;
        // Storage remove last element
        s_subscriptions[subId].consumers.pop();
        break;
      }
    }
    delete s_consumers[consumer];
    emit SubscriptionConsumerRemoved(subId, consumer);
  }

  function addConsumer(
    uint64 subId,
    address consumer
  )
    external
    onlySubOwner(subId)
  {
    // Already maxed, cannot add any more consumers.
    if (s_subscriptions[subId].consumers.length == MAXIMUM_CONSUMERS) {
      revert TooManyConsumers();
    }
    // Must explicitly remove a consumer before changing its subscription.
    if (s_consumers[consumer] != 0) {
      revert AlreadySubscribed(subId, consumer);
    }
    s_consumers[consumer] = subId;
    s_subscriptions[subId].consumers.push(consumer);

    emit SubscriptionConsumerAdded(subId, consumer);
  }

  function defundSubscription(
    uint64 subId,
    address to,
    uint96 amount
  )
    external
    onlySubOwner(subId)
  {
    if (s_subscriptions[subId].balance < amount) {
      revert InsufficientBalance();
    }
    uint256 oldBalance = s_subscriptions[subId].balance;
    s_subscriptions[subId].balance -= amount;
    s_totalBalance -= amount;
    if (!LINK.transfer(to, amount)) {
      revert InsufficientBalance();
    }
    emit SubscriptionDefunded(subId, oldBalance, s_subscriptions[subId].balance);
  }

  // Keep this separate from zeroing, perhaps there is a use case where consumers
  // want to keep the subId, but withdraw all the link.
  function cancelSubscription(
    uint64 subId,
    address to
  )
    external
    onlySubOwner(subId)
  {
    Subscription memory sub = s_subscriptions[subId];
    uint96 balance = sub.balance;
    // Note bounded by MAXIMUM_CONSUMERS;
    // If no consumers, does nothing.
    for (uint256 i = 0; i < sub.consumers.length; i++) {
      delete s_consumers[sub.consumers[i]];
    }
    delete s_subscriptions[subId];
    s_totalBalance -= balance;
    if (!LINK.transfer(to, uint256(balance))) {
      revert InsufficientBalance();
    }
    emit SubscriptionCanceled(subId, to, balance);
  }

  modifier onlySubOwner(uint64 subId) {
    address owner = s_subscriptions[subId].owner;
    if (owner == address(0)) {
      revert InvalidSubscription();
    }
    if (msg.sender != owner) {
      revert MustBeSubOwner(owner);
    }
    _;
  }

  /**
   * @notice The type and version of this contract
   * @return Type and version string
   */
  function typeAndVersion()
    external
    pure
    virtual
    override
    returns (
      string memory
    )
  {
    return "VRFCoordinatorV2 1.0.0";
  }
}