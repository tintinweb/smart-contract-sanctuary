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
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
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
    address token;
    string tokenType;  // "ERC20" by default
    uint256 rate;  // price per full share (1e18)
}



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
 * @dev OptionsManagerV2 contract interface.
 * Only the functions required for FinNexusTokenAdapter contract are added.
 */
interface OptionsManagerV2 {
    function getTokenNetworth() external view returns (uint256);
}


/**
 * @dev FNXOracle contract interface.
 * Only the functions required for FinNexusTokenAdapter contract are added.
 */
interface FNXOracle {
    function getPrice(address asset) external view returns (uint256);
}


/**
 * @title Token adapter for FinNexus.
 * @dev Implementation of TokenAdapter interface.
 * @author jeffqg123 <forestjqg@163.com>
 */
contract FinNexusTokenAdapter is TokenAdapter {

    address public  constant optManager = 0xfa30ec96De9840A611FcB64e7312f97bdE6e155A;
    address public  constant oracle = 0x940b491905529542Ba3b56244A06B1EBE11e71F2;

    address[] internal underlyingAddress = [0x0000000000000000000000000000000000000000,0xeF9Cd7882c067686691B6fF49e650b43AFBBCC6B,0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48];
                                                           //  ,
                                                           //  ];
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
    function getComponents(address) external view override returns (Component[] memory) {
        
        Component[] memory underlyingTokens = new Component[](underlyingAddress.length);

        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            uint256 fptWorth = OptionsManagerV2(optManager).getTokenNetworth();
            uint256 tokenPrice = FNXOracle(oracle).getPrice(underlyingAddress[i]);
            
            if(i==2) {
                tokenPrice = 1e6 * tokenPrice;
            } else {
                tokenPrice = 1e18 * tokenPrice;
            }
            
            underlyingTokens[i] = Component({
                token: i==0?0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:underlyingAddress[i],
                tokenType: "ERC20",
                rate: tokenPrice/fptWorth
            });
        }

        return underlyingTokens;
    }
}