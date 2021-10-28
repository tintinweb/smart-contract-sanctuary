// SPDX-License-Identifier: AGPL-3.0-or-later

/// end.sol -- global settlement engine

pragma solidity >=0.5.12;

import "./lib.sol";

interface VatLike {
    function c77(address) external view returns (uint256);
    function ilks(bytes32 ilk) external returns (
        uint256 Art,   // [wad]
        uint256 rate,  // [ray]
        uint256 spot,  // [ray]
        uint256 line,  // [rad]
        uint256 dust   // [rad]
    );
    function urns(bytes32 ilk, address urn) external returns (
        uint256 ink,   // [wad]
        uint256 art    // [wad]
    );
    function debt() external returns (uint256);
    function move(address src, address dst, uint256 rad) external;
    function hope(address) external;
    function flux(bytes32 ilk, address src, address dst, uint256 rad) external;
    function grab(bytes32 i, address u, address v, address w, int256 dink, int256 dart) external;
    function suck(address u, address v, uint256 rad) external;
    function cage() external;
}
interface CatLike {
    function ilks(bytes32) external returns (
        address flip,
        uint256 chop,  // [ray]
        uint256 lump   // [rad]
    );
    function cage() external;
}
interface PotLike {
    function cage() external;
}
interface VowLike {
    function cage() external;
}
interface Flippy {
    function bids(uint id) external view returns (
        uint256 bid,   // [rad]
        uint256 lot,   // [wad]
        address guy,
        uint48  tic,   // [unix epoch time]
        uint48  end,   // [unix epoch time]
        address usr,
        address gal,
        uint256 tab    // [rad]
    );
    function yank(uint id) external;
}

interface PipLike {
    function read() external view returns (bytes32);
}

interface Spotty {
    function par() external view returns (uint256);
    function ilks(bytes32) external view returns (
        PipLike pip,
        uint256 mat    // [ray]
    );
    function cage() external;
}

/*
    This is the `End` and it coordinates Global Settlement. This is an
    involved, stateful process that takes place over nine steps.

    First we freeze the system and lock the prices for each ilk.

    1. `cage()`:
        - freezes user entrypoints
        - cancels flop/flap auctions
        - starts cooldown period
        - stops pot drips

    2. `cage(ilk)`:
       - set the cage price for each `ilk`, reading off the price feed

    We must process some system state before it is possible to calculate
    the final c77 / collateral price. In particular, we need to determine

      a. `gap`, the collateral shortfall per collateral type by
         considering under-collateralised CDPs.

      b. `debt`, the outstanding c77 supply after including system
         surplus / deficit

    We determine (a) by processing all under-collateralised CDPs with
    `skim`:

    3. `skim(ilk, urn)`:
       - cancels CDP debt
       - any excess collateral remains
       - backing collateral taken

    We determine (b) by processing ongoing c77 generating processes,
    i.e. auctions. We need to ensure that auctions will not generate any
    further c77 income. In the two-way auction model this occurs when
    all auctions are in the reverse (`dent`) phase. There are two ways
    of ensuring this:

    4.  i) `wait`: set the cooldown period to be at least as long as the
           longest auction duration, which needs to be determined by the
           cage administrator.

           This takes a fairly predictable time to occur but with altered
           auction dynamics due to the now varying price of c77.

       ii) `skip`: cancel all ongoing auctions and seize the collateral.

           This allows for faster processing at the expense of more
           processing calls. This option allows c77 holders to retrieve
           their collateral faster.

           `skip(ilk, id)`:
            - cancel individual flip auctions in the `tend` (forward) phase
            - retrieves collateral and returns c77 to bidder
            - `dent` (reverse) phase auctions can continue normally

    Option (i), `wait`, is sufficient for processing the system
    settlement but option (ii), `skip`, will speed it up. Both options
    are available in this implementation, with `skip` being enabled on a
    per-auction basis.

    When a CDP has been processed and has no debt remaining, the
    remaining collateral can be removed.

    5. `free(ilk)`:
        - remove collateral from the caller's CDP
        - owner can call as needed

    After the processing period has elapsed, we enable calculation of
    the final price for each collateral type.

    6. `thaw()`:
       - only callable after processing time period elapsed
       - assumption that all under-collateralised CDPs are processed
       - fixes the total outstanding supply of c77
       - may also require extra CDP processing to cover vow surplus

    7. `flow(ilk)`:
        - calculate the `fix`, the cash price for a given ilk
        - adjusts the `fix` in the case of deficit / surplus

    At this point we have computed the final price for each collateral
    type and c77 holders can now turn their c77 into collateral. Each
    unit c77 can claim a fixed basket of collateral.

    c77 holders must first `pack` some c77 into a `bag`. Once packed,
    c77 cannot be unpacked and is not transferrable. More c77 can be
    added to a bag later.

    8. `pack(wad)`:
        - put some c77 into a bag in preparation for `cash`

    Finally, collateral can be obtained with `cash`. The bigger the bag,
    the more collateral can be released.

    9. `cash(ilk, wad)`:
        - exchange some c77 from your bag for gems from a specific ilk
        - the number of gems is limited by how big your bag is
*/
//This module coordinates the shutdown. In short, the shutdown shuts down the system and compensates the c77 holders.
//This process can happen during the upgrade (c77 iteration), or it can happen for security reasons when there are implementation flaws in the code and design.

