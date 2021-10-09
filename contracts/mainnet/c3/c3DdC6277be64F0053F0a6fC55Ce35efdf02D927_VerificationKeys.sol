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
            mstore(mload(add(vk, 0xa0)), 0x0c592cd40a28a9b726fa641a05b32cd4bf85a61a670ed916719d9b98631eea40)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x0de70151d57e35ab11226d58674901b9cc358e76816c479044fb1aa193fc2c36)
            mstore(mload(add(vk, 0xc0)), 0x08002f1293b048e8574cc57bfc9e1a8b0c5c0346d6fa27e9d8ccaead9db86c11)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x28e342275e1f6efb41d18fbbbd5fc10cad938f12433a524a25f37c0aa7a4cff1)
            mstore(mload(add(vk, 0xe0)), 0x182c598275a8bef5cdfe13e33f6f78ee77ed1dd2dd922b891b75ff26fe534ad9)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x1802d768f37d7433a3274c7bf3e0a5e3d444b270518d3657fc1797cd993561fd)
            mstore(mload(add(vk, 0x100)), 0x0c16e10a13db828f1a6137846d9420cc11bdcd19edff05f39b9e47b3bf953cc4)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x20bea7e7fe545095d527471ad4126b7e29825b9f793b7346e9f305af5da2eb23)
            mstore(mload(add(vk, 0x120)), 0x21a24f3a3e29898912ae459fa0ab70956ba72568f6342d253418e782b698a889)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x14ed25ebfac646df91a7680393ba7a8e676432cea41b0e7369bb8e015e482768)
            mstore(mload(add(vk, 0x140)), 0x15015be7c1b812fbc9ece949280a3ec00609a804dfc7daa900c521d8c064e741)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x0255d44470e7e772c2c4040ef570209ab2146363892e29e33b4504e4d0efedec)
            mstore(mload(add(vk, 0x160)), 0x19dc45657dc291dd01794080df198fb72031216274c916fef072477e82cdd65a)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x114c448181049e16e92839f394c90a6439be6596fc1b9658e12e8896e488d1b0)
            mstore(mload(add(vk, 0x180)), 0x2358a82f2b4ac8dca370633aec9b9a197298cdd9cb3e17a621af87b32ee93757)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2cf113fadcd3e7e063e6578ec0f56d5c46eef945110fd8f2177c8b975fc4cf31)
            mstore(mload(add(vk, 0x1a0)), 0x2464fe0f03bc3bf549ea6ea21682df575c8eee941862d3d902f5bef0c6c5073d)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x16b24942e04cb035a4f3700678045982dfb410130368fc79640e3bf81f3d1695)
            mstore(mload(add(vk, 0x1c0)), 0x22636011e2ce575ead19c67228b4365423e88020d07fcedaa69831bcfa518546)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x0dff1aad3f8761befdc296e8dd700858986ebf6a5672d03625ff285fd8dd5baf)
            mstore(mload(add(vk, 0x1e0)), 0x20735c1704fee325f652a4a61b3fe620130f9c868d6430f9ace2a782e4cd474e)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x217a0dc7aa32d5ec9f686718931304a9673229626cbfa0d9e30501e546331f4b)
            mstore(mload(add(vk, 0x200)), 0x144e7a07e00015b967c1973319b0d93dfe071bc2b553aee9e9e270d8c4ded794)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x009d72f0cba4835ad2689427d226db036153c215293d87dd6cae7c724e96d6e6)
            mstore(mload(add(vk, 0x220)), 0x026f38fa7477342e5051f82ddb160e1a6f7b89393ce46d6ccb4175d3b1a85cdb)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x2cc7671397ee68e45a781377738621544083b88fdf913a73d459b81e3f100128)
            mstore(mload(add(vk, 0x240)), 0x10fe3a0b68848cfc051473affa28fd715432300b19ee6a63b888ec8af68f934f)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x0ed93216f720ff1fa89002a463e1da0b47dbfaadd94d1d2966d736e82d1d0207)
            mstore(mload(add(vk, 0x260)), 0x230827e1e5b4c00a206714535a60d4b83c133d75d17117fd6a3ad43c3ca124ea)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x1b30c08633f85e929001dea71433b697d8d34153edc21c97dcf8d7dc647b1c01)
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
            mstore(mload(add(vk, 0xa0)), 0x1494c983a4014af415408b84a73dd29a551dad2a46f5ff73e20e65bdda0415de)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x09f8e776e896591db3f175d3c70e3df79d8040f5f628c196653c9a069d5c1bf5)
            mstore(mload(add(vk, 0xc0)), 0x1e88c416481082631ca69190461e689da91a0fdb91069027790a42473fab853c)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x04b11f5528c899785e3f5042c624cb8e9d500636f9267699a3b58135865afb32)
            mstore(mload(add(vk, 0xe0)), 0x1ef5a0a59b3b6bafee6555671817a74b831e56ab6fe10affd486ce8b17d41585)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0c56d219136bb97fc64ac4d21a81f3375e68c30bc19100b6e91bbcbcb5a1c81a)
            mstore(mload(add(vk, 0x100)), 0x1f27d0f27790b9b54089b6d4cf6753665c8e4fcd7d5332ed68a11c24297aa8a5)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x012543acb47293aa56293e9795aad4f0723217954f05ec91b3024de0bc630351)
            mstore(mload(add(vk, 0x120)), 0x04072b0a6b300b05d31e16ecc4c4c5d24cc325d90728ed15305d1a804233f94f)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x1b286071b0a083bdb26af1584fdf83c465745404ce1cf2b8b349154cc2e0580a)
            mstore(mload(add(vk, 0x140)), 0x24e87dc9bd6343226fe885af9f30da07c22d23c35a93dcd6cf3258e08c3fb435)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x0ceed4102b3a4e272c30c9098ba676518ea4cef6c469a8c3dbaec2e0df17339b)
            mstore(mload(add(vk, 0x160)), 0x27fcd290a9064d2dd4bacd1e5f4bfe5303361f12fc5db255a5a348decf5a405e)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x10b0c0c35d7e7227402b20b3631e54ae7209b1e80c939b242407dbc9d8359d5f)
            mstore(mload(add(vk, 0x180)), 0x2f50fd42e3b7d84db82e7252791073d4622cd1d3993d657deacf0879edf7e8ab)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0d891e8d949a242b3430e33247bb95636bde08c062150f61408685e17ec61838)
            mstore(mload(add(vk, 0x1a0)), 0x0aad547972b3b99db5233ada23dfa01701d0d50bb2cd2d8919174e6e3551d5c3)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x2fa67d69cb906af7ef46bafcde68f97a80f002bb52bf573341e577c55a428a36)
            mstore(mload(add(vk, 0x1c0)), 0x035bb3d3ea11cee216b5fbcb0654c7abdf976d53196bb24f6414b9ccce34b857)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x1cd877aed87b33e713def94b9e913a7f60a07109d32c3aef18097bb802e6a6b7)
            mstore(mload(add(vk, 0x1e0)), 0x2956cd5126b44362be7d9d9bc63ac056d6da0f952aa17cfcf9c79929b95477a1)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x19fe15891be1421df2599a8b0bd3f0e0b852abc71fdc7b0ccecfe42a5b7f7198)
            mstore(mload(add(vk, 0x200)), 0x1071a8c625ed26c4e9f3b559d314e04f143d146fcb5484dcfb1b8a346758fcf0)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x12da71aa112ad82e5b0bb196f555df492171be424670eb9ffe3d69b5c6e3d54d)
            mstore(mload(add(vk, 0x220)), 0x1d0148032a643173acce91e4e1d65fc077e0e5ba906d3c4e78f29d0947e14002)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x01a929b46c92ec4d77a67e40dc0bbf9ae7a91021e4edd619b280dd872eb43140)
            mstore(mload(add(vk, 0x240)), 0x00313b1a850ae2f3e7697f625f7ae5cea2c86aec4833a22e6c3fd37bd3eb87f6)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x1b0e7a48d19f1a700f8dcdd6b020f203b12538239d09f6184c41b52dadbfd546)
            mstore(mload(add(vk, 0x260)), 0x26e161b82fd7ebf027f67cc8b244d0e10e3e11b3a16492ec23a7ec1708a61bb0)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x058a758818fde0ebb9016d04aaaeb69cc6ae6fe385eb12237838dc71cd9c3f2d)
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
            mstore(mload(add(vk, 0xa0)), 0x2d7da4a5ba6ca10e43cf7383dd026edb17136225a024171889abc788370fe8ee)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x0b7764b610a3e80b0a44df25beb7e4273877facadeafc4ed9d4efd6a4bfa7c5e)
            mstore(mload(add(vk, 0xc0)), 0x14d3c8b01759528025469cb3b4464c413c8b64ff802ff638629e64828afaf90c)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x055e7818bfbfa0e2705d7f44d950ffa2faf1b7345a24d5bea0aafd7dc2faae77)
            mstore(mload(add(vk, 0xe0)), 0x16ad086667ae816423cf12a52d68415601ba583d6f13766f4fc36010422a70f4)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0187c575705895a4a3642d6859d36afb838f85790e5870ca09cbe8027b0ebe67)
            mstore(mload(add(vk, 0x100)), 0x11fa05498a27bc35ebd32baceca58a061b13481223ba25307c65929776b58739)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x18bec637b3b7729cb595012283fa2bbc0d7f61bb7a869a767cadcd42e9dd3e35)
            mstore(mload(add(vk, 0x120)), 0x2788137533de6d10b7d67109cbaaf3c73f2319af8bb402080199dddd5e502da9)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x1c3fe4f3ee71fd4027ceff16ff6e33cfe61d3b1b28888b0159a4ea97eb896658)
            mstore(mload(add(vk, 0x140)), 0x264a9cac82e600564a5372feacf7f2cbc08ae6656e2d762eea6a48360c8a9968)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x1a36b4e6148ec37b8eed5d623e06d81804fc8834708592e20544b5d9e3c91f51)
            mstore(mload(add(vk, 0x160)), 0x2d3f602476de57a42999a9731d3ceaf2f4b71e65432f28933fd0e4f32b26a572)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x0181355eec6206a5cd15e26e997004631339c79e931d9ec35c9880fc1f6cbe80)
            mstore(mload(add(vk, 0x180)), 0x12841b0ae4282c1c01655cb6e8426414a1a39b68c762285b708ec9014740c085)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0a325f616a9aadae6861b79fd3d30cb86c3ec7fcd31fc107eeef28bd97b59226)
            mstore(mload(add(vk, 0x1a0)), 0x1b9edae6ed8cc00c6f8e62f43a03071e8d168dbd97386a1e9ad0e603a6e96cda)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1315c8e889dcf4daf9b14712a0c3ba8de5310674a196d4f7c5c8f14e4d60d2a4)
            mstore(mload(add(vk, 0x1c0)), 0x290883179d3796b4d6bbce70adec1b9b76c2fd5744bf8275b19850f5d2739817)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x3058ee1e47a36d540530b4113c7156ec3e7bd907e805a19928c04b962a953370)
            mstore(mload(add(vk, 0x1e0)), 0x27cda6c91bb4d3077580b03448546ca1ad7535e7ba0298ce8e6d809ee448b42a)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x02f356e126f28aa1446d87dd22b9a183c049460d7c658864cdebcf908fdfbf2b)
            mstore(mload(add(vk, 0x200)), 0x223a19671d8fb58c16e1b67a98245c2a2d908c04119af2000c1037f31092226a)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x24b25dadc6c31601b1eef09d28167e75fee716aff32effa16d23efb895a94514)
            mstore(mload(add(vk, 0x220)), 0x06326b039be65b4b9defc480891d1a677819407456cd7e49a5836882741927a4)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x06bac8fa72ea521ba5b32f62d1a091dc1a0decf2086ec2bfeb0edebc8a9e1fd4)
            mstore(mload(add(vk, 0x240)), 0x12020c65b5382ab1da18fbf7b00ef7718b097531477fa4d67294c93a3b8816a3)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2fc89972c0a731730c217b3d2dfdf7a07419d9eda0f398d6d0f1bc64e6a69953)
            mstore(mload(add(vk, 0x260)), 0x23a54e6c90f842e1f37f442611fb4ef129ff1970dce87d73b29277df80985ac4)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x13021a2f374a905beedb95a86976e2e4ca3709e03fc35a331056be7c91ddc1dd)
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
            mstore(mload(add(vk, 0xa0)), 0x131a4ab77d5ef901c051db551b52fa4db31627c146641bc8146f5d8a37d51896)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x2175f0a0d1be6f7f4c6a67bfbec75e71c70b13038344cf38c7a482b30fad8b95)
            mstore(mload(add(vk, 0xc0)), 0x009e09a3e58907a9fde56c9ca7986692f8253e217225bff8accd7d7ff19230cc)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1c1d323236a620d8cab05d51afc2fd1effab51bc5b201cdeefcc30b833c67431)
            mstore(mload(add(vk, 0xe0)), 0x0716d0c8ecd5f4de245505802ffc9f3b600b4f363aaeb5f1e6bae609c34e9ec0)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x180b0f77e48ddb0148866b58ca0729d088cadaa81cb791f476b202851ada0dd6)
            mstore(mload(add(vk, 0x100)), 0x17f67f82a53f726931c94d68e1b1c85255a6c9fae9b4a5c3400b35a4f91bacc1)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x0588ed9770ebbdba2f33304a04e80eb9606935d2a6d270019052bc18b46ded7d)
            mstore(mload(add(vk, 0x120)), 0x020c2dc4dc94d2a51cdf59997b0f0a2e49239325033162de576f33afe6234015)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x2cf542e642ef2b92c7ba41c2ade86510826c70a59b5556b8423563252e517bf5)
            mstore(mload(add(vk, 0x140)), 0x14621110b991356af79ae17112ea874144c39c520d8fa258ebc57246cdfbea75)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x0ac77e8fb752574a51837c968760ee3c3e1fd74094a1ecf36d2531114435b3cc)
            mstore(mload(add(vk, 0x160)), 0x26a5c56556c6a47b88d02cc6e62dc95f5b02b642101432b35089b808d55939f2)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x2a11834735d79cfefdccc00c5e65a4b2885e411d9eaaf331b533fd9464fbe102)
            mstore(mload(add(vk, 0x180)), 0x2619d4bcb4171a3a0cd4f369ff676178c269a58620ecbe6a3c3fcfc546aec396)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x1f8db7de67d896a210afaa1e3708ae6a78c4e938a8c18d9107956051ec72b071)
            mstore(mload(add(vk, 0x1a0)), 0x0c45250be3d1aef45f00bd2d6a7089212a937bebd4a15e95225440d0c6e4c76f)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x294d8b005b9e0bff4da7e2a6bc7c9a888cdffa69b05f783ea1c3604429fea63a)
            mstore(mload(add(vk, 0x1c0)), 0x17ca617c07a352cc3ffed601db32f9865754eca3000a8d85c5dcec9c2de64a15)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x106900630a849ed16000076caab5eea0d263fdf2bf255d9fda10917830596b0c)
            mstore(mload(add(vk, 0x1e0)), 0x01902b1a4652cb8eeaf73c03be6dd9cc46537a64f691358f31598ea108a13b37)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x13484549915a2a4bf652cc3200039c60e5d4e3097632590ac89ade0957f4e474)
            mstore(mload(add(vk, 0x200)), 0x0184cf7430ffe7664cf2b1da1ce631a39e9b0c9ad54964352384a6475c2f29a2)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x1dab05fead8b573e4395eb9ecf4483d79648e35344a09a7b4a09f439d0b04643)
            mstore(mload(add(vk, 0x220)), 0x1ced7c80e79bd9e5604724ee9ebe41a61d3633e69368abbb48ebd07e79cdde5e)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x226faf947eafb1dfbb3c2984736109572ac942c2daad5019ec31c56e2b8cd418)
            mstore(mload(add(vk, 0x240)), 0x0095d13ad62ec509fdda38d5933c63db9050d797415ad584273339840385e230)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x1e3e80bdc74385acfb2f527a6440bd8ed129db290287bf730fc859594e300d88)
            mstore(mload(add(vk, 0x260)), 0x166b4a087290dbc7765c0c334769ce1b15bc87000d5d78f5d6e8bffa7d7170a0)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x282be34de658dd836ad0fe796d1c8de49bf1f431de00c122e3d5c8e036e63282)
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
            mstore(mload(add(vk, 0xa0)), 0x1340b5e121ced615f56db9f918274fb7d288a3ab61dff5a19594c2b96cbe23a5)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x0a0853386dcfbf113a2f980b6251caf5a68f018937f854d4910d99fc01b8bebe)
            mstore(mload(add(vk, 0xc0)), 0x2b74a88d2c617027d2a63bbf900ba06ae721d19c7d061ed9eca3437a85bd293d)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x258952e1a7066e37408f8dae0b7c8a04af9dc500ffbaafb10e5837171d749e23)
            mstore(mload(add(vk, 0xe0)), 0x149881c31dbf92050731c54853e1dbffce5e432bbedbd6701d7f6ebcc9e86661)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x01b4cc111e156304b4af0da5d44df4da0a14f50810ec390cec47639809adb97f)
            mstore(mload(add(vk, 0x100)), 0x200e37ec9a0ffaa0e25ae88f7891ba70c6eebd088ae5e7a58b1bd758e0839067)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x06928009896114dc84ac0de71d224afdfb4267dee32a66dd95be05a33ebac2f2)
            mstore(mload(add(vk, 0x120)), 0x171bd670606e79bfd4bee7a904535a6c687c08e32b110942bcb8cd1bd082240e)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x02bd31be051b434e285d81c6d956b5a72140916427c8879357d75252c5001813)
            mstore(mload(add(vk, 0x140)), 0x080637fa943079b3905b2171d3d03e57a34af325c36d6832563a8c05f102d809)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x22288d0eeb954a0dd52f1ac95901d35de729c89f7f6defcbfbd8762ee56d5726)
            mstore(mload(add(vk, 0x160)), 0x1e3bad59a87695df69e74936b84df8586cda08879a092aff8cd0e7b5d3b823f1)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x0c098d054018de2525453077f7b9040c8559c629ea1ab21965cc167d02349e19)
            mstore(mload(add(vk, 0x180)), 0x133ec8621fbd6894063a5c4a636a87758694e374344c9ca10c259a44ee1c594a)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x18879c87e928f11b93a567935298d09e734ccf5cea51c755d6aa0bc23dd840a6)
            mstore(mload(add(vk, 0x1a0)), 0x214f7db081debb408f865a226cf017346cc2b06f3f6ff7ac7fbfb35877a87a36)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1fd8ca5d3daee196ea279e97c1d6d8048b4c90185a49b1f3a1063c6a4e09044e)
            mstore(mload(add(vk, 0x1c0)), 0x015968f39bf53733220cf5277c47c7b6bd5dc05ef53cafb6547b3a2343d43d54)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x05f18632da7092477f0ddeb08174ca6aa81104d37d98fe3838831612b375fd02)
            mstore(mload(add(vk, 0x1e0)), 0x27257a08dffe29b8e4bf78a9844d01fd808ee8f6e7d419b4e348cdf7d4ab686e)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x11ee0a08f3d883b9eecc693f4c03f1b15356393c5b617da28b96dc5bf9236a91)
            mstore(mload(add(vk, 0x200)), 0x253616b4483515298e05aeb332801d60778df77cb9785d8bbee348f20df24c4d)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x1d344a80672c2ce73da5ab7fcb939aea3162ebeb3d636ddf4d34d0a2edad8950)
            mstore(mload(add(vk, 0x220)), 0x05db52d0db9140fdddb8e18abaa9c3c5595ef6140da4104a23066c821d8dc252)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x048ace3297ef43c7ab5fdf26709c0b3020cbcd0965583d1f56d1b78d9e92f695)
            mstore(mload(add(vk, 0x240)), 0x1c5a8cc38ee5b3bf9d6924dff25213c04be2debe4cda2fd69ac1c572958090b4)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x0d0b8b61d8ac52932f1e660152577611067eb8edeccc313504cc922ad64f8b06)
            mstore(mload(add(vk, 0x260)), 0x2df68d8c85114395f291d939ba368f5e3c37e7ff0989016b6eddf25bd792d883)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x063dc89d12713d19f93c6ffe414a57da4e7628816809e8f9f38709a7b46f659f)
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
            mstore(mload(add(vk, 0xa0)), 0x0966751c80374a3362429da47872ce0c6e1b915105cb1a5e7aad1b284e3e7b67)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x0a39f94469ba5b0e86cf4bb414ede4a777d91d7d07cc0b642b3d30d76f6911b0)
            mstore(mload(add(vk, 0xc0)), 0x0f9f9672ce4579409dcdb621b47ea255b3dd8ee9481e9ace5407e6a3db539c5d)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x156a05740019dad9cde20e3f8593f4f4568be65d5e891140b2deca9e91c8e6c0)
            mstore(mload(add(vk, 0xe0)), 0x2b51c97692a31d58050514812c665e88f0693cfd2b1f1700e7b292f38f131eab)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x02293ffef9cd3633dc81263189eddaf25229cfd885c2841fd7c649038e0cba99)
            mstore(mload(add(vk, 0x100)), 0x0cdbc42be8e617333076b89441a6e3fe4531efc53379f26e40713dcd6581f254)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x1d3f54958bcef1bfa5c609888bc5473b7b786d55eaeccd123ce527eae46039c0)
            mstore(mload(add(vk, 0x120)), 0x11780fe296089b6cfa66ccc42e58e52ea8fff5ffb1f16126385998381e5701df)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x01805831da0d3467b60c0e97e97028b5407531dce50fceb99ed270c53be75be2)
            mstore(mload(add(vk, 0x140)), 0x162382cda216393cc1032930468becada75a61b4b699954a8d3354665e7bd864)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x16bd9cc0531489d3e1a1bb313936eac2944df9ee2095d7f3b4436ad368ab7491)
            mstore(mload(add(vk, 0x160)), 0x2c51b61f34fc90c41dd7f8813c204f8b45a56325bca9926e47052290cd7655a1)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1eecaa2e8361cf73743ad6ac85060f1358e5ef83beb8b59821d0eacb654b3938)
            mstore(mload(add(vk, 0x180)), 0x28275156dc2830093090dcdfd84ca7de6c32951bc8090358e2400c5e0fd318ff)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0c99a03aab57b6ec2ad4317b10bab925dd8180bd37a38b28167bd387833cc305)
            mstore(mload(add(vk, 0x1a0)), 0x0c5a55334e5f488c8c8d0b3a570d4427f5d6270fe9ed7c2f372a997afbe8df3f)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x2c152400afb3d41599e7a760ef2bd44a4cfca97f8d7375eb50664470bf90628d)
            mstore(mload(add(vk, 0x1c0)), 0x0d1778269b54ec38bafd8448e85469acf21c56fe52072d12ddc5519ff0ff929b)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x1b13450aed355f85cddc35c3517baea1f0c30780b948c302e9dc781e0843cff1)
            mstore(mload(add(vk, 0x1e0)), 0x2c1e3dfcae155cfe932bab710d284da6b03cb5d0d2e2bc1a68534213e56f3b9a)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x1edf920496e650dcf4454ac2b508880f053447b19a83978f915744c979df19b9)
            mstore(mload(add(vk, 0x200)), 0x1d1ea4a05eb02453ad033fb8abdbf8b283860538b8045766d88e9380d93298ad)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x0bf5fa01bfc57d44a1a5d26bbe2adee2a7b8c4ffee8593d80fa7c7707689531c)
            mstore(mload(add(vk, 0x220)), 0x02dad9cb208f468c6873055280153163bb41e47d424a88ac8d834ce4826955dd)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x0eb9b7ab97988efa9d00006d2ceb2634bd5f040ae4dafeb97a255fa63bf892da)
            mstore(mload(add(vk, 0x240)), 0x2460c39847ebfc82654e1c415e0be7ae7cc224da3d5d2ea50fb7a3b09713da23)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2f3c7141abc8c0d1e7d0907bd552539e31877a7d196a331e5782ace02771b0d7)
            mstore(mload(add(vk, 0x260)), 0x1f2c806537d18cf7117db2e08552b6d5ce0149deb6119fa62f054e595d0f395f)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x0659e8cba22023d2d28662ac514f74fa4d84f10997e893f0a39ac56462e82cc8)
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
            mstore(mload(add(vk, 0xa0)), 0x1279d2085cc7d5cd109ab9dd43ff33cb95c7a13046b453a4bfb61bbdd72492d2)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x28ab33a6fa82f60cdad385a78bcdd940aaccd9a7cf9b453ac8c80aac1b4777fe)
            mstore(mload(add(vk, 0xc0)), 0x27f67bd4f2baa8fcb9eb46fa5295491ff1081db334232b913925fae0b0329961)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x0faf0ab4d5d4177b157d05d7956a3e7efc2e7786ab8864605e2b3b6b3f8ae3b5)
            mstore(mload(add(vk, 0xe0)), 0x014ca3daa697ac00fc7de92d65456acef16a42be471c75756fddb5237850b350)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0375707a4a831032ee8611f7b0ef4a7b03399cfdf9f1235cae1199aadc49523f)
            mstore(mload(add(vk, 0x100)), 0x15d63ab4cf44a3fdcca802224cc3d5da9a9dde520363f22e436c7b442bdfc626)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x2571127f4c6af3eb0b5faffdf0c14b52e57a61b9788727afeed2e1b45bb6d1c2)
            mstore(mload(add(vk, 0x120)), 0x14be377de9fbabbb4aef102f1d2ece5770e2d46e8dd30876054e4b64af9c35a9)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x01b810b38e1cb22cbf270e19cb150debdac6ab8fa38b66e266b1a55db3453855)
            mstore(mload(add(vk, 0x140)), 0x2d01e34f2251daa161281a8d5e6a163d58c6672683e7e77f3a76c92b7c8d4e93)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x262c29a17182888bb5499f98029b04dd74b33150c89f82233e932d52e1812ca1)
            mstore(mload(add(vk, 0x160)), 0x0e65650672209a49af8bef4a76ec549d56d4d0f28e1fed391cb2dd592066d6e9)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1a60dd5babb1e856ec8eea11fc1e2fd6546a5555be097d58437cb0cbff25b920)
            mstore(mload(add(vk, 0x180)), 0x2929e4fb516b4387375d4a42203afac5c218fc9b0b680d9fc83119d59948da9d)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x22b1f8d3d1aa27b317984ecccf9e5af9e07258a9dde282a3a2f15c0a8357ce08)
            mstore(mload(add(vk, 0x1a0)), 0x014bc072259718b55bb0fb3edb5118e4824e6473da3c4c65100f7d64ad45dce1)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x128eb91aa74e12801bd61c6027450804979f053eb0c99fdcc8c13daf147c0853)
            mstore(mload(add(vk, 0x1c0)), 0x090b293c05cb024ab4872f57f5ff36216155f2ea362cda33c9f38bcf92ac34a9)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x2524fd5a1fd9ae231b821fbc8267642cf8efc3dccd7f33d8e32c0c2c70338788)
            mstore(mload(add(vk, 0x1e0)), 0x1886069e4af02aab5feccdd3dc48f40c3940fad4c1ae712e6e192e408050560b)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x1e8ca495b98ef622e367ac42edf7bdd6c6a56ae2cae87bb9fb0ef29413f0e3a8)
            mstore(mload(add(vk, 0x200)), 0x0f88644a940dce7b381323b2b29e879508a6c1f5c56f227565c4ecb506921cf0)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x1fc4901ccd07a280a0317940225b0c8c7fd4515d0fbed46ded77a5cd7e8fc540)
            mstore(mload(add(vk, 0x220)), 0x0f0259931fea8cc0f1f8fbf4a118dd097efc00d47fd579e29ad5b9b806896514)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x24424eb4cd780341b9c16b5817bbe9a3bf8e0e18389866c3768f74976802109c)
            mstore(mload(add(vk, 0x240)), 0x2d478be2413dfbb000f5695cf291843469a09291506b55eb878f90c43c2f8618)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x0c02fc72b2a78f75a063d32104ca0deaba3fb1210a1017e6a7d66a63f8c24331)
            mstore(mload(add(vk, 0x260)), 0x15edfc8c28858c9c3f827169777bc657fcc3006e7e40cf4993df86a99918a4e1)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x1081c10d1a67ce208f5832c8217669ddbc43b75f005f2c5ce1af4d7efbd154c0)
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