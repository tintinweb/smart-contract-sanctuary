// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

import "./FraxFarm_UniV3_veFXS.sol";

contract FraxFarm_UniV3_veFXS_FRAX_USDC is FraxFarm_UniV3_veFXS {
    constructor(
        address _owner,
        address _rewardsToken0,
        address _stakingTokenNFT,
        address _lp_pool_address,
        address _timelock_address,
        address _veFXS_address,
        address _gauge_controller_address,
        address _uni_token0,
        address _uni_token1,
        int24 _uni_tick_lower,
        int24 _uni_tick_upper,
        int24 _uni_ideal_tick
    ) 
    FraxFarm_UniV3_veFXS(_owner, _rewardsToken0, _stakingTokenNFT, _lp_pool_address, _timelock_address, _veFXS_address, _gauge_controller_address, _uni_token0, _uni_token1, _uni_tick_lower, _uni_tick_upper, _uni_ideal_tick)
    {}
}