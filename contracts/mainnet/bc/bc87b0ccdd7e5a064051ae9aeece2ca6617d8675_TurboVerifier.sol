// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Bn254Crypto} from './cryptography/Bn254Crypto.sol';
import {PolynomialEval} from './cryptography/PolynomialEval.sol';
import {Types} from './cryptography/Types.sol';
import {VerificationKeys} from './keys/VerificationKeys.sol';
import {Transcript} from './cryptography/Transcript.sol';
import {IVerifier} from '../interfaces/IVerifier.sol';

/**
 * @title Turbo Plonk proof verification contract
 * @dev Top level Plonk proof verification contract, which allows Plonk proof to be verified
 *
 * Copyright 2020 Spilsbury Holdings Ltd
 *
 * Licensed under the GNU General Public License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
contract TurboVerifier is IVerifier {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;
    using Transcript for Transcript.TranscriptData;

    /**
     * @dev Verify a Plonk proof
     * @param - array of serialized proof data
     * @param rollup_size - number of transactions in the rollup
     */
    function verify(bytes calldata, uint256 rollup_size) external override {
        // extract the correct rollup verification key
        Types.VerificationKey memory vk = VerificationKeys.getKeyById(rollup_size);
        uint256 num_public_inputs = vk.num_inputs;

        // parse the input calldata and construct a Proof object
        Types.Proof memory decoded_proof = deserialize_proof(num_public_inputs, vk);

        Transcript.TranscriptData memory transcript;
        transcript.generate_initial_challenge(vk.circuit_size, vk.num_inputs);

        // reconstruct the beta, gamma, alpha and zeta challenges
        Types.ChallengeTranscript memory challenges;
        transcript.generate_beta_gamma_challenges(challenges, vk.num_inputs);
        transcript.generate_alpha_challenge(challenges, decoded_proof.Z);
        transcript.generate_zeta_challenge(challenges, decoded_proof.T1, decoded_proof.T2, decoded_proof.T3, decoded_proof.T4);

        /**
         * Compute all inverses that will be needed throughout the program here.
         *
         * This is an efficiency improvement - it allows us to make use of the batch inversion Montgomery trick,
         * which allows all inversions to be replaced with one inversion operation, at the expense of a few
         * additional multiplications
         **/
        (uint256 quotient_eval, uint256 L1) = evalaute_field_operations(decoded_proof, vk, challenges);
        decoded_proof.quotient_polynomial_eval = quotient_eval;

        // reconstruct the nu and u challenges
        transcript.generate_nu_challenges(challenges, decoded_proof.quotient_polynomial_eval, vk.num_inputs);
        transcript.generate_separator_challenge(challenges, decoded_proof.PI_Z, decoded_proof.PI_Z_OMEGA);

        //reset 'alpha base'
        challenges.alpha_base = challenges.alpha;

        Types.G1Point memory linearised_contribution = PolynomialEval.compute_linearised_opening_terms(
            challenges,
            L1,
            vk,
            decoded_proof
        );

        Types.G1Point memory batch_opening_commitment = PolynomialEval.compute_batch_opening_commitment(
            challenges,
            vk,
            linearised_contribution,
            decoded_proof
        );

        uint256 batch_evaluation_g1_scalar = PolynomialEval.compute_batch_evaluation_scalar_multiplier(
            decoded_proof,
            challenges
        );

        bool result = perform_pairing(
            batch_opening_commitment,
            batch_evaluation_g1_scalar,
            challenges,
            decoded_proof,
            vk
        );
        require(result, 'Proof failed');
    }


    /**
     * @dev Compute partial state of the verifier, specifically: public input delta evaluation, zero polynomial
     * evaluation, the lagrange evaluations and the quotient polynomial evaluations
     *
     * Note: This uses the batch inversion Montgomery trick to reduce the number of
     * inversions, and therefore the number of calls to the bn128 modular exponentiation
     * precompile.
     *
     * Specifically, each function call: compute_public_input_delta() etc. at some point needs to invert a
     * value to calculate a denominator in a fraction. Instead of performing this inversion as it is needed, we
     * instead 'save up' the denominator calculations. The inputs to this are returned from the various functions
     * and then we perform all necessary inversions in one go at the end of `evalaute_field_operations()`. This
     * gives us the various variables that need to be returned.
     *
     * @param decoded_proof - deserialised proof
     * @param vk - verification key
     * @param challenges - all challenges (alpha, beta, gamma, zeta, nu[NUM_NU_CHALLENGES], u) stored in
     * ChallengeTranscript struct form
     * @return quotient polynomial evaluation (field element) and lagrange 1 evaluation (field element)
     */
    function evalaute_field_operations(
        Types.Proof memory decoded_proof,
        Types.VerificationKey memory vk,
        Types.ChallengeTranscript memory challenges
    ) internal view returns (uint256, uint256) {
        uint256 public_input_delta;
        uint256 zero_polynomial_eval;
        uint256 l_start;
        uint256 l_end;
        {
            (uint256 public_input_numerator, uint256 public_input_denominator) = PolynomialEval.compute_public_input_delta(
                challenges,
                vk
            );

            (
                uint256 vanishing_numerator,
                uint256 vanishing_denominator,
                uint256 lagrange_numerator,
                uint256 l_start_denominator,
                uint256 l_end_denominator
            ) = PolynomialEval.compute_lagrange_and_vanishing_fractions(vk, challenges.zeta);


            (zero_polynomial_eval, public_input_delta, l_start, l_end) = PolynomialEval.compute_batch_inversions(
                public_input_numerator,
                public_input_denominator,
                vanishing_numerator,
                vanishing_denominator,
                lagrange_numerator,
                l_start_denominator,
                l_end_denominator
            );
        }

        uint256 quotient_eval = PolynomialEval.compute_quotient_polynomial(
            zero_polynomial_eval,
            public_input_delta,
            challenges,
            l_start,
            l_end,
            decoded_proof
        );

        return (quotient_eval, l_start);
    }


    /**
     * @dev Perform the pairing check
     * @param batch_opening_commitment - G1 point representing the calculated batch opening commitment
     * @param batch_evaluation_g1_scalar - uint256 representing the batch evaluation scalar multiplier to be applied to the G1 generator point
     * @param challenges - all challenges (alpha, beta, gamma, zeta, nu[NUM_NU_CHALLENGES], u) stored in
     * ChallengeTranscript struct form
     * @param vk - verification key
     * @param decoded_proof - deserialised proof
     * @return bool specifying whether the pairing check was successful
     */
    function perform_pairing(
        Types.G1Point memory batch_opening_commitment,
        uint256 batch_evaluation_g1_scalar,
        Types.ChallengeTranscript memory challenges,
        Types.Proof memory decoded_proof,
        Types.VerificationKey memory vk
    ) internal view returns (bool) {

        uint256 u = challenges.u;
        bool success;
        uint256 p = Bn254Crypto.r_mod;
        Types.G1Point memory rhs;     
        Types.G1Point memory PI_Z_OMEGA = decoded_proof.PI_Z_OMEGA;
        Types.G1Point memory PI_Z = decoded_proof.PI_Z;
        PI_Z.validateG1Point();
        PI_Z_OMEGA.validateG1Point();
    
        // rhs = zeta.[PI_Z] + u.zeta.omega.[PI_Z_OMEGA] + [batch_opening_commitment] - batch_evaluation_g1_scalar.[1]
        // scope this block to prevent stack depth errors
        {
            uint256 zeta = challenges.zeta;
            uint256 pi_z_omega_scalar = vk.work_root;
            assembly {
                pi_z_omega_scalar := mulmod(pi_z_omega_scalar, zeta, p)
                pi_z_omega_scalar := mulmod(pi_z_omega_scalar, u, p)
                batch_evaluation_g1_scalar := sub(p, batch_evaluation_g1_scalar)

                // store accumulator point at mptr
                let mPtr := mload(0x40)

                // set accumulator = batch_opening_commitment
                mstore(mPtr, mload(batch_opening_commitment))
                mstore(add(mPtr, 0x20), mload(add(batch_opening_commitment, 0x20)))

                // compute zeta.[PI_Z] and add into accumulator
                mstore(add(mPtr, 0x40), mload(PI_Z))
                mstore(add(mPtr, 0x60), mload(add(PI_Z, 0x20)))
                mstore(add(mPtr, 0x80), zeta)
                success := staticcall(gas(), 7, add(mPtr, 0x40), 0x60, add(mPtr, 0x40), 0x40)
                success := and(success, staticcall(gas(), 6, mPtr, 0x80, mPtr, 0x40))

                // compute u.zeta.omega.[PI_Z_OMEGA] and add into accumulator
                mstore(add(mPtr, 0x40), mload(PI_Z_OMEGA))
                mstore(add(mPtr, 0x60), mload(add(PI_Z_OMEGA, 0x20)))
                mstore(add(mPtr, 0x80), pi_z_omega_scalar)
                success := and(success, staticcall(gas(), 7, add(mPtr, 0x40), 0x60, add(mPtr, 0x40), 0x40))
                success := and(success, staticcall(gas(), 6, mPtr, 0x80, mPtr, 0x40))

                // compute -batch_evaluation_g1_scalar.[1]
                mstore(add(mPtr, 0x40), 0x01) // hardcoded generator point (1, 2)
                mstore(add(mPtr, 0x60), 0x02)
                mstore(add(mPtr, 0x80), batch_evaluation_g1_scalar)
                success := and(success, staticcall(gas(), 7, add(mPtr, 0x40), 0x60, add(mPtr, 0x40), 0x40))

                // add -batch_evaluation_g1_scalar.[1] and the accumulator point, write result into rhs
                success := and(success, staticcall(gas(), 6, mPtr, 0x80, rhs, 0x40))
            }
        }

        Types.G1Point memory lhs;   
        assembly {
            // store accumulator point at mptr
            let mPtr := mload(0x40)

            // copy [PI_Z] into mPtr
            mstore(mPtr, mload(PI_Z))
            mstore(add(mPtr, 0x20), mload(add(PI_Z, 0x20)))

            // compute u.[PI_Z_OMEGA] and write to (mPtr + 0x40)
            mstore(add(mPtr, 0x40), mload(PI_Z_OMEGA))
            mstore(add(mPtr, 0x60), mload(add(PI_Z_OMEGA, 0x20)))
            mstore(add(mPtr, 0x80), u)
            success := and(success, staticcall(gas(), 7, add(mPtr, 0x40), 0x60, add(mPtr, 0x40), 0x40))
            
            // add [PI_Z] + u.[PI_Z_OMEGA] and write result into lhs
            success := and(success, staticcall(gas(), 6, mPtr, 0x80, lhs, 0x40))
        }

        // negate lhs y-coordinate
        uint256 q = Bn254Crypto.p_mod;
        assembly {
            mstore(add(lhs, 0x20), sub(q, mload(add(lhs, 0x20))))
        }

        if (vk.contains_recursive_proof)
        {
            // If the proof itself contains an accumulated proof,
            // we will have extracted two G1 elements `recursive_P1`, `recursive_p2` from the public inputs

            // We need to evaluate that e(recursive_P1, [x]_2) == e(recursive_P2, [1]_2) to finish verifying the inner proof
            // We do this by creating a random linear combination between (lhs, recursive_P1) and (rhs, recursivee_P2)
            // That way we still only need to evaluate one pairing product

            // We use `challenge.u * challenge.u` as the randomness to create a linear combination
            // challenge.u is produced by hashing the entire transcript, which contains the public inputs (and by extension the recursive proof)

            // i.e. [lhs] = [lhs] + u.u.[recursive_P1]
            //      [rhs] = [rhs] + u.u.[recursive_P2]
            Types.G1Point memory recursive_P1 = decoded_proof.recursive_P1;
            Types.G1Point memory recursive_P2 = decoded_proof.recursive_P2;
            recursive_P1.validateG1Point();
            recursive_P2.validateG1Point();
            assembly {
                let mPtr := mload(0x40)

                // compute u.u.[recursive_P1]
                mstore(mPtr, mload(recursive_P1))
                mstore(add(mPtr, 0x20), mload(add(recursive_P1, 0x20)))
                mstore(add(mPtr, 0x40), mulmod(u, u, p)) // separator_challenge = u * u
                success := and(success, staticcall(gas(), 7, mPtr, 0x60, add(mPtr, 0x60), 0x40))

                // compute u.u.[recursive_P2] (u*u is still in memory at (mPtr + 0x40), no need to re-write it)
                mstore(mPtr, mload(recursive_P2))
                mstore(add(mPtr, 0x20), mload(add(recursive_P2, 0x20)))
                success := and(success, staticcall(gas(), 7, mPtr, 0x60, mPtr, 0x40))

                // compute u.u.[recursiveP2] + rhs and write into rhs
                mstore(add(mPtr, 0xa0), mload(rhs))
                mstore(add(mPtr, 0xc0), mload(add(rhs, 0x20)))
                success := and(success, staticcall(gas(), 6, add(mPtr, 0x60), 0x80, rhs, 0x40))

                // compute u.u.[recursiveP1] + lhs and write into lhs
                mstore(add(mPtr, 0x40), mload(lhs))
                mstore(add(mPtr, 0x60), mload(add(lhs, 0x20)))
                success := and(success, staticcall(gas(), 6, mPtr, 0x80, lhs, 0x40))
            }
        }

        require(success, "perform_pairing G1 operations preamble fail");

        return Bn254Crypto.pairingProd2(rhs, Bn254Crypto.P2(), lhs, vk.g2_x);
    }

    /**
     * @dev Deserialize a proof into a Proof struct
     * @param num_public_inputs - number of public inputs in the proof. Taken from verification key
     * @return proof - proof deserialized into the proof struct
     */
    function deserialize_proof(uint256 num_public_inputs, Types.VerificationKey memory vk)
        internal
        pure
        returns (Types.Proof memory proof)
    {
        uint256 p = Bn254Crypto.r_mod;
        uint256 q = Bn254Crypto.p_mod;
        uint256 data_ptr;
        uint256 proof_ptr;
        // first 32 bytes of bytes array contains length, skip it
        assembly {
            data_ptr := add(calldataload(0x04), 0x24)
            proof_ptr := proof
        }

        if (vk.contains_recursive_proof) {
            uint256 index_counter = vk.recursive_proof_indices * 32;
            uint256 x0 = 0;
            uint256 y0 = 0;
            uint256 x1 = 0;
            uint256 y1 = 0;
            assembly {
                index_counter := add(index_counter, data_ptr)
                x0 := calldataload(index_counter)
                x0 := add(x0, shl(68, calldataload(add(index_counter, 0x20))))
                x0 := add(x0, shl(136, calldataload(add(index_counter, 0x40))))
                x0 := add(x0, shl(204, calldataload(add(index_counter, 0x60))))
                y0 := calldataload(add(index_counter, 0x80))
                y0 := add(y0, shl(68, calldataload(add(index_counter, 0xa0))))
                y0 := add(y0, shl(136, calldataload(add(index_counter, 0xc0))))
                y0 := add(y0, shl(204, calldataload(add(index_counter, 0xe0))))
                x1 := calldataload(add(index_counter, 0x100))
                x1 := add(x1, shl(68, calldataload(add(index_counter, 0x120))))
                x1 := add(x1, shl(136, calldataload(add(index_counter, 0x140))))
                x1 := add(x1, shl(204, calldataload(add(index_counter, 0x160))))
                y1 := calldataload(add(index_counter, 0x180))
                y1 := add(y1, shl(68, calldataload(add(index_counter, 0x1a0))))
                y1 := add(y1, shl(136, calldataload(add(index_counter, 0x1c0))))
                y1 := add(y1, shl(204, calldataload(add(index_counter, 0x1e0))))
            }

            proof.recursive_P1 = Bn254Crypto.new_g1(x0, y0);
            proof.recursive_P2 = Bn254Crypto.new_g1(x1, y1);
        }

        assembly {
            let public_input_byte_length := mul(num_public_inputs, 0x20)
            data_ptr := add(data_ptr, public_input_byte_length)
  
            // proof.W1
            mstore(mload(proof_ptr), mod(calldataload(add(data_ptr, 0x20)), q))
            mstore(add(mload(proof_ptr), 0x20), mod(calldataload(data_ptr), q))

            // proof.W2
            mstore(mload(add(proof_ptr, 0x20)), mod(calldataload(add(data_ptr, 0x60)), q))
            mstore(add(mload(add(proof_ptr, 0x20)), 0x20), mod(calldataload(add(data_ptr, 0x40)), q))
 
            // proof.W3
            mstore(mload(add(proof_ptr, 0x40)), mod(calldataload(add(data_ptr, 0xa0)), q))
            mstore(add(mload(add(proof_ptr, 0x40)), 0x20), mod(calldataload(add(data_ptr, 0x80)), q))

            // proof.W4
            mstore(mload(add(proof_ptr, 0x60)), mod(calldataload(add(data_ptr, 0xe0)), q))
            mstore(add(mload(add(proof_ptr, 0x60)), 0x20), mod(calldataload(add(data_ptr, 0xc0)), q))
  
            // proof.Z
            mstore(mload(add(proof_ptr, 0x80)), mod(calldataload(add(data_ptr, 0x120)), q))
            mstore(add(mload(add(proof_ptr, 0x80)), 0x20), mod(calldataload(add(data_ptr, 0x100)), q))
  
            // proof.T1
            mstore(mload(add(proof_ptr, 0xa0)), mod(calldataload(add(data_ptr, 0x160)), q))
            mstore(add(mload(add(proof_ptr, 0xa0)), 0x20), mod(calldataload(add(data_ptr, 0x140)), q))

            // proof.T2
            mstore(mload(add(proof_ptr, 0xc0)), mod(calldataload(add(data_ptr, 0x1a0)), q))
            mstore(add(mload(add(proof_ptr, 0xc0)), 0x20), mod(calldataload(add(data_ptr, 0x180)), q))

            // proof.T3
            mstore(mload(add(proof_ptr, 0xe0)), mod(calldataload(add(data_ptr, 0x1e0)), q))
            mstore(add(mload(add(proof_ptr, 0xe0)), 0x20), mod(calldataload(add(data_ptr, 0x1c0)), q))

            // proof.T4
            mstore(mload(add(proof_ptr, 0x100)), mod(calldataload(add(data_ptr, 0x220)), q))
            mstore(add(mload(add(proof_ptr, 0x100)), 0x20), mod(calldataload(add(data_ptr, 0x200)), q))
  
            // proof.w1 to proof.w4
            mstore(add(proof_ptr, 0x120), mod(calldataload(add(data_ptr, 0x240)), p))
            mstore(add(proof_ptr, 0x140), mod(calldataload(add(data_ptr, 0x260)), p))
            mstore(add(proof_ptr, 0x160), mod(calldataload(add(data_ptr, 0x280)), p))
            mstore(add(proof_ptr, 0x180), mod(calldataload(add(data_ptr, 0x2a0)), p))
 
            // proof.sigma1
            mstore(add(proof_ptr, 0x1a0), mod(calldataload(add(data_ptr, 0x2c0)), p))

            // proof.sigma2
            mstore(add(proof_ptr, 0x1c0), mod(calldataload(add(data_ptr, 0x2e0)), p))

            // proof.sigma3
            mstore(add(proof_ptr, 0x1e0), mod(calldataload(add(data_ptr, 0x300)), p))

            // proof.q_arith
            mstore(add(proof_ptr, 0x200), mod(calldataload(add(data_ptr, 0x320)), p))

            // proof.q_ecc
            mstore(add(proof_ptr, 0x220), mod(calldataload(add(data_ptr, 0x340)), p))

            // proof.q_c
            mstore(add(proof_ptr, 0x240), mod(calldataload(add(data_ptr, 0x360)), p))
 
            // proof.linearization_polynomial
            mstore(add(proof_ptr, 0x260), mod(calldataload(add(data_ptr, 0x380)), p))

            // proof.grand_product_at_z_omega
            mstore(add(proof_ptr, 0x280), mod(calldataload(add(data_ptr, 0x3a0)), p))

            // proof.w1_omega to proof.w4_omega
            mstore(add(proof_ptr, 0x2a0), mod(calldataload(add(data_ptr, 0x3c0)), p))
            mstore(add(proof_ptr, 0x2c0), mod(calldataload(add(data_ptr, 0x3e0)), p))
            mstore(add(proof_ptr, 0x2e0), mod(calldataload(add(data_ptr, 0x400)), p))
            mstore(add(proof_ptr, 0x300), mod(calldataload(add(data_ptr, 0x420)), p))
  
            // proof.PI_Z
            mstore(mload(add(proof_ptr, 0x320)), mod(calldataload(add(data_ptr, 0x460)), q))
            mstore(add(mload(add(proof_ptr, 0x320)), 0x20), mod(calldataload(add(data_ptr, 0x440)), q))

            // proof.PI_Z_OMEGA
            mstore(mload(add(proof_ptr, 0x340)), mod(calldataload(add(data_ptr, 0x4a0)), q))
            mstore(add(mload(add(proof_ptr, 0x340)), 0x20), mod(calldataload(add(data_ptr, 0x480)), q))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from "./Types.sol";

/**
 * @title Bn254 elliptic curve crypto
 * @dev Provides some basic methods to compute bilinear pairings, construct group elements and misc numerical methods
 */
library Bn254Crypto {
    uint256 constant p_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // Perform a modular exponentiation. This method is ideal for small exponents (~64 bits or less), as
    // it is cheaper than using the pow precompile
    function pow_small(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) internal pure returns (uint256) {
        uint256 result = 1;
        uint256 input = base;
        uint256 count = 1;

        assembly {
            let endpoint := add(exponent, 0x01)
            for {} lt(count, endpoint) { count := add(count, count) }
            {
                if and(exponent, count) {
                    result := mulmod(result, input, modulus)
                }
                input := mulmod(input, input, modulus)
            }
        }

        return result;
    }

    function invert(uint256 fr) internal view returns (uint256)
    {
        uint256 output;
        bool success;
        uint256 p = r_mod;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, 0x20)
            mstore(add(mPtr, 0x20), 0x20)
            mstore(add(mPtr, 0x40), 0x20)
            mstore(add(mPtr, 0x60), fr)
            mstore(add(mPtr, 0x80), sub(p, 2))
            mstore(add(mPtr, 0xa0), p)
            success := staticcall(gas(), 0x05, mPtr, 0xc0, 0x00, 0x20)
            output := mload(0x00)
        }
        require(success, "pow precompile call failed!");
        return output;
    }

    function new_g1(uint256 x, uint256 y)
        internal
        pure
        returns (Types.G1Point memory)
    {
        uint256 xValue;
        uint256 yValue;
        assembly {
            xValue := mod(x, r_mod)
            yValue := mod(y, r_mod)
        }
        return Types.G1Point(xValue, yValue);
    }

    function new_g2(uint256 x0, uint256 x1, uint256 y0, uint256 y1)
        internal
        pure
        returns (Types.G2Point memory)
    {
        return Types.G2Point(x0, x1, y0, y1);
    }

    function P1() internal pure returns (Types.G1Point memory) {
        return Types.G1Point(1, 2);
    }

    function P2() internal pure returns (Types.G2Point memory) {
        return Types.G2Point({
            x0: 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
            x1: 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed,
            y0: 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
            y1: 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
        });
    }


    /// Evaluate the following pairing product:
    /// e(a1, a2).e(-b1, b2) == 1
    function pairingProd2(
        Types.G1Point memory a1,
        Types.G2Point memory a2,
        Types.G1Point memory b1,
        Types.G2Point memory b2
    ) internal view returns (bool) {
        validateG1Point(a1);
        validateG1Point(b1);
        bool success;
        uint256 out;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, mload(a1))
            mstore(add(mPtr, 0x20), mload(add(a1, 0x20)))
            mstore(add(mPtr, 0x40), mload(a2))
            mstore(add(mPtr, 0x60), mload(add(a2, 0x20)))
            mstore(add(mPtr, 0x80), mload(add(a2, 0x40)))
            mstore(add(mPtr, 0xa0), mload(add(a2, 0x60)))

            mstore(add(mPtr, 0xc0), mload(b1))
            mstore(add(mPtr, 0xe0), mload(add(b1, 0x20)))
            mstore(add(mPtr, 0x100), mload(b2))
            mstore(add(mPtr, 0x120), mload(add(b2, 0x20)))
            mstore(add(mPtr, 0x140), mload(add(b2, 0x40)))
            mstore(add(mPtr, 0x160), mload(add(b2, 0x60)))
            success := staticcall(
                gas(),
                8,
                mPtr,
                0x180,
                0x00,
                0x20
            )
            out := mload(0x00)
        }
        require(success, "Pairing check failed!");
        return (out != 0);
    }

    /**
    * validate the following:
    *   x != 0
    *   y != 0
    *   x < p
    *   y < p
    *   y^2 = x^3 + 3 mod p
    */
    function validateG1Point(Types.G1Point memory point) internal pure {
        bool is_well_formed;
        uint256 p = p_mod;
        assembly {
            let x := mload(point)
            let y := mload(add(point, 0x20))

            is_well_formed := and(
                and(
                    and(lt(x, p), lt(y, p)),
                    not(or(iszero(x), iszero(y)))
                ),
                eq(mulmod(y, y, p), addmod(mulmod(x, mulmod(x, x, p), p), 3, p))
            )
        }
        require(is_well_formed, "Bn254: G1 point not on curve, or is malformed");
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Bn254Crypto} from './Bn254Crypto.sol';
import {Types} from './Types.sol';

