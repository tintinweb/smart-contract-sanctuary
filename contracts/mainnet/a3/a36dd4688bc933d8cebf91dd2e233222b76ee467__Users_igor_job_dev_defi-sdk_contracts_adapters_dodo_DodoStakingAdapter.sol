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

import { ProtocolAdapter } from "../ProtocolAdapter.sol";


/**
 * @dev DODOMine contract interface.
 * Only the functions required for DodoStakingAdapter contract are added.
 * The DODOMine contract is available here
 * github.com/DODOEX/dodo-smart-contract/blob/master/contracts/token/DODOMine.sol.
 */
interface DODOMine {
    function getUserLpBalance(address, address) external view returns (uint256);
    function getAllPendingReward(address) external view returns (uint256);
}


/**
 * @title Adapter for DODO protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract DodoStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant DODO = 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd;
    address internal constant DODO_MINE = 0xaeD7384F03844Af886b830862FF0a7AFce0a632C;

    /**
     * @return Amount of DODO rewards / DLP staked tokens for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        if (token == DODO) {
            uint256 totalBalance = 0;

            totalBalance += DODOMine(DODO_MINE).getAllPendingReward(account);
            totalBalance += DODOMine(DODO_MINE).getUserLpBalance(token, account);

            return totalBalance;
        } else {
            return DODOMine(DODO_MINE).getUserLpBalance(token, account);
        }
    }
}
