// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";
import "./InnerProductVerifier.sol";

contract BurnVerifier {
    using Utils for uint256;
    using Utils for Utils.G1Point;

    InnerProductVerifier ip;

    struct BurnStatement {
        Utils.G1Point CLn;
        Utils.G1Point CRn;
        Utils.G1Point y;
        uint256 epoch; // or uint8?
        address sender;
        Utils.G1Point u;
    }

    struct BurnProof {
        Utils.G1Point BA;
        Utils.G1Point BS;

        Utils.G1Point T_1;
        Utils.G1Point T_2;
        uint256 tHat;
        uint256 mu;

        uint256 c;
        uint256 s_sk;
        uint256 s_b;
        uint256 s_tau;

        InnerProductVerifier.InnerProductProof ipProof;
    }

    constructor(address _ip) {
        ip = InnerProductVerifier(_ip);
    }

    function verifyBurn(Utils.G1Point memory CLn, Utils.G1Point memory CRn, Utils.G1Point memory y, uint256 epoch, Utils.G1Point memory u, address sender, bytes memory proof) public view returns (bool) {
        BurnStatement memory statement; // WARNING: if this is called directly in the console,
        // and your strings are less than 64 characters, they will be padded on the right, not the left. should hopefully not be an issue,
        // as this will typically be called simply by the other contract. still though, beware
        statement.CLn = CLn;
        statement.CRn = CRn;
        statement.y = y;
        statement.epoch = epoch;
        statement.u = u;
        statement.sender = sender;
        BurnProof memory burnProof = unserialize(proof);
        return verify(statement, burnProof);
    }

    struct BurnAuxiliaries {
        uint256 y;
        uint256[32] ys;
        uint256 z;
        uint256[1] zs; // silly. just to match zether.
        uint256 zSum;
        uint256[32] twoTimesZSquared;
        uint256 x;
        uint256 t;
        uint256 k;
        Utils.G1Point tEval;
    }

    struct SigmaAuxiliaries {
        uint256 c;
        Utils.G1Point A_y;
        Utils.G1Point A_b;
        Utils.G1Point A_t;
        Utils.G1Point gEpoch;
        Utils.G1Point A_u;
    }

    struct IPAuxiliaries {
        Utils.G1Point P;
        Utils.G1Point u_x;
        Utils.G1Point[] hPrimes;
        Utils.G1Point hPrimeSum;
        uint256 o;
    }

    function gSum() internal pure returns (Utils.G1Point memory) {
        return Utils.G1Point(0x2257118d30fe5064dda298b2fac15cf96fd51f0e7e3df342d0aed40b8d7bb151, 0x0d4250e7509c99370e6b15ebfe4f1aa5e65a691133357901aa4b0641f96c80a8);
    }

    function verify(BurnStatement memory statement, BurnProof memory proof) internal view returns (bool) {
        uint256 statementHash = uint256(keccak256(abi.encode(statement.CLn, statement.CRn, statement.y, statement.epoch, statement.sender))).mod(); // stacktoodeep?

        BurnAuxiliaries memory burnAuxiliaries;
        burnAuxiliaries.y = uint256(keccak256(abi.encode(statementHash, proof.BA, proof.BS))).mod();
        burnAuxiliaries.ys[0] = 1;
        burnAuxiliaries.k = 1;
        for (uint256 i = 1; i < 32; i++) {
            burnAuxiliaries.ys[i] = burnAuxiliaries.ys[i - 1].mul(burnAuxiliaries.y);
            burnAuxiliaries.k = burnAuxiliaries.k.add(burnAuxiliaries.ys[i]);
        }
        burnAuxiliaries.z = uint256(keccak256(abi.encode(burnAuxiliaries.y))).mod();
        burnAuxiliaries.zs[0] = burnAuxiliaries.z.mul(burnAuxiliaries.z);
        burnAuxiliaries.zSum = burnAuxiliaries.zs[0].mul(burnAuxiliaries.z); // trivial sum
        burnAuxiliaries.k = burnAuxiliaries.k.mul(burnAuxiliaries.z.sub(burnAuxiliaries.zs[0])).sub(burnAuxiliaries.zSum.mul(1 << 32).sub(burnAuxiliaries.zSum));
        burnAuxiliaries.t = proof.tHat.sub(burnAuxiliaries.k);
        for (uint256 i = 0; i < 32; i++) {
            burnAuxiliaries.twoTimesZSquared[i] = burnAuxiliaries.zs[0].mul(1 << i);
        }

        burnAuxiliaries.x = uint256(keccak256(abi.encode(burnAuxiliaries.z, proof.T_1, proof.T_2))).mod();
        burnAuxiliaries.tEval = proof.T_1.mul(burnAuxiliaries.x).add(proof.T_2.mul(burnAuxiliaries.x.mul(burnAuxiliaries.x))); // replace with "commit"?

        SigmaAuxiliaries memory sigmaAuxiliaries;
        sigmaAuxiliaries.A_y = Utils.g().mul(proof.s_sk).add(statement.y.mul(proof.c.neg()));
        sigmaAuxiliaries.A_b = Utils.g().mul(proof.s_b).add(statement.CRn.mul(proof.s_sk).add(statement.CLn.mul(proof.c.neg())).mul(burnAuxiliaries.zs[0]));
        sigmaAuxiliaries.A_t = Utils.g().mul(burnAuxiliaries.t).add(burnAuxiliaries.tEval.neg()).mul(proof.c).add(Utils.h().mul(proof.s_tau)).add(Utils.g().mul(proof.s_b.neg()));
        sigmaAuxiliaries.gEpoch = Utils.mapInto("Zether", statement.epoch);
        sigmaAuxiliaries.A_u = sigmaAuxiliaries.gEpoch.mul(proof.s_sk).add(statement.u.mul(proof.c.neg()));

        sigmaAuxiliaries.c = uint256(keccak256(abi.encode(burnAuxiliaries.x, sigmaAuxiliaries.A_y, sigmaAuxiliaries.A_b, sigmaAuxiliaries.A_t, sigmaAuxiliaries.A_u))).mod();
        require(sigmaAuxiliaries.c == proof.c, "Sigma protocol challenge equality failure.");

        IPAuxiliaries memory ipAuxiliaries;
        ipAuxiliaries.o = uint256(keccak256(abi.encode(sigmaAuxiliaries.c))).mod();
        ipAuxiliaries.u_x = Utils.h().mul(ipAuxiliaries.o);
        ipAuxiliaries.hPrimes = new Utils.G1Point[](32);
        for (uint256 i = 0; i < 32; i++) {
            ipAuxiliaries.hPrimes[i] = ip.hs(i).mul(burnAuxiliaries.ys[i].inv());
            ipAuxiliaries.hPrimeSum = ipAuxiliaries.hPrimeSum.add(ipAuxiliaries.hPrimes[i].mul(burnAuxiliaries.ys[i].mul(burnAuxiliaries.z).add(burnAuxiliaries.twoTimesZSquared[i])));
        }
        ipAuxiliaries.P = proof.BA.add(proof.BS.mul(burnAuxiliaries.x)).add(gSum().mul(burnAuxiliaries.z.neg())).add(ipAuxiliaries.hPrimeSum);
        ipAuxiliaries.P = ipAuxiliaries.P.add(Utils.h().mul(proof.mu.neg()));
        ipAuxiliaries.P = ipAuxiliaries.P.add(ipAuxiliaries.u_x.mul(proof.tHat));
        require(ip.verifyInnerProduct(ipAuxiliaries.hPrimes, ipAuxiliaries.u_x, ipAuxiliaries.P, proof.ipProof, ipAuxiliaries.o), "Inner product proof verification failed.");

        return true;
    }

    function unserialize(bytes memory arr) internal pure returns (BurnProof memory proof) {
        proof.BA = Utils.G1Point(Utils.slice(arr, 0), Utils.slice(arr, 32));
        proof.BS = Utils.G1Point(Utils.slice(arr, 64), Utils.slice(arr, 96));

        proof.T_1 = Utils.G1Point(Utils.slice(arr, 128), Utils.slice(arr, 160));
        proof.T_2 = Utils.G1Point(Utils.slice(arr, 192), Utils.slice(arr, 224));
        proof.tHat = uint256(Utils.slice(arr, 256));
        proof.mu = uint256(Utils.slice(arr, 288));

        proof.c = uint256(Utils.slice(arr, 320));
        proof.s_sk = uint256(Utils.slice(arr, 352));
        proof.s_b = uint256(Utils.slice(arr, 384));
        proof.s_tau = uint256(Utils.slice(arr, 416));

        InnerProductVerifier.InnerProductProof memory ipProof;
        ipProof.L = new Utils.G1Point[](5);
        ipProof.R = new Utils.G1Point[](5);
        for (uint256 i = 0; i < 5; i++) { // 2^5 = 32.
            ipProof.L[i] = Utils.G1Point(Utils.slice(arr, 448 + i * 64), Utils.slice(arr, 480 + i * 64));
            ipProof.R[i] = Utils.G1Point(Utils.slice(arr, 448 + (5 + i) * 64), Utils.slice(arr, 480 + (5 + i) * 64));
        }
        ipProof.a = uint256(Utils.slice(arr, 448 + 5 * 128));
        ipProof.b = uint256(Utils.slice(arr, 480 + 5 * 128));
        proof.ipProof = ipProof;

        return proof;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library Utils {

    uint256 constant GROUP_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    uint256 constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        return addmod(x, y, GROUP_ORDER);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulmod(x, y, GROUP_ORDER);
    }

    function inv(uint256 x) internal view returns (uint256) {
        return exp(x, GROUP_ORDER - 2);
    }

    function mod(uint256 x) internal pure returns (uint256) {
        return x % GROUP_ORDER;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x - y : GROUP_ORDER - y + x;
    }

    function neg(uint256 x) internal pure returns (uint256) {
        return GROUP_ORDER - x;
    }

    function exp(uint256 base, uint256 exponent) internal view returns (uint256 output) {
        uint256 order = GROUP_ORDER;
        assembly {
            let m := mload(0x40)
            mstore(m, 0x20)
            mstore(add(m, 0x20), 0x20)
            mstore(add(m, 0x40), 0x20)
            mstore(add(m, 0x60), base)
            mstore(add(m, 0x80), exponent)
            mstore(add(m, 0xa0), order)
            if iszero(staticcall(gas(), 0x05, m, 0xc0, m, 0x20)) { // staticcall or call?
                revert(0, 0)
            }
            output := mload(m)
        }
    }

    function fieldExp(uint256 base, uint256 exponent) internal view returns (uint256 output) { // warning: mod p, not q
        uint256 order = FIELD_ORDER;
        assembly {
            let m := mload(0x40)
            mstore(m, 0x20)
            mstore(add(m, 0x20), 0x20)
            mstore(add(m, 0x40), 0x20)
            mstore(add(m, 0x60), base)
            mstore(add(m, 0x80), exponent)
            mstore(add(m, 0xa0), order)
            if iszero(staticcall(gas(), 0x05, m, 0xc0, m, 0x20)) { // staticcall or call?
                revert(0, 0)
            }
            output := mload(m)
        }
    }

    struct G1Point {
        bytes32 x;
        bytes32 y;
    }

    function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        assembly {
            let m := mload(0x40)
            mstore(m, mload(p1))
            mstore(add(m, 0x20), mload(add(p1, 0x20)))
            mstore(add(m, 0x40), mload(p2))
            mstore(add(m, 0x60), mload(add(p2, 0x20)))
            if iszero(staticcall(gas(), 0x06, m, 0x80, r, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        assembly {
            let m := mload(0x40)
            mstore(m, mload(p))
            mstore(add(m, 0x20), mload(add(p, 0x20)))
            mstore(add(m, 0x40), s)
            if iszero(staticcall(gas(), 0x07, m, 0x60, r, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function neg(G1Point memory p) internal pure returns (G1Point memory) {
        return G1Point(p.x, bytes32(FIELD_ORDER - uint256(p.y))); // p.y should already be reduced mod P?
    }

    function eq(G1Point memory p1, G1Point memory p2) internal pure returns (bool) {
        return p1.x == p2.x && p1.y == p2.y;
    }

    function g() internal pure returns (G1Point memory) {
        return G1Point(0x077da99d806abd13c9f15ece5398525119d11e11e9836b2ee7d23f6159ad87d4, 0x01485efa927f2ad41bff567eec88f32fb0a0f706588b4e41a8d587d008b7f875);
    }

    function h() internal pure returns (G1Point memory) {
        return G1Point(0x01b7de3dcf359928dd19f643d54dc487478b68a5b2634f9f1903c9fb78331aef, 0x2bda7d3ae6a557c716477c108be0d0f94abc6c4dc6b1bd93caccbcceaaa71d6b);
    }

    function mapInto(uint256 seed) internal view returns (G1Point memory) {
        uint256 y;
        while (true) {
            uint256 ySquared = fieldExp(seed, 3) + 3; // addmod instead of add: waste of gas, plus function overhead cost
            y = fieldExp(ySquared, (FIELD_ORDER + 1) / 4);
            if (fieldExp(y, 2) == ySquared) {
                break;
            }
            seed += 1;
        }
        return G1Point(bytes32(seed), bytes32(y));
    }

    function mapInto(string memory input) internal view returns (G1Point memory) {
        return mapInto(uint256(keccak256(abi.encodePacked(input))) % FIELD_ORDER);
    }

    function mapInto(string memory input, uint256 i) internal view returns (G1Point memory) {
        return mapInto(uint256(keccak256(abi.encodePacked(input, i))) % FIELD_ORDER);
    }

    function slice(bytes memory input, uint256 start) internal pure returns (bytes32 result) {
        assembly {
            let m := mload(0x40)
            mstore(m, mload(add(add(input, 0x20), start))) // why only 0x20?
            result := mload(m)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";

contract InnerProductVerifier {
    using Utils for uint256;
    using Utils for Utils.G1Point;

    struct InnerProductStatement {
        Utils.G1Point[] hs; // "overridden" parameters.
        Utils.G1Point u;
        Utils.G1Point P;
    }

    struct InnerProductProof {
        Utils.G1Point[] L;
        Utils.G1Point[] R;
        uint256 a;
        uint256 b;
    }

    function verifyInnerProduct(Utils.G1Point[] memory hs, Utils.G1Point memory u, Utils.G1Point memory P, InnerProductProof memory proof, uint256 salt) public view returns (bool) {
        InnerProductStatement memory statement;
        statement.hs = hs;
        statement.u = u;
        statement.P = P;

        return verify(statement, proof, salt);
    }

    function gs(uint256 i) public pure returns (Utils.G1Point memory) {
        if (i == 0) return Utils.G1Point(0x0d1fff31f8dfb29333568b00628a0f92a752e8dee420dfede1be731810a807b9, 0x06c3001c74387dae9deddc75b76959ef5f98f1be48b0d9fc8ff6d7d76106b41b);
        if (i == 1) return Utils.G1Point(0x06e1b58cb1420e3d12020c5be2c4e48955efc64310ab10002164d0e2a767018e, 0x229facdebea78bd67f5b332bcdab7d692d0c4b18d77e92a8b3ffaee450c797c7);
        if (i == 2) return Utils.G1Point(0x22f32c65b43f3e770b793ea6e31c85d1aea2c41ea3204fc08a036004e5adef3a, 0x1d63e3737f864f05f62e2be0a6b7528b76cdabcda9703edc304c015480fb5543);
        if (i == 3) return Utils.G1Point(0x01df5e3e2818cfce850bd5d5f57872abc34b1315748e0280c4f0d3d6a40f94a9, 0x0d622581880ddba6a3911aa0df64f4fd816800c6dee483f07aa542a6e61534d5);
        if (i == 4) return Utils.G1Point(0x18d7f2117b1144f5035218384d817c6d1b4359497489a52bcf9d16c44624c1d0, 0x115f00d2f27917b5a3e8e6754451a4e990931516cf47e742949b8cbdda0e2c20);
        if (i == 5) return Utils.G1Point(0x093a9e9ba588d1b8eae48cf96b97def1fb8dccd519678520314e96d289ad1d11, 0x0f94a152edd0254ece896bc7e56708ba623c1ed3a27e4fd4c449f8e98fee1b5e);
        if (i == 6) return Utils.G1Point(0x0a7e8bc3cecaff1d9ec3e7d9c1fab7b5397bd6b6739c99bfe4bcb21d08d25934, 0x18d0114fa64774f712044e9a05b818fea4734db2b91fc7f049e120ce01c096be);
        if (i == 7) return Utils.G1Point(0x2095c16aea6e127aa3394d0124b545a45323708ae1c227575270d99b9900673a, 0x24c5a6afc36ef443197217591e084cdd69820401447163b5ab5f015801551a03);
        if (i == 8) return Utils.G1Point(0x041ee7d5aa6e191ba063876fda64b87728fa3ed39531400118b83372cbb5af75, 0x2dc2abc7d618ae4e1522f90d294c23627b6bc4f60093e8f07a7cd3869dac9836);
        if (i == 9) return Utils.G1Point(0x16dc75831b780dc5806dd5b8973f57f2f4ce8ad2a6bb152fbd9ccb58534115b4, 0x17b434c3b65a2f754c99f7bacf2f20bdcd7517a38e5eb301d2d88fe7735ebc9c);
        if (i == 10) return Utils.G1Point(0x18f1393a76e0af102ffeb380787ed950dc35b04b0cc6de1a6d806d4007b30dba, 0x1d640e43bab253bf176b69dffdb3ffc02640c591c392f400596155c8c3f668ef);
        if (i == 11) return Utils.G1Point(0x2bf3f58b4c957a8ae697aa57eb3f7428527fcb0c7e8d099efae80b97bde600e0, 0x14072f8bfdbe285b203cd0a2ebc1aed9ad1de309794226aee63c89397b187abf);
        if (i == 12) return Utils.G1Point(0x028eb6852c2827302aeb09def685b57bef74ff1a3ff72eda972e32b9ea80c32f, 0x1ba2dfb85a585de4b8a189f7b764f87c6f8e06c10d68d4493fc469504888837d);
        if (i == 13) return Utils.G1Point(0x19003e6b8f14f3583435527eac51a460c705dc6a042a2b7dd56b4f598af50886, 0x10e755ac3373f769e7e092f9eca276d911cd31833e82c70b8af09787e2c02d20);
        if (i == 14) return Utils.G1Point(0x0d493d4d49aa1a4fdf3bc3ba6d969b3e203741b3d570dbc511dd3171baf96f85, 0x1d103731795bcc57ddb8514e0e232446bfd9834f6a8ae9ff5235330d2a9e5ffa);
        if (i == 15) return Utils.G1Point(0x0ce438e766aae8c59b4006ee1749f40370fe5ec9fe29edce6b98e945915db97f, 0x02dba20dff83b373d2b47282e08d2c7883254a56701f2dbeea7ccc167ffb49a5);
        if (i == 16) return Utils.G1Point(0x05092110319650610a94fa0f9d50536404ba526380fc31b99ce95fbc1423a26f, 0x18a40146a4e79c2830d6d6e56314c538b0da4a2a72b7533e63f7d0a7e5ab2d22);
        if (i == 17) return Utils.G1Point(0x25b9ad9c4235b0a2e9f1b2ed20a5ca63814e1fb0eb95540c6f4f163c1a9fc2bd, 0x0a726ff7b655ad45468bcfd2d77f8aa0786ff3012d4edb77b5118f863dcdcbc0);
        if (i == 18) return Utils.G1Point(0x291ff28fa0a9840e230de0f0da725900bd18ce31d2369ffc80abbc4a77c1aff3, 0x1ffed5e9dffcd885ac867e2279836a11225548a8c253c47efe24f7d95a4bdd61);
        if (i == 19) return Utils.G1Point(0x0a01c96340d6bb4c94e028a522f74bef899d8f9d1a6d0b0d832f83275efa68de, 0x119c6a17ecb14721ac9eb331abccf2748868855fae43392391c37037d1b150a1);
        if (i == 20) return Utils.G1Point(0x2c846ad384d3ea063001f34fd60f0b8dc12b3b3ab7a5757f1d394f19850d8309, 0x1ff69942134c51e7315ccf1431e66fb5f70c24148c668f4fbe3861fbe535e39c);
        if (i == 21) return Utils.G1Point(0x0dafb5ae6accb6048e6dbc52f455c262dd2876b565792d68189618a3e630ade0, 0x236e97c592c19a2f2244f2938021671045787501e5a4a26de3580628ce37eb3b);
        if (i == 22) return Utils.G1Point(0x10df3e10a8d613058eae3278e2c80c3366c482354260f501447d15797de7378a, 0x10b25f7e075c93203ceba523afc44e0d5cd9e45a60b6dc11d2034180c40a004d);
        if (i == 23) return Utils.G1Point(0x1437b718d075d54da65adccdd3b6f758a5b76a9e5c5c7a13bf897a92e23fcde2, 0x0f0b988d70298608d02c73c410dc8b8bb6b95f0dde0dedcd5ea5692f0c07f3ed);
        if (i == 24) return Utils.G1Point(0x2705c71a95661231956d10845933f43cd973f4626e3a31dbf6287e01a00beb70, 0x27d09bd21d44269e2e7c85e1555fd351698eca14686d5aa969cb08e33db6691b);
        if (i == 25) return Utils.G1Point(0x1614dabf48099c315f244f8763f4b99ca2cef559781bf55e8e4d912d952edb4a, 0x16bf2f8fb1021b47be88ceb6fce08bf3b3a17026509cf9756c1a3fbf3b9d70bd);
        if (i == 26) return Utils.G1Point(0x21c448cfdcf007959812b2c5977cd4a808fa25408547e660c3fc12ed47501eb3, 0x14495c361cf9dc10222549bc258a76a20058f4795c2e65cd27f013c940b7dc7b);
        if (i == 27) return Utils.G1Point(0x1ac35f37ee0bfcb173d513ea7ac1daf5b46c6f70ce5f82a0396e7afac270ff35, 0x2f5f4480260b838ffcba9d34396fc116f75d1d5c24396ed4f7e01fd010ab9970);
        if (i == 28) return Utils.G1Point(0x0caaa12a18563703797d9be6ef74cbfb9e532cd027a1021f34ad337ce231e074, 0x2281c11389906c02bb15e995ffd6db136c3cdb4ec0829b88aec6db8dda05d5af);
        if (i == 29) return Utils.G1Point(0x1f3d91f1dfbbf01002a7e339ff6754b4ad2290493757475a062a75ec44bc3d50, 0x207b99884d9f7ca1e2f04457b90982ec6f8fb0a5b2ffd5b50d9cf4b2d850a920);
        if (i == 30) return Utils.G1Point(0x1fe58e4e4b1d155fb0a97dc9bae46f401edb2828dc4f96dafb86124cba424455, 0x01ad0a57feb7eeda4319a70ea56ded5e9fef71c78ff84413399d51f647d55113);
        if (i == 31) return Utils.G1Point(0x044e80195798557e870554d7025a8bc6b2ee9a05fa6ae016c3ab3b9e97af5769, 0x2c141a12135c4d14352fc60d851cdde147270f76405291b7c5d01da8f5dfed4d);
        if (i == 32) return Utils.G1Point(0x2883d31d84e605c858cf52260183f09d18bd55dc330f8bf12785e7a2563f8da4, 0x0e681e5c997f0bb609af7a95f920f23c4be78ded534832b514510518ede888b2);
        if (i == 33) return Utils.G1Point(0x2cdf5738c2690b263dfdc2b4235620d781bbff534d3363c4f3cfe5d1c67767c1, 0x15f4fb05e5facfd1988d61fd174a14b20e1dbe6ac37946e1527261be8742f5cf);
        if (i == 34) return Utils.G1Point(0x05542337765c24871e053bb8ec4e1baaca722f58b834426431c6d773788e9c66, 0x00e64d379c28d138d394f2cf9f0cc0b5a71e93a055bad23a2c6de74b217f3fac);
        if (i == 35) return Utils.G1Point(0x2efe9c1359531adb8a104242559a320593803c89a6ff0c6c493d7da5832603ab, 0x295898b3b86cf9e09e99d7f80e539078d3b5455bba60a5aa138b2995b75f0409);
        if (i == 36) return Utils.G1Point(0x2a3740ca39e35d23a5107fdae38209eaebdcd70ae740c873caf8b0b64d92db31, 0x05bab66121bccf807b1f776dc487057a5adf5f5791019996a2b7a2dbe1488797);
        if (i == 37) return Utils.G1Point(0x11ef5ef35b895540be39974ac6ad6697ef4337377f06092b6a668062bf0d8019, 0x1a42e3b4b73119a4be1dde36a8eaf553e88717cecb3fdfdc65ed2e728fda0782);
        if (i == 38) return Utils.G1Point(0x245aac96c5353f38ae92c6c17120e123c223b7eaca134658ebf584a8580ec096, 0x25ec55531155156663f8ba825a78f41f158def7b9d082e80259958277369ed08);
        if (i == 39) return Utils.G1Point(0x0fb13a72db572b1727954bb77d014894e972d7872678200a088febe8bd949986, 0x151af2ae374e02dec2b8c5dbde722ae7838d70ab4fd0857597b616a96a1db57c);
        if (i == 40) return Utils.G1Point(0x155fa64e4c8bf5f5aa53c1f5e44d961f688132c8545323d3bdc6c43a83220f89, 0x188507b59213816846bc9c763a93b52fb7ae8e8c8cc7549ce3358728415338a4);
        if (i == 41) return Utils.G1Point(0x28631525d5192140fd4fb04efbad8dcfddd5b8d0f5dc54442e5530989ef5b7fe, 0x0ad3a3d4845b4bc6a92563e72db2bc836168a295c56987c7bb1eea131a3760ac);
        if (i == 42) return Utils.G1Point(0x043b2963b1c5af8e2e77dfb89db7a0d907a40180929f3fd630a4a37811030b6d, 0x0721a4b292b41a3d948237bf076aabeedba377c43a10f78f368042ad155a3c91);
        if (i == 43) return Utils.G1Point(0x14bfb894e332921cf925f726f7c242a70dbd9366b68b50e14b618a86ecd45bd6, 0x09b1c50016fff7018a9483ce00b8ec3b6a0df36db21ae3b8282ca0b4be2e283c);
        if (i == 44) return Utils.G1Point(0x2758e65c03fdb27e58eb300bde8ada18372aa268b393ad5414e4db097ce9492d, 0x041f685536314ddd11441a3d7e01157f7ea7e474aae449dbba70c2edc70cd573);
        if (i == 45) return Utils.G1Point(0x191365dba9df566e0e6403fb9bcd6847c0964ea516c403fd88543a6a9b3fa1f2, 0x0ae815170115c7ce78323cbd9399735847552b379c2651af6fc29184e95eef7f);
        if (i == 46) return Utils.G1Point(0x027a2a874ba2ab278be899fe96528b6d39f9d090ef4511e68a3e4979bc18a526, 0x2272820981fe8a9f0f7c4910dd601cea6dd7045aa4d91843d3cf2afa959fbe68);
        if (i == 47) return Utils.G1Point(0x13feec071e0834433193b7be17ce48dec58d7610865d9876a08f91ea79c7e28d, 0x26325544133c7ec915c317ac358273eb2bf2e6b6119922d7f0ab0727e5eb9e64);
        if (i == 48) return Utils.G1Point(0x08e6096c8425c13b79e6fa38dffcc92c930d1d0bff9671303dbc0445e73c77bc, 0x03e884c8dc85f0d80baf968ae0516c1a7927808f83b4615665c67c59389db606);
        if (i == 49) return Utils.G1Point(0x1217ff3c630396cd92aa13aa6fee99880afc00f47162625274090278f09cbed3, 0x270b44f96accb061e9cad4a3341d72986677ed56157f3ba02520fdf484bb740d);
        if (i == 50) return Utils.G1Point(0x239128d2e007217328aae4e510c3d9fe1a3ef2b23212dfaf6f2dcb75ef08ed04, 0x2d5495372c759fdba858b7f6fa89a948eb4fd277bae9aebf9785c86ea3f9c07d);
        if (i == 51) return Utils.G1Point(0x305747313ea4d7d17bd14b69527094fa79bdc05c3cc837a668a97eb81cffd3d4, 0x0aa43bd7ad9090012e12f78ac3cb416903c2e1aabb61161ca261892465b3555d);
        if (i == 52) return Utils.G1Point(0x267742bd96caad20a76073d5060085103b7d29c88f0a0d842ef610472a1764ef, 0x0086485faeedd1ea8f6595b2edaf5f99044864271a178bd33e6d5b73b6d240a0);
        if (i == 53) return Utils.G1Point(0x00aed2e1ac448b854a44c7aa43cabb93d92316460c8f5eacb038f4cf554dfa01, 0x1b2ec095d370b234214a0c68fdfe8da1e06cbfdc5e889e2337ccb28c49089fcf);
        if (i == 54) return Utils.G1Point(0x06f37ac505236b2ed8c520ea36b0448229eb2f2536465b14e6e115dc810c6e39, 0x174db60e92b421e4d59c81e2c0666f7081067255c8e0d775e085278f34663490);
        if (i == 55) return Utils.G1Point(0x2af094e58a7961c4a1dba0685d8b01dacbb01f0fc0e7a648085a38aa380a7ab6, 0x108ade796501042dab10a83d878cf1deccf74e05edc92460b056d31f3e39fd53);
        if (i == 56) return Utils.G1Point(0x051ec23f1166a446caa4c8ff443470e98e753697fcceb4fbe5a49bf7a2db7199, 0x00f938707bf367e519d0c5efcdb61cc5a606901c0fbd4565abeeb5d020081d96);
        if (i == 57) return Utils.G1Point(0x1132459cf7287884b102467a71fad0992f1486178f7385ef159277b6e800239d, 0x257fedb1e126363af3fb3a80a4ad850d43041d64ef27cc5947730901f3019138);
        if (i == 58) return Utils.G1Point(0x14a571bbbb8d2a442855cde5fe6ed635d91668eded003d7698f9f744557887ea, 0x0f65f76e6fa6f6c7f765f947d905b015c3ad077219fc715c2ec40e37607c1041);
        if (i == 59) return Utils.G1Point(0x0e303c28b0649b95c624d01327a61fd144d29bfed6d3a1cf83216b45b78180cf, 0x229975c2e3aaba1d6203a5d94ea92605edb2af04f41e3783ec4e64755eeb1d1b);
        if (i == 60) return Utils.G1Point(0x05a62a2f1dfe368e81d9ae5fe150b9a57e0f85572194de27f48fec1c5f3b0dad, 0x200eb8097c91fe825adb0e3920e6bdff2e40114bd388298b85a0094a9a5bc654);
        if (i == 61) return Utils.G1Point(0x06545efc18dfc2f444e147c77ed572decd2b58d0668bbaaf0d31f1297cde6b99, 0x29ecbbeb81fe6c14279e9e46637ad286ba71e4c4e5da1416d8501e691f9e5bed);
        if (i == 62) return Utils.G1Point(0x045ce430f0713c29748e30d024cd703a5672633faebe1fd4d210b5af56a50e70, 0x0e3ec93722610f4599ffaac0db0c1b2bb446ff5aea5117710c271d1e64348844);
        if (i == 63) return Utils.G1Point(0x243de1ee802dd7a3ca9a991ec228fbbfb4973260f905b5106e5f738183d5cacd, 0x133d25bb8dc9f54932b9d6ee98e0432676f5278e9878967fbbd8f5dfc46df4f8);
    }

    function hs(uint256 i) public pure returns (Utils.G1Point memory) {
        if (i == 0) return Utils.G1Point(0x01d39aef1308fae84642befcdb6c07f655cc4d092f6a66f464cb9c959bff743a, 0x277420423ebed18174bd2730d4387b06c10958e564af6444333ac5b30767c59c);
        if (i == 1) return Utils.G1Point(0x2f1a6e72cf51c976df65f69457491bd852b4cf8a172183537dc413d0801bef0a, 0x0fc8845b156f86c3018d7a193c089c8d02ea38ba2cec11b1b6118a3b37f4cb08);
        if (i == 2) return Utils.G1Point(0x00f698cd9c34ea5fc62bd7d91c3a8b7f70bb12596d3c6d99b9be4d7acf2e72ea, 0x23abea6d9096d3c23f3aee1447570211efc5d2add2f310a2acaf3afc1faa0ed1);
        if (i == 3) return Utils.G1Point(0x06e93364d8080a84ab1dac7fa743b3f3f139f84c602cc67a899e3739abf11cc0, 0x2246590e06850a6f55b3e9bb81d7316fe7b08bef9f9a06d43b30226d626a979d);
        if (i == 4) return Utils.G1Point(0x1fb8f0bbb173c6d8f7ae2e1fa1e3770aa8c66fbed8d459d8e6fa972c990e0e22, 0x23d30ccd0b4747679bbd29620c3efb39ee1d7018b0281c448ad1501a5e04dc1a);
        if (i == 5) return Utils.G1Point(0x1b5f7c9fa9f3ef4adbed1f09bc6e151ba5e7c1d098c2d94e2dbe95897e6675cd, 0x23ff89ca0d326bd98629bf7ccf343ababdb330821a495b7624d8720fd1ead1e3);
        if (i == 6) return Utils.G1Point(0x2ffd2415cb4cd71a9f3cf4ed64d4a85d4d3eb06bfa10f98cb8a2ab7e2d96797c, 0x1d770c3d19238753457dd36280bd6685f6f214461a81aa95962f1c80a6c4168d);
        if (i == 7) return Utils.G1Point(0x2d344a9de673000e4108f8b6eb21b8cf39e223fad81cef47cd599b5e548a092b, 0x1abe37b046f84fa46b7629e432e298ae7dda657d2cdde851775431cab1d34402);
        if (i == 8) return Utils.G1Point(0x131bea29a212d81278492c44179c04f2a3f7e72151a0a4870b01e2fa96cdf84a, 0x0e5a783a7d6e044761fa10b801de33a1c4de8d4569f132b86a5be6aa13726127);
        if (i == 9) return Utils.G1Point(0x2e9de6196c9d4be4d765078245515d02b18ee6073ca0afb1afe98dcca2378d76, 0x1a5be81d26e9261e5072bb86f5cbd1dd8075316c8fec769ac839819a17ec3841);
        if (i == 10) return Utils.G1Point(0x21ccb04d241aa8108e9e5f2487fffe82debc69e4cff3a7ee292609fbe49cb6ad, 0x14d2e86d8bea6af2ad1cde303c9b2993a37c5b7bf0567278854ca666e61f2e80);
        if (i == 11) return Utils.G1Point(0x164314a3b09437cc1cd0f7726b8291be0bd293876093e51f989feab3238cfd85, 0x043bb4c392fbf35b9991d01ffaf6c59d7e72559ed7f338f85beebdf74ed3132f);
        if (i == 12) return Utils.G1Point(0x08a85c13ee191db8c043a21db38c016e27376d82063a93f8a6ff603b0f396433, 0x19be7f870a4bbd255c61ca01588bc3be2632c015753a3320309915e600d78a0a);
        if (i == 13) return Utils.G1Point(0x2090c3ab526ff54497f984b860682c77c0a89842f6612928cf4188c5c0f1ee20, 0x151a9c9fcdc438b3197d85ab51317d969d66e03fe26e05f6be466058cb8b7e65);
        if (i == 14) return Utils.G1Point(0x220b0c31ba1c84a2c1235d987e79d8fb1854fb59cce44719a13e4b83331da63b, 0x19a161498b4d63a027670174b424260b2180ccb02e05e4e061363ac3a87642da);
        if (i == 15) return Utils.G1Point(0x018eb881dd184f8abff3b91b50676a12945e205f200fdaf25ffb7e8c97385334, 0x1dea48b102351f75ce4977a6c3c908455a9e269aab69c3f66e642791052d0cfb);
        if (i == 16) return Utils.G1Point(0x07b0183a2450ccb5a001554ac3fe1a763bb69a0222316c1a553124a915cd0720, 0x282216c8c2711780ed3b24281fdd358d0e3d2e05e9cd1ab6842432f818a4a40c);
        if (i == 17) return Utils.G1Point(0x2b3f257e1258a3c2bda28be60fdc4cf2a74a19bb17d61783a91ec478d379e1a5, 0x1a8ddf17a83d7b89a6c7ae59601b736c4c7022f29c74700bd5d51cbd70b5051d);
        if (i == 18) return Utils.G1Point(0x0485fd181e30eef43c4356c6cdfb8957267795c838e6e64c52fd81a697dd8505, 0x17105695b4bfc555a55c8449182a6335584f971a0058172bd2b5441db3129843);
        if (i == 19) return Utils.G1Point(0x2008a80d7c60d7dc6e069b174efd31984a0933da7f89a574aae52e8805b40095, 0x052398552fb4706758b6eafb50bed493568670961058586735bca016e875e6ef);
        if (i == 20) return Utils.G1Point(0x119ff93e1bce3d5c7c57d1fea845e9335e04c729ec7a62ca2283d6c5dc0acc7c, 0x2042b68991a4d4c959df76947ef2594afb6735d760c3629825db8451b4830a3c);
        if (i == 21) return Utils.G1Point(0x0ed374dfa5daee92868812764c47ffd9c0c832abe09124f6f55283869d639eb7, 0x267767cb5017979990d9fa6db5f741de043afb70ee8a5e29045e926486f00858);
        if (i == 22) return Utils.G1Point(0x1c3786f37ee4f7eb9493551cea3c2a4e8ddcdd3c86e9f9ea2a41199efa1da476, 0x147d40e13345ec2f38975b09989d2c01954122796f83bfc19974ab647f754a32);
        if (i == 23) return Utils.G1Point(0x0040bf79ad3c473ffd4d7e15dbe0fa0a9b06e765a6d5adb372f98b8ea107f2c6, 0x17bf761b14f52da007532fcdf1bbdec180750af1b7b3804e29d6d45af62042f8);
        if (i == 24) return Utils.G1Point(0x01a9c26d59a9962250ce2b20b477884d11ce2c2404b749ceee59c51c2dcc0918, 0x1603d5448eb9b7528b247c0cdf8b0d9275322975bc7e4b13b8d0312cf032c467);
        if (i == 25) return Utils.G1Point(0x215ecf3e09641d5a38d4f510ed72e2ee586d4fbfc7e46411e1a3396f07b1e276, 0x28ece25edfb8c48631b861e838641f8e61e58afcf4e6c8f336c86fe5b7c0dfc9);
        if (i == 26) return Utils.G1Point(0x0beda6c3cbaec7226ed3bd6e0a27a626e0022b1afa820ac509e21b646f23dc60, 0x212f09e343da69ec34d90491282e69499c779973c0352126a38aabbf5783b288);
        if (i == 27) return Utils.G1Point(0x27f5c2199a6cebc34e3b5376b4db3ac6db08d2f302aa9b99f808e20a95e9ef8c, 0x0ccc4c0723e2a255e9b649eae9c16d72f4ddb97d088d7b3154c00e9a1dd94fe8);
        if (i == 28) return Utils.G1Point(0x2af5191d45c6ca76563c6f936f0cd2dcaa4311719675c2bb5f65d3df2270f636, 0x1252aca114b1fda7f43c06d1f2b60718e7bc99b8544138f9c67aad8dfca863d7);
        if (i == 29) return Utils.G1Point(0x13bdce5de7cf1c2250bac0be0d23d3be0140ce3838c8966ea2870e64b87adaee, 0x2f3770a6b5a9babcc5fa7cae8ffbb2a63ff312f2d3352e4fe8c173b12ff847e0);
        if (i == 30) return Utils.G1Point(0x18d1242b7bee604de29b4511814b02c8fd1519a4fc6daf9dbc95f8bb64ee097b, 0x0f828debef5bd4115c91f419718bdb59464bd8bb78fd0dc250d1efb1a51366df);
        if (i == 31) return Utils.G1Point(0x04b4102e8d3a2d3ba330257de8d18861db5652d685efb297d9c116eb1a7b1299, 0x08a3fd325f19ddebb53063d60fccdb8f0321fe41d4d93d98c65e05c9b4101aa0);
        if (i == 32) return Utils.G1Point(0x20f38c332b7117550a2462637fd38dfa08eb063e5bbc1838de2d8a933b052a5d, 0x0de3339a34e84bc8d57daf4fe55855a02df1c6fe4ce1cd07ca3060f67e1d75b2);
        if (i == 33) return Utils.G1Point(0x02f501714aa467e8b06ec808af8a3278f58faa7b87b678a1e36ee779adb01def, 0x1b8f1369d47a1d7b4da91b777bbcd7a2a4bde8ad09cc2eeeb9e8c0036ef5df47);
        if (i == 34) return Utils.G1Point(0x059c89b0e337c65e8132ac7c78f29d1a016edbff65da6663ef114f85bc414f20, 0x0b6e3d301ca62d0946299c6b79f2207479351ac27478901cdf5be144cf77435f);
        if (i == 35) return Utils.G1Point(0x02f51c34b66cd01304c185bcc087b9430beb0e6738e97491550740e18c262948, 0x27e42ced0bf3356a10e9685f1365a2ac3fdb3f3e89b9cd2f0309cd9ffcd6dfc0);
        if (i == 36) return Utils.G1Point(0x28c0affe0178e407e8196e3d0af3674aecc46a94342a97fec96d1eaa0e24ce3a, 0x1056737f11d45d9de7ff2d6de4ae31af9aa6a3ca2a0d56e5748059c7c39a02e7);
        if (i == 37) return Utils.G1Point(0x0100b2eb3ec56d3c557be418c4aabf0229ba4fb58c0bbb0756802e9f1573e245, 0x10a6e05da67b0cab1b2ded1f6e29f2c55279c738e18bbb91687fb046bac7789c);
        if (i == 38) return Utils.G1Point(0x0fe1fdb40a1c4b49772635241e37196fdca6a3cbd8ac2c550e1a48c90ec30029, 0x064ac2c20c146923131bab9ff316498a29fdce765a06c4a891f5b36993f52dba);
        if (i == 39) return Utils.G1Point(0x0c0aadc1d96e9b0b609e9f455c85ecf9506bbb7972f4adf58a3731f40cfd5d77, 0x1f3941c16c4c9da3c169c71abb9557d8b7b54d4b0998410d91d1b4a759f15028);
        if (i == 40) return Utils.G1Point(0x0a46308afef5a8af8f3b822aaa413d2961845a361f05cab5524144e74699cdec, 0x1035f4f2bf0b1ae6d0524d1309829c6d997cd7010650ca05a1bf585206e1aa3b);
        if (i == 41) return Utils.G1Point(0x1ccf854703b8608e10416032eaeadcc7ef236f2d1d33fec289d6db28db10b517, 0x1dbd7e3ed44a0fc339078bcb420b2641210a930a95eecc2aec0147a1abcbbb1a);
        if (i == 42) return Utils.G1Point(0x1408a19ef2793b8af811e95ffbdf901671a3b76bdc2203be5fde5475de4c54bc, 0x26431b0fbb7fb432a0edc0b247fee08d8f44a2abb0cb9b4b8a8a040bdea3cbf8);
        if (i == 43) return Utils.G1Point(0x2eb3aa4eb2234e4de8d30bcfeca595e758bc542da4ee111722fd6be47defd7e8, 0x1a7d7ab203974731e8f33dbbc7af481bbb64e47407e998d2d26dfa90a9dc321b);
        if (i == 44) return Utils.G1Point(0x1b6c0f4b954626f03f4fe59bc83ecc9ac2279d7d20746829583b66735cbb4830, 0x2eb200acc2138afec4e5f53438273760ca4d46bd0ebfa0155ae62a8055fee316);
        if (i == 45) return Utils.G1Point(0x0241820580d821b485c5d3f905cfc4a407881bbc7e041b4e50e2f628f88afc49, 0x2ee28fcaecd349babc91cb6fc9d65ed51dac6e2dd118898e3a0ee1bf0e94793d);
        if (i == 46) return Utils.G1Point(0x0b7b54391ce78ebf1aa3b4b2a75958f1702100aef8163810f89d0ad81c04ed78, 0x129075ea4b1ab58683019ab79340b2b090b9720721046332d8e0e80b2039406e);
        if (i == 47) return Utils.G1Point(0x18c8880c588c4dd3d657439a3357ff3bf0f44b9074d5d7aebb384fbac7e58090, 0x305de2ed95fe36ca48642098d98180b4ab92a03978fa6a038d80e546da989e6a);
        if (i == 48) return Utils.G1Point(0x00f185128b4341f79c914ef9739c830294df8da311891416babcc53e364ef245, 0x0a1ee67a755420fe0835770271142c883ebe3721140075a1677f2d57c6cec4b3);
        if (i == 49) return Utils.G1Point(0x2cf787f4957c6af6a6431d4a1577df0c71b6b44cca9771d8dee49ed83b024008, 0x25dfce7a0c6515b610f0b602d4083adfa436cbf1cce0e3dbec14338bee6ef501);
        if (i == 50) return Utils.G1Point(0x19934b0990d3b31864dcd3a9a7fe8ea20c87ef0abc3980c81035234b961b6c20, 0x2b8ca35cc74606b825937545131cb3c9248ec880b8df7c5eeac6d2be85aff646);
        if (i == 51) return Utils.G1Point(0x2adbdb8197cd82851b706df9c38a53950b1ba5953c8e7fcf3a037e4af817f706, 0x0cd2df6ffbde434614d0288d75ef6afd5d8f0c1b831d38b7de57785658b4bfe9);
        if (i == 52) return Utils.G1Point(0x1ee70de811fe6abb48823d75549e97bb81e3e98aea57e03b03164601b45a8889, 0x18ff1b711d742b30520fb8aeb174940d0e78ad926e0747cd3cf6cd9fdac1eb83);
        if (i == 53) return Utils.G1Point(0x2d831e2ba4c03354502c9ec8569eb4f1b7617b92e90e6bd2df617273793af02e, 0x1d838e04c75622032862a0ad64e997f99b64f9dce9dfd71b25214dc75371ef53);
        if (i == 54) return Utils.G1Point(0x0816128c1a69aacf266b28efd029bd12998f9abbfaa42c6b175d13452e81ec74, 0x084f00999de16016819beea6c19bade38d1802ac9ea2a59c70a94ab43676423f);
        if (i == 55) return Utils.G1Point(0x19fbf07d90fb1fc051cf76bc3ca6fb551463834456cac5a40a7e50dc492b6e07, 0x136cccfcd75ba252a946fc7e8d323ed9afdba4990600f97c8ea69ed72759c756);
        if (i == 56) return Utils.G1Point(0x2c0dca3a80d643d69ac2ccff2c16e727aa5eb81839a0b46e9b9f351941100e86, 0x0d90cee7e881d7484d76b29524af629358dc9795a2a789606fdec6d73e161435);
        if (i == 57) return Utils.G1Point(0x134b5d77b0c39945e9c8a7701bf5058183c5dc2010ab6ab6061243b2d748c4fa, 0x0d6297624431107091b2ccfc7c4f6964a14521ebecc4ca4687ad11ac439c9bc1);
        if (i == 58) return Utils.G1Point(0x1eff41015f3733fb8a295ff8a513d992d8723a159a294b5c444919ba22beb549, 0x0006941da956684261258a79a72fcf1b10e23e3f5844f808749fe10818cade97);
        if (i == 59) return Utils.G1Point(0x05d6227f2a9650a4b35412a9369f96155487d28e0f1827bce5fe2748e2b39c4f, 0x1640729260ba5f06592f23e8d2cf9b0a40ba5d090539b3d3f03e9a9bf8f6aad3);
        if (i == 60) return Utils.G1Point(0x166793ff28c5d31cf3c50fe736340af6cc6d6c80749bbcfd66db78ed80408e50, 0x2015c5c83fb2bb673aeb63e79928fa4c3a8ac6eb758b643e6bb9ff416ec6f3a5);
        if (i == 61) return Utils.G1Point(0x09ea2a4226678267f88c933e6f947fa16648a7710d169e715048e336d1b4129d, 0x26bb40f1b5f88a0a63acebd040aba0bbf85b03e04760bf5be723bd42d0f7d0ae);
        if (i == 62) return Utils.G1Point(0x0fe50825f829d35375a488cff7df34638241bce1a5b2f48c39635651e24c470d, 0x049b06661bb12c19ba643933a06d93035ecec6f53c61b8d4d2b39cc5c0459e68);
        if (i == 63) return Utils.G1Point(0x0b8871057f2a8bf0f794c099fba2481b9f39457d55d7e472e5dc994d69f0fbb8, 0x072c9e81fc2e118414a9fb6d9fff6e5b615f07fa980e3ce692a09bce95cc54f2);
    }

    struct IPAuxiliaries {
        uint256 o;
        uint256[] challenges;
        uint256[] s;
    }

    function verify(InnerProductStatement memory statement, InnerProductProof memory proof, uint256 salt) internal view returns (bool) {
        uint256 log_n = proof.L.length;
        uint256 n = 1 << log_n;

        IPAuxiliaries memory ipAuxiliaries; // for stacktoodeep
        ipAuxiliaries.o = salt; // could probably just access / overwrite the parameter directly.
        ipAuxiliaries.challenges = new uint256[](log_n);
        for (uint256 i = 0; i < log_n; i++) {
            ipAuxiliaries.o = uint256(keccak256(abi.encode(ipAuxiliaries.o, proof.L[i], proof.R[i]))).mod(); // overwrites
            ipAuxiliaries.challenges[i] = ipAuxiliaries.o;
            uint256 inverse = ipAuxiliaries.o.inv();
            statement.P = statement.P.add(proof.L[i].mul(ipAuxiliaries.o.mul(ipAuxiliaries.o)).add(proof.R[i].mul(inverse.mul(inverse))));
        }

        ipAuxiliaries.s = new uint256[](n);
        ipAuxiliaries.s[0] = 1;
        // credit to https://github.com/leanderdulac/BulletProofLib/blob/master/truffle/contracts/EfficientInnerProductVerifier.sol for the below block.
        // it is an unusual and clever variant of what we already do in ZetherVerifier.sol:234-249, but with the special property that it requires only 1 inversion.
        // indeed, that algorithm computes the same function as this, yet its use here would require log(N) modular inversions. inversions turn out to be expensive.
        // of course in that case don't have to invert, but rather to do x minus, etc., so in that case we might as well just use the simpler algorithm.
        for (uint256 i = 0; i < log_n; i++) ipAuxiliaries.s[0] = ipAuxiliaries.s[0].mul(ipAuxiliaries.challenges[i]);
        ipAuxiliaries.s[0] = ipAuxiliaries.s[0].inv(); // here.
        bool[] memory bitSet = new bool[](n);
        for (uint256 i = 0; i < n / 2; i++) {
            for (uint256 j = 0; (1 << j) + i < n; j++) {
                uint256 k = i + (1 << j);
                if (!bitSet[k]) {
                    ipAuxiliaries.s[k] = ipAuxiliaries.s[i].mul(ipAuxiliaries.challenges[log_n - 1 - j]).mul(ipAuxiliaries.challenges[log_n - 1 - j]);
                    bitSet[k] = true;
                }
            }
        }

        Utils.G1Point memory temp = statement.u.mul(proof.a.mul(proof.b));
        for (uint256 i = 0; i < n; i++) {
            temp = temp.add(gs(i).mul(ipAuxiliaries.s[i].mul(proof.a)));
            temp = temp.add(statement.hs[i].mul(ipAuxiliaries.s[n - 1 - i].mul(proof.b)));
        }
        require(temp.eq(statement.P), "Inner product equality check failure.");

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./VoteToken.sol";
import "./Utils.sol";
import "./InnerProductVerifier.sol";
import "./ZetherVerifier.sol";
import "./BurnVerifier.sol";

contract ZSC {
    using Utils for uint256;
    using Utils for Utils.G1Point;

    VoteToken coin;
    ZetherVerifier zetherVerifier;
    BurnVerifier burnVerifier;
    uint256 public epochLength;
    uint256 public fee;

    uint256 constant MAX = 4294967295; // 2^32 - 1 // no sload for constants...!
    mapping(bytes32 => Utils.G1Point[2]) acc; // main account mapping
    mapping(bytes32 => Utils.G1Point[2]) pending; // storage for pending transfers
    mapping(bytes32 => uint256) lastRollOver;
    bytes32[] nonceSet; // would be more natural to use a mapping, but they can't be deleted / reset!
    uint256 lastGlobalUpdate = 0; // will be also used as a proxy for "current epoch", seeing as rollovers will be anticipated
    // not implementing account locking for now...revisit

    event TransferOccurred(Utils.G1Point[] parties, Utils.G1Point beneficiary);
    // arg is still necessary for transfers---not even so much to know when you received a transfer, as to know when you got rolled over.

    constructor(address _coin, address _zether, address _burn, uint256 _epochLength) { // visibiility won't be needed in 7.0
        // epoch length, like block.time, is in _seconds_. 4 is the minimum!!! (To allow a withdrawal to go through.)
        coin = VoteToken(_coin);
        zetherVerifier = ZetherVerifier(_zether);
        burnVerifier = BurnVerifier(_burn);
        epochLength = _epochLength;
        fee = zetherVerifier.fee();
        Utils.G1Point memory empty;
        pending[keccak256(abi.encode(empty))][1] = Utils.g(); // "register" the empty account...
    }

    function simulateAccounts(Utils.G1Point[] memory y, uint256 epoch) view public returns (Utils.G1Point[2][] memory accounts) {
        // in this function and others, i have to use public + memory (and hence, a superfluous copy from calldata)
        // only because calldata structs aren't yet supported by solidity. revisit this in the future.
        uint256 size = y.length;
        accounts = new Utils.G1Point[2][](size);
        for (uint256 i = 0; i < size; i++) {
            bytes32 yHash = keccak256(abi.encode(y[i]));
            accounts[i] = acc[yHash];
            if (lastRollOver[yHash] < epoch) {
                Utils.G1Point[2] memory scratch = pending[yHash];
                accounts[i][0] = accounts[i][0].add(scratch[0]);
                accounts[i][1] = accounts[i][1].add(scratch[1]);
            }
        }
    }

    function rollOver(bytes32 yHash) internal {
        uint256 e = block.timestamp / epochLength;
        if (lastRollOver[yHash] < e) {
            Utils.G1Point[2][2] memory scratch = [acc[yHash], pending[yHash]];
            acc[yHash][0] = scratch[0][0].add(scratch[1][0]);
            acc[yHash][1] = scratch[0][1].add(scratch[1][1]);
            // acc[yHash] = scratch[0]; // can't do this---have to do the above instead (and spend 2 sloads / stores)---because "not supported". revisit
            delete pending[yHash]; // pending[yHash] = [Utils.G1Point(0, 0), Utils.G1Point(0, 0)];
            lastRollOver[yHash] = e;
        }
        if (lastGlobalUpdate < e) {
            lastGlobalUpdate = e;
            delete nonceSet;
        }
    }

    function registered(bytes32 yHash) internal view returns (bool) {
        Utils.G1Point memory zero = Utils.G1Point(0, 0);
        Utils.G1Point[2][2] memory scratch = [acc[yHash], pending[yHash]];
        return !(scratch[0][0].eq(zero) && scratch[0][1].eq(zero) && scratch[1][0].eq(zero) && scratch[1][1].eq(zero));
    }

    function register(Utils.G1Point memory y, uint256 c, uint256 s) public {
        // allows y to participate. c, s should be a Schnorr signature on "this"
        Utils.G1Point memory K = Utils.g().mul(s).add(y.mul(c.neg()));
        uint256 challenge = uint256(keccak256(abi.encode(address(this), y, K))).mod();
        require(challenge == c, "Invalid registration signature!");
        bytes32 yHash = keccak256(abi.encode(y));
        require(!registered(yHash), "Account already registered!");
        // pending[yHash] = [y, Utils.g()]; // "not supported" yet, have to do the below
        pending[yHash][0] = y;
        pending[yHash][1] = Utils.g();
    }

    function fund(Utils.G1Point memory y, uint256 bTransfer) public {
        bytes32 yHash = keccak256(abi.encode(y));
        require(registered(yHash), "Account not yet registered.");
        rollOver(yHash);

        require(bTransfer <= MAX, "Deposit amount out of range."); // uint, so other way not necessary?

        Utils.G1Point memory scratch = pending[yHash][0];
        scratch = scratch.add(Utils.g().mul(bTransfer));
        pending[yHash][0] = scratch;
        require(coin.transferFrom(msg.sender, address(this), bTransfer), "Transfer from sender failed.");
        require(coin.balanceOf(address(this)) <= MAX, "Fund pushes contract past maximum value.");
    }

    function transfer(Utils.G1Point[] memory C, Utils.G1Point memory D, Utils.G1Point[] memory y, Utils.G1Point memory u, bytes memory proof, Utils.G1Point memory beneficiary) public {
        uint256 size = y.length;
        Utils.G1Point[] memory CLn = new Utils.G1Point[](size);
        Utils.G1Point[] memory CRn = new Utils.G1Point[](size);
        require(C.length == size, "Input array length mismatch!");

        bytes32 beneficiaryHash = keccak256(abi.encode(beneficiary));
        require(registered(beneficiaryHash), "Miner's account is not yet registered."); // necessary so that receiving a fee can't "backdoor" you into registration.
        rollOver(beneficiaryHash);
        pending[beneficiaryHash][0] = pending[beneficiaryHash][0].add(Utils.g().mul(fee));

        for (uint256 i = 0; i < size; i++) {
            bytes32 yHash = keccak256(abi.encode(y[i]));
            require(registered(yHash), "Account not yet registered.");
            rollOver(yHash);
            Utils.G1Point[2] memory scratch = pending[yHash];
            pending[yHash][0] = scratch[0].add(C[i]);
            pending[yHash][1] = scratch[1].add(D);
            // pending[yHash] = scratch; // can't do this, so have to use 2 sstores _anyway_ (as in above)

            scratch = acc[yHash]; // trying to save an sload, i guess.
            CLn[i] = scratch[0].add(C[i]);
            CRn[i] = scratch[1].add(D);
        }

        bytes32 uHash = keccak256(abi.encode(u));
        for (uint256 i = 0; i < nonceSet.length; i++) {
            require(nonceSet[i] != uHash, "Nonce already seen!");
        }
        nonceSet.push(uHash);

        require(zetherVerifier.verifyTransfer(CLn, CRn, C, D, y, lastGlobalUpdate, u, proof), "Transfer proof verification failed!");

        emit TransferOccurred(y, beneficiary);
    }

    function burn(Utils.G1Point memory y, uint256 bTransfer, Utils.G1Point memory u, bytes memory proof) public {
        bytes32 yHash = keccak256(abi.encode(y));
        require(registered(yHash), "Account not yet registered.");
        rollOver(yHash);

        require(0 <= bTransfer && bTransfer <= MAX, "Transfer amount out of range.");
        Utils.G1Point[2] memory scratch = pending[yHash];
        pending[yHash][0] = scratch[0].add(Utils.g().mul(bTransfer.neg()));

        scratch = acc[yHash]; // simulate debit of acc---just for use in verification, won't be applied
        scratch[0] = scratch[0].add(Utils.g().mul(bTransfer.neg()));
        bytes32 uHash = keccak256(abi.encode(u));
        for (uint256 i = 0; i < nonceSet.length; i++) {
            require(nonceSet[i] != uHash, "Nonce already seen!");
        }
        nonceSet.push(uHash);

        require(burnVerifier.verifyBurn(scratch[0], scratch[1], y, lastGlobalUpdate, u, msg.sender, proof), "Burn proof verification failed!");
        require(coin.transfer(msg.sender, bTransfer), "This shouldn't fail... Something went severely wrong.");
    }
}

//Be name khoda

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract VoteToken is ERC20, AccessControl {

    mapping(address => bool) isCandidate;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

	constructor() ERC20("Vote Token", "VOTE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, msg.sender);
        grantRole(ADMIN_ROLE, msg.sender);
        _setupDecimals(0);
	}

	function mint(uint nationalCode, address to) external {
        require(hasRole(MINTER_ROLE, msg.sender), "ERR: Caller is not a minter");
        _mint(to, 1);
        emit MintVote(nationalCode, to, 1);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(isCandidate[recipient], "ERR: You can not send your vote to people wallets");
        return super.transfer(recipient, amount);
    }

    function addCandidate(address candidate) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "ERR: Caller is not an admin");
        isCandidate[candidate] = true;
		emit CandidateAdded(candidate);
	}

	function removeCandidate(address candidate) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "ERR: Caller is not an admin");
        delete isCandidate[candidate];
		emit CandidateRemoved(candidate);
	}

    event MintVote(uint nationalCode, address to, uint amount);
    event CandidateRemoved(address candidate);
    event CandidateAdded(address candidate);
}

//Dar panah khoda

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";
import "./InnerProductVerifier.sol";

contract ZetherVerifier {
    using Utils for uint256;
    using Utils for Utils.G1Point;

    uint256 constant UNITY = 0x14a3074b02521e3b1ed9852e5028452693e87be4e910500c7ba9bbddb2f46edd; // primitive 2^28th root of unity modulo q.
    uint256 constant TWO_INV = 0x183227397098d014dc2822db40c0ac2e9419f4243cdcb848a1f0fac9f8000001; // 2^{-1} modulo q

    InnerProductVerifier ip;
    uint256 public constant fee = 0; // set this to be the "transaction fee". can be any integer under MAX.

    struct ZetherStatement {
        Utils.G1Point[] CLn;
        Utils.G1Point[] CRn;
        Utils.G1Point[] C;
        Utils.G1Point D;
        Utils.G1Point[] y;
        uint256 epoch;
        Utils.G1Point u;
    }

    struct ZetherProof {
        Utils.G1Point BA;
        Utils.G1Point BS;
        Utils.G1Point A;
        Utils.G1Point B;

        Utils.G1Point[] CLnG;
        Utils.G1Point[] CRnG;
        Utils.G1Point[] C_0G;
        Utils.G1Point[] DG;
        Utils.G1Point[] y_0G;
        Utils.G1Point[] gG;
        Utils.G1Point[] C_XG;
        Utils.G1Point[] y_XG;

        uint256[] f;
        uint256 z_A;

        Utils.G1Point T_1;
        Utils.G1Point T_2;
        uint256 tHat;
        uint256 mu;

        uint256 c;
        uint256 s_sk;
        uint256 s_r;
        uint256 s_b;
        uint256 s_tau;

        InnerProductVerifier.InnerProductProof ipProof;
    }

    constructor(address _ip) {
        ip = InnerProductVerifier(_ip);
    }

    function verifyTransfer(Utils.G1Point[] memory CLn, Utils.G1Point[] memory CRn, Utils.G1Point[] memory C, Utils.G1Point memory D, Utils.G1Point[] memory y, uint256 epoch, Utils.G1Point memory u, bytes memory proof) public view returns (bool) {
        ZetherStatement memory statement;
        statement.CLn = CLn; // do i need to allocate / set size?!
        statement.CRn = CRn;
        statement.C = C;
        statement.D = D;
        statement.y = y;
        statement.epoch = epoch;
        statement.u = u;
        ZetherProof memory zetherProof = unserialize(proof);
        return verify(statement, zetherProof);
    }

    struct ZetherAuxiliaries {
        uint256 y;
        uint256[64] ys;
        uint256 z;
        uint256[2] zs; // [z^2, z^3]
        uint256[64] twoTimesZSquared;
        uint256 zSum;
        uint256 x;
        uint256 t;
        uint256 k;
        Utils.G1Point tEval;
    }

    struct SigmaAuxiliaries {
        uint256 c;
        Utils.G1Point A_y;
        Utils.G1Point A_D;
        Utils.G1Point A_b;
        Utils.G1Point A_X;
        Utils.G1Point A_t;
        Utils.G1Point gEpoch;
        Utils.G1Point A_u;
    }

    struct AnonAuxiliaries {
        uint256 m;
        uint256 N;
        uint256 v;
        uint256 w;
        uint256 vPow;
        uint256 wPow;
        uint256[2][] f; // could just allocate extra space in the proof?
        uint256[2][] r; // each poly is an array of length N. evaluations of prods
        Utils.G1Point temp;
        Utils.G1Point CLnR;
        Utils.G1Point CRnR;
        Utils.G1Point[2][] CR;
        Utils.G1Point[2][] yR;
        Utils.G1Point C_XR;
        Utils.G1Point y_XR;
        Utils.G1Point gR;
        Utils.G1Point DR;
    }

    struct IPAuxiliaries {
        Utils.G1Point P;
        Utils.G1Point u_x;
        Utils.G1Point[] hPrimes;
        Utils.G1Point hPrimeSum;
        uint256 o;
    }

    function gSum() internal pure returns (Utils.G1Point memory) {
        return Utils.G1Point(0x00715f13ea08d6b51bedcde3599d8e12163e090921309d5aafc9b5bfaadbcda0, 0x27aceab598af7bf3d16ca9d40fe186c489382c21bb9d22b19cb3af8b751b959f);
    }

    function verify(ZetherStatement memory statement, ZetherProof memory proof) internal view returns (bool) {
        uint256 statementHash = uint256(keccak256(abi.encode(statement.CLn, statement.CRn, statement.C, statement.D, statement.y, statement.epoch))).mod();
        AnonAuxiliaries memory anonAuxiliaries;
        anonAuxiliaries.v = uint256(keccak256(abi.encode(statementHash, proof.BA, proof.BS, proof.A, proof.B))).mod();
        anonAuxiliaries.w = uint256(keccak256(abi.encode(anonAuxiliaries.v, proof.CLnG, proof.CRnG, proof.C_0G, proof.DG, proof.y_0G, proof.gG, proof.C_XG, proof.y_XG))).mod();
        anonAuxiliaries.m = proof.f.length / 2;
        anonAuxiliaries.N = 1 << anonAuxiliaries.m;
        anonAuxiliaries.f = new uint256[2][](2 * anonAuxiliaries.m);
        for (uint256 k = 0; k < 2 * anonAuxiliaries.m; k++) {
            anonAuxiliaries.f[k][1] = proof.f[k];
            anonAuxiliaries.f[k][0] = anonAuxiliaries.w.sub(proof.f[k]); // is it wasteful to store / keep all these in memory?
        }

        for (uint256 k = 0; k < 2 * anonAuxiliaries.m; k++) {
            anonAuxiliaries.temp = anonAuxiliaries.temp.add(ip.gs(k).mul(anonAuxiliaries.f[k][1]));
            anonAuxiliaries.temp = anonAuxiliaries.temp.add(ip.hs(k).mul(anonAuxiliaries.f[k][1].mul(anonAuxiliaries.f[k][0])));
        }
        anonAuxiliaries.temp = anonAuxiliaries.temp.add(ip.hs(2 * anonAuxiliaries.m).mul(anonAuxiliaries.f[0][1].mul(anonAuxiliaries.f[anonAuxiliaries.m][1])).add(ip.hs(2 * anonAuxiliaries.m + 1).mul(anonAuxiliaries.f[0][0].mul(anonAuxiliaries.f[anonAuxiliaries.m][0]))));
        require(proof.B.mul(anonAuxiliaries.w).add(proof.A).eq(anonAuxiliaries.temp.add(Utils.h().mul(proof.z_A))), "Recovery failure for B^w * A.");

        anonAuxiliaries.r = assemblePolynomials(anonAuxiliaries.f);

        anonAuxiliaries.CR = assembleConvolutions(anonAuxiliaries.r, statement.C);
        anonAuxiliaries.yR = assembleConvolutions(anonAuxiliaries.r, statement.y);
        for (uint256 i = 0; i < anonAuxiliaries.N; i++) {
            anonAuxiliaries.CLnR = anonAuxiliaries.CLnR.add(statement.CLn[i].mul(anonAuxiliaries.r[i][0]));
            anonAuxiliaries.CRnR = anonAuxiliaries.CRnR.add(statement.CRn[i].mul(anonAuxiliaries.r[i][0]));
        }
        anonAuxiliaries.vPow = 1;
        for (uint256 i = 0; i < anonAuxiliaries.N; i++) {
            anonAuxiliaries.C_XR = anonAuxiliaries.C_XR.add(anonAuxiliaries.CR[i / 2][i % 2].mul(anonAuxiliaries.vPow));
            anonAuxiliaries.y_XR = anonAuxiliaries.y_XR.add(anonAuxiliaries.yR[i / 2][i % 2].mul(anonAuxiliaries.vPow));
            if (i > 0) {
                anonAuxiliaries.vPow = anonAuxiliaries.vPow.mul(anonAuxiliaries.v);
            }
        }
        anonAuxiliaries.wPow = 1;
        for (uint256 k = 0; k < anonAuxiliaries.m; k++) {
            anonAuxiliaries.CLnR = anonAuxiliaries.CLnR.add(proof.CLnG[k].mul(anonAuxiliaries.wPow.neg()));
            anonAuxiliaries.CRnR = anonAuxiliaries.CRnR.add(proof.CRnG[k].mul(anonAuxiliaries.wPow.neg()));
            anonAuxiliaries.CR[0][0] = anonAuxiliaries.CR[0][0].add(proof.C_0G[k].mul(anonAuxiliaries.wPow.neg()));
            anonAuxiliaries.DR = anonAuxiliaries.DR.add(proof.DG[k].mul(anonAuxiliaries.wPow.neg()));
            anonAuxiliaries.yR[0][0] = anonAuxiliaries.yR[0][0].add(proof.y_0G[k].mul(anonAuxiliaries.wPow.neg()));
            anonAuxiliaries.gR = anonAuxiliaries.gR.add(proof.gG[k].mul(anonAuxiliaries.wPow.neg()));
            anonAuxiliaries.C_XR = anonAuxiliaries.C_XR.add(proof.C_XG[k].mul(anonAuxiliaries.wPow.neg()));
            anonAuxiliaries.y_XR = anonAuxiliaries.y_XR.add(proof.y_XG[k].mul(anonAuxiliaries.wPow.neg()));

            anonAuxiliaries.wPow = anonAuxiliaries.wPow.mul(anonAuxiliaries.w);
        }
        anonAuxiliaries.DR = anonAuxiliaries.DR.add(statement.D.mul(anonAuxiliaries.wPow));
        anonAuxiliaries.gR = anonAuxiliaries.gR.add(Utils.g().mul(anonAuxiliaries.wPow));
        anonAuxiliaries.C_XR = anonAuxiliaries.C_XR.add(Utils.g().mul(fee.mul(anonAuxiliaries.wPow)));  // this line is new

        ZetherAuxiliaries memory zetherAuxiliaries;
        zetherAuxiliaries.y = uint256(keccak256(abi.encode(anonAuxiliaries.w))).mod();
        zetherAuxiliaries.ys[0] = 1;
        zetherAuxiliaries.k = 1;
        for (uint256 i = 1; i < 64; i++) {
            zetherAuxiliaries.ys[i] = zetherAuxiliaries.ys[i - 1].mul(zetherAuxiliaries.y);
            zetherAuxiliaries.k = zetherAuxiliaries.k.add(zetherAuxiliaries.ys[i]);
        }
        zetherAuxiliaries.z = uint256(keccak256(abi.encode(zetherAuxiliaries.y))).mod();
        zetherAuxiliaries.zs[0] = zetherAuxiliaries.z.mul(zetherAuxiliaries.z);
        zetherAuxiliaries.zs[1] = zetherAuxiliaries.zs[0].mul(zetherAuxiliaries.z);
        zetherAuxiliaries.zSum = zetherAuxiliaries.zs[0].add(zetherAuxiliaries.zs[1]).mul(zetherAuxiliaries.z);
        zetherAuxiliaries.k = zetherAuxiliaries.k.mul(zetherAuxiliaries.z.sub(zetherAuxiliaries.zs[0])).sub(zetherAuxiliaries.zSum.mul(1 << 32).sub(zetherAuxiliaries.zSum));
        zetherAuxiliaries.t = proof.tHat.sub(zetherAuxiliaries.k); // t = tHat - delta(y, z)
        for (uint256 i = 0; i < 32; i++) {
            zetherAuxiliaries.twoTimesZSquared[i] = zetherAuxiliaries.zs[0].mul(1 << i);
            zetherAuxiliaries.twoTimesZSquared[i + 32] = zetherAuxiliaries.zs[1].mul(1 << i);
        }

        zetherAuxiliaries.x = uint256(keccak256(abi.encode(zetherAuxiliaries.z, proof.T_1, proof.T_2))).mod();
        zetherAuxiliaries.tEval = proof.T_1.mul(zetherAuxiliaries.x).add(proof.T_2.mul(zetherAuxiliaries.x.mul(zetherAuxiliaries.x))); // replace with "commit"?

        SigmaAuxiliaries memory sigmaAuxiliaries;
        sigmaAuxiliaries.A_y = anonAuxiliaries.gR.mul(proof.s_sk).add(anonAuxiliaries.yR[0][0].mul(proof.c.neg()));
        sigmaAuxiliaries.A_D = Utils.g().mul(proof.s_r).add(statement.D.mul(proof.c.neg())); // add(mul(anonAuxiliaries.gR, proof.s_r), mul(anonAuxiliaries.DR, proof.c.neg()));
        sigmaAuxiliaries.A_b = Utils.g().mul(proof.s_b).add(anonAuxiliaries.DR.mul(zetherAuxiliaries.zs[0].neg()).add(anonAuxiliaries.CRnR.mul(zetherAuxiliaries.zs[1])).mul(proof.s_sk).add(anonAuxiliaries.CR[0][0].add(Utils.g().mul(fee.mul(anonAuxiliaries.wPow))).mul(zetherAuxiliaries.zs[0].neg()).add(anonAuxiliaries.CLnR.mul(zetherAuxiliaries.zs[1])).mul(proof.c.neg())));
        sigmaAuxiliaries.A_X = anonAuxiliaries.y_XR.mul(proof.s_r).add(anonAuxiliaries.C_XR.mul(proof.c.neg()));
        sigmaAuxiliaries.A_t = Utils.g().mul(zetherAuxiliaries.t).add(zetherAuxiliaries.tEval.neg()).mul(proof.c.mul(anonAuxiliaries.wPow)).add(Utils.h().mul(proof.s_tau)).add(Utils.g().mul(proof.s_b.neg()));
        sigmaAuxiliaries.gEpoch = Utils.mapInto("Zether", statement.epoch);
        sigmaAuxiliaries.A_u = sigmaAuxiliaries.gEpoch.mul(proof.s_sk).add(statement.u.mul(proof.c.neg()));

        sigmaAuxiliaries.c = uint256(keccak256(abi.encode(zetherAuxiliaries.x, sigmaAuxiliaries.A_y, sigmaAuxiliaries.A_D, sigmaAuxiliaries.A_b, sigmaAuxiliaries.A_X, sigmaAuxiliaries.A_t, sigmaAuxiliaries.A_u))).mod();
        require(sigmaAuxiliaries.c == proof.c, "Sigma protocol challenge equality failure.");

        IPAuxiliaries memory ipAuxiliaries;
        ipAuxiliaries.o = uint256(keccak256(abi.encode(sigmaAuxiliaries.c))).mod();
        ipAuxiliaries.u_x = Utils.h().mul(ipAuxiliaries.o);
        ipAuxiliaries.hPrimes = new Utils.G1Point[](64);
        for (uint256 i = 0; i < 64; i++) {
            ipAuxiliaries.hPrimes[i] = ip.hs(i).mul(zetherAuxiliaries.ys[i].inv());
            ipAuxiliaries.hPrimeSum = ipAuxiliaries.hPrimeSum.add(ipAuxiliaries.hPrimes[i].mul(zetherAuxiliaries.ys[i].mul(zetherAuxiliaries.z).add(zetherAuxiliaries.twoTimesZSquared[i])));
        }
        ipAuxiliaries.P = proof.BA.add(proof.BS.mul(zetherAuxiliaries.x)).add(gSum().mul(zetherAuxiliaries.z.neg())).add(ipAuxiliaries.hPrimeSum);
        ipAuxiliaries.P = ipAuxiliaries.P.add(Utils.h().mul(proof.mu.neg()));
        ipAuxiliaries.P = ipAuxiliaries.P.add(ipAuxiliaries.u_x.mul(proof.tHat));
        require(ip.verifyInnerProduct(ipAuxiliaries.hPrimes, ipAuxiliaries.u_x, ipAuxiliaries.P, proof.ipProof, ipAuxiliaries.o), "Inner product proof verification failed.");

        return true;
    }

    function assemblePolynomials(uint256[2][] memory f) internal pure returns (uint256[2][] memory result) {
        // f is a 2m-by-2 array... containing the f's and x - f's, twice (i.e., concatenated).
        // output contains two "rows", each of length N.
        uint256 m = f.length / 2;
        uint256 N = 1 << m;
        result = new uint256[2][](N);
        for (uint256 j = 0; j < 2; j++) {
            result[0][j] = 1;
            for (uint256 k = 0; k < m; k++) {
                for (uint256 i = 0; i < N; i += 1 << m - k) {
                    result[i + (1 << m - 1 - k)][j] = result[i][j].mul(f[j * m + m - 1 - k][1]);
                    result[i][j] = result[i][j].mul(f[j * m + m - 1 - k][0]);
                }
            }
        }
    }

    function assembleConvolutions(uint256[2][] memory exponent, Utils.G1Point[] memory base) internal view returns (Utils.G1Point[2][] memory result) {
        // exponent is two "rows" (actually columns).
        // will return two rows, each of half the length of the exponents;
        // namely, we will return the Hadamards of "base" by the even circular shifts of "exponent"'s rows.
        uint256 size = exponent.length;
        uint256 half = size / 2;
        result = new Utils.G1Point[2][](half); // assuming that this is necessary even when return is declared up top
        uint256 omega = UNITY.exp((1 << 28) / size); // wasteful: using exp for all 256-bits, though we only need 28 (at most!)
        uint256 omega_inv = omega.mul(omega).inv(); // also square it. inverse fft will be half as big
        uint256[] memory omegas = new uint256[](half);
        uint256[] memory inverses = new uint256[](half / 2); // if it's not an integer, will this still work nicely?
        omegas[0] = 1;
        inverses[0] = 1;
        for (uint256 i = 1; i < half; i++) omegas[i] = omegas[i - 1].mul(omega);
        for (uint256 i = 1; i < half / 2; i++) inverses[i] = inverses[i - 1].mul(omega_inv);
        Utils.G1Point[] memory base_fft = fft(base, omegas, false); // could precompute UNITY.inv(), but... have to exp it anyway
        uint256[] memory exponent_fft = new uint256[](size);
        for (uint256 j = 0; j < 2; j++) {
            for (uint256 i = 0; i < size; i++) exponent_fft[i] = exponent[(size - i) % size][j]; // convolutional flip plus copy

            exponent_fft = fft(exponent_fft, omegas);
            Utils.G1Point[] memory inverse_fft = new Utils.G1Point[](half);
            for (uint256 i = 0; i < half; i++) { // break up into two statements for ease of reading
                inverse_fft[i] = inverse_fft[i].add(base_fft[i].mul(exponent_fft[i].mul(TWO_INV)));
                inverse_fft[i] = inverse_fft[i].add(base_fft[i + half].mul(exponent_fft[i + half].mul(TWO_INV)));
            }

            inverse_fft = fft(inverse_fft, inverses, true); // square, because half as big.
            for (uint256 i = 0; i < half; i++) result[i][j] = inverse_fft[i];
        }
    }

    function fft(Utils.G1Point[] memory input, uint256[] memory omegas, bool inverse) internal view returns (Utils.G1Point[] memory result) {
        uint256 size = input.length;
        if (size == 1) return input;
        require(size % 2 == 0, "Input size is not a power of 2!");

        Utils.G1Point[] memory even = fft(extract(input, 0), extract(omegas, 0), inverse);
        Utils.G1Point[] memory odd = fft(extract(input, 1), extract(omegas, 0), inverse);
        result = new Utils.G1Point[](size);
        for (uint256 i = 0; i < size / 2; i++) {
            Utils.G1Point memory temp = odd[i].mul(omegas[i]);
            result[i] = even[i].add(temp);
            result[i + size / 2] = even[i].add(temp.neg());
            if (inverse) { // could probably "delay" the successive multiplications by 2 up the recursion.
                result[i] = result[i].mul(TWO_INV);
                result[i + size / 2] = result[i + size / 2].mul(TWO_INV);
            }
        }
    }

    function extract(Utils.G1Point[] memory input, uint256 parity) internal pure returns (Utils.G1Point[] memory result) {
        result = new Utils.G1Point[](input.length / 2);
        for (uint256 i = 0; i < input.length / 2; i++) {
            result[i] = input[2 * i + parity];
        }
    }

    function fft(uint256[] memory input, uint256[] memory omegas) internal view returns (uint256[] memory result) {
        uint256 size = input.length;
        if (size == 1) return input;
        require(size % 2 == 0, "Input size is not a power of 2!");

        uint256[] memory even = fft(extract(input, 0), extract(omegas, 0));
        uint256[] memory odd = fft(extract(input, 1), extract(omegas, 0));
        result = new uint256[](size);
        for (uint256 i = 0; i < size / 2; i++) {
            uint256 temp = odd[i].mul(omegas[i]);
            result[i] = even[i].add(temp);
            result[i + size / 2] = even[i].sub(temp);
        }
    }

    function extract(uint256[] memory input, uint256 parity) internal pure returns (uint256[] memory result) {
        result = new uint256[](input.length / 2);
        for (uint256 i = 0; i < input.length / 2; i++) {
            result[i] = input[2 * i + parity];
        }
    }

    function unserialize(bytes memory arr) internal pure returns (ZetherProof memory proof) {
        proof.BA = Utils.G1Point(Utils.slice(arr, 0), Utils.slice(arr, 32));
        proof.BS = Utils.G1Point(Utils.slice(arr, 64), Utils.slice(arr, 96));
        proof.A = Utils.G1Point(Utils.slice(arr, 128), Utils.slice(arr, 160));
        proof.B = Utils.G1Point(Utils.slice(arr, 192), Utils.slice(arr, 224));

        uint256 m = (arr.length - 1472) / 576;
        proof.CLnG = new Utils.G1Point[](m);
        proof.CRnG = new Utils.G1Point[](m);
        proof.C_0G = new Utils.G1Point[](m);
        proof.DG = new Utils.G1Point[](m);
        proof.y_0G = new Utils.G1Point[](m);
        proof.gG = new Utils.G1Point[](m);
        proof.C_XG = new Utils.G1Point[](m);
        proof.y_XG = new Utils.G1Point[](m);
        proof.f = new uint256[](2 * m);
        for (uint256 k = 0; k < m; k++) {
            proof.CLnG[k] = Utils.G1Point(Utils.slice(arr, 256 + k * 64), Utils.slice(arr, 288 + k * 64));
            proof.CRnG[k] = Utils.G1Point(Utils.slice(arr, 256 + (m + k) * 64), Utils.slice(arr, 288 + (m + k) * 64));
            proof.C_0G[k] = Utils.G1Point(Utils.slice(arr, 256 + m * 128 + k * 64), Utils.slice(arr, 288 + m * 128 + k * 64));
            proof.DG[k] = Utils.G1Point(Utils.slice(arr, 256 + m * 192 + k * 64), Utils.slice(arr, 288 + m * 192 + k * 64));
            proof.y_0G[k] = Utils.G1Point(Utils.slice(arr, 256 + m * 256 + k * 64), Utils.slice(arr, 288 + m * 256 + k * 64));
            proof.gG[k] = Utils.G1Point(Utils.slice(arr, 256 + m * 320 + k * 64), Utils.slice(arr, 288 + m * 320 + k * 64));
            proof.C_XG[k] = Utils.G1Point(Utils.slice(arr, 256 + m * 384 + k * 64), Utils.slice(arr, 288 + m * 384 + k * 64));
            proof.y_XG[k] = Utils.G1Point(Utils.slice(arr, 256 + m * 448 + k * 64), Utils.slice(arr, 288 + m * 448 + k * 64));
            proof.f[k] = uint256(Utils.slice(arr, 256 + m * 512 + k * 32));
            proof.f[k + m] = uint256(Utils.slice(arr, 256 + m * 544 + k * 32));
        }
        uint256 starting = m * 576;
        proof.z_A = uint256(Utils.slice(arr, 256 + starting));

        proof.T_1 = Utils.G1Point(Utils.slice(arr, 288 + starting), Utils.slice(arr, 320 + starting));
        proof.T_2 = Utils.G1Point(Utils.slice(arr, 352 + starting), Utils.slice(arr, 384 + starting));
        proof.tHat = uint256(Utils.slice(arr, 416 + starting));
        proof.mu = uint256(Utils.slice(arr, 448 + starting));

        proof.c = uint256(Utils.slice(arr, 480 + starting));
        proof.s_sk = uint256(Utils.slice(arr, 512 + starting));
        proof.s_r = uint256(Utils.slice(arr, 544 + starting));
        proof.s_b = uint256(Utils.slice(arr, 576 + starting));
        proof.s_tau = uint256(Utils.slice(arr, 608 + starting));

        InnerProductVerifier.InnerProductProof memory ipProof;
        ipProof.L = new Utils.G1Point[](6);
        ipProof.R = new Utils.G1Point[](6);
        for (uint256 i = 0; i < 6; i++) { // 2^6 = 64.
            ipProof.L[i] = Utils.G1Point(Utils.slice(arr, 640 + starting + i * 64), Utils.slice(arr, 672 + starting + i * 64));
            ipProof.R[i] = Utils.G1Point(Utils.slice(arr, 640 + starting + (6 + i) * 64), Utils.slice(arr, 672 + starting + (6 + i) * 64));
        }
        ipProof.a = uint256(Utils.slice(arr, 640 + starting + 6 * 128));
        ipProof.b = uint256(Utils.slice(arr, 672 + starting + 6 * 128));
        proof.ipProof = ipProof;

        return proof;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