/**
 * @title Turbo Plonk polynomial evaluation
 * @dev Implementation of Turbo Plonk's polynomial evaluation algorithms
 *
 * Expected to be inherited by `TurboPlonk.sol`
 *
 * Copyright 2020 Spilsbury Holdings Ltd
 *
 * Licensed under the GNU General Public License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
library PolynomialEval {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    /**
     * @dev Use batch inversion (so called Montgomery's trick). Circuit size is the domain
     * Allows multiple inversions to be performed in one inversion, at the expense of additional multiplications
     *
     * Returns a struct containing the inverted elements
     */
    function compute_batch_inversions(
        uint256 public_input_delta_numerator,
        uint256 public_input_delta_denominator,
        uint256 vanishing_numerator,
        uint256 vanishing_denominator,
        uint256 lagrange_numerator,
        uint256 l_start_denominator,
        uint256 l_end_denominator
    )
        internal
        view
        returns (
            uint256 zero_polynomial_eval,
            uint256 public_input_delta,
            uint256 l_start,
            uint256 l_end
        )
    {
        uint256 mPtr;
        uint256 p = Bn254Crypto.r_mod;
        uint256 accumulator = 1;
        assembly {
            mPtr := mload(0x40)
            mstore(0x40, add(mPtr, 0x200))
        }
    
        // store denominators in mPtr -> mPtr + 0x80
        assembly {
            mstore(mPtr, public_input_delta_denominator) // store denominator
            mstore(add(mPtr, 0x20), vanishing_numerator) // store numerator, because we want the inverse of the zero poly
            mstore(add(mPtr, 0x40), l_start_denominator) // store denominator
            mstore(add(mPtr, 0x60), l_end_denominator) // store denominator

            // store temporary product terms at mPtr + 0x80 -> mPtr + 0x100
            mstore(add(mPtr, 0x80), accumulator)
            accumulator := mulmod(accumulator, mload(mPtr), p)
            mstore(add(mPtr, 0xa0), accumulator)
            accumulator := mulmod(accumulator, mload(add(mPtr, 0x20)), p)
            mstore(add(mPtr, 0xc0), accumulator)
            accumulator := mulmod(accumulator, mload(add(mPtr, 0x40)), p)
            mstore(add(mPtr, 0xe0), accumulator)
            accumulator := mulmod(accumulator, mload(add(mPtr, 0x60)), p)
        }

        accumulator = Bn254Crypto.invert(accumulator);
        assembly {
            let intermediate := mulmod(accumulator, mload(add(mPtr, 0xe0)), p)
            accumulator := mulmod(accumulator, mload(add(mPtr, 0x60)), p)
            mstore(add(mPtr, 0x60), intermediate)

            intermediate := mulmod(accumulator, mload(add(mPtr, 0xc0)), p)
            accumulator := mulmod(accumulator, mload(add(mPtr, 0x40)), p)
            mstore(add(mPtr, 0x40), intermediate)

            intermediate := mulmod(accumulator, mload(add(mPtr, 0xa0)), p)
            accumulator := mulmod(accumulator, mload(add(mPtr, 0x20)), p)
            mstore(add(mPtr, 0x20), intermediate)

            intermediate := mulmod(accumulator, mload(add(mPtr, 0x80)), p)
            accumulator := mulmod(accumulator, mload(mPtr), p)
            mstore(mPtr, intermediate)

            public_input_delta := mulmod(public_input_delta_numerator, mload(mPtr), p)

            zero_polynomial_eval := mulmod(vanishing_denominator, mload(add(mPtr, 0x20)), p)
    
            l_start := mulmod(lagrange_numerator, mload(add(mPtr, 0x40)), p)

            l_end := mulmod(lagrange_numerator, mload(add(mPtr, 0x60)), p)
        }
    }

    function compute_public_input_delta(
        Types.ChallengeTranscript memory challenges,
        Types.VerificationKey memory vk
    ) internal pure returns (uint256, uint256) {
        uint256 gamma = challenges.gamma;
        uint256 work_root = vk.work_root;

        uint256 endpoint = (vk.num_inputs * 0x20) - 0x20;
        uint256 public_inputs;
        uint256 root_1 = challenges.beta;
        uint256 root_2 = challenges.beta;
        uint256 numerator_value = 1;
        uint256 denominator_value = 1;

        // we multiply length by 0x20 because our loop step size is 0x20 not 0x01
        // we subtract 0x20 because our loop is unrolled 2 times an we don't want to overshoot

        // perform this computation in assembly to improve efficiency. We are sensitive to the cost of this loop as
        // it scales with the number of public inputs
        uint256 p = Bn254Crypto.r_mod;
        bool valid = true;
        assembly {
            root_1 := mulmod(root_1, 0x05, p)
            root_2 := mulmod(root_2, 0x07, p)
            public_inputs := add(calldataload(0x04), 0x24)

            // get public inputs from calldata. N.B. If Contract ABI Changes this code will need to be updated!
            endpoint := add(endpoint, public_inputs)
            // Do some loop unrolling to reduce number of conditional jump operations
            for {} lt(public_inputs, endpoint) {}
            {
                let input0 := calldataload(public_inputs)
                let N0 := add(root_1, add(input0, gamma))
                let D0 := add(root_2, N0) // 4x overloaded

                root_1 := mulmod(root_1, work_root, p)
                root_2 := mulmod(root_2, work_root, p)

                let input1 := calldataload(add(public_inputs, 0x20))
                let N1 := add(root_1, add(input1, gamma))

                denominator_value := mulmod(mulmod(D0, denominator_value, p), add(N1, root_2), p)
                numerator_value := mulmod(mulmod(N1, N0, p), numerator_value, p)

                root_1 := mulmod(root_1, work_root, p)
                root_2 := mulmod(root_2, work_root, p)

                valid := and(valid, and(lt(input0, p), lt(input1, p)))
                public_inputs := add(public_inputs, 0x40)
            }

            endpoint := add(endpoint, 0x20)
            for {} lt(public_inputs, endpoint) { public_inputs := add(public_inputs, 0x20) }
            {
                let input0 := calldataload(public_inputs)
                valid := and(valid, lt(input0, p))
                let T0 := addmod(input0, gamma, p)
                numerator_value := mulmod(
                    numerator_value,
                    add(root_1, T0), // 0x05 = coset_generator0
                    p
                )
                denominator_value := mulmod(
                    denominator_value,
                    add(add(root_1, root_2), T0), // 0x0c = coset_generator7
                    p
                )
                root_1 := mulmod(root_1, work_root, p)
                root_2 := mulmod(root_2, work_root, p)
            }
        }
        require(valid, "public inputs are greater than circuit modulus");
        return (numerator_value, denominator_value);
    }

    /**
     * @dev Computes the vanishing polynoimal and lagrange evaluations L1 and Ln.
     * @return Returns fractions as numerators and denominators. We combine with the public input fraction and compute inverses as a batch
     */
    function compute_lagrange_and_vanishing_fractions(Types.VerificationKey memory vk, uint256 zeta
    ) internal pure returns (uint256, uint256, uint256, uint256, uint256) {

        uint256 p = Bn254Crypto.r_mod;
        uint256 vanishing_numerator = Bn254Crypto.pow_small(zeta, vk.circuit_size, p);
        vk.zeta_pow_n = vanishing_numerator;
        assembly {
            vanishing_numerator := addmod(vanishing_numerator, sub(p, 1), p)
        }

        uint256 accumulating_root = vk.work_root_inverse;
        uint256 work_root = vk.work_root_inverse;
        uint256 vanishing_denominator;
        uint256 domain_inverse = vk.domain_inverse;
        uint256 l_start_denominator;
        uint256 l_end_denominator;
        uint256 z = zeta; // copy input var to prevent stack depth errors
        assembly {

            // vanishing_denominator = (z - w^{n-1})(z - w^{n-2})(z - w^{n-3})(z - w^{n-4})
            // we need to cut 4 roots of unity out of the vanishing poly, the last 4 constraints are not satisfied due to randomness
            // added to ensure the proving system is zero-knowledge
            vanishing_denominator := addmod(z, sub(p, work_root), p)
            work_root := mulmod(work_root, accumulating_root, p)
            vanishing_denominator := mulmod(vanishing_denominator, addmod(z, sub(p, work_root), p), p)
            work_root := mulmod(work_root, accumulating_root, p)
            vanishing_denominator := mulmod(vanishing_denominator, addmod(z, sub(p, work_root), p), p)
            work_root := mulmod(work_root, accumulating_root, p)
            vanishing_denominator := mulmod(vanishing_denominator, addmod(z, sub(p, work_root), p), p)
        }
        
        work_root = vk.work_root;
        uint256 lagrange_numerator;
        assembly {
            lagrange_numerator := mulmod(vanishing_numerator, domain_inverse, p)
            // l_start_denominator = z - 1
            // l_end_denominator = z * \omega^5 - 1
            l_start_denominator := addmod(z, sub(p, 1), p)

            accumulating_root := mulmod(work_root, work_root, p)
            accumulating_root := mulmod(accumulating_root, accumulating_root, p)
            accumulating_root := mulmod(accumulating_root, work_root, p)

            l_end_denominator := addmod(mulmod(accumulating_root, z, p), sub(p, 1), p)
        }

        return (vanishing_numerator, vanishing_denominator, lagrange_numerator, l_start_denominator, l_end_denominator);
    }

    function compute_arithmetic_gate_quotient_contribution(
        Types.ChallengeTranscript memory challenges,
        Types.Proof memory proof
    ) internal pure returns (uint256) {

        uint256 q_arith = proof.q_arith;
        uint256 wire3 = proof.w3;
        uint256 wire4 = proof.w4;
        uint256 alpha_base = challenges.alpha_base;
        uint256 alpha = challenges.alpha;
        uint256 t1;
        uint256 p = Bn254Crypto.r_mod;
        assembly {
            t1 := addmod(mulmod(q_arith, q_arith, p), sub(p, q_arith), p)

            let t2 := addmod(sub(p, mulmod(wire4, 0x04, p)), wire3, p)

            let t3 := mulmod(mulmod(t2, t2, p), 0x02, p)

            let t4 := mulmod(t2, 0x09, p)
            t4 := addmod(t4, addmod(sub(p, t3), sub(p, 0x07), p), p)

            t2 := mulmod(t2, t4, p)

            t1 := mulmod(mulmod(t1, t2, p), alpha_base, p)


            alpha_base := mulmod(alpha_base, alpha, p)
            alpha_base := mulmod(alpha_base, alpha, p)
        }

        challenges.alpha_base = alpha_base;

        return t1;
    }

    function compute_pedersen_gate_quotient_contribution(
        Types.ChallengeTranscript memory challenges,
        Types.Proof memory proof
    ) internal pure returns (uint256) {


        uint256 alpha = challenges.alpha;
        uint256 gate_id = 0;
        uint256 alpha_base = challenges.alpha_base;

        {
            uint256 p = Bn254Crypto.r_mod;
            uint256 delta = 0;

            uint256 wire_t0 = proof.w4; // w4
            uint256 wire_t1 = proof.w4_omega; // w4_omega
            uint256 wire_t2 = proof.w3_omega; // w3_omega
            assembly {
                let wire4_neg := sub(p, wire_t0)
                delta := addmod(wire_t1, mulmod(wire4_neg, 0x04, p), p)

                gate_id :=
                mulmod(
                    mulmod(
                        mulmod(
                            mulmod(
                                add(delta, 0x01),
                                add(delta, 0x03),
                                p
                            ),
                            add(delta, sub(p, 0x01)),
                            p
                        ),
                        add(delta, sub(p, 0x03)),
                        p
                    ),
                    alpha_base,
                    p
                )
                alpha_base := mulmod(alpha_base, alpha, p)
        
                gate_id := addmod(gate_id, sub(p, mulmod(wire_t2, alpha_base, p)), p)

                alpha_base := mulmod(alpha_base, alpha, p)
            }

            uint256 selector_value = proof.q_ecc;

            wire_t0 = proof.w1; // w1
            wire_t1 = proof.w1_omega; // w1_omega
            wire_t2 = proof.w2; // w2
            uint256 wire_t3 = proof.w3_omega; // w3_omega
            uint256 t0;
            uint256 t1;
            uint256 t2;
            assembly {
                t0 := addmod(wire_t1, addmod(wire_t0, wire_t3, p), p)

                t1 := addmod(wire_t3, sub(p, wire_t0), p)
                t1 := mulmod(t1, t1, p)

                t0 := mulmod(t0, t1, p)

                t1 := mulmod(wire_t3, mulmod(wire_t3, wire_t3, p), p)

                t2 := mulmod(wire_t2, wire_t2, p)

                t1 := sub(p, addmod(addmod(t1, t2, p), sub(p, 17), p))

                t2 := mulmod(mulmod(delta, wire_t2, p), selector_value, p)
                t2 := addmod(t2, t2, p)

                t0 := 
                    mulmod(
                        addmod(t0, addmod(t1, t2, p), p),
                        alpha_base,
                        p
                    )
                gate_id := addmod(gate_id, t0, p)

                alpha_base := mulmod(alpha_base, alpha, p)
            }

            wire_t0 = proof.w1; // w1
            wire_t1 = proof.w2_omega; // w2_omega
            wire_t2 = proof.w2; // w2
            wire_t3 = proof.w3_omega; // w3_omega
            uint256 wire_t4 = proof.w1_omega; // w1_omega
            assembly {
                t0 := mulmod(
                    addmod(wire_t1, wire_t2, p),
                    addmod(wire_t3, sub(p, wire_t0), p),
                    p
                )

                t1 := addmod(wire_t0, sub(p, wire_t4), p)

                t2 := addmod(
                        sub(p, mulmod(selector_value, delta, p)),
                        wire_t2,
                        p
                )

                gate_id := addmod(gate_id, mulmod(add(t0, mulmod(t1, t2, p)), alpha_base, p), p)

                alpha_base := mulmod(alpha_base, alpha, p)
            }

            selector_value = proof.q_c;
        
            wire_t1 = proof.w4; // w4
            wire_t2 = proof.w3; // w3
            assembly {
                let acc_init_id := addmod(wire_t1, sub(p, 0x01), p)

                t1 := addmod(acc_init_id, sub(p, wire_t2), p)

                acc_init_id := mulmod(acc_init_id, mulmod(t1, alpha_base, p), p)
                acc_init_id := mulmod(acc_init_id, selector_value, p)

                gate_id := addmod(gate_id, acc_init_id, p)

                alpha_base := mulmod(alpha_base, alpha, p)
            }
        
            assembly {
                let x_init_id := sub(p, mulmod(mulmod(wire_t0, selector_value, p), mulmod(wire_t2, alpha_base, p), p))

                gate_id := addmod(gate_id, x_init_id, p)

                alpha_base := mulmod(alpha_base, alpha, p)
            }

            wire_t0 = proof.w2; // w2
            wire_t1 = proof.w3; // w3
            wire_t2 = proof.w4; // w4
            assembly {
                let y_init_id := mulmod(add(0x01, sub(p, wire_t2)), selector_value, p)

                t1 := sub(p, mulmod(wire_t0, wire_t1, p))

                y_init_id := mulmod(add(y_init_id, t1), mulmod(alpha_base, selector_value, p), p)

                gate_id := addmod(gate_id, y_init_id, p)

                alpha_base := mulmod(alpha_base, alpha, p)

            }
            selector_value = proof.q_ecc;
            assembly {
                gate_id := mulmod(gate_id, selector_value, p)
            }
        }
        challenges.alpha_base = alpha_base;
        return gate_id;
    }

    function compute_permutation_quotient_contribution(
        uint256 public_input_delta,
        Types.ChallengeTranscript memory challenges,
        uint256 lagrange_start,
        uint256 lagrange_end,
        Types.Proof memory proof
    ) internal pure returns (uint256) {

        uint256 numerator_collector;
        uint256 alpha = challenges.alpha;
        uint256 beta = challenges.beta;
        uint256 p = Bn254Crypto.r_mod;
        uint256 grand_product = proof.grand_product_at_z_omega;
        {
            uint256 gamma = challenges.gamma;
            uint256 wire1 = proof.w1;
            uint256 wire2 = proof.w2;
            uint256 wire3 = proof.w3;
            uint256 wire4 = proof.w4;
            uint256 sigma1 = proof.sigma1;
            uint256 sigma2 = proof.sigma2;
            uint256 sigma3 = proof.sigma3;
            assembly {

                let t0 := add(
                    add(wire1, gamma),
                    mulmod(beta, sigma1, p)
                )

                let t1 := add(
                    add(wire2, gamma),
                    mulmod(beta, sigma2, p)
                )

                let t2 := add(
                    add(wire3, gamma),
                    mulmod(beta, sigma3, p)
                )

                t0 := mulmod(t0, mulmod(t1, t2, p), p)

                t0 := mulmod(
                    t0,
                    add(wire4, gamma),
                    p
                )

                t0 := mulmod(
                    t0,
                    grand_product,
                    p
                )

                t0 := mulmod(
                    t0,
                    alpha,
                    p
                )

                numerator_collector := sub(p, t0)
            }
        }


        uint256 alpha_base = challenges.alpha_base;
        {
            uint256 lstart = lagrange_start;
            uint256 lend = lagrange_end;
            uint256 public_delta = public_input_delta;
            uint256 linearization_poly = proof.linearization_polynomial;
            assembly {
                let alpha_squared := mulmod(alpha, alpha, p)
                let alpha_cubed := mulmod(alpha, alpha_squared, p)

                let t0 := mulmod(lstart, alpha_cubed, p)
                let t1 := mulmod(lend, alpha_squared, p)
                let t2 := addmod(grand_product, sub(p, public_delta), p)
                t1 := mulmod(t1, t2, p)

                numerator_collector := addmod(numerator_collector, sub(p, t0), p)
                numerator_collector := addmod(numerator_collector, t1, p)
                numerator_collector := addmod(numerator_collector, linearization_poly, p)
                alpha_base := mulmod(alpha_base, alpha_cubed, p)
            }
        }

        challenges.alpha_base = alpha_base;

        return numerator_collector;
    }

    function compute_quotient_polynomial(
        uint256 zero_poly_inverse,
        uint256 public_input_delta,
        Types.ChallengeTranscript memory challenges,
        uint256 lagrange_start,
        uint256 lagrange_end,
        Types.Proof memory proof
    ) internal pure returns (uint256) {
        uint256 t0 = compute_permutation_quotient_contribution(
            public_input_delta,
            challenges,
            lagrange_start,
            lagrange_end,
            proof
        );

        uint256 t1 = compute_arithmetic_gate_quotient_contribution(challenges, proof);

        uint256 t2 = compute_pedersen_gate_quotient_contribution(challenges, proof);

        uint256 quotient_eval;
        uint256 p = Bn254Crypto.r_mod;
        assembly {
            quotient_eval := addmod(t0, addmod(t1, t2, p), p)
            quotient_eval := mulmod(quotient_eval, zero_poly_inverse, p)
        }
        return quotient_eval;
    }

    function compute_linearised_opening_terms(
        Types.ChallengeTranscript memory challenges,
        uint256 L1_fr,
        Types.VerificationKey memory vk,
        Types.Proof memory proof
    ) internal view returns (Types.G1Point memory) {
        Types.G1Point memory accumulator = compute_grand_product_opening_group_element(proof, vk, challenges, L1_fr);
        Types.G1Point memory arithmetic_term = compute_arithmetic_selector_opening_group_element(proof, vk, challenges);
        uint256 range_multiplier = compute_range_gate_opening_scalar(proof, challenges);
        uint256 logic_multiplier = compute_logic_gate_opening_scalar(proof, challenges);

        Types.G1Point memory QRANGE = vk.QRANGE;
        Types.G1Point memory QLOGIC = vk.QLOGIC;
        QRANGE.validateG1Point();
        QLOGIC.validateG1Point();

        // compute range_multiplier.[QRANGE] + logic_multiplier.[QLOGIC] + [accumulator] + [grand_product_term]
        bool success;
        assembly {
            let mPtr := mload(0x40)

            // range_multiplier.[QRANGE]
            mstore(mPtr, mload(QRANGE))
            mstore(add(mPtr, 0x20), mload(add(QRANGE, 0x20)))
            mstore(add(mPtr, 0x40), range_multiplier)
            success := staticcall(gas(), 7, mPtr, 0x60, mPtr, 0x40)

            // add scalar mul output into accumulator
            // we use mPtr to store accumulated point
            mstore(add(mPtr, 0x40), mload(accumulator))
            mstore(add(mPtr, 0x60), mload(add(accumulator, 0x20)))
            success := and(success, staticcall(gas(), 6, mPtr, 0x80, mPtr, 0x40))

            // logic_multiplier.[QLOGIC]
            mstore(add(mPtr, 0x40), mload(QLOGIC))
            mstore(add(mPtr, 0x60), mload(add(QLOGIC, 0x20)))
            mstore(add(mPtr, 0x80), logic_multiplier)
            success := and(success, staticcall(gas(), 7, add(mPtr, 0x40), 0x60, add(mPtr, 0x40), 0x40))

            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, mPtr, 0x80, mPtr, 0x40))

            // add arithmetic into accumulator
            mstore(add(mPtr, 0x40), mload(arithmetic_term))
            mstore(add(mPtr, 0x60), mload(add(arithmetic_term, 0x20)))
            success := and(success, staticcall(gas(), 6, mPtr, 0x80, accumulator, 0x40))
        }
        require(success, "compute_linearised_opening_terms group operations fail");
    
        return accumulator;
    }

    function compute_batch_opening_commitment(
        Types.ChallengeTranscript memory challenges,
        Types.VerificationKey memory vk,
        Types.G1Point memory partial_opening_commitment,
        Types.Proof memory proof
    ) internal view returns (Types.G1Point memory) {
        // Computes the Kate opening proof group operations, for commitments that are not linearised
        bool success;
        // Reserve 0xa0 bytes of memory to perform group operations
        uint256 accumulator_ptr;
        uint256 p = Bn254Crypto.r_mod;
        assembly {
            accumulator_ptr := mload(0x40)
            mstore(0x40, add(accumulator_ptr, 0xa0))
        }

        // first term
        Types.G1Point memory work_point = proof.T1;
        work_point.validateG1Point();
        assembly {
            mstore(accumulator_ptr, mload(work_point))
            mstore(add(accumulator_ptr, 0x20), mload(add(work_point, 0x20)))
        }

        // second term
        uint256 scalar_multiplier = vk.zeta_pow_n; // zeta_pow_n is computed in compute_lagrange_and_vanishing_fractions
        uint256 zeta_n = scalar_multiplier;
        work_point = proof.T2;
        work_point.validateG1Point();
        assembly {
            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute zeta_n.[T2]
            success := staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40)
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        // third term
        work_point = proof.T3;
        work_point.validateG1Point();
        assembly {
            scalar_multiplier := mulmod(scalar_multiplier, scalar_multiplier, p)

            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute zeta_n^2.[T3]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))

        }

        // fourth term
        work_point = proof.T4;
        work_point.validateG1Point();
        assembly {
            scalar_multiplier := mulmod(scalar_multiplier, zeta_n, p)

            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute zeta_n^3.[T4]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        // fifth term
        work_point = partial_opening_commitment;
        work_point.validateG1Point();
        assembly {            
            // add partial opening commitment into accumulator
            mstore(add(accumulator_ptr, 0x40), mload(partial_opening_commitment))
            mstore(add(accumulator_ptr, 0x60), mload(add(partial_opening_commitment, 0x20)))
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        uint256 u_plus_one = challenges.u;
        uint256 v_challenge = challenges.v0;

        // W1
        work_point = proof.W1;
        work_point.validateG1Point();
        assembly {
            u_plus_one := addmod(u_plus_one, 0x01, p)

            scalar_multiplier := mulmod(v_challenge, u_plus_one, p)

            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute v0(u + 1).[W1]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        // W2
        v_challenge = challenges.v1;
        work_point = proof.W2;
        work_point.validateG1Point();
        assembly {
            scalar_multiplier := mulmod(v_challenge, u_plus_one, p)

            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute v1(u + 1).[W2]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        // W3
        v_challenge = challenges.v2;
        work_point = proof.W3;
        work_point.validateG1Point();
        assembly {
            scalar_multiplier := mulmod(v_challenge, u_plus_one, p)

            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute v2(u + 1).[W3]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }


        // W4
        v_challenge = challenges.v3;
        work_point = proof.W4;
        work_point.validateG1Point();
        assembly {
            scalar_multiplier := mulmod(v_challenge, u_plus_one, p)

            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute v3(u + 1).[W4]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        // SIGMA1
        scalar_multiplier = challenges.v4;
        work_point = vk.SIGMA1;
        work_point.validateG1Point();
        assembly {
            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute v4.[SIGMA1]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        // SIGMA2
        scalar_multiplier = challenges.v5;
        work_point = vk.SIGMA2;
        work_point.validateG1Point();
        assembly {
            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute v5.[SIGMA2]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        // SIGMA3
        scalar_multiplier = challenges.v6;
        work_point = vk.SIGMA3;
        work_point.validateG1Point();
        assembly {
            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute v6.[SIGMA3]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        // QARITH
        scalar_multiplier = challenges.v7;
        work_point = vk.QARITH;
        work_point.validateG1Point();
        assembly {
            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute v7.[QARITH]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into accumulator
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
        }

        Types.G1Point memory output;
        // QECC
        scalar_multiplier = challenges.v8;
        work_point = vk.QECC;
        work_point.validateG1Point();
        assembly {
            mstore(add(accumulator_ptr, 0x40), mload(work_point))
            mstore(add(accumulator_ptr, 0x60), mload(add(work_point, 0x20)))
            mstore(add(accumulator_ptr, 0x80), scalar_multiplier)

            // compute v8.[QECC]
            success := and(success, staticcall(gas(), 7, add(accumulator_ptr, 0x40), 0x60, add(accumulator_ptr, 0x40), 0x40))
            
            // add scalar mul output into output point
            success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, output, 0x40))
        }
        
        require(success, "compute_batch_opening_commitment group operations error");

        return output;
    }

    function compute_batch_evaluation_scalar_multiplier(Types.Proof memory proof, Types.ChallengeTranscript memory challenges)
        internal
        pure
        returns (uint256)
    {
        uint256 p = Bn254Crypto.r_mod;
        uint256 opening_scalar;
        uint256 lhs;
        uint256 rhs;

        lhs = challenges.v0;
        rhs = proof.w1;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v1;
        rhs = proof.w2;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v2;
        rhs = proof.w3;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v3;
        rhs = proof.w4;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v4;
        rhs = proof.sigma1;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v5;
        rhs = proof.sigma2;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v6;
        rhs = proof.sigma3;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v7;
        rhs = proof.q_arith;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v8;
        rhs = proof.q_ecc;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v9;
        rhs = proof.q_c;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }
    
        lhs = challenges.v10;
        rhs = proof.linearization_polynomial;
        assembly {
            opening_scalar := addmod(opening_scalar, mulmod(lhs, rhs, p), p)
        }
    
        lhs = proof.quotient_polynomial_eval;
        assembly {
            opening_scalar := addmod(opening_scalar, lhs, p)
        }

        lhs = challenges.v0;
        rhs = proof.w1_omega;
        uint256 shifted_opening_scalar;
        assembly {
            shifted_opening_scalar := mulmod(lhs, rhs, p)
        }
    
        lhs = challenges.v1;
        rhs = proof.w2_omega;
        assembly {
            shifted_opening_scalar := addmod(shifted_opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v2;
        rhs = proof.w3_omega;
        assembly {
            shifted_opening_scalar := addmod(shifted_opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = challenges.v3;
        rhs = proof.w4_omega;
        assembly {
            shifted_opening_scalar := addmod(shifted_opening_scalar, mulmod(lhs, rhs, p), p)
        }

        lhs = proof.grand_product_at_z_omega;
        assembly {
            shifted_opening_scalar := addmod(shifted_opening_scalar, lhs, p)
        }

        lhs = challenges.u;
        assembly {
            shifted_opening_scalar := mulmod(shifted_opening_scalar, lhs, p)

            opening_scalar := addmod(opening_scalar, shifted_opening_scalar, p)
        }

        return opening_scalar;
    }

    // Compute kate opening scalar for arithmetic gate selectors and pedersen gate selectors
    // (both the arithmetic gate and pedersen hash gate reuse the same selectors)
    function compute_arithmetic_selector_opening_group_element(
        Types.Proof memory proof,
        Types.VerificationKey memory vk,
        Types.ChallengeTranscript memory challenges
    ) internal view returns (Types.G1Point memory) {

        uint256 q_arith = proof.q_arith;
        uint256 q_ecc = proof.q_ecc;
        uint256 linear_challenge = challenges.v10;
        uint256 alpha_base = challenges.alpha_base;
        uint256 scaling_alpha = challenges.alpha_base;
        uint256 alpha = challenges.alpha;
        uint256 p = Bn254Crypto.r_mod;
        uint256 scalar_multiplier;
        uint256 accumulator_ptr; // reserve 0xa0 bytes of memory to multiply and add points
        assembly {
            accumulator_ptr := mload(0x40)
            mstore(0x40, add(accumulator_ptr, 0xa0))
        }
        {
            uint256 delta;
            // Q1 Selector
            {
                {
                    uint256 w4 = proof.w4;
                    uint256 w4_omega = proof.w4_omega;
                    assembly {
                        delta := addmod(w4_omega, sub(p, mulmod(w4, 0x04, p)), p)
                    }
                }
                uint256 w1 = proof.w1;

                assembly {
                    scalar_multiplier := mulmod(w1, linear_challenge, p)
                    scalar_multiplier := mulmod(scalar_multiplier, alpha_base, p)
                    scalar_multiplier := mulmod(scalar_multiplier, q_arith, p)

                    scaling_alpha := mulmod(scaling_alpha, alpha, p)
                    scaling_alpha := mulmod(scaling_alpha, alpha, p)
                    scaling_alpha := mulmod(scaling_alpha, alpha, p)
                    let t0 := mulmod(delta, delta, p)
                    t0 := mulmod(t0, q_ecc, p)
                    t0 := mulmod(t0, scaling_alpha, p)

                    scalar_multiplier := addmod(scalar_multiplier, mulmod(t0, linear_challenge, p), p)
                }
                Types.G1Point memory Q1 = vk.Q1;
                Q1.validateG1Point();
                bool success;
                assembly {
                    let mPtr := mload(0x40)
                    mstore(mPtr, mload(Q1))
                    mstore(add(mPtr, 0x20), mload(add(Q1, 0x20)))
                    mstore(add(mPtr, 0x40), scalar_multiplier)
                    success := staticcall(gas(), 7, mPtr, 0x60, accumulator_ptr, 0x40)
                }
                require(success, "G1 point multiplication failed!");
            }

            // Q2 Selector
            {
                uint256 w2 = proof.w2;
                assembly {
                    scalar_multiplier := mulmod(w2, linear_challenge, p)
                    scalar_multiplier := mulmod(scalar_multiplier, alpha_base, p)
                    scalar_multiplier := mulmod(scalar_multiplier, q_arith, p)

                    let t0 := mulmod(scaling_alpha, q_ecc, p)
                    scalar_multiplier := addmod(scalar_multiplier, mulmod(t0, linear_challenge, p), p)
                }

                Types.G1Point memory Q2 = vk.Q2;
                Q2.validateG1Point();
                bool success;
                assembly {
                    let mPtr := mload(0x40)
                    mstore(mPtr, mload(Q2))
                    mstore(add(mPtr, 0x20), mload(add(Q2, 0x20)))
                    mstore(add(mPtr, 0x40), scalar_multiplier)

                    // write scalar mul output 0x40 bytes ahead of accumulator
                    success := staticcall(gas(), 7, mPtr, 0x60, add(accumulator_ptr, 0x40), 0x40)

                    // add scalar mul output into accumulator
                    success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
                }
                require(success, "G1 point multiplication failed!");
            }

            // Q3 Selector
            {
                {
                    uint256 w3 = proof.w3;
                    assembly {
                        scalar_multiplier := mulmod(w3, linear_challenge, p)
                        scalar_multiplier := mulmod(scalar_multiplier, alpha_base, p)
                        scalar_multiplier := mulmod(scalar_multiplier, q_arith, p)
                    }
                }
                {
                    uint256 t1;
                    {
                        uint256 w3_omega = proof.w3_omega;
                        assembly {
                            t1 := mulmod(delta, w3_omega, p)
                        }
                    }
                    {
                        uint256 w2 = proof.w2;
                        assembly {
                            scaling_alpha := mulmod(scaling_alpha, alpha, p)

                            t1 := mulmod(t1, w2, p)
                            t1 := mulmod(t1, scaling_alpha, p)
                            t1 := addmod(t1, t1, p)
                            t1 := mulmod(t1, q_ecc, p)

                        scalar_multiplier := addmod(scalar_multiplier, mulmod(t1, linear_challenge, p), p)
                        }
                    }
                }
                uint256 t0 = proof.w1_omega;
                {
                    uint256 w1 = proof.w1;
                    assembly {
                        scaling_alpha := mulmod(scaling_alpha, alpha, p)
                        t0 := addmod(t0, sub(p, w1), p)
                        t0 := mulmod(t0, delta, p)
                    }
                }
                uint256 w3_omega = proof.w3_omega;
                assembly {

                    t0 := mulmod(t0, w3_omega, p)
                    t0 := mulmod(t0, scaling_alpha, p)

                    t0 := mulmod(t0, q_ecc, p)

                    scalar_multiplier := addmod(scalar_multiplier, mulmod(t0, linear_challenge, p), p)
                }
            }

            Types.G1Point memory Q3 = vk.Q3;
            Q3.validateG1Point();
            bool success;
            assembly {
                let mPtr := mload(0x40)
                mstore(mPtr, mload(Q3))
                mstore(add(mPtr, 0x20), mload(add(Q3, 0x20)))
                mstore(add(mPtr, 0x40), scalar_multiplier)

                // write scalar mul output 0x40 bytes ahead of accumulator
                success := staticcall(gas(), 7, mPtr, 0x60, add(accumulator_ptr, 0x40), 0x40)

                // add scalar mul output into accumulator
                success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
            }
            require(success, "G1 point multiplication failed!");
        }

        // Q4 Selector
        {
            uint256 w3 = proof.w3;
            uint256 w4 = proof.w4;
            uint256 q_c = proof.q_c;
            assembly {
                scalar_multiplier := mulmod(w4, linear_challenge, p)
                scalar_multiplier := mulmod(scalar_multiplier, alpha_base, p)
                scalar_multiplier := mulmod(scalar_multiplier, q_arith, p)

                scaling_alpha := mulmod(scaling_alpha, mulmod(alpha, alpha, p), p)
                let t0 := mulmod(w3, q_ecc, p)
                t0 := mulmod(t0, q_c, p)
                t0 := mulmod(t0, scaling_alpha, p)

                scalar_multiplier := addmod(scalar_multiplier, mulmod(t0, linear_challenge, p), p)
            }

            Types.G1Point memory Q4 = vk.Q4;
            Q4.validateG1Point();
            bool success;
            assembly {
                let mPtr := mload(0x40)
                mstore(mPtr, mload(Q4))
                mstore(add(mPtr, 0x20), mload(add(Q4, 0x20)))
                mstore(add(mPtr, 0x40), scalar_multiplier)

                // write scalar mul output 0x40 bytes ahead of accumulator
                success := staticcall(gas(), 7, mPtr, 0x60, add(accumulator_ptr, 0x40), 0x40)

                // add scalar mul output into accumulator
                success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
            }
            require(success, "G1 point multiplication failed!");
        }

        // Q5 Selector
        {
            uint256 w4 = proof.w4;
            uint256 q_c = proof.q_c;
            assembly {
                let neg_w4 := sub(p, w4)
                scalar_multiplier := mulmod(w4, w4, p)
                scalar_multiplier := addmod(scalar_multiplier, neg_w4, p)
                scalar_multiplier := mulmod(scalar_multiplier, addmod(w4, sub(p, 2), p), p)
                scalar_multiplier := mulmod(scalar_multiplier, alpha_base, p)
                scalar_multiplier := mulmod(scalar_multiplier, alpha, p)
                scalar_multiplier := mulmod(scalar_multiplier, q_arith, p)
                scalar_multiplier := mulmod(scalar_multiplier, linear_challenge, p)

                let t0 := addmod(0x01, neg_w4, p)
                t0 := mulmod(t0, q_ecc, p)
                t0 := mulmod(t0, q_c, p)
                t0 := mulmod(t0, scaling_alpha, p)

                scalar_multiplier := addmod(scalar_multiplier, mulmod(t0, linear_challenge, p), p)
            }

            Types.G1Point memory Q5 = vk.Q5;
            Q5.validateG1Point();
            bool success;
            assembly {
                let mPtr := mload(0x40)
                mstore(mPtr, mload(Q5))
                mstore(add(mPtr, 0x20), mload(add(Q5, 0x20)))
                mstore(add(mPtr, 0x40), scalar_multiplier)

                // write scalar mul output 0x40 bytes ahead of accumulator
                success := staticcall(gas(), 7, mPtr, 0x60, add(accumulator_ptr, 0x40), 0x40)

                // add scalar mul output into accumulator
                success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
            }
            require(success, "G1 point multiplication failed!");
        }
    
        // QM Selector
        {
            {
                uint256 w1 = proof.w1;
                uint256 w2 = proof.w2;

                assembly {
                    scalar_multiplier := mulmod(w1, w2, p)
                    scalar_multiplier := mulmod(scalar_multiplier, linear_challenge, p)
                    scalar_multiplier := mulmod(scalar_multiplier, alpha_base, p)
                    scalar_multiplier := mulmod(scalar_multiplier, q_arith, p)
                }
            }
            uint256 w3 = proof.w3;
            uint256 q_c = proof.q_c;
            assembly {

                scaling_alpha := mulmod(scaling_alpha, alpha, p)
                let t0 := mulmod(w3, q_ecc, p)
                t0 := mulmod(t0, q_c, p)
                t0 := mulmod(t0, scaling_alpha, p)

                scalar_multiplier := addmod(scalar_multiplier, mulmod(t0, linear_challenge, p), p)
            }

            Types.G1Point memory QM = vk.QM;
            QM.validateG1Point();
            bool success;
            assembly {
                let mPtr := mload(0x40)
                mstore(mPtr, mload(QM))
                mstore(add(mPtr, 0x20), mload(add(QM, 0x20)))
                mstore(add(mPtr, 0x40), scalar_multiplier)

                // write scalar mul output 0x40 bytes ahead of accumulator
                success := staticcall(gas(), 7, mPtr, 0x60, add(accumulator_ptr, 0x40), 0x40)

                // add scalar mul output into accumulator
                success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, accumulator_ptr, 0x40))
            }
            require(success, "G1 point multiplication failed!");
        }

        Types.G1Point memory output;
        // QC Selector
        {
            uint256 q_c_challenge = challenges.v9;
            assembly {
                scalar_multiplier := mulmod(linear_challenge, alpha_base, p)
                scalar_multiplier := mulmod(scalar_multiplier, q_arith, p)

                // TurboPlonk requires an explicit evaluation of q_c
                scalar_multiplier := addmod(scalar_multiplier, q_c_challenge, p)

                alpha_base := mulmod(scaling_alpha, alpha, p)
            }

            Types.G1Point memory QC = vk.QC;
            QC.validateG1Point();
            bool success;
            assembly {
                let mPtr := mload(0x40)
                mstore(mPtr, mload(QC))
                mstore(add(mPtr, 0x20), mload(add(QC, 0x20)))
                mstore(add(mPtr, 0x40), scalar_multiplier)

                // write scalar mul output 0x40 bytes ahead of accumulator
                success := staticcall(gas(), 7, mPtr, 0x60, add(accumulator_ptr, 0x40), 0x40)

                // add scalar mul output into output point
                success := and(success, staticcall(gas(), 6, accumulator_ptr, 0x80, output, 0x40))
            }
            require(success, "G1 point multiplication failed!");

        }
        challenges.alpha_base = alpha_base;

        return output;
    }


    // Compute kate opening scalar for logic gate opening scalars
    // This method evalautes the polynomial identity used to evaluate either
    // a 2-bit AND or XOR operation in a single constraint
    function compute_logic_gate_opening_scalar(
        Types.Proof memory proof,
        Types.ChallengeTranscript memory challenges
    ) internal pure returns (uint256) {
        uint256 identity = 0;
        uint256 p = Bn254Crypto.r_mod;
        {
            uint256 delta_sum = 0;
            uint256 delta_squared_sum = 0;
            uint256 t0 = 0;
            uint256 t1 = 0;
            uint256 t2 = 0;
            uint256 t3 = 0;
            {
                uint256 wire1_omega = proof.w1_omega;
                uint256 wire1 = proof.w1;
                assembly {
                    t0 := addmod(wire1_omega, sub(p, mulmod(wire1, 0x04, p)), p)
                }
            }

            {
                uint256 wire2_omega = proof.w2_omega;
                uint256 wire2 = proof.w2;
                assembly {
                    t1 := addmod(wire2_omega, sub(p, mulmod(wire2, 0x04, p)), p)

                    delta_sum := addmod(t0, t1, p)
                    t2 := mulmod(t0, t0, p)
                    t3 := mulmod(t1, t1, p)
                    delta_squared_sum := addmod(t2, t3, p)
                    identity := mulmod(delta_sum, delta_sum, p)
                    identity := addmod(identity, sub(p, delta_squared_sum), p)
                }
            }

            uint256 t4 = 0;
            uint256 alpha = challenges.alpha;

            {
                uint256 wire3 = proof.w3;
                assembly{
                    t4 := mulmod(wire3, 0x02, p)
                    identity := addmod(identity, sub(p, t4), p)
                    identity := mulmod(identity, alpha, p)
                }
            }

            assembly {
                t4 := addmod(t4, t4, p)
                t2 := addmod(t2, sub(p, t0), p)
                t0 := mulmod(t0, 0x04, p)
                t0 := addmod(t2, sub(p, t0), p)
                t0 := addmod(t0, 0x06, p)

                t0 := mulmod(t0, t2, p)
                identity := addmod(identity, t0, p)
                identity := mulmod(identity, alpha, p)

                t3 := addmod(t3, sub(p, t1), p)
                t1 := mulmod(t1, 0x04, p)
                t1 := addmod(t3, sub(p, t1), p)
                t1 := addmod(t1, 0x06, p)

                t1 := mulmod(t1, t3, p)
                identity := addmod(identity, t1, p)
                identity := mulmod(identity, alpha, p)

                t0 := mulmod(delta_sum, 0x03, p)

                t1 := mulmod(t0, 0x03, p)

                delta_sum := addmod(t1, t1, p)

                t2 := mulmod(delta_sum, 0x04, p)
                t1 := addmod(t1, t2, p)

                t2 := mulmod(delta_squared_sum, 0x03, p)

                delta_squared_sum := mulmod(t2, 0x06, p)

                delta_sum := addmod(t4, sub(p, delta_sum), p)
                delta_sum := addmod(delta_sum, 81, p)

                t1 := addmod(delta_squared_sum, sub(p, t1), p)
                t1 := addmod(t1, 83, p)
            }

            {
                uint256 wire3 = proof.w3;
                assembly {
                    delta_sum := mulmod(delta_sum, wire3, p)

                    delta_sum := addmod(delta_sum, t1, p)
                    delta_sum := mulmod(delta_sum, wire3, p)
                }
            }
            {
                uint256 wire4 = proof.w4;
                assembly {
                    t2 := mulmod(wire4, 0x04, p)
                }
            }
            {
                uint256 wire4_omega = proof.w4_omega;
                assembly {
                    t2 := addmod(wire4_omega, sub(p, t2), p)
                }
            }
            {
                uint256 q_c = proof.q_c;
                assembly {
                    t3 := addmod(t2, t2, p)
                    t2 := addmod(t2, t3, p)

                    t3 := addmod(t2, t2, p)
                    t3 := addmod(t3, t2, p)

                    t3 := addmod(t3, sub(p, t0), p)
                    t3 := mulmod(t3, q_c, p)

                    t2 := addmod(t2, t0, p)
                    delta_sum := addmod(delta_sum, delta_sum, p)
                    t2 := addmod(t2, sub(p, delta_sum), p)

                    t2 := addmod(t2, t3, p)

                    identity := addmod(identity, t2, p)
                }
            }
            uint256 linear_nu = challenges.v10;
            uint256 alpha_base = challenges.alpha_base;

            assembly {
                identity := mulmod(identity, alpha_base, p)
                identity := mulmod(identity, linear_nu, p)
            }
        }
        // update alpha
        uint256 alpha_base = challenges.alpha_base;
        uint256 alpha = challenges.alpha;
        assembly {
            alpha := mulmod(alpha, alpha, p)
            alpha := mulmod(alpha, alpha, p)
            alpha_base := mulmod(alpha_base, alpha, p) 
        }
        challenges.alpha_base = alpha_base;

        return identity;
    }

    // Compute kate opening scalar for arithmetic gate selectors
    function compute_range_gate_opening_scalar(
        Types.Proof memory proof,
        Types.ChallengeTranscript memory challenges
    ) internal pure returns (uint256) {
        uint256 wire1 = proof.w1;
        uint256 wire2 = proof.w2;
        uint256 wire3 = proof.w3;
        uint256 wire4 = proof.w4;
        uint256 wire4_omega = proof.w4_omega;
        uint256 alpha = challenges.alpha;
        uint256 alpha_base = challenges.alpha_base;
        uint256 range_acc;
        uint256 p = Bn254Crypto.r_mod;
        uint256 linear_challenge = challenges.v10;
        assembly {
            let delta_1 := addmod(wire3, sub(p, mulmod(wire4, 0x04, p)), p)
            let delta_2 := addmod(wire2, sub(p, mulmod(wire3, 0x04, p)), p)
            let delta_3 := addmod(wire1, sub(p, mulmod(wire2, 0x04, p)), p)
            let delta_4 := addmod(wire4_omega, sub(p, mulmod(wire1, 0x04, p)), p)


            let t0 := mulmod(delta_1, delta_1, p)
            t0 := addmod(t0, sub(p, delta_1), p)
            let t1 := addmod(delta_1, sub(p, 2), p)
            t0 := mulmod(t0, t1, p)
            t1 := addmod(delta_1, sub(p, 3), p)
            t0 := mulmod(t0, t1, p)
            t0 := mulmod(t0, alpha_base, p)

            range_acc := t0
            alpha_base := mulmod(alpha_base, alpha, p)

            t0 := mulmod(delta_2, delta_2, p)
            t0 := addmod(t0, sub(p, delta_2), p)
            t1 := addmod(delta_2, sub(p, 2), p)
            t0 := mulmod(t0, t1, p)
            t1 := addmod(delta_2, sub(p, 3), p)
            t0 := mulmod(t0, t1, p)
            t0 := mulmod(t0, alpha_base, p)
            range_acc := addmod(range_acc, t0, p)
            alpha_base := mulmod(alpha_base, alpha, p)

            t0 := mulmod(delta_3, delta_3, p)
            t0 := addmod(t0, sub(p, delta_3), p)
            t1 := addmod(delta_3, sub(p, 2), p)
            t0 := mulmod(t0, t1, p)
            t1 := addmod(delta_3, sub(p, 3), p)
            t0 := mulmod(t0, t1, p)
            t0 := mulmod(t0, alpha_base, p)
            range_acc := addmod(range_acc, t0, p)
            alpha_base := mulmod(alpha_base, alpha, p)

            t0 := mulmod(delta_4, delta_4, p)
            t0 := addmod(t0, sub(p, delta_4), p)
            t1 := addmod(delta_4, sub(p, 2), p)
            t0 := mulmod(t0, t1, p)
            t1 := addmod(delta_4, sub(p, 3), p)
            t0 := mulmod(t0, t1, p)
            t0 := mulmod(t0, alpha_base, p)
            range_acc := addmod(range_acc, t0, p)
            alpha_base := mulmod(alpha_base, alpha, p)

            range_acc := mulmod(range_acc, linear_challenge, p)
        }

        challenges.alpha_base = alpha_base;
        return range_acc;
    }

    // Compute grand product opening scalar and perform kate verification scalar multiplication
    function compute_grand_product_opening_group_element(
        Types.Proof memory proof,
        Types.VerificationKey memory vk,
        Types.ChallengeTranscript memory challenges,
        uint256 L1_fr
    ) internal view returns (Types.G1Point memory) {
        uint256 beta = challenges.beta;
        uint256 zeta = challenges.zeta;
        uint256 gamma = challenges.gamma;
        uint256 p = Bn254Crypto.r_mod;
        
        uint256 partial_grand_product;
        uint256 sigma_multiplier;

        {
            uint256 w1 = proof.w1;
            uint256 sigma1 = proof.sigma1;
            assembly {
                let witness_term := addmod(w1, gamma, p)
                partial_grand_product := addmod(mulmod(beta, zeta, p), witness_term, p)
                sigma_multiplier := addmod(mulmod(sigma1, beta, p), witness_term, p)
            }
        }
        {
            uint256 w2 = proof.w2;
            uint256 sigma2 = proof.sigma2;
            assembly {
                let witness_term := addmod(w2, gamma, p)
                partial_grand_product := mulmod(partial_grand_product, addmod(mulmod(mulmod(zeta, 0x05, p), beta, p), witness_term, p), p)
                sigma_multiplier := mulmod(sigma_multiplier, addmod(mulmod(sigma2, beta, p), witness_term, p), p)
            }
        }
        {
            uint256 w3 = proof.w3;
            uint256 sigma3 = proof.sigma3;
            assembly {
                let witness_term := addmod(w3, gamma, p)
                partial_grand_product := mulmod(partial_grand_product, addmod(mulmod(mulmod(zeta, 0x06, p), beta, p), witness_term, p), p)

                sigma_multiplier := mulmod(sigma_multiplier, addmod(mulmod(sigma3, beta, p), witness_term, p), p)
            }
        }
        {
            uint256 w4 = proof.w4;
            assembly {
                partial_grand_product := mulmod(partial_grand_product, addmod(addmod(mulmod(mulmod(zeta, 0x07, p), beta, p), gamma, p), w4, p), p)
            }
        }
        {
            uint256 linear_challenge = challenges.v10;
            uint256 alpha_base = challenges.alpha_base;
            uint256 alpha = challenges.alpha;
            uint256 separator_challenge = challenges.u;
            uint256 grand_product_at_z_omega = proof.grand_product_at_z_omega;
            uint256 l_start = L1_fr;
            assembly {
                partial_grand_product := mulmod(partial_grand_product, alpha_base, p)

                sigma_multiplier := mulmod(mulmod(sub(p, mulmod(mulmod(sigma_multiplier, grand_product_at_z_omega, p), alpha_base, p)), beta, p), linear_challenge, p)

                alpha_base := mulmod(mulmod(alpha_base, alpha, p), alpha, p)

                partial_grand_product := addmod(mulmod(addmod(partial_grand_product, mulmod(l_start, alpha_base, p), p), linear_challenge, p), separator_challenge, p)

                alpha_base := mulmod(alpha_base, alpha, p)
            }
            challenges.alpha_base = alpha_base;
        }

        Types.G1Point memory Z = proof.Z;
        Types.G1Point memory SIGMA4 = vk.SIGMA4;
        Types.G1Point memory accumulator;
        Z.validateG1Point();
        SIGMA4.validateG1Point();
        bool success;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, mload(Z))
            mstore(add(mPtr, 0x20), mload(add(Z, 0x20)))
            mstore(add(mPtr, 0x40), partial_grand_product)
            success := staticcall(gas(), 7, mPtr, 0x60, mPtr, 0x40)

            mstore(add(mPtr, 0x40), mload(SIGMA4))
            mstore(add(mPtr, 0x60), mload(add(SIGMA4, 0x20)))
            mstore(add(mPtr, 0x80), sigma_multiplier)
            success := and(success, staticcall(gas(), 7, add(mPtr, 0x40), 0x60, add(mPtr, 0x40), 0x40))
            
            success := and(success, staticcall(gas(), 6, mPtr, 0x80, accumulator, 0x40))
        }

        require(success, "compute_grand_product_opening_scalar group operations failure");
        return accumulator;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Bn254Crypto library used for the fr, g1 and g2 point types
 * @dev Used to manipulate fr, g1, g2 types, perform modular arithmetic on them and call
 * the precompiles add, scalar mul and pairing
 *
 * Notes on optimisations
 * 1) Perform addmod, mulmod etc. in assembly - removes the check that Solidity performs to confirm that
 * the supplied modulus is not 0. This is safe as the modulus's used (r_mod, q_mod) are hard coded
 * inside the contract and not supplied by the user
 */
library Types {
    uint256 constant PROGRAM_WIDTH = 4;
    uint256 constant NUM_NU_CHALLENGES = 11;

    uint256 constant coset_generator0 = 0x0000000000000000000000000000000000000000000000000000000000000005;
    uint256 constant coset_generator1 = 0x0000000000000000000000000000000000000000000000000000000000000006;
    uint256 constant coset_generator2 = 0x0000000000000000000000000000000000000000000000000000000000000007;

    // TODO: add external_coset_generator() method to compute this
    uint256 constant coset_generator7 = 0x000000000000000000000000000000000000000000000000000000000000000c;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // G2 group element where x \in Fq2 = x0 * z + x1
    struct G2Point {
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
    }

    // N>B. Do not re-order these fields! They must appear in the same order as they
    // appear in the proof data
    struct Proof {
        G1Point W1;
        G1Point W2;
        G1Point W3;
        G1Point W4;
        G1Point Z;
        G1Point T1;
        G1Point T2;
        G1Point T3;
        G1Point T4;
        uint256 w1;
        uint256 w2;
        uint256 w3;
        uint256 w4;
        uint256 sigma1;
        uint256 sigma2;
        uint256 sigma3;
        uint256 q_arith;
        uint256 q_ecc;
        uint256 q_c;
        uint256 linearization_polynomial;
        uint256 grand_product_at_z_omega;
        uint256 w1_omega;
        uint256 w2_omega;
        uint256 w3_omega;
        uint256 w4_omega;
        G1Point PI_Z;
        G1Point PI_Z_OMEGA;
        G1Point recursive_P1;
        G1Point recursive_P2;
        uint256 quotient_polynomial_eval;
    }

    struct ChallengeTranscript {
        uint256 alpha_base;
        uint256 alpha;
        uint256 zeta;
        uint256 beta;
        uint256 gamma;
        uint256 u;
        uint256 v0;
        uint256 v1;
        uint256 v2;
        uint256 v3;
        uint256 v4;
        uint256 v5;
        uint256 v6;
        uint256 v7;
        uint256 v8;
        uint256 v9;
        uint256 v10;
    }

    struct VerificationKey {
        uint256 circuit_size;
        uint256 num_inputs;
        uint256 work_root;
        uint256 domain_inverse;
        uint256 work_root_inverse;
        G1Point Q1;
        G1Point Q2;
        G1Point Q3;
        G1Point Q4;
        G1Point Q5;
        G1Point QM;
        G1Point QC;
        G1Point QARITH;
        G1Point QECC;
        G1Point QRANGE;
        G1Point QLOGIC;
        G1Point SIGMA1;
        G1Point SIGMA2;
        G1Point SIGMA3;
        G1Point SIGMA4;
        bool contains_recursive_proof;
        uint256 recursive_proof_indices;
        G2Point g2_x;

        // zeta challenge raised to the power of the circuit size.
        // Not actually part of the verification key, but we put it here to prevent stack depth errors
        uint256 zeta_pow_n;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from '../cryptography/Types.sol';

import {Rollup1x1Vk} from '../keys/Rollup1x1Vk.sol';
import {Rollup1x2Vk} from '../keys/Rollup1x2Vk.sol';
import {Rollup1x4Vk} from '../keys/Rollup1x4Vk.sol';

import {Rollup28x1Vk} from '../keys/Rollup28x1Vk.sol';
import {Rollup28x2Vk} from '../keys/Rollup28x2Vk.sol';
import {Rollup28x4Vk} from '../keys/Rollup28x4Vk.sol';
// import {Rollup28x8Vk} from '../keys/Rollup28x8Vk.sol';
// import {Rollup28x16Vk} from '../keys/Rollup28x16Vk.sol';
// import {Rollup28x32Vk} from '../keys/Rollup28x32Vk.sol';

import {EscapeHatchVk} from '../keys/EscapeHatchVk.sol';

/**
 * @title Verification keys library
 * @dev Used to select the appropriate verification key for the proof in question
 */
library VerificationKeys {
    /**
     * @param _keyId - verification key identifier used to select the appropriate proof's key
     * @return Verification key
     */
    function getKeyById(uint256 _keyId) external pure returns (Types.VerificationKey memory) {
        // added in order: qL, qR, qO, qC, qM. x coord first, followed by y coord
        Types.VerificationKey memory vk;

        if (_keyId == 0) {
            vk = EscapeHatchVk.get_verification_key();
        } else if (_keyId == 1) {
            vk = Rollup1x1Vk.get_verification_key();
        } else if (_keyId == 2) {
            vk = Rollup1x2Vk.get_verification_key();
        } else if (_keyId == 4) {
            vk = Rollup1x4Vk.get_verification_key();
        } else if (_keyId == 32) {
            vk = Rollup28x1Vk.get_verification_key();
        } else if (_keyId == 64) {
            vk = Rollup28x2Vk.get_verification_key();
        } else if (_keyId == 128) {
            vk = Rollup28x4Vk.get_verification_key();
            // } else if (_keyId == 256) {
            //     vk = Rollup28x8Vk.get_verification_key();
            // } else if (_keyId == 512) {
            //     vk = Rollup28x16Vk.get_verification_key();
            // } else if (_keyId == 1024) {
            //     vk = Rollup28x32Vk.get_verification_key();
        } else {
            require(false, 'UNKNOWN_KEY_ID');
        }
        return vk;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from './Types.sol';
import {Bn254Crypto} from './Bn254Crypto.sol';

/**
 * @title Transcript library
 * @dev Generates Plonk random challenges
 */
library Transcript {

    struct TranscriptData {
        bytes32 current_challenge;
    }
    
    /**
     * Compute keccak256 hash of 2 4-byte variables (circuit_size, num_public_inputs)
     */
    function generate_initial_challenge(
                TranscriptData memory self,
                uint256 circuit_size,
                uint256 num_public_inputs
    ) internal pure {
        bytes32 challenge;
        assembly {
            let mPtr := mload(0x40)
            mstore8(add(mPtr, 0x20), shr(24, circuit_size))
            mstore8(add(mPtr, 0x21), shr(16, circuit_size))
            mstore8(add(mPtr, 0x22), shr(8, circuit_size))
            mstore8(add(mPtr, 0x23), circuit_size)           
            mstore8(add(mPtr, 0x24), shr(24, num_public_inputs))
            mstore8(add(mPtr, 0x25), shr(16, num_public_inputs))
            mstore8(add(mPtr, 0x26), shr(8, num_public_inputs))
            mstore8(add(mPtr, 0x27), num_public_inputs)
            challenge := keccak256(add(mPtr, 0x20), 0x08)
        }
        self.current_challenge = challenge;
    }

    /**
     * We treat the beta challenge as a special case, because it includes the public inputs.
     * The number of public inputs can be extremely large for rollups and we want to minimize mem consumption.
     * => we directly allocate memory to hash the public inputs, in order to prevent the global memory pointer from increasing
     */
    function generate_beta_gamma_challenges(
        TranscriptData memory self,
        Types.ChallengeTranscript memory challenges,
        uint256 num_public_inputs
    ) internal pure  {
        bytes32 challenge;
        bytes32 old_challenge = self.current_challenge;
        uint256 p = Bn254Crypto.r_mod;
        uint256 reduced_challenge;
        assembly {
            let m_ptr := mload(0x40)
            // N.B. If the calldata ABI changes this code will need to change!
            // We can copy all of the public inputs, followed by the wire commitments, into memory
            // using calldatacopy
            mstore(m_ptr, old_challenge)
            m_ptr := add(m_ptr, 0x20)
            let inputs_start := add(calldataload(0x04), 0x24)
            // num_calldata_bytes = public input size + 256 bytes for the 4 wire commitments
            let num_calldata_bytes := add(0x100, mul(num_public_inputs, 0x20))
            calldatacopy(m_ptr, inputs_start, num_calldata_bytes)

            let start := mload(0x40)
            let length := add(num_calldata_bytes, 0x20)

            challenge := keccak256(start, length)
            reduced_challenge := mod(challenge, p)
        }
        challenges.beta = reduced_challenge;

        // get gamma challenge by appending 1 to the beta challenge and hash
        assembly {
            mstore(0x00, challenge)
            mstore8(0x20, 0x01)
            challenge := keccak256(0, 0x21)
            reduced_challenge := mod(challenge, p)
        }
        challenges.gamma = reduced_challenge;
        self.current_challenge = challenge;
    }

    function generate_alpha_challenge(
        TranscriptData memory self,
        Types.ChallengeTranscript memory challenges,
        Types.G1Point memory Z
    ) internal pure  {
        bytes32 challenge;
        bytes32 old_challenge = self.current_challenge;
        uint256 p = Bn254Crypto.r_mod;
        uint256 reduced_challenge;
        assembly {
            let m_ptr := mload(0x40)
            mstore(m_ptr, old_challenge)
            mstore(add(m_ptr, 0x20), mload(add(Z, 0x20)))
            mstore(add(m_ptr, 0x40), mload(Z))
            challenge := keccak256(m_ptr, 0x60)
            reduced_challenge := mod(challenge, p)
        }
        challenges.alpha = reduced_challenge;
        challenges.alpha_base = reduced_challenge;
        self.current_challenge = challenge;
    }

    function generate_zeta_challenge(
        TranscriptData memory self,
        Types.ChallengeTranscript memory challenges,
        Types.G1Point memory T1,
        Types.G1Point memory T2,
        Types.G1Point memory T3,
        Types.G1Point memory T4
    ) internal pure  {
        bytes32 challenge;
        bytes32 old_challenge = self.current_challenge;
        uint256 p = Bn254Crypto.r_mod;
        uint256 reduced_challenge;
        assembly {
            let m_ptr := mload(0x40)
            mstore(m_ptr, old_challenge)
            mstore(add(m_ptr, 0x20), mload(add(T1, 0x20)))
            mstore(add(m_ptr, 0x40), mload(T1))
            mstore(add(m_ptr, 0x60), mload(add(T2, 0x20)))
            mstore(add(m_ptr, 0x80), mload(T2))
            mstore(add(m_ptr, 0xa0), mload(add(T3, 0x20)))
            mstore(add(m_ptr, 0xc0), mload(T3))
            mstore(add(m_ptr, 0xe0), mload(add(T4, 0x20)))
            mstore(add(m_ptr, 0x100), mload(T4))
            challenge := keccak256(m_ptr, 0x120)
            reduced_challenge := mod(challenge, p)
        }
        challenges.zeta = reduced_challenge;
        self.current_challenge = challenge;
    }

    /**
     * We compute our initial nu challenge by hashing the following proof elements (with the current challenge):
     *
     * w1, w2, w3, w4, sigma1, sigma2, sigma3, q_arith, q_ecc, q_c, linearization_poly, grand_product_at_z_omega,
     * w1_omega, w2_omega, w3_omega, w4_omega
     *
     * These values are placed linearly in the proofData, we can extract them with a calldatacopy call
     *
     */
    function generate_nu_challenges(TranscriptData memory self, Types.ChallengeTranscript memory challenges, uint256 quotient_poly_eval, uint256 num_public_inputs) internal pure
    {
        uint256 p = Bn254Crypto.r_mod;
        bytes32 current_challenge = self.current_challenge;
        uint256 base_v_challenge;
        uint256 updated_v;

        // We want to copy SIXTEEN field elements from calldata into memory to hash
        // But we start by adding the quotient poly evaluation to the hash transcript
        assembly {
            // get a calldata pointer that points to the start of the data we want to copy
            let calldata_ptr := add(calldataload(0x04), 0x24)
            // skip over the public inputs
            calldata_ptr := add(calldata_ptr, mul(num_public_inputs, 0x20))
            // There are NINE G1 group elements added into the transcript in the `beta` round, that we need to skip over
            calldata_ptr := add(calldata_ptr, 0x240) // 9 * 0x40 = 0x240

            let m_ptr := mload(0x40)
            mstore(m_ptr, current_challenge)
            mstore(add(m_ptr, 0x20), quotient_poly_eval)
            calldatacopy(add(m_ptr, 0x40), calldata_ptr, 0x200) // 16 * 0x20 = 0x200
            base_v_challenge := keccak256(m_ptr, 0x240) // hash length = 0x240, we include the previous challenge in the hash
            updated_v := mod(base_v_challenge, p)
        }

        // assign the first challenge value
        challenges.v0 = updated_v;

        // for subsequent challenges we iterate 10 times.
        // At each iteration i \in [1, 10] we compute challenges.vi = keccak256(base_v_challenge, byte(i))
        assembly {
            mstore(0x00, base_v_challenge)
            mstore8(0x20, 0x01)
            updated_v := mod(keccak256(0x00, 0x21), p)
        }
        challenges.v1 = updated_v;
        assembly {
            mstore8(0x20, 0x02)
            updated_v := mod(keccak256(0x00, 0x21), p)
        }
        challenges.v2 = updated_v;
        assembly {
            mstore8(0x20, 0x03)
            updated_v := mod(keccak256(0x00, 0x21), p)
        }
        challenges.v3 = updated_v;
        assembly {
            mstore8(0x20, 0x04)
            updated_v := mod(keccak256(0x00, 0x21), p)
        }
        challenges.v4 = updated_v;
        assembly {
            mstore8(0x20, 0x05)
            updated_v := mod(keccak256(0x00, 0x21), p)
        }
        challenges.v5 = updated_v;
        assembly {
            mstore8(0x20, 0x06)
            updated_v := mod(keccak256(0x00, 0x21), p)
        }
        challenges.v6 = updated_v;
        assembly {
            mstore8(0x20, 0x07)
            updated_v := mod(keccak256(0x00, 0x21), p)
        }
        challenges.v7 = updated_v;
        assembly {
            mstore8(0x20, 0x08)
            updated_v := mod(keccak256(0x00, 0x21), p)
        }
        challenges.v8 = updated_v;
        assembly {
            mstore8(0x20, 0x09)
            updated_v := mod(keccak256(0x00, 0x21), p)
        }
        challenges.v9 = updated_v;

        // update the current challenge when computing the final nu challenge
        bytes32 challenge;
        assembly {
            mstore8(0x20, 0x0a)
            challenge := keccak256(0x00, 0x21)
            updated_v := mod(challenge, p)
        }
        challenges.v10 = updated_v;

        self.current_challenge = challenge;
    }

    function generate_separator_challenge(
        TranscriptData memory self,
        Types.ChallengeTranscript memory challenges,
        Types.G1Point memory PI_Z,
        Types.G1Point memory PI_Z_OMEGA
    ) internal pure  {
        bytes32 challenge;
        bytes32 old_challenge = self.current_challenge;
        uint256 p = Bn254Crypto.r_mod;
        uint256 reduced_challenge;
        assembly {
            let m_ptr := mload(0x40)
            mstore(m_ptr, old_challenge)
            mstore(add(m_ptr, 0x20), mload(add(PI_Z, 0x20)))
            mstore(add(m_ptr, 0x40), mload(PI_Z))
            mstore(add(m_ptr, 0x60), mload(add(PI_Z_OMEGA, 0x20)))
            mstore(add(m_ptr, 0x80), mload(PI_Z_OMEGA))
            challenge := keccak256(m_ptr, 0xa0)
            reduced_challenge := mod(challenge, p)
        }
        challenges.u = reduced_challenge;
        self.current_challenge = challenge;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd
pragma solidity >=0.6.10 <0.8.0;

interface IVerifier {
    function verify(bytes memory serialized_proof, uint256 _keyId) external;
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from '../cryptography/Types.sol';
import {Bn254Crypto} from '../cryptography/Bn254Crypto.sol';

library Rollup1x1Vk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 1048576) // vk.circuit_size
            mstore(add(vk, 0x20), 42) // vk.num_inputs
            mstore(add(vk, 0x40),0x26125da10a0ed06327508aba06d1e303ac616632dbed349f53422da953337857) // vk.work_root
            mstore(add(vk, 0x60),0x30644b6c9c4a72169e4daa317d25f04512ae15c53b34e8f5acd8e155d0a6c101) // vk.domain_inverse
            mstore(add(vk, 0x80),0x100c332d2100895fab6473bc2c51bfca521f45cb3baca6260852a8fde26c91f3) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x1f2ac4d179286e11ea27474eb42a59e783378ef2d4b3dcaf53bcc4bfd5766cdf)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x037b973ea64359336003789dd5c14e0d08427601633f7a60915c233e2416793b)
            mstore(mload(add(vk, 0xc0)), 0x09a89b78e80f9a471318ca402938418bb3df1bf743b37237593e5d61210a36b4)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2b7e8fd3a325fa5319243146c0264e5447f55f9bbed7638db81260e2953c055c)
            mstore(mload(add(vk, 0xe0)), 0x08b939500bec7b7468ba394ce9630842c3847a45f3771440c958315e426124b0)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x2fc02df0bface1f5d03869b3e2c354c2504238dd9474a367dcb4e3d9da568ebb)
            mstore(mload(add(vk, 0x100)), 0x2c3ad8425d75ac138dba56485d90edcc021f60327be3498b4e3fe27be3d56295)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x217fa454c2018d20ac6d691580f40bba410b37bbd05af596b7de276b4fb1f6ee)
            mstore(mload(add(vk, 0x120)), 0x15a1de41f51208defd88775e97fef82bf3ab02d8668b47db61dfeb47cd4f245b)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x12f7d8bb05da8297beadd0d252e1ad442ffa1e417a7409cb8f5fdd9aa7f8c0f6)
            mstore(mload(add(vk, 0x140)), 0x1ab0878c1bdb3f32a0852d57d8c4a34596fd3cd05d7c993cb13ea693e8811bbf)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x1288c1f417fb0b2824e6cfbf2ef2f0b7779b5021c31bc7fcd6ab2548098e3120)
            mstore(mload(add(vk, 0x160)), 0x061b6360be0227a86a035b045aef240eb58589053fce87c01c720bda452f43d1)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x01156ab445d61985688f31ec54c6cd62d316d0c87cade32706fd236c2e93d96c)
            mstore(mload(add(vk, 0x180)), 0x0b0f5891e864b4017a747aa299632bfe31a889aad3f3de6a01852b1ce243001e)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0c9fcc80878d243d6188504c7887f5f1fa75ab2bf26ffccf756eee03c8a84c76)
            mstore(mload(add(vk, 0x1a0)), 0x2f9db190db59e2a2d54873e289c85cbbb7ae92c313ec601b431f497e98b0a421)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x13e353dc36b2271889f3914bd574bbf7543591e0ee3e0536602f34b2283815b0)
            mstore(mload(add(vk, 0x1c0)), 0x2abffcb12d5d0076a25e93b0c7fc92189796618f174bb7d1af5fc920676117be)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x068a7d9bcb8ad26f29607644a4e06c1bc4be3ce7febd65bde61879a24e570115)
            mstore(mload(add(vk, 0x1e0)), 0x20735c1704fee325f652a4a61b3fe620130f9c868d6430f9ace2a782e4cd474e)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x217a0dc7aa32d5ec9f686718931304a9673229626cbfa0d9e30501e546331f4b)
            mstore(mload(add(vk, 0x200)), 0x20cff9441d3a303e85c353ce25709bef99d5a07dec6e6d76c9e97cb68e3fd311)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x1d93dc5472d57a5863b6dc93891d875ade34abf17a06154b6793c187111fc9a3)
            mstore(mload(add(vk, 0x220)), 0x1c5a9c2747d0b4788343819582cd7d76a577a46b718315fd8361ee86845384b3)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x069b936b21b217b81107423f7eb9772a0295009e1ca7b449febdf11bd967b391)
            mstore(mload(add(vk, 0x240)), 0x162904b9f7b4cc5fb50b7440e1e885c5bf10646a1701f2b7286bcd237ba52c64)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x0f281022f4802d347c838ba2390a5ed9430d596c8a3dc831f50ecf0bb872c974)
            mstore(mload(add(vk, 0x260)), 0x1ac525fe26d3a6aebce5d7e0e09643a8193eff2bd2f6d35262460233353cbaad)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x16eb8c3d631fd40449c8ae2e025a04660b2548b9783805868d74b7ef6e1f7d12)
            mstore(add(vk, 0x280), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 26) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x2c0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x2c0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from '../cryptography/Types.sol';
