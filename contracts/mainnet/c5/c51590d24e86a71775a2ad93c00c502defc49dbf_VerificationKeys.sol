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
import {Rollup28x8Vk} from '../keys/Rollup28x8Vk.sol';
import {Rollup28x16Vk} from '../keys/Rollup28x16Vk.sol';
import {Rollup28x32Vk} from '../keys/Rollup28x32Vk.sol';

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
        } else if (_keyId == 256) {
            vk = Rollup28x8Vk.get_verification_key();
        } else if (_keyId == 512) {
            vk = Rollup28x16Vk.get_verification_key();
        } else if (_keyId == 1024) {
            vk = Rollup28x32Vk.get_verification_key();
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
            mstore(mload(add(vk, 0xa0)), 0x203bd0f897802b3e260eb46829df30bff8321fc1877ff373a17d1ba324b22cd5)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x28b13b38988e513632b856ff030e6a3362dc4bef91c348f123a2e737470593b3)
            mstore(mload(add(vk, 0xc0)), 0x20245b5b3783acb959d2ff79f239067b021ec3b7838f97b5302fedde63b335a6)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1e49addb9d01d9745bea8270befc5688c3d6316dd11afef8e4056faa632e35d0)
            mstore(mload(add(vk, 0xe0)), 0x058d2ad96ae78fc327d2d7bde393fb79ce7742d2a7c6ddab3a0b7c0a69ee9df8)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0afa953b470dd6e4a54a4d99479b2d217eae2698186995809d791a0acc705c6e)
            mstore(mload(add(vk, 0x100)), 0x0cd955e915b07cb230cf7d4886be4f8f72367f98c0a694fc63c7333297103264)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x114a54c76f958d38f9ec082b34977713e60a5dba1c34da94eaaf5f9d5061dc9b)
            mstore(mload(add(vk, 0x120)), 0x1bc5d6ce77315e3c1dc23945d94ebdaef4083f231ae4f9095314bd7b38b85424)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x0d32293f33c4e4df2411dc772d7666f2ea2af813d1fe5ba683c84e6ab3261c3c)
            mstore(mload(add(vk, 0x140)), 0x1e83c90ce5f94c6e4eaec974300e4b417ee3f257dd3230ed0599e7958a8ddb59)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x102c576b75dc6f56d2ecec3b38c8263625f24146df202a9ecd2bbe256ef70c5b)
            mstore(mload(add(vk, 0x160)), 0x0ed4a31044247879e691d48a1bb1eecc17c23668f5632e8a490a37609f4de396)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x0814bcc85a02edf0621c0bbc9c6269bcb801d2440b7ea975c8d337f997838162)
            mstore(mload(add(vk, 0x180)), 0x04d1a6b766fb03e40a92e7ee52435146ef367a44af4548bb573d69d14ac1dc04)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0a50d29fa71cdf5caf9780d7d90baff3ac3d208023b634c87247b1bd3fcbdc98)
            mstore(mload(add(vk, 0x1a0)), 0x035d65e63f0f5d65af58f54283d54517698b62a9eb6f97d24a5ecb6d2aaef4bf)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1704b058b8867cfe2b24411b0a98472d64f479280d9de0bbe8d01a38e59a2a1e)
            mstore(mload(add(vk, 0x1c0)), 0x2c75191104b195b3898216fbef70e7699dc57c23d998a28790a883875bcd4b87)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x188efdb9601963bb6483814778b7f494a9759ec64ab3e7cc80a02b60cdbdd1a0)
            mstore(mload(add(vk, 0x1e0)), 0x25360955ff3fd4ff053f2f8e6cc363596ec3edf4c8ee6bf1460bb39194ec3a8d)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x2cb830c4b0989093d840bd0b7332cd9b054289b9344218fc2b7a1c1741efe965)
            mstore(mload(add(vk, 0x200)), 0x10c1cc2193880a1b8823da67052e926770d4d98ea10caec75b7ddefe60db1d3c)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x13fe1d19280835eab52d73ce9f656021c3c751675db3989ea21b101fa60242c0)
            mstore(mload(add(vk, 0x220)), 0x10bdae0660ccb52cee76aaf9264048e2ed0a143cc946b98a6f72c04279228dd7)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x1cb2275dff734fa3647220d31abd52fb27e3b5174a8e2f06f8facf3e3cc9c8cb)
            mstore(mload(add(vk, 0x240)), 0x1cf266290e2d6dadecb66d8a0b8c00c10c8fb1f6a39d465fe235c2f8f96825e8)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x16b39ae14c6add4e14d9a76a684c84529096c5b842c678f30428ce69459f3491)
            mstore(mload(add(vk, 0x260)), 0x26ece0fbf28d9beb13cde905cf1193306145f1669b6502bf0fef09bb911c2ee2)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x2a14826608a3683323b36e3d6e96082197220178022edce202f99c2c89a1d2eb)
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
            mstore(mload(add(vk, 0xa0)), 0x1d13ad067f036f7b6835ff71ddf7ce8461e5ee8a073176a5d2eec2880e1e4194)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x3049f49776312ffddc827c17e160dba10ce16f1408023f1d12d228f4d6f9974c)
            mstore(mload(add(vk, 0xc0)), 0x219b6bd918653613a233fa5ba0c4fc692d3237d2cd33aba04bb21ba8bc120f37)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x2ddac179e527f3c66ed644c9f5d5d4e982fa5d4f1a08e584aff04c81cbc53e06)
            mstore(mload(add(vk, 0xe0)), 0x2874a03931ebc3ec83658a4e7a6aea6b6994e8da68e2157af9629899bea0f5e6)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x2abfcacdabb3caf0795e4831fcc3146446e2450c427c8937b65edf010fe8a00e)
            mstore(mload(add(vk, 0x100)), 0x2dfca9caf50e90d767f5a68b7ecfc82752c6011ba68118c37d119c0c2887ec47)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x1e756162543021c2cdb16e083409dd0c3f9527fc73b65d65385eaede78cbbe61)
            mstore(mload(add(vk, 0x120)), 0x00f6c213b2eef0aceea90c27e0b0e350cf36a2a21a712acbb0ad88016310371d)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x26716655f12a4bbac00915dee1c2151b8d7b902a68e44b25a26f47a99f9274ea)
            mstore(mload(add(vk, 0x140)), 0x16806ff0c438bce6c8e3ac1aa61a453f75696b9ff57a9c561faecf23d78de24e)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x225a04ec57f47dd9bc8efc07a438984862da1ce9433e993f27566614ba221e0a)
            mstore(mload(add(vk, 0x160)), 0x16a8e4f6fbf48a821a087159bc2cba8f8c36eeb5c04126a2eab726c1c01c62eb)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1e70a9a8c70f089b6806e1b00d523077df261dc1aed8ca90438c8018a686fee5)
            mstore(mload(add(vk, 0x180)), 0x1895ef1a566f21da8c95b93d8ae3c0d920db7af590f6c41df2de26c11c7f3b35)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x01a13a95347e23143d52c8c95c80d176fc812685e0ddbe5ff10b7343dce4c61f)
            mstore(mload(add(vk, 0x1a0)), 0x104c7f7665488130081554fc5a7d159133633883c7480dac6f841cf0cd275934)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1fd01fec691179cd0d0ef7da9b589faedd2ef9807edaa49aa0c12738ca56ea9c)
            mstore(mload(add(vk, 0x1c0)), 0x2cb448e7dcde5a70a5b0f5fed37843646cfe3512b9246fabbf3e51ec6e75ff24)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x280573bcde2d93716237b94c0ae6201099a600e1361de62bd2083fa66256eb31)
            mstore(mload(add(vk, 0x1e0)), 0x20c4448fc460258023f509d7fd0d26f638f72d46b3a05f54ceafc67a94b29e71)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x158318fea15185ea59124d26513e0071ff8766bb9fd7f3b3e494df2cf6220c05)
            mstore(mload(add(vk, 0x200)), 0x27e38b8d2a2bf982391650f02d76b074719f99ee42721a431402d14f53b58115)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x0dc2a2e770ec49454e426329b87d1e40194a0cf71994d81c8022ac8e8ad24c53)
            mstore(mload(add(vk, 0x220)), 0x15376d447b0bc1fb6c22fe3a2a46d6fbf564b5dddae950266a0e062279a2a362)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x0786c9b814a601c78c033752a5186c57bacb9fb292bff6fd83d241cd13562801)
            mstore(mload(add(vk, 0x240)), 0x2a04a60539ba5e01466cde91d0793813f50bf15cf4ffa62f7fe76b7d84f5cce6)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x147f221a17f1dbabf1b289bbfeb689c9b0b7eb63630b6c6ee95b0c9a64e13f8f)
            mstore(mload(add(vk, 0x260)), 0x0cc582c12cb49ca03287d8ad1d6ab069ce12468bebf662ce9c5583f12e5bee4b)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x12a893f7131692ca1119fc11d5fadc5872912837fcf516b64f8703635cfc0ce3)
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
            mstore(mload(add(vk, 0xa0)), 0x160e6a4586108fee8a7f22b07e4a8624154d39d65ee0fbed8034ae85aa1c5279)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x223562449a7a88c08051309a6817deeee0e54a95ecdc6c5187272246ae122847)
            mstore(mload(add(vk, 0xc0)), 0x195e8a95efb89a44657f9d64484586cd5eeb758f0bad9ac266220f1b4cc845e8)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x177ca44dd3591e42e92abe07baf40a6b57fa3f3434a139a15f5b233d61bb74f3)
            mstore(mload(add(vk, 0xe0)), 0x07045da9858689e08e73cd8326714b797e70be4810b447f906c77d96fe794436)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x059ac2b0595db9e58403c8fadc649e89504f0d6f68ae7735cc3fe384a6ca36f4)
            mstore(mload(add(vk, 0x100)), 0x06d7103241d14a134e31f0acd3ef93ccf51a1358b46314e0cb238a48b155ca59)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x11aabd4945658c422f944b319fa254fab6303a0f3fbb3ac39c127a0620c04125)
            mstore(mload(add(vk, 0x120)), 0x13435d57fe4342bc4779b1c1eadc3ab4597ab754e1ab4e4779f6c0ecba88a687)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x185b2abdf67ff6900e7e87f541706d4c1a4b3e5faa009ba7e9ff885ca2c3800b)
            mstore(mload(add(vk, 0x140)), 0x0d11c50eb658a8fa1faa425ee2def281225ff4d14a1a35a80dd6a2fc1cb10855)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x144df6bea9b59c383c6ed7ca7b390a6864c5d1798c20d028344a7839335b4030)
            mstore(mload(add(vk, 0x160)), 0x23a57379b172e76b42c8a197dab5015d500dc6a27f0653cb2f8a4ff5aeffbf58)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x06c151eab97ba30a793cb7640c25cc545d00773068e42139892280e6b3cf99dc)
            mstore(mload(add(vk, 0x180)), 0x0e9aaff2623c4dddb802514ef5e99dfbfe34819561a012bea365994a58e6fce0)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0a5392b4570bb126f551c95f5ba48f5e687822345987c4d61cc1870bf1cb560a)
            mstore(mload(add(vk, 0x1a0)), 0x077420e28b964721a58d2f8b676db09770a14ebe405524eb786ef471299bea0c)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x2ec87e355ea9a6fe661e129945fd4c05d3cce95ac2dc32c766a54fd4565fd995)
            mstore(mload(add(vk, 0x1c0)), 0x1ae39dfb496a35c9e413cc9686165a9fb5a3b688bed6e1ae85d1ba57d633794b)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x2de20f8dfb87c84a222f107f881a814313a5e30c7d0b63385a45a98d895d8175)
            mstore(mload(add(vk, 0x1e0)), 0x00681ca5f0148be31656b3ff29af8a6b03569c9f0addcb9d41a4e7d6b7106b51)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0bd744f3059f7ef8d645a8d6204d3c12d008787fcd36c0c4eb79779bbf58a57b)
            mstore(mload(add(vk, 0x200)), 0x2ce9227a023e4d481fa024381cd0f0b3efa79f84a5ed2f037419cc76f71a32df)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x1dabb3d66a53247df00cc44884363dce5eb28560cf9f12c53ec20be89ea828f9)
            mstore(mload(add(vk, 0x220)), 0x2f28f547c1e658265711d6e9500f352e43a384f9290a81cd6c7d63058daafc64)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x09b4222870e8a7acf5d1e9565da25bd2a693c660a6bed8230f4a27cf3194b230)
            mstore(mload(add(vk, 0x240)), 0x2d647bbead52a7e6fc6a64588e86aedb4c8e82b0ef8ea83aacf06b37959ddb69)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x14bfd955b808afb90f4d4e99beaa6015d1b4a47354146143b3ebbc7729f65eed)
            mstore(mload(add(vk, 0x260)), 0x069d5a3aee3e963edc76714ea784ee4b6bca821f4cc8889b450b23dc2bf37e5e)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x20ee1cdbf819674d4b737008b6120b526d7ddfed2962733666ca108f15953505)
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
            mstore(mload(add(vk, 0xa0)), 0x20c3b1f6da75a02125fd172b2f89571ddf8a3bdbefff1624d5677eecdc7b83ee)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x2e9046591f50cb3d830f378a7de9997952bf257d7cd6f8b9eff3257310c05cb6)
            mstore(mload(add(vk, 0xc0)), 0x0fdb81dff3306b2751f20e554cc3fe16508dad7e10abb2a4acf658c1c974562a)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1f798ebef49709fbe0cd9bd3c1e07221b3eac1ff4ef2d1142a79aa1eb2873e7c)
            mstore(mload(add(vk, 0xe0)), 0x198f888e8ab414636d44e07aade430e8e13e20f8f606c306fd85ae32005b917e)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x1b8030742fed696820608f0692d92a59954c495c277676b6b586b01d321cb454)
            mstore(mload(add(vk, 0x100)), 0x24f170225fd7569dcec212ab3854a390dadd5908158dc604be644a99fbd020aa)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x1922fdd43ceee396ecc853b5b9f75840c9423275ed10325e13507bd3a56ca8ad)
            mstore(mload(add(vk, 0x120)), 0x2ff0bd2b8a3695c8e5d6744934b63a4168f5b008f8f02542760377eb9ec091ea)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x1c3c379ff4393bea64bbfc6bf7386145b249f387fdf2b2c01ecb0a86c12a0218)
            mstore(mload(add(vk, 0x140)), 0x025529f2478f861a8d44d4ac741bda329615a591dc5079ca25db3dff177ab2e1)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x215663e4138c943cc935a466ee2ad0fff68168d39865ca0a2681e00f8accef03)
            mstore(mload(add(vk, 0x160)), 0x06c098c8fc0f73360b0bcc0d67cdd633991145eeeb1c46d1c4ded94974df811c)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x18a07ca4716eed8aa4323851d69b290d1b590db232c11b3367d7d5c7ba891324)
            mstore(mload(add(vk, 0x180)), 0x0234bdb57026f0f29391273502a878e84566596c5c86dcfc48b96f13b192d0e4)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x011e56653f2c8c87648a8789a4bd89d87cd117d91943c6f5fef36b69b609bfd2)
            mstore(mload(add(vk, 0x1a0)), 0x0dbfa028b7725e3a265bc4e9b81a3673f3ad31b0e1d0d6ebb6b83933221efd46)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x10a9401ede7455864995e42092b64459f8afd0f0adde1713042370b7ce95d48c)
            mstore(mload(add(vk, 0x1c0)), 0x0bffa1c6d75dd184aa06eb363ebbc54da8bb9ba8d77530676accd99aac9bb0c7)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x126113745df8697ba05e5d0ccee227c75e1aab6d1cf559f2de5dc67d3a652ee3)
            mstore(mload(add(vk, 0x1e0)), 0x2c08ec515cef848d88ee08677817c978e841ccca2b146c8b8b612d10ec5478d6)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x050304aae6fbb062c2910fc1ca392f5573181304f28d65cebc69a7a98b35c0d3)
            mstore(mload(add(vk, 0x200)), 0x0ff29c6efc77157837cddd0413c6108068bfc492e5433ae4b057480601b31d3b)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x247a1ef053a643a70bdf0d968941ac0504ffec79599b9ace88c106dc5c27136e)
            mstore(mload(add(vk, 0x220)), 0x15fc7bf37a10ba59d33d29e7e64da19716d57e66a08fdb59daefcf006a744f51)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x0538591473b3eec75ca4bdd61e6f2eb8c399f246da0ffaa59fbe8223b8717aa1)
            mstore(mload(add(vk, 0x240)), 0x1f2c4c03864e5e9757ba1a0d8cdd104f16a33d97bc6b738fc76cda336b3d02c2)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2dd7ff5f7c09c708cc6355172ddf0e5d9d8338eba59d98461e752c13b866e98b)
            mstore(mload(add(vk, 0x260)), 0x0ce0b16d4cf00309ac2df7cb9cc067876158f894fdd136e675da13b2bc72f2ee)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x1b29c952a5f7d4564fae411e6cd3e54c738cea089808a68c9e072ce3a2735b8c)
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
            mstore(mload(add(vk, 0xa0)), 0x0f5bcb595e6cf0d0971aa1c14a153f931793cf2eb1e5c7d8b254ad3e04a00f38)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x1c7e2b4449a0b79b9d69c1bf6437cec4a4aeeeece921c86048b466f623c3bec4)
            mstore(mload(add(vk, 0xc0)), 0x18743dd4c07e51f5192f627f1581579ceeb1a0f66c401d3df6ee920c7e9b535f)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x112b5ca0f83789f997be4b96ec0d2cc9e722b8ae38de687662f525e52bc3263d)
            mstore(mload(add(vk, 0xe0)), 0x0e9df11f40419bbdfff48efd72c2abe03f4b724039e7503a38d89d500bde67ea)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0287bba3b9207555bd2796d869094aa7f23ff502e998a741eeef8045f2703903)
            mstore(mload(add(vk, 0x100)), 0x0b516a57c852c656a844b7cbef1f48c1d6840f4892d713e817a29408f3364d9b)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x29a8f3d431431f0b3b2835b8cd4a39cfb87b648250fc3bb82653c9be438ccc38)
            mstore(mload(add(vk, 0x120)), 0x249782b1aad1d8934c75f6db570b4236173cc16958107df85c3f92c285a44b10)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x020d35e04b0be2cfb47091335861e69fc3fe765fbe8872179a1c6168aeaad55e)
            mstore(mload(add(vk, 0x140)), 0x2f4ca26da448fb9a2f2585e1f790a7bff3b18cebac743ea93ce6f03ebb49b2d8)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x18702a0972f93ef00da4f21e861759302f38fae52d271983fa060ad63f7f1e25)
            mstore(mload(add(vk, 0x160)), 0x150100966d420165f6e9bc86fadf24af5a81207e2caa3ac595697809e236379b)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x11cafba7b7020e93d766911e288bbae6cf535c080ec1bb024803a66b416e312f)
            mstore(mload(add(vk, 0x180)), 0x2e38e6252cac51d81c102098b0b37bb75a1b6a9b5135eedda93b5efd97690423)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x217530f9f78aae868233649b6ad1c249bb3bfa0ea00f2bdc39a2dd6e4e3eade3)
            mstore(mload(add(vk, 0x1a0)), 0x101d35ca0d418acec1da102a0b30a5493dfd0695ed781f447b4a32756ed6c55a)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x140514e43aba2576b34443144b9fead36ee85fa8d35a2925a4a38b8d3e216574)
            mstore(mload(add(vk, 0x1c0)), 0x051b63890c9b5cdcf5393e50f164dbfd7a8676f1a3de6a0b20faae8b2778df40)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x23973cede832f68167fbdd6f89aca606a05918fe5d707649a3b9bf4307e85bf1)
            mstore(mload(add(vk, 0x1e0)), 0x16987cee793578cbb589ad2809a892cf1a50dbbb4e7dacb1bea98296689dbdf6)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0bcd0ea4ddf722534eff63986a4facb34cf8b23a966c88da4238092c453ec297)
            mstore(mload(add(vk, 0x200)), 0x1466b5dc5187bc86515e91c63c5c555aece060705d7f2c4a3e04be90f51dafe5)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x03ebba799878863e1d37c301f398b69d21abb06ffa83f371ad366954cd27950e)
            mstore(mload(add(vk, 0x220)), 0x2aa07323ad64eb8452d21f94bddca046161c68273c22679d716880c887efbce4)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x01d33718ddfe960b28e3c4f484f334f97572f73fc00f5e36426cbb65921597a3)
            mstore(mload(add(vk, 0x240)), 0x098decdabdb93498ab8963d41c6bc34d281891635c7bc47661e2a2dee994995b)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x0a1d4c0f44a75442533b4168ac630bb7cbe6e16fc380a8671c5b83284f5be86e)
            mstore(mload(add(vk, 0x260)), 0x222b8f2057d0e6e60d5f3c94d0b4ae9e3ef35c5a7a34cd572713ab0eb4e1f04c)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x162ffcb18a6f4405efe16fab6973227769b5666c1d88bcb0598d780947477ece)
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
            mstore(mload(add(vk, 0xa0)), 0x15cde7305bf040ebdf69643ccaaa6e457b8b5ddbf6372cbc9920cd131932fee6)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x10f3abfd58cb632cc3ca521caac020b18f9d68dbb6bec8a26279ec066a3f35f4)
            mstore(mload(add(vk, 0xc0)), 0x04f20961b7fddaf7e996ed549562c4c7ee2024964eec50266237830166f43b5e)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1070e25ceaf135940f6edfeeea15ca3b569d9bab73f3e8ceb81f0c5eeee4a403)
            mstore(mload(add(vk, 0xe0)), 0x18f8e63faeeac3bdea214cef496c86157129762b084cd998b58996e2128c8c23)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0a2e09272721a3058a18e67bbdc3ed692077da867890218521942b2843f98331)
            mstore(mload(add(vk, 0x100)), 0x057d116c25cee4582ff5d8abc4f513762c14c85f52391a74c77cc3278c31eb0b)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x0f5b614f99639ae163fb233758937728f1a7a8f6b793032bee042b7010104c58)
            mstore(mload(add(vk, 0x120)), 0x01209c83527bd3b7cfcc84f773aabc98dfdf8219f1b815d767f5545393c2e991)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x08b2898b0ff93ed59c94fc8163c9cdfb70649a5763a65081d4101b5fa8dfbd19)
            mstore(mload(add(vk, 0x140)), 0x2a25af73d1d1e18e6996fefd4c93f131d822bcacc697cef6a4e01bf7789bb6f9)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2cd7d2f7991441dc21a9e03433c71a4472397cc6d26eab31b736c733f5e31cf1)
            mstore(mload(add(vk, 0x160)), 0x0a193f0cf79b430d0e0a563a5b18890d133071cd13e6dbd387a4c122d4495705)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x2bfe8dd9b3721cc2b2d8e7f227f1682838048d734c04396e02c5749035174e04)
            mstore(mload(add(vk, 0x180)), 0x055c5de129f19793389c3ce9b5a3ccb7cff247cc10d730a3b49eba7706081221)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x0cd78ca48d4076ca003747875c01c9ffa971ca8bc7128ee7aab1b929b67542ec)
            mstore(mload(add(vk, 0x1a0)), 0x1d76ab4aa28048497fc48229c668449f3bbf7948cd12beb6db95b2226c756b7a)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x0bf05f0416a2076ee22c907c2f83e89f51692ca20e0110a06b2c6974c43f9995)
            mstore(mload(add(vk, 0x1c0)), 0x23a35b7851a65fe59b1875aee30de567ae76104bc64052761f714dfa003602d9)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x22e7293cdff7bbf4a494781be5a653c559137c0e5be22c0d64adcf03242f457d)
            mstore(mload(add(vk, 0x1e0)), 0x0b224dd5b9e2a0382044e7f4a7da069e36d07c9967a6374bc027db3f146c5970)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x2199763b1e7108835424f82c983f16788a9035255a9cfeb89cc82be44e617540)
            mstore(mload(add(vk, 0x200)), 0x08ae072fc1a74e9076fbede3c25b1311ea90a36ae2f8901d17db2e91c2b13d55)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x18501b839feb78ab86be66c1692e632b291dd2f787fc608cedef72b82518ec4a)
            mstore(mload(add(vk, 0x220)), 0x165b3e3cf3ab8c447ab74861ba5a556da1038e5240551b8b4a2c03051f4fe32b)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x1bb7e00fdcb47173facd19b390514c74a163255f0ea4f724bf5c8d10dd7c4c20)
            mstore(mload(add(vk, 0x240)), 0x15882a6b69d15bcd330bc4bb7e250f4f75b9b80e6e6b6d9e79746920086fbc13)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x303399a0c0dee5d2177a5e11de42807970d61e4bbb1181d7cf8aaf5775cd065d)
            mstore(mload(add(vk, 0x260)), 0x15892f8ee69a7bea477e669289454f8c78d894ab8a4df1aafb8fe7e57128da4b)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x252f78df16fe34fcd40738256d9414c4e528a4d9040a84257b1e37a9a9844b37)
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

