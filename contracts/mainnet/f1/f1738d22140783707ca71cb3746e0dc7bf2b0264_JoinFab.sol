/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// hevm: flattened sources of src/JoinFab.sol

pragma solidity =0.5.12 >=0.5.12;

////// lib/dss/src/lib.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity >=0.5.12; */

contract LibNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize()                       // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
                 shl(224, shr(224, calldataload(0))), // msg.sig
                 caller(),                            // msg.sender
                 calldataload(4),                     // arg1
                 calldataload(36)                     // arg2
                )
        }
    }
}

////// lib/dss-gem-joins/src/join-5.sol

/// join-5.sol -- Non-standard token adapters

// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.
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

/* pragma solidity >=0.5.12; */

/* import "dss/lib.sol"; */

interface VatLike_1 {
    function slip(bytes32, address, int256) external;
}

interface GemLike_1 {
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// For a token that has a lower precision than 18 and it has decimals (like USDC)

contract GemJoin5 is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike_1 public vat;
    bytes32 public ilk;
    GemLike_1 public gem;
    uint256 public dec;
    uint256 public live;  // Access Flag

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        gem = GemLike_1(gem_);
        dec = gem.decimals();
        require(dec < 18, "GemJoin5/decimals-18-or-higher");
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_1(vat_);
        ilk = ilk_;
    }

    function cage() external note auth {
        live = 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoin5/overflow");
    }

    function join(address urn, uint256 amt) public note {
        require(live == 1, "GemJoin5/not-live");
        uint256 wad = mul(amt, 10 ** (18 - dec));
        require(int256(wad) >= 0, "GemJoin5/overflow");
        vat.slip(ilk, urn, int256(wad));
        require(gem.transferFrom(msg.sender, address(this), amt), "GemJoin5/failed-transfer");
    }

    function exit(address guy, uint256 amt) public note {
        uint256 wad = mul(amt, 10 ** (18 - dec));
        require(int256(wad) >= 0, "GemJoin5/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        require(gem.transfer(guy, amt), "GemJoin5/failed-transfer");
    }
}

////// lib/dss-gem-joins/src/join-auth.sol

/// join-auth.sol -- Non-standard token adapters

// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.
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

/* pragma solidity >=0.5.12; */

/* import "dss/lib.sol"; */

interface VatLike_2 {
    function slip(bytes32, address, int256) external;
}

interface GemLike_2 {
    function decimals() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// For a token that needs restriction on the sources which are able to execute the join function (like SAI through Migration contract)

contract AuthGemJoin is LibNote {
    VatLike_2 public vat;
    bytes32 public ilk;
    GemLike_2 public gem;
    uint256 public dec;
    uint256 public live;  // Access Flag

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) public note auth { wards[usr] = 1; }
    function deny(address usr) public note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1, "AuthGemJoin/non-authed"); _; }

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_2(vat_);
        ilk = ilk_;
        gem = GemLike_2(gem_);
        dec = gem.decimals();
    }

    function cage() external note auth {
        live = 0;
    }

    function join(address usr, uint256 wad) public auth note {
        require(live == 1, "AuthGemJoin/not-live");
        require(int256(wad) >= 0, "AuthGemJoin/overflow");
        vat.slip(ilk, usr, int256(wad));
        require(gem.transferFrom(msg.sender, address(this), wad), "AuthGemJoin/failed-transfer");
    }

    function exit(address usr, uint256 wad) public note {
        require(wad <= 2 ** 255, "AuthGemJoin/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        require(gem.transfer(usr, wad), "AuthGemJoin/failed-transfer");
    }
}

////// lib/dss/src/join.sol

/// join.sol -- Basic token adapters

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

/* pragma solidity >=0.5.12; */

/* import "./lib.sol"; */

interface GemLike_3 {
    function decimals() external view returns (uint);
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
}

interface DSTokenLike {
    function mint(address,uint) external;
    function burn(address,uint) external;
}

interface VatLike_3 {
    function slip(bytes32,address,int) external;
    function move(address,address,uint) external;
}

