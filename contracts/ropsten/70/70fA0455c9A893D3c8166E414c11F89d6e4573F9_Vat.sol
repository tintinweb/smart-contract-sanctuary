/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// vat.sol -- c77 CDP database

pragma solidity >=0.5.12;

//Mortgage debt warehouse
//The core of CDP, stores and tracks all associated c77 and mortgage balances.
//It also defines the rules and balancing strategies that can be used to operate CDP.
//The rules defined by Vat are immutable.
//The public structure in Vat and other contracts are called globally through the Vat address, and the parameters are passed through the file for setting
contract Vat {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { require(live == 1, "Vat/not-live"); wards[usr] = 1; }
    function deny(address usr) external note auth { require(live == 1, "Vat/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Vat/not-authorized");
        _;
    }

    mapping(address => mapping (address => uint)) public can;
    //edit permission
    function hope(address usr) external note { can[msg.sender][usr] = 1; }
    function nope(address usr) external note { can[msg.sender][usr] = 0; }
    //Check if one address is allowed to modify the gem or c77 balance of another address
    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }
    //wad、ray、rad Three numerical units
    //wad：Fixed-point decimal with 18 decimal places
    //ray: Fixed-point decimal with 27 decimal places
    //rad: Fixed-point decimal with 45 decimal places
   // ray  = 10 ** 27

    // --- Data ---
    //The structure of the collateral, the id of the collateral is the individual
    //The function of rate and spot is mainly to satisfy that ink * spot >= art * rate can be borrowed, otherwise it needs to be liquidated.
    struct Ilk {
        // The total loan amount of this collateral c77                                       [wad]
        uint256 Art; 
        // Cumulative stability expenses, cumulative loan annualized rate compound interest                    [ray]  
        uint256 rate;  
        // The price safety line is the maximum stable price allowed per unit of collateral under the current price of the collateral. Collateral with a price lower than the current value faces liquidation         [ray]
        //The contract spot calls vat.file() in poke() to give the maximum number of c77 that each unit asset is allowed to borrow, such as
        // spot=100c77/ETH, if 1 ETH was previously mortgaged and 120c77 was borrowed, liquidation must be performed
        uint256 spot;  
        // The maximum loanable amount of such collateral in the system                 [rad]
        uint256 line;  
        // The smallest loanable collateral in the system                [rad]
        uint256 dust;  
    }
    //Mortgage vault
    struct Urn {
        //The total amount of collateral, such as locking 10ETH
        uint256 ink;   // Locked Collateral  [wad]
        //The user's total loan, c77 is loaned from the system
        uint256 art;   // Normalised Debt    [wad]
    }
    //Collateral corresponding to the collateral id
    mapping (bytes32 => Ilk)                       public ilks;
   ////Collateral id => personal address => personal debt
    mapping (bytes32 => mapping (address => Urn )) public urns;
    //Token generates gem first, and then lends c77 through Ilk object
    //If you lock eth into the debt warehouse, then lend out c77
    //Collateral id => personal address => total value of personal collateral
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]
    //Personal address => contains c77, statistical function
    mapping (address => uint256)                   public c77;  // [rad]
    //Liquidation address => total liquidation value, statistical function
    mapping (address => uint256)                   public sin;  // [rad]
        
    // For example, if a user mortgages a certain amount of ETH, a corresponding amount of c77s will be generated, and debt records the total number of issued c77s.
    uint256 public debt;  // Total c77 Issued    [rad]
    //Insolvent debts will use buffer funds to repay debts, reducing vice
    uint256 public vice;  // Total Unbacked c77  [rad]
    // The maximum total number of c77s that the system can lend, the upper limit of the total number of c77s that can be loaned by all collaterals in the system
    uint256 public Line;  // Total Debt Ceiling  [rad]
    uint256 public live;  // Active Flag

    // --- Logs ---
    event LogNote(
        bytes4   indexed  sig,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes32  indexed  arg3,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: the selector and the first three args
            let mark := msize()                       // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
                 shl(224, shr(224, calldataload(0))), // msg.sig
                 calldataload(4),                     // arg1
                 calldataload(36),                    // arg2
                 calldataload(68)                     // arg3
                )
        }
    }

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }
    //Safe math functions to prevent buffer overflow
    // --- Math ---
    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function sub(uint x, int y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function init(bytes32 ilk) external note auth {
        require(ilks[ilk].rate == 0, "Vat/ilk-already-init");
        ilks[ilk].rate = 10 ** 27;
    }
    function file(bytes32 what, uint data) external note auth {
        require(live == 1, "Vat/not-live");
        if (what == "Line") Line = data;
        else revert("Vat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, uint data) external note auth {
        require(live == 1, "Vat/not-live");
        if (what == "spot") ilks[ilk].spot = data;
        else if (what == "line") ilks[ilk].line = data;
        else if (what == "dust") ilks[ilk].dust = data;
        else revert("Vat/file-unrecognized-param");
    }
    function cage() external note auth {
        live = 0;
    }

    // --- Fungibility ---
    //Called when modifying the user's collateral balance and adding more collateral to the locked-in contract of the collateral
    //The first step of lending is a join contract, which is to help keep the coins/tokens.
    //Call the join method, the coins/tokens will be transferred to the join contract address, and then the join contract will call the vat.slip method
    function slip(bytes32 ilk, address usr, int256 wad) external note auth {
        gem[ilk][usr] = add(gem[ilk][usr], wad);
    }
    //Transfer collateral to dst
    //In the auction, ETH is auctioned through c77, then ilk is the id of c77, src is the address of the holder of c77, dst is the address of the flip contract of the auction contract, and wad is the bid amount
    function flux(bytes32 ilk, address src, address dst, uint256 wad) external note {
        require(wish(src, msg.sender), "Vat/not-allowed");
        gem[ilk][src] = sub(gem[ilk][src], wad);
        gem[ilk][dst] = add(gem[ilk][dst], wad);
    }
    //Transfer dst to stable currency c77
    function move(address src, address dst, uint256 rad) external note {
        require(wish(src, msg.sender), "Vat/not-allowed");
        c77[src] = sub(c77[src], rad);
        c77[dst] = add(c77[dst], rad);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- CDP Manipulation ---
    //i ID of the collateral, u cdp owner, v owner of the collateral, w owner of the c77, dink amount of the collateral, the amount of the debt c77 lent by dart
    //Modify the CDP of user u, use the gem of user v, and create c77 for user w
    //When dart<0, it is repaying the loan, that is, redeeming the collateral
    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external note {
        // system is live
        require(live == 1, "Vat/not-live");
        //User u's personal debt
        Urn memory urn = urns[i][u];
        //Mortgage type i
        Ilk memory ilk = ilks[i];
        // ilk has been initialised
        require(ilk.rate != 0, "Vat/ilk-not-init");
        //The user's total amount of collateral
        urn.ink = add(urn.ink, dink);
        //User's loan amount
        urn.art = add(urn.art, dart);
        //Total borrowings that the collateral has been lent
        ilk.Art = add(ilk.Art, dart);
        //This loan plus the cumulative stability fee incurred
        int dtab = mul(ilk.rate, dart);
        //The total debt of this user plus the stability fee incurred
        uint tab = mul(ilk.rate, urn.art);
        //Total system debt
        debt     = add(debt, dtab);
        //When dart<0, it is repaying the loan, that is, redeeming the collateral
        //When the collateral is redeemed or the debt limit has not been reached
        // either debt has decreased, or debt ceilings are not exceeded
        //Each collateral has a loanable limit
        require(either(dart <= 0, both(mul(ilk.Art, ilk.rate) <= ilk.line, debt <= Line)), "Vat/ceiling-exceeded");
        // urn is either less risky than before, or it is safe
        //As the price of the collateral changes, the total debt is less than the value of the collateral at the security price of the collateral
        require(either(both(dart <= 0, dink >= 0), tab <= mul(urn.ink, ilk.spot)), "Vat/not-safe");
    
        // urn is either more safe, or the owner consents
        require(either(both(dart <= 0, dink >= 0), wish(u, msg.sender)), "Vat/not-allowed-u");
        // collateral src consents
        require(either(dink <= 0, wish(v, msg.sender)), "Vat/not-allowed-v");
        // debt dst consents
        require(either(dart >= 0, wish(w, msg.sender)), "Vat/not-allowed-w");

        // urn has no debt, or a non-dusty amount
        require(either(urn.art == 0, tab >= ilk.dust), "Vat/dust");
       //Deduction/redemption of collateral (gem), loan/repayment of c77.
        gem[i][v] = sub(gem[i][v], dink);
        c77[w]    = add(c77[w],    dtab);

        urns[i][u] = urn;
        ilks[i]    = ilk;
    }
    // --- CDP Fungibility ---
    function fork(bytes32 ilk, address src, address dst, int dink, int dart) external note {
        Urn storage u = urns[ilk][src];
        Urn storage v = urns[ilk][dst];
        Ilk storage i = ilks[ilk];

        u.ink = sub(u.ink, dink);
        u.art = sub(u.art, dart);
        v.ink = add(v.ink, dink);
        v.art = add(v.art, dart);

        uint utab = mul(u.art, i.rate);
        uint vtab = mul(v.art, i.rate);

        // both sides consent
        require(both(wish(src, msg.sender), wish(dst, msg.sender)), "Vat/not-allowed");

        // both sides safe
        require(utab <= mul(u.ink, i.spot), "Vat/not-safe-src");
        require(vtab <= mul(v.ink, i.spot), "Vat/not-safe-dst");

        // both sides non-dusty
        require(either(utab >= i.dust, u.art == 0), "Vat/dust-src");
        require(either(vtab >= i.dust, v.art == 0), "Vat/dust-dst");
    }
    // --- CDP Confiscation ---
    //When the market fluctuates sharply, it may become insolvent and trigger liquidation
    //This function is the agent that executes the lowest level of liquidation logic, is responsible for asset status monitoring, and marks dangerous assets. It is another core contract Cat
    function grab(bytes32 i, address u, address v, address w, int dink, int dart) external note auth {
        Urn storage urn = urns[i][u];
        Ilk storage ilk = ilks[i];

        urn.ink = add(urn.ink, dink);
        urn.art = add(urn.art, dart);
        ilk.Art = add(ilk.Art, dart);

        int dtab = mul(ilk.rate, dart);

        gem[i][v] = sub(gem[i][v], dink);
        sin[w]    = sub(sin[w],    dtab);
        vice      = sub(vice,      dtab);
    }

    //Create/destroy an equal amount of stablecoins and system debt
    //Only the Vom contract can be called
    // --- Settlement ---
    function heal(uint rad) external note {
        //u为vow合约地址
        address u = msg.sender;
        sin[u] = sub(sin[u], rad);
        c77[u] = sub(c77[u], rad);
        vice   = sub(vice,   rad);
        debt   = sub(debt,   rad);
    }
    //Debt calculation
    function suck(address u, address v, uint rad) external note auth {
        sin[u] = add(sin[u], rad);
        c77[v] = add(c77[v], rad);
        vice   = add(vice,   rad);
        debt   = add(debt,   rad);
    }
    //Increase/decrease stability costs
    // --- Rates ---
    function fold(bytes32 i, address u, int rate) external note auth {
        require(live == 1, "Vat/not-live");
        Ilk storage ilk = ilks[i];
        ilk.rate = add(ilk.rate, rate);
        int rad  = mul(ilk.Art, rate);
        c77[u]   = add(c77[u], rad);
        debt     = add(debt,   rad);
    }
}