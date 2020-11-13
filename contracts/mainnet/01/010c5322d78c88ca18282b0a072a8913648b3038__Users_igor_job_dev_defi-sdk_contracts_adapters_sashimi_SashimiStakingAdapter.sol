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
 * @dev UserInfo struct from MasterChef contract.
 */
struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
}


/**
 * @dev PoolInfo struct from MasterChef contract.
 */
struct PoolInfo {
    address lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accSushiPerShare;
}


/**
 * @dev MasterChef contract interface.
 * Only the functions required for SashimiStakingAdapter contract are added.
 */
interface MasterChef {
    function poolLength() external view returns (uint256);
    function poolInfo(uint256) external view returns (PoolInfo memory);
    function userInfo(uint256, address) external view returns (UserInfo memory);
    function pendingSashimi(uint256, address) external view returns (uint256);
}


/**
 * @title Adapter for SashimiSwap protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract SashimiStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant SASHIMI = 0xC28E27870558cF22ADD83540d2126da2e4b464c2;
    address internal constant MASTER_CHEF = 0x1DaeD74ed1dD7C9Dabbe51361ac90A69d851234D;

    /**
     * @return Amount of SASHIMI rewards / staked tokens for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        uint256 length = MasterChef(MASTER_CHEF).poolLength();

        if (token == SASHIMI) {
            uint256 totalRewards = 0;

            for(uint256 i = 0; i < length; i++) {
                totalRewards += MasterChef(MASTER_CHEF).pendingSashimi(i, account);
            }

            return totalRewards;
        } else {
            for(uint256 i = 0; i < length; i++) {
                UserInfo memory user = MasterChef(MASTER_CHEF).userInfo(i, account);
                PoolInfo memory pool = MasterChef(MASTER_CHEF).poolInfo(i);

                if (pool.lpToken == token) {
                    return user.amount;
                }
            }

            return 0;
        }
    }
}
