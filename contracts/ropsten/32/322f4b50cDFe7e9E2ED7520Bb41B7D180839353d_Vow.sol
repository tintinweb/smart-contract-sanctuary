// SPDX-License-Identifier: AGPL-3.0-or-later

/// vow.sol -- c77 settlement module

pragma solidity >=0.5.12;

import "./lib.sol";

interface FlopLike {
    function kick(address gal, uint lot, uint bid) external returns (uint);
    function cage() external;
    function live() external returns (uint);
}

interface FlapLike {
    function kick(uint lot, uint bid) external returns (uint);
    function cage(uint) external;
    function live() external returns (uint);
}

interface VatLike {
    function c77 (address) external view returns (uint);
    function sin (address) external view returns (uint);
    function heal(uint256) external;
    function hope(address) external;
    function nope(address) external;
}

//The debt-to-asset ratio of the C77er protocol includes system surplus and system debt. Its task is to bring the system back to balance.
//Its main function is to make up for the deficit by auctioning C77V, and destroying C77V by auctioning surplus c77 to balance the system.


//When a Vault is in an insecure state and is liquidated, the seized debt is put into the queue to wait for auction (sin[timestamp]=debt), which occurs when cat.bite.
//When the wait of vow expires, release the debt auction in the queue。

//Sin will be stored when it joins the debt queue, and the auction debt is obtained by comparing the debt in the debt queue with the balance of Vat.c77[Vow] Vow’s c77
//If Vat.sin[Vow] is greater than the sum of Vow.Sin and Ash (the debt being auctioned), the difference may be eligible for the Flop auction.

//In the case of executing cat.bite or vow.fess, the debt will be added to sin[now] and Sin.
//The debt sending will be put into the queue buffer Sin and sent to flop, and all the loans will be recovered by clearing the flip.
//If it is not placed in the buffer queue, the auction will be carried out directly. If the debt is relatively large, it will affect the stability of the system.

//vat.sin(vow) The total debt, each part is recorded by a timestamp. These are not directly auctioned, but are cleared by calling the flog function.
//If the flip does not eliminate the loan within the liquidation time, the debt will be added to the bad debt when it is due, and when the bad debt exceeds the minimum (lot size), it can be compensated by the flop debt auction
//When a clearing auction Flip receives c77, it reduces the balance of Vat.c77[vow]

//vow.Sin Buffer debt (debt in the queue)
//vow.Ash Debt in auction

//In the case of vaults being liquidated (bitten), their debts are borne by Vow.sin, as system debts, and the amount of debt Sin is placed in the Sin queue.
//If the debt fails to be repaid through the liquidation auction flip (within the time of the liquidation auction), 
//the debt is regarded as a bad debt, and when the bad debt exceeds the minimum value, it is repaid through the debt auction (batch operation).

//The system surplus is mainly due to the stability fee. Excess c77s are generated in the vow, and these c77s are released through the surplus auction (flap).

