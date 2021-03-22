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
            mstore(mload(add(vk, 0xa0)), 0x1be7e7ec6ee8a0506394f4ce3bc7e14a5fa06f38409e8c71fe1537d17bffdfa5)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x0df8786a8ff526d9602182ae6af8104acafef226396f7d747458c8979ef31109)
            mstore(mload(add(vk, 0xc0)), 0x1814e160f453be6c360dd023ebe43ea72c0df92e79084be1041fab8ddfba1a4c)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x06fae88bdc1906d333fff5a66d200e4adc99a343e2de59fae8256a71e379643c)
            mstore(mload(add(vk, 0xe0)), 0x088852de2448e1123e3409492cef33db8c150d0a63c87957aef4587e06bffc32)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0589f975d7566b3f0cae0472033d9fbec369214cf11c11a988bd26071af56fc7)
            mstore(mload(add(vk, 0x100)), 0x1097701258b171854c8bd0a7571f11649c69db7e58597670ec91b9b4b6aba766)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x19387ad4630cd3bb63038b9e20b85da16c9c931cb2fbc130f6a41825d642eee9)
            mstore(mload(add(vk, 0x120)), 0x1905eb3926d039c2f0446421f14ad8cb55c4cdc6fbd3807734c1ea59acbaa8c0)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x1354b6ed0043aeac4b451e978397b556f71adfa1e873968c965567100e9c9722)
            mstore(mload(add(vk, 0x140)), 0x26238ae94290ceec5ac0d5e90e6f64265c874e9d183ef36f7c855e32c9a4646b)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x0c73d4a5cf1e6ac4e91955ff0d79d1770204a4fb8339965fe5e9f349ec64ff41)
            mstore(mload(add(vk, 0x160)), 0x0e97ee8d5078ecb3b607d37236e8d3c225044a4f9cdee4dd340dce4f55320ab0)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x230692b75d034ed2a13d55c5de8acdfc3eb02475c7afebb9a7cf55e98645e50b)
            mstore(mload(add(vk, 0x180)), 0x2a44dfbb41b2818df3cebdbe4871341399c56956d17f6c9c95273e0a65c5910b)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2731b12af184e1543fe67a952002609590356a3064434f752545e520965c3aba)
            mstore(mload(add(vk, 0x1a0)), 0x1e9558821fdbadeed920158e24bafc7d92c8c6f3874398de56b7f3a5827a3d20)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x00db48e3b50462f252e9dfa037e3f0cdafc8fc0f48a262d0dfd778ad6782d029)
            mstore(mload(add(vk, 0x1c0)), 0x25deba27da9f8e5540abffdaea72c6a70f1a70b0e69749cb25dcc4d8166a1833)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x284c132e73db652707160217abddc03b83175a8348493fdf5aa365ebbdec7894)
            mstore(mload(add(vk, 0x1e0)), 0x2c536d4d7c77c6ded8c388d2d9eb5eb8b8082c6f4498c3e3025168880315ebe5)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x17907d56b67926c267abb2a5a8063146bc9f043fe641726296062a3d4d612306)
            mstore(mload(add(vk, 0x200)), 0x2fea3140ac2e12af271d2e8427084da5d262d9683afebfc6239d5af77ea620a7)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x2a8d3cc15d4bf57bdf139916b5507af023a4cfb68df9508a7e0a203ff1f15af2)
            mstore(mload(add(vk, 0x220)), 0x252c028ed5c97533eac8cb7aa71da46ab66fe6758b116d80ee35073daf99aec0)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x2c24c107f72c341839f44106647e3a2332c4d60849b4631b1a0ee995e000e936)
            mstore(mload(add(vk, 0x240)), 0x2f35b1cc2894816f76e3ad5e0f0c780b802d62faca20a78886006b46f675e78a)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x178ac8a9f4a07f38b6ff3322e30b87046362a6f20aff221e15b6abbdff543c19)
            mstore(mload(add(vk, 0x260)), 0x093f90ed651406ac7692d0c4b31342a7d092600bd425d125cfdacc2bd30b6214)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x01ed14f06fc27e7c9f60d7d56c45f301385b9e549d29d2fb21ca38c1775e6002)
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
            mstore(mload(add(vk, 0xa0)), 0x2ab94bc70c9b9af303322e919ceca9d68b33d57853b9476d4f3b458fcc918694)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x1adac823b9c64f10e9e8cfcb042f75a949d1dfb53596ccc3a07f4a2601b70a11)
            mstore(mload(add(vk, 0xc0)), 0x20720585053249caa023b0ac7aaf44431588c6a2503b2ee38aad720ff07c7259)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x28e68ffdad3d634a9ff6cccfb076833c91421295e0ce602d99d1535367c8ebea)
            mstore(mload(add(vk, 0xe0)), 0x2935334f8d66dca95cde79c0ba249bf85bfb496cc89d15673b358585f661b74c)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x02f630cdc5d23314855994e1f5d10f5f15cfb8ca88505917de400d76855b6903)
            mstore(mload(add(vk, 0x100)), 0x0e866ed9b98c49a6f7290bcb4702e445b123cb4d48d1b0f1651845a78363cf39)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x1362407a0a3ca84165b50f0163b7ad537fb74ef35715a78c2ee15335158ad1f9)
            mstore(mload(add(vk, 0x120)), 0x207684ab8f134db34ab36dda8988217d940969cc88a2cdf91d2ab75eb3854fa6)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x21966ec719e8b902728edaebf91729393c4747937ae3689240e1e2b70d1d7e24)
            mstore(mload(add(vk, 0x140)), 0x07639d789041e7e90f75f4cf304c71ab72c7adac599f2843190432b767e11444)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x01233798d136e26755cb671131fe5ccdfadbf3952b2117c59f195828080826df)
            mstore(mload(add(vk, 0x160)), 0x25f7eccae1b1b880a8ff1c2b3cc7dad3cf9a8841664f3bc8d00585be1a029e11)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x294b8570639b62dfda7697e71453487eb936ec11c99c09e6dfff7588dcbd8083)
            mstore(mload(add(vk, 0x180)), 0x025f7779e6a5c6e886500edd9b6b39d6dbc28b4c3d717300311d32d63eea6f57)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x160b9904f771f3fcd45ff6e9d70eaffa1f37ba57360cbf67a913e054b0b2ec76)
            mstore(mload(add(vk, 0x1a0)), 0x122d66f6aad21592b73587aae8f88ba29d468bac95ed9f358fd6a8361e5a5882)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x2eba75105adf4d2d77dc6f9b8d4df247ea19fb8c70355841dbd512193b80123d)
            mstore(mload(add(vk, 0x1c0)), 0x0ab7e4a21429aef4845c55eba84ac90f21776acbe6c527c5990239ca26c5a0ab)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x22c7c56b739081ec66f3eb41ba0aee8cb2ffe95bc8abe468a786de0772dfcca1)
            mstore(mload(add(vk, 0x1e0)), 0x0bd2a88cae73b8c33d19eeb7813a55070e7dd726c17fd9c85dd29c00041ceab3)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x14ee63b58bb535a8532329706c250b33ee6198c0c0bff1b2eacbbc15a5a59144)
            mstore(mload(add(vk, 0x200)), 0x0ba605d76fb121723f300a34bb352e195c9ea8abb61f9f6418a58e6192b839ce)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x08c5fafc69d127b0021257f3544e1e1587c18e901b1afdadc58190059d0dfe94)
            mstore(mload(add(vk, 0x220)), 0x06422697f69f6673ab40d15c9aac4544f863f1d92baca5e30d55f73d9b823f28)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x13b79ebd1cbd6f0959a21bce13293779cb948f7fe094eee296d72f5c387d3c59)
            mstore(mload(add(vk, 0x240)), 0x2b75ef4a9d53c0d31af619b4ac115255a5a7944bd4e8604209aa7919aa448d92)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2fc3a19b4a0061a5b1c6c88f8d9256949bdac72b7b0bc450277722fb54636bed)
            mstore(mload(add(vk, 0x260)), 0x1ff1deac8e8c8a2933acfb642421b72fb4bf582fefe459d298fa9ccbcb6d8da8)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x2605ebbf0ee1bbf8a18fad3e25e4f040341a07c5376787316963226db59f944d)
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
            mstore(mload(add(vk, 0xa0)), 0x0cb0de9e8bd32b8f7d07e27760a940f0934e8fa5e54179a00bda63b073e35526)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x07dd8de270931b4419b9382986e4f897c05dfb505a4857d8c7a51fab0257d822)
            mstore(mload(add(vk, 0xc0)), 0x16cae7e32cc43c1a5a766eedeb544743ae215006ab0cdcd1eaee6ed4221d5d1a)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2e0e702a34885da755fa60e817b02c5f55a81ce0beb0a59426f338d56346940d)
            mstore(mload(add(vk, 0xe0)), 0x15ac7165dff3b556ddee3d61c4a5778691a56a10dc1a9601ebfacd84d99a4cbd)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0bf33e24fb82095c9c9453b17a4708101623383dbbe69d5ec3520ac1056dbbb0)
            mstore(mload(add(vk, 0x100)), 0x1958211b1b07e05f3d401cce7c95a7f5fb18161eb2796932469362c059c143fb)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x1b9c6d6bcb72386c2768487147ad6c542ab8251f34ed959b7299e83d8af82da8)
            mstore(mload(add(vk, 0x120)), 0x0c7e00b0d102af46ae32ab1af1cbcba0a5c3f9e07167625575bfe2485dee0896)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x24a03a4413a83b8a31b69806607287b2aec147c62f562449c85b2d00687acbb1)
            mstore(mload(add(vk, 0x140)), 0x0388c2da82e27b08b803dbd62c347acfc4141dc1f22854628b2ebddd47425559)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x1109051a82d875fa9a309c14265bcf8afbd57c935f7d0ab21388ac14f9a05569)
            mstore(mload(add(vk, 0x160)), 0x034d69adc3bfda9e00672093efb450041fcd8f417a9371838a8375e1426497da)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x25ffd0f010a7089fe83c594149250a7505b19817c6e61f80c2ec80f9fb3087b5)
            mstore(mload(add(vk, 0x180)), 0x102fb27f86cb9cb91307e021398172b918344575f165316e282b6235ae85eadf)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x1d83ac034ef96bc84fcff66cc285c4406a971e75961bc6604b72d2f760ee6443)
            mstore(mload(add(vk, 0x1a0)), 0x1c91246ae88554510e5a12c953e1bba891fbea75f12de7d939262003150d6e89)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1098b5826555f36758820278267bc644ec6f3791bdc3e96960c786b6ec21f4b4)
            mstore(mload(add(vk, 0x1c0)), 0x2a71af2c5ed0a1749919832f036eba54cfebdf64b10fea7b23b01e232856ae6b)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x0a4cf2eb3bef3a451cc6f1a5bcfa067a881aded8cbc7b4f93093fdc5a58a5fb3)
            mstore(mload(add(vk, 0x1e0)), 0x0f166177d26cc007cf02cf330aede53e5a0bb08a802fcfbe27500fe8df43ab25)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0782dd0a51f0982c363d57aaa0bd4abf50cc8914c6d40d17e47114701dc6f4c6)
            mstore(mload(add(vk, 0x200)), 0x2f5aec26a6b3175a04cb46d57bcd3992f4cd8c8533bbe8e6832b381313bed69c)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x26791acc4412b71c43b6f2ee4897bd271e0a21f156c3452044a979b0a127a42b)
            mstore(mload(add(vk, 0x220)), 0x1e78cef11d82213e798993918652c2186eb2dfa9e92d4e464b74f6b4bb4674a1)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x0dd7edaad86bb92f377221229114c853874df0c4f393e8d9995b451044f6061d)
            mstore(mload(add(vk, 0x240)), 0x1c7f696041fd222635a1111f7ef5cf752c965caab29f53e3866594458549a9cd)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x1fe465f0ace4c2a19665e4d580676cc4d4d25997f50ba402882dbb292cca5cbe)
            mstore(mload(add(vk, 0x260)), 0x07393c69b25639d3c853f8e1438945e9d78dd45f148258d65a5d2d33e36bb968)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x04a321290f2ea38ad3ae988d7f1fc01553293deda3c8ae2d134f728ef018446a)
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
            mstore(mload(add(vk, 0xa0)), 0x0706c08f355c0b2c6d09433c2433b5e6018e7bf87da7a814af8364685db33163)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x2a003a2ccf6affa34c8b866ea05fac13424b9bda1c77e7121c70b3c54ceabd59)
            mstore(mload(add(vk, 0xc0)), 0x10ba37223179e6377c05a7508ee8e6b51c07bc6454bad11e37d97dfad5a5f28c)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x047b24e0019e2f2d12a1c687ffc331df4d1bbd382546f018b1cbfc4b060d4e82)
            mstore(mload(add(vk, 0xe0)), 0x1e8e675413746c77d7ea50c98bc64bc019b7ca0553ae33270178afb37cf18105)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x1054961efc510069ac04725f4ac7d17344e77f751250a97eda719b918593d1cd)
            mstore(mload(add(vk, 0x100)), 0x26a1ac65bfd7947ee4a7f693cd81d9956cdbdc6170ae85e831489c9572503587)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x2a18515f918f28f06341e710f1b6cbaf409a044a99b236365eb748f1e075577b)
            mstore(mload(add(vk, 0x120)), 0x244931dbf0a9d057340a6a96cf55cb4a38b99ac3150cd6772024e9dfad5b1393)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x2943a029d17a776cb7c25e124ebb036413a0716594955a1085448d1e82a1b378)
            mstore(mload(add(vk, 0x140)), 0x2dc7839c7e81543a3bcf16fa2c3f9f907828d027557d0d650aef9a8dbdcc8f69)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2eef3f178711b589655c0cc27ccae7a8fe0efac72df2fec18ae968fe93f006bc)
            mstore(mload(add(vk, 0x160)), 0x08a4ce8532b322e778d7e9152384faeefc3b225577944fdc8465e16446f2419d)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x084c13508a012fad40e21f903ceb16730b032d425549f9946eeabfd05187c245)
            mstore(mload(add(vk, 0x180)), 0x04c5bca390b8f3ca1157056d86f1a8f3b6df2987f94f0c5fc9cbcde5a546ef64)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x1a7f7fe979991a6d414509360b59655a777c0e8098b37647acf7046aec943aeb)
            mstore(mload(add(vk, 0x1a0)), 0x2768569fd3ba59851d7ab16bd209ba837543c3cee50b0e0a93cbaf00def34793)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x2dd72927cd481ac6b0308fcc5376e63db240c0894583b48ff89f5c242f230c2c)
            mstore(mload(add(vk, 0x1c0)), 0x2748138851887e9a348b81f0411a2b3adbc66332d52baa65997f0bd0630b13be)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x06354b54646132d4a8e2521ae538b65f3a2255e2fc0a2b3e76b23bf55beab28d)
            mstore(mload(add(vk, 0x1e0)), 0x102e15668c315c11aec87fbd832be9375b6fda2e5d11c7ac72c88b0f806372a7)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x04f290282bece3c71ec851b13412a44d150faf7b120820c89e30bd8820eb9c9a)
            mstore(mload(add(vk, 0x200)), 0x20ba6ec939a0a2ee3758b2aed5731ae704da73fc28d28507da56ea5dd73275a1)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x2aebf62ef95465c59edf6ea081902902dc063d44d694764794edd8f29aba1518)
            mstore(mload(add(vk, 0x220)), 0x28075b97c9125abe072dd53c1bffb7c71a30c6801fe2dd2ef6d748f0c04515f1)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x11ea3823b322c6822f2b08c9a04de01ebc42b2832584d69e85a66985c46cc461)
            mstore(mload(add(vk, 0x240)), 0x0037f2a07b4a46d582181c33813f1d68f011765eb12f966583be452d5b838f61)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2470db8fb2aa5b9ecfd0f0b9e8a20f595b1a230bb8158df2b0ad16dda7464741)
            mstore(mload(add(vk, 0x260)), 0x0f6b5fb55a2c1c8ef2353450066d34b9ea106d309a09dc9890a87e5bda861f68)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x264d8bb3bfafcfa8fb0ce29630ddb1f906a5d17aad610940058874033f44a8b0)
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
            mstore(mload(add(vk, 0xa0)), 0x2a7d3ac3ab291cf97cbea8d6df19e7f7ef399960f99298777776fce73184d436)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x175bc9bfcce438148f41258eae2d6f98db8948aa7179272d7450f3cde754aae4)
            mstore(mload(add(vk, 0xc0)), 0x2cc298df99321fdbe8ef84c15722ba059da9f99cbaa3919d9edca4e1ff73f63d)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x171103f5237184bb424ca7d45fae073f0eb9c94897a1c4c23916506d3943d07d)
            mstore(mload(add(vk, 0xe0)), 0x184aca5cbf50be3bf44e27a2866c4b82f5ce5b432543d458da9e62a8f8347c90)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x1f9e41dce60049cb7f8601b012515d542f8b73e49f07818b53e43a0c48985908)
            mstore(mload(add(vk, 0x100)), 0x27567ef240cdae19466322d234ef78a5b54c44fe9e6d18c5aefb45ea1b9fb58f)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x0664ad5ebbb9e3e3dab5df03882798a3f609c784f26dc6eaef69eba99c5618e9)
            mstore(mload(add(vk, 0x120)), 0x0de7f4fce898217d8f647f8398f24d2c0c761fdcfbe0623b2c8d32d1f0464296)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x15a75f8f2a74e531c3754777d8dcfdfafa519754fffb731e87ce06adc67da196)
            mstore(mload(add(vk, 0x140)), 0x1a29e359d4eabe9fdc96fd2dcf551a300105619eee8524cc889fb5507fd26190)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x09eb8cea053af8be831b6bb142e008e44366f06b2939eaaddd9daa50f57681e7)
            mstore(mload(add(vk, 0x160)), 0x2bb8d94b933d39c7bd7a13ba28f9d710a2e4f5f1f20e383edef87e62b1b4b946)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1c3022b7bcaa922da81853613b6cb710e4582f8526a309151d5ecb894de49c2e)
            mstore(mload(add(vk, 0x180)), 0x2d141d81635e4142a5b7a2464c0c9b380948f80ea88e6ea643808961ea1d93ad)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x14eac0c95b3f747d94d7d95e61609ba8cb34a3c473616dcc264b4cf210fc9911)
            mstore(mload(add(vk, 0x1a0)), 0x1acd4a353ba196e68a0fe3e9cf8fabf07b5626c694234858b62e2c57bf6f5fa7)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x25205fcac837d8ee2e5a55c1f56f4e58a7d38fddec96ae52ddb26258b0227934)
            mstore(mload(add(vk, 0x1c0)), 0x1b30408ff7c9401da4b8ad60be0f8a81cbd005de7778717195a1c3ef5731b0c3)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x21d94a276fd892f828e3e4db3cc3fbd5fab6a9c9a50904df5134133cd10794f7)
            mstore(mload(add(vk, 0x1e0)), 0x021ae51dfdc35471fbe4c0eb4339dd2d23d4c2f01b1baffb8b186ff8a50d415f)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0c8abb188aa9c1e84c058a8995731f353e35c6e37ae97598a5973432b0820270)
            mstore(mload(add(vk, 0x200)), 0x1d17f70f3bacc45af3fde7012ab94042a428d3e8104248ce13f0c32acfc04f14)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x009dfd3e2cc720105d5eb636e82a134b5c4cdc11c0e228be3574b20cf0852da9)
            mstore(mload(add(vk, 0x220)), 0x098a7ae79b645a3e8f48dec85f1dce0f763201945dee0669d7c4d9591ac756b9)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x2cca2cd8bf12a377e3b199e84c58b18541c32c5ca4fef65991ab138962f8967c)
            mstore(mload(add(vk, 0x240)), 0x264556931288e82a64d6d71c702ee72952332b50cf71ee959a0f667036562b80)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x21a06f38dbafd465eeed460fa54e6eaad2962c5a64ddcf00149fbb175cb365ce)
            mstore(mload(add(vk, 0x260)), 0x0abfbc2cb193caae3750e9a0a73fcc50edf2ea3caae08a4328fb06d933e7a7c4)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x2dfba85859fbd97321d4eb0ddba4c4fab3f4716cfab432174ba3c567695d71e9)
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
            mstore(mload(add(vk, 0xa0)), 0x0622125c4b852fd0ef25e6b388c447c3d88fcff945cf13898852b62e91280fbe)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x234df1b2a7df5be874b9a10c13dc60d94b32f4506d8f0a2145dce59a47b5d070)
            mstore(mload(add(vk, 0xc0)), 0x28c3c306fb48b6dea46ee5ac66a7618279f92bcc1877e70794636564e4c6156f)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2eb874e42eae37737f5c22010240a5ec916c01494ed16d774e5f41876ae41e9b)
            mstore(mload(add(vk, 0xe0)), 0x0d1e33e630b975a33760050fe8885a43db4d2f5122e5fcb94ecef20eb980aff9)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x038721a5bb474c817b3f41f8c6f71a1666bfe2e3445ddbc3cfdc7130623bebd3)
            mstore(mload(add(vk, 0x100)), 0x1158f3a8391ac5e4003fa173ea384fe51a1998a113880803b5cc1aecfa0aed3d)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x220dad6630ad6bb541b59aedb4cb638c98e29f61f272f08c00bdd1a7e8abcff9)
            mstore(mload(add(vk, 0x120)), 0x04578b3c524542c413ace8e2c6fc8c90b175ef1642ed840dbe7087b3238f5d61)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x1265e93ce2cf3ccd5bd203f2bc23f07e2a7e766109b787723143d70ff23e5de5)
            mstore(mload(add(vk, 0x140)), 0x19add4a25014b7c77565451882136caa4d8a6f7a54f6ca42a562fbb09b2c5db7)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2defbfd386bff36ed819930263fc43d7a9f03863c75a9c1c13d2b1e9f8bbdcc7)
            mstore(mload(add(vk, 0x160)), 0x0758b6c2ef3126105ef4118042b73234dbb2b30a0949fc8ae2928fa04725e4c9)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x00bce08a6909a9ce4c2ed85ce1cd25b554dd915dbdf55201596e2f9205ec92e6)
            mstore(mload(add(vk, 0x180)), 0x2143dc0665ba090f050fdd7094ff1230f1a8fb1e192d3b41e3b23d6c71b4870e)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x302f04fa836718f182619bd53d37270bc19c0df44382c40230919ff386185e5d)
            mstore(mload(add(vk, 0x1a0)), 0x0523a0a34552e6d88ade0159c22e02b161319dec092fbd86656a99e5f9500fd2)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x0fecb66c9aeb2eacec66a943685a2610dbf34daa8ab22190605dfa3f9c739f2b)
            mstore(mload(add(vk, 0x1c0)), 0x2aaf30fb73b6f6a1989ca935a0ab07f4eae535c0cc7fa45921c0d75fc4c8102e)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x0f2f9c254c01c78f9f81bbc3c521fed42deb4f9d0776391f67104b8e3ef4f579)
            mstore(mload(add(vk, 0x1e0)), 0x2f9cfcda7509c0903a124a4c7c8e6abed8be32bdffa97c0fd552e07534fba046)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0bf6ad133332e36a9e8d4666bcb26b7a895992f580f55255b9fbf79c1e4ad499)
            mstore(mload(add(vk, 0x200)), 0x0f1e498d31624d3affb3a8f73d6b20e1456bc4c8d93d89f8407a3eb4bb924b31)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x1ae29045593e2a9de0262d95da39b799da8b87f1a52bfa6d0b691f01f399d611)
            mstore(mload(add(vk, 0x220)), 0x1a1b0614d90537219ae0922149afc9415bd8f64e50eda7a55924c039be65fdb3)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x1fc72848ebe77952f8a89237da6ef864851cb540d9d5afbfc7eac9c7a54644c4)
            mstore(mload(add(vk, 0x240)), 0x2efdbde7ae53d541ff526e3981ea66370f4d639c8e6ae7ae589da576b80aac06)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2e2ac699a73f7573844d23e5bfb69af9c42fd9b14014e857a02e691a190fa1ca)
            mstore(mload(add(vk, 0x260)), 0x113d0c7629c021c873ef717487658eb15e73c2dc8a58baf721c74f8f85143f54)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x0d879172c7dc736c16974a866535fbb3c89b9834a280bd775263e88c53aff5a2)
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
            mstore(mload(add(vk, 0xc0)), 0x27bb9587702025db4eb9dba04b9abfcca1aa16a24a4692e90ff4197208ba21a9)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1974fa1e729ab0d97ad38bd1c212617f9f2fdda1ef38ad6571549992b9f512a2)
            mstore(mload(add(vk, 0xe0)), 0x05c63dff9ea6d84930499309729d82697af5febfc5b40ecb5296c55ea3f5e179)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x270557e99250f65d4907e9d7ee9ebcc791712df61d8dbb7cadfbf1358049ce83)
            mstore(mload(add(vk, 0x100)), 0x2f81998b3f87c8dd33ffc072ff50289c0e92cbcd570e86902dbad50225661525)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x0d7dd6359dbffd61df6032f827fd21953f9f0c73ec02dba7e1713d1cbefe2f71)
            mstore(mload(add(vk, 0x120)), 0x14e5eedb828b93326d1eeae737d816193677c3f57a0fda32c839f294ee921852)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x0547179e2d2c259f3da8b7afe79a8a00f102604b630bcd8416f099b422aa3c0d)
            mstore(mload(add(vk, 0x140)), 0x09336d18b1e1526a24d5f533445e70f4ae2ad131fe034eaa1dad6c40d42ff9b5)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x04f997d41d2426caad28b1f32313d345bdf81ef4b6fcc80a273cb625e6cd502b)
            mstore(mload(add(vk, 0x160)), 0x137bc4cd7621f6d9eaa4c76f6070e28d09a0ba81e56e413b9047200bd318854f)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1edf634bc8e7ff5495012ce1368bdab088b6f972095de12d920154c64295ab28)
            mstore(mload(add(vk, 0x180)), 0x080189f596dddf5feda887af3a2a169e1ea8a69a65701cc150091ab5b4a96424)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x16d74168928caaa606eeb5061a5e0315ad30943a604a958b4154dae6bcbe2ce8)
            mstore(mload(add(vk, 0x1a0)), 0x0bea205b2dc3cb6cc9ed1483eb14e2f1d3c8cff726a2e11aa0e785d40bc2d759)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x19ee753b148189d6877e944c3b193c38c42708585a493ee0e2c43ad4a9f3557f)
            mstore(mload(add(vk, 0x1c0)), 0x2db2e8919ea4292ce170cff4754699076b42af89b24e148cd6a172c416b59751)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x2bf92ad75a03c4f401ba560a0b3aa85a6d2932404974b761e6c00cc2f2ad26a8)
            mstore(mload(add(vk, 0x1e0)), 0x2126d00eb70b411bdfa05aed4e08959767f250db6248b8a20f757a6ec2a7a6c6)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0bd3275037c33c2466cb1717d8e5c8cf2d2bb869dbc0a10d73ed2bea7d3e246b)
            mstore(mload(add(vk, 0x200)), 0x0ffe38e772df83946d748796cc084a82b48256f079cca66195a91507162d3269)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x150597d86cbef95be2421df1c888fff5dc553bdedf96ce05f3ab6166b779113c)
            mstore(mload(add(vk, 0x220)), 0x097dd0e2a921a8ba163b4a5eff4788ca569f446e7fb4c293f3fb6636fde6b0ab)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x0251a0a84f54f1d726f97517e3b365c7f0744ad91b6301700bf8b6a4f40a2104)
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