import {Bn254Crypto} from '../cryptography/Bn254Crypto.sol';

library Rollup1x2Vk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 2097152) // vk.circuit_size
            mstore(add(vk, 0x20), 54) // vk.num_inputs
            mstore(add(vk, 0x40),0x1ded8980ae2bdd1a4222150e8598fc8c58f50577ca5a5ce3b2c87885fcd0b523) // vk.work_root
            mstore(add(vk, 0x60),0x30644cefbebe09202b4ef7f3ff53a4511d70ff06da772cc3785d6b74e0536081) // vk.domain_inverse
            mstore(add(vk, 0x80),0x19c6dfb841091b14ab14ecc1145f527850fd246e940797d3f5fac783a376d0f0) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x2035797d3cfe55fb2cb1d7495a7bd8557579193cffa8b2869ef1e6334d7c0370)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x1cff5ff0b7b2373e36ebb6fe7fd43de16e3da206b845a80312cbde147e33df3c)
            mstore(mload(add(vk, 0xc0)), 0x13fd1d48ec231af1c268d63a7eecac135183fe49a97e1d8cb52a485110c99771)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1519d84f5732134d01f7991ed0a23bdfac4e1abf132c8c81ef3db223cc798547)
            mstore(mload(add(vk, 0xe0)), 0x1f8f37443d6b35f4e37d9227d8c7b705b0ce0137eba7c31f67f0ff305c435f06)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x02aa9e7e15d6066825ed4cb9ee26dc3c792cf947aaecbdb082e2ebf8934f2635)
            mstore(mload(add(vk, 0x100)), 0x0ebdf890f294b514a792518762d47c1ea8682dec1eaed7d8a9da9b529ee1d4b9)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x2fbded8ed1cb6e11c285c4db14197b26bc9dd5c48fc0cfb3c3b6d357ae9ed89b)
            mstore(mload(add(vk, 0x120)), 0x12c597dd13b50f505d34fbb6a6ca15c913f87f71f312a838438c2e5818f35847)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x0664442fff533df8eae9add8b011c8c24332efb23e00da3bb145ecd2e32102a5)
            mstore(mload(add(vk, 0x140)), 0x284f4d6d4a99337a45e9c222d5e05243ff276d3736456dfacc449bd6ef2511ce)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2adfeaaceb6331071fcf41d290322be8025dd2d5615b9a13078f235530faa1b6)
            mstore(mload(add(vk, 0x160)), 0x06517b067977fe1743c8b429c032f6fd3846ae20997d2dd05813a10701fc5348)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1b209661353dbdf602b85ab124e30051aadee936d68610493889fe633a4191a1)
            mstore(mload(add(vk, 0x180)), 0x04e67fcb0781f800e131d3f98a584b333b7e9ba24f8f1848156412e9d7cad7c4)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x1c50e0a2d57ddf592a0b03c6942451d7744e34402f6a330ac149a05f6c8dc431)
            mstore(mload(add(vk, 0x1a0)), 0x149e9c48163b7050a2a0fc14f3c1f9b774f1dd2f2d1248cd8d4fadce6e754129)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x2d9406755cf062c4f9afa31c1124ea66a7650821fb8ef7c89865687126c610b1)
            mstore(mload(add(vk, 0x1c0)), 0x26feacb1c66490c9239f6ebe1882a34d48d808c7d778b43039c7bff795c517ae)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x05e6597b85e3438d4345377c2cc4707ae55a58e1b8658b420608d19a44a7c66c)
            mstore(mload(add(vk, 0x1e0)), 0x2956cd5126b44362be7d9d9bc63ac056d6da0f952aa17cfcf9c79929b95477a1)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x19fe15891be1421df2599a8b0bd3f0e0b852abc71fdc7b0ccecfe42a5b7f7198)
            mstore(mload(add(vk, 0x200)), 0x03328c296b883fbe931776cf309004a3b819fab885f790a51d1430167b24698e)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x2a76d6ca1d88c2e9ad2e18c03215fafc81ac163ecfe79ddf060d4f4b7389c03d)
            mstore(mload(add(vk, 0x220)), 0x11e7c17289e04208ec90a76ecbe436120193debae02fba654ae61d0b83d1abe1)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x17f03d09230f58660f79a93fd27339763996794c6346527ed1ddb06ffb830240)
            mstore(mload(add(vk, 0x240)), 0x0f58505fafa98e131cc94bcc57fa21d89b2797113bd263889665fc74f86b540b)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x153e8f0949a7c7f83ba8e6a6418b254c5703e836f864657ca8adf17facbe3edf)
            mstore(mload(add(vk, 0x260)), 0x1dd744cc20dcde91df6e12965f9b4572b37e898ab61cce8580a8635f76922d66)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x1480e010037944e5c157ab07ce92e07bd367c74f5710a8229fcfecfd1cf860f2)
            mstore(add(vk, 0x280), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 38) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x2c0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x2c0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from '../cryptography/Types.sol';
