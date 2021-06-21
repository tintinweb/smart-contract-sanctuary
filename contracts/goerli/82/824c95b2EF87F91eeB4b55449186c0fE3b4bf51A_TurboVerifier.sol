/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

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
contract TurboVerifier {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;
    using TranscriptLibrary for TranscriptLibrary.Transcript;

    // The first parameter is the proof and the second parameter is the public inputs
    function verify(bytes calldata, bytes calldata) public view returns (bool) {
        
        Types.VerificationKey memory vk = get_verification_key();
        uint256 num_public_inputs = vk.num_inputs;

        // parse the input calldata and construct a Proof object
        Types.Proof memory decoded_proof = deserialize_proof(num_public_inputs, vk);

        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript(
            vk.circuit_size,
            vk.num_inputs
        );

        // reconstruct the beta, gamma, alpha and zeta challenges
        Types.ChallengeTranscript memory challenges;
        transcript.get_beta_gamma_challenges(challenges, vk.num_inputs);
        transcript.update_with_g1(decoded_proof.Z);
        challenges.alpha = transcript.get_challenge();
        challenges.alpha_base = challenges.alpha;
        transcript.update_with_four_g1_elements(
            decoded_proof.T1,
            decoded_proof.T2,
            decoded_proof.T3,
            decoded_proof.T4
        );
        challenges.zeta = transcript.get_challenge();


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
        transcript.get_nu_challenges(decoded_proof.quotient_polynomial_eval, challenges);
        transcript.update_with_g1(decoded_proof.PI_Z);
        transcript.update_with_g1(decoded_proof.PI_Z_OMEGA);
        challenges.u = transcript.get_challenge();

        //reset 'alpha base'
        challenges.alpha_base = challenges.alpha;

        Types.G1Point memory partial_opening_commitment = PolynomialEval.compute_linearised_opening_terms(
            challenges,
            L1,
            vk,
            decoded_proof
        );

        Types.G1Point memory batch_opening_commitment = PolynomialEval.compute_batch_opening_commitment(
            challenges,
            vk,
            partial_opening_commitment,
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
        return result;
    }

    
    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 65536) // vk.circuit_size
            mstore(add(vk, 0x20), 34) // vk.num_inputs
            mstore(add(vk, 0x40),0x00eeb2cb5981ed45649abebde081dcff16c8601de4347e7dd1628ba2daac43b7) // vk.work_root
            mstore(add(vk, 0x60),0x30641e0e92bebef818268d663bcad6dbcfd6c0149170f6d7d350b1b1fa6c1001) // vk.domain_inverse
            mstore(add(vk, 0x80),0x0b5d56b77fe704e8e92338c0082f37e091126414c830e4c6922d5ac802d842d4) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x013ceee696f2968678b47d9e6d155adf4edf674172c371ae505b23d6526e81e7)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x11a757e9598c89d6ab27eaf46788344130ed84ee61f1716b703ec0876de00fe6)
            mstore(mload(add(vk, 0xc0)), 0x06c358f6a8d8e556ca85472ad5760b9c5d71ff32c8649a5bfddc2e8ba6473d92)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2047456f675e6cbe859e0242aeddecacb2efa33a288653f69c5f49d0a031bb1a)
            mstore(mload(add(vk, 0xe0)), 0x2491a60d5fef54ed632900a2ead7a27b5b08c3e1bf1a655d24795fe249e981f5)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x065469966fbeb873d8d788d0b75ed3b67874ce2ce58b288b61a97d56e3558232)
            mstore(mload(add(vk, 0x100)), 0x2c1698613d1890de132145e07401773404e4e0e42458d8a832e57c759ba99f4e)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x03ab6cbe028c1f108ff27964084debbd7d11564aa63a6685e8d5212c07abc8c4)
            mstore(mload(add(vk, 0x120)), 0x19ab7d0119b2ee6f68508da76665a278a38f7bf4ab93cbbaf487dcfe649ead01)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x01ceb12c444a46254a9a8c831fc2a07eff526a3240149c19fe21106e40e86100)
            mstore(mload(add(vk, 0x140)), 0x2f2e6af645a46ba40affdde86c5fce4620778844aff2496cab2f5023a8a37a58)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2edfe71116b94bf6d1e63a5d1bda2c1fbbf65fefa0b3998c4cb1ba304fca2064)
            mstore(mload(add(vk, 0x160)), 0x168bf6301244a4a1e091c887cc96913ac843b2940ef942a8233e67e54647a605)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1c17f5e5c47a0db41eabadfb8c602fcb434b6b4452129df459a01223c56819fb)
            mstore(mload(add(vk, 0x180)), 0x0c384ea42a416724a450e7533f889336709422aa6f00eada610084bd7f5f2f4a)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0d0a5208d52c188285f66444721ef8514f2cd98c171d4fb39f5aea625a1d17ae)
            mstore(mload(add(vk, 0x1a0)), 0x0df1ca06c4bbc77e7949965850348385f79d8a45673364c4fc299a9b969d381d)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x0ec17c451f7143c2df5576839e8b5fe7703963f65c8ef569c288396fcf52a43b)
            mstore(mload(add(vk, 0x1c0)), 0x0949a3eb36db1a0565bdc022d49d1f84ff034e38a94a6a0b2f5977dc9c354584)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x01c6909c7815789fb5c44d997eb06b6a8f345bee85ac5ea56ec4733d673dbf7d)
            mstore(mload(add(vk, 0x1e0)), 0x0284fe3baf75abe2cc41f69ccaa599900a2aa95020bb1b8b228379523299afd4)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x1cdf9102ae0ff637d9f4f74aeebdaf65680f1fd75154e5dc4571ba62dbc8a837)
            mstore(mload(add(vk, 0x200)), 0x1cbcac6170d456c9d4cdcece0328fdabc63d2bdb508584b50da92724d315c2cc)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x19acb4d60d9cea3a6ad03e3797ce1da00d5ef177853eb78804e894d7e4d32b12)
            mstore(mload(add(vk, 0x220)), 0x059869c72c12a324a0f65eb5f28b6d90ae8d43d4c7e70cfc7b4d3776f3f2e6fc)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x105195da1ace1ab81b16940aebb48e06aaa7c40297d84a954e52f0ae6413967b)
            mstore(mload(add(vk, 0x240)), 0x2d4e65edffc12926f6f254e4c69df0e99905b2b44b65bb904152a4e7f6fbe3c5)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x21e1d2c2e53599e0cdc4493e79adf154b39d99106861d11ccb9c01ee3eedb8eb)
            mstore(mload(add(vk, 0x260)), 0x06bddcf79944337e8d3658c78912528bf59c62e328bd14ccf1a6b045f0edcc5f)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x1d0d02ed81516f2a3e7e93eddde9ec19117607e9f0a518a3953295a3acdd0215)
            mstore(add(vk, 0x280), 0x00) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 0) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x2c0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x2c0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
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
                index_counter := add(index_counter, add(calldataload(0x24), 0x04))
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




