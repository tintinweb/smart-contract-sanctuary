/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// hevm: flattened sources of src/JoinFab.sol
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

////// lib/dss-gem-joins/src/join-2.sol

/// join-2.sol -- Non-standard token adapters

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
    function decimals() external view returns (uint256);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

// For a token that does not return a bool on transfer or transferFrom (like OMG)
// This is one way of doing it. Check the balances before and after calling a transfer

contract GemJoin2 is LibNote {
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
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_1(vat_);
        ilk = ilk_;
        gem = GemLike_1(gem_);
        dec = gem.decimals();
    }

    function cage() external note auth {
        live = 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoin2/overflow");
    }

    function join(address urn, uint256 wad) public note {
        require(live == 1, "GemJoin2/not-live");
        require(wad <= 2 ** 255, "GemJoin2/overflow");
        vat.slip(ilk, urn, int256(wad));
        uint256 prevBalance = gem.balanceOf(msg.sender);

        require(prevBalance >= wad, "GemJoin2/no-funds");
        require(gem.allowance(msg.sender, address(this)) >= wad, "GemJoin2/no-allowance");

        (bool ok,) = address(gem).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), wad)
        );
        require(ok, "GemJoin2/failed-transfer");

        require(prevBalance - wad == gem.balanceOf(msg.sender), "GemJoin2/failed-transfer");
    }

    function exit(address guy, uint256 wad) public note {
        require(wad <= 2 ** 255, "GemJoin2/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        uint256 prevBalance = gem.balanceOf(address(this));

        require(prevBalance >= wad, "GemJoin2/no-funds");

        (bool ok,) = address(gem).call(
            abi.encodeWithSignature("transfer(address,uint256)", guy, wad)
        );
        require(ok, "GemJoin2/failed-transfer");

        require(prevBalance - wad == gem.balanceOf(address(this)), "GemJoin2/failed-transfer");
    }
}

////// lib/dss-gem-joins/src/join-3.sol

/// join-3.sol -- Non-standard token adapters

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
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// For a token that has a lower precision than 18 and doesn't have decimals field in place (like DGD)

contract GemJoin3 is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike_2 public vat;
    bytes32 public ilk;
    GemLike_2 public gem;
    uint256 public dec;
    uint256 public live;  // Access Flag

    constructor(address vat_, bytes32 ilk_, address gem_, uint256 decimals) public {
        require(decimals < 18, "GemJoin3/decimals-18-or-higher");
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_2(vat_);
        ilk = ilk_;
        gem = GemLike_2(gem_);
        dec = decimals;
    }

    function cage() external note auth {
        live = 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoin3/overflow");
    }

    function join(address urn, uint256 amt) public note {
        require(live == 1, "GemJoin3/not-live");
        uint256 wad = mul(amt, 10 ** (18 - dec));
        require(wad <= 2 ** 255, "GemJoin3/overflow");
        vat.slip(ilk, urn, int256(wad));
        require(gem.transferFrom(msg.sender, address(this), amt), "GemJoin3/failed-transfer");
    }

    function exit(address guy, uint256 amt) public note {
        uint256 wad = mul(amt, 10 ** (18 - dec));
        require(wad <= 2 ** 255, "GemJoin3/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        require(gem.transfer(guy, amt), "GemJoin3/failed-transfer");
    }
}

////// lib/dss-gem-joins/src/join-4.sol

/// join-4.sol -- Non-standard token adapters

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

interface VatLike_3 {
    function slip(bytes32, address, int256) external;
}

interface GemLike_3 {
    function decimals() external view returns (uint256);
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

// For tokens that do not implement transferFrom (like GNT), meaning the usual adapter
// approach won't work: the adapter cannot call transferFrom and therefore
// has no way of knowing when users deposit gems into it.

// To work around this, we introduce the concept of a bag, which is a trusted
// (it's created by the adapter), personalized component (one for each user).

// Users first have to create their bag with `GemJoin4.make`, then transfer
// gem to it, and then call `GemJoin4.join`, which transfer the gems from the
// bag to the adapter.

contract GemBag {
    address public ada;
    address public lad;
    GemLike_3 public gem;

    constructor(address lad_, address gem_) public {
        ada = msg.sender;
        lad = lad_;
        gem = GemLike_3(gem_);
    }

    function exit(address usr, uint256 wad) external {
        require(msg.sender == ada || msg.sender == lad, "GemBag/invalid-caller");
        require(gem.transfer(usr, wad), "GemBag/failed-transfer");
    }
}

contract GemJoin4 is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike_3 public vat;
    bytes32 public ilk;
    GemLike_3 public gem;
    uint256 public dec;
    uint256 public live;  // Access Flag

    mapping(address => address) public bags;

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

    // -- admin --
    function make() external returns (address bag) {
        bag = make(msg.sender);
    }

    function make(address usr) public note returns (address bag) {
        require(bags[usr] == address(0), "GemJoin4/bag-already-exists");

        bag = address(new GemBag(address(usr), address(gem)));
        bags[usr] = bag;
    }

    // -- gems --
    function join(address urn, uint256 wad) external note {
        require(live == 1, "GemJoin4/not-live");
        require(int256(wad) >= 0, "GemJoin4/negative-amount");

        GemBag(bags[msg.sender]).exit(address(this), wad);
        vat.slip(ilk, urn, int256(wad));
    }

    function exit(address usr, uint256 wad) external note {
        require(int256(wad) >= 0, "GemJoin4/negative-amount");

        vat.slip(ilk, msg.sender, -int256(wad));
        require(gem.transfer(usr, wad), "GemJoin4/failed-transfer");
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

interface VatLike_4 {
    function slip(bytes32, address, int256) external;
}

interface GemLike_4 {
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

    VatLike_4 public vat;
    bytes32 public ilk;
    GemLike_4 public gem;
    uint256 public dec;
    uint256 public live;  // Access Flag

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        gem = GemLike_4(gem_);
        dec = gem.decimals();
        require(dec < 18, "GemJoin5/decimals-18-or-higher");
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_4(vat_);
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

////// lib/dss-gem-joins/src/join-6.sol

/// join-6.sol -- Non-standard token adapters

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

interface VatLike_5 {
    function slip(bytes32, address, int256) external;
}

interface GemLike_5 {
    function decimals() external view returns (uint256);
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function implementation() external view returns (address);
}

// For a token with a proxy and implementation contract (like tUSD)
//  If the implementation behind the proxy is changed, this prevents joins
//   and exits until the implementation is reviewed and approved by governance.

contract GemJoin6 is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "GemJoin6/not-authorized");
        _;
    }

    VatLike_5 public vat;
    bytes32 public ilk;
    GemLike_5 public gem;
    uint256 public dec;
    uint256 public live;  // Access Flag

    mapping (address => uint256) public implementations;

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_5(vat_);
        ilk = ilk_;
        gem = GemLike_5(gem_);
        setImplementation(gem.implementation(), 1);
        dec = gem.decimals();
    }
    function cage() external note auth {
        live = 0;
    }
    function setImplementation(address implementation, uint256 permitted) public auth note {
        implementations[implementation] = permitted;  // 1 live, 0 disable
    }
    function join(address usr, uint256 wad) external note {
        require(live == 1, "GemJoin6/not-live");
        require(int256(wad) >= 0, "GemJoin6/overflow");
        require(implementations[gem.implementation()] == 1, "GemJoin6/implementation-invalid");
        vat.slip(ilk, usr, int256(wad));
        require(gem.transferFrom(msg.sender, address(this), wad), "GemJoin6/failed-transfer");
    }
    function exit(address usr, uint256 wad) external note {
        require(wad <= 2 ** 255, "GemJoin6/overflow");
        require(implementations[gem.implementation()] == 1, "GemJoin6/implementation-invalid");
        vat.slip(ilk, msg.sender, -int256(wad));
        require(gem.transfer(usr, wad), "GemJoin6/failed-transfer");
    }
}

////// lib/dss-gem-joins/src/join-7.sol

/// join-7.sol -- Non-standard token adapters

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

interface VatLike_6 {
    function slip(bytes32, address, int256) external;
}

interface GemLike_6 {
    function decimals() external view returns (uint256);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function upgradedAddress() external view returns (address);
    function setImplementation(address, uint256) external;
    function adjustFee(uint256) external;
}

// GemJoin7
// For an upgradable token (like USDT) which doesn't return bool on transfers and may charge fees
//  If the token is deprecated changing the implementation behind, this prevents joins
//   and exits until the implementation is reviewed and approved by governance.

contract GemJoin7 is LibNote {
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike_6 public vat;
    bytes32 public ilk;
    GemLike_6 public gem;
    uint256 public dec;
    uint256 public live; // Access flag

    mapping (address => uint256) public implementations;

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        gem = GemLike_6(gem_);
        dec = gem.decimals();
        require(dec < 18, "GemJoin7/decimals-18-or-higher");
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_6(vat_);
        ilk = ilk_;
        setImplementation(address(gem.upgradedAddress()), 1);
    }

    function cage() external note auth {
        live = 0;
    }

    function setImplementation(address implementation, uint256 permitted) public auth note {
        implementations[implementation] = permitted; // 1 live, 0 disable
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoin7/overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "GemJoin7/underflow");
    }

    function join(address urn, uint256 amt) public note {
        require(live == 1, "GemJoin7/not-live");
        require(implementations[gem.upgradedAddress()] == 1, "GemJoin7/implementation-invalid");
        uint256 bal = gem.balanceOf(address(this));
        gem.transferFrom(msg.sender, address(this), amt);
        uint256 wad = mul(sub(gem.balanceOf(address(this)), bal), 10 ** (18 - dec));
        require(int256(wad) >= 0, "GemJoin7/overflow");
        vat.slip(ilk, urn, int256(wad));
    }

    function exit(address guy, uint256 amt) public note {
        uint256 wad = mul(amt, 10 ** (18 - dec));
        require(int256(wad) >= 0, "GemJoin7/overflow");
        require(implementations[gem.upgradedAddress()] == 1, "GemJoin7/implementation-invalid");
        vat.slip(ilk, msg.sender, -int256(wad));
        gem.transfer(guy, amt);
    }
}

////// lib/dss-gem-joins/src/join-8.sol

/// join-8.sol -- Non-standard token adapters

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

interface VatLike_7 {
    function slip(bytes32, address, int256) external;
}

interface GemLike_7 {
    function decimals() external view returns (uint8);
    function transfer(address,uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function erc20Impl() external view returns (address);
}

// GemJoin8
// For a token that has a lower precision than 18, has decimals and it is upgradable (like GUSD)

contract GemJoin8 is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike_7  public vat;
    bytes32  public ilk;
    GemLike_7  public gem;
    uint256  public dec;
    uint256  public live;  // Access Flag

    mapping (address => uint256) public implementations;

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        gem = GemLike_7(gem_);
        dec = gem.decimals();
        require(dec < 18, "GemJoin8/decimals-18-or-higher");
        wards[msg.sender] = 1;
        live = 1;
        setImplementation(gem.erc20Impl(), 1);
        vat = VatLike_7(vat_);
        ilk = ilk_;
    }

    function cage() external note auth {
        live = 0;
    }

    function setImplementation(address implementation, uint256 permitted) public auth note {
        implementations[implementation] = permitted;  // 1 live, 0 disable
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoin8/overflow");
    }

    function join(address urn, uint256 amt) public note {
        require(live == 1, "GemJoin8/not-live");
        uint256 wad = mul(amt, 10 ** (18 - dec));
        require(int256(wad) >= 0, "GemJoin8/overflow");
        require(implementations[gem.erc20Impl()] == 1, "GemJoin8/implementation-invalid");
        vat.slip(ilk, urn, int256(wad));
        require(gem.transferFrom(msg.sender, address(this), amt), "GemJoin8/failed-transfer");
    }

    function exit(address guy, uint256 amt) public note {
        uint256 wad = mul(amt, 10 ** (18 - dec));
        require(int256(wad) >= 0, "GemJoin8/overflow");
        require(implementations[gem.erc20Impl()] == 1, "GemJoin8/implementation-invalid");
        vat.slip(ilk, msg.sender, -int256(wad));
        require(gem.transfer(guy, amt), "GemJoin8/failed-transfer");
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

interface VatLike_8 {
    function slip(bytes32, address, int256) external;
}

interface GemLike_8 {
    function decimals() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// For a token that needs restriction on the sources which are able to execute the join function (like SAI through Migration contract)

contract AuthGemJoin is LibNote {
    VatLike_8 public vat;
    bytes32 public ilk;
    GemLike_8 public gem;
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
        vat = VatLike_8(vat_);
        ilk = ilk_;
        gem = GemLike_8(gem_);
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

interface GemLike_9 {
    function decimals() external view returns (uint);
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
}

interface DSTokenLike {
    function mint(address,uint) external;
    function burn(address,uint) external;
}

interface VatLike_9 {
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

    VatLike_9 public vat;   // CDP Engine
    bytes32 public ilk;   // Collateral Type
    GemLike_9 public gem;
    uint    public dec;
    uint    public live;  // Active Flag

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_9(vat_);
        ilk = ilk_;
        gem = GemLike_9(gem_);
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

    VatLike_9 public vat;      // CDP Engine
    DSTokenLike public dai;  // Stablecoin Token
    uint    public live;     // Active Flag

    constructor(address vat_, address dai_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_9(vat_);
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
/* import {GemJoin2}       from "dss-gem-joins/join-2.sol"; */
/* import {GemJoin3}       from "dss-gem-joins/join-3.sol"; */
/* import {GemJoin4}       from "dss-gem-joins/join-4.sol"; */
/* import {GemJoin5}       from "dss-gem-joins/join-5.sol"; */
/* import {GemJoin6}       from "dss-gem-joins/join-6.sol"; */
/* import {GemJoin7}       from "dss-gem-joins/join-7.sol"; */
/* import {GemJoin8}       from "dss-gem-joins/join-8.sol"; */
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

contract GemJoin2Fab {
    // GemJoin2
    // For a token that does not return a bool on transfer or transferFrom (like OMG)
    // This is one way of doing it. Check the balances before and after calling a transfer
    function newGemJoin2(address _vat, address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = address(new GemJoin2(_vat, _ilk, _gem));
        GemJoin(join).rely(_owner);
        GemJoin(join).deny(address(this));
    }
}

contract GemJoin3Fab {
    // GemJoin3
    // For a token that has a lower precision than 18 and doesn't have decimals field in place (like DGD)
    function newGemJoin3(address _vat, address _owner, bytes32 _ilk, address _gem, uint256 _dec) external returns (address join) {
        join = address(new GemJoin3(_vat, _ilk, _gem, _dec));
        GemJoin(join).rely(_owner);
        GemJoin(join).deny(address(this));
    }
}

contract GemJoin4Fab {
    // GemJoin4
    // For tokens that do not implement transferFrom (like GNT), meaning the usual adapter
    // approach won't work: the adapter cannot call transferFrom and therefore
    // has no way of knowing when users deposit gems into it.
    //
    // To work around this, we introduce the concept of a bag, which is a trusted
    // (it's created by the adapter), personalized component (one for each user).
    //
    // Users first have to create their bag with `GemJoin4.make`, then transfer
    // gem to it, and then call `GemJoin4.join`, which transfer the gems from the
    // bag to the adapter.
    function newGemJoin4(address _vat, address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = address(new GemJoin4(_vat, _ilk, _gem));
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

contract GemJoin6Fab {
    // GemJoin6
    // For a token with a proxy and implementation contract (like tUSD)
    //  If the implementation behind the proxy is changed, this prevents joins
    //   and exits until the implementation is reviewed and approved by governance.
    function newGemJoin6(address _vat, address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = address(new GemJoin6(_vat, _ilk, _gem));
        GemJoin(join).rely(_owner);
        GemJoin(join).deny(address(this));
    }
}

contract GemJoin7Fab {
    // GemJoin7
    // For an upgradable token (like USDT) which doesn't return bool on transfers and may charge fees
    //  If the token is deprecated changing the implementation behind, this prevents joins
    //   and exits until the implementation is reviewed and approved by governance.
    function newGemJoin7(address _vat, address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = address(new GemJoin7(_vat, _ilk, _gem));
        GemJoin(join).rely(_owner);
        GemJoin(join).deny(address(this));
    }
}

contract GemJoin8Fab {
    // GemJoin8
    // For a token that has a lower precision than 18, has decimals and it is upgradable (like GUSD)
    function newGemJoin8(address _vat, address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = address(new GemJoin8(_vat, _ilk, _gem));
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
    GemJoin2Fab    gemJoin2Fab;
    GemJoin3Fab    gemJoin3Fab;
    GemJoin4Fab    gemJoin4Fab;
    GemJoin5Fab    gemJoin5Fab;
    GemJoin6Fab    gemJoin6Fab;
    GemJoin7Fab    gemJoin7Fab;
    GemJoin8Fab    gemJoin8Fab;
    AuthGemJoinFab authGemJoinFab;

    // Emit the join address and the calldata used to create it
    event NewJoin(address indexed join, bytes data);

    constructor(address _vat) public {
        vat            = _vat;
        gemJoinFab     = new GemJoinFab();
        gemJoin2Fab    = new GemJoin2Fab();
        gemJoin3Fab    = new GemJoin3Fab();
        gemJoin4Fab    = new GemJoin4Fab();
        gemJoin5Fab    = new GemJoin5Fab();
        gemJoin6Fab    = new GemJoin6Fab();
        gemJoin7Fab    = new GemJoin7Fab();
        gemJoin8Fab    = new GemJoin8Fab();
        authGemJoinFab = new AuthGemJoinFab();
    }

    function newGemJoin(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = gemJoinFab.newGemJoin(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }

    function newGemJoin2(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = gemJoin2Fab.newGemJoin2(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }

    function newGemJoin3(address _owner, bytes32 _ilk, address _gem, uint256 _dec) external returns (address join) {
        join = gemJoin3Fab.newGemJoin3(vat, _owner, _ilk, _gem, _dec);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem, _dec));
    }

    function newGemJoin4(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = gemJoin4Fab.newGemJoin4(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }

    function newGemJoin5(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = gemJoin5Fab.newGemJoin5(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }

    function newGemJoin6(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = gemJoin6Fab.newGemJoin6(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }

    function newGemJoin7(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = gemJoin7Fab.newGemJoin7(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }

    function newGemJoin8(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = gemJoin8Fab.newGemJoin8(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }

    function newAuthGemJoin(address _owner, bytes32 _ilk, address _gem) external returns (address join) {
        join = authGemJoinFab.newAuthGemJoin(vat, _owner, _ilk, _gem);
        emit NewJoin(join, abi.encode(vat, _ilk, _gem));
    }
}