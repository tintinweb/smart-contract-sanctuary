/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.12;

////// src/UniswapV2Callee.sol
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.6.12; */

interface VatLike_7 {
    function hope(address) external;
}

interface GemJoinLike_2 {
    function dec() external view returns (uint256);
    function gem() external view returns (TokenLike_2);
    function exit(address, uint256) external;
}

interface DaiJoinLike_2 {
    function dai() external view returns (TokenLike_2);
    function vat() external view returns (VatLike_7);
    function join(address, uint256) external;
}

interface TokenLike_2 {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface UniswapV2Router02Like_1 {
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external returns (uint[] memory);
}

// Simple Callee Example to interact with MatchingMarket
// This Callee contract exists as a standalone contract
contract UniswapV2Callee_1 {
    UniswapV2Router02Like_1   public uniRouter02;
    DaiJoinLike_2             public daiJoin;
    TokenLike_2               public dai;

    uint256                 public constant RAY = 10 ** 27;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(x, sub(y, 1)) / y;
    }

    function setUp(address uniRouter02_, address daiJoin_) internal {
        uniRouter02 = UniswapV2Router02Like_1(uniRouter02_);
        daiJoin = DaiJoinLike_2(daiJoin_);
        dai = daiJoin.dai();

        dai.approve(daiJoin_, uint256(-1));
    }

    function _fromWad(address gemJoin, uint256 wad) internal view returns (uint256 amt) {
        amt = wad / 10 ** (sub(18, GemJoinLike_2(gemJoin).dec()));
    }
}

// Uniswapv2Router02 route directs swaps from one pool to another
contract UniswapV2CalleeDai is UniswapV2Callee_1 {
    constructor(address uniRouter02_, address daiJoin_) public {
        setUp(uniRouter02_, daiJoin_);
    }

    function clipperCall(
        address sender,         // Clipper Caller and Dai deliveryaddress
        uint256 daiAmt,         // Dai amount to payback[rad]
        uint256 gemAmt,         // Gem amount received [wad]
        bytes calldata data     // Extra data needed (gemJoin)
    ) external {
        (
            address to,           // address to send remaining DAI to
            address gemJoin,      // gemJoin adapter address
            uint256 minProfit,    // minimum profit in DAI to make [wad]
            address[] memory path // Uniswap pool path
        ) = abi.decode(data, (address, address, uint256, address[]));

        // Convert gem amount to token precision
        gemAmt = _fromWad(gemJoin, gemAmt);

        // Exit collateral to token version
        GemJoinLike_2(gemJoin).exit(address(this), gemAmt);

        // Approve uniRouter02 to take gem
        TokenLike_2 gem = GemJoinLike_2(gemJoin).gem();
        gem.approve(address(uniRouter02), gemAmt);

        // Calculate amount of DAI to Join (as erc20 WAD value)
        uint256 daiToJoin = divup(daiAmt, RAY);

        // Do operation and get dai amount bought (checking the profit is achieved)
        uniRouter02.swapExactTokensForTokens(
            gemAmt,
            add(daiToJoin, minProfit),
            path,
            address(this),
            block.timestamp
        );

        // Although Uniswap will accept all gems, this check is a sanity check, just in case
        // Transfer any lingering gem to specified address
        if (gem.balanceOf(address(this)) > 0) {
            gem.transfer(to, gem.balanceOf(address(this)));
        }

        // Convert DAI bought to internal vat value of the msg.sender of Clipper.take
        daiJoin.join(sender, daiToJoin);

        // Transfer remaining DAI to specified address
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}