library Rollup28x8Vk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 8388608) // vk.circuit_size
            mstore(add(vk, 0x20), 3102) // vk.num_inputs
            mstore(add(vk, 0x40),0x0210fe635ab4c74d6b7bcf70bc23a1395680c64022dd991fb54d4506ab80c59d) // vk.work_root
            mstore(add(vk, 0x60),0x30644e121894ba67550ff245e0f5eb5a25832df811e8df9dd100d30c2c14d821) // vk.domain_inverse
            mstore(add(vk, 0x80),0x2165a1a5bda6792b1dd75c9f4e2b8e61126a786ba1a6eadf811b03e7d69ca83b) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x271c8cb8e0353266e1b74ffd052f437ee970344b3bdba32d27b9daf7340ea299)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x1972386c6c93a7dc405e8aa41c07e415cbaecdab6ef278bf56e01b10c5cd6438)
            mstore(mload(add(vk, 0xc0)), 0x132fedbea05df3d7d1c0afa5ab731d86dfd3adfe78e8f401538f5c655e7d12b5)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1058e36c5c3b214839d05d131a274a3e240afb6d0e8f946b0487ba4500b71d61)
            mstore(mload(add(vk, 0xe0)), 0x2675a1f967a193dada2cf858ace1771456439a18a7ff46f83428913dd1c8ef9f)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0cb5764f9696fc4c48e3171b07ae283028190345113e6d5065e188d1d0535555)
            mstore(mload(add(vk, 0x100)), 0x03d71f3e7461474b63cfd70c06c6d50fb63a6a560fda67219a9041d6440126e4)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x1aab392c78d3b30855a8d83c8c109156d5b0a9c6ceda729cd6292b613b7b6814)
            mstore(mload(add(vk, 0x120)), 0x0008bd57186e441c757eaad814dfa072bd8d32c3c6e5b94c2166d4b6a9118132)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x16721486092ec4b32de8096285900fd71fd2ecd332ae94c9f91ddc3d6d12322e)
            mstore(mload(add(vk, 0x140)), 0x033b10c9cbe2a07e6b8660d3892104bfdcbfb466113a65df04f1cdd9dbf321c7)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x03d8a20875656244cbbb62362fe3fbda0172f8e6c452f521249f9ae10eb7f064)
            mstore(mload(add(vk, 0x160)), 0x158472d5aed61d16cb9c30e637fe1d6082481164aeeffd08eae6213f4e5f5789)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x01c508193dee652accfe34bdb72c075c2ddf62de30d2b7df03f5016029142b04)
            mstore(mload(add(vk, 0x180)), 0x1435fa496fe410c306fc9e7d06083a9e5dd1fb4f65d50d04ebb62da395c1d65f)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x160dea7c98413a14541a89d19537d2339efd30bffdcbb745fdc23caf98eee987)
            mstore(mload(add(vk, 0x1a0)), 0x086aaa1bb2a062a1b573ebde11efa824d726e79ab297730f5d1cc5ae1e8fc340)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1604dc65788449a4ab7d5fc24e750ce8eff78c4538a336081fa9189782426af7)
            mstore(mload(add(vk, 0x1c0)), 0x2f1c19b03c877d24e2218e69ea277abb9acdcc52b61ae2986a39fa965c5124b1)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x29ab90a6e686f76b260cb704d3a379236456265988f5dabf7e09861b4c6acf2d)
            mstore(mload(add(vk, 0x1e0)), 0x187a072c1ce40d52210a457d4b68cafd62b5a7fb7209d29172b0b4b7751e437a)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x20e843404de170e738192f703e56ec543d21bf911981279d9a76cbdd70c01530)
            mstore(mload(add(vk, 0x200)), 0x1ef84519690456361bce5d972e244768f8d5fca3768b278ad9164e5c1f58b7b5)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x2851e50aa41328a7e43732dcd18036b218d6c6f7c1c7f5a3abad2972359ae570)
            mstore(mload(add(vk, 0x220)), 0x1f5caca8b1c5ecb875c4b6560655d4e4c5c828bbb487e287726ccd01e2cd4749)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x20d8df59ddc0fc47849d8906ad42fdd1dbd0c2334f991ce348bfbdf8a2b6a89a)
            mstore(mload(add(vk, 0x240)), 0x16d3cbd14cef190c1c98bd99d5099f1c6dbd0a1581a202501e17280e3c7a90b2)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x04320127ea4fa947a2ebf97824b292091df95176a6a96f5a83515f20cb69bf21)
            mstore(mload(add(vk, 0x260)), 0x1634d869acbfaf37d0792a570e0cfaeacb73dab33ba926f4c516a16e6ee2d685)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x25816e48fdf103cabac4c88f2bd3ed4087afc18b6df8a0a8fc76ac4ab01fab73)
            mstore(add(vk, 0x280), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 3086) // vk.recursive_proof_public_input_indices
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

