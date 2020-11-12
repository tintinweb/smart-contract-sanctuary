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
}/**


/**
 * @title Token adapter for FinNexus.
 * @dev Implementation of TokenAdapter interface.
 * @author jeffqg123 <forestjqg@163.com>
 */
contract FinNexusTokenAdapter is TokenAdapter {

    address public constant OPT_MANAGER_FNX = 0xfDf252995da6D6c54C03FC993e7AA6B593A57B8d;
    address public constant OPT_MANAGER_USDC = 0x120f18F5B8EdCaA3c083F9464c57C11D81a9E549;
    
    address public constant ORACLE = 0x43BD92bF3Bb25EBB3BdC2524CBd6156E3Fdd41F3;


    address public constant FNX = 0xeF9Cd7882c067686691B6fF49e650b43AFBBCC6B;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public constant FPT_FNX = 0x7E605Fb638983A448096D82fFD2958ba012F30Cd;
    address public constant FPT_USDC = 0x16305b9EC0bdBE32cF8a0b5C142cEb3682dB9d2d;
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
        
        Component[] memory underlyingTokens = new Component[](1);

        if (token == FPT_USDC) {
            
            uint256 fptWorth = OptionsManagerV2(OPT_MANAGER_USDC).getTokenNetworth();
            uint256 tokenPrice = FNXOracle(ORACLE).getPrice(USDC);
            tokenPrice = tokenPrice * 1e6 ;
            underlyingTokens[0] = Component({
                    token:USDC,
                    tokenType: "ERC20",
                    rate: tokenPrice / fptWorth
                    });
                    
        } else if (token == FPT_FNX) {
                
            uint256 fptWorth = OptionsManagerV2(OPT_MANAGER_FNX).getTokenNetworth();
            uint256 tokenPrice = FNXOracle(ORACLE).getPrice(FNX);    
            tokenPrice =  tokenPrice * 1e18;
            underlyingTokens[0] = Component({
                    token:FNX,
                    tokenType: "ERC20",
                    rate: tokenPrice / fptWorth
                    });
        }
                
        return underlyingTokens;
    }
}