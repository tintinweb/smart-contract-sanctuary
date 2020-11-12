// SPDX-License-Identifier: AGPL-3.0-only

/*
    ECDH.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR _A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;
import "./SafeMath.sol";


contract ECDH {
    using SafeMath for uint256;

    uint256 constant private _GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 constant private _GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 constant private _N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 constant private _A = 0;

    function publicKey(uint256 privKey) external pure returns (uint256 qx, uint256 qy) {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = ecMul(
            privKey,
            _GX,
            _GY,
            1
        );
        z = inverse(z);
        qx = mulmod(x, z, _N);
        qy = mulmod(y, z, _N);
    }

    function deriveKey(
        uint256 privKey,
        uint256 pubX,
        uint256 pubY
    )
        external
        pure
        returns (uint256 qx, uint256 qy)
    {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = ecMul(
            privKey,
            pubX,
            pubY,
            1
        );
        z = inverse(z);
        qx = mulmod(x, z, _N);
        qy = mulmod(y, z, _N);
    }

    function jAdd(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    )
        public
        pure
        returns (uint256 x3, uint256 z3)
    {
        (x3, z3) = (addmod(mulmod(z2, x1, _N), mulmod(x2, z1, _N), _N), mulmod(z1, z2, _N));
    }

    function jSub(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    )
        public
        pure
        returns (uint256 x3, uint256 z3)
    {
        (x3, z3) = (addmod(mulmod(z2, x1, _N), mulmod(_N.sub(x2), z1, _N), _N), mulmod(z1, z2, _N));
    }

    function jMul(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    )
        public
        pure
        returns (uint256 x3, uint256 z3)
    {
        (x3, z3) = (mulmod(x1, x2, _N), mulmod(z1, z2, _N));
    }

    function jDiv(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    )
        public
        pure
        returns (uint256 x3, uint256 z3)
    {
        (x3, z3) = (mulmod(x1, z2, _N), mulmod(z1, x2, _N));
    }

    function inverse(uint256 a) public pure returns (uint256 invA) {
        uint256 t = 0;
        uint256 newT = 1;
        uint256 r = _N;
        uint256 newR = a;
        uint256 q;
        while (newR != 0) {
            q = r.div(newR);
            (t, newT) = (newT, addmod(t, (_N.sub(mulmod(q, newT, _N))), _N));
            (r, newR) = (newR, r % newR);
        }
        return t;
    }

    function ecAdd(
        uint256 x1,
        uint256 y1,
        uint256 z1,
        uint256 x2,
        uint256 y2,
        uint256 z2
    )
        public
        pure
        returns (uint256 x3, uint256 y3, uint256 z3)
    {
        uint256 ln;
        uint256 lz;
        uint256 da;
        uint256 db;

        if ((x1 == 0) && (y1 == 0)) {
            return (x2, y2, z2);
        }

        if ((x2 == 0) && (y2 == 0)) {
            return (x1, y1, z1);
        }

        if ((x1 == x2) && (y1 == y2)) {
            (ln, lz) = jMul(x1, z1, x1, z1);
            (ln, lz) = jMul(ln,lz,3,1);
            (ln, lz) = jAdd(ln,lz,_A,1);
            (da, db) = jMul(y1,z1,2,1);
        } else {
            (ln, lz) = jSub(y2,z2,y1,z1);
            (da, db) = jSub(x2,z2,x1,z1);
        }
        (ln, lz) = jDiv(ln,lz,da,db);

        (x3, da) = jMul(ln,lz,ln,lz);
        (x3, da) = jSub(x3,da,x1,z1);
        (x3, da) = jSub(x3,da,x2,z2);

        (y3, db) = jSub(x1,z1,x3,da);
        (y3, db) = jMul(y3,db,ln,lz);
        (y3, db) = jSub(y3,db,y1,z1);

        if (da != db) {
            x3 = mulmod(x3, db, _N);
            y3 = mulmod(y3, da, _N);
            z3 = mulmod(da, db, _N);
        } else {
            z3 = da;
        }
    }

    function ecDouble(
        uint256 x1,
        uint256 y1,
        uint256 z1
    )
        public
        pure
        returns (uint256 x3, uint256 y3, uint256 z3)
    {
        (x3, y3, z3) = ecAdd(
            x1,
            y1,
            z1,
            x1,
            y1,
            z1
        );
    }

    function ecMul(
        uint256 d,
        uint256 x1,
        uint256 y1,
        uint256 z1
    )
        public
        pure
        returns (uint256 x3, uint256 y3, uint256 z3)
    {
        uint256 remaining = d;
        uint256 px = x1;
        uint256 py = y1;
        uint256 pz = z1;
        uint256 acx = 0;
        uint256 acy = 0;
        uint256 acz = 1;

        if (d == 0) {
            return (0, 0, 1);
        }

        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (acx, acy, acz) = ecAdd(
                    acx,
                    acy,
                    acz,
                    px,
                    py,
                    pz
                );
            }
            remaining = remaining.div(2);
            (px, py, pz) = ecDouble(px, py, pz);
        }

        (x3, y3, z3) = (acx, acy, acz);
    }
}