library Rollup28x16Vk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 16777216) // vk.circuit_size
            mstore(add(vk, 0x20), 6174) // vk.num_inputs
            mstore(add(vk, 0x40),0x0c9fabc7845d50d2852e2a0371c6441f145e0db82e8326961c25f1e3e32b045b) // vk.work_root
            mstore(add(vk, 0x60),0x30644e427ce32d4886b01bfe313ba1dba6db8b2045d128178a7164500e0a6c11) // vk.domain_inverse
            mstore(add(vk, 0x80),0x2710c370db50e9cda334d3179cd061637be1488db323a16402e1d4d1110b737b) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x225613b5b81f2763475798b632b85f387bd8ccb95ad5af90925c356f6e14b038)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x1b3ddc306f9c5bd54d6f91a8b37fc90bcb3f1002284ff1e1729f0c376839b89b)
            mstore(mload(add(vk, 0xc0)), 0x0c974388444a9227d576dc757ffbdb57940316cbb6361f642374614b21355b30)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x27d04dfe8ad958331cbe4ac6a013be21fb60822b97252bb8ae173a8c2e4aee0b)
            mstore(mload(add(vk, 0xe0)), 0x0a2c8a18e623451c12465e2190b0bd3d16ac3404569aaa0aae4e8097ead009ab)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x028129f90dd50b4301a750400eaa41e9a0e91bc5ccb01a081ad78f59d2aaf34b)
            mstore(mload(add(vk, 0x100)), 0x29a2479e6ea4daf56d6c4b6dac6d0e506ab53cb21184404a0e00be17bc83ab4a)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x138b5dfa6ddff36b7fa3beca00c7e13b69493ef3da03dc7e6400248cf103273b)
            mstore(mload(add(vk, 0x120)), 0x1cadf2dd2337e33195c7ef8a061ec21b07d19352c433b221167597344c4c65c8)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x18ac80b2d5dc142792422cbf28bbe44723fca8fdfdbf0469184dc22dbb5e4d8f)
            mstore(mload(add(vk, 0x140)), 0x077e80efe087ddd22b06f5eb457019d9acde4a62e02c46c404afb91442a3ce4e)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x2bf3cc08e50fa723e1b21e548a9cb30e8655ea01a692452c7a93af750a4069aa)
            mstore(mload(add(vk, 0x160)), 0x13eb9b2713e35a1ffd987fed4fb99036bf5ed8fdda9158a9f6ed29ffc4cc112d)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x0444c99825c737e6cda96b5f035d1bb8f7c99df776075dcc489d7478ad036b1c)
            mstore(mload(add(vk, 0x180)), 0x0173a6d8fc0a790df84404ba9bc82a13ad68adbaf329ba7b175b5fd768f7a12a)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2fb6d546c3e8045e2c6c9e6b8b071089829637bb45348a40bc2bc88190453152)
            mstore(mload(add(vk, 0x1a0)), 0x1d343b603151ccb0348556450eb83234037bc3f6294cf0d8d08039fe8241afc5)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x1051f968307fca55282cd2260369a30aef2904677f53a3af2b55fff36f254a57)
            mstore(mload(add(vk, 0x1c0)), 0x0d543617915d41ddca7f5017f91dc089e468b1dd5f8aac94999dc183bccfd5f5)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x0007e59ebeed62c41801aa4dfaf501006b68c5031dadb22180e6dd33b1fc69e7)
            mstore(mload(add(vk, 0x1e0)), 0x003165d428c6e052580b2ab7ba4519222799ed066afa052f742e0d109b179f19)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x2b2371ed9b653986d0bd0802b55f855531c23b2a2693cf63fc031f7a12966d7c)
            mstore(mload(add(vk, 0x200)), 0x1d24cbf33ac23f4e3ef652bdaaceb9508f1f261e88c0b719ec14e6d9905c3584)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x18cb7b7a347d8409a9e0efcc86db390351f92ff3806201b48c7d9fd6b4a5b437)
            mstore(mload(add(vk, 0x220)), 0x1ff115fdbcfc375ddf7a01251b30ac0f4b530eb7be0724860e8754dc3e5b4a1e)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x15bda12bd36bfcc548a8d63319055333b8c33cb145357494d83784ce4701b873)
            mstore(mload(add(vk, 0x240)), 0x138d5f013666510737b0baa4d10c386f7a44e0dd4d35508ccdf9cd86da7a7423)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2d763395ea934c56a0607e293be42913433d31676df8196a523582f27cf6f42f)
            mstore(mload(add(vk, 0x260)), 0x141c8bbb9662f5259989a6aab008daa300310da8477f99a826e3e89642dda83d)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x047a64f10308552c3240962e2ea1e4e78f5041514ebdd47c2fef436d374955a1)
            mstore(add(vk, 0x280), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 6158) // vk.recursive_proof_public_input_indices
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