import {Bn254Crypto} from '../cryptography/Bn254Crypto.sol';

library Rollup1x4Vk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 4194304) // vk.circuit_size
            mstore(add(vk, 0x20), 78) // vk.num_inputs
            mstore(add(vk, 0x40),0x1ad92f46b1f8d9a7cda0ceb68be08215ec1a1f05359eebbba76dde56a219447e) // vk.work_root
            mstore(add(vk, 0x60),0x30644db14ff7d4a4f1cf9ed5406a7e5722d273a7aa184eaa5e1fb0846829b041) // vk.domain_inverse
            mstore(add(vk, 0x80),0x2eb584390c74a876ecc11e9c6d3c38c3d437be9d4beced2343dc52e27faa1396) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x1905de26e0521f6770bd0f862fe4e0eec67f12507686404c6446757a98a37814)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x0694957d080b0decf988c57dced5f3b5e3484d68025a3e835bef2d99be6be002)
            mstore(mload(add(vk, 0xc0)), 0x0ca202177999ac7977504b6cc300641a9b4298c8aa558aec3ee94c30b5a15aec)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2fc822dddd433de2e74843c0bfcf4f8364a68a50a27b9e7e8cb34f21533e258c)
            mstore(mload(add(vk, 0xe0)), 0x1a18221746331118b68efbeac03a4f473a71bfd5d382852e2793701af36eba06)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x21b2c1cd7c94a3d2408da26cf1f3d3375c601760a79482393f9ff6b922158c3d)
            mstore(mload(add(vk, 0x100)), 0x2346c947ff02dca4de5e54b2253d037776fbcfe0fdad86638e9db890da71c049)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x0d97ce16eb882cee8465f26d5d551a7d9d3b4919d8e88534a9f9e5c8bc4edd4a)
            mstore(mload(add(vk, 0x120)), 0x098db84adc95fb46bee39c99b82c016f462f1221a4ed3aff5e3091e6f998efab)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x2f9a9bf026f0e7bca888b888b7329e6e6c3aa838676807ed043447568477ae1c)
            mstore(mload(add(vk, 0x140)), 0x12eca0c50cefe2f40970e31c3bf0cc86759947cb551ce64d4d0d9f1b506e7804)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x1754769e1f2b2d2d6b02eeb4177d550b2d64b27c487f7e3a1901b8bb7c079dbd)
            mstore(mload(add(vk, 0x160)), 0x1c6a1a9155a078ee45d77612cdfb952be0a9b1ccf28a1952862bb14dca612df0)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x2b49a3c68393f7432426bc88001731bd19b39bc4440a6e92a22c808ee79cef0b)
            mstore(mload(add(vk, 0x180)), 0x2bf6295f483d0c31a2cd59d90660ae15322fbd7f2c7de91f632e4d85bb9e5542)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x03f9cc8c1db059f7efe6139ac124818a803b83a878899371659e4effcdd34634)
            mstore(mload(add(vk, 0x1a0)), 0x198db1e92d744866cff883596651252349cba329e34e188fea3d5e8688e96d80)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1683a17e5916c5b9d4a207cc851046ce8c2e4c0969c9f7b415b408c9a04e1e5f)
            mstore(mload(add(vk, 0x1c0)), 0x26d32da521d28feac610accf88e570731359b6aadab174e5c54764f5b27479cc)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x23da92a89982bb0c3aea8828d5ba5c7cf18dafe5955cca80ce577931026169c3)
            mstore(mload(add(vk, 0x1e0)), 0x27cda6c91bb4d3077580b03448546ca1ad7535e7ba0298ce8e6d809ee448b42a)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x02f356e126f28aa1446d87dd22b9a183c049460d7c658864cdebcf908fdfbf2b)
            mstore(mload(add(vk, 0x200)), 0x1bded30987633ade34bfc4f5dcbd52037f9793f81b3b64a4f9b2f727f510b68a)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x18f40cabd6c86d97b3f074c6e1138dc2b5b9a9e818f547ae44963903b390fbb9)
            mstore(mload(add(vk, 0x220)), 0x0c10302401e0b254cb1bdf938db61dd2c410533da8847d17b982630748f0b2dd)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x070eec8345671872a78e1a2f0af5efeb844f89d973c51aabbb648396d5db7356)
            mstore(mload(add(vk, 0x240)), 0x2372b6db3edc75e1682ed30b67f3014cbb5d038363953a6736c16a1deecbdf79)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x28d36f1f1f02d019955c7a582cbe8555b9662a27862b1b61e0d40c33b2f55bad)
            mstore(mload(add(vk, 0x260)), 0x0297ba9bd48b4ab9f0bb567cfea88ff27822214f5ba096bf4dea312a08323d61)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x174eae2839fb8eed0ae03668a2a7628a806a6873591b5af113df6b9aa969e67f)
            mstore(add(vk, 0x280), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 62) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x2c0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x2c0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from '../cryptography/Types.sol';
