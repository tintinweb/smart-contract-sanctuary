/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// hevm: flattened sources of src/CharterManager.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12;

////// src/CharterManager.sol
// Copyright (C) 2021 Dai Foundation
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

/* pragma solidity 0.6.12; */

interface VatLike {
    function live() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function fork(bytes32, address, address, int256, int256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function hope(address) external;
    function ilks(bytes32) external view returns (
        uint256 Art,  // [wad]
        uint256 rate, // [ray]
        uint256 spot, // [ray]
        uint256 line, // [rad]
        uint256 dust  // [rad]
    );
}

interface SpotterLike {
    function ilks(bytes32) external returns (address, uint256);
}

interface GemLike {
    function approve(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

interface ManagedGemJoinLike {
    function gem() external view returns (GemLike);
    function ilk() external view returns (bytes32);
    function join(address, uint256) external;
    function exit(address, address, uint256) external;
}

contract UrnProxy {
    address public usr;

    constructor(address vat_, address usr_) public {
        usr = usr_;
        VatLike(vat_).hope(msg.sender);
    }
}

contract CharterManagerImp {
    // --- Proxy Storage ---
    bytes32 slot0; // avoid collision with proxy's implementation field
    mapping (address => uint256) public wards;

    // --- Implementation Storage ---
    mapping (address => address) public proxy; // UrnProxy per user
    mapping (address => mapping (address => uint256))  public can;
    mapping (bytes32 => uint256)                       public gate;  // allow only permissioned vaults
    mapping (bytes32 => uint256)                       public Nib;   // fee percentage for un-permissioned vaults [wad]
    mapping (bytes32 => mapping (address => uint256))  public nib;   // fee percentage for permissioned vaults    [wad]
    mapping (bytes32 => uint256)                       public Peace; // min CR for un-permissioned vaults         [ray]
    mapping (bytes32 => mapping (address => uint256))  public peace; // min CR for permissioned vaults            [ray]
    mapping (bytes32 => mapping (address => uint256))  public uline; // debt ceiling for permissioned vaults      [rad]

    //address public immutable vat;
    //address public immutable vow;
    //address public immutable spotter;

    address public vat;
    address public vow;
    address public spotter;


    // --- Events ---
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, address indexed usr, bytes32 indexed what, uint256 data);
    event Hope(address indexed from, address indexed to);
    event Nope(address indexed from, address indexed to);
    event NewProxy(address indexed usr, address indexed urp);

    // --- Administration ---
    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if (what == "gate") gate[ilk] = data;
        else if (what == "Nib") Nib[ilk] = data;
        else if (what == "Peace") Peace[ilk] = data;
        else revert("CharterManager/file-unrecognized-param");
        emit File(ilk, what, data);
    }
    function file(bytes32 ilk, address usr, bytes32 what, uint256 data) external auth {
        if (what == "uline") uline[ilk][usr] = data;
        else if (what == "nib") nib[ilk][usr] = data;
        else if (what == "peace") peace[ilk][usr] = data;
        else revert("CharterManager/file-unrecognized-param");
        emit File(ilk, usr, what, data);
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function _wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _mul(x, y) / WAD;
    }
    function _rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _mul(x, y) / RAY;
    }
    function _rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _mul(x, RAY) / y;
    }

    // --- Auth ---
    modifier auth {
        require(wards[msg.sender] == 1, "CharterManager/non-authed");
        _;
    }

    constructor(address vat_, address vow_, address spotter_) public {
        vat = vat_;
        vow = vow_;
        spotter = spotter_;
    }

    modifier allowed(address usr) {
        require(msg.sender == usr || can[usr][msg.sender] == 1, "CharterManager/not-allowed");
        _;
    }
    function hope(address usr) external {
        can[msg.sender][usr] = 1;
        emit Hope(msg.sender, usr);
    }
    function nope(address usr) external {
        can[msg.sender][usr] = 0;
        emit Nope(msg.sender, usr);
    }

    function getOrCreateProxy(address usr) public returns (address urp) {
        urp = proxy[usr];
        if (urp == address(0)) {
            urp = proxy[usr] = address(new UrnProxy(address(vat), usr));
            emit NewProxy(usr, urp);
        }
    }

    function join(address gemJoin, address usr, uint256 amt) external {
        require(VatLike(vat).wards(gemJoin) == 1, "CharterManager/gem-join-not-authorized");

        GemLike gem = ManagedGemJoinLike(gemJoin).gem();
        gem.transferFrom(msg.sender, address(this), amt);
        gem.approve(gemJoin, amt);
        ManagedGemJoinLike(gemJoin).join(getOrCreateProxy(usr), amt);
    }

    function exit(address gemJoin, address usr, uint256 amt) external {
        require(VatLike(vat).wards(gemJoin) == 1, "CharterManager/gem-join-not-authorized");

        address urp = proxy[msg.sender];
        require(urp != address(0), "CharterManager/non-existing-urp");
        ManagedGemJoinLike(gemJoin).exit(urp, usr, amt);
    }

    function _draw(
        bytes32 ilk, address u, address urp, address w, int256 dink, int256 dart, uint256 rate, uint256 _gate
        ) internal {
        uint256 _nib = (_gate == 1) ? nib[ilk][u] : Nib[ilk];
        uint256 dtab = _mul(rate, uint256(dart)); // rad
        uint256 coin = _wmul(dtab, _nib);         // rad

        VatLike(vat).frob(ilk, urp, urp, urp, dink, dart);
        VatLike(vat).move(urp, w, _sub(dtab, coin));
        VatLike(vat).move(urp, vow, coin);
    }

    function _validate(
        bytes32 ilk, address u, address urp, int256 dink, int256 dart, uint256 rate, uint256 spot, uint256 _gate
        ) internal {
        if (dart > 0 || dink < 0) {
            // vault is more risky than before

            (uint256 ink, uint256 art) = VatLike(vat).urns(ilk, urp);
            uint256 tab = _mul(art, rate); // rad

            if (dart > 0 && _gate == 1) {
                require(tab <= uline[ilk][u], "CharterManager/user-line-exceeded");
            }

            uint256 _peace = (_gate == 1) ? peace[ilk][u] : Peace[ilk];
            if (_peace > 0) {
                (, uint256 mat) = SpotterLike(spotter).ilks(ilk);
                // reconstruct price, avoid un-applying par so it's accounted for when comparing to tab
                uint256 peaceSpot = _rdiv(_rmul(spot, mat), _peace); // ray
                require(tab <= _mul(ink, peaceSpot), "CharterManager/below-peace-ratio");
            }
        }
    }

    function frob(bytes32 ilk, address u, address v, address w, int256 dink, int256 dart) external allowed(u) {
        require(u == v && w == msg.sender, "CharterManager/not-matching");
        address urp = getOrCreateProxy(u);
        (, uint256 rate, uint256 spot,,) = VatLike(vat).ilks(ilk);
        uint256 _gate = gate[ilk];

        if (dart <= 0) {
            VatLike(vat).frob(ilk, urp, urp, w, dink, dart);
        } else {
            _draw(ilk, u, urp, w, dink, dart, rate, _gate);
        }
        _validate(ilk, u, urp, dink, dart, rate, spot, _gate);
    }

    function flux(bytes32 ilk, address src, address dst, uint256 wad) external allowed(src) {
        address surp = getOrCreateProxy(src);
        address durp = getOrCreateProxy(dst);

        VatLike(vat).flux(ilk, surp, durp, wad);
    }

    function onLiquidation(address gemJoin, address usr, uint256 wad) external {}

    function onVatFlux(address gemJoin, address from, address to, uint256 wad) external {}

    function quit(bytes32 ilk, address dst) external {
        require(VatLike(vat).live() == 0, "CharterManager/vat-still-live");

        address urp = getOrCreateProxy(msg.sender);
        (uint256 ink, uint256 art) = VatLike(vat).urns(ilk, urp);
        require(int256(ink) >= 0, "CharterManager/overflow");
        require(int256(art) >= 0, "CharterManager/overflow");
        VatLike(vat).fork(
            ilk,
            urp,
            dst,
            int256(ink),
            int256(art)
        );
    }
}