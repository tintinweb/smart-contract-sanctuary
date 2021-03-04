/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// Copyright (C) 2020, 2021 Lev Livnev <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

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
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

pragma solidity >=0.4.23;

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

contract DSThing is DSAuth, DSNote, DSMath {
    function S(string memory s) internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked(s)));
    }

}

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

contract RwaLiquidationOracle {
    // --- auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaOracle/not-authorized");
        _;
    }

    // --- math ---
    function add(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    VatAbstract public vat;
    address     public vow;
    struct Ilk {
        string  doc; // hash of borrower's agreement with MakerDAO
        address pip; // DSValue tracking nominal loan value
        uint48  tau; // pre-agreed remediation period
        uint48  toc; // timestamp when liquidation initiated
    }
    mapping (bytes32 => Ilk) public ilks;

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, address data);
    event Init(bytes32 indexed ilk, uint256 val, string doc, uint48 tau);
    event Bump(bytes32 indexed ilk, uint256 val);
    event Tell(bytes32 indexed ilk);
    event Cure(bytes32 indexed ilk);
    event Cull(bytes32 indexed ilk, address indexed urn);

    constructor(address vat_, address vow_) public {
        vat = VatAbstract(vat_);
        vow = vow_;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        emit File("vow", vow_);
    }

    // --- administration ---
    function file(bytes32 what, address data) external auth {
        if (what == "vow") { vow = data; }
        else revert("RwaOracle/unrecognised-param");
        emit File(what, data);
    }

    function init(bytes32 ilk, uint256 val, string calldata doc, uint48 tau) external auth {
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

    // --- valuation adjustment ---
    function bump(bytes32 ilk, uint256 val) external auth {
        DSValue pip = DSValue(ilks[ilk].pip);
        require(address(pip) != address(0), "RwaOracle/unknown-ilk");
        require(ilks[ilk].toc == 0, "RwaOracle/in-remediation");
        // only cull can decrease
        require(val >= uint256(pip.read()), "RwaOracle/decreasing-val");
        pip.poke(bytes32(val));
        emit Bump(ilk, val);
    }
    // --- liquidation ---
    function tell(bytes32 ilk) external auth {
        (,,,uint256 line,) = vat.ilks(ilk);
        // DC must be set to zero first
        require(line == 0, "RwaOracle/nonzero-line");
        require(ilks[ilk].pip != address(0), "RwaOracle/unknown-ilk");
        ilks[ilk].toc = uint48(block.timestamp);
        emit Tell(ilk);
    }
    // --- remediation ---
    function cure(bytes32 ilk) external auth {
        require(ilks[ilk].pip != address(0), "RwaOracle/unknown-ilk");
        require(ilks[ilk].toc > 0, "RwaOracle/not-in-remediation");
        ilks[ilk].toc = 0;
        emit Cure(ilk);
    }
    // --- write-off ---
    function cull(bytes32 ilk, address urn) external auth {
        require(ilks[ilk].pip != address(0), "RwaOracle/unknown-ilk");
        require(block.timestamp >= add(ilks[ilk].toc, ilks[ilk].tau), "RwaOracle/early-cull");

        DSValue(ilks[ilk].pip).poke(bytes32(uint256(0)));

        (uint256 ink, uint256 art) = vat.urns(ilk, urn);
        require(ink <= 2 ** 255, "RwaOracle/overflow");
        require(art <= 2 ** 255, "RwaOracle/overflow");

        vat.grab(ilk,
                 address(urn),
                 address(this),
                 address(vow),
                 -int256(ink),
                 -int256(art));
        emit Cull(ilk, urn);
    }

    // --- liquidation check ---
    // to be called by off-chain parties (e.g. a trustee) to check the standing of the loan
    function good(bytes32 ilk) external view returns (bool) {
        require(ilks[ilk].pip != address(0), "RwaOracle/unknown-ilk");
        // tell not called or still in remediation period
        return (ilks[ilk].toc == 0 || block.timestamp < add(ilks[ilk].toc, ilks[ilk].tau));
    }
}