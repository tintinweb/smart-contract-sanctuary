/**
 *Submitted for verification at Etherscan.io on 2020-04-16
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
}


// ERC20-style token metadata
// 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE address is used for ETH
struct TokenMetadata {
    address token;
    string name;
    string symbol;
    uint8 decimals;
}


struct Component {
    address token;    // Address of token contract
    string tokenType; // Token type ("ERC20" by default)
    uint256 rate;     // Price per full share (1e18)
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
    *     uint256 rate;     // Price per full share (1e18)
    * }
    */
    function getComponents(address token) external view returns (Component[] memory);
}


/**
 * @dev SetToken contract interface.
 * Only the functions required for TokenSetsTokenAdapter contract are added.
 * The SetToken contract is available here
 * github.com/SetProtocol/set-protocol-contracts/blob/master/contracts/core/tokens/SetToken.sol.
 */
interface SetToken {
    function getUnits() external view returns (uint256[] memory);
    function naturalUnit() external view returns (uint256);
    function getComponents() external view returns(address[] memory);
}

/**
 * @dev RebalancingSetToken contract interface.
 * Only the functions required for TokenSetsTokenAdapter contract are added.
 * The RebalancingSetToken contract is available here
 * github.com/SetProtocol/set-protocol-contracts/blob/master/contracts/core/tokens/RebalancingSetTokenV3.sol.
 */
interface RebalancingSetToken {
    function unitShares() external view returns (uint256);
    function naturalUnit() external view returns (uint256);
    function currentSet() external view returns (SetToken);
}


/**
 * @title Token adapter for TokenSets.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract TokenSetsTokenAdapter is TokenAdapter {

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
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        RebalancingSetToken rebalancingSetToken = RebalancingSetToken(token);
        uint256 tokenUnitShare = rebalancingSetToken.unitShares();
        uint256 tokenNaturalUnit = rebalancingSetToken.naturalUnit();
        uint256 tokenRate = 1e18 * tokenUnitShare / tokenNaturalUnit;

        SetToken setToken = rebalancingSetToken.currentSet();
        uint256[] memory unitShares = setToken.getUnits();
        uint256 naturalUnit = setToken.naturalUnit();
        address[] memory components = setToken.getComponents();

        Component[] memory underlyingTokens = new Component[](components.length);

        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            underlyingTokens[i] = Component({
                token: components[i],
                tokenType: "ERC20",
                rate: tokenRate * unitShares[i] / naturalUnit
            });
        }

        return underlyingTokens;
    }
}