import {Bn254Crypto} from '../cryptography/Bn254Crypto.sol';

library Rollup28x1Vk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 1048576) // vk.circuit_size
            mstore(add(vk, 0x20), 414) // vk.num_inputs
            mstore(add(vk, 0x40),0x26125da10a0ed06327508aba06d1e303ac616632dbed349f53422da953337857) // vk.work_root
            mstore(add(vk, 0x60),0x30644b6c9c4a72169e4daa317d25f04512ae15c53b34e8f5acd8e155d0a6c101) // vk.domain_inverse
            mstore(add(vk, 0x80),0x100c332d2100895fab6473bc2c51bfca521f45cb3baca6260852a8fde26c91f3) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x10bd711408fe2b61aa9262b4a004dcf2ca130cbc32707b0b912f9f89988c98ba)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x08afbc361df7453c1dd919450bd79220a33b2788b6f95283050bf9c323135c5b)
            mstore(mload(add(vk, 0xc0)), 0x137a7113b310661cf1675a8f8770d5a42207c973b5af1d01a6c032bdf2f29a4a)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1f5b2952576e631b56af8de08eac4f657df5b12accb50c9471a1db88774e90b5)
            mstore(mload(add(vk, 0xe0)), 0x1cef558b208cf3d4f94dfa013a98b95290b868386ef510ca1748f6f98bf10be6)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x2446a3863bc0f0f76dd05dd1d42d14bd8bac21d722b77a1f5a5b2d5a579a5234)
            mstore(mload(add(vk, 0x100)), 0x2684bc8456c09dd44dd28e01787220d1f16067ebf7fe761a2e0162f2487bbfe5)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x18196003211bed495d38cbdb609208146170031a8382280a7858085d8a887957)
            mstore(mload(add(vk, 0x120)), 0x2d7c9719e88ebb7b4a2127a6db4b86ad6122a4ef8a1c793fdec3a8973d0b9876)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x297cd6d4531a9ada5d0da740135f7e59bf007a6e43c68e0b3535cca70210bd1e)
            mstore(mload(add(vk, 0x140)), 0x096d40976d338598fc442fb0c1a154d419bca8f9f43eb2015331a97d59565bd1)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x18feffe5bef7a4a8ad9a425c9ae3ccfc57b09fa380994e72ebbbc38b7e1742a0)
            mstore(mload(add(vk, 0x160)), 0x116696fa382e05e33b3cfe33589c21f0ed1e2c943598843118cc537cbf8a7889)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x0943908333df3135bf0a2bb95598e8ed63f398850e5e6580f717fb88e5cfdded)
            mstore(mload(add(vk, 0x180)), 0x1eb644a98415205832ee4888b328ad7c677467160a32a5d46e4ab89f9ae778ba)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x1d3973861d86d55001f5c08bf4f679c311cea8433625b4a5a76a41fcacca7065)
            mstore(mload(add(vk, 0x1a0)), 0x0f05143ecec847223aff4840177b7893eadfa3a251508a894b8ca4befc97ac94)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1920490f668a36b0d098e057aa3b0ef6a979ed13737d56c7d72782f6cc27ded4)
            mstore(mload(add(vk, 0x1c0)), 0x0f5856acdec453a85cd6f66561bd683f611b945b0efd33b751cb2700d231667a)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x21895e7908d82d86a0742fa431c120b69971d4a3baa00ff74f275e43d972e6af)
            mstore(mload(add(vk, 0x1e0)), 0x01902b1a4652cb8eeaf73c03be6dd9cc46537a64f691358f31598ea108a13b37)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x13484549915a2a4bf652cc3200039c60e5d4e3097632590ac89ade0957f4e474)
            mstore(mload(add(vk, 0x200)), 0x0a8d6da0158244b6ddc8109319cafeb5bf8706b8d0d429f1ffd69841b91d0c9b)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x0c3b81b88d53d7f1eb09511e3df867418fe7aca31413843b4369e480779ae965)
            mstore(mload(add(vk, 0x220)), 0x1e2f827d84aedf723ac005cad54e173946fe58f2ee0c6260ca61731c0092c762)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x0c42ca9f0857faf0eebbcfc915eefc3616705dc1a0a5f461278c5ea2dd46ad79)
            mstore(mload(add(vk, 0x240)), 0x14664645717286f98d1505681a9ed79ca2f14acbfbd539d04a42c52295569baa)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x156b5ceac5557d202408c6be907fb3604d1bfab9f16f164ebd1eabdb0ebca7f7)
            mstore(mload(add(vk, 0x260)), 0x0f9987c57db930d1d7b18a9389f77b441a75a3c8abdd1f18be9d012cef08f981)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x2c2cbc7eb7af7221a6fc921f45295645bcaecc330dd2ea76ab55041bc4aa4514)
            mstore(add(vk, 0x280), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 398) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x2c0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x2c0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from '../cryptography/Types.sol';