/**
 * @title TurboPlonk verification algo implementation
 * @dev Implements the Turbo Plonk verification algorithm, through the use of five functions that
 * calculate challenges, setup initial state, evaluate the necessary polynomials and executes the pairing
 * check.
 *
 * Expected to be inherited by `Verifier.sol`
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
library TurboPlonk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;
    using TranscriptLibrary for TranscriptLibrary.Transcript;

    /**
     * @dev Evaluate the various remaining polynomials: partial_opening, batch_opening, batch_evaluation
     * @param decoded_proof - deserialised proof
     * @param vk - verification key
     * @param challenges - all challenges (alpha, beta, gamma, zeta, nu[NUM_NU_CHALLENGES], u) stored in
     * ChallengeTranscript struct form
     * @param L1 - lagrange 1 evaluation
     * @return batch_opening commitment and batch_evaluation commitment, both represented as G1 Points
     */
    function evaluate_polynomials(
        Types.Proof memory decoded_proof,
        Types.VerificationKey memory vk,
        Types.ChallengeTranscript memory challenges,
        uint256 L1
    ) internal view returns (Types.G1Point memory, uint256) {
        Types.G1Point memory partial_opening_commitment = PolynomialEval.compute_linearised_opening_terms(
            challenges,
            L1,
            vk,
            decoded_proof
        );

        Types.G1Point memory batch_opening_commitment = PolynomialEval.compute_batch_opening_commitment(
            challenges,
            vk,
            partial_opening_commitment,
            decoded_proof
        );


        uint256 batch_evaluation_g1_scalar = PolynomialEval.compute_batch_evaluation_scalar_multiplier(
            decoded_proof,
            challenges
        );

        return (batch_opening_commitment, batch_evaluation_g1_scalar);
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
     * @dev Calculate the alpha, beta, gamma and zeta challenges
     * Makes use of the Transcript library
     * @param decoded_proof - deserialised proof
     * @param vk - verification key
     * @return challenge transcript containing alpha, beta, gamma, zeta and seperately the
     * general helper transcript containing the data necessary future challenges
     */
    function construct_alpha_beta_gamma_zeta_challenges(
        Types.Proof memory decoded_proof,
        Types.VerificationKey memory vk
    ) internal pure returns (Types.ChallengeTranscript memory, TranscriptLibrary.Transcript memory) {
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript(
            vk.circuit_size,
            vk.num_inputs
        );

        Types.ChallengeTranscript memory challenges;

        transcript.get_beta_gamma_challenges(challenges, vk.num_inputs);
        transcript.update_with_g1(decoded_proof.Z);
        challenges.alpha = transcript.get_challenge();
        challenges.alpha_base = challenges.alpha;

        transcript.update_with_four_g1_elements(
            decoded_proof.T1,
            decoded_proof.T2,
            decoded_proof.T3,
            decoded_proof.T4
        );
        challenges.zeta = transcript.get_challenge();

        return (challenges, transcript);
    }

    /**
     * @dev Calculate the remaining challenges: nu[] and u.
     * For Turbo PLONK, 11 challenges are calculated. Makes use of the Transcript library
     *
     * @param decoded_proof - deserialised proof
     * @param transcript - general transcript containing the data necessary to calculate subsequent
     * challenges
     * @param challenges - challenge transcript containing alpha, beta, gamma, zeta
     * @return challenge transcript containing the original challenges, together with the calculated
     * nu's and u challenges
     */
    function construct_nu_u_challenges(
        Types.Proof memory decoded_proof,
        TranscriptLibrary.Transcript memory transcript,
        Types.ChallengeTranscript memory challenges
    ) internal pure returns (Types.ChallengeTranscript memory) {

        transcript.get_nu_challenges(decoded_proof.quotient_polynomial_eval, challenges);


        transcript.update_with_g1(decoded_proof.PI_Z);
        transcript.update_with_g1(decoded_proof.PI_Z_OMEGA);
        challenges.u = transcript.get_challenge();

        return challenges;
    }
}
    
    
    


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

        uint256 endpoint = (vk.num_inputs * 0x20) - 0x60;
        uint256 public_inputs;
        uint256 accumulating_root = challenges.beta;
        uint256 numerator_value = 1;
        uint256 denominator_value = 1;

        // we multiply length by 0x20 because our loop step size is 0x20 not 0x01
        // we subtract 0x60 because our loop is unrolled 4 times an we don't want to overshoot

        // perform this computation in assembly to improve efficiency. We are sensitive to the cost of this loop as
        // it scales with the number of public inputs
        uint256 p = Bn254Crypto.r_mod;
        assembly {
            public_inputs := add(calldataload(0x24), 0x24)

            // get public inputs from calldata. N.B. If Contract ABI Changes this code will need to be updated!
            endpoint := add(endpoint, public_inputs)
            // Do some loop unrolling to reduce number of conditional jump operations
            for {} lt(public_inputs, endpoint) {}
            {
                let N0 := add(mulmod(accumulating_root, 0x05, p), addmod(calldataload(public_inputs), gamma, p))
                let D0 := add(mulmod(accumulating_root, 0x07, p), N0)

                accumulating_root := mulmod(accumulating_root, work_root, p)

                let N1 := add(mulmod(accumulating_root, 0x05, p), addmod(calldataload(add(public_inputs, 0x20)), gamma, p))
                let D1 := add(mulmod(accumulating_root, 0x07, p), N1)

                accumulating_root := mulmod(accumulating_root, work_root, p)

                let N2 := add(mulmod(accumulating_root, 0x05, p), addmod(calldataload(add(public_inputs, 0x40)), gamma, p))
                let D2 := add(mulmod(accumulating_root, 0x07, p), N2)

                accumulating_root := mulmod(accumulating_root, work_root, p)

                let N3 := add(mulmod(accumulating_root, 0x05, p), addmod(calldataload(add(public_inputs, 0x60)), gamma, p))

                denominator_value := mulmod(mulmod(mulmod(mulmod(D2, D1, p), D0, p), denominator_value, p), add(N3, mulmod(accumulating_root, 0x07, p)), p)
                numerator_value := mulmod(mulmod(mulmod(mulmod(N3, N2, p), N1, p), N0, p), numerator_value, p)

                accumulating_root := mulmod(accumulating_root, work_root, p)

                public_inputs := add(public_inputs, 0x80)
            }

            endpoint := add(endpoint, 0x60)
            for {} lt(public_inputs, endpoint) { public_inputs := add(public_inputs, 0x20) }
            {
                let T0 := addmod(calldataload(public_inputs), gamma, p)
                numerator_value := mulmod(
                    numerator_value,
                    add(mulmod(accumulating_root, 0x05, p), T0), // 0x05 = coset_generator0
                    p
                )
                denominator_value := mulmod(
                    denominator_value,
                    add(mulmod(accumulating_root, 0x0c, p), T0), // 0x0c = coset_generator7
                    p
                )
                accumulating_root := mulmod(accumulating_root, work_root, p)
            }
        }
        
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

    
    
    

