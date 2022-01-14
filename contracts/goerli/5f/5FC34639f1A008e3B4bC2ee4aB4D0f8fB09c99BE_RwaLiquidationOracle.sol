/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// hevm: flattened sources of src/RwaLiquidationOracle.sol
// SPDX-License-Identifier: GNU-3 AND AGPL-3.0-or-later AND GPL-3.0-or-later
pragma solidity =0.6.12 >0.4.13 >=0.4.23 >=0.5.12;

////// lib/ds-math/src/math.sol
/// math.sol -- mixin for inline numerical wizardry

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

/* pragma solidity >0.4.13; */

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

////// lib/ds-token/lib/ds-auth/src/auth.sol
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

/* pragma solidity >=0.4.23; */

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

////// lib/ds-value/lib/ds-thing/lib/ds-note/src/note.sol
/// note.sol -- the `note' modifier, for logging calls as events

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

/* pragma solidity >=0.4.23; */

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

////// lib/ds-value/lib/ds-thing/src/thing.sol
// thing.sol - `auth` with handy mixins. your things should be DSThings

// Copyright (C) 2017  DappHub, LLC

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

/* pragma solidity >=0.4.23; */

/* import 'ds-auth/auth.sol'; */
/* import 'ds-note/note.sol'; */
/* import 'ds-math/math.sol'; */

contract DSThing is DSAuth, DSNote, DSMath {
    function S(string memory s) internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked(s)));
    }

}

////// lib/ds-value/src/value.sol
/// value.sol - a value is a simple thing, it can be get and set

// Copyright (C) 2017  DappHub, LLC

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

/* pragma solidity >=0.4.23; */

/* import 'ds-thing/thing.sol'; */

contract DSValue is DSThing {
    bool    has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val,has);
    }
    function read() public view returns (bytes32) {
        bytes32 wut; bool haz;
        (wut, haz) = peek();
        require(haz, "haz-not");
        return wut;
    }
    function poke(bytes32 wut) public note auth {
        val = wut;
        has = true;
    }
    function void() public note auth {  // unset the value
        has = false;
    }
}

////// lib/dss-interfaces/src/dss/VatAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}

////// src/RwaLiquidationOracle.sol
/*//////////////////////////////////////////////////////////////
//                          WARNING                           //
//                                                            //
// This is NOT the contract currently being used on the live  //
// system. To get the implementation currently in use, check  //
// https://changelog.makerdao.com/ and look for               //
// `MIP21_LIQUIDATION_ORACLE`                                 //
//////////////////////////////////////////////////////////////*/

/* pragma solidity 0.6.12; */

/* import {VatAbstract} from "dss-interfaces/dss/VatAbstract.sol"; */
/* import {DSValue} from "ds-value/value.sol"; */

/**
 * @title An extension/subset of `DSMath` containing only the methods required in this file.
 */
library DSMathCustom_1 {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "DSMath/add-overflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "DSMath/mul-overflow");
    }
}

/**
 * @title An Oracle for liquitation of real-world assets (RWA).
 * @dev One instance of contract can be used for many RWA collateral types.
 */
