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
 * The MasterChef contract is available here
 * github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol.
 */
struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
}


/**
 * @dev PoolInfo struct from MasterChef contract.
 * The MasterChef contract is available here
 * github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol.
 */
struct PoolInfo {
    address lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accSushiPerShare;
}


/**
 * @dev MasterChef contract interface.
 * Only the functions required for SushiStakingAdapter contract are added.
 * The MasterChef contract is available here
 * github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol.
 */
interface MasterChef {
    function poolLength() external view returns (uint256);
    function poolInfo(uint256) external view returns (PoolInfo memory);
    function userInfo(uint256, address) external view returns (UserInfo memory);
    function pendingSushi(uint256, address) external view returns (uint256);
}


/**
 * @title Adapter for SushiSwap protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract SushiStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address internal constant MASTER_CHEF = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    /**
     * @return Amount of SUSHI rewards / staked tokens for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        uint256 length = MasterChef(MASTER_CHEF).poolLength();

        if (token == SUSHI) {
            uint256 totalRewards = 0;

            for(uint256 i = 0; i < length; i++) {
                totalRewards += MasterChef(MASTER_CHEF).pendingSushi(i, account);
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}