/**
 * @title Challenge transcript library
 * @dev Used to collect the data necessary to calculate the various challenges: beta, gamma, alpha, zeta, nu[7], u
 */
library TranscriptLibrary {
    // When creating `transcript.data` we pre-allocate all the memory required to store the entire transcript, minus public inputs
    uint256 constant NUM_TRANSCRIPT_BYTES = 1248;

    struct Transcript {
        bytes data;
        bytes32 current_challenge;
        uint32 challenge_counter;
        uint256 num_public_inputs;
    }

    /**
     * Instantiate a transcript and calculate the initial challenge, from which other challenges are derived.
     *
     * Resembles the preamble round in the Plonk prover
     */
    function new_transcript(uint256 circuit_size, uint256 num_public_inputs)
        internal
        pure
        returns (Transcript memory transcript)
    {
        transcript.current_challenge = compute_initial_challenge(circuit_size, num_public_inputs);
        transcript.challenge_counter = 0;

        // manually format the transcript.data bytes array
        // This is because we want to reserve memory that is greatly in excess of the array's initial size
        bytes memory transcript_data_pointer;
        bytes32 transcript_data = transcript.current_challenge;
        uint256 total_transcript_bytes = NUM_TRANSCRIPT_BYTES;
        assembly {
            transcript_data_pointer := mload(0x40)
            mstore(0x40, add(transcript_data_pointer, total_transcript_bytes))
            // update length of transcript.data
            mstore(transcript_data_pointer, 0x20)
            // insert current challenge
            mstore(add(transcript_data_pointer, 0x20), transcript_data)
        }
        transcript.data = transcript_data_pointer;
        transcript.num_public_inputs = num_public_inputs;
    }

    
    /**
     * Compute keccak256 hash of 2 4-byte variables (circuit_size, num_public_inputs)
     */
    function compute_initial_challenge(uint256 circuit_size, uint256 num_public_inputs) internal pure returns (bytes32 challenge) {
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
    }

    /**
     * Add a uint256 into the transcript
     */
    function update_with_u256(Transcript memory self, uint256 value) internal pure {
        bytes memory data_ptr = self.data;
        assembly {
            // update length of transcript data
            let array_length := mload(data_ptr)
            mstore(data_ptr, add(0x20, array_length))
            // insert new 32-byte value at the end of the array
            mstore(add(data_ptr, add(array_length, 0x20)), value)
        }
    }

    /**
     * Add a g1 point into the transcript
     */
    function update_with_g1(Transcript memory self, Types.G1Point memory p) internal pure {
        // in the C++ prover, the y coord is appended first before the x
        bytes memory data_ptr = self.data;
        assembly {
            // update length of transcript data
            let array_length := mload(data_ptr)
            mstore(data_ptr, add(0x40, array_length))
            // insert new 64-byte value at the end of the array
            mstore(add(data_ptr, add(array_length, 0x20)), mload(add(p, 0x20)))
            mstore(add(data_ptr, add(array_length, 0x40)), mload(p))
        }
    }


    /**
     * Add a g1 point into the transcript
     */
    function update_with_four_g1_elements(
        Transcript memory self,
        Types.G1Point memory p1,
        Types.G1Point memory p2,
        Types.G1Point memory p3,
        Types.G1Point memory p4
    ) internal pure {
        // in the C++ prover, the y coord is appended first before the x
        bytes memory data_ptr = self.data;
        assembly {
            // update length of transcript data
            let array_length := mload(data_ptr)
            mstore(data_ptr, add(0x100, array_length))
            data_ptr := add(data_ptr, array_length)
            // insert new 64-byte value at the end of the array
            mstore(add(data_ptr, 0x20), mload(add(p1, 0x20)))
            mstore(add(data_ptr, 0x40), mload(p1))
            mstore(add(data_ptr, 0x60), mload(add(p2, 0x20)))
            mstore(add(data_ptr, 0x80), mload(p2))
            mstore(add(data_ptr, 0xa0), mload(add(p3, 0x20)))
            mstore(add(data_ptr, 0xc0), mload(p3))
            mstore(add(data_ptr, 0xe0), mload(add(p4, 0x20)))
            mstore(add(data_ptr, 0x100), mload(p4))
        }
    }

    /**
     * Append byte
     */
    function append_byte(Transcript memory self, uint8 value) internal pure {
        bytes memory data_ptr = self.data;
        uint256 array_length = 0;
        assembly {
            // update length of transcript data
            array_length := mload(data_ptr)
            mstore(data_ptr, add(0x01, array_length))
            // insert new 1-byte value at the end of the array
            mstore8(add(data_ptr, add(array_length, 0x20)), value)
        }
    }

    /**
     * Reset challenge array to equal a single bytes32 value
     */
    function reset_to_bytes32(Transcript memory self, bytes32 value) internal pure {
        bytes memory data_ptr = self.data;
        {
            assembly {
                mstore(data_ptr, 0x20)
                mstore(add(data_ptr, 0x20), value)
            }
        }
    }

    /**
     * Draw a challenge
     */
    function get_challenge(Transcript memory self) internal pure returns (uint256) {
        bytes32 challenge;
        bytes memory data_ptr = self.data;
        assembly {
            let length := mload(data_ptr)
            challenge := keccak256(add(data_ptr, 0x20), length)
        }
        self.current_challenge = challenge;

        // reset self.data by setting length to 0x20 and update first element
        {
            assembly {
                mstore(data_ptr, 0x20)
                mstore(add(data_ptr, 0x20), challenge)
            }
        }
        uint256 p = Bn254Crypto.r_mod;
        assembly {
            challenge := mod(challenge, p)
        }
        return (uint256)(challenge);
    }

    /**
     * We treat the beta challenge as a special case, because it includes the public inputs.
     * The number of public inputs can be extremely large for rollups and we want to minimize mem consumption.
     * => we directly allocate memory to hash the public inputs, in order to prevent the global memory pointer from increasing
     */
    function get_beta_gamma_challenges(
        Transcript memory self,
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
            let inputs_start := add(calldataload(0x24), 0x24) // start of call data
            let num_calldata_bytes := mul(num_public_inputs, 0x20)
            calldatacopy(m_ptr, inputs_start, num_calldata_bytes)

            inputs_start := add(calldataload(0x04), 0x24) // start of proof data
            calldatacopy(add(m_ptr, num_calldata_bytes), inputs_start, 0x100)

            let start := mload(0x40)
            let length := add(num_calldata_bytes, 0x120)

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

        bytes memory data_ptr = self.data;
        self.current_challenge = challenge;

        // reset self.data by setting length to 0x20 and update first element
        {
            assembly {
                mstore(data_ptr, 0x20)
                mstore(add(data_ptr, 0x20), challenge)
            }
        }
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
    function get_nu_challenges(Transcript memory self, uint256 quotient_poly_eval, Types.ChallengeTranscript memory challenges) internal pure
    {
        // get a calldata pointer that points to the start of the data we want to copy
        uint256 calldata_ptr;
        assembly {
            calldata_ptr := add(calldataload(0x04), 0x24)
        }
        // There are NINE G1 group elements added into the transcript in the `beta` round, that we need to skip over
        assembly {
            calldata_ptr := add(calldata_ptr, 0x240) // 9 * 0x40 = 0x240
        }

        uint256 p = Bn254Crypto.r_mod;
        bytes memory data_ptr = self.data;
        uint256 base_v_challenge;
        uint256 updated_v;

        // We want to copy SIXTEEN field elements from calldata into memory to hash
        // But we start by adding the quotient poly evaluation to the hash transcript
        assembly {
            mstore(add(data_ptr, 0x40), quotient_poly_eval)
            calldatacopy(add(data_ptr, 0x60), calldata_ptr, 0x200) // 16 * 0x20 = 0x200
            base_v_challenge := keccak256(add(data_ptr, 0x20), 0x240) // hash length = 0x240, we include the previous challenge in the hash
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

            mstore(data_ptr, 0x20)
            mstore(add(data_ptr, 0x20), challenge)
            updated_v := mod(challenge, p)
        }
        challenges.v10 = updated_v;

        self.current_challenge = challenge;
    }
}