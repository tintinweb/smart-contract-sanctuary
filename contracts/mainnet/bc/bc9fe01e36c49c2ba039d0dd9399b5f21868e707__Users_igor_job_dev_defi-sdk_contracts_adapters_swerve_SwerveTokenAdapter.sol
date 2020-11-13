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
 * @dev CurveRegistry contract interface.
 * Only the functions required for CurveTokenAdapter contract are added.
 * The CurveRegistry contract is available here
 * github.com/zeriontech/defi-sdk/blob/master/contracts/adapters/curve/CurveRegistry.sol.
 */
interface CurveRegistry {
    function getSwapAndTotalCoins(address) external view returns (address, uint256);
    function getName(address) external view returns (string memory);
}


/**
 * @dev stableswap contract interface.
 * Only the functions required for CurveTokenAdapter contract are added.
 * The stableswap contract is available here
 * github.com/curvefi/curve-contract/blob/compounded/vyper/stableswap.vy.
 */
// solhint-disable-next-line contract-name-camelcase
interface stableswap {
    function coins(int128) external view returns (address);
    function balances(int128) external view returns (uint256);
}


/**
 * @title Token adapter for Swerve pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract SwerveTokenAdapter is TokenAdapter {

    address internal constant REGISTRY = 0x2f9505a841a1e3b4fBFbb6693c8C3b26C5F1254D;

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
        (address swap, uint256 totalCoins) = CurveRegistry(REGISTRY).getSwapAndTotalCoins(token);
        Component[] memory underlyingComponents= new Component[](totalCoins);

        address underlyingToken;
        for (uint256 i = 0; i < totalCoins; i++) {
            underlyingToken = stableswap(swap).coins(int128(i));
            underlyingComponents[i] = Component({
                token: underlyingToken,
                tokenType: "ERC20",
                rate: stableswap(swap).balances(int128(i)) * 1e18 / ERC20(token).totalSupply()
            });
        }

        return underlyingComponents;
    }

    /**
     * @return Pool name.
     */
    function getPoolName(address token) internal view returns (string memory) {
        return CurveRegistry(REGISTRY).getName(token);
    }
}