contract RwaLiquidationOracle {
    struct Ilk {
        string doc; // hash of borrower's agrrement with MakerDAO.
        address pip; // DSValue tracking nominal loan value.
        uint48 tau; // remediation period.
        uint48 toc; // timestamp when liquidation was initiated.
    }

    /// @notice Dai Core module address.
    VatAbstract public immutable vat;
    /// @notice Module that handles system debt and surplus.
    address public vow;

    /// @notice All collateral types supported by this oracle. `ilks[ilk]`
    mapping(bytes32 => Ilk) public ilks;
    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;

    /**
     * @notice `usr` was granted admin access.
     * @param usr The user address.
     */
    event Rely(address indexed usr);
    /**
     * @notice `usr` admin access was revoked.
     * @param usr The user address.
     */
    event Deny(address indexed usr);
    /**
     * @notice A contract parameter was updated.
     * @param what The changed parameter name. Currently the only supported value is "vow".
     * @param data The new value of the parameter.
     */
    event File(bytes32 indexed what, address data);
    /**
     * @notice A new collateral `ilk` was added.
     * @param ilk The name of the collateral.
     * @param val The initial value for the price feed.
     * @param doc The hash to the off-chain agreement for the ilk.
     * @param tau The amount of time the ilk can remain in liquidation before being written-off.
     */
    event Init(bytes32 indexed ilk, uint256 val, string doc, uint48 tau);
    /**
     * @notice The value of the collateral `ilk` was updated.
     * @param ilk The name of the collateral.
     * @param val The new value.
     */
    event Bump(bytes32 indexed ilk, uint256 val);
    /**
     * @notice The liquidation process for collateral `ilk` was started.
     * @param ilk The name of the collateral.
     */
    event Tell(bytes32 indexed ilk);
    /**
     * @notice The liquidation process for collateral `ilk` was stopped before the write-off.
     * @param ilk The name of the collateral.
     */
    event Cure(bytes32 indexed ilk);
    /**
     * @notice A `urn` outstanding debt for collateral `ilk` was written-off.
     * @param ilk The name of the collateral.
     * @param urn The address of the urn.
     */
    event Cull(bytes32 indexed ilk, address indexed urn);

    /**
     * @param vat_ The Dai core module address.
     * @param vow_ The address of module that handles system debt and surplus.
     */
    constructor(address vat_, address vow_) public {
        vat = VatAbstract(vat_);
        vow = vow_;
        wards[msg.sender] = 1;

        emit Rely(msg.sender);
        emit File("vow", vow_);
    }

    /*//////////////////////////////////
               Authorization
    //////////////////////////////////*/

    /**
     * @notice Grants `usr` admin access to this contract.
     * @param usr The user address.
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract.
     * @param usr The user address.
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaOracle/not-authorized");
        _;
    }

    /*//////////////////////////////////
               Administration
    //////////////////////////////////*/

    /**
     * @notice Updates a contract parameter.
     * @param what The changed parameter name. Currently the only supported value is "vow".
     * @param data The new value of the parameter.
     */
    function file(bytes32 what, address data) external auth {
        if (what == "vow") {
            vow = data;
        } else {
            revert("RwaOracle/unrecognised-param");
        }

        emit File(what, data);
    }

    /**
     * @notice Initializes a new collateral type `ilk`.
     * @param ilk The name of the collateral type.
     * @param val The initial value for the price feed.
     * @param doc The hash to the off-chain agreement for the ilk.
     * @param tau The amount of time the ilk can remain in liquidation before being written-off.
     */
    function init(
        bytes32 ilk,
        uint256 val,
        string calldata doc,
        uint48 tau
    ) external auth {
        // doc, and tau can be amended, but tau cannot decrease
        require(tau >= ilks[ilk].tau, "RwaOracle/decreasing-tau");
        ilks[ilk].doc = doc;
        ilks[ilk].tau = tau;

        if (ilks[ilk].pip == address(0)) {
            DSValue pip = new DSValue();
            ilks[ilk].pip = address(pip);
            pip.poke(bytes32(val));
        } else {
            val = uint256(DSValue(ilks[ilk].pip).read());
        }

        emit Init(ilk, val, doc, tau);
    }

    /*//////////////////////////////////
                 Operations
    //////////////////////////////////*/

    /**
     * @notice Performs valuation adjustment for a given ilk.
     * @param ilk The ilk to adjust.
     * @param val The new value.
     */
    function bump(bytes32 ilk, uint256 val) external auth {
        DSValue pip = DSValue(ilks[ilk].pip);
        require(address(pip) != address(0), "RwaOracle/unknown-ilk");
        require(ilks[ilk].toc == 0, "RwaOracle/in-remediation");

        require(val >= uint256(pip.read()), "RwaOracle/decreasing-val");
        pip.poke(bytes32(val));

        emit Bump(ilk, val);
    }

    /**
     * @notice Enables liquidation for a given ilk.
     * @param ilk The ilk being liquidated.
     */
    function tell(bytes32 ilk) external auth {
        require(ilks[ilk].pip != address(0), "RwaOracle/unknown-ilk");

        (, , , uint256 line, ) = vat.ilks(ilk);
        require(line == 0, "RwaOracle/nonzero-line");

        ilks[ilk].toc = uint48(block.timestamp);

        emit Tell(ilk);
    }

    /**
     * @notice Remediation: stops the liquidation process for a given ilk.
     * @param ilk The ilk being remediated.
     */
    function cure(bytes32 ilk) external auth {
        require(ilks[ilk].pip != address(0), "RwaOracle/unknown-ilk");
        require(ilks[ilk].toc > 0, "RwaOracle/not-in-liquidation");

        ilks[ilk].toc = 0;

        emit Cure(ilk);
    }

    /**
     * @notice Writes-off a specific urn for a given ilk.
     * @dev It assigns the outstanding debt of the urn to the vow.
     * @param ilk The ilk being liquidated.
     * @param urn The urn being written-off.
     */
    function cull(bytes32 ilk, address urn) external auth {
        require(ilks[ilk].pip != address(0), "RwaOracle/unknown-ilk");
        require(block.timestamp >= DSMathCustom_1.add(ilks[ilk].toc, ilks[ilk].tau), "RwaOracle/early-cull");

        DSValue(ilks[ilk].pip).poke(bytes32(0));

        (uint256 ink, uint256 art) = vat.urns(ilk, urn);

        vat.grab(ilk, urn, address(this), vow, -int256(ink), -int256(art));

        emit Cull(ilk, urn);
    }

    /**
     * @notice Allows off-chain parties to check the state of the loan.
     * @param ilk the Ilk.
     */
    function good(bytes32 ilk) external view returns (bool) {
        require(ilks[ilk].pip != address(0), "RwaOracle/unknown-ilk");

        return (ilks[ilk].toc == 0 || block.timestamp < DSMathCustom_1.add(ilks[ilk].toc, ilks[ilk].tau));
    }
}