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
            mstore(mload(add(vk, 0xa0)), 0x25390913c5974bef766a8a0a5af782fd039ea5a9d4aede2817f02e14ab4114fc)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x29c5965cb93f7aa8643c83a476e1749cdc4c85c341985dd0d54fcd5dc8398dd7)
            mstore(mload(add(vk, 0xc0)), 0x1ed06fb9a009077b7c15c493e8f9162358315fbe652eeec9e6988502a3b288bb)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1f0b1a5f5aaa31de8ae34f347dac987223c6a44864f661da2ff2af14b4a1633e)
            mstore(mload(add(vk, 0xe0)), 0x23afd4cdb91cad9f2e429746bcff16aab228215dfa9ccc5d88c50c0bed5b9cc2)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x1ef69796c6c4fd141a2d530ee25cb1fe131f41077ec6f0fa0235f09db131faa5)
            mstore(mload(add(vk, 0x100)), 0x0553053cf7758173616ce52d05ec4066641460c1066b4c7e3672afe4fd4c46c8)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x1e749f044086c2c3e7120c55ffb60f0a6fb5ad673d5eb6b7d73d4e76d26be615)
            mstore(mload(add(vk, 0x120)), 0x0556c56f8fe9d1ef2c2853af88e15d4953cda8df68e52cb9f2938ebf8bde2386)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x2593139c74bf4bb4c619a4a33bd0bf08157b74e580402a2c6a1da77655e83f9c)
            mstore(mload(add(vk, 0x140)), 0x12cf6657075c75a14a946b9d425ccd820559880ae0206021bf4abb3f1f5e0a17)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x0afd2353a51dbdf875b309a60abec2e7d2a9a12e51940c7183439a499a677cab)
            mstore(mload(add(vk, 0x160)), 0x16a4029e1e2e59bc439be2a4a4c6cd7dbc6eaded01ad77e927473da544334d4b)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1341ff4007a01fa22fee33bed0eb97fb9c0134c46af0beb0d346bcb64c995552)
            mstore(mload(add(vk, 0x180)), 0x0c49ae172cde337f14194fb4212e6323f3db82f072dc45d8a450f6daa7d3e28d)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2feeed427a0e59d56eac80d43d9301e991d452843830e72daf74d3d2fbe62896)
            mstore(mload(add(vk, 0x1a0)), 0x0c3aad92b1b550f3463bd61fbb53b170e29d11fcf3860d951b28cc8de2a35492)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x2bad1fa40eea00506addb334f7f7e43878973bfdee9b2bf456728194b788560f)
            mstore(mload(add(vk, 0x1c0)), 0x0b93e156f18ebfb463fce04e6ba1453678ab69d9884f45c813fa22767795ef14)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x112fa28bc39356ab856101e2b0df0174431760ae68f1f70400988c9fbad95695)
            mstore(mload(add(vk, 0x1e0)), 0x2b3f5a828b5461b20bca52d88120c7ea369b6668ff3e1147f7fd1a757c023acb)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x1fa613eadf21d222bf645feaf9725ddf7b3d8cfc159d93b34eab566ec434ee75)
            mstore(mload(add(vk, 0x200)), 0x09efeb79dc4e5bef5049cd5277ba72c70c3c031dc3be10b9e14d7c7cbe892c09)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x25f642d818e63e3995b648fafc0bb3dd2262dffa2df84d812a19f961cfc32499)
            mstore(mload(add(vk, 0x220)), 0x253bf04a86bdd932ad28a4bfcd24c12a6e323e062fb2da87fcb27cc5f4749d6e)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x041257f354014c3bce8c9ed77cc59ed5dc3255968c1e3429f8df3739830fb0d3)
            mstore(mload(add(vk, 0x240)), 0x07a6273dc71e924da1df2ddc8ad9d2c4443e6ad2993577d5c80e75be552054dc)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2a49f5d39753cd4802085148daf223255aadfe1bd2a49e066068e1f8821222bc)
            mstore(mload(add(vk, 0x260)), 0x13d877bb601c49c90ed7307af3f44c2efc044d9646e3693445dbfc64ab2d592b)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x06626487231796f1a9461d540c3fcb0bd58cf426c05e440af81392f15e180ee6)
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
            mstore(mload(add(vk, 0xa0)), 0x23b18f118d2ef765ccfa0a5812bd14cdf7b87118c2af484bdf130029a003a0a5)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x2c9e42fcfa56de2ab6e6daacbb80c74410c862e0cb6d44e242cc30cd5f27bdf7)
            mstore(mload(add(vk, 0xc0)), 0x0e4dc6a44d20baf5e5de2d9afc679424e3c241ac839eb2e2d6f1e4078a94b567)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x27f968689ec1fa94d4927417b80d04636fc29d98454f5feee43d9c804fddd8de)
            mstore(mload(add(vk, 0xe0)), 0x115e8204fb6002583e9789ab4311ef3d23b72feeeb89e70351fab189822a73ea)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x2c1a9ed72e58ed72346aa7a4fdad90ad27ea5dc4aaa4a026e82619f52f8f1630)
            mstore(mload(add(vk, 0x100)), 0x0097d095d906a325f5c55f76509799978cc1085354831e36e52e44994d863dbe)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x03eccbbe0316541ee1193b7d6a59cf0cc8ffd136fa0094e26dad4c2d37abc46a)
            mstore(mload(add(vk, 0x120)), 0x1382dde7b35afbd2c6977acec5f2780f3c9824d53e7625e0f7c4c82552aceb2b)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x0077895d92313fe4d94434a9a256924e02755faeea085baaeca822f1ff3b72ff)
            mstore(mload(add(vk, 0x140)), 0x15d84e93edf3bef23ef2595a9d1cf9a39b66ad7356c744bd46fb8af6988f014f)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x04a4a7cc4a1a8bbccb449c3ca568efa2e6dfd331ca81021ad94fbcd539b0180a)
            mstore(mload(add(vk, 0x160)), 0x06b8a1b17cea2b870c6675cd767f05bc4135398bbc6df67cfc7d44b782451906)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1d6445659ac7a3829146adb820757d70d77d97bca056223bea7834b548c49cf2)
            mstore(mload(add(vk, 0x180)), 0x15349076a8245067cb48dbb42d991ad5d818107c4db91488b3a660b883bb5ef8)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2cb0c46dcbe4d299f149cd0dffea61f2c24509d0e3d5f4dea32edb47c720ba63)
            mstore(mload(add(vk, 0x1a0)), 0x16f07bf189dba77a9e5704294e0a19a2ff17466de784b1a68e0b46592ed397d0)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1e2ae5ef84c0f59ef1b6584b6ae4ad58e8f9d6a2d6b40950436140381d80a24f)
            mstore(mload(add(vk, 0x1c0)), 0x0a3114789cb047c7d2f3ac3b3d388ce4716994b3f5a29a6110e2501702b28693)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x0abecbbe4e0ecc895f0d9685b7c474db481a51dea9ed2891bd5447a4c59543b0)
            mstore(mload(add(vk, 0x1e0)), 0x1e029cb97dbf87a2b9481e09b2473619e9ab1527792d4829f70c4ac465ff5675)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x26b72df0bd74390e3381fd07a784d4a0573ee7a2d9facbb43cea8ff77c27b5b3)
            mstore(mload(add(vk, 0x200)), 0x27fe2743ae56746b442911cfc9724c2990520bf7ea24ce6f34a1756b578c0f0b)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x1ffbee2320167e7271b408a2ae45d807681e54b16fcdf108a5699bffe174399b)
            mstore(mload(add(vk, 0x220)), 0x07ea6f90f32b9cc82599c222799758502cff4979ab8b58a315df578024cb8887)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x0aa4856710d0463f8dde53e6ae60e229294247c1b2dc3ae0fb1b733097b71a29)
            mstore(mload(add(vk, 0x240)), 0x2083ea49d5a291e2e4080f6bc47e524da357c2e66a2992097a1c28370aa8ec95)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x0addf3187fadf8ceedb571ec1ce443f1bb88938eb7d5238ecec921db26d9068b)
            mstore(mload(add(vk, 0x260)), 0x12a5226bd23b425c150584ee6227037d214859ac0394009b883e3994d1a7e8ee)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x14f5e7b1f11c8b3693e6f80efdf6fcdedc8980be06c3ec9502a6e80ec6f5e2be)
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
            mstore(mload(add(vk, 0xa0)), 0x0ed021ab3dea29e98ed85f24aa9ababbf5d9b238b35881f67e5a7aa8e1c71066)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x144b423d5bc9e43c5c7a4ca9a8d01189291f9a9cbd28dcbf354091bfe5a35baa)
            mstore(mload(add(vk, 0xc0)), 0x29e3cc9f176a2d860ddfcb6bae60377708e2eb37d7d885988c1e8b6d55ec4493)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x18d5daaf59c77f53eff3a08fe0a42d20ac4fb454b40e09593437505f75fbe119)
            mstore(mload(add(vk, 0xe0)), 0x2f8506e26ed387a5b9e4efd8740091b5359b8395ab5ae9ecee5b0f055e54ec94)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x2faa158af12b620c0a4e700ae6ee1bdfcfb6dc18ad13669dbf682da9c0e6be2b)
            mstore(mload(add(vk, 0x100)), 0x2fa760fc1f22dd4ddeded0de4fa1583c4a07e8a75408cb0ef82acad1f0b944f4)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x14939eb8544b267ba56418f13037baeda119c7ad3d755adccdf749bbbfb64fdd)
            mstore(mload(add(vk, 0x120)), 0x12bc548020f5c62776903c212b5fa4fb3f45913ea4f5f574dded11cb874232c1)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x1f7008d3734759230d9c766e2b96b3bf78aa16f8250baedb0449943d910fe422)
            mstore(mload(add(vk, 0x140)), 0x205179393446c2c31c1857dc83a83328f9e497c10dc41dc7a9cb01663839baa8)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x0521129ae5b7e06fd9dc8920514a1aab95a3aac63a185cc2a3739b094dc92f33)
            mstore(mload(add(vk, 0x160)), 0x05df62d41e85edb98d278100e569de5e7d11b20c2f4dccc1f30aeaff05ec594e)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x09842b41f1c42dd514348aa40dc87898af9b59567fc38d40e224ba10c93f7849)
            mstore(mload(add(vk, 0x180)), 0x033f2d3a75d0ad536533f2ed78975d303359a3f06cc3de95c04e2658c14c6e71)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2ff32f8002a37d230d705d1de15a9131fbbc99f64ad27d9794f8ac99d0aa3cbe)
            mstore(mload(add(vk, 0x1a0)), 0x1add2c3d44c4a72cfe07d898a44eee527b2b3bf384a619e2b595585cb4a4f7ac)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x2ed61a90fd7cc96eae92b9f1eced79a8d2222febe5a91aeb2c26e8dc3f19311d)
            mstore(mload(add(vk, 0x1c0)), 0x101f90828e51262448cf1e7270ad0cd43898c7058a407c84c714eafae496310d)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x2c157732042d89ac2727e882dc68a149243e470b823250530461256f8258e592)
            mstore(mload(add(vk, 0x1e0)), 0x11aff31b1da1fbb3d8ae090ce00085de4673b4c1ca5c45f5c13f23ef00ee2d98)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x12e4d1363e3b7a4c73424b51b05009c24b646044f807367ecf77b28b4e5aa259)
            mstore(mload(add(vk, 0x200)), 0x087be8860385e0dd844820fa5950df81c018e4a7ede654437c5b7e06755a46ac)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x185b5541f0702802a78ae4ff30c267541177662fecfc4124a58edeb580d3945d)
            mstore(mload(add(vk, 0x220)), 0x26ebe4dc163030178ace75e723f6a0e5e2faed1a4c507945704a4e4c62c2df24)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x0ff9ad1cb34f0b5c83aec890fe37fde9b8c45800466622e99a90019e9f2b650b)
            mstore(mload(add(vk, 0x240)), 0x1c26ef44451575098e3829fa64a7ffaa0ffa788a8bdab825ea6b5069cb9d213c)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x02b61d5e296349b10b8393dfe85440139eefae5f9565760c58d7621c37627308)
            mstore(mload(add(vk, 0x260)), 0x21e92d332387e853889b36ce394f3e2d1d392b0c4736227774b557e08b9a4132)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x1136b489b5e13b32bc8e0c9fd0853f66f69db643641e29a8f2d7d5d395868192)
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
            mstore(mload(add(vk, 0xa0)), 0x0751c67ecac7630a454686c1e54d2fb210880eb514a8e04ab68978c29e81b63e)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x229073c6c73d1fe0146728ffa776eedba952df17e36b4dcc7d2c68e796700202)
            mstore(mload(add(vk, 0xc0)), 0x2c006b7cd574e2315daf5f7f85f76dcb5d207dd85f29cfef533c373133a074bb)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x026ea93a619a0065e76790e2a2ad3ad1f0622587cdd1d16231e647d4a9829131)
            mstore(mload(add(vk, 0xe0)), 0x1d836b3fc13b60528d821bc84eaeab2b9ac5709bf4486f176d14b728f72e8f92)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x2479b155d25d75fadd33d5a222d2bc78a95edac75d82356456f922b11abc0c74)
            mstore(mload(add(vk, 0x100)), 0x112739abf96fa79269e3f7a5ebe9fdac18fa8348607512a8daf50482900e2f71)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x0a00a416def762930f47389664ad263caeec3c5de87a0f3542a9032d00168da2)
            mstore(mload(add(vk, 0x120)), 0x20a5dc08944e7d234cfa2b44a017176ea71530a6121382d2f7a7f4754c4a2278)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x258fe4c31ae2e285fa0f58a1510c562c50d01c4258bd6f2e5f4e3171c6e1944c)
            mstore(mload(add(vk, 0x140)), 0x2b01a26299cfa17da8198035e62e67e305515d3ec3391daa7200aa64fd0d7a36)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x3000d28c6608d2698782234a1603bf41b8a355f635aab5906eaacefc7a2003b8)
            mstore(mload(add(vk, 0x160)), 0x286a29d8f6494b29dccc4ea3c4528ae03f656b06027c0d86ff58655192fc2f6f)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x095233e57d3feadb033abe1346412880387f44668a853e43b542193d4016ae55)
            mstore(mload(add(vk, 0x180)), 0x06442ed9ed579f0f8b28f49662ab0e2b250b0f3f4a3e6ba6d2598518fd4fb859)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2afa59017b5c64caab8c2f24044d3daaf4788ef7a969501add766b713320f755)
            mstore(mload(add(vk, 0x1a0)), 0x0d2385327495b57f93ab894a1283b858851bd59a7f52939bbe41f1a69fc0ce7f)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x0df576d367982f76746d342891035efef57dc0bc3210796f944b1ee75366d452)
            mstore(mload(add(vk, 0x1c0)), 0x15cdeffede1717b81a6b908fb7e73c7c566b41ec9e7a5cf9122a00833a7198c6)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x0e3e9328db1a3a30c06f71a4610f74b0a83eef8423a687a53d5aec0a889c810a)
            mstore(mload(add(vk, 0x1e0)), 0x109b01ea2bfde695e0ba94225224af50d06e907206c1d7990447716b5e4a743e)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x2c3564edafae943b8b3bc7cd9e7a14ef02d605725bbbdc11d43c78265f920f2d)
            mstore(mload(add(vk, 0x200)), 0x143bb1fe980ed9a77d8371b6781a11e15ed50f7fa55ff0f87ea39383535bd070)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x040ea0b6f74d815e74c42df01e4a20bb25cb961af713dbd953061fb111167123)
            mstore(mload(add(vk, 0x220)), 0x0d6e6bc16cad2acedb3c9d6d920ca52c6c6780faede65716de23501401cdb348)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x2340d2bdfc9ca0323980c879e7c85d2ceb2cd0177c5cf8a87e288bfdb4e291e3)
            mstore(mload(add(vk, 0x240)), 0x26ec64d303278dd874f42cd80d80c1482dbf9443189ea2cc8e66a42c6d59956d)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x08b0ec54ae3f12dc56da1602c213be21877da32aac204c171b3ee80be6586533)
            mstore(mload(add(vk, 0x260)), 0x1d8d66c676adf883f520fffed1e3ee6401a05aab3b3a426f76a82412c8cc81cf)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x04b8bf99240e447613a05b88e13c49bbc9fc997d90319f7b25025eec4feefefd)
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
            mstore(mload(add(vk, 0xa0)), 0x128ecc5bb1da7fd8a68aa5c7e72cfe3b42aabce313d1d6645fe4055a7b49ac0c)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x01c53dddbed7239dfa98090722b3bbebab0fb95b075e051f64203f07a29a31f7)
            mstore(mload(add(vk, 0xc0)), 0x14dcc8cbd9d47735859662164fc78f4493fc44cd2f3dfe77463a76499612bb0a)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2416a3c737e905ddb9b40ca1bf0f7d07d18c5b37e74df33beab4f91f4f8a745a)
            mstore(mload(add(vk, 0xe0)), 0x1ec0bc5717c0a1e598f5112a3e495c8ba16be8c5b1f3f541d455291f1ef9145a)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x2b335e8cfd27683a04d5150d1d58cd2ac9bd7acd492822913e6c879796d27087)
            mstore(mload(add(vk, 0x100)), 0x18da028ce6a296d6a00118efafc33cdb7e8e502e5e091e2541f092ccf827924d)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x15c369108fd2252737b1de1711f63967069540c5e7ba3103d67d6f71a120f02e)
            mstore(mload(add(vk, 0x120)), 0x2b1bbd130ad99391dc200c7bcfbe0b372e4b8793a873349b0725ebf92caeda37)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x096e6e9b8217692ae77c3a9a67fa2cea4a1c2cef667f263bf00fcb7f8c936404)
            mstore(mload(add(vk, 0x140)), 0x07f37f32204c913a18d8ed73676b5adb693c9c112a6fc62189faf2258be58e1d)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2571fb2b82ecbc30c04e00f0933f9ceb8aedd71fb2c80d9f42f016296d59d89f)
            mstore(mload(add(vk, 0x160)), 0x18e6b1da800602780582e885f7dd27e8f8f9577c278747d3372d9a928ae016e9)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x01f0ed702cf9fca094120d6f3c1bb12a4e8c06c8a3056ab97ed1379e320b94f1)
            mstore(mload(add(vk, 0x180)), 0x063b49beebe109a37261cc9ce1dd0d28dce4521a695969eb8dbc37bb53602c82)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x23e13a5eebd3ca90ce15a71410d8242ee114addc99c25ac0567d72e3630ea7cf)
            mstore(mload(add(vk, 0x1a0)), 0x2c26d6ac4b98e625cf31fd0332f8b9e8d69ace15e6d513bfa275ce0045066ff9)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x24596feb9933bb3403eb00429c1bf6519dd7e2dfae4823e0239c02de0ddd3211)
            mstore(mload(add(vk, 0x1c0)), 0x1a4c9bbea280067967f4685cc2ef1eead93ffd01b39133e0791a788fdcd07d22)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x04ebabd89e28b86e67627ea2950dfcd85e40b79561d1717b2654e7d0b5b8dc19)
            mstore(mload(add(vk, 0x1e0)), 0x0c64d466e69580885346203e51b6609e482a61fd1730d672d5bbf04d8aae271a)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x29d0a21cc1b3157ef4cdecace69fb7fa568d06cdba742c38b99ceffe55e197ac)
            mstore(mload(add(vk, 0x200)), 0x0ff79f24d2374bb54f69884e0d61211f743020bbdc49311b8735295729b55aef)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x2cc9bb4ae2006f624fa856b71ff39e99d04471080904905b79a3560d7bd8b0c1)
            mstore(mload(add(vk, 0x220)), 0x09cc281203ae2f68a664fd11de2acd7e54bfde8715b0744fb2b670179836339f)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x16ca2c9a40d67b32770be2e4e6c0f8c8e6e4f0e04d9aca70f54c96f87a818278)
            mstore(mload(add(vk, 0x240)), 0x2c92afbb51fcb9478f6c2cd28501a0cac267096799f9b49aa77a5c5043205365)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x168e95ca6e96a656c3ff7c296957c59ba6fc2b0980d3ef5f7d4384ff16a96639)
            mstore(mload(add(vk, 0x260)), 0x1f3ea8f987822139bdc9ebfa6d9768762075c72c67a87235422ba5efbc708314)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x12b2e1e2b10c55c832e2b0a1a699f3ea48ae4085238616997d460b382003c00e)
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
            mstore(mload(add(vk, 0xa0)), 0x00aedfd3673713c0e4185928880c2259b050bafa390dad1f5c7162296b77d309)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x1d851124257daa8f8673424e3ef4908664e6a5f147a734a2a16aa4b134eb848e)
            mstore(mload(add(vk, 0xc0)), 0x16a847ea6a828a8d4ac9006dfb7cb6a8d3cf6256168baa82b49a4d15afbf88e9)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2686e71565f5ae835322b874dd4cfcd41690e76b1602a77a7b9643e0676e59a3)
            mstore(mload(add(vk, 0xe0)), 0x156e27ef850efff2fd85a0a08614a782dca765399e9415de201bbcf49a7d8842)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x039c03a3bc6147c0e44cdc6476ac26ec2832fd5c300ff2211d8f298c3403594a)
            mstore(mload(add(vk, 0x100)), 0x101c63ecb0e31f417551439fa5cf944905f857e85b8d8652a394e8247f06e5db)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x08b51a9d5878908c2ecf9b614abc2db76eba9e2fd744e1bf950f2085e48db650)
            mstore(mload(add(vk, 0x120)), 0x007b962b89d5c95d05f5e289b70c94638ee91f00639859122c5d306b6fab5b43)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x1d9b4ce5d6111f2b6617afc15158713ccc5f7b473e3bcf5f81e739e1c1f6e5dc)
            mstore(mload(add(vk, 0x140)), 0x303ecd0abd791231be3c46932023d628854098599af5964744a0abbc34ab66b8)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x27a6a54866e70e5b26e9aa83b7a336ec496f234803fd4373f171fe2a47623db2)
            mstore(mload(add(vk, 0x160)), 0x0a8a5d12269ad92086c027b3b44f91077e950c281ae74e740c24a30a83f7f47d)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x2b2189f1114cc98d1a49ed3989ace09ae0a639ec87eed20081e9170d36a650b6)
            mstore(mload(add(vk, 0x180)), 0x2046de2ec2d235b1eabe00f8efbb457d04cb397c3d08bd989a8b3d241e3ca34b)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2fcbe115a306ff18b86b237d2d42f9bddfd0576fa469d0ff4a4ce4d26081a466)
            mstore(mload(add(vk, 0x1a0)), 0x049a2e40de309bda195b9a9f4a75df8112b272f465c6e44b83fe8d715efeaac9)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1a6994863a80b388bd025afd8250ec18490b4f0e448ac2efe9e277bf57e4bd63)
            mstore(mload(add(vk, 0x1c0)), 0x0b2b5bf773e1e5e762227bb903da156673155f745a9c07e11b40042572a6ca14)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x2f867fbe12bb998b8b6189123ace71d46d4ff5a5194fc4da0fddc188e16303c3)
            mstore(mload(add(vk, 0x1e0)), 0x2e4ef6c2eecabb86bd7420c3950c5537bd7e17ef76bd42b113f6af434d9042e7)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x11f5685959f6eff605dbcbd761de75d091a23aa24409edd48aca175ffd16ba05)
            mstore(mload(add(vk, 0x200)), 0x2cb9e48a5c313e4dd3b5b1e43aa43b1ab0a44a6f683fbc7698628f29106f4e3d)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x0f4cd5c520af036ce10120dd52bd7979cf1e536d1b29b15c97a40a05b760b355)
            mstore(mload(add(vk, 0x220)), 0x034fce2e99be9afb219bbe2f7fd802d4cb40c9053415e71fe70ca3bcebbbfc1d)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x25cbb3eaea6d4324155a8ecad62347b7790fd1fa14c552931d8a6eb9bc18a364)
            mstore(mload(add(vk, 0x240)), 0x0c684132b19adc0370df75fc86235d3810e9bd70d5bc7f2f56c2e8ba6823d35d)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x07cfd8ca9c1946c6854882bb3af06445fede3ec3abc983b43d05415aa65ea830)
            mstore(mload(add(vk, 0x260)), 0x185a6bd652174af82c3b8db6f2ff319396e9924284321c113d0afe21dd6844d8)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x084362cf6768135357ecb9b3f1d113ecde4811079d98e4c1ae35cb989063fb7f)
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
            mstore(mload(add(vk, 0xa0)), 0x290b8d025ef832ba1c15c0147293e992410787d68e5f80959e676822934cf4c5)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x1204d8e89851a0fcca9b613cdc0d0163b69d93f70664706febe77a56abc5c4f2)
            mstore(mload(add(vk, 0xc0)), 0x188b98c9109cb663f5636202c43dad3c3826381a7c95c13441548817261520ac)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2ccf54971527f9c47165b2bcf5325954b0e455157a96a4a894994fe8af9c5b1d)
            mstore(mload(add(vk, 0xe0)), 0x0d58c89aa3b5bfe281de252714bd760e7d694660ca471669aa400564afa878b2)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x05d811ce51898ba9c3a01eadae0728dfd322bb19f7d57cbc48fbec3ac6b10aec)
            mstore(mload(add(vk, 0x100)), 0x2e7dc6adeb3b3f62d0fac3b2b0c3b726f7f93dbac39fa9f58c7535e54f88377d)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x206226c72bfe3fc476dc92470311ab6006a67503ff6217f134747ce1ea330236)
            mstore(mload(add(vk, 0x120)), 0x24b65466c31f22eacf5eeaa821b61b966dad4c77991d13dd22d1e61efa0bd544)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x0e1410a41b907eece55b710e79c97c511fd0890f66b6a192697c047cd0e9d326)
            mstore(mload(add(vk, 0x140)), 0x222b2d5b093b2a779e7b35382ef96999ecc0a0e52939809989aef89986feea78)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x128b78cc42bbd421b7f6f1469bfe5fb7eff2d14ec2707154920463bd09ec64da)
            mstore(mload(add(vk, 0x160)), 0x158dabf7d828c19c0dbf6f8c45b84a4977ae5248ea6e990e61b8c2951f6a8412)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x07478fc30cf185888b86c61792dc9353e370678ca7c30ea50dfadbf75af51e1a)
            mstore(mload(add(vk, 0x180)), 0x1376ac7861b0588c613d38f43f5853ef05a6bc8588f5b6a2129ed595ad0f8212)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0399440aa8aac234a1c646e599c1c61111365dc9f59554fb851625182bc7fb3e)
            mstore(mload(add(vk, 0x1a0)), 0x24ddb45521cac4b1b7a82d08c999ef50f2724c3b7bf5360e627e9539cb5739e2)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x0003e99bcc497f0cfbe5a31732f7748b68f99925a6764f682a71d33517574de9)
            mstore(mload(add(vk, 0x1c0)), 0x20d2bb06ac7c559a383cb3837d1f012629658488ddb34e1df1d6697d51e767f1)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x0a810c61487cf79c19511179a69fc15905a96c87d359c189f46017d1d026bde6)
            mstore(mload(add(vk, 0x1e0)), 0x21a152ca3054255176f3f5800fee75d8f269e9e271a7f1bb5f3c90db09beacc2)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x2b5804d78be43843e7e73e8dde54537f865dc4827a0f9ce6e0c18dd95d8f2cb6)
            mstore(mload(add(vk, 0x200)), 0x1394f7edd7fb557ea04c2178fe79964bad3fcf27c2c6a870f58e795c9220a797)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x23375c4a1a9a89d05088a6ac8236c3d41e831bd6ec6365f320cad8c3dfdd2535)
            mstore(mload(add(vk, 0x220)), 0x27df75ef4c0f777dac6620d9861f75c668f110ef8f2b956991e5fb29983e0132)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x1575139bb2e106ddb5eaffdd4a7921bd1cbaf468c23929968d89c188831d3818)
            mstore(mload(add(vk, 0x240)), 0x0fa93fb9f82f7afebc381eb8ea34a3b345ba681bd46fdd1b6bdcd67f3cc36ec3)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x0efd9f1464d650e3d7497fa22d69d413e37258ddf906c16486b9f757da4b27da)
            mstore(mload(add(vk, 0x260)), 0x23f4dc16cf2932b87003ab768dee4e1efe679737a34e6a6d7007dbaaed4647ca)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x2540d52263daa3452d423c991db42df442b14eacad06fad9afafe0029af3c873)
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