import {Bn254Crypto} from '../cryptography/Bn254Crypto.sol';

library Rollup28x2Vk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 2097152) // vk.circuit_size
            mstore(add(vk, 0x20), 798) // vk.num_inputs
            mstore(add(vk, 0x40),0x1ded8980ae2bdd1a4222150e8598fc8c58f50577ca5a5ce3b2c87885fcd0b523) // vk.work_root
            mstore(add(vk, 0x60),0x30644cefbebe09202b4ef7f3ff53a4511d70ff06da772cc3785d6b74e0536081) // vk.domain_inverse
            mstore(add(vk, 0x80),0x19c6dfb841091b14ab14ecc1145f527850fd246e940797d3f5fac783a376d0f0) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x0f0d0bfb6fec117bb2077786e723a1565aeb4bfa14c72da9878faa883fcd2d9f)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x15c54ec4e65aa7ed3e2d32812a8b10f552b50967d6b7951486ad4adf89c223f8)
            mstore(mload(add(vk, 0xc0)), 0x0a9996200df4a05c08248a418b2b425a0496d4be35730607e4196b765b1cf398)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2a040c7281e5b5295f0b7364ff657b8aa3b9a5763fe5a883de0e5515ce3c3889)
            mstore(mload(add(vk, 0xe0)), 0x25c60a9905b097158141e3c0592524cecb6bbd078b3a8db8151249a630d27af8)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x3061fbf11a770e0988ebf6a86cd2444889297f5840987ae62643db0c775fd200)
            mstore(mload(add(vk, 0x100)), 0x177117434065a4c3716c4e9fad4ff60d7f73f1bf32ca94ea89037fd1fc905be9)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x0d660f14e9f03323ee85d6e5434e9c87c98ebd4408ea2cb7aa4d4c43f40e55e1)
            mstore(mload(add(vk, 0x120)), 0x0df6c77a9a6bae51cee804b5c1ea6a0ed527bc5bf8a44b1adc4a963b4541a7be)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x1d8fc177b0b1af86d92bc51b39280afb343dbba2d2929f28de0d6fc6656c2917)
            mstore(mload(add(vk, 0x140)), 0x01dfe736aa8cf3635136a08f35dd65b184c85e9a0c59dac8f1d0ebead964959b)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2a691233e2e13145e933c9118ec820af49488639045ce0642807b1022b3c74e7)
            mstore(mload(add(vk, 0x160)), 0x07d69a43886facf8097f8cad533853c896c580aaeb533a02ce7dc5cf92f21ce7)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x2d9c7ce74cb26cb62559bc4697d9cce0c0405d7afabff15c3d740c90fe5fc698)
            mstore(mload(add(vk, 0x180)), 0x2cc2690e4100f95c939a850467e6adc5d906b2f8e7e5d1444e38278e241559da)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2d88c17306d76a91cc9e0b7e225bce42c174819d0e1bac7ee9796081a8285e2e)
            mstore(mload(add(vk, 0x1a0)), 0x0b103de069011640f2594cafec9b5ae2eaa8dadbf83be5891cf7e3119f78bf7e)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x13fc1c920188a004ab78d7a825d1277ffa1cab0707a3cf78874893eef617d3c0)
            mstore(mload(add(vk, 0x1c0)), 0x0de3e722e1a3c2383a2e8939075967c7775ec5b89bf5063b178733051defd1d7)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x1aff0c1424638eb7c2df2bad7b97ab810aaa3eb285d9badcf4d4dc45a696da69)
            mstore(mload(add(vk, 0x1e0)), 0x27257a08dffe29b8e4bf78a9844d01fd808ee8f6e7d419b4e348cdf7d4ab686e)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x11ee0a08f3d883b9eecc693f4c03f1b15356393c5b617da28b96dc5bf9236a91)
            mstore(mload(add(vk, 0x200)), 0x21fb5ca832dc2125bad5019939ad4659e7acefdad6448dd1d900f8912f2a4c6a)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x13cef6e1b0d450b3fe95afdc4dc540e453b66255b12e5bf44dbd37e163dcdd40)
            mstore(mload(add(vk, 0x220)), 0x02f89ba935374a58032f20285d5a1158818f669217a5fed04d04ad6c468e0791)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x26a802cc55c39f79774e98942c103410e4a9889db5239a755d86ad1300c5b3c8)
            mstore(mload(add(vk, 0x240)), 0x2bdb1e71d81c17186eb361e2894a194070dda76762de9caa314b8f099393ae58)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x0efdf91c574f69a89a1154cd97e9dfee19a03590c71738670f866872f6d7b34f)
            mstore(mload(add(vk, 0x260)), 0x2f16de71f5081ba2a41d06a9d0d0790f5ea9c2a0353a89c18ba366f5a313cfe3)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x072220b85bcb1814c213f4ea717c6db6b99043f40ebc6f1ba67f13488eb949fc)
            mstore(add(vk, 0x280), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 782) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x2c0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x2c0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from '../cryptography/Types.sol';