//The purpose of End is to coordinate the shutdown of the system. This is a complex and stateful process that takes place in the following nine main steps
//1.cage()
//  1.1. This process starts by freezing the system and locking the price of each collateral.
//       1.1.1 Ability to stop depositing collateral and withdraw c77 from the vault

//Next, the system will stop all current Flap/Flop auctions, allowing the cancellation of the call to a single auction and calling the yank() function of the corresponding contract.
// One of the reasons these auctions were frozen and cancelled was because the purpose of the closure procedure was to transfer system surplus or system debt to c77.
//In addition, there is no guarantee of the value of C77V during the closure period, so it is impossible to rely on the mechanism of market value of C77V, which means that there is no reason to continue auctions that will affect the supply of C77V.
contract End is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external note auth { wards[guy] = 1; }
    function deny(address guy) external note auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "End/not-authorized");
        _;
    }

    // --- Data ---
    //Respectively represent the addresses of their respective contracts
    VatLike  public vat;   // CDP Engine
    CatLike  public cat;
    VowLike  public vow;   // Debt Engine
    PotLike  public pot;
    Spotty   public spot;
    //The system is operating normally at 1 o'clock
    uint256  public live;  // Active Flag
    //Settlement time
    uint256  public when;  // Time of cage                   [unix epoch time]
    //Cooling time
    uint256  public wait;  // Processing Cooldown Length             [seconds]
    //The processed c77 is normal/stable coin supply is normal, and the system surplus/deficit has been absorbed.
    uint256  public debt;  // Total outstanding c77 following processing [rad]
    //The price of each collateral at the time of settlement
    mapping (bytes32 => uint256) public tag;  // Cage price              [ray]
    //Insufficient collateral
    mapping (bytes32 => uint256) public gap;  // Collateral shortfall    [wad]
    //Total outstanding stablecoin debt
    mapping (bytes32 => uint256) public Art;  // Total debt per ilk      [wad]
    //Price of each stablecoin
    mapping (bytes32 => uint256) public fix;  // Final cash price        [ray]
    //Packed c77, ready to exchange collateral
    mapping (address => uint256)                      public bag;  //    [wad]
    //The number of stablecoins exchanged for a given address
    mapping (bytes32 => mapping (address => uint256)) public out;  //    [wad]

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / RAY;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, RAY) / y;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, WAD) / y;
    }

    // --- Administration ---
    function file(bytes32 what, address data) external note auth {
        require(live == 1, "End/not-live");
        if (what == "vat")  vat = VatLike(data);
        else if (what == "cat")  cat = CatLike(data);
        else if (what == "vow")  vow = VowLike(data);
        else if (what == "pot")  pot = PotLike(data);
        else if (what == "spot") spot = Spotty(data);
        else revert("End/file-unrecognized-param");
    }
    function file(bytes32 what, uint256 data) external note auth {
        require(live == 1, "End/not-live");
        if (what == "wait") wait = data;
        else revert("End/file-unrecognized-param");
    }

    // --- Settlement ---
    function cage() external note auth {
        require(live == 1, "End/not-live");
        live = 0;
        when = now;
        vat.cage();
        cat.cage();
        vow.cage();
        spot.cage();
        pot.cage();
    }
    //cage-Lock the system and initiate shutdown. This is done by freezing user-oriented operations, canceling flap and flop auctions,
    //This is achieved by locking the remaining system contracts, disabling certain governance operations that may interfere with the resolution process, and starting a cooling-off period.
    function cage(bytes32 ilk) external note {
        require(live == 0, "End/still-live");
        require(tag[ilk] == 0, "End/tag-ilk-already-defined");
        (Art[ilk],,,,) = vat.ilks(ilk);
        (PipLike pip,) = spot.ilks(ilk);
        // par is a ray, pip returns a wad
        //Set the final price of the collateral
        tag[ilk] = wdiv(spot.par(), uint(pip.read()));
    }
    //Cancel auction
    function skip(bytes32 ilk, uint256 id) external note {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");

        (address flipV,,) = cat.ilks(ilk);
        Flippy flip = Flippy(flipV);
        (, uint rate,,,) = vat.ilks(ilk);
        (uint bid, uint lot,,,, address usr,, uint tab) = flip.bids(id);

        vat.suck(address(vow), address(vow),  tab);
        vat.suck(address(vow), address(this), bid);
        vat.hope(address(flip));
        flip.yank(id);

        uint art = tab / rate;
        Art[ilk] = add(Art[ilk], art);
        require(int(lot) >= 0 && int(art) >= 0, "End/overflow");
        vat.grab(ilk, usr, address(this), address(vow), int(lot), int(art));
    }

    //Cancel the arrears in the vault at the quoted price
    function skim(bytes32 ilk, address urn) external note {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");
        (, uint rate,,,) = vat.ilks(ilk);
        (uint ink, uint art) = vat.urns(ilk, urn);

        uint owe = rmul(rmul(art, rate), tag[ilk]);
        uint wad = min(ink, owe);
        gap[ilk] = add(gap[ilk], sub(owe, wad));

        require(wad <= 2**255 && art <= 2**255, "End/overflow");
        //Final liquidation
        vat.grab(ilk, urn, address(this), address(vow), -int(wad), -int(art));
    }
    //Remove (remaining) collateral from the settled vault. It only happens when there is no debt in the safe.
    function free(bytes32 ilk) external note {
        require(live == 0, "End/still-live");
        (uint ink, uint art) = vat.urns(ilk, msg.sender);
        require(art == 0, "End/art-not-zero");
        require(ink <= 2**255, "End/overflow");
        vat.grab(ilk, msg.sender, msg.sender, address(vow), -int(ink), 0);
    }
    //Fixed total stable currency debt
    function thaw() external note {
        require(live == 0, "End/still-live");
        require(debt == 0, "End/debt-not-zero");
        require(vat.c77(address(vow)) == 0, "End/surplus-not-zero");
        require(now >= add(when, wait), "End/wait-not-finished");
        debt = vat.debt();
    }
    //Calculating the fixed price of the collateral may adjust the cage price based on the surplus/deficit.
    function flow(bytes32 ilk) external note {
        require(debt != 0, "End/debt-zero");
        require(fix[ilk] == 0, "End/fix-ilk-already-defined");

        (, uint rate,,,) = vat.ilks(ilk);
        uint256 wad = rmul(rmul(Art[ilk], rate), tag[ilk]);
        fix[ilk] = rdiv(mul(sub(wad, gap[ilk]), RAY), debt);
    }
    //Lock c77 in front of Cash / put some stablecoins in the bag to prepare cash.
    function pack(uint256 wad) external note {
        require(debt != 0, "End/debt-zero");
        vat.move(msg.sender, address(vow), mul(wad, RAY));
        bag[msg.sender] = add(bag[msg.sender], wad);
    }
    function cash(bytes32 ilk, uint wad) external note {
        require(fix[ilk] != 0, "End/fix-ilk-not-defined");
        vat.flux(ilk, address(this), msg.sender, rmul(wad, fix[ilk]));
        out[ilk][msg.sender] = add(out[ilk][msg.sender], wad);
        require(out[ilk][msg.sender] <= bag[msg.sender], "End/insufficient-bag-balance");
    }
}