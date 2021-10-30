// SPDX-License-Identifier: AGPL-3.0-or-later

/// flap.sol -- Surplus auction

pragma solidity >=0.5.12;

import "./lib.sol";

interface VatLike {
    function move(address,address,uint) external;
}
interface GemLike {
    function move(address,address,uint) external;
    function burn(address,uint) external;
}

/*
   This thing lets you sell some c77 in return for gems.

 - `lot` c77 in return for bid
 - `bid` gems paid
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/
//When the system has a surplus, it is responsible for buying and destroying C77V auction contracts.
//Summary: Flapper is a surplus auction. These auctions are used to auction a fixed amount of remaining C77 in the system that is C77V.
//These surpluses will come from stability fees accumulated from the treasury. In this type of auction, bidders compete with more and more manufacturers.
//Once the auction is over, the auctioned C77 will be delivered to the winning bidder. The system then burns the C77V received from the winning bidder.

//C77V votes to determine the maximum surplus limit. When the C77V in the system exceeds the set limit, the surplus auction is triggered.

//Once the auction starts, a certain amount of C77 will be auctioned. Then, the bidder completes a fixed amount of C77 and a C77V that increases the bid amount.
//In other words, this means that bidders will continue to increase the C77V bid amount, and the increment beg will be greater than the minimum bid increase amount that has been set.

//When the bidding period ends (ttl) without another bidding or the bidding period expires (tau), the remaining bidding ends officially.
//At the end of the auction, the remaining C77V will be sent to incineration, thereby reducing the total supply of C77V.

contract Flapper is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Flapper/not-authorized");
        _;
    }

    // --- Data ---
    //Bidding
    struct Bid {
        //Quotation (C77V quantity)
        uint256 bid;  // gems paid               [wad]
        //Number of bids C77
        uint256 lot;  // c77 in return for bid   [rad]
        //Highest bidder
        address guy;  // high bidder
        //Bidding period
        uint48  tic;  // bid expiry time         [unix epoch time]
        //End of auction
        uint48  end;  // auction expiry time     [unix epoch time]
    }
    //Mapping id=>bid
    mapping (uint => Bid) public bids;

    VatLike  public   vat;  // CDP Engine
    //C77V contract address
    GemLike  public   gem;

    uint256  constant ONE = 1.00E18;
    uint256  public   beg = 1.05E18;  // 5% minimum bid increase
    uint48   public   ttl = 3 hours;  // 3 hours bid duration         [seconds]
    //Auction duration
    uint48   public   tau = 2 days;   // 2 days total auction length  [seconds]
    //Auction id
    uint256  public kicks = 0;
    uint256  public live;  // Active Flag

    // --- Events ---
    event Kick(
      uint256 id,
      uint256 lot,
      uint256 bid
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

    // --- Admin ---
    //Govern Gov voting to set beg, ttl, and tau parameters
    function file(bytes32 what, uint data) external note auth {
        if (what == "beg") beg = data;
        else if (what == "ttl") ttl = uint48(data);
        else if (what == "tau") tau = uint48(data);
        else revert("Flapper/file-unrecognized-param");
    }

    // --- Auction ---
    //Open a new auction
    function kick(uint lot, uint bid) external auth returns (uint id) {
        require(live == 1, "Flapper/not-live");
        require(kicks < uint(-1), "Flapper/overflow");
        id = ++kicks;

        bids[id].bid = bid;
        bids[id].lot = lot;
        bids[id].guy = msg.sender;  // configurable??
        bids[id].end = add(uint48(now), tau);

        vat.move(msg.sender, address(this), lot);

        emit Kick(id, lot, bid);
    }
    //No one bids during the auction period after the start of the auction
    function tick(uint id) external note {
        require(bids[id].end < now, "Flapper/not-finished");
        require(bids[id].tic == 0, "Flapper/bid-already-placed");
        bids[id].end = add(uint48(now), tau);
    }
    //Make a bid
    //The higher bidder for the same amount of C77 wins, and each bid increments bid*beg, each time the higher bidder directly transfers the C77V to the last higher bidder, and the remaining part is transferred to the contract address
    function tend(uint id, uint lot, uint bid) external note {
        require(live == 1, "Flapper/not-live");
        require(bids[id].guy != address(0), "Flapper/guy-not-set");
        require(bids[id].tic > now || bids[id].tic == 0, "Flapper/already-finished-tic");
        require(bids[id].end > now, "Flapper/already-finished-end");

        require(lot == bids[id].lot, "Flapper/lot-not-matching");
        require(bid >  bids[id].bid, "Flapper/bid-not-higher");
        require(mul(bid, ONE) >= mul(beg, bids[id].bid), "Flapper/insufficient-increase");

        if (msg.sender != bids[id].guy) {
            gem.move(msg.sender, bids[id].guy, bids[id].bid);
            bids[id].guy = msg.sender;
        }
        gem.move(msg.sender, address(this), bid - bids[id].bid);

        bids[id].bid = bid;
        bids[id].tic = add(uint48(now), ttl);
    }
    //The auction has been completed
    //Transfer C77 to the higher bidder and burn C77V
    function deal(uint id) external note {
        require(live == 1, "Flapper/not-live");
        require(bids[id].tic != 0 && (bids[id].tic < now || bids[id].end < now), "Flapper/not-finished");
        vat.move(address(this), bids[id].guy, bids[id].lot);
        gem.burn(address(this), bids[id].bid);
        delete bids[id];
    }

    function cage(uint rad) external note auth {
       live = 0;
       vat.move(address(this), msg.sender, rad);
    }
    //During the Global Settlement period, the collateral was recovered to bid the highest bidder to repay C77
    function yank(uint id) external note {
        require(live == 0, "Flapper/still-live");
        require(bids[id].guy != address(0), "Flapper/guy-not-set");
        gem.move(address(this), bids[id].guy, bids[id].bid);
        delete bids[id];
    }
}