/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// GUniOracle.sol 

// based heavily on GUniLPOracle.sol from MakerDAO
// found here: https://github.com/makerdao/univ3-lp-oracle/blob/master/src/GUniLPOracle.sol
// Copyright (C) 2017-2020 Maker Ecosystem Growth Holdings, INC.

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

///////////////////////////////////////////////////////
//                                                   //
//    Methodology for Calculating LP Token Price     //
//                                                   //
///////////////////////////////////////////////////////

// We derive the sqrtPriceX96 via Chainlink Oracles to prevent price manipulation in the pool:
// 
// p0 = price of token0 in USD (18 decimal precision)
// p1 = price of token1 in USD (18 decimal precision)
// UNITS_0 = decimals of token0
// UNITS_1 = decimals of token1
// 
// token1/token0 = (p0 / 10^UNITS_0) / (p1 / 10^UNITS_1)               [price ratio, Uniswap format]
//               = (p0 * 10^UNITS_1) / (p1 * 10^UNITS_0)
// 
// sqrtPriceX96 = sqrt(token1/token0) * 2^96                           [From Uniswap's definition]
//              = sqrt((p0 * 10^UNITS_1) / (p1 * 10^UNITS_0)) * 2^96
//              = sqrt((p0 * 10^UNITS_1) / (p1 * 10^UNITS_0)) * 2^48 * 2^48
//              = sqrt((p0 * 10^UNITS_1 * 2^96) / (p1 * 10^UNITS_0)) * 2^48
// 
// Once we have the sqrtPriceX96 we can use that to compute the fair reserves for each token. 
// This part may be slightly subjective depending on the implementation, 
// but we expect token to provide something like getUnderlyingBalancesAtPrice(uint160 sqrtPriceX96)
// which will forward our oracle derived `sqrtPriceX96` 
// to Uniswap's LiquidityAmounts.getAmountsForLiquidity(...)
// This function will return the fair reserves for each token.
// Vendor-specific logic is then used to tack any uninvested fees on top of those amounts.
// 
// Once we have the fair reserves and the prices we can compute the token price by:
// 
// Token Price = TVL / Token Supply
//             = (r0 * p0 + r1 * p1) / totalSupply


pragma solidity =0.6.12;

interface IExtendedAggregator {
    enum TokenType {Invalid, Simple, Complex}

    enum PlatformId {Invalid, Simple, Uniswap, Balancer, GUni}

    /**
     * @dev Returns the LP shares token
     * @return address of the LP shares token
     */
    function getToken() external view returns (address);

    /**
     * @dev Returns the number of tokens that composes the LP shares
     * @return address[] memory of token addresses
     */
    function getSubTokens() external view returns (address[] memory);
    
    /**
     * @dev Returns the latest price
     * @return int256 price
     */
    function latestAnswer() external view returns (int256);

    /**
     * @dev Returns the decimals of latestAnswer()
     * @return uint8
     */
    function decimals() external pure returns (uint8);
    
    /**
     * @dev Returns the platform id to categorize the price aggregator
     * @return uint256 1 = Uniswap, 2 = Balancer, 3 = G-UNI
     */
    function getPlatformId() external pure returns (PlatformId);

    /**
     * @dev Returns token type for categorization
     * @return uint256 1 = Simple (Native or plain ERC20s), 2 = Complex (LP Tokens, Staked tokens)
     */
    function getTokenType() external pure returns (TokenType);
}

interface IGUniPool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getUnderlyingBalancesAtPrice(uint160) external view returns (uint256, uint256);
    function getUnderlyingBalances() external view returns (uint256, uint256);
    function totalSupply() external view returns (uint256);
}

