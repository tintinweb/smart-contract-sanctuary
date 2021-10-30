// SPDX-License-Identifier: AGPL-3.0-or-later

/// flop.sol -- Debt auction

pragma solidity >=0.5.12;

import "./lib.sol";

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
   This thing creates gems on demand in return for c77.

 - `lot` gems in return for bid
 - `bid` c77 paid
 - `gal` receives c77 income
 - `ttl` single bid lifetime
 - `beg` minimum bid increase
 - `end` max auction duration
*/
//Debt auction is also called C77V auction
//Gov determines the debt ceiling (vow.sump) through C77V holders. When C77's bad debt exceeds this ceiling, a debt auction is triggered.
//Through vow.dump to decide to start the auction of the number of c77, the number of C77V can be reduced during the bidding period.
//When the system has bad debts, it is responsible for issuing and selling C77V auction contracts.	

//beg, ttl, tau intelligence is assigned by Gov governance contract through file(), only Vow calls kick()

//The debt auction adjusts the balance of the system by auctioning C77V in exchange for a fixed amount of c77.

//In a special period (Global Settlement) cage is called, the auction (dent) and completion of the auction (deal) cannot be called.

//By reconciling the surplus and the stability fee, if there is enough debt, (cleared debt> vow.sump), any user can send vow.flop to trigger the debt auction.

//Flop's auction is a reverse auction. The number of c77 auctioned by the system is fixed, and the number of C77V is required to win through bidding. After calling kick, set the c77 to be sold as Vow.sump,
//The number of C77V for the first bid is vow.dump. The auction will end after the bid time ttl, or after the auction time tau ends, and the first bidder will start to repay the system debt.
//Subsequent bids will reimburse the bidders who did not win the bid before. After the auction is over, debts will be cleared and C77V will be cast for the winning bidder.


//If the auction has not yet received the bid, anyone can call tick to restart the auction:
 //   Reset 1.. bids[id].end to now + tau
 //      2. bids[id].lot to bids[id].lot * pad / ONE

 //During the auction period, the number of C77V bids for each bid is decreasing, decreasing at least beg times of the previous one.
 //For example, if the first bidder bids 100c77 bid 10C77V, the next bidder's maximum bid is 9.5C77V competition 100c77


 //When the debt auction is triggered for the first time, the system-wide under-collateralized debt exceeds 4 million U.S. dollars. 
 //This auction will sell C77V tokens in exchange for 50,000 increments of c77, and use the raised funds to repay outstanding bad debts.
 //The first auction price of C77V started from 200c77, and a total of 250C77V (representing 50,000c77) was sold.
 //The next auction also corresponds to 50,000c77, but bidders can only get 230C77V, which is equivalent to the price of 217c77/C77V.
 //If no one bids for the first bid of 250C77V, the auction will restart three days later. 50,000c77 corresponds to 300C77V, that is, the price of each C77V is 166.66c77.
 //Ultimately, if there is at least one bid, and no one bids higher within 6 hours, the auction ends.

contract Flopper is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Flopper/not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        //Amount paid
        uint256 bid;  // c77 paid                [rad]
        //Number of auctions / C77V sold
        uint256 lot;  // gems in return for bid  [wad]
        //Highest bidder
        address guy;  // high bidder
        //Bid validity period
        uint48  tic;  // bid expiry time         [unix epoch time]
        //Auction end time
        uint48  end;  // auction expiry time     [unix epoch time]
    }

    mapping (uint => Bid) public bids;

    VatLike  public   vat;  // CDP Engine
    //C77V address
    GemLike  public   gem;

    uint256  constant ONE = 1.00E18;
    //Minimum bid rate %%
    uint256  public   beg = 1.05E18;  // 5% minimum bid increase
    //The size of the liquidation amount increased during the bidding period
    uint256  public   pad = 1.50E18;  // 50% lot increase for tick
    uint48   public   ttl = 3 hours;  // 3 hours bid lifetime         [seconds]
    //Maximum auction time
    uint48   public   tau = 2 days;   // 2 days total auction length  [seconds]
    //Total number of auctions, increasing id
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
    function file(bytes32 what, uint data) external note auth {
        if (what == "beg") beg = data;
        else if (what == "pad") pad = data;
        else if (what == "ttl") ttl = uint48(data);
        else if (what == "tau") tau = uint48(data);
        else revert("Flopper/file-unrecognized-param");
    }

    //First, vow calls the kick function to start a new auction, and the guy with the highest bid is set to the vow contract address. 
    //For example, the first auction parameter is the first bid parameter (vow address, 250C77V, 50000c77)
    // --- Auction ---
    //Start a new bidding auction
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
    //Restart the auction
    function tick(uint id) external note {
        require(bids[id].end < now, "Flopper/not-finished");
        require(bids[id].tic == 0, "Flopper/bid-already-placed");
        bids[id].lot = mul(pad, bids[id].lot) / ONE;
        bids[id].end = add(uint48(now), tau);
    }
    //Submit a fixed amount of C77. Whoever requires less C77V will win. If there is no bid for the first bid, the auction will restart three days later.
    //The first auction was for 50000c77, and the initial bid was 250C77V.
    //The first bidder A bid 230C77V, beg is 5%, 230C77V*(1+5%)> 250C77V
    //Then transfer 50000c77 to vat.c77[vow], the first bid is automatically triggered by vow, and the balance of c77 in A's vat is reduced by 50000c77.
    //The second bidder B continues to reduce the number of C77V, and needs to meet the requirements of beg, adding vat.c77[A] += 50000c77,vat.c77[B] += 50000c77.
    //Stop bidding if you know that other bidders think it is not worth accepting the lower price. Once the offer expires
    function dent(uint id, uint lot, uint bid) external note {
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
    //Complete the auction
    function deal(uint id) external note {
        require(live == 1, "Flopper/not-live");
        require(bids[id].tic != 0 && (bids[id].tic < now || bids[id].end < now), "Flopper/not-finished");
        gem.mint(bids[id].guy, bids[id].lot);
        delete bids[id];
    }

    // --- Shutdown ---
    //Call these two parameters when the system is shut down
    function cage() external note auth {
       live = 0;
       vow = msg.sender;
    }
    function yank(uint id) external note {
        require(live == 0, "Flopper/still-live");
        require(bids[id].guy != address(0), "Flopper/guy-not-set");
        vat.suck(vow, bids[id].guy, bids[id].bid);
        delete bids[id];
    }
}