import {Bn254Crypto} from '../cryptography/Bn254Crypto.sol';

library Rollup28x4Vk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 4194304) // vk.circuit_size
            mstore(add(vk, 0x20), 1566) // vk.num_inputs
            mstore(add(vk, 0x40),0x1ad92f46b1f8d9a7cda0ceb68be08215ec1a1f05359eebbba76dde56a219447e) // vk.work_root
            mstore(add(vk, 0x60),0x30644db14ff7d4a4f1cf9ed5406a7e5722d273a7aa184eaa5e1fb0846829b041) // vk.domain_inverse
            mstore(add(vk, 0x80),0x2eb584390c74a876ecc11e9c6d3c38c3d437be9d4beced2343dc52e27faa1396) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x26bb602a4eda00566ddd5bbeff4cd2423db0009acc3accf7156606a4245fd845)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x1dd8547f013efcfc01a7e40a509b24646595342898c5242abe9b10fb58f1c58b)
            mstore(mload(add(vk, 0xc0)), 0x009bf6f14745eec4f9055a140861a09d49864fda7485b704896de4a6ecdb9551)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x08e79e438a66ef31e7bfb99a1165e43f524bd26f78d4f394599f72b59b8042fd)
            mstore(mload(add(vk, 0xe0)), 0x14b7a43408b0c79f59b52823495cf4ef5e41e217091aac757e7d89bc42e10ae3)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x25a096773133d0ce13cb5c27993a3a4d2bb6e0e1d8f2e04674fec28e9e3c5a28)
            mstore(mload(add(vk, 0x100)), 0x08b6422c5411befe0e6a3a0696a6dda1035fb4738ff25917532076a0a4126af7)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x2298cf986a28cb1d0ee774a65f21e976452bfdf2126455424f29d67b267e9a66)
            mstore(mload(add(vk, 0x120)), 0x263505e9368a00c5d18b6b2367a557425010ef995257e28ca1d96734382aa654)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x206c6b0e864976d0cf1af4f23cc0686c18413558fdad150df4da74e07872e469)
            mstore(mload(add(vk, 0x140)), 0x1a01eeee82d343d876b4768c9ff9d6556d46513d115678664f8f1c0d43afbbc3)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x25917c457c81d9f5f4b896233f6265b9d60a359af9df16956e4dbc09763c0bd6)
            mstore(mload(add(vk, 0x160)), 0x17b0ae9b0c736a1979ab82f54fb4d001170dfa76d006103f02c43a67dec91fb3)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x2c78125c1d76b79daae8fba3f3a32c1713ecb35bd66b0eebbc7196bfa52b9f57)
            mstore(mload(add(vk, 0x180)), 0x25e1b7ef083b39733b81eb0907e96f617f0fe98f23c5b02bc973433eae02ff77)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0a470bcbe5901d4889d389054d564a2449fa000fec23e0cbff8a1c5b0392152b)
            mstore(mload(add(vk, 0x1a0)), 0x0cd6a83b1c2ca031316875660a0b30c58e356b27cfe63f3d9cb912d128d6a3a5)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x29f1e77dc2a6d16f6208579b9e370864204c7099f05ac168c8b49f8d94e1eea5)
            mstore(mload(add(vk, 0x1c0)), 0x0b33f722b800eb6ccf5fd90efb0354b7093892f48398856e21720a5ba817bef4)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x1723e0bad06c4d46d4cb0d643a0634d1fb191a0315672eea80e0f0b909cb4721)
            mstore(mload(add(vk, 0x1e0)), 0x2c1e3dfcae155cfe932bab710d284da6b03cb5d0d2e2bc1a68534213e56f3b9a)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x1edf920496e650dcf4454ac2b508880f053447b19a83978f915744c979df19b9)
            mstore(mload(add(vk, 0x200)), 0x2419c069c1dfbf281accb738eca695c6ed185ff693668f624887d99cd9bef538)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x22aab8ee870b67caae4805504bcd2965e5eb5397f9c93299ed7081d1a2536578)
            mstore(mload(add(vk, 0x220)), 0x01850320a678501e3dc5aa919e578778d8360ac8ffbc737fb9d62c74bd7b3bf7)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x06baff0bb65569a45146269564e5f679cc9556816a4e6e62a9a822bfa3a9a568)
            mstore(mload(add(vk, 0x240)), 0x056cd85a7ef2cdd00313566df453f131e20dc1fe870845ddef9b4caad32cb87f)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x1504f7003446dd2a73b86683d89c735e11cc8aef3de93481ce85c8e70ecb3b22)
            mstore(mload(add(vk, 0x260)), 0x1e4573d2de1aac0427a8492c4c5348f3f8261f36636ff9e509490f958740b0a0)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x0a039078c063734e840576e905e6616c67c08253d83c8e0df86ca7a1b5751290)
            mstore(add(vk, 0x280), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 1550) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x2c0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x2c0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Types} from '../cryptography/Types.sol';
