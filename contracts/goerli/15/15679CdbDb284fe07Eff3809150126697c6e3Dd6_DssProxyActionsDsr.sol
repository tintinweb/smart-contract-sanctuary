/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// DssProxyActions.sol

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
    function approve(address, uint) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
}

interface ManagerLike {
    function cdpCan(address, uint, address) external view returns (uint);
    function ilks(uint) external view returns (bytes32);
    function owns(uint) external view returns (address);
    function urns(uint) external view returns (address);
    function vat() external view returns (address);
    function open(bytes32, address) external returns (uint);
    function give(uint, address) external;
    function cdpAllow(uint, address, uint) external;
    function urnAllow(address, uint) external;
    function frob(uint, int, int) external;
    function flux(uint, address, uint) external;
    function move(uint, address, uint) external;
    function exit(address, uint, address, uint) external;
    function quit(uint, address) external;
    function enter(address, uint) external;
    function shift(uint, uint) external;
}

interface VatLike {
    function can(address, address) external view returns (uint);
    function ilks(bytes32) external view returns (uint, uint, uint, uint, uint);
    function dai(address) external view returns (uint);
    function urns(bytes32, address) external view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) external;
    function hope(address) external;
    function move(address, address, uint) external;
}

interface GemJoinLike {
    function dec() external returns (uint);
    function gem() external returns (GemLike);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface GNTJoinLike {
    function bags(address) external view returns (address);
    function make(address) external returns (address);
}

interface DaiJoinLike {
    function vat() external returns (VatLike);
    function dai() external returns (GemLike);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

interface HopeLike {
    function hope(address) external;
    function nope(address) external;
}

interface EndLike {
    function fix(bytes32) external view returns (uint);
    function cash(bytes32, uint) external;
    function free(bytes32) external;
    function pack(uint) external;
    function skim(bytes32, address) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint);
}

interface PotLike {
    function pie(address) external view returns (uint);
    function drip() external returns (uint);
    function join(uint) external;
    function exit(uint) external;
}

interface ProxyRegistryLike {
    function proxies(address) external view returns (address);
    function build(address) external returns (address);
}

interface ProxyLike {
    function owner() external view returns (address);
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract Common {
    uint256 constant RAY = 10 ** 27;

    // Internal functions

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    // Public functions

    function daiJoin_join(address apt, address urn, uint wad) public {
        // Gets DAI from the user's wallet
        DaiJoinLike(apt).dai().transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the DAI amount
        DaiJoinLike(apt).dai().approve(apt, wad);
        // Joins DAI into the vat
        DaiJoinLike(apt).join(urn, wad);
    }
}

contract DssProxyActionsDsr is Common {
    function join(
        address daiJoin,
        address pot,
        uint wad
    ) public {
        VatLike vat = DaiJoinLike(daiJoin).vat();
        // Executes drip to get the chi rate updated to rho == now, otherwise join will fail
        uint chi = PotLike(pot).drip();
        // Joins wad amount to the vat balance
        daiJoin_join(daiJoin, address(this), wad);
        // Approves the pot to take out DAI from the proxy's balance in the vat
        if (vat.can(address(this), address(pot)) == 0) {
            vat.hope(pot);
        }
        // Joins the pie value (equivalent to the DAI wad amount) in the pot
        PotLike(pot).join(mul(wad, RAY) / chi);
    }

    function exit(
        address daiJoin,
        address pot,
        uint wad
    ) public {
        VatLike vat = DaiJoinLike(daiJoin).vat();
        // Executes drip to count the savings accumulated until this moment
        uint chi = PotLike(pot).drip();
        // Calculates the pie value in the pot equivalent to the DAI wad amount
        uint pie = mul(wad, RAY) / chi;
        // Exits DAI from the pot
        PotLike(pot).exit(pie);
        // Checks the actual balance of DAI in the vat after the pot exit
        uint bal = DaiJoinLike(daiJoin).vat().dai(address(this));
        // Allows adapter to access to proxy's DAI balance in the vat
        if (vat.can(address(this), address(daiJoin)) == 0) {
            vat.hope(daiJoin);
        }
        // It is necessary to check if due rounding the exact wad amount can be exited by the adapter.
        // Otherwise it will do the maximum DAI balance in the vat
        DaiJoinLike(daiJoin).exit(
            msg.sender,
            bal >= mul(wad, RAY) ? wad : bal / RAY
        );
    }

    function exitAll(
        address daiJoin,
        address pot
    ) public {
        VatLike vat = DaiJoinLike(daiJoin).vat();
        // Executes drip to count the savings accumulated until this moment
        uint chi = PotLike(pot).drip();
        // Gets the total pie belonging to the proxy address
        uint pie = PotLike(pot).pie(address(this));
        // Exits DAI from the pot
        PotLike(pot).exit(pie);
        // Allows adapter to access to proxy's DAI balance in the vat
        if (vat.can(address(this), address(daiJoin)) == 0) {
            vat.hope(daiJoin);
        }
        // Exits the DAI amount corresponding to the value of pie
        DaiJoinLike(daiJoin).exit(msg.sender, mul(chi, pie) / RAY);
    }
}