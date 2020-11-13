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

import { ERC20 } from "../../ERC20.sol";
import { TokenMetadata, Component } from "../../Structs.sol";
import { TokenAdapter } from "../TokenAdapter.sol";


/**
 * @dev CToken contract interface.
 * Only the functions required for MooniswapTokenAdapter contract are added.
 * The CToken contract is available here
 * github.com/compound-finance/compound-protocol/blob/master/contracts/CToken.sol.
 */
interface CToken {
    function isCToken() external view returns (bool);
}


/**
 * @dev Mooniswap contract interface.
 * Only the functions required for MooniswapTokenAdapter contract are added.
 * The MooniswapV2Pair contract is available here
 * github.com/CryptoManiacsZone/mooniswap/blob/master/contracts/Mooniswap.sol
 */
interface Mooniswap {
    function getTokens() external view returns(address[] memory);
}


/**
 * @title Token adapter for Mooniswap pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author 1inch.exchange <info@1inch.exchange>
 */
contract MooniswapTokenAdapter is TokenAdapter {

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
        address[] memory tokens = Mooniswap(token).getTokens();
        uint256 totalSupply = ERC20(token).totalSupply();
        Component[] memory underlyingTokens = new Component[](2);

        for (uint256 i = 0; i < 2; i++) {
            underlyingTokens[i] = Component({
                token: isETH(ERC20(tokens[i])) ? 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE : tokens[i],
                tokenType: getTokenType(tokens[i]),
                rate: uniBalanceOf(ERC20(tokens[i]), token) * 1e18 / totalSupply
            });
        }

        return underlyingTokens;
    }

    function getTokenType(address token) internal view returns (string memory) {
        (bool success, bytes memory returnData) = token.staticcall{gas: 2000}(
            abi.encodeWithSelector(CToken(token).isCToken.selector)
        );

        if (success) {
            if (returnData.length == 32) {
                return abi.decode(returnData, (bool)) ? "CToken" : "ERC20";
            } else {
                return "ERC20";
            }
        } else {
            return "ERC20";
        }
    }

    function uniBalanceOf(ERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function isETH(ERC20 token) internal pure returns(bool) {
        return (address(token) == address(0));
    }
}
