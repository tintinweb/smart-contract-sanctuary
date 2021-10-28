// SPDX-License-Identifier: AGPL-3.0-or-later

/// cat.sol -- c77 liquidation module

pragma solidity >=0.5.12;

import "./lib.sol";

//Defines the interface of the kick() function in the auction contract，
//The specific logic of this interface is defined in the external contract. The current auction-related logic is in the flip contract of the main contract warehouse.
interface Kicker {
    function kick(address urn, address gal, uint256 tab, uint256 lot, uint256 bid)
        external returns (uint256);
}
//The interface of the core contract module Vat
interface VatLike {
    function ilks(bytes32) external view returns (
        uint256 Art,  // [wad]
        uint256 rate, // [ray]
        uint256 spot, // [ray]
        uint256 line, // [rad]
        uint256 dust  // [rad]
    );
    function urns(bytes32,address) external view returns (
        uint256 ink,  // [wad]
        uint256 art   // [wad]
    );
    function grab(bytes32,address,address,address,int256,int256) external;
    function hope(address) external;
    function nope(address) external;
}
//
interface VowLike {
    function fess(uint256) external;
}

//The system's clearing agent, which enables keepers users to send debt positions below the safety line to auctions.
contract Cat is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Cat/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        //The contract address specifically responsible for executing the collateral liquidation auction logic
        address flip;  // Liquidator
        //Penalty for collateral, currently ETH is 13%
        uint256 chop;  // Liquidation Penalty  [wad]
        //The number of assets waiting to be liquidated
        uint256 dunk;  // Liquidation Quantity [rad]
    }

    mapping (bytes32 => Ilk) public ilks;
    //Confirm whether it is over by live as 1. After deployment, it can only be set to 0 through the cage function, and cannot be set to 1 anymore.
    uint256 public live;   // Active Flag
    //The contract address of the core contract vat
    VatLike public vat;    // CDP Engine
    //
    VowLike public vow;    // Debt Engine
    //The system includes the maximum amount of fines that can be auctioned (C77V voting settings)
    uint256 public box;    // Max c77 out for liquidation        [rad]
    //The total repayment amount required for system clearing
    uint256 public litter; // Balance of c77 out for liquidation [rad]

    // --- Events ---
    event Bite(
      bytes32 indexed ilk,
      address indexed urn,
      uint256 ink,
      uint256 art,
      uint256 tab,
      address flip,
      uint256 id
    );

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        live = 1;
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    //Safe calculation function, judging up and down overflow
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) { z = y; } else { z = x; }
    }
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    //Only external administrator rights can be adjusted
    // --- Administration ---
    function file(bytes32 what, address data) external note auth {
        if (what == "vow") vow = VowLike(data);
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 what, uint256 data) external note auth {
        if (what == "box") box = data;
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, uint256 data) external note auth {
        if (what == "chop") ilks[ilk].chop = data;
        else if (what == "dunk") ilks[ilk].dunk = data;
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, address flip) external note auth {
        if (what == "flip") {
            vat.nope(ilks[ilk].flip);
            ilks[ilk].flip = flip;
            vat.hope(flip);
        }
        else revert("Cat/file-unrecognized-param");
    }

    // --- CDP Liquidation ---
    //You can call bite at any time, but it will only succeed if the mortgage debt warehouse is not safe.
    //When the locked collateral multiplied by the collateral rate is lower than its debt (collateral multiplied by the collateral rate), cdp is not safe.
    function bite(bytes32 ilk, address urn) external returns (uint256 id) {
        //Obtain the mortgage rate, the real-time price of the oracle, and the minimum loanable amount respectively
        (,uint256 rate,uint256 spot,,uint256 dust) = vat.ilks(ilk);
        //Return the amount of collateral and the total loan amount
        (uint256 ink, uint256 art) = vat.urns(ilk, urn);
        //Make sure it is not over, it can only be set to 0 after deployment
        require(live == 1, "Cat/not-live");
        //Multiply the collateral by the mortgage rate. If it is less than the mortgage amount multiplied by the real-time price of the oracle, the call will be successful.
        //Trigger liquidation requirements, the amount of personal collateral * the price of collateral with a margin of safety <personal debt * mortgage rate
        //For example, when the price of ETH is 300usd/eth, 1ETH is used to borrow 200c77. When the price of Eth changes to 200usd/eth, then 1Eth * 200usd/Eth <200c77 * 150% will trigger liquidation
        //After the price of collateral drops to a certain level, liquidation is triggered
        require(spot > 0 && mul(ink, spot) < mul(art, rate), "Cat/not-unsafe");
        //Add link to memory to optimize efficiency
        Ilk memory milk = ilks[ilk];
        uint256 dart;
        //Apply for a new scope to prevent the stack from overflowing too deep and causing errors
        {
            //Price buffer zone
            uint256 room = sub(box, litter);

            // test whether the remaining space in the litterbox is dusty
            require(litter < box && room >= dust, "Cat/liquidation-limit-hit");

            dart = min(art, mul(min(milk.dunk, room), WAD) / rate / milk.chop);
        }

        uint256 dink = min(ink, mul(ink, dart) / art);

        require(dart >  0      && dink >  0     , "Cat/null-auction");
        require(dart <= 2**255 && dink <= 2**255, "Cat/overflow"    );

        // This may leave the CDP in a dusty state
        //Liquidation, reduce personal collateral and personal debts, transfer the reduced collateral to this address (gem)
        //Control users' assets to be liquidated
        vat.grab(
            ilk, urn, address(this), address(vow), -int256(dink), -int256(dart)
        );
        vow.fess(mul(dart, rate));

        { // Avoid stack too deep
            // This calcuation will overflow if dart*rate exceeds ~10^14,
            // i.e. the maximum dunk is roughly 100 trillion c77.
            //
            uint256 tab = mul(mul(dart, rate), milk.chop) / WAD;
            litter = add(litter, tab);
            //Trigger an auction
            //Hand over to the corresponding clearing contract to initiate an auction request
            id = Kicker(milk.flip).kick({
                urn: urn,
                gal: address(vow),
                tab: tab,
                lot: dink,
                bid: 0
            });
        }

        emit Bite(ilk, urn, dink, dart, mul(dart, rate), milk.flip, id);
    }

    function claw(uint256 rad) external note auth {
        litter = sub(litter, rad);
    }

    function cage() external note auth {
        live = 0;
    }
}