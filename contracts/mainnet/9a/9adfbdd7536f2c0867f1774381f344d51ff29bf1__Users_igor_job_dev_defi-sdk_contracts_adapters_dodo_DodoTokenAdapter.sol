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
 * @dev DODOLpToken contract interface.
 * Only the functions required for DodoTokenAdapter contract are added.
 * The DODOLpToken contract is available here
 * github.com/DODOEX/dodo-smart-contract/blob/master/contracts/impl/DODOLpToken.sol.
 */
interface DODOLpToken {
    function _OWNER_() external view returns (address);
    function originToken() external view returns (address);
}


/**
 * @dev DODO contract interface.
 * Only the functions required for DodoTokenAdapter contract are added.
 * The DODO contract is available here
 * github.com/DODOEX/dodo-smart-contract/blob/master/contracts/dodo.sol.
 */
interface DODO {
    function _BASE_TOKEN_() external view returns (address);
    function _QUOTE_TOKEN_() external view returns (address);
}


/**
 * @title Token adapter for DODO pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract DodoTokenAdapter is TokenAdapter {

    /**
     * @return TokenMetadata struct with ERC20-style token info.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getMetadata(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: getPoolName(token),
            symbol: "DLP",
            decimals: ERC20(token).decimals()
        });
    }

    /**
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        address[] memory tokens = new address[](2);
        address dodo = DODOLpToken(token)._OWNER_();
        tokens[0] = DODO(dodo)._BASE_TOKEN_();
        tokens[1] = DODO(dodo)._QUOTE_TOKEN_();
        uint256 totalSupply = ERC20(token).totalSupply();
        Component[] memory underlyingTokens = new Component[](2);

        for (uint256 i = 0; i < 2; i++) {
            underlyingTokens[i] = Component({
                token: tokens[i],
                tokenType: "ERC20",
                rate: ERC20(tokens[i]).balanceOf(dodo) * 1e18 / totalSupply
            });
        }

        return underlyingTokens;
    }

    function getPoolName(address token) internal view returns (string memory) {
        address dodo = DODOLpToken(token)._OWNER_();
        return string(
            abi.encodePacked(
                getSymbol(DODO(dodo)._BASE_TOKEN_()),
                "/",
                getSymbol(DODO(dodo)._QUOTE_TOKEN_()),
                " Pool: ",
                getSymbol(DODOLpToken(token).originToken())
            )
        );
    }

    function getSymbol(address token) internal view returns (string memory) {
        (, bytes memory returnData) = token.staticcall(
            abi.encodeWithSelector(ERC20(token).symbol.selector)
        );

        if (returnData.length == 32) {
            return convertToString(abi.decode(returnData, (bytes32)));
        } else {
            return abi.decode(returnData, (string));
        }
    }

    /**
     * @dev Internal function to convert bytes32 to string and trim zeroes.
     */
    function convertToString(bytes32 data) internal pure returns (string memory) {
        uint256 counter = 0;
        bytes memory result;

        for (uint256 i = 0; i < 32; i++) {
            if (data[i] != bytes1(0)) {
                counter++;
            }
        }

        result = new bytes(counter);
        counter = 0;
        for (uint256 i = 0; i < 32; i++) {
            if (data[i] != bytes1(0)) {
                result[counter] = data[i];
                counter++;
            }
        }

        return string(result);
    }
}
