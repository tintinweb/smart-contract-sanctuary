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
 * Only the functions required for YearnStakingV1Adapter contract are added.
 * The StakingRewards contract is available here
 * github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol.
 */
interface StakingRewards {
    function earned(address) external view returns (uint256);
}


/**
 * @title Adapter for Harvest protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract HarvestStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant FARM = 0xa0246c9032bC3A600820415aE600c6388619A14D;
    address internal constant UNI_FARM_USDC = 0x514906FC121c7878424a5C928cad1852CC545892;
    address internal constant F_WBTC = 0x5d9d25c7C457dD82fc8668FFC6B9746b674d4EcB;
    address internal constant F_WETH = 0xFE09e53A81Fe2808bc493ea64319109B5bAa573e;
    address internal constant F_DAI = 0xab7FA2B2985BCcfC13c6D86b1D5A17486ab1e04C;
    address internal constant F_USDC = 0xf0358e8c3CD5Fa238a29301d0bEa3D63A17bEdBE;
    address internal constant F_USDT = 0x053c80eA73Dc6941F518a68E2FC52Ac45BDE7c9C;
    address internal constant F_RENBTC = 0xC391d1b08c1403313B0c28D47202DFDA015633C4;
    address internal constant F_CRV_RENWBTC = 0x9aA8F427A17d6B0d91B6262989EdC7D45d6aEdf8;
    address internal constant F_UNI_WETH_USDT = 0x7DDc3ffF0612E75Ea5ddC0d6Bd4e268f70362Cff;
    address internal constant F_UNI_WETH_USDC = 0xA79a083FDD87F73c2f983c5551EC974685D6bb36;
    address internal constant F_UNI_WETH_DAI = 0x307E2752e8b8a9C29005001Be66B1c012CA9CDB7;
    address internal constant F_UNI_WETH_WBTC = 0x01112a60f427205dcA6E229425306923c3Cc2073;
    address internal constant F_TUSD = 0x7674622c63Bee7F46E86a4A5A18976693D54441b;
    address internal constant F_SUSHI_WBTC_TBTC = 0xF553E1f826f42716cDFe02bde5ee76b2a52fc7EB;

    address internal constant FARM_POOL = 0x8f5adC58b32D4e5Ca02EAC0E293D35855999436C;
    address internal constant UNI_FARM_USDC_POOL = 0x99b0d6641A63Ce173E6EB063b3d3AED9A35Cf9bf;
    address internal constant F_WBTC_POOL = 0x917d6480Ec60cBddd6CbD0C8EA317Bcc709EA77B;
    address internal constant F_WETH_POOL = 0x3DA9D911301f8144bdF5c3c67886e5373DCdff8e;
    address internal constant F_DAI_POOL = 0x15d3A64B2d5ab9E152F16593Cdebc4bB165B5B4A;
    address internal constant F_USDC_POOL = 0x4F7c28cCb0F1Dbd1388209C67eEc234273C878Bd;
    address internal constant F_USDT_POOL = 0x6ac4a7AB91E6fD098E13B7d347c6d4d1494994a2;
    address internal constant F_RENBTC_POOL = 0x7b8Ff8884590f44e10Ea8105730fe637Ce0cb4F6;
    address internal constant F_CRV_RENWBTC_POOL = 0xA3Cf8D1CEe996253FAD1F8e3d68BDCba7B3A3Db5;
    address internal constant F_UNI_WETH_USDT_POOL = 0x75071F2653fBC902EBaff908d4c68712a5d1C960;
    address internal constant F_UNI_WETH_USDC_POOL = 0x156733b89Ac5C704F3217FEe2949A9D4A73764b5;
    address internal constant F_UNI_WETH_DAI_POOL = 0x7aeb36e22e60397098C2a5C51f0A5fB06e7b859c;
    address internal constant F_UNI_WETH_WBTC_POOL = 0xF1181A71CC331958AE2cA2aAD0784Acfc436CB93;
    address internal constant F_TUSD_POOL = 0xeC56a21CF0D7FeB93C25587C12bFfe094aa0eCdA;
    address internal constant F_SUSHI_WBTC_TBTC_POOL = 0x9523FdC055F503F73FF40D7F66850F409D80EF34;


    /**
     * @return Amount of staked tokens / rewards earned after staking for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        if (token == FARM) {
            uint256 totalRewards = 0;

            totalRewards += ERC20(FARM_POOL).balanceOf(account);
            totalRewards += StakingRewards(FARM_POOL).earned(account);
            totalRewards += StakingRewards(UNI_FARM_USDC_POOL).earned(account);
            totalRewards += StakingRewards(F_WBTC_POOL).earned(account);
            totalRewards += StakingRewards(F_WETH_POOL).earned(account);
            totalRewards += StakingRewards(F_DAI_POOL).earned(account);
            totalRewards += StakingRewards(F_USDC_POOL).earned(account);
            totalRewards += StakingRewards(F_USDT_POOL).earned(account);
            totalRewards += StakingRewards(F_RENBTC_POOL).earned(account);
            totalRewards += StakingRewards(F_CRV_RENWBTC_POOL).earned(account);
            totalRewards += StakingRewards(F_UNI_WETH_USDT_POOL).earned(account);
            totalRewards += StakingRewards(F_UNI_WETH_USDC_POOL).earned(account);
            totalRewards += StakingRewards(F_UNI_WETH_DAI_POOL).earned(account);
            totalRewards += StakingRewards(F_UNI_WETH_WBTC_POOL).earned(account);
            totalRewards += StakingRewards(F_TUSD_POOL).earned(account);
            totalRewards += StakingRewards(F_SUSHI_WBTC_TBTC_POOL).earned(account);

            return totalRewards;
        } else if (token == UNI_FARM_USDC) {
            return ERC20(UNI_FARM_USDC_POOL).balanceOf(account);
        } else if (token == F_WBTC) {
            return ERC20(F_WBTC_POOL).balanceOf(account);
        } else if (token == F_WETH) {
            return ERC20(F_WETH_POOL).balanceOf(account);
        } else if (token == F_DAI) {
            return ERC20(F_DAI_POOL).balanceOf(account);
        } else if (token == F_USDC) {
            return ERC20(F_USDC_POOL).balanceOf(account);
        } else if (token == F_USDT) {
            return ERC20(F_USDT_POOL).balanceOf(account);
        } else if (token == F_RENBTC) {
            return ERC20(F_RENBTC_POOL).balanceOf(account);
        } else if (token == F_CRV_RENWBTC) {
            return ERC20(F_CRV_RENWBTC_POOL).balanceOf(account);
        } else if (token == F_UNI_WETH_USDT) {
            return ERC20(F_UNI_WETH_USDT_POOL).balanceOf(account);
        } else if (token == F_UNI_WETH_USDC) {
            return ERC20(F_UNI_WETH_USDC_POOL).balanceOf(account);
        } else if (token == F_UNI_WETH_DAI) {
            return ERC20(F_UNI_WETH_DAI_POOL).balanceOf(account);
        } else if (token == F_UNI_WETH_WBTC) {
            return ERC20(F_UNI_WETH_WBTC_POOL).balanceOf(account);
        } else if (token == F_TUSD) {
            return ERC20(F_TUSD_POOL).balanceOf(account);
        } else if (token == F_SUSHI_WBTC_TBTC) {
            return ERC20(F_SUSHI_WBTC_TBTC_POOL).balanceOf(account);
        } else {
            return 0;
        }
    }
}
