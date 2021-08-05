/**
 *Submitted for verification at Etherscan.io on 2020-04-17
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
 * @dev CToken contract interface.
 * Only the functions required for BalancerTokenAdapter contract are added.
 * The CToken contract is available here
 * github.com/compound-finance/compound-protocol/blob/master/contracts/CToken.sol.
 */
interface CToken {
    function isCToken() external view returns (bool);
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
 * @title Token adapter for Balancer pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract BalancerTokenAdapter is TokenAdapter {


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
     * @return Array of Component structs with underlying tokens rates for the given asset.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        address[] memory underlyingTokensAddresses;
        try BPool(token).getFinalTokens() returns (address[] memory result) {
            underlyingTokensAddresses = result;
        } catch {
            underlyingTokensAddresses = new address[](0);
        }

        uint256 totalSupply = ERC20(token).totalSupply();

        Component[] memory underlyingTokens = new Component[](underlyingTokensAddresses.length);

        address underlyingToken;
        string memory underlyingTokenType;
        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            underlyingToken = underlyingTokensAddresses[i];

            try CToken(underlyingToken).isCToken{gas: 2000}() returns (bool) {
                underlyingTokenType = "CToken";
            } catch {
                underlyingTokenType = "ERC20";
            }

            underlyingTokens[i] = Component({
                token: underlyingToken,
                tokenType: underlyingTokenType,
                rate: BPool(token).getBalance(underlyingToken) * 1e18 / totalSupply
            });
        }

        return underlyingTokens;
    }

    function getPoolName(address token) internal view returns (string memory) {
        address[] memory underlyingTokensAddresses;
        try BPool(token).getFinalTokens() returns (address[] memory result) {
            underlyingTokensAddresses = result;
        } catch {
            return "Unknown pool";
        }

        string memory poolName = "";
        uint256 lastIndex = underlyingTokensAddresses.length - 1;
        for (uint256 i = 0; i < underlyingTokensAddresses.length; i++) {
            poolName = string(abi.encodePacked(
                poolName,
                getPoolElement(token, underlyingTokensAddresses[i]),
                i == lastIndex ? " pool" : " + "
            ));
        }
        return poolName;
    }

    function getPoolElement(address pool, address token) internal view returns (string memory) {
        return string(abi.encodePacked(
            convertToString(BPool(pool).getNormalizedWeight(token) / 1e16),
            "% ",
            getSymbol(token)
        ));
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
        uint256 length = 0;
        bytes memory result;

        for (uint256 i = 0; i < 32; i++) {
            if (data[i] != bytes1(0)) {
                length++;
            }
        }

        result = new bytes(length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = data[i];
        }

        return string(result);
    }

    /**
     * @dev Internal function to convert uint256 to string and trim zeroes.
     */
    function convertToString(uint256 data) internal pure returns (string memory) {
        uint256 length = 0;

        uint256 dataCopy = data;
        while (dataCopy != 0){
            length++;
            dataCopy /= 10;
        }

        bytes memory result = new bytes(length);
        dataCopy = data;
        for (uint256 i = length - 1; i < length; i--) {
            result[i] = bytes1(uint8(48 + dataCopy % 10));
            dataCopy /= 10;
        }

        return string(result);
    }
}