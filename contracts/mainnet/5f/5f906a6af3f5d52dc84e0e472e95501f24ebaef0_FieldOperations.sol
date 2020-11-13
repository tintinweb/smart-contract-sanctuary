// SPDX-License-Identifier: AGPL-3.0-only

/*
    FieldOperations.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs

    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;

import "./SafeMath.sol";

import "./Precompiled.sol";


library Fp2Operations {
    using SafeMath for uint;

    struct Fp2Point {
        uint a;
        uint b;
    }

    uint constant public P = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    function addFp2(Fp2Point memory value1, Fp2Point memory value2) internal pure returns (Fp2Point memory) {
        return Fp2Point({ a: addmod(value1.a, value2.a, P), b: addmod(value1.b, value2.b, P) });
    }

    function scalarMulFp2(Fp2Point memory value, uint scalar) internal pure returns (Fp2Point memory) {
        return Fp2Point({ a: mulmod(scalar, value.a, P), b: mulmod(scalar, value.b, P) });
    }

    function minusFp2(Fp2Point memory diminished, Fp2Point memory subtracted) internal pure
        returns (Fp2Point memory difference)
    {
        uint p = P;
        if (diminished.a >= subtracted.a) {
            difference.a = addmod(diminished.a, p - (subtracted.a), p);
        } else {
            difference.a = p - (addmod(subtracted.a, p - (diminished.a), p));
        }
        if (diminished.b >= subtracted.b) {
            difference.b = addmod(diminished.b, p - (subtracted.b), p);
        } else {
            difference.b = p - (addmod(subtracted.b, p - (diminished.b), p));
        }
    }

    function mulFp2(
        Fp2Point memory value1,
        Fp2Point memory value2
    )
        internal
        pure
        returns (Fp2Point memory result)
    {
        uint p = P;
        Fp2Point memory point = Fp2Point({
            a: mulmod(value1.a, value2.a, p),
            b: mulmod(value1.b, value2.b, p)});
        result.a = addmod(
            point.a,
            mulmod(p - 1, point.b, p),
            p);
        result.b = addmod(
            mulmod(
                addmod(value1.a, value1.b, p),
                addmod(value2.a, value2.b, p),
                p),
            p - addmod(point.a, point.b, p),
            p);
    }

    function squaredFp2(Fp2Point memory value) internal pure returns (Fp2Point memory) {
        uint p = P;
        uint ab = mulmod(value.a, value.b, p);
        uint mult = mulmod(addmod(value.a, value.b, p), addmod(value.a, mulmod(p - 1, value.b, p), p), p);
        return Fp2Point({ a: mult, b: addmod(ab, ab, p) });
    }

    function inverseFp2(Fp2Point memory value) internal view returns (Fp2Point memory result) {
        uint p = P;
        uint t0 = mulmod(value.a, value.a, p);
        uint t1 = mulmod(value.b, value.b, p);
        uint t2 = mulmod(p - 1, t1, p);
        if (t0 >= t2) {
            t2 = addmod(t0, p - t2, p);
        } else {
            t2 = p - addmod(t2, p - t0, p);
        }
        uint t3 = Precompiled.bigModExp(t2, p - 2, p);
        result.a = mulmod(value.a, t3, p);
        result.b = p - mulmod(value.b, t3, p);
    }

    function isEqual(
        Fp2Point memory value1,
        Fp2Point memory value2
    )
        internal
        pure
        returns (bool)
    {
        return value1.a == value2.a && value1.b == value2.b;
    }
}


library G2Operations {
    using SafeMath for uint;
    using Fp2Operations for Fp2Operations.Fp2Point;

    struct G2Point {
        Fp2Operations.Fp2Point x;
        Fp2Operations.Fp2Point y;
    }

    function getTWISTB() internal pure returns (Fp2Operations.Fp2Point memory) {
        // Current solidity version does not support Constants of non-value type
        // so we implemented this function
        return Fp2Operations.Fp2Point({
            a: 19485874751759354771024239261021720505790618469301721065564631296452457478373,
            b: 266929791119991161246907387137283842545076965332900288569378510910307636690
        });
    }

    function getG2() internal pure returns (G2Point memory) {
        // Current solidity version does not support Constants of non-value type
        // so we implemented this function
        return G2Point({
            x: Fp2Operations.Fp2Point({
                a: 10857046999023057135944570762232829481370756359578518086990519993285655852781,
                b: 11559732032986387107991004021392285783925812861821192530917403151452391805634
            }),
            y: Fp2Operations.Fp2Point({
                a: 8495653923123431417604973247489272438418190587263600148770280649306958101930,
                b: 4082367875863433681332203403145435568316851327593401208105741076214120093531
            })
        });
    }

    function getG1() internal pure returns (Fp2Operations.Fp2Point memory) {
        // Current solidity version does not support Constants of non-value type
        // so we implemented this function
        return Fp2Operations.Fp2Point({
            a: 1,
            b: 2
        });
    }

    function getG2Zero() internal pure returns (G2Point memory) {
        // Current solidity version does not support Constants of non-value type
        // so we implemented this function
        return G2Point({
            x: Fp2Operations.Fp2Point({
                a: 0,
                b: 0
            }),
            y: Fp2Operations.Fp2Point({
                a: 1,
                b: 0
            })
        });
    }

    function isG1Point(uint x, uint y) internal pure returns (bool) {
        uint p = Fp2Operations.P;
        return mulmod(y, y, p) == 
            addmod(mulmod(mulmod(x, x, p), x, p), 3, p);
    }
    function isG1(Fp2Operations.Fp2Point memory point) internal pure returns (bool) {
        return isG1Point(point.a, point.b);
    }

    function isG2Point(Fp2Operations.Fp2Point memory x, Fp2Operations.Fp2Point memory y) internal pure returns (bool) {
        if (isG2ZeroPoint(x, y)) {
            return true;
        }
        Fp2Operations.Fp2Point memory squaredY = y.squaredFp2();
        Fp2Operations.Fp2Point memory res = squaredY.minusFp2(
                x.squaredFp2().mulFp2(x)
            ).minusFp2(getTWISTB());
        return res.a == 0 && res.b == 0;
    }

    function isG2(G2Point memory value) internal pure returns (bool) {
        return isG2Point(value.x, value.y);
    }

    function isG2ZeroPoint(
        Fp2Operations.Fp2Point memory x,
        Fp2Operations.Fp2Point memory y
    )
        internal
        pure
        returns (bool)
    {
        return x.a == 0 && x.b == 0 && y.a == 1 && y.b == 0;
    }

    function isG2Zero(G2Point memory value) internal pure returns (bool) {
        return value.x.a == 0 && value.x.b == 0 && value.y.a == 1 && value.y.b == 0;
        // return isG2ZeroPoint(value.x, value.y);
    }

    function addG2(
        G2Point memory value1,
        G2Point memory value2
    )
        internal
        view
        returns (G2Point memory sum)
    {
        if (isG2Zero(value1)) {
            return value2;
        }
        if (isG2Zero(value2)) {
            return value1;
        }
        if (isEqual(value1, value2)) {
            return doubleG2(value1);
        }

        Fp2Operations.Fp2Point memory s = value2.y.minusFp2(value1.y).mulFp2(value2.x.minusFp2(value1.x).inverseFp2());
        sum.x = s.squaredFp2().minusFp2(value1.x.addFp2(value2.x));
        sum.y = value1.y.addFp2(s.mulFp2(sum.x.minusFp2(value1.x)));
        uint p = Fp2Operations.P;
        sum.y.a = p - sum.y.a;
        sum.y.b = p - sum.y.b;
    }

    function isEqual(
        G2Point memory value1,
        G2Point memory value2
    )
        internal
        pure
        returns (bool)
    {
        return value1.x.isEqual(value2.x) && value1.y.isEqual(value2.y);
    }

    function doubleG2(G2Point memory value)
        internal
        view
        returns (G2Point memory result)
    {
        if (isG2Zero(value)) {
            return value;
        } else {
            Fp2Operations.Fp2Point memory s =
                value.x.squaredFp2().scalarMulFp2(3).mulFp2(value.y.scalarMulFp2(2).inverseFp2());
            result.x = s.squaredFp2().minusFp2(value.x.addFp2(value.x));
            result.y = value.y.addFp2(s.mulFp2(result.x.minusFp2(value.x)));
            uint p = Fp2Operations.P;
            result.y.a = p - result.y.a;
            result.y.b = p - result.y.b;
        }
    }
}