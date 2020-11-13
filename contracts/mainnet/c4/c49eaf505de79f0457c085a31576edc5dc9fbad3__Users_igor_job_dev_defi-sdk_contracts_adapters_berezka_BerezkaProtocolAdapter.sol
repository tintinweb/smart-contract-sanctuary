// Copyright (C) 2020 Easy Chain. <https://easychain.tech>
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
import { ProtocolAdapter } from "../ProtocolAdapter.sol";

/**
 * @dev BerezkaProtocolAdapterContract contract.
 * This adapter provides adapter for multiple BerezkaDAO contracts.
 * @author Vasin Denis <denis.vasin@easychain.tech>
 */
contract BerezkaProtocolAdapter is ProtocolAdapter {

    string public constant override adapterType = "Berezka DAO";

    string public constant override tokenType = "ERC20";

    /**
     * @return Amount of BerezkaDAO tokens held by the given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        return ERC20(token).balanceOf(account);
    }
}
