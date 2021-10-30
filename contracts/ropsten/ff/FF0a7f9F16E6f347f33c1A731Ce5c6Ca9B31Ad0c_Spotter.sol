// SPDX-License-Identifier: AGPL-3.0-or-later

/// spot.sol -- Spotter

pragma solidity >=0.5.12;

import "./lib.sol";

interface VatLike {
    function file(bytes32, bytes32, uint) external;
}
//Price feed interface of oracle machine
interface PipLike {
    function peek() external returns (bytes32, bool);
}
//The Spot contract is a direct interface between the oracle machine and the core module vat, which feeds prices to the collateral
contract Spotter is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external note auth { wards[guy] = 1;  }
    function deny(address guy) external note auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Spotter/not-authorized");
        _;
    }

    // --- Data ---
    //Given collateral type
    struct Ilk {
        //Feed price, feed price through the oracle machine
        PipLike pip;  // Price Feed
        //Mortgage rate
        uint256 mat;  // Liquidation ratio [ray]
    }

    mapping (bytes32 => Ilk) public ilks;

    //Mortgage vat
    VatLike public vat;  // CDP Engine
    //The price of c77, the standard anchor is $1
    uint256 public par;  // ref per c77 [ray]
    //1 means the system is operating normally
    uint256 public live;

    // --- Events ---
    event Poke(
      bytes32 ilk,
      bytes32 val,  // [wad]
      uint256 spot  // [ray]
    );

    // --- Init ---
    //The address of the core vat contract needs to be passed in during initialization
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        par = ONE;
        live = 1;
    }

    // --- Math ---
    uint constant ONE = 10 ** 27;
    //Divide check for upper and lower overflow
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, ONE) / y;
    }

    // --- Administration ---
    function file(bytes32 ilk, bytes32 what, address pip_) external note auth {
        require(live == 1, "Spotter/not-live");
        if (what == "pip") ilks[ilk].pip = PipLike(pip_);
        else revert("Spotter/file-unrecognized-param");
    }
    function file(bytes32 what, uint data) external note auth {
        require(live == 1, "Spotter/not-live");
        if (what == "par") par = data;
        else revert("Spotter/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, uint data) external note auth {
        require(live == 1, "Spotter/not-live");
        if (what == "mat") ilks[ilk].mat = data;
        else revert("Spotter/file-unrecognized-param");
    }

    // --- Update value ---
    function poke(bytes32 ilk) external {
        //Call the price feed module in OSM to get the price, return the price and the bool value, and then make the following call if it is true
        (bytes32 val, bool has) = ilks[ilk].pip.peek();
        //After obtaining the price, convert to get the maximum loan amount
        uint256 spot = has ? rdiv(rdiv(mul(uint(val), 10 ** 9), par), ilks[ilk].mat) : 0;
        //Real-time update of the maximum mortgage amount corresponding to the mortgage rate of the current mortgage price
        vat.file(ilk, "spot", spot);
        emit Poke(ilk, val, spot);
    }

    function cage() external note auth {
        live = 0;
    }
}