/**
 *Submitted for verification at Etherscan.io on 2020-04-23
*/

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}


// ERC20-style token metadata
// 0xEeee...EEeE address is used for ETH
struct TokenMetadata {
    address token;
    string name;
    string symbol;
    uint8 decimals;
}


struct Component {
    address token;    // Address of token contract
    string tokenType; // Token type ("ERC20" by default)
    uint256 rate;     // Price per share (1e18)
}


/**
 * @title Token adapter interface.
 * @dev getMetadata() and getComponents() functions MUST be implemented.
 * @author Igor Sobolev <[email protected]>
 */
interface TokenAdapter {

    /**
     * @dev MUST return TokenMetadata struct with ERC20-style token info.
     * struct TokenMetadata {
     *     address token;
     *     string name;
     *     string symbol;
     *     uint8 decimals;
     * }
     */
    function getMetadata(address token) external view returns (TokenMetadata memory);

    /**
    * @dev MUST return array of Component structs with underlying tokens rates for the given token.
    * struct Component {
    *     address token;    // Address of token contract
    *     string tokenType; // Token type ("ERC20" by default)
    *     uint256 rate;     // Price per share (1e18)
    * }
    */
    function getComponents(address token) external view returns (Component[] memory);
}


/**
 * @dev stableswap contract interface.
 * Only the functions required for CurveAdapter contract are added.
 * The stableswap contract is available here
 * github.com/curvefi/curve-contract/blob/compounded/vyper/stableswap.vy.
 */
// solhint-disable-next-line contract-name-camelcase
interface stableswap {
    function coins(int128) external view returns (address);
    function balances(int128) external view returns (uint256);
}


/**
 * @title Token adapter for Curve pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract CurveTokenAdapter is TokenAdapter {

    address internal constant COMPOUND_POOL_TOKEN = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
    address internal constant Y_POOL_TOKEN = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
    address internal constant BUSD_POOL_TOKEN = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
    address internal constant SUSD_POOL_TOKEN = 0xC25a3A3b969415c80451098fa907EC722572917F;

    /**
     * @return TokenMetadata struct with ERC20-style token info.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getMetadata(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: getPoolName(token),
            symbol: ERC20(token).symbol(),
            decimals: ERC20(token).decimals()
        });
    }

    /**
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        (stableswap ss, uint256 length, string memory tokenType) = getPoolInfo(token);
        Component[] memory underlyingTokens = new Component[](length);

        for (uint256 i = 0; i < length; i++) {
            underlyingTokens[i] = Component({
                token: ss.coins(int128(i)),
                tokenType: tokenType,
                rate: ss.balances(int128(i)) * 1e18 / ERC20(token).totalSupply()
            });
        }

        return underlyingTokens;
    }

    /**
     * @return Stableswap address, number of coins, type of tokens inside.
     */
    function getPoolInfo(address token) internal pure returns (stableswap, uint256, string memory) {
        if (token == COMPOUND_POOL_TOKEN) {
            return (stableswap(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56), 2, "CToken");
        } else if (token == Y_POOL_TOKEN) {
            return (stableswap(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51), 4, "YToken");
        } else if (token == BUSD_POOL_TOKEN) {
            return (stableswap(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27), 4, "YToken");
        } else if (token == SUSD_POOL_TOKEN) {
            return (stableswap(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD), 4, "ERC20");
        } else {
            return (stableswap(address(0)), 0, "");
        }
    }

    function getPoolName(address token) internal pure returns (string memory) {
        if (token == COMPOUND_POOL_TOKEN) {
            return "Compound pool";
        } else if (token == Y_POOL_TOKEN) {
            return "Y pool";
        } else if (token == BUSD_POOL_TOKEN) {
            return "bUSD pool";
        } else if (token == SUSD_POOL_TOKEN) {
            return "sUSD pool";
        } else {
            return "Unknown pool";
        }
    }
}