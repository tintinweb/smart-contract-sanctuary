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
 * @dev StakingRewards contract interface.
 * Only the functions required for UniswapV2StakingAdapter contract are added.
 * The StakingRewards contract is available here
 * github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol.
 */
interface StakingRewards {
    function earned(address) external view returns (uint256);
}


/**
 * @title Adapter for Uniswap V2 staking.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract UniswapV2StakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    address internal constant UNI_V2_WBTC_WETH = 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940;
    address internal constant UNI_V2_WETH_USDT = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
    address internal constant UNI_V2_USDC_WETH = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address internal constant UNI_V2_DAI_WETH = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;

    address internal constant UNI_V2_WBTC_WETH_POOL = 0xCA35e32e7926b96A9988f61d510E038108d8068e;
    address internal constant UNI_V2_WETH_USDT_POOL = 0x6C3e4cb2E96B01F4b866965A91ed4437839A121a;
    address internal constant UNI_V2_USDC_WETH_POOL = 0x7FBa4B8Dc5E7616e59622806932DBea72537A56b;
    address internal constant UNI_V2_DAI_WETH_POOL = 0xa1484C3aa22a66C62b77E0AE78E15258bd0cB711;

    /**
     * @return Amount of staked tokens / rewards earned after staking for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        if (token == UNI) {
            uint256 totalRewards = 0;

            totalRewards += StakingRewards(UNI_V2_WBTC_WETH_POOL).earned(account);
            totalRewards += StakingRewards(UNI_V2_WETH_USDT_POOL).earned(account);
            totalRewards += StakingRewards(UNI_V2_USDC_WETH_POOL).earned(account);
            totalRewards += StakingRewards(UNI_V2_DAI_WETH_POOL).earned(account);

            return totalRewards;
        } else if (token == UNI_V2_WBTC_WETH) {
            return ERC20(UNI_V2_WBTC_WETH_POOL).balanceOf(account);
        } else if (token == UNI_V2_WETH_USDT) {
            return ERC20(UNI_V2_WETH_USDT_POOL).balanceOf(account);
        } else if (token == UNI_V2_USDC_WETH) {
            return ERC20(UNI_V2_USDC_WETH_POOL).balanceOf(account);
        } else if (token == UNI_V2_DAI_WETH) {
            return ERC20(UNI_V2_DAI_WETH_POOL).balanceOf(account);
        } else {
            return 0;
        }
    }
}
