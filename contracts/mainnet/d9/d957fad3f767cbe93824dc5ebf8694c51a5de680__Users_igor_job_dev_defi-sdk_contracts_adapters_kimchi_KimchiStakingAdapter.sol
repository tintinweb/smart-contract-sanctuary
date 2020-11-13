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
 * @dev UserInfo struct from KimchiChef contract.
 * The KimchiChef contract is available here
 * github.com/sushiswap/sushiswap/blob/master/contracts/KimchiChef.sol.
 */
struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
}


/**
 * @dev PoolInfo struct from KimchiChef contract.
 * The KimchiChef contract is available here
 * github.com/sushiswap/sushiswap/blob/master/contracts/KimchiChef.sol.
 */
struct PoolInfo {
    address lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accSushiPerShare;
}


/**
 * @dev KimchiChef (forked KimchiChef) contract interface.
 * Only the functions required for SushiStakingAdapter contract are added.
 * The KimchiChef contract is available here
 * github.com/sushiswap/sushiswap/blob/master/contracts/KimchiChef.sol.
 */
interface KimchiChef {
    function poolLength() external view returns (uint256);
    function poolInfo(uint256) external view returns (PoolInfo memory);
    function userInfo(uint256, address) external view returns (UserInfo memory);
    function pendingKimchi(uint256, address) external view returns (uint256);
}


/**
 * @title Adapter for KIMCHI protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract KimchiStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant SUSHI = 0x1E18821E69B9FAA8e6e75DFFe54E7E25754beDa0;
    address internal constant KIMCHI_CHEF = 0x9Dd5b5c71842a4fD51533532E5470298BFA398fd;

    /**
     * @return Amount of SUSHI rewards / staked tokens for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        uint256 length = KimchiChef(KIMCHI_CHEF).poolLength();

        if (token == SUSHI) {
            uint256 totalRewards = 0;

            for(uint256 i = 0; i < length; i++) {
                totalRewards += KimchiChef(KIMCHI_CHEF).pendingKimchi(i, account);
            }

            return totalRewards;
        } else {
            for(uint256 i = 0; i < length; i++) {
                UserInfo memory user = KimchiChef(KIMCHI_CHEF).userInfo(i, account);
                PoolInfo memory pool = KimchiChef(KIMCHI_CHEF).poolInfo(i);

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
