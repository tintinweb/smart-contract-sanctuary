/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

// File: contracts\vendor\SafeMath.sol

pragma solidity ^0.6.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}


interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}


interface BlockHashStoreInterface {
  function getBlockhash(uint256 number) external view returns (bytes32);
}


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
      p[0] = fieldHash(b);
      p[1] = squareRoot(ySquared(p[0]));
      if (p[1] % 2 == 1) {
        p[1] = FIELD_SIZE - p[1];
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
   * @return verifies true iff product==scalar*multiplicand, with cryptographically high probability
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
    address expected = address(uint256(keccak256(abi.encodePacked(product))));
    return (actual == expected);
  }

  // Returns x1/z1-x2/z2=(x1z2-x2z1)/(z1z2) in projective coordinates on P¹(𝔽ₙ)
  function projectiveSub(uint256 x1, uint256 z1, uint256 x2, uint256 z2)
    internal pure returns(uint256 x3, uint256 z3) {
      uint256 num1 = mulmod(z2, x1, FIELD_SIZE);
      uint256 num2 = mulmod(FIELD_SIZE - x2, z1, FIELD_SIZE);
      (x3, z3) = (addmod(num1, num2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
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
      // See "Group law for E/K : y^2 = x^3 + ax + b", in section 3.1.2, p. 80,
      // "Guide to Elliptic Curve Cryptography" by Hankerson, Menezes and Vanstone
      // We take the equations there for (sx,sy), and homogenize them to
      // projective coordinates. That way, no inverses are required, here, and we
      // only need the one inverse in affineECAdd.

      // We only need the "point addition" equations from Hankerson et al. Can
      // skip the "point doubling" equations because p1 == p2 is cryptographically
      // impossible, and require'd not to be the case in linearCombination.

      // Add extra "projective coordinate" to the two points
      (uint256 z1, uint256 z2) = (1, 1);

      // (lx, lz) = (qy-py)/(qx-px), i.e., gradient of secant line.
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
      require(lcWitness != address(0), "bad witness");
      uint8 v = (p[1] % 2 == 0) ? 27 : 28; // parity of y-ordinate of p
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
      require((cp1Witness[0] - sp2Witness[0]) % FIELD_SIZE != 0,
              "points in sum must be distinct");
      require(ecmulVerify(p1, c, cp1Witness), "First multiplication check failed");
      require(ecmulVerify(p2, s, sp2Witness), "Second multiplication check failed");
      return affineECAdd(cp1Witness, sp2Witness, zInv);
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
        "addr(c*pk+s*g)≠_uWitness"
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


contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}


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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerInterface, and can
 * @dev initialize VRFConsumerInterface's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness()
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls fulfillRandomness().
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMath for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it.
   *
   * @dev The VRFCoordinator expects a calling contract to have a method with
   * @dev this signature, and will trigger it once it has verified the proof
   * @dev associated with the randomness (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev See "SECURITY CONSIDERATIONS" above for more information on _seed.
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   * @param _seed seed mixed into the input of the VRF
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to *
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    public returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input
    // seed, which would result in a predictable/duplicate output.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) public nonces;
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}


/**
 * @title VRFCoordinator coordinates on-chain verifiable-randomness requests
 * @title with off-chain responses
 */
contract VRFCoordinator is VRF, VRFRequestIDBase {

  using SafeMath for uint256;

  LinkTokenInterface internal LINK;
  BlockHashStoreInterface internal blockHashStore;

  constructor(address _link, address _blockHashStore) public {
    LINK = LinkTokenInterface(_link);
    blockHashStore = BlockHashStoreInterface(_blockHashStore);
  }

  struct Callback { // Tracks an ongoing request
    address callbackContract; // Requesting contract, which will receive response
    // Amount of LINK paid at request time. Total LINK = 1e9 * 1e18 < 2^96, so
    // this representation is adequate, and saves a word of storage when this
    // field follows the 160-bit callbackContract address.
    uint96 randomnessFee;
    // Commitment to seed passed to oracle by this contract, and the number of
    // the block in which the request appeared. This is the keccak256 of the
    // concatenation of those values. Storing this commitment saves a word of
    // storage.
    bytes32 seedAndBlockNum;
  }

  struct ServiceAgreement { // Tracks oracle commitments to VRF service
    address vRFOracle; // Oracle committing to respond with VRF service
    uint96 fee; // Minimum payment for oracle response. Total LINK=1e9*1e18<2^96
    bytes32 jobID; // ID of corresponding chainlink job in oracle's DB
  }

  mapping(bytes32 /* (provingKey, seed) */ => Callback) public callbacks;
  mapping(bytes32 /* provingKey */ => ServiceAgreement)
    public serviceAgreements;
  mapping(address /* oracle */ => uint256 /* LINK balance */)
    public withdrawableTokens;
  mapping(bytes32 /* provingKey */ => mapping(address /* consumer */ => uint256))
    private nonces;

  // The oracle only needs the jobID to look up the VRF, but specifying public
  // key as well prevents a malicious oracle from inducing VRF outputs from
  // another oracle by reusing the jobID.
  event RandomnessRequest(
    bytes32 keyHash,
    uint256 seed,
    bytes32 indexed jobID,
    address sender,
    uint256 fee,
    bytes32 requestID);

  event NewServiceAgreement(bytes32 keyHash, uint256 fee);

  event RandomnessRequestFulfilled(bytes32 requestId, uint256 output);

  /**
   * @notice Commits calling address to serve randomness
   * @param _fee minimum LINK payment required to serve randomness
   * @param _oracle the address of the Chainlink node with the proving key and job
   * @param _publicProvingKey public key used to prove randomness
   * @param _jobID ID of the corresponding chainlink job in the oracle's db
   */
  function registerProvingKey(
    uint256 _fee, address _oracle, uint256[2] calldata _publicProvingKey, bytes32 _jobID
  )
    external
  {
    bytes32 keyHash = hashOfKey(_publicProvingKey);
    address oldVRFOracle = serviceAgreements[keyHash].vRFOracle;
    require(oldVRFOracle == address(0), "please register a new key");
    require(_oracle != address(0), "_oracle must not be 0x0");
    serviceAgreements[keyHash].vRFOracle = _oracle;
    serviceAgreements[keyHash].jobID = _jobID;
    // Yes, this revert message doesn't fit in a word
    require(_fee <= 1e9 ether,
      "you can't charge more than all the LINK in the world, greedy");
    serviceAgreements[keyHash].fee = uint96(_fee);
    emit NewServiceAgreement(keyHash, _fee);
  }

  /**
   * @notice Called by LINK.transferAndCall, on successful LINK transfer
   *
   * @dev To invoke this, use the requestRandomness method in VRFConsumerBase.
   *
   * @dev The VRFCoordinator will call back to the calling contract when the
   * @dev oracle responds, on the method fulfillRandomness. See
   * @dev VRFConsumerBase.fulfilRandomness for its signature. Your consuming
   * @dev contract should inherit from VRFConsumerBase, and implement
   * @dev fulfilRandomness.
   *
   * @param _sender address: who sent the LINK (must be a contract)
   * @param _fee amount of LINK sent
   * @param _data abi-encoded call to randomnessRequest
   */
  function onTokenTransfer(address _sender, uint256 _fee, bytes memory _data)
    public
    onlyLINK
  {
    (bytes32 keyHash, uint256 seed) = abi.decode(_data, (bytes32, uint256));
    randomnessRequest(keyHash, seed, _fee, _sender);
  }

  /**
   * @notice creates the chainlink request for randomness
   *
   * @param _keyHash ID of the VRF public key against which to generate output
   * @param _consumerSeed Input to the VRF, from which randomness is generated
   * @param _feePaid Amount of LINK sent with request. Must exceed fee for key
   * @param _sender Requesting contract; to be called back with VRF output
   *
   * @dev _consumerSeed is mixed with key hash, sender address and nonce to
   * @dev obtain preSeed, which is passed to VRF oracle, which mixes it with the
   * @dev hash of the block containing this request, to compute the final seed.
   *
   * @dev The requestId used to store the request data is constructed from the
   * @dev preSeed and keyHash.
   */
  function randomnessRequest(
    bytes32 _keyHash,
    uint256 _consumerSeed,
    uint256 _feePaid,
    address _sender
  )
    internal
    sufficientLINK(_feePaid, _keyHash)
  {
    uint256 nonce = nonces[_keyHash][_sender];
    uint256 preSeed = makeVRFInputSeed(_keyHash, _consumerSeed, _sender, nonce);
    bytes32 requestId = makeRequestId(_keyHash, preSeed);
    // Cryptographically guaranteed by preSeed including an increasing nonce
    assert(callbacks[requestId].callbackContract == address(0));
    callbacks[requestId].callbackContract = _sender;
    assert(_feePaid < 1e27); // Total LINK fits in uint96
    callbacks[requestId].randomnessFee = uint96(_feePaid);
    callbacks[requestId].seedAndBlockNum = keccak256(abi.encodePacked(
      preSeed, block.number));
    emit RandomnessRequest(_keyHash, preSeed, serviceAgreements[_keyHash].jobID,
      _sender, _feePaid, requestId);
    nonces[_keyHash][_sender] = nonces[_keyHash][_sender].add(1);
  }

  // Offsets into fulfillRandomnessRequest's _proof of various values
  //
  // Public key. Skips byte array's length prefix.
  uint256 public constant PUBLIC_KEY_OFFSET = 0x20;
  // Seed is 7th word in proof, plus word for length, (6+1)*0x20=0xe0
  uint256 public constant PRESEED_OFFSET = 0xe0;

  /**
   * @notice Called by the chainlink node to fulfill requests
   *
   * @param _proof the proof of randomness. Actual random output built from this
   *
   * @dev The structure of _proof corresponds to vrf.MarshaledOnChainResponse,
   * @dev in the node source code. I.e., it is a vrf.MarshaledProof with the
   * @dev seed replaced by the preSeed, followed by the hash of the requesting
   * @dev block.
   */
  function fulfillRandomnessRequest(bytes memory _proof) public {
    (bytes32 currentKeyHash, Callback memory callback, bytes32 requestId,
     uint256 randomness) = getRandomnessFromProof(_proof);

    // Pay oracle
    address oadd = serviceAgreements[currentKeyHash].vRFOracle;
    withdrawableTokens[oadd] = withdrawableTokens[oadd].add(
      callback.randomnessFee);

    // Forget request. Must precede callback (prevents reentrancy)
    delete callbacks[requestId];
    callBackWithRandomness(requestId, randomness, callback.callbackContract);

    emit RandomnessRequestFulfilled(requestId, randomness);
  }

  function callBackWithRandomness(bytes32 requestId, uint256 randomness,
    address consumerContract) internal {
    // Dummy variable; allows access to method selector in next line. See
    // https://github.com/ethereum/solidity/issues/3506#issuecomment-553727797
    VRFConsumerBase v;
    bytes memory resp = abi.encodeWithSelector(
      v.rawFulfillRandomness.selector, requestId, randomness);
    // The bound b here comes from https://eips.ethereum.org/EIPS/eip-150. The
    // actual gas available to the consuming contract will be b-floor(b/64).
    // This is chosen to leave the consuming contract ~200k gas, after the cost
    // of the call itself.
    uint256 b = 206000;
    require(gasleft() >= b, "not enough gas for consumer");
    // A low-level call is necessary, here, because we don't want the consuming
    // contract to be able to revert this execution, and thus deny the oracle
    // payment for a valid randomness response. This also necessitates the above
    // check on the gasleft, as otherwise there would be no indication if the
    // callback method ran out of gas.
    //
    // solhint-disable-next-line avoid-low-level-calls
    (bool success,) = consumerContract.call(resp);
    // Avoid unused-local-variable warning. (success is only present to prevent
    // a warning that the return value of consumerContract.call is unused.)
    (success);
  }

  function getRandomnessFromProof(bytes memory _proof)
    internal view returns (bytes32 currentKeyHash, Callback memory callback,
      bytes32 requestId, uint256 randomness) {
    // blockNum follows proof, which follows length word (only direct-number
    // constants are allowed in assembly, so have to compute this in code)
    uint256 BLOCKNUM_OFFSET = 0x20 + PROOF_LENGTH;
    // _proof.length skips the initial length word, so not including the
    // blocknum in this length check balances out.
    require(_proof.length == BLOCKNUM_OFFSET, "wrong proof length");
    uint256[2] memory publicKey;
    uint256 preSeed;
    uint256 blockNum;
    assembly { // solhint-disable-line no-inline-assembly
      publicKey := add(_proof, PUBLIC_KEY_OFFSET)
      preSeed := mload(add(_proof, PRESEED_OFFSET))
      blockNum := mload(add(_proof, BLOCKNUM_OFFSET))
    }
    currentKeyHash = hashOfKey(publicKey);
    requestId = makeRequestId(currentKeyHash, preSeed);
    callback = callbacks[requestId];
    require(callback.callbackContract != address(0), "no corresponding request");
    require(callback.seedAndBlockNum == keccak256(abi.encodePacked(preSeed,
      blockNum)), "wrong preSeed or block num");

    bytes32 blockHash = blockhash(blockNum);
    if (blockHash == bytes32(0)) {
      blockHash = blockHashStore.getBlockhash(blockNum);
      require(blockHash != bytes32(0), "please prove blockhash");
    }
    // The seed actually used by the VRF machinery, mixing in the blockhash
    uint256 actualSeed = uint256(keccak256(abi.encodePacked(preSeed, blockHash)));
    // solhint-disable-next-line no-inline-assembly
    assembly { // Construct the actual proof from the remains of _proof
      mstore(add(_proof, PRESEED_OFFSET), actualSeed)
      mstore(_proof, PROOF_LENGTH)
    }
    randomness = VRF.randomValueFromVRFProof(_proof); // Reverts on failure
  }

  /**
   * @dev Allows the oracle operator to withdraw their LINK
   * @param _recipient is the address the funds will be sent to
   * @param _amount is the amount of LINK transferred from the Coordinator contract
   */
  function withdraw(address _recipient, uint256 _amount)
    external
    hasAvailableFunds(_amount)
  {
    withdrawableTokens[msg.sender] = withdrawableTokens[msg.sender].sub(_amount);
    assert(LINK.transfer(_recipient, _amount));
  }

  /**
   * @notice Returns the serviceAgreements key associated with this public key
   * @param _publicKey the key to return the address for
   */
  function hashOfKey(uint256[2] memory _publicKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_publicKey));
  }

  /**
   * @dev Reverts if amount is not at least what was agreed upon in the service agreement
   * @param _feePaid The payment for the request
   * @param _keyHash The key which the request is for
   */
  modifier sufficientLINK(uint256 _feePaid, bytes32 _keyHash) {
    require(_feePaid >= serviceAgreements[_keyHash].fee, "Below agreed payment");
    _;
  }

/**
   * @dev Reverts if not sent from the LINK token
   */
  modifier onlyLINK() {
    require(msg.sender == address(LINK), "Must use LINK token");
    _;
  }

  /**
   * @dev Reverts if amount requested is greater than withdrawable balance
   * @param _amount The given amount to compare to `withdrawableTokens`
   */
  modifier hasAvailableFunds(uint256 _amount) {
    require(withdrawableTokens[msg.sender] >= _amount, "can't withdraw more than balance");
    _;
  }

}