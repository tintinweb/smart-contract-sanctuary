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
 * Only the functions required for PieDAOStakingAdapter contract are added.
 * The StakingRewards contract is available here
 * github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol.
 */
interface StakingRewards {
    function earned(address) external view returns (uint256);
}

/**
 * @title Adapter for PieDAO protocol (staking).
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract PieDAOStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant DOUGH = 0xad32A8e6220741182940c5aBF610bDE99E737b2D;
    address internal constant BALANCER_ETH_20_DOUGH_80 = 0xFAE2809935233d4BfE8a56c2355c4A2e7d1fFf1A;
    address internal constant UNISWAP_DAI_DEFI = 0x7aeFaF3ea1b465dd01561B0548c9FD969e3F76BA;
    address internal constant BALANCER_DEFI_70_ETH_30 = 0x35333CF3Db8e334384EC6D2ea446DA6e445701dF;

    address internal constant BALANCER_ETH_20_DOUGH_80_POOL = 0x8314337d2b13e1A61EadF0FD1686b2134D43762F;
    address internal constant UNISWAP_DAI_DEFI_POOL = 0x64964cb69f40A1B56AF76e32Eb5BF2e2E52a747c;
    address internal constant BALANCER_DEFI_70_ETH_30_POOL = 0x220f25C2105a65425913FE0CF38e7699E3992B97;

    /**
     * @return Amount of staked LP tokens for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        if (token == DOUGH) {
            uint256 totalBalance = 0;

            totalBalance += StakingRewards(BALANCER_ETH_20_DOUGH_80_POOL).earned(account);
            totalBalance += StakingRewards(UNISWAP_DAI_DEFI_POOL).earned(account);
            totalBalance += StakingRewards(BALANCER_DEFI_70_ETH_30_POOL).earned(account);

            return totalBalance;
        } else if (token == BALANCER_ETH_20_DOUGH_80) {
            return ERC20(BALANCER_ETH_20_DOUGH_80_POOL).balanceOf(account);
        } else if (token == UNISWAP_DAI_DEFI) {
            return ERC20(UNISWAP_DAI_DEFI_POOL).balanceOf(account);
        } else if (token == BALANCER_DEFI_70_ETH_30) {
            return ERC20(BALANCER_DEFI_70_ETH_30_POOL).balanceOf(account);
        } else {
            return 0;
        }
    }
}
