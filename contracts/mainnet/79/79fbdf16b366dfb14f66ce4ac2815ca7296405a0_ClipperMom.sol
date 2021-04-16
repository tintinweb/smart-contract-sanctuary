/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// ClipperMom.sol -- governance interface for the Clipper

// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity >=0.6.12;

interface ClipLike {
    function file(bytes32, uint256) external;
    function ilk() external view returns (bytes32);
    function stopped() external view returns (uint256);
}

interface AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

interface OsmLike {
    function peek() external view returns (uint256, bool);
    function peep() external view returns (uint256, bool);
}

interface SpotterLike {
    function ilks(bytes32) external view returns (OsmLike, uint256);
}

contract ClipperMom {
    address public owner;
    address public authority;
    mapping (address => uint256) public locked;    // timestamp when becomes unlocked (per clipper)
    mapping (address => uint256) public tolerance; // clipper -> ray

    SpotterLike public immutable spotter;

    event SetOwner(address indexed oldOwner, address indexed newOwner);
    event SetAuthority(address indexed oldAuthority, address indexed newAuthority);
    event SetBreaker(address indexed clip, uint256 level);

    modifier onlyOwner {
        require(msg.sender == owner, "ClipperMom/only-owner");
        _;
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ClipperMom/not-authorized");
        _;
    }

    constructor(address spotter_) public {
        owner = msg.sender;
        spotter = SpotterLike(spotter_);
        emit SetOwner(address(0), msg.sender);
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == address(0)) {
            return false;
        } else {
            return AuthorityLike(authority).canCall(src, address(this), sig);
        }
    }

    function getPrices(address clip) internal view returns (uint256 cur, uint256 nxt) {
        (OsmLike osm, ) = spotter.ilks(ClipLike(clip).ilk());
        bool has;
        (cur, has) = osm.peek();
        require(has, "ClipperMom/invalid-cur-price");
        (nxt, has) = osm.peep();
        require(has, "ClipperMom/invalid-nxt-price");
    }

    // Governance actions with delay
    function setOwner(address owner_) external onlyOwner {
        emit SetOwner(owner, owner_);
        owner = owner_;
    }

    function setAuthority(address authority_) external onlyOwner {
        emit SetAuthority(authority, authority_);
        authority = authority_;
    }

    // Set the price tolerance for a specific ilk.
    // The price tolerance is the minimum acceptable value a new price can have relative to the previous price
    // For instance, a tolerance of 0.6 means that a new price can't be lower than 60% of the previous price
    // 0.6 * RAY = 600000000000000000000000000 => means acceptable drop from previous price is up to 40%
    function setPriceTolerance(address clip, uint256 value) external onlyOwner {
        require(value <= 1 * RAY, "ClipperMom/tolerance-out-of-bounds");
        tolerance[clip] = value;
    }

    // Governance action without delay
    function setBreaker(address clip, uint256 level, uint256 delay) external auth {
        require(level <= 3, "ClipperMom/nonexistent-level");
        ClipLike(clip).file("stopped", level);
        // If governance changes the status of the breaker we want to lock for one hour
        // the permissionless function so the osm can pull new nxt price to compare
        locked[clip] = add(block.timestamp, delay);
        emit SetBreaker(clip, level);
    }

    /**
        The following implements a permissionless circuit breaker in case the price reported by an oracle
        for a particular collateral type will drop below than a governance-defined % from 1 hour to the next.

        The setPriceTolerance function sets that % (as a value between 0 and RAY) for a specific collateral type.
        
        tripBreaker takes the address of some ilk's Clipper.
        It then gets the current and next price and checks whether the next price is less than the minimum
        acceptable next price based on the tolerance. If the next price is unacceptable (lower than rmul(current_price, tolerance)),
        it stops creation of new auctions and resets of current auctions for the Clipper's ilk. Currently, governance
        must reset the breaker manually.
    */
    function tripBreaker(address clip) external {
        require(ClipLike(clip).stopped() < 2, "ClipperMom/clipper-already-stopped");
        require(block.timestamp > locked[clip], "ClipperMom/temporary-locked");
      
        (uint256 cur, uint256 nxt) = getPrices(clip);

        // tolerance[clip] == 0 will always make the following require to revert
        require(nxt < rmul(cur, tolerance[clip]), "ClipperMom/price-within-bounds");
        ClipLike(clip).file("stopped", 2);
        emit SetBreaker(clip, 2);
    }
}