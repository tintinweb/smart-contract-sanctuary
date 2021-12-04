pragma solidity 0.8.10;

import "./PedersenBase.sol";
import "./Utils.sol";

contract WithdrawalVerifier {
    using Utils for uint256;
    using Utils for Utils.Point;

    PedersenBase immutable base;

    constructor(address _base) {
        base = PedersenBase(_base);
    }

    function gs(uint256 i) internal view returns (Utils.Point memory) {
        (bytes32 x, bytes32 y) = base.gs(i);
        return Utils.Point(x, y);
    }

    function hs(uint256 i) internal view returns (Utils.Point memory) {
        (bytes32 x, bytes32 y) = base.hs(i);
        return Utils.Point(x, y);
    }

    struct Locals {
        uint256 v;
        uint256 w;
        uint256 vPow;
        uint256 wPow;
        uint256[n][2] f; // could just allocate extra space in the proof?
        uint256[N] r; // each poly is an array of length N. evaluations of prods
        Utils.Point temp;
        Utils.Point CLnR;
        Utils.Point CRnR;
        Utils.Point yR;
        Utils.Point gR;
        Utils.Point C_XR;
        Utils.Point y_XR;

        uint256 y;
        uint256[M] ys;
        uint256 z;
        uint256[1] zs; // silly. just to match zether.
        uint256[M] twoTimesZSquared;
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
        Utils.Point[M] hs; // "overridden" parameters.
        Utils.Point u;
        Utils.Point P;
        uint256[m] challenges;
        uint256[M] s;
    }

    function gSum() private pure returns (Utils.Point memory) {
        return Utils.Point(0x1bcf9024624aef47656cdbd47d104a1b30efac20504e72d395e7e012727c73a3, 0x052d5b8798a0be8c27d47246f021c2e9841837904a92a33dc4f6c755fda097bd);
    }

    function verify(address recipient, uint256 amount, Utils.Statement calldata statement, Utils.WithdrawalProof calldata proof) external view {
        Locals memory locals;
        locals.v = uint256(keccak256(abi.encode(amount, statement.Y, statement.CLn, statement.CRn, statement.C, statement.D, statement.epoch, proof.BA, proof.BS, proof.A, proof.B))).mod();
        locals.w = uint256(keccak256(abi.encode(locals.v, proof.CLnG, proof.CRnG, proof.y_0G, proof.gG, proof.C_XG, proof.y_XG))).mod();
        for (uint256 k = 0; k < n; k++) {
            locals.f[1][k] = proof.f[k];
            locals.f[0][k] = locals.w.sub(proof.f[k]);
        }
        for (uint256 k = 0; k < n; k++) {
            locals.temp = locals.temp.add(gs(k).mul(locals.f[1][k]));
            locals.temp = locals.temp.add(hs(k).mul(locals.f[1][k].mul(locals.f[0][k])));
        }
        require(proof.B.mul(locals.w).add(proof.A).eq(locals.temp.add(Utils.h().mul(proof.z_A))), "Recovery failure for B^w * A.");

        locals.r = Utils.assemblePolynomials(locals.f);
        locals.wPow = 1;
        for (uint256 k = 0; k < n; k++) {
            locals.CLnR = locals.CLnR.add(proof.CLnG[k].mul(locals.wPow.neg()));
            locals.CRnR = locals.CRnR.add(proof.CRnG[k].mul(locals.wPow.neg()));
            locals.yR = locals.yR.add(proof.y_0G[k].mul(locals.wPow.neg()));
            locals.gR = locals.gR.add(proof.gG[k].mul(locals.wPow.neg()));
            locals.C_XR = locals.C_XR.add(proof.C_XG[k].mul(locals.wPow.neg()));
            locals.y_XR = locals.y_XR.add(proof.y_XG[k].mul(locals.wPow.neg()));

            locals.wPow = locals.wPow.mul(locals.w);
        }
        locals.vPow = locals.v; // used to be 1
        for (uint256 i = 0; i < N; i++) {
            locals.CLnR = locals.CLnR.add(statement.CLn[i].mul(locals.r[i]));
            locals.CRnR = locals.CRnR.add(statement.CRn[i].mul(locals.r[i]));
            locals.yR = locals.yR.add(statement.Y[i].mul(locals.r[i]));
            uint256 multiplier = locals.r[i].add(locals.vPow.mul(locals.wPow.sub(locals.r[i]))); // locals. ?
            locals.C_XR = locals.C_XR.add(statement.C[i].mul(multiplier));
            locals.y_XR = locals.y_XR.add(statement.Y[i].mul(multiplier));
            locals.vPow = locals.vPow.mul(locals.v); // used to do this only if (i > 0)
        }
        locals.gR = locals.gR.add(Utils.g().mul(locals.wPow));
        locals.C_XR = locals.C_XR.add(Utils.g().mul(statement.fee.add(amount).mul(locals.wPow))); // this line is new

        locals.y = uint256(keccak256(abi.encode(locals.w))).mod();
        locals.ys[0] = 1;
        locals.k = 1;
        for (uint256 i = 1; i < M; i++) {
            locals.ys[i] = locals.ys[i - 1].mul(locals.y);
            locals.k = locals.k.add(locals.ys[i]);
        }
        locals.z = uint256(keccak256(abi.encode(locals.y))).mod();
        locals.zs[0] = locals.z.mul(locals.z);
        locals.zSum = locals.zs[0].mul(locals.z); // trivial sum
        locals.k = locals.k.mul(locals.z.sub(locals.zs[0])).sub(locals.zSum.mul(1 << M).sub(locals.zSum));
        locals.t = proof.tHat.sub(locals.k);
        for (uint256 i = 0; i < M; i++) {
            locals.twoTimesZSquared[i] = locals.zs[0].mul(1 << i);
        }

        locals.x = uint256(keccak256(abi.encode(locals.z, proof.T_1, proof.T_2))).mod();
        locals.tEval = proof.T_1.mul(locals.x).add(proof.T_2.mul(locals.x.mul(locals.x))); // replace with "commit"?

        locals.A_y = locals.gR.mul(proof.s_sk).add(locals.yR.mul(proof.c.neg()));
        locals.A_D = Utils.g().mul(proof.s_r).add(statement.D.mul(proof.c.neg())); // add(mul(locals.gR, proof.s_r), mul(locals.DR, proof.c.neg()));
        locals.A_b = Utils.g().mul(proof.s_b).add(locals.CRnR.mul(locals.zs[0]).mul(proof.s_sk).add(locals.CLnR.mul(locals.zs[0]).mul(proof.c.neg())));
        locals.A_X = locals.y_XR.mul(proof.s_r).add(locals.C_XR.mul(proof.c.neg()));
        locals.A_t = Utils.g().mul(locals.t).add(locals.tEval.neg()).mul(proof.c.mul(locals.wPow)).add(Utils.h().mul(proof.s_tau)).add(Utils.g().mul(proof.s_b.neg()));
        locals.gEpoch = Utils.mapInto("Firn Epoch", statement.epoch); // TODO: cast my own address to string as well?
        locals.A_u = locals.gEpoch.mul(proof.s_sk).add(statement.u.mul(proof.c.neg()));

        locals.c = uint256(keccak256(abi.encode(recipient, locals.x, locals.A_y, locals.A_D, locals.A_b, locals.A_X, locals.A_t, locals.A_u))).mod();
        require(locals.c == proof.c, "Sigma protocol failure.");

        locals.o = uint256(keccak256(abi.encode(locals.c))).mod();

        locals.u = Utils.h().mul(locals.o);
        locals.P = proof.BA.add(proof.BS.mul(locals.x)).add(gSum().mul(locals.z.neg())).add(Utils.h().mul(proof.mu.neg())).add(locals.u.mul(proof.tHat));
        for (uint256 i = 0; i < M; i++) {
            locals.hs[i] = hs(i).mul(locals.ys[i].inv());
            locals.P = locals.P.add(locals.hs[i].mul(locals.ys[i].mul(locals.z).add(locals.twoTimesZSquared[i])));
        }

        for (uint256 i = 0; i < m; i++) {
            locals.o = uint256(keccak256(abi.encode(locals.o, proof.L[i], proof.R[i]))).mod(); // overwrites
            locals.challenges[i] = locals.o;
            uint256 inverse = locals.o.inv();
            locals.P = locals.P.add(proof.L[i].mul(locals.o.mul(locals.o)).add(proof.R[i].mul(inverse.mul(inverse))));
        }

        locals.s[0] = 1;
        // credit to https://github.com/leanderdulac/BulletProofLib/blob/master/truffle/contracts/EfficientInnerProductVerifier.sol for the below block.
        for (uint256 i = 0; i < m; i++) locals.s[0] = locals.s[0].mul(locals.challenges[i]);
        locals.s[0] = locals.s[0].inv(); // here.
        bool[M] memory set;
        for (uint256 i = 0; i < M >> 1; i++) {
            for (uint256 j = 0; (1 << j) + i < M; j++) {
                uint256 k = i + (1 << j);
                if (!set[k]) {
                    locals.s[k] = locals.s[i].mul(locals.challenges[m - 1 - j]).mul(locals.challenges[m - 1 - j]);
                    set[k] = true;
                }
            }
        }

        Utils.Point memory temp = locals.u.mul(proof.a.mul(proof.b));
        for (uint256 i = 0; i < M; i++) {
            temp = temp.add(gs(i).mul(locals.s[i].mul(proof.a)));
            temp = temp.add(locals.hs[i].mul(locals.s[M - 1 - i].mul(proof.b)));
        }
        require(temp.eq(locals.P), "Inner product proof failed.");
    }
}