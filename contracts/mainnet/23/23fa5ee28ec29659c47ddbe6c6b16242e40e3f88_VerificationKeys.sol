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
  "libraries": {}
}