// SPDX-License-Identifier: AGPL-3.0-or-later

/// pot.sol -- c77 Savings Rate

pragma solidity >=0.5.12;

import "./lib.sol";

/*
   "Savings c77" is obtained when c77 is deposited into
   this contract. Each "Savings c77" accrues c77 interest
   at the "c77 Savings Rate".

   This contract does not implement a user tradeable token
   and is intended to be used with adapters.

         --- `save` your `c77` in the `pot` ---

   - `dsr`: the c77 Savings Rate
   - `pie`: user balance of Savings c77

   - `join`: start saving some c77
   - `exit`: remove some c77
   - `drip`: perform rate collection

*/

interface VatLike {
    function move(address,address,uint256) external;
    function suck(address,address,uint256) external;
}
//Pot is the core of the savings rate (DSR). It allows users to deposit c77 and activate the c77 savings rate, and earn savings on c77.
//DSR is governed by the manufacturer and is usually lower than the basic stability fee to maintain sustainability. The purpose of Pot is to provide another incentive for holding c77.

//Users need not call drip() before exit, then they will not be able to get the full amount earned during the deposit period.

//If the user wants to join and exit to pot 10c77, then send wad=10/chi, and the balance you transfer to the pot is 10/chi.

//If C77V votes to set the dsr to a very high rate, it may cause the system to be too expensive.
//In addition, if governance allows dsr (significantly) to exceed system fees (exceeding the mortgage rate), it will lead to increased debt and increased Flop auctions.
contract Pot is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external note auth { wards[guy] = 1; }
    function deny(address guy) external note auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Pot/not-authorized");
        _;
    }

    // --- Data ---
    //Deposit the pot balance
    mapping (address => uint256) public pie;  // Normalised Savings c77 [wad]
    //The total balance in the storage warehouse
    uint256 public Pie;   // Total Normalised Savings c77  [wad]
    //The storage rate of c77, initialized to 1 (10**27), updated by voting
    uint256 public dsr;   // The c77 Savings Rate          [ray]
    //Determines how much c77 storage fee is given in drip
    uint256 public chi;   // The Rate Accumulator          [ray]

    VatLike public vat;   // CDP Engine
    address public vow;   // Debt Engine
    //The last time to call the drip
    uint256 public rho;   // Time of last drip     [unix epoch time]

    uint256 public live;  // Active Flag

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        dsr = ONE;
        chi = ONE;
        rho = now;
        live = 1;
    }

    // --- Math ---
    //x**n
    uint256 constant ONE = 10 ** 27;
    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
    //Prevent up and down overflow
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / ONE;
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
    function file(bytes32 what, uint256 data) external note auth {
        require(live == 1, "Pot/not-live");
        require(now == rho, "Pot/rho-not-updated");
        if (what == "dsr") dsr = data;
        else revert("Pot/file-unrecognized-param");
    }

    function file(bytes32 what, address addr) external note auth {
        if (what == "vow") vow = addr;
        else revert("Pot/file-unrecognized-param");
    }

    function cage() external note auth {
        live = 0;
        dsr = ONE;
    }

    // --- Savings Rate Accumulation ---
    //Called before join and exit, calculate the final deposit amount through chi and dsr
    function drip() external note returns (uint tmp) {
        require(now >= rho, "Pot/invalid-now");
        tmp = rmul(rpow(dsr, now - rho, ONE), chi);
        uint chi_ = sub(tmp, chi);
        chi = tmp;
        rho = now;
        vat.suck(address(vow), address(this), mul(Pie, chi_));
    }

    // --- Savings c77 Management ---
    function join(uint wad) external note {
        require(now == rho, "Pot/rho-not-updated");
        pie[msg.sender] = add(pie[msg.sender], wad);
        Pie             = add(Pie,             wad);
        vat.move(msg.sender, address(this), mul(chi, wad));
    }

    function exit(uint wad) external note {
        pie[msg.sender] = sub(pie[msg.sender], wad);
        Pie             = sub(Pie,             wad);
        vat.move(address(this), msg.sender, mul(chi, wad));
    }
}