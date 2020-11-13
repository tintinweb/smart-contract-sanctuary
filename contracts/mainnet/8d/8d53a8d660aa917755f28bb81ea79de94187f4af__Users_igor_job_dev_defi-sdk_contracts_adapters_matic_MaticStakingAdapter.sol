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


/**
 * @dev StakingManager contract interface.
 * Only the functions required for MaticStakingAdapter contract are added.
 */
interface ValidatorShare {
    function getLiquidRewards(address) external view returns (uint256);
}


/**
 * @title Adapter for Matic Staking.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract MaticStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant VALIDATOR_SHARE = 0xD9AeF0814e7eCBB4447eab08EDe33b6EBC29F842;

    /**
     * @return Amount of MATIC tokens locked on the StakingManager contract by the given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address, address account) external view override returns (uint256) {
        uint256 totalBalance = 0;
        totalBalance += ERC20(VALIDATOR_SHARE).balanceOf(account);
        totalBalance += ValidatorShare(VALIDATOR_SHARE).getLiquidRewards(account);
        return totalBalance;
    }
}
