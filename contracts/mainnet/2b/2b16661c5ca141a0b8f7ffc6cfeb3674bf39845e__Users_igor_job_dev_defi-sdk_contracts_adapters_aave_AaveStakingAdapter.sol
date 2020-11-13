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
import { ProtocolAdapter } from "../ProtocolAdapter.sol";


interface StakedAave {
    function getTotalRewardsBalance(address) external view returns (uint256);
}


/**
 * @title Adapter for Aave protocol (staking).
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract AaveStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant STAKED_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

    /**
     * @return Amount of staked AAVE tokens for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address, address account) external view override returns (uint256) {
        uint256 totalBalance = 0;

        totalBalance += ERC20(STAKED_AAVE).balanceOf(account);
        totalBalance += StakedAave(STAKED_AAVE).getTotalRewardsBalance(account);

        return totalBalance;
    }
}
