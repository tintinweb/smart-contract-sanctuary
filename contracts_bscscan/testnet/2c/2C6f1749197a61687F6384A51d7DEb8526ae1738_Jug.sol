/**
 *Submitted for verification at Etherscan.io on 2019-11-09
*/

// hevm: flattened sources of /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/jug.sol
pragma solidity =0.5.12;

////// /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/lib.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity 0.5.12; */

contract LibNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
        // log an 'anonymous' event with a constant 6 words of calldata
        // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize                         // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
            shl(224, shr(224, calldataload(0))), // msg.sig
            caller,                              // msg.sender
            calldataload(4),                     // arg1
            calldataload(36)                     // arg2
            )
        }
    }
}

////// /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/jug.sol
/* pragma solidity 0.5.12; */

/* import "./lib.sol"; */

contract VatLike {
    function ilks(bytes32) external returns (
        uint256 Art,   // wad
        uint256 rate   // ray
    );
    function fold(bytes32,address,int) external;
}

contract Jug is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Jug/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        uint256 duty;
        uint256  rho;
    }

    mapping (bytes32 => Ilk) public ilks;
    VatLike                  public vat;
    address                  public vow;
    uint256                  public base;

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
    }

    // --- Math ---
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := b} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := b } default { z := x }
                let half := div(b, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, b)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, b)
                }
            }
            }
        }
    }
    uint256 constant ONE = 10 ** 27;
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function diff(uint x, uint y) internal pure returns (int z) {
        z = int(x) - int(y);
        require(int(x) >= 0 && int(y) >= 0);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / ONE;
    }

    // --- Administration ---
    function init(bytes32 ilk) external note auth {
        Ilk storage i = ilks[ilk];
        require(i.duty == 0, "Jug/ilk-already-init");
        i.duty = ONE;
        i.rho  = now;
    }
    function file(bytes32 ilk, bytes32 what, uint data) external note auth {
        require(now == ilks[ilk].rho, "Jug/rho-not-updated");
        if (what == "duty") ilks[ilk].duty = data;
        else revert("Jug/file-unrecognized-param");
    }
    function file(bytes32 what, uint data) external note auth {
        if (what == "base") base = data;
        else revert("Jug/file-unrecognized-param");
    }
    function file(bytes32 what, address data) external note auth {
        if (what == "vow") vow = data;
        else revert("Jug/file-unrecognized-param");
    }

    // --- Stability Fee Collection ---
    function drip(bytes32 ilk) external note returns (uint rate) {
        require(now >= ilks[ilk].rho, "Jug/invalid-now");
        (, uint prev) = vat.ilks(ilk);
        rate = rmul(rpow(add(base, ilks[ilk].duty), now - ilks[ilk].rho, ONE), prev);
        vat.fold(ilk, vow, diff(rate, prev));
        ilks[ilk].rho = now;
    }
}