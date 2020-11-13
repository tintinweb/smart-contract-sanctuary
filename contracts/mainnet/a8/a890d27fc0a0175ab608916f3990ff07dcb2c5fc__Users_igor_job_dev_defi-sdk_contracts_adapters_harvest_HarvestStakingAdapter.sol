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
    address internal constant FDAI = 0xe85C8581e60D7Cd32Bbfd86303d2A4FA6a951Dac;
    address internal constant FUSDC = 0xc3F7ffb5d5869B3ade9448D094d81B0521e8326f;
    address internal constant FUSDT = 0xc7EE21406BB581e741FBb8B21f213188433D9f2F;
    address internal constant BALANCER_USDC_95_FARM_5 = 0x0395e4A17fF11D36DaC9959f2D7c8Eca10Fe89c9;
    address internal constant UNISWAP_V2_USDC_FARM = 0x514906FC121c7878424a5C928cad1852CC545892;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address internal constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    address internal constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address internal constant YFV = 0x45f24BaEef268BB6d63AEe5129015d69702BCDfa;
    address internal constant YFII = 0xa1d0E215a23d7030842FC67cE582a6aFa3CCaB83;
    address internal constant OGN = 0x8207c1FfC5B6804F6024322CcF34F29c3541Ae26;
    address internal constant UNISWAP_V2_BASED_SUSD = 0xaAD22f5543FCDaA694B68f94Be177B561836AE57;
    address internal constant UNISWAP_V2_PASTA_WETH = 0xE92346d9369Fe03b735Ed9bDeB6bdC2591b8227E;

    address internal constant FDAI_POOL = 0xF9E5f9024c2f3f2908A1d0e7272861a767C9484b;
    address internal constant FUSDC_POOL = 0xE1f9A3EE001a2EcC906E8de637DBf20BB2d44633;
    address internal constant FUSDT_POOL = 0x5bd997039FFF16F653EF15D1428F2C791519f58d;
    address internal constant BALANCER_POOL = 0x6f8A975758436A5Ec38d2f9d2336504430465517;
    address internal constant UNISWAP_POOL = 0x99b0d6641A63Ce173E6EB063b3d3AED9A35Cf9bf;
    address internal constant PROFIT_SHARING_POOL = 0xae024F29C26D6f71Ec71658B1980189956B0546D;

    address internal constant WETH_POOL = 0xE604Fd5b1317BABd0cF2c72F7F5f2AD8c00Adbe1;
    address internal constant LINK_POOL = 0xa112c2354d27c2Fb3370cc5d027B28987117a268;
    address internal constant YFI_POOL = 0x84646F736795a8bC22Ab34E05c8982CD058328C7;
    address internal constant SUSHI_POOL = 0x4938960C507A4d7094C53A8cDdCF925835393B8f;
    address internal constant YFV_POOL = 0x3631A32c959C5c52BC90AB5b7D212a8D00321918;
    address internal constant YFII_POOL = 0xC97DDAa8091aBaF79A4910b094830CCE5cDd78f4;
    address internal constant OGN_POOL = 0xF71042C88458ff1702c3870f62F4c764712Cc9F0;
    address internal constant BASED_POOL = 0xb3b56c7BDc87F9DeB7972cD8b5c09329ce421F89;
    address internal constant PASTA_POOL = 0xC6f39CFf6797baC5e29275177b6E8e315cF87D95;

    /**
     * @return Amount of staked tokens / rewards earned after staking for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        if (token == FARM) {
            uint256 totalRewards = 0;

            totalRewards += ERC20(PROFIT_SHARING_POOL).balanceOf(account);
            totalRewards += StakingRewards(FDAI_POOL).earned(account);
            totalRewards += StakingRewards(FUSDC_POOL).earned(account);
            totalRewards += StakingRewards(FUSDT_POOL).earned(account);
            totalRewards += StakingRewards(BALANCER_POOL).earned(account);
            totalRewards += StakingRewards(UNISWAP_POOL).earned(account);
            totalRewards += StakingRewards(WETH_POOL).earned(account);
            totalRewards += StakingRewards(LINK_POOL).earned(account);
            totalRewards += StakingRewards(YFI_POOL).earned(account);
            totalRewards += StakingRewards(SUSHI_POOL).earned(account);
            totalRewards += StakingRewards(YFV_POOL).earned(account);
            totalRewards += StakingRewards(YFII_POOL).earned(account);
            totalRewards += StakingRewards(OGN_POOL).earned(account);
            totalRewards += StakingRewards(BASED_POOL).earned(account);
            totalRewards += StakingRewards(PASTA_POOL).earned(account);

            return totalRewards;
        } else if (token == DAI) {
            return StakingRewards(PROFIT_SHARING_POOL).earned(account);
        } else if (token == FDAI) {
            return ERC20(FDAI_POOL).balanceOf(account);
        } else if (token == FUSDC) {
            return ERC20(FUSDC_POOL).balanceOf(account);
        } else if (token == FUSDT) {
            return ERC20(FUSDT_POOL).balanceOf(account);
        } else if (token == BALANCER_USDC_95_FARM_5) {
            return ERC20(BALANCER_POOL).balanceOf(account);
        } else if (token == UNISWAP_V2_USDC_FARM) {
            return ERC20(UNISWAP_POOL).balanceOf(account);
        } else if (token == WETH) {
            return ERC20(WETH_POOL).balanceOf(account);
        } else if (token == LINK) {
            return ERC20(LINK_POOL).balanceOf(account);
        } else if (token == YFI) {
            return ERC20(YFI_POOL).balanceOf(account);
        } else if (token == SUSHI) {
            return ERC20(SUSHI_POOL).balanceOf(account);
        } else if (token == YFV) {
            return ERC20(YFV_POOL).balanceOf(account);
        } else if (token == YFII) {
            return ERC20(YFII_POOL).balanceOf(account);
        } else if (token == OGN) {
            return ERC20(OGN_POOL).balanceOf(account);
        } else if (token == UNISWAP_V2_BASED_SUSD) {
            return ERC20(BASED_POOL).balanceOf(account);
        } else if (token == UNISWAP_V2_PASTA_WETH) {
            return ERC20(PASTA_POOL).balanceOf(account);
        } else {
            return 0;
        }
    }
}
