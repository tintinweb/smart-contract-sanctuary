/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// flop.sol -- Debt auction

// Copyright (C) 2018 Rain <[email protected]>
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

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface VatLike {
    function move(address,address,uint) external;
    function suck(address,address,uint) external;
}
interface GemLike {
    function mint(address,uint) external;
}
interface VowLike {
    function Ash() external returns (uint);
    function kiss(uint) external;
}

/*
   This thing creates gems on demand in return for dai.

 - `lot` gems in return for bid
 - `bid` dai paid
 - `gal` receives dai income
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/

contract Flopper {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Flopper/not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        uint256 bid;  // dai paid                [rad]
        uint256 lot;  // gems in return for bid  [wad]
        address guy;  // high bidder
        uint48  tic;  // bid expiry time         [unix epoch time]
        uint48  end;  // auction expiry time     [unix epoch time]
    }

    mapping (uint => Bid) public bids;

    VatLike  public   vat;  // CDP Engine
    GemLike  public   gem;

    uint256  constant ONE = 1.00E18;
    uint256  public   beg = 1.05E18;  // 5% minimum bid increase
    uint256  public   pad = 1.50E18;  // 50% lot increase for tick
    uint48   public   ttl = 3 hours;  // 3 hours bid lifetime         [seconds]
    uint48   public   tau = 2 days;   // 2 days total auction length  [seconds]
    uint256  public kicks = 0;
    uint256  public live;             // Active Flag
    address  public vow;              // not used until shutdown

    // --- Events ---
    event Kick(
      uint256 id,
      uint256 lot,
      uint256 bid,
      address indexed gal
    );

    // --- Init ---
    constructor(address vat_, address gem_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        gem = GemLike(gem_);
        live = 1;
    }

    // --- Math ---
    function add(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        if (x > y) { z = y; } else { z = x; }
    }

    // --- Admin ---
    function file(bytes32 what, uint data) external auth {
        if (what == "beg") beg = data;
        else if (what == "pad") pad = data;
        else if (what == "ttl") ttl = uint48(data);
        else if (what == "tau") tau = uint48(data);
        else revert("Flopper/file-unrecognized-param");
    }

    // --- Auction ---
    function kick(address gal, uint lot, uint bid) external auth returns (uint id) {
        require(live == 1, "Flopper/not-live");
        require(kicks < uint(-1), "Flopper/overflow");
        id = ++kicks;

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = gal;
        bids[id].end = add(uint48(now), tau);

        emit Kick(id, lot, bid, gal);
    }
    function tick(uint id) external {
        require(bids[id].end < now, "Flopper/not-finished");
        require(bids[id].tic == 0, "Flopper/bid-already-placed");
        bids[id].lot = mul(pad, bids[id].lot) / ONE;
        bids[id].end = add(uint48(now), tau);
    }
    function dent(uint id, uint lot, uint bid) external {
        require(live == 1, "Flopper/not-live");
        require(bids[id].guy != address(0), "Flopper/guy-not-set");
        require(bids[id].tic > now || bids[id].tic == 0, "Flopper/already-finished-tic");
        require(bids[id].end > now, "Flopper/already-finished-end");

        require(bid == bids[id].bid, "Flopper/not-matching-bid");
        require(lot <  bids[id].lot, "Flopper/lot-not-lower");
        require(mul(beg, lot) <= mul(bids[id].lot, ONE), "Flopper/insufficient-decrease");

        if (msg.sender != bids[id].guy) {
            vat.move(msg.sender, bids[id].guy, bid);

            // on first dent, clear as much Ash as possible
            if (bids[id].tic == 0) {
                uint Ash = VowLike(bids[id].guy).Ash();
                VowLike(bids[id].guy).kiss(min(bid, Ash));
            }

            bids[id].guy = msg.sender;
        }

        bids[id].lot = lot;
        bids[id].tic = add(uint48(now), ttl);
    }
    function deal(uint id) external {
        require(live == 1, "Flopper/not-live");
        require(bids[id].tic != 0 && (bids[id].tic < now || bids[id].end < now), "Flopper/not-finished");
        gem.mint(bids[id].guy, bids[id].lot);
        delete bids[id];
    }

    // --- Shutdown ---
    function cage() external auth {
       live = 0;
       vow = msg.sender;
    }
    function yank(uint id) external {
        require(live == 0, "Flopper/still-live");
        require(bids[id].guy != address(0), "Flopper/guy-not-set");
        vat.suck(vow, bids[id].guy, bids[id].bid);
        delete bids[id];
    }
}