/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// join-8-auth.sol -- Non-standard token adapters

// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity ^0.6.12;

interface VatLike {
    function slip(bytes32, address, int256) external;
}

interface GemLike {
    function decimals() external view returns (uint8);
    function transfer(address,uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function erc20Impl() external view returns (address);
}

// AuthGemJoin8
// For a token that has a lower precision than 18, has decimals and it is upgradable (like GUSD)

contract AuthGemJoin8 {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike public immutable vat;
    bytes32 public immutable ilk;
    GemLike public immutable gem;
    uint256 public immutable dec;
    uint256 public live;  // Access Flag

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Cage();
    event Join(address indexed urn, uint256 amt, address indexed msgSender);
    event Exit(address indexed usr, uint256 amt);
    event SetImplementation(address indexed implementation, uint256 permitted);

    mapping (address => uint256) public implementations;

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        gem = GemLike(gem_);
        uint256 dec_ = dec = GemLike(gem_).decimals();
        require(dec_ < 18, "AuthGemJoin8/decimals-18-or-higher");
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        live = 1;
        setImplementation(GemLike(gem_).erc20Impl(), 1);
        vat = VatLike(vat_);
        ilk = ilk_;
    }

    function cage() external auth {
        live = 0;
        emit Cage();
    }

    function setImplementation(address implementation, uint256 permitted) public auth {
        implementations[implementation] = permitted;  // 1 live, 0 disable
        emit SetImplementation(implementation, permitted);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "AuthGemJoin8/overflow");
    }

    function join(address urn, uint256 amt, address msgSender) external auth {
        require(live == 1, "AuthGemJoin8/not-live");
        uint256 wad = mul(amt, 10 ** (18 - dec));
        require(int256(wad) >= 0, "AuthGemJoin8/overflow");
        require(implementations[gem.erc20Impl()] == 1, "AuthGemJoin8/implementation-invalid");
        vat.slip(ilk, urn, int256(wad));
        require(gem.transferFrom(msgSender, address(this), amt), "AuthGemJoin8/failed-transfer");
        emit Join(urn, amt, msgSender);
    }

    function exit(address usr, uint256 amt) external {
        uint256 wad = mul(amt, 10 ** (18 - dec));
        require(int256(wad) >= 0, "AuthGemJoin8/overflow");
        require(implementations[gem.erc20Impl()] == 1, "AuthGemJoin8/implementation-invalid");
        vat.slip(ilk, msg.sender, -int256(wad));
        require(gem.transfer(usr, amt), "AuthGemJoin8/failed-transfer");
        emit Exit(usr, amt);
    }
}