library Rollup28x32Vk {
    using Bn254Crypto for Types.G1Point;
    using Bn254Crypto for Types.G2Point;

    function get_verification_key() internal pure returns (Types.VerificationKey memory) {
        Types.VerificationKey memory vk;

        assembly {
            mstore(add(vk, 0x00), 33554432) // vk.circuit_size
            mstore(add(vk, 0x20), 12318) // vk.num_inputs
            mstore(add(vk, 0x40),0x2a734ebb326341efa19b0361d9130cd47b26b7488dc6d26eeccd4f3eb878331a) // vk.work_root
            mstore(add(vk, 0x60),0x30644e5aaf0a66b91f8030da595e7d1c6787b9b45fc54c546729acf1ff053609) // vk.domain_inverse
            mstore(add(vk, 0x80),0x27f035bdb21de9525bcd0d50e993ee185f43327bf6a8efc445d2f3cb9550fe47) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x086905b1a07af75d9ea51dcfc12d10d06c43ed63279680e92737190e7f4b2697)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x0be838f2747f6ad146e81cb26052b73d52452c866e65a72f924d84e078f7b77b)
            mstore(mload(add(vk, 0xc0)), 0x0d60b79ea89ee6bd6285ec6ebb11346c77d8540adca7f272a1b5de4c64b8cccd)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x0ef762cb2a0434e5e312f21d5702f031e2d7abfe1f7db30a7ae96f0f2b047a19)
            mstore(mload(add(vk, 0xe0)), 0x2e6f4066fa7e9054abc23a4ff74b37a66d649e35d159d5a058d693cc22e95e0d)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x0e730547a6fa4283346f2625e5f060b1ef8398d555796436e2f371688fba3b03)
            mstore(mload(add(vk, 0x100)), 0x15e1a9f18685a764d57313eb6a9bb7f385ec08558e7bba567a4f759711ddaa3f)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x250706758064ba268bf17f6ff6b11e4f70d94e0f9bc23dcdd15bb8f15aa99b0c)
            mstore(mload(add(vk, 0x120)), 0x2d4cf97ac9e50da50f2c5db9724ecfae45d29373508363f395feb8c5b3c152da)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x086e6cfa25aadc97abfd9f2ecfac621b3b2f3e9ccf23400a5b77de5b2441e74c)
            mstore(mload(add(vk, 0x140)), 0x032779282156d7fc67e7aa5ee400d9a019249f65d377e0b6d6e1340ab91b9edd)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x0eca6649be8268276f57dc117ef5af49029d26514f14f47e6ffad5c0e179cab0)
            mstore(mload(add(vk, 0x160)), 0x1f9d99609993fe16b667c642c7dc038368ebd775acb91827ceb4a20356659d8b)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x0838464b5864b1287f0ece26ab40b1f1e5d6ecdc7b6a613668a074695e38d4e2)
            mstore(mload(add(vk, 0x180)), 0x0a10616a00a6af3d7fc256e920941be4cf99317e4a1b368ec145bf8ce7a72378)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x2fc8c80dcf2330fb893d99e12e11959eb97679730879c61592a566a06ed3b6c4)
            mstore(mload(add(vk, 0x1a0)), 0x1e22063e2fde4e8b7192c394075473a1d0aa3a23a9273cdc555c522bd401b73a)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x22583e15816116a8743e3e8c6ee86d75ba64346115c53d0eef50a20569ca9cb6)
            mstore(mload(add(vk, 0x1c0)), 0x1b6377d8ee470002bdd503fd358f22932a91fe8f6790a862b4857eb018ff12d1)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x1b701dc2d7862e13a4a8682c06d3f212112c0b276e7f9efda07e301e3e0b9801)
            mstore(mload(add(vk, 0x1e0)), 0x2ae6958ac716d5c3e9328cbce5b30e88b3e4f24b4e0c5c759e8cc00e4c8b035d)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x23c3a6b809cced1a1db0597e93809b9a6febb59e8f8fc484c092c82a1b316e3b)
            mstore(mload(add(vk, 0x200)), 0x185ca9b821082f91857b4c5fdb352a3f7497f23520fce8647faa43de5025022c)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x0b39c36eec3d6910cfd18a0150ac38131e880e774e61a2a57db43adb92057577)
            mstore(mload(add(vk, 0x220)), 0x0064f273192873c02f822e5dc0fa6c7e22d3fb2e88e93d2e79a67f15f0060d4b)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x22351726180e9a7a2bca2a4edcdff5ef606ff499eca33239f12ad5dbd934a719)
            mstore(mload(add(vk, 0x240)), 0x18d297fed40f6d26fdde239c15d42d5fb7abff8f271be8adb97f5324d04c453d)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x1cf8e959389b7febd018c51e02b8b1785f760f2dec805b074cbc06c5f00a3c96)
            mstore(mload(add(vk, 0x260)), 0x2aedaa32d50815b316729630ecd602e281cc4ea4d870dd0dc97ded80f81816bd)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x2b47c44ccc4e9c4e88d9195ab298a752d883a3d65e28b342b8b4d4d6911ab1aa)
            mstore(add(vk, 0x280), 0x01) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 12302) // vk.recursive_proof_public_input_indices
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