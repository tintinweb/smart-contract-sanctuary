/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// hevm: flattened sources of src/DssProxyActionsCharter.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12;

////// src/DssProxyActionsCharter.sol

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

/* pragma solidity 0.6.12; */

interface GemLike_8 {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface CharterLike {
    function getOrCreateProxy(address) external returns (address);
    function join(address, address, uint256) external;
    function exit(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function quit(bytes32 ilk, address dst) external;
    function gate(bytes32) external view returns (uint256);
    function Nib(bytes32) external view returns (uint256);
    function nib(bytes32, address) external view returns (uint256);
}

interface VatLike_17 {
    function can(address, address) external view returns (uint256);
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function dai(address) external view returns (uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function hope(address) external;
    function nope(address) external;
    function flux(bytes32, address, address, uint256) external;
}

interface GemJoinLike_2 {
    function dec() external returns (uint256);
    function gem() external returns (GemLike_8);
    function ilk() external returns (bytes32);
}

interface DaiJoinLike {
    function dai() external returns (GemLike_8);
    function join(address, uint256) external payable;
    function exit(address, uint256) external;
}

interface EndLike_3 {
    function fix(bytes32) external view returns (uint256);
    function cash(bytes32, uint256) external;
    function free(bytes32) external;
    function pack(uint256) external;
    function skim(bytes32, address) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint256);
}

interface HopeLike_2 {
    function hope(address) external;
    function nope(address) external;
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract Common {
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    address immutable public vat;
    address immutable public charter;

    constructor(address vat_, address charter_) public {
        vat = vat_;
        charter = charter_;
    }

    // Internal functions

    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    // Public functions

    function daiJoin_join(address daiJoin, uint256 wad) public {
        GemLike_8 dai = DaiJoinLike(daiJoin).dai();
        // Gets DAI from the user's wallet
        dai.transferFrom(msg.sender, address(this), wad);
        // Approves adapter to take the DAI amount
        dai.approve(daiJoin, wad);
        // Joins DAI into the vat
        DaiJoinLike(daiJoin).join(address(this), wad);
    }
}


contract DssProxyActionsEndCharter is Common {

    constructor(address vat_, address charter_) public Common(vat_, charter_) {}

    // Internal functions

    function _free(
        address end,
        bytes32 ilk
    ) internal returns (uint256 ink) {
        address urp = CharterLike(charter).getOrCreateProxy(address(this));
        uint256 art;
        (ink, art) = VatLike_17(vat).urns(ilk, urp);

        // If CDP still has debt, it needs to be paid
        if (art > 0) {
            EndLike_3(end).skim(ilk, urp);
            (ink,) = VatLike_17(vat).urns(ilk, urp);
        }
        // Approves the charter to transfer the position to proxy's address in the vat
        VatLike_17(vat).hope(charter);
        // Transfers position from CDP to the proxy address
        CharterLike(charter).quit(ilk, address(this));
        // Denies charter to access to proxy's position in the vat after execution
        VatLike_17(vat).nope(charter);
        // Frees the position and recovers the collateral in the vat registry
        EndLike_3(end).free(ilk);
        // Fluxs to the proxy's manager proxy, so it can be pulled out with the managed gem join
        VatLike_17(vat).flux(
            ilk,
            address(this),
            urp,
            ink
        );
    }

    // Public functions
    function freeETH(
        address ethJoin,
        address end
    ) external {
        bytes32 ilk = GemJoinLike_2(ethJoin).ilk();

        // Frees the position through the end contract
        uint256 wad = _free(end, ilk);
        // Exits WETH amount to proxy address as a token
        CharterLike(charter).exit(ethJoin, address(this), wad);
        // Converts WETH to ETH
        GemJoinLike_2(ethJoin).gem().withdraw(wad);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wad);
    }

    function freeGem(
        address gemJoin,
        address end
    ) external {
        bytes32 ilk = GemJoinLike_2(gemJoin).ilk();

        // Frees the position through the end contract
        uint256 wad = _free(end, ilk);
        // Exits token amount to the user's wallet as a token
        uint256 amt = wad / 10 ** (18 - GemJoinLike_2(gemJoin).dec());
        CharterLike(charter).exit(gemJoin, msg.sender, amt);
    }

    function pack(
        address daiJoin,
        address end,
        uint256 wad
    ) external {
        // Joins DAI amount into the vat
        daiJoin_join(daiJoin, wad);
        // Approves the end to take out DAI from the proxy's balance in the vat
        if (VatLike_17(vat).can(address(this), address(end)) == 0) {
            VatLike_17(vat).hope(end);
        }
        EndLike_3(end).pack(wad);
    }

    function cashETH(
        address ethJoin,
        address end,
        uint256 wad
    ) external {
        bytes32 ilk = GemJoinLike_2(ethJoin).ilk();
        EndLike_3(end).cash(ilk, wad);
        uint256 wadC = _mul(wad, EndLike_3(end).fix(ilk)) / RAY;
        // Flux to the proxy's UrnProxy in charter manager, so it can be pulled out with the managed gem join
        VatLike_17(vat).flux(
            ilk,
            address(this),
            CharterLike(charter).getOrCreateProxy(address(this)),
            wadC
        );
        // Exits WETH amount to proxy address as a token
        CharterLike(charter).exit(ethJoin, address(this), wadC);
        // Converts WETH to ETH
        GemJoinLike_2(ethJoin).gem().withdraw(wadC);
        // Sends ETH back to the user's wallet
        msg.sender.transfer(wadC);
    }

    function cashGem(
        address gemJoin,
        address end,
        uint256 wad
    ) external {
        bytes32 ilk = GemJoinLike_2(gemJoin).ilk();
        EndLike_3(end).cash(ilk, wad);
        uint256 wadC = _mul(wad, EndLike_3(end).fix(ilk)) / RAY;
        // Flux to the proxy's UrnProxy in charter manager, so it can be pulled out with the managed gem join
        VatLike_17(vat).flux(
            ilk,
            address(this),
            CharterLike(charter).getOrCreateProxy(address(this)),
            wadC
        );
        // Exits token amount to the user's wallet as a token
        uint256 amt = wadC / 10 ** (18 - GemJoinLike_2(gemJoin).dec());
        CharterLike(charter).exit(gemJoin, msg.sender, amt);
    }
}