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
    function name() external view returns (string memory);
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
 * @dev PieSmartPool contract interface.
 * Only the functions required for UniswapAdapter contract are added.
 * The BPool contract is available here
 * github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
interface IPieSmartPool {
    function getTokens() external view returns (address[] memory);
    function getBPool() external view returns (address);
}


/**
 * @dev BPool contract interface.
 * Only the functions required for UniswapAdapter contract are added.
 * The BPool contract is available here
 * github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
interface BPool {
    function getFinalTokens() external view returns (address[] memory);
    function getBalance(address) external view returns (uint256);
    function getNormalizedWeight(address) external view returns (uint256);
}


/**
 * @title Token adapter for Pie pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Mick de Graaf <[email protected]>
 */
contract PieDAOPieTokenAdapter is TokenAdapter {

    /**
     * @return TokenMetadata struct with ERC20-style token info.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getMetadata(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: ERC20(token).name(),
            symbol: ERC20(token).symbol(),
            decimals: ERC20(token).decimals()
        });
    }

    /**
     * @return Array of Component structs with underlying tokens rates for the given asset.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        address[] memory underlyingTokensAddresses = IPieSmartPool(token).getTokens();
        uint256 totalSupply = ERC20(token).totalSupply();
        BPool bPool = BPool(IPieSmartPool(token).getBPool());

        Component[] memory underlyingTokens = new Component[](underlyingTokensAddresses.length);
        address underlyingToken;

        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            underlyingToken = underlyingTokensAddresses[i];
            underlyingTokens[i] = Component({
                token: underlyingToken,
                tokenType: "ERC20",
                rate: bPool.getBalance(underlyingToken) * 1e18 / totalSupply
            });
        }

        return underlyingTokens;
    }
}