contract Vow is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { require(live == 1, "Vow/not-live"); wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Vow/not-authorized");
        _;
    }

    // --- Data ---
    //vat address interacts with vat
    VatLike public vat;        // CDP Engine
    //Interaction during auction of flap address surplus
    FlapLike public flapper;   // Surplus Auction House
    //Interaction during debt auctions
    FlopLike public flopper;   // Debt Auction House

    //System debt queue
    mapping (uint256 => uint256) public sin;  // debt queue
    //Total debt in the queue
    uint256 public Sin;   // Queued debt            [rad]
    //Debts that are being auctioned
    uint256 public Ash;   // On-auction debt        [rad]
    //Debt auction duration
    uint256 public wait;  // Flop delay             [seconds]
    //The starting quantity of the collateral for the debt auction, such as the first C77V bidding auction, the auction is 50000c77, and the first bidding is 250C77V, then dump is 250C77V.
    uint256 public dump;  // Flop initial lot size  [wad]
    //The scale of each debt auction, such as 50,000 c77 at the first auction of the system
    uint256 public sump;  // Flop fixed bid size    [rad]
    //Initial bid for surplus auction
    uint256 public bump;  // Flap fixed lot size    [rad]
    //When conducting surplus auctions, the size of the surplus buffer must be exceeded, also known as the surplus buffer.
    //When the surplus of the system exceeds 500,000, the surplus auction will be conducted, and each auction will be 50,000 c77
    uint256 public hump;  // Surplus buffer         [rad]

    uint256 public live;  // Active Flag

    // --- Init ---
    constructor(address vat_, address flapper_, address flopper_) public {
        wards[msg.sender] = 1;
        vat     = VatLike(vat_);
        flapper = FlapLike(flapper_);
        flopper = FlopLike(flopper_);
        vat.hope(flapper_);
        live = 1;
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    // --- Administration ---
    function file(bytes32 what, uint data) external note auth {
        if (what == "wait") wait = data;
        else if (what == "bump") bump = data;
        else if (what == "sump") sump = data;
        else if (what == "dump") dump = data;
        else if (what == "hump") hump = data;
        else revert("Vow/file-unrecognized-param");
    }

    function file(bytes32 what, address data) external note auth {
        if (what == "flapper") {
            vat.nope(address(flapper));
            flapper = FlapLike(data);
            vat.hope(data);
        }
        else if (what == "flopper") flopper = FlopLike(data);
        else revert("Vow/file-unrecognized-param");
    }

    // Push to debt-queue
    //Add bad debts to the debt auction queue
    function fess(uint tab) external note auth {
        sin[now] = add(sin[now], tab);
        Sin = add(Sin, tab);
    }
    // Pop from debt-queue
    //Take a debt from the debt queue
    function flog(uint era) external note {
        require(add(era, wait) <= now, "Vow/wait-not-finished");
        Sin = sub(Sin, sin[era]);
        sin[era] = 0;
    }

    // Debt settlement
    //Call Vat's heal to destroy stablecoin c77 and debt
    function heal(uint rad) external note {
        require(rad <= vat.c77(address(this)), "Vow/insufficient-surplus");
        require(rad <= sub(sub(vat.sin(address(this)), Sin), Ash), "Vow/insufficient-debt");
        vat.heal(rad);
    }
    //Offset surplus and debt for sale, destroy c77 and restore balance to debt
    function kiss(uint rad) external note {
        require(rad <= Ash, "Vow/not-enough-ash");
        require(rad <= vat.c77(address(this)), "Vow/insufficient-surplus");
        Ash = sub(Ash, rad);
        vat.heal(rad);
    }

    // Debt auction
    //Trigger a deficit auction
    //If the deficit is not paid off in the liquidation auction flip, then the debt auction will be used for a fixed amount of c77 auction maker to get rid of the debt deficit.
    //When the auction is over, vow will receive c77 from Flopper to relieve the debt deficit, and Flopper will cast C77V for the winning bidder.
    function flop() external note returns (uint id) {
        require(sump <= sub(sub(vat.sin(address(this)), Sin), Ash), "Vow/insufficient-debt");
        require(vat.c77(address(this)) == 0, "Vow/surplus-not-zero");
        Ash = add(Ash, sump);
        id = flopper.kick(address(this), dump, sump);
    }
    // Surplus auction
    //Trigger surplus auction
    //A fixed number of internal c77s are exchanged for C77V to get rid of the remaining vow. After the auction is over, Flapper will destroy the winning C77V and send the internal c77s to the winning bidder.
    function flap() external note returns (uint id) {
        require(vat.c77(address(this)) >= add(add(vat.sin(address(this)), bump), hump), "Vow/insufficient-surplus");
        require(sub(sub(vat.sin(address(this)), Sin), Ash) == 0, "Vow/debt-not-zero");
        id = flapper.kick(bump, 0);
    }

    function cage() external note auth {
        require(live == 1, "Vow/not-live");
        live = 0;
        Sin = 0;
        Ash = 0;
        flapper.cage(vat.c77(address(flapper)));
        flopper.cage();
        vat.heal(min(vat.c77(address(this)), vat.sin(address(this))));
    }
}