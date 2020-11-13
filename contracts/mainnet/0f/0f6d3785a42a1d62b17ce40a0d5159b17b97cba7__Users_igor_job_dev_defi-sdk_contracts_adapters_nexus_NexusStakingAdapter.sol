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
 * @dev TokenController contract interface.
 * Only the functions required for NexusStakingAdapter contract are added.
 * The TokenController contract is available here
 * github.com/somish/NexusMutual/blob/master/contracts/TokenController.sol.
 */
interface TokenController {
    function totalBalanceOf(address) external view returns (uint256);
}


/**
 * @title Adapter for Nexus Mutual protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract NexusStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant TOKEN_CONTROLLER = 0x5407381b6c251cFd498ccD4A1d877739CB7960B8;
    address internal constant NXM = 0xd7c49CEE7E9188cCa6AD8FF264C1DA2e69D4Cf3B;

    /**
     * @return Amount of staked tokens + rewards by the given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address, address account) external view override returns (uint256) {
        uint256 totalBalance = TokenController(TOKEN_CONTROLLER).totalBalanceOf(account);
        uint256 tokenBalance = ERC20(NXM).balanceOf(account);
        return totalBalance - tokenBalance;
    }
}
