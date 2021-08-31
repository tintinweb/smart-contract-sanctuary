/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
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

pragma solidity >=0.6.12;

interface VatLike {
    function hope(address) external;
}

interface GemJoinLike {
    function dec() external view returns (uint256);
    function gem() external view returns (VaultLike);
    function exit(address, uint256) external;
}

interface DaiJoinLike {
    function dai() external view returns (TokenLike);
    function vat() external view returns (VatLike);
    function join(address, uint256) external;
}

interface DssPsmLike {
    function gemJoin() external view returns (address);
    function sellGem(address, uint256) external;
}

interface TokenLike {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface LpTokenLike is TokenLike {
    function token0() external view returns (TokenLike);
    function token1() external view returns (TokenLike);
}

interface VaultLike is TokenLike
{
	function withdraw(uint256, uint256, bool) external;
}

interface UniswapV2Router02Like {
    function factory() external pure returns (UniswapV2FactoryLike);
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external returns (uint[] memory);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface UniswapV2FactoryLike {
    function getPair(address, address) external view returns (LpTokenLike);
}

// This Callee contract exists as a standalone contract
contract UniswapV2Callee {
    DssPsmLike              public dssPsm;
    UniswapV2Router02Like   public uniRouter02;
    DaiJoinLike             public daiJoin;
    TokenLike               public dai;

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

    function setUp(address dssPsm_, address uniRouter02_, address daiJoin_) internal {
        dssPsm = DssPsmLike(dssPsm_);
        uniRouter02 = UniswapV2Router02Like(uniRouter02_);
        daiJoin = DaiJoinLike(daiJoin_);
        dai = daiJoin.dai();

        dai.approve(daiJoin_, uint256(-1));
    }

    function _fromWad(address gemJoin, uint256 wad) internal view returns (uint256 amt) {
        amt = wad / 10 ** (sub(18, GemJoinLike(gemJoin).dec()));
    }
}

// Uniswapv2Router02 route directs swaps from one pool to another
contract UniswapV2LpTokenCalleeDai is UniswapV2Callee {
    constructor(address dssPsm_, address uniRouter02_, address daiJoin_) public {
        setUp(dssPsm_, uniRouter02_, daiJoin_);
    }

    function swapGemForDai(
        TokenLike token,
        address[] memory path,
        address to
    ) internal {
        if (path.length > 1) {
            uint256 amountIn = token.balanceOf(address(this));
            token.approve(address(uniRouter02), amountIn);
            uniRouter02.swapExactTokensForTokens(
                amountIn,
                0, // amountOutMin is zero because minProfit is checked at the end
                path,
                address(this),
                block.timestamp
            );
            if (token.balanceOf(address(this)) > 0) {
                token.transfer(to, token.balanceOf(address(this)));
            }
        }
        TokenLike busd = TokenLike(path[path.length - 1]);
        uint256 amountOut = busd.balanceOf(address(this));
        busd.approve(dssPsm.gemJoin(), amountOut);
        dssPsm.sellGem(address(this), amountOut);
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
            address[] memory pathA, // path of token A
            address[] memory pathB  // path of token B
        ) = abi.decode(data, (address, address, uint256, address[], address[]));

        // Convert gem amount to token precision
        gemAmt = _fromWad(gemJoin, gemAmt);

        // Exit collateral to token version
        GemJoinLike(gemJoin).exit(address(this), gemAmt);

        {
            VaultLike vault = GemJoinLike(gemJoin).gem();
            vault.withdraw(gemAmt, 1, true);
        }

        // Approve uniRouter02 to take gem
        LpTokenLike gem;
        {
            UniswapV2FactoryLike uniFactory = uniRouter02.factory();
            gem = uniFactory.getPair(pathA[0], pathB[0]);
        }
        gemAmt = gem.balanceOf(address(this));
        gem.approve(address(uniRouter02), gemAmt);

        // Calculate amount of DAI to Join (as erc20 WAD value)
        uint256 daiToJoin = divup(daiAmt, RAY);

        // Do operation and get dai amount bought (checking the profit is achieved)
        TokenLike tokenA = gem.token0();
        TokenLike tokenB = gem.token1();
        uniRouter02.removeLiquidity({ // burn token to obtain its components
            tokenA: address(tokenA),
            tokenB: address(tokenB),
            liquidity: gemAmt,
            amountAMin: 0, // minProfit is checked below
            amountBMin: 0,
            to: address(this),
            deadline: block.timestamp
        });
        if (address(tokenA) != address(dai)) {
            swapGemForDai(tokenA, pathA, to);
        }
        if (address(tokenB) != address(dai)) {
            swapGemForDai(tokenB, pathB, to);
        }
        require(
            dai.balanceOf(address(this)) >= add(daiToJoin, minProfit),
            "UniswapV2Callee/insufficient-profit"
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