/*
    Here we provide *adapters* to connect the Vat to arbitrary external
    token implementations, creating a bounded context for the Vat. The
    adapters here are provided as working examples:

      - `GemJoin`: For well behaved ERC20 tokens, with simple transfer
                   semantics.

      - `ETHJoin`: For native Ether.

      - `DaiJoin`: For connecting internal Dai balances to an external
                   `DSToken` implementation.

    In practice, adapter implementations will be varied and specific to
    individual collateral types, accounting for different transfer
    semantics and token standards.

    Adapters need to implement two basic methods:

      - `join`: enter collateral into the system
      - `exit`: remove collateral from the system

*/

contract GemJoin is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "GemJoin/not-authorized");
        _;
    }

    VatLike_3 public vat;   // CDP Engine
    bytes32 public ilk;   // Collateral Type
    GemLike_3 public gem;
    uint    public dec;
    uint    public live;  // Active Flag

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_3(vat_);
        ilk = ilk_;
        gem = GemLike_3(gem_);
        dec = gem.decimals();
    }
    function cage() external note auth {
        live = 0;
    }
    function join(address usr, uint wad) external note {
        require(live == 1, "GemJoin/not-live");
        require(int(wad) >= 0, "GemJoin/overflow");
        vat.slip(ilk, usr, int(wad));
        require(gem.transferFrom(msg.sender, address(this), wad), "GemJoin/failed-transfer");
    }
    function exit(address usr, uint wad) external note {
        require(wad <= 2 ** 255, "GemJoin/overflow");
        vat.slip(ilk, msg.sender, -int(wad));
        require(gem.transfer(usr, wad), "GemJoin/failed-transfer");
    }
}

contract DaiJoin is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "DaiJoin/not-authorized");
        _;
    }

    VatLike_3 public vat;      // CDP Engine
    DSTokenLike public dai;  // Stablecoin Token
    uint    public live;     // Active Flag

    constructor(address vat_, address dai_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_3(vat_);
        dai = DSTokenLike(dai_);
    }
    function cage() external note auth {
        live = 0;
    }
    uint constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function join(address usr, uint wad) external note {
        vat.move(address(this), usr, mul(ONE, wad));
        dai.burn(msg.sender, wad);
    }
    function exit(address usr, uint wad) external note {
        require(live == 1, "DaiJoin/not-live");
        vat.move(msg.sender, address(this), mul(ONE, wad));
        dai.mint(usr, wad);
    }
}

////// src/JoinFab.sol
// Copyright (C) 2021 Dai Foundation
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
/* pragma solidity 0.5.12; */

/* import {GemJoin}        from "dss/join.sol"; */
/* import {GemJoin5}       from "dss-gem-joins/join-5.sol"; */
/* import {AuthGemJoin}    from "dss-gem-joins/join-auth.sol"; */

contract GemJoinFab {
    // GemJoin
    // Standard ERC-20 Join Adapter
    function newGemJoin(address _vat, address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = address(new GemJoin(_vat, _ilk, _gem));
        GemJoin(join).rely(_owner);
        GemJoin(join).deny(address(this));
    }
}

contract GemJoin5Fab {
    // GemJoin5
    // For a token that has a lower precision than 18 and it has decimals (like USDC)
    function newGemJoin5(address _vat, address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = address(new GemJoin5(_vat, _ilk, _gem));
        GemJoin(join).rely(_owner);
        GemJoin(join).deny(address(this));
    }
}

contract AuthGemJoinFab {
    // AuthGemJoin
    // For a token that needs restriction on the sources which are able to execute the join function (like SAI through Migration contract)
    function newAuthGemJoin(address _vat, address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = address(new AuthGemJoin(_vat, _ilk, _gem));
        GemJoin(join).rely(_owner);
        GemJoin(join).deny(address(this));
    }
}

contract JoinFab {

    address public vat;

    GemJoinFab     gemJoinFab;
    GemJoin5Fab    gemJoin5Fab;
    AuthGemJoinFab authGemJoinFab;

    // Emit the join address and the calldata used to create it
    event NewJoin(address indexed join, bytes data);

    constructor(address _vat) public {
        vat            = _vat;
        gemJoinFab     = new GemJoinFab();
        gemJoin5Fab    = new GemJoin5Fab();
        authGemJoinFab = new AuthGemJoinFab();
    }

    function newGemJoin(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = gemJoinFab.newGemJoin(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }

    function newGemJoin5(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = gemJoin5Fab.newGemJoin5(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }

    function newAuthGemJoin(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = authGemJoinFab.newAuthGemJoin(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }
}