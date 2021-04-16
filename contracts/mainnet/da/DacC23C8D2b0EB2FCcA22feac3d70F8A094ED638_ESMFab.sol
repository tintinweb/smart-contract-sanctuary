/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// DssDeploy.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

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

pragma solidity >=0.5.12;

interface GemLike {
    function balanceOf(address) external view returns (uint256);
    function burn(uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface EndLike {
    function live() external view returns (uint256);
    function vat()  external view returns (address);
    function cage() external;
}

interface DenyLike {
    function deny(address) external;
}

contract ESM {
    GemLike public immutable gem;   // collateral (MKR token)
    EndLike public immutable end;   // cage module
    address public immutable proxy; // Pause proxy
    uint256 public immutable min;   // minimum activation threshold [wad]

    mapping(address => uint256) public sum; // per-address balance
    uint256 public Sum; // total balance

    event Fire();
    event Join(address indexed usr, uint256 wad);

    constructor(address gem_, address end_, address proxy_, uint256 min_) public {
        gem = GemLike(gem_);
        end = EndLike(end_);
        proxy = proxy_;
        min = min_;
    }

    function revokesGovernanceAccess() external view returns (bool ret) {
        ret = proxy != address(0);
    }

    // -- math --
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    function fire() external {
        require(Sum >= min,  "ESM/min-not-reached");

        if (proxy != address(0)) {
            DenyLike(end.vat()).deny(proxy);
        }
        end.cage();

        emit Fire();
    }

    function deny(address target) external {
        require(Sum >= min,  "ESM/min-not-reached");

        DenyLike(target).deny(proxy);
    }

    function join(uint256 wad) external {
        require(end.live() == 1, "ESM/system-already-shutdown");

        sum[msg.sender] = add(sum[msg.sender], wad);
        Sum = add(Sum, wad);

        require(gem.transferFrom(msg.sender, address(this), wad), "ESM/transfer-failed");
        emit Join(msg.sender, wad);
    }

    function burn() external {
        gem.burn(gem.balanceOf(address(this)));
    }
}


contract ESMFab {
    function newESM(address gov, address end, address proxy, uint min) public returns (ESM esm) {
        esm = new ESM(gov, end, proxy, min);
    }
}