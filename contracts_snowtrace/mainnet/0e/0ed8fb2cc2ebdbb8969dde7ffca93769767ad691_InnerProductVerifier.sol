// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./Utils.sol";

contract InnerProductVerifier {
    using Utils for uint256;
    using Utils for Utils.Point;

    Utils.Point[M << 1] public gs;
    Utils.Point[M << 1] public hs;
    // have to use storage, not immutable, because solidity doesn't support non-primitive immutable types

    constructor() {
        for (uint256 i = 0; i < M << 1; i++) {
            gs[i] = Utils.mapInto("g", i);
            hs[i] = Utils.mapInto("h", i);
        }
    }

    struct Locals {
        uint256 o;
        Utils.Point P;
        uint256[m + 1] challenges;
        uint256[M << 1] s;
    }

    function verify(Utils.InnerProductStatement calldata statement, Utils.InnerProductProof calldata proof, bool transfer) external view {
        Locals memory locals;
        locals.o = statement.salt;
        locals.P = statement.P;
        for (uint256 i = 0; i < m + (transfer ? 1 : 0); i++) {
            locals.o = uint256(keccak256(abi.encode(locals.o, proof.L[i], proof.R[i]))).mod(); // overwrites
            locals.challenges[i] = locals.o;
            uint256 inverse = locals.o.inv();
            locals.P = locals.P.add(proof.L[i].mul(locals.o.mul(locals.o))).add(proof.R[i].mul(inverse.mul(inverse)));
        }

        locals.s[0] = 1;
        // credit to https://github.com/leanderdulac/BulletProofLib/blob/master/truffle/contracts/EfficientInnerProductVerifier.sol for the below block.
        // it is an unusual and clever variant of what we already do in Utils.sol:322-332, but with the special property that it requires only 1 inversion.
        // indeed, that algorithm computes the same function as this, yet its use here would require log(M) modular inversions. inversions are expensive.
        // of course in that case don't have to invert, but rather to do x minus, etc., so in that case we might as well just use the simpler algorithm.
        for (uint256 i = 0; i < m + (transfer ? 1 : 0); i++) locals.s[0] = locals.s[0].mul(locals.challenges[i]);
        locals.s[0] = locals.s[0].inv(); // here.
        bool[M << 1] memory set; // will only use the first half in the case of withdrawals
        for (uint256 i = 0; i < M >> (transfer ? 0 : 1); i++) {
            for (uint256 j = 0; (1 << j) + i < M << (transfer ? 1 : 0); j++) {
                uint256 k = i + (1 << j);
                if (!set[k]) {
                    locals.s[k] = locals.s[i].mul(locals.challenges[m + (transfer ? 1 : 0) - 1 - j]).mul(locals.challenges[m + (transfer ? 1 : 0) - 1 - j]);
                    set[k] = true;
                }
            }
        }
        Utils.Point memory temp = statement.u.mul(proof.a.mul(proof.b));
        for (uint256 i = 0; i < M << (transfer ? 1 : 0); i++) {
            temp = temp.add(gs[i].mul(locals.s[i].mul(proof.a)));
            temp = temp.add(statement.hs[i].mul(locals.s[(M << (transfer ? 1 : 0)) - 1 - i].mul(proof.b)));
        }
        require(temp.eq(locals.P), "Inner product proof failed.");
    }
}