import {Bn254Crypto} from '../cryptography/Bn254Crypto.sol';

library EscapeHatchVk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 524288) // vk.circuit_size
            mstore(add(vk, 0x20), 26) // vk.num_inputs
            mstore(add(vk, 0x40),0x2260e724844bca5251829353968e4915305258418357473a5c1d597f613f6cbd) // vk.work_root
            mstore(add(vk, 0x60),0x3064486657634403844b0eac78ca882cfd284341fcb0615a15cfcd17b14d8201) // vk.domain_inverse
            mstore(add(vk, 0x80),0x06e402c0a314fb67a15cf806664ae1b722dbc0efe66e6c81d98f9924ca535321) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x1a3423bd895e8b66e96de71363e5c424087c0e04775ef8b42a367358753ae0f4)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x2894da501e061ba9b5e1e1198f079425eebfe1a2bba51ba4fa8b76df1d1a73c8)
            mstore(mload(add(vk, 0xc0)), 0x11f33e953c5db955d3f93a7e99805784c4e0ffa6cff9cad064793345c32d2129)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2061f0caa8fa3d35b65afa4bfa97f093b5ab74f62112436f54eebb254d005106)
            mstore(mload(add(vk, 0xe0)), 0x05c63dff9ea6d84930499309729d82697af5febfc5b40ecb5296c55ea3f5e179)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x270557e99250f65d4907e9d7ee9ebcc791712df61d8dbb7cadfbf1358049ce83)
            mstore(mload(add(vk, 0x100)), 0x2f81998b3f87c8dd33ffc072ff50289c0e92cbcd570e86902dbad50225661525)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x0d7dd6359dbffd61df6032f827fd21953f9f0c73ec02dba7e1713d1cbefe2f71)
            mstore(mload(add(vk, 0x120)), 0x14e5eedb828b93326d1eeae737d816193677c3f57a0fda32c839f294ee921852)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x0547179e2d2c259f3da8b7afe79a8a00f102604b630bcd8416f099b422aa3c0d)
            mstore(mload(add(vk, 0x140)), 0x09336d18b1e1526a24d5f533445e70f4ae2ad131fe034eaa1dad6c40d42ff9b5)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x04f997d41d2426caad28b1f32313d345bdf81ef4b6fcc80a273cb625e6cd502b)
            mstore(mload(add(vk, 0x160)), 0x238db768786f8c7c3aba511b0660bcd8de54a369e1bfc5e88458dcedf6c860a4)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x0814aa00e8c674f32437864d6576acb10e21706b574269118566a20420d6ed64)
            mstore(mload(add(vk, 0x180)), 0x080189f596dddf5feda887af3a2a169e1ea8a69a65701cc150091ab5b4a96424)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x16d74168928caaa606eeb5061a5e0315ad30943a604a958b4154dae6bcbe2ce8)
            mstore(mload(add(vk, 0x1a0)), 0x0bea205b2dc3cb6cc9ed1483eb14e2f1d3c8cff726a2e11aa0e785d40bc2d759)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x19ee753b148189d6877e944c3b193c38c42708585a493ee0e2c43ad4a9f3557f)
            mstore(mload(add(vk, 0x1c0)), 0x2db2e8919ea4292ce170cff4754699076b42af89b24e148cd6a172c416b59751)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x2bf92ad75a03c4f401ba560a0b3aa85a6d2932404974b761e6c00cc2f2ad26a8)
            mstore(mload(add(vk, 0x1e0)), 0x2126d00eb70b411bdfa05aed4e08959767f250db6248b8a20f757a6ec2a7a6c6)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0bd3275037c33c2466cb1717d8e5c8cf2d2bb869dbc0a10d73ed2bea7d3e246b)
            mstore(mload(add(vk, 0x200)), 0x264a4e627e4684e1ec952701a69f8b1c4d9b6dda9d1a615576c5e978bfae69eb)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x1a8d0fd1f1b1e55d82ffca8bcb96aff440c7d58c804eb8c997530c6448a74441)
            mstore(mload(add(vk, 0x220)), 0x0a4e05d11db2e3d857561c027fc69909922c83266c23913cc0716e4f3e20b01c)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x2f4fd5534086a603cdff53bb3e2c40f4cae85839fc13cc4cf8aae8dba9b4265a)
            mstore(mload(add(vk, 0x240)), 0x229d17f3ba3fe020cb02be60ae11a9a9cc5b625240edd6af8c21689af9d9e4f5)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2408b183ac099721fe9ddfb0c51c1c7d6305441aefdc1510d306027f22000f70)
            mstore(mload(add(vk, 0x260)), 0x1d928372dc4405e422924f1750369a62320422208422c7a8ddf22510fe3301a3)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x003f0e42598c2979879084939dd681db21471e29c009760079f8fde72ae59de4)
            mstore(add(vk, 0x280), 0x00) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 0) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x2c0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x2c0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

{
  "evmVersion": "istanbul",
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {
    "contracts/verifier/keys/VerificationKeys.sol": {
      "VerificationKeys": "0x23fa5ee28ec29659c47ddbe6c6b16242e40e3f88"
    }
  }
}