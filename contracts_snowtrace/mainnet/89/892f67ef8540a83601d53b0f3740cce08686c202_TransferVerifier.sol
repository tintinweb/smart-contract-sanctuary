pragma solidity 0.8.10;

import "./Utils.sol";

contract TransferVerifier {
    using Utils for uint256;
    using Utils for Utils.Point;

    Utils.Point[M << 1] gs;
    Utils.Point[M << 1] hs;

    function populate() external {
        for (uint256 i = 0; i < M << 1; i++) {
            gs[i] = Utils.mapInto("g", i);
            hs[i] = Utils.mapInto("h", i);
        }
    }

    struct Locals {
        uint256 v;
        uint256 w;
        uint256 vPow;
        uint256 wPow;
        uint256[n][2][2] f;
        uint256[N][2] r; // each poly is an array of length N. evaluations of prods
        Utils.Point temp;
        Utils.Point CLnR;
        Utils.Point CRnR;
        Utils.Point CR;
        Utils.Point DR;
        Utils.Point yR;
        Utils.Point gR;
        Utils.Point C_XR;
        Utils.Point y_XR;

        uint256 y;
        uint256[M << 1] ys;
        uint256 z;
        uint256[2] zs; // [z^2, z^3]
        uint256[M << 1] twoTimesZSquared;
        uint256 zSum;
        uint256 x;
        uint256 t;
        uint256 k;
        Utils.Point tEval;

        uint256 c;
        Utils.Point A_y;
        Utils.Point A_D;
        Utils.Point A_b;
        Utils.Point A_X;
        Utils.Point A_t;
        Utils.Point gEpoch;
        Utils.Point A_u;

        uint256 o;
        Utils.Point[M << 1] hs; // "overridden" parameters.
        Utils.Point u;
        Utils.Point P;
        uint256[m + 1] challenges;
        uint256[M << 1] s;
    }

    function gSum() private pure returns (Utils.Point memory) {
        return Utils.Point(0x2fa4d012d8b2496ef27316c1447cd8958b034225a0fad7f9e9b944b7de8c5064, 0x0c648fe5b6fbbda8eec3d8ce13a891b005f4228f90638e84041b46a17bff0aae);
    }

    function verify(Utils.Statement calldata statement, Utils.TransferProof calldata proof) external view {
        Locals memory locals;
        locals.v = uint256(keccak256(abi.encode(statement.Y, statement.CLn, statement.CRn, statement.C, statement.D, statement.epoch, proof.BA, proof.BS, proof.A, proof.B))).mod();
        locals.w = uint256(keccak256(abi.encode(locals.v, proof.CLnG, proof.CRnG, proof.C_0G, proof.DG, proof.y_0G, proof.gG, proof.C_XG, proof.y_XG))).mod();
        for (uint256 row = 0; row < 2; row++) {
            for (uint256 k = 0; k < n; k++) {
                locals.f[row][1][k] = proof.f[row][k];
                locals.f[row][0][k] = locals.w.sub(proof.f[row][k]);
                locals.temp = locals.temp.add(gs[k + n * row].mul(locals.f[row][1][k]));
                locals.temp = locals.temp.add(hs[k + n * row].mul(locals.f[row][1][k].mul(locals.f[row][0][k])));
            }
        }

        locals.temp = locals.temp.add(hs[2 * n].mul(locals.f[0][1][0].mul(locals.f[1][1][0])).add(hs[2 * n + 1].mul(locals.f[0][0][0].mul(locals.f[1][0][0]))));
        require(proof.B.mul(locals.w).add(proof.A).eq(locals.temp.add(Utils.h().mul(proof.z_A))), "Recovery failure for B^w * A.");

        locals.r[0] = Utils.assemblePolynomials(locals.f[0]);
        locals.r[1] = Utils.assemblePolynomials(locals.f[1]);
        locals.wPow = 1;
        for (uint256 k = 0; k < n; k++) {
            uint256 wNeg = locals.wPow.neg();
            locals.CLnR = locals.CLnR.add(proof.CLnG[k].mul(wNeg));
            locals.CRnR = locals.CRnR.add(proof.CRnG[k].mul(wNeg));
            locals.CR = locals.CR.add(proof.C_0G[k].mul(wNeg));
            locals.DR = locals.DR.add(proof.DG[k].mul(wNeg));
            locals.yR = locals.yR.add(proof.y_0G[k].mul(wNeg));
            locals.gR = locals.gR.add(proof.gG[k].mul(wNeg));
            locals.C_XR = locals.C_XR.add(proof.C_XG[k].mul(wNeg));
            locals.y_XR = locals.y_XR.add(proof.y_XG[k].mul(wNeg));

            locals.wPow = locals.wPow.mul(locals.w);
        }
        locals.vPow = locals.v;
        for (uint256 i = 0; i < N; i++) {
            locals.CLnR = locals.CLnR.add(statement.CLn[i].mul(locals.r[0][i]));
            locals.CRnR = locals.CRnR.add(statement.CRn[i].mul(locals.r[0][i]));
            locals.CR = locals.CR.add(statement.C[i].mul(locals.r[0][i]));
            locals.yR = locals.yR.add(statement.Y[i].mul(locals.r[0][i]));
            uint256 multiplier = locals.r[0][i].add(locals.r[1][i]);
            multiplier = multiplier.add(locals.vPow.mul(locals.wPow.sub(multiplier)));
            locals.C_XR = locals.C_XR.add(statement.C[i].mul(multiplier));
            locals.y_XR = locals.y_XR.add(statement.Y[i].mul(multiplier));

            locals.vPow = locals.vPow.mul(locals.v); // used to do this only if (i > 0)
        }
        locals.DR = locals.DR.add(statement.D.mul(locals.wPow));
        locals.gR = locals.gR.add(Utils.g().mul(locals.wPow));
        locals.C_XR = locals.C_XR.add(Utils.g().mul(statement.fee.mul(locals.wPow))); // this line is new

        locals.y = uint256(keccak256(abi.encode(locals.w))).mod();
        locals.ys[0] = 1;
        locals.k = 1;
        for (uint256 i = 1; i < M << 1; i++) {
            locals.ys[i] = locals.ys[i - 1].mul(locals.y);
            locals.k = locals.k.add(locals.ys[i]);
        }
        locals.z = uint256(keccak256(abi.encode(locals.y))).mod();
        locals.zs[0] = locals.z.mul(locals.z);
        locals.zs[1] = locals.zs[0].mul(locals.z);
        locals.zSum = locals.zs[0].add(locals.zs[1]).mul(locals.z);
        locals.k = locals.k.mul(locals.z.sub(locals.zs[0])).sub(locals.zSum.mul(1 << M).sub(locals.zSum));
        locals.t = proof.tHat.sub(locals.k); // t = tHat - delta(y, z)
        for (uint256 i = 0; i < M; i++) {
            locals.twoTimesZSquared[i] = locals.zs[0].mul(1 << i);
            locals.twoTimesZSquared[i + M] = locals.zs[1].mul(1 << i);
        }

        locals.x = uint256(keccak256(abi.encode(locals.z, proof.T_1, proof.T_2))).mod();
        locals.tEval = proof.T_1.mul(locals.x).add(proof.T_2.mul(locals.x.mul(locals.x))); // replace with "commit"?

        locals.A_y = locals.gR.mul(proof.s_sk).add(locals.yR.mul(proof.c.neg()));
        locals.A_D = Utils.g().mul(proof.s_r).add(statement.D.mul(proof.c.neg())); // add(mul(locals.gR, proof.s_r), mul(locals.DR, proof.c.neg()));
        locals.A_b = Utils.g().mul(proof.s_b).add(locals.DR.mul(locals.zs[0].neg()).add(locals.CRnR.mul(locals.zs[1])).mul(proof.s_sk).add(locals.CR.add(Utils.g().mul(statement.fee.mul(locals.wPow))).mul(locals.zs[0].neg()).add(locals.CLnR.mul(locals.zs[1])).mul(proof.c.neg())));
        locals.A_X = locals.y_XR.mul(proof.s_r).add(locals.C_XR.mul(proof.c.neg()));
        locals.A_t = Utils.g().mul(locals.t).add(locals.tEval.neg()).mul(proof.c.mul(locals.wPow)).add(Utils.h().mul(proof.s_tau)).add(Utils.g().mul(proof.s_b.neg()));
        locals.gEpoch = Utils.mapInto("Firn Epoch", statement.epoch); // TODO: cast my own address to string as well?
        locals.A_u = locals.gEpoch.mul(proof.s_sk).add(statement.u.mul(proof.c.neg()));

        locals.c = uint256(keccak256(abi.encode(locals.x, locals.A_y, locals.A_D, locals.A_b, locals.A_X, locals.A_t, locals.A_u))).mod();
        require(locals.c == proof.c, "Sigma protocol challenge equality failure.");

        locals.o = uint256(keccak256(abi.encode(locals.c))).mod();
        locals.u = Utils.h().mul(locals.o);
        locals.P = proof.BA.add(proof.BS.mul(locals.x)).add(gSum().mul(locals.z.neg())).add(Utils.h().mul(proof.mu.neg())).add(locals.u.mul(proof.tHat));
        for (uint256 i = 0; i < M << 1; i++) {
            locals.hs[i] = hs[i].mul(locals.ys[i].inv());
            locals.P = locals.P.add(locals.hs[i].mul(locals.ys[i].mul(locals.z).add(locals.twoTimesZSquared[i])));
        }
        for (uint256 i = 0; i < m + 1; i++) {
            locals.o = uint256(keccak256(abi.encode(locals.o, proof.L[i], proof.R[i]))).mod(); // overwrites
            locals.challenges[i] = locals.o;
            uint256 inverse = locals.o.inv();
            locals.P = locals.P.add(proof.L[i].mul(locals.o.mul(locals.o))).add(proof.R[i].mul(inverse.mul(inverse)));
        }

        locals.s[0] = 1;
        // credit to https://github.com/leanderdulac/BulletProofLib/blob/master/truffle/contracts/EfficientInnerProductVerifier.sol for the below block.
        // it is an unusual and clever variant of what we already do in Utils.sol:235-236, but with the special property that it requires only 1 inversion.
        // indeed, that algorithm computes the same function as this, yet its use here would require log(M) modular inversions. inversions are expensive.
        // of course in that case don't have to invert, but rather to do x minus, etc., so in that case we might as well just use the simpler algorithm.
        for (uint256 i = 0; i < m + 1; i++) locals.s[0] = locals.s[0].mul(locals.challenges[i]);
        locals.s[0] = locals.s[0].inv(); // here.
        bool[M << 1] memory set;
        for (uint256 i = 0; i < M; i++) {
            for (uint256 j = 0; (1 << j) + i < M << 1; j++) {
                uint256 k = i + (1 << j);
                if (!set[k]) {
                    locals.s[k] = locals.s[i].mul(locals.challenges[m - j]).mul(locals.challenges[m - j]);
                    set[k] = true;
                }
            }
        }
        Utils.Point memory temp = locals.u.mul(proof.a.mul(proof.b));
        for (uint256 i = 0; i < M << 1; i++) {
            temp = temp.add(gs[i].mul(locals.s[i].mul(proof.a)));
            temp = temp.add(locals.hs[i].mul(locals.s[(M << 1) - 1 - i].mul(proof.b)));
        }
        require(temp.eq(locals.P), "Inner product proof verification failed.");
    }
}