contract GUniOracle is IExtendedAggregator {
    // solhint-disable private-vars-leading-underscore, var-name-mixedcase
    uint256 private immutable UNIT_0;
    uint256 private immutable UNIT_1;
    uint256 private immutable TO_WAD_0;
    uint256 private immutable TO_WAD_1;
    uint256 private immutable TO_WAD_ORACLE_0;
    uint256 private immutable TO_WAD_ORACLE_1;

    address public immutable pool;
    address public immutable priceFeed0;
    address public immutable priceFeed1;

    constructor(address _pool, address _feed0, address _feed1) public {
        uint256 dec0 = uint256(IExtendedAggregator(IGUniPool(_pool).token0()).decimals());
        require(dec0 <= 18, "token0-dec-gt-18");
        UNIT_0 = 10 ** dec0;
        TO_WAD_0 = 10 ** (18 - dec0);
        uint256 dec1 = uint256(IExtendedAggregator(IGUniPool(_pool).token1()).decimals());
        require(dec1 <= 18, "token1-dec-gt-18");
        UNIT_1 = 10 ** dec1;
        TO_WAD_1 = 10 ** (18 - dec1);
        uint256 decOracle0 = uint256(IExtendedAggregator(_feed0).decimals());
        require(decOracle0 <= 18, "oracle0-dec-gt-18");
        TO_WAD_ORACLE_0 = 10 ** (18 - decOracle0);
        uint256 decOracle1 = uint256(IExtendedAggregator(_feed1).decimals());
        require(decOracle1 <= 18, "oracle1-dec-gt-18");
        TO_WAD_ORACLE_1 = 10 ** (18 - decOracle1);
        pool = _pool;
        priceFeed0 = _feed0;
        priceFeed1 = _feed1;
    }

    function latestAnswer() external view override returns (int256) {
        // All Oracle prices are priced with 18 decimals against USD
        uint256 p0 = _getWADPrice(true);  // Query token0 price from oracle (WAD)
        uint256 p1 = _getWADPrice(false);  // Query token1 price from oracle (WAD)
        uint160 sqrtPriceX96 =
            _toUint160(_sqrt(_mul(_mul(p0, UNIT_1), (1 << 96)) / (_mul(p1, UNIT_0))) << 48);

        // Get balances of the tokens in the pool
        (uint256 r0, uint256 r1) = IGUniPool(pool).getUnderlyingBalancesAtPrice(sqrtPriceX96);
        require(r0 > 0 || r1 > 0, "invalid-balances");
        uint256 totalSupply = IGUniPool(pool).totalSupply();
        // Protect against precision errors with dust-levels of collateral
        require(totalSupply >= 1e9, "total-supply-too-small");

        // Add the total value of each token together and divide by totalSupply to get unit price
        uint256 preq = _add(
            _mul(p0, _mul(r0, TO_WAD_0)),
            _mul(p1, _mul(r1, TO_WAD_1))
        ) / totalSupply;
        
        return int256(preq);
    }

    function getToken() external view override returns (address) {
        return pool;
    }

    function getSubTokens() external view override returns (address[] memory) {
        address[] memory arr = new address[](2);
        arr[0] = IGUniPool(pool).token0();
        arr[1] = IGUniPool(pool).token1();
        return arr;
    }

    function getPlatformId() external pure override returns (IExtendedAggregator.PlatformId) {
        return IExtendedAggregator.PlatformId.GUni;
    }

    function getTokenType() external pure override returns (IExtendedAggregator.TokenType) {
        return IExtendedAggregator.TokenType.Complex;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function _getWADPrice(bool isToken0)
        internal
        view
        returns (uint256)
    {
        int256 price = IExtendedAggregator(isToken0 ? priceFeed0 : priceFeed1).latestAnswer();
        require(price > 0, "negative-price");
        return _mul(uint256(price), isToken0 ? TO_WAD_ORACLE_0 : TO_WAD_ORACLE_1);
    }

    function _add(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require((z = _x + _y) >= _x, "add-overflow");
    }
    function _sub(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require((z = _x - _y) <= _x, "sub-underflow");
    }
    function _mul(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require(_y == 0 || (z = _x * _y) / _y == _x, "mul-overflow");
    }
    function _toUint160(uint256 x) internal pure returns (uint160 z) {
        require((z = uint160(x)) == x, "uint160-overflow");
    }

    // solhint-disable-next-line max-line-length
    // FROM https://github.com/abdk-consulting/abdk-libraries-solidity/blob/16d7e1dd8628dfa2f88d5dadab731df7ada70bdd/ABDKMath64x64.sol#L687
    // solhint-disable-next-line code-complexity
    function _sqrt(uint256 _x) private pure returns (uint128) {
        if (_x == 0) return 0;
        else {
            uint256 xx = _x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
            if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
            if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
            if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
            if (xx >= 0x100) { xx >>= 8; r <<= 4; }
            if (xx >= 0x10) { xx >>= 4; r <<= 2; }
            if (xx >= 0x8) { r <<= 1; }
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = _x / r;
            return uint128 (r < r1 ? r : r1);
        }
    }
}