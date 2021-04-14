/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity >=0.5.12;

////// lib/dss-deploy/lib/dss/src/lib.sol
// SPDX-License-Identifier: AGPL-3.0-or-later

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

////// src/join-7.sol
// SPDX-License-Identifier: AGPL-3.0-or-later

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

interface VatLike_16 {
    function slip(bytes32, address, int256) external;
}

interface GemLike_10 {
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

    VatLike_16 public vat;
    bytes32 public ilk;
    GemLike_10 public gem;
    uint256 public dec;
    uint256 public live; // Access flag

    mapping (address => uint256) public implementations;

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        gem = GemLike_10(gem_);
        dec = gem.decimals();
        require(dec < 18, "GemJoin7/decimals-18-or-higher");
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